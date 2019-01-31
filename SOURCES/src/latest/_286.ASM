	include	page.inc

	.286c				; allow 80286 instructions

DEBUG	equ	0
SLOW	equ	1
TIME1	equ	180			; 10 seconds before descriptor maint
TIME2	equ	216			; 12 seconds before fast mode
LIGHTS	equ	1

;--------------------------------------------------------------------;
;               MEMDEV Driver for 80286 Protected Mode               ;
;           Copyright 1988 The Software Link, Incorporated           ;
;--------------------------------------------------------------------;
;     MOS will always load this driver at absolute address 00700     ;
;--------------------------------------------------------------------;

PARLIMIT equ   0900h                    ; support up to 8mb + 640k 

mainseg  segment para public 'code'
         assume cs:mainseg,ds:mainseg
begin    label near

         public mmbeg
mmbeg    label near

;--------------------- Device Header at 00700 -----------------------;

	dd	-1			; pointer to next driver
	dw	8000h			; attribute: indicate character device
	dw	strategy		; pointer to strategy routine
	dw	interupt		; pointer to interrupt routine
	db	'$$MEMDEV'		; device name

wsmaint	db	'Y'			; plug Y here to turn on dtmaint
cchange	db	'N'			; Y to change code selectors to FFxx

	db	'Copyright 1988 The Software Link, Incorporated ',1ah

;----------------------- Miscellaneous Data -------------------------;

	even
litbits	dw	0100h
litally	db	0

	org	0068h			; get within 128 bytes of "base"

seldata	dw	gdtdata-gdt
selcode	dw	gdtcode-gdt
selzero	dw	gdtzero-gdt
selwork	dw	gdtwork-gdt
selscum	dw	gdtscum-gdt
selvideo dw	?			; video ram selector for cpl=3
selgdt	dw	?			; gdt data  selector for cpl=3
selldt	dw	?			; ldt data  selector for cpl=3
selidt  dw	?			; idt data  selector for cpl=3

cscount dw	0			; number of entries in cstab1/cstab2
cscslow	dw	0			; substitute for cscount in slow mode
overseg	 dw	0			; selector from override prefix
override db	'N'			; Y if seg override in effect

fastmode db	'S'			; F if in "fast mode"
newtime  dw	0			; saves timer value
excount  dw	0			; counts exceptions in slow mode
excmax   dw	64			; max acceptable exceptions/second
dabegin	 dw	00400h			; begin of dynamic area
daend	 dw	0a000h			; end   of dynamic area
trsegadr dw	?			; for trace
trtype	 db     ?			; for trace
trreason db	?			; for trace

;------------ Stack for Privilege Change to Level Zero --------------;

	 org	00f0h-12		; leaving some stack space
p0error  dw	0                       ; error code 
base	 label	byte			; see discussion in entint0d handler
p0ip     dw	0
p0cs     dw	0
p0flags  dw	0
p0sp     dw	0
p0ss     dw	0
p0stack  label	word

;------------------- mos Foundation Area at 007f0 -------------------;

	org	00f0h
	dd	?			; pointer to Int 13 handler
	db	5 dup(?)		; jmp dword ptr cs:[0]
	db	?			; unused
	dw	?			; segment address of grp
mfazero	dw	?			; selector for segment at 00000
	dw	?			; unused

	page
;--------------------------------------------------------------------;
;        LOADALL Data Area at 00800 - Initially for Real Mode        ;
;--------------------------------------------------------------------;

lastart	label	byte
	db	6 dup(0)	; unused
lamsw	dw	0fff0h		; Machine Status Word
	db	14 dup(0)	; unused
latr	dw	0		; Task Register 
laflags	dw	0002h		; Flags Register
laip	dw	0		; Instruction Pointer
laldt	dw	0		; ldt Selector
lads	dw	0		; ds Selector
lass	dw	0		; ss Selector
lacs	dw	0		; cs Selector
laes	dw	0		; es Selector
ladi	dw	0		; di
lasi	dw	0		; si
labp	dw	0		; bp
lasp	dw	0		; sp
labx	dw	0		; bx
ladx	dw	0		; dx
lacx	dw	0		; cx
laax	dw	0		; ax

laesdc	db	3 dup(0)	; es base address
	db	11110010b	;  p=1,dpl=11,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit
lacsdc	db	3 dup(0)	; cs base address
	db	10010010b	;  p=1,dpl=00,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit
lassdc	db	3 dup(0)	; ss base address
	db	10010010b	;  p=1,dpl=00,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit
ladsdc	db	3 dup(0)	; ds base address
	db	11110010b	;  p=1,dpl=11,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit

lagdtr	dw	0		; gdtr base 
	db	0,0
      	dw	0		; limit
laldtdc dw	0		; ldt base address
	db	0		;  64k beyond gdt
	db	00000010b	;  p=0,dpl=00,0,type=ldt
	dw	0		;  limit
laidtr	dw	0		; idtr base 
	db	0,0
      	dw	256*4-1		; limit
latssdc	dw	0		; tss base address
	db	0
	db	00000001b	;  p=0,dpl=00,0,type=avtss
	dw	0		;  limit

lalen	equ	$-lastart

	page
;--------------------------------------------------------------------;
;                       Code Selector Table                          ;
;--------------------------------------------------------------------;

CSTMAX	equ	10			; maximum number of entries
cstab1	dw	CSTMAX dup(0)		; segment address entries
cstab2	dw	CSTMAX dup(0)     	; FFxx selector values
cstseln	dw	0ffbfh			; next-available selector value
cstself	dw	0ffbfh			; first selector value

;--------------------------------------------------------------------;
;                      Interrupt Jump Table                          ;
;--------------------------------------------------------------------;

	even
ijtable	db	5*256 dup(-1)	; 256 indirect far jumps with cs override

;--------------------------------------------------------------------;
;                        Miscellaneous data                          ;
;--------------------------------------------------------------------;

	even
wsgdtr   dw	0ffffh,0,0		; to initialize gdt
wsidtr   dw	256*8-1,0,0		;           and idt

buffsize dw	18*512			; disk staging buffer size 
emstart	 dw	0100h			; extended memory starts at 100000
wordten	 dw	10
myselect dw	0070h			; for loading ds

;--------------------------------------------------------------------;
;                          Selector Cache                            ;
;--------------------------------------------------------------------;
;   The purpose of this table is to speed up the "getadr3" routine,  ;
;   which determines the physical address for a given selector.      ;
;   Each 8-byte table entry contains a 2-byte selector value, a      ;
;   3-byte address, a flag byte, and 2 unused bytes.  The index      ;
;   into the table is computed by a simple randomization of the      ;
;   selector - see "getadr3" for specifics.  FFFE in the first word  ;
;   indicates an unused entry.  This cache is invalidated (cleared)  ;
;   whenever a remap operation is done.                              ;
;--------------------------------------------------------------------;

selcache dw	64 dup(0fffeh)		; 16 8-byte entries

	page
;--------------------------------------------------------------------;
;         map instruction op codes to the appropriate handler        ;
;--------------------------------------------------------------------;

optable  label	word

         dw	opmisc   ; 00  add  mem/reg,reg (byte)
         dw	opmisc   ; 01  add  mem/reg,reg (word)
         dw	opmisc   ; 02  add  reg,mem/reg (byte)
         dw	opmisc   ; 03  add  reg,mem/reg (word)
         dw	opmisc   ; 04  add  al,kk
         dw	opmisc   ; 05  add  ax,jjkk
         dw	opmisc   ; 06  push es
         dw	oppopes  ; 07  pop  es
         dw	opmisc   ; 08  or   mem/reg,reg (byte)
         dw	opmisc   ; 09  or   mem/reg,reg (word)
         dw	opmisc   ; 0a  or   reg,mem/reg (byte)
         dw	opmisc   ; 0b  or   reg,mem/reg (word)
         dw	opmisc   ; 0c  or   al,kk
         dw	opmisc   ; 0d  or   ax,jjkk
         dw	opmisc   ; 0e  push cs
         dw	opmisc   ; 0f  Invalid

         dw	opmisc   ; 10  adc  mem/reg,reg (byte)
         dw	opmisc   ; 11  adc  mem/reg,reg (word)
         dw	opmisc   ; 12  adc  reg,mem/reg (byte)
         dw	opmisc   ; 13  adc  reg,mem/reg (word)
         dw	opmisc   ; 14  adc  al,kk
         dw	opmisc   ; 15  adc  ax,jjkk
         dw	opmisc   ; 16  push ss
         dw	oppopss  ; 17  pop  ss
         dw	opmisc   ; 18  sbb  mem/reg,reg (byte)
         dw	opmisc   ; 19  sbb  mem/reg,reg (word)
         dw	opmisc   ; 1a  sbb  reg,mem/reg (byte)
         dw	opmisc   ; 1b  sbb  reg,mem/reg (word)
         dw	opmisc   ; 1c  sbb  al,kk
         dw	opmisc   ; 1d  sbb  al,jjkk
         dw	opmisc   ; 1e  push ds
         dw	oppopds  ; 1f  pop  ds

         dw	opmisc   ; 20  and  mem/reg,reg (byte)
         dw	opmisc   ; 21  and  mem/reg,reg (word)
         dw	opmisc   ; 22  and  reg,mem/reg (byte)
         dw	opmisc   ; 23  and  reg,mem/reg (word)
         dw	opmisc   ; 24  and  al,kk
         dw	opmisc   ; 25  and  ax,jjkk
         dw	opseges  ; 26  seg  es
         dw	opmisc   ; 27  daa
         dw	opmisc   ; 28  sub  mem/reg,reg (byte)
         dw	opmisc   ; 29  sub  mem/reg,reg (word)
         dw	opmisc   ; 2a  sub  reg,mem/reg (byte)
         dw	opmisc   ; 2b  sub  reg,mem/reg (word)
         dw	opmisc   ; 2c  sub  al,kk
         dw	opmisc   ; 2d  sub  ax,jjkk
         dw	opsegcs  ; 2e  seg  cs
         dw	opmisc   ; 2f  das

         dw	opmisc   ; 30  xor  mem/reg,reg (byte)
         dw	opmisc   ; 31  xor  mem/reg,reg (word)
         dw	opmisc   ; 32  xor  reg,mem/reg (byte)
         dw	opmisc   ; 33  xor  reg,mem/reg (word)
         dw	opmisc   ; 34  xor  al,kk
         dw	opmisc   ; 35  xor  ax,jjkk
         dw	opsegss  ; 36  seg  ss
         dw	opmisc   ; 37  aaa
         dw	opmisc   ; 38  cmp  mem/reg,reg (byte)
         dw	opmisc   ; 39  cmp  mem/reg,reg (word)
         dw	opmisc   ; 3a  cmp  reg,mem/reg (byte)
         dw	opmisc   ; 3b  cmp  reg,mem/reg (word)
         dw	opmisc   ; 3c  cmp  al,kk
         dw	opmisc   ; 3d  cmp  ax,jjkk
         dw	opsegds  ; 3e  seg  ds
         dw	opmisc   ; 3f  aas

	page
         dw	opmisc   ; 40  inc ax
         dw	opmisc   ; 41  inc cx
         dw	opmisc   ; 42  inc dx
         dw	opmisc   ; 43  inc bx
         dw	opmisc   ; 44  inc sp
         dw	opmisc   ; 45  inc bp
         dw	opmisc   ; 46  inc si
         dw	opmisc   ; 47  inc di
         dw	opmisc   ; 48  dec ax
         dw	opmisc   ; 49  dec cx
         dw	opmisc   ; 4a  dec dx
         dw	opmisc   ; 4b  dec bx
         dw	opmisc   ; 4c  dec sp
         dw	opmisc   ; 4d  dec bp
         dw	opmisc   ; 4e  dec si
         dw	opmisc   ; 4f  dec di

         dw	opmisc   ; 50  push ax
         dw	opmisc   ; 51  push cx
         dw	opmisc   ; 52  push dx
         dw	opmisc   ; 53  push bx
         dw	opmisc   ; 54  push sp
         dw	opmisc   ; 55  push bp
         dw	opmisc   ; 56  push si
         dw	opmisc   ; 57  push di
         dw	opmisc   ; 58  pop ax
         dw	opmisc   ; 59  pop cx
         dw	opmisc   ; 5a  pop dx
         dw	opmisc   ; 5b  pop bx
         dw	opmisc   ; 5c  pop sp
         dw	opmisc   ; 5d  pop bp
         dw	opmisc   ; 5e  pop si
         dw	opmisc   ; 5f  pop di

         dw	opmisc   ; 60  Invalid
         dw	opmisc   ; 61  Invalid
         dw	opmisc   ; 62  Invalid
         dw	opmisc   ; 63  Invalid
         dw	opmisc   ; 64  Invalid
         dw	opmisc   ; 65  Invalid
         dw	opmisc   ; 66  Invalid
         dw	opmisc   ; 67  Invalid
         dw	opmisc   ; 68  Invalid
         dw	opmisc   ; 69  Invalid
         dw	opmisc   ; 6a  Invalid
         dw	opmisc   ; 6b  Invalid
         dw	opmisc   ; 6c  Invalid
         dw	opmisc   ; 6d  Invalid
         dw	opmisc   ; 6e  Invalid
         dw	opmisc   ; 6f  Invalid

         dw	opmisc   ; 70  jo
         dw	opmisc   ; 71  jno
         dw	opmisc   ; 72  jb or jnae or jc
         dw	opmisc   ; 73  jnb or jae or jnc
         dw	opmisc   ; 74  je or jz
         dw	opmisc   ; 75  jne or jnz
         dw	opmisc   ; 76  jbe or jna
         dw	opmisc   ; 77  jnbe or ja
         dw	opmisc   ; 78  js
         dw	opmisc   ; 79  jns
         dw	opmisc   ; 7a  jp or jpe
         dw	opmisc   ; 7b  jnp or jpo
         dw	opmisc   ; 7c  jl or jnge
         dw	opmisc   ; 7d  jnl or jge
         dw	opmisc   ; 7e  jle or jng
         dw	opmisc   ; 7f  jnle or jg

	page
         dw	opmisc   ; 80  misc mem/reg,kk   instructions
         dw	opmisc   ; 81  misc mem/reg,jjkk instructions
         dw	opmisc   ; 82
         dw	opmisc   ; 83
         dw	opmisc   ; 84  test mem/reg,reg (byte)
         dw	opmisc   ; 85  test mem/reg,reg (word)
         dw	opmisc   ; 86  xchg reg,mem/reg (byte)
         dw	opmisc   ; 87  xchg reg,mem/reg (word)            
         dw	opmisc   ; 88  mov  mem/reg,reg (byte)
         dw	opmisc   ; 89  mov  mem/reg,reg (word)            
         dw	opmisc   ; 8a  mov  reg,mem/reg (byte)
         dw	opmisc   ; 8b  mov  reg,mem/reg (word)            
         dw	opmisc   ; 8c  mov  mem/reg,segreg or invalid
         dw	opmisc   ; 8d  lea  reg,addr                      
         dw	op8e     ; 8e  mov  segreg,mem/reg or invalid     
         dw	opmisc   ; 8f  pop  mem/reg or invalid

         dw	opmisc   ; 90  nop
         dw	opmisc   ; 91  xchg ax,cx
         dw	opmisc   ; 92  xchg ax,dx
         dw	opmisc   ; 93  xchg ax,bx
         dw	opmisc   ; 94  xchg ax,sp                         
         dw	opmisc   ; 95  xchg ax,bp
         dw	opmisc   ; 96  xchg ax,si
         dw	opmisc   ; 97  xchg ax,di
         dw	opmisc   ; 98  cbw
         dw	opmisc   ; 99  cwd
         dw	opcallfd ; 9a  call far (5 bytes)
         dw	opmisc   ; 9b  wait  (Commonly used with 8087 instructions)
         dw	opmisc   ; 9c  pushf
         dw	opmisc   ; 9d  popf
         dw	opmisc   ; 9e  sahf
         dw	opmisc   ; 9f  lahf

         dw	opmisc   ; a0  mov  al,addr
         dw	opmisc   ; a1  mov  ax,addr
         dw	opmisc   ; a2  mov  addr,al (3 bytes)
         dw	opmisc   ; a3  mov  addr,ax (3 bytes)
         dw	opmisc   ; a4  movsb
         dw	opmisc   ; a5  movsw
         dw	opmisc   ; a6  cmpsb
         dw	opmisc   ; a7  cmpsw
         dw	opmisc   ; a8  test al,kk
         dw	opmisc   ; a9  test ax,jjkk
         dw	opmisc   ; aa  stosb
         dw	opmisc   ; ab  stosw
         dw	opmisc   ; ac  lodsb
         dw	opmisc   ; ad  lodsw
         dw	opmisc   ; ae  scasb
         dw	opmisc   ; af  scasw

         dw	opmisc   ; b0  mov  al,kk
         dw	opmisc   ; b1  mov  cl,kk
         dw	opmisc   ; b2  mov  dl,kk
         dw	opmisc   ; b3  mov  bl,kk
         dw	opmisc   ; b4  mov  ah,kk
         dw	opmisc   ; b5  mov  ch,kk
         dw	opmisc   ; b6  mov  dh,kk
         dw	opmisc   ; b7  mov  bh,kk
         dw	opmisc   ; b8  mov  ax,jjkk
         dw	opmisc   ; b9  mov  cx,jjkk
         dw	opmisc   ; ba  mov  dx,jjkk
         dw	opmisc   ; bb  mov  bx,jjkk
         dw	opmisc   ; bc  mov  sp,jjkk                       
         dw	opmisc   ; bd  mov  bp,jjkk
         dw	opmisc   ; be  mov  si,jjkk
         dw	opmisc   ; bf  mov  di,jjkk

	page
         dw	opmisc   ; c0  Invalid
         dw	opmisc   ; c1  Invalid
         dw	opmisc   ; c2  ret  jjkk
         dw	opmisc   ; c3  ret
         dw	oples    ; c4  les  reg,addr
         dw	oplds    ; c5  lds  reg,addr
         dw	opmisc   ; c6  mov  mem/reg,kk
         dw	opmisc   ; c7  mov  mem/reg,jjkk                  
         dw	opmisc   ; c8  Invalid
         dw	opmisc   ; c9  Invalid
         dw	opretf3  ; ca  ret jjkk
         dw	opretf   ; cb  ret
         dw	opmisc   ; cc  int 3
         dw	opmisc   ; cd  int nn
         dw	opmisc   ; ce  into
         dw	opiret   ; cf  iret

         dw	opmisc   ; d0  Shift/Rotate Instructions
         dw	opmisc   ; d1  Shift/Rotate Instructions
         dw	opmisc   ; d2  Shift/Rotate Instructions
         dw	opmisc   ; d3  Shift/Rotate Instructions
         dw	opmisc   ; d4  aam
         dw	opmisc   ; d5  aad
         dw	opmisc   ; d6  Invalid
         dw	opmisc   ; d7  xlat
         dw	opmisc   ; d8  esc mem/reg \
         dw	opmisc   ; d9  esc mem/reg  \
         dw	opmisc   ; da  esc mem/reg   \
         dw	opmisc   ; db  esc mem/reg    \
         dw	opmisc   ; dc  esc mem/reg    /  8087 Instruction Set
         dw	opmisc   ; dd  esc mem/reg   /
         dw	opmisc   ; de  esc mem/reg  /
         dw	opmisc   ; df  esc mem/reg /

         dw	opmisc   ; e0  loopnz disp
         dw	opmisc   ; e1  loopz disp
         dw	opmisc   ; e2  loop disp
         dw	opmisc   ; e3  jcxz disp
         dw	opmisc   ; e4  in  al,kk
         dw	opmisc   ; e5  in  ax,kk
         dw	opmisc   ; e6  out kk,al
         dw	opmisc   ; e7  out kk,ax
         dw	opmisc   ; e8  call near
         dw	opmisc   ; e9  jmp  near
         dw	opjumpfd ; ea  jmp  far
         dw	opmisc   ; eb  jmp  short
         dw	opmisc   ; ec  in  al,dx
         dw	opmisc   ; ed  in  ax,dx
         dw	opmisc   ; ee  out dx,al
         dw	opmisc   ; ef  out dx,ax

         dw	opmisc   ; f0  lock
         dw	opmisc   ; f1  Invalid
         dw	opmisc   ; f2  repnz
         dw	opmisc   ; f3  rep
         dw	opmisc   ; f4  hlt invalid!
         dw	opmisc   ; f5  cmc
         dw	opmisc   ; f6
         dw	opmisc   ; f7
         dw	opmisc   ; f8  clc
         dw	opmisc   ; f9  stc
         dw	opmisc   ; fa  cli
         dw	opmisc   ; fb  sti
         dw	opmisc   ; fc  cld
         dw	opmisc   ; fd  std
         dw	opmisc   ; fe
         dw	opff     ; ff

	page
;--------------------------------------------------------------------;
;                      device function vectors                       ;
;--------------------------------------------------------------------;

	 even
funtab   label word
         dw    init
         dw    mediachk
         dw    buildbpb
         dw    ioctlin
         dw    input
         dw    ndinput
         dw    instatus
         dw    inflush
         dw    output
         dw    outputv
         dw    oustatus
         dw    ouflush
         dw    ioctlout

         page
;--------------------------------------------------------------------;
;                   strategy and interrupt routines                  ;
;--------------------------------------------------------------------;

strategy label near
	 push  ds
	 push  ax
	 mov   ds,cs:[myselect]
         mov   [rhseg],es
         mov   [rhoff],bx
	 pop   ax
	 pop   ds
farret1  proc  far
         ret
farret1  endp  

interupt label near
         push  bp
         push  es
         push  ds
         push  di
         push  si
         push  dx
         push  cx
         push  bx
         push  ax

	 mov   ds,cs:[myselect]	     ; init ds register
         les   bx,dword ptr [rhoff]  ; load rh pointer
         mov   al,es:[bx+2]          ; get command code byte
         mov   ah,0
         shl   ax,1
         mov   di,ax
         jmp   [di+funtab]
  
donestat label near
         les   bx,dword ptr [rhoff]
         or    word ptr es:[bx+03],0100h   ; "done" status

exit     label near
         clc
         pop   ax
         pop   bx
         pop   cx
         pop   dx
         pop   si
         pop   di
         pop   ds
         pop   es
         pop   bp
farret2  proc  far
         ret
farret2  endp

         page
;--------------------------------------------------------------------;
;                        device functions                            ;
;--------------------------------------------------------------------;

input    label near
         les   bx,dword ptr es:[bx+14] ; address the buffer
         mov   word ptr es:[bx],offset parms
         mov   es:[bx+2],ds
         les   bx,dword ptr [rhoff]
         mov   word ptr es:[bx+18],4   ; 4 bytes transferred
         jmp   donestat

output   label near
outputv  label near
ioctlin  label near
ioctlout label near
         mov   word ptr es:[bx+18],0     ; no data transferred
ndinput  label near
instatus label near
inflush  label near
oustatus label near
ouflush  label near
mediachk label near
buildbpb label near
         or    word ptr es:[bx+03],8102h ; indicate device not ready
         jmp   donestat
         page
;--------------------------------------------------------------------;
;                         int 13 vector table                        ;
;--------------------------------------------------------------------;

         even
int13tab label word
         dw    i13pass  ; 00  reset disk
         dw    i13pass  ; 01  get status
         dw    i13nread ; 02  read sectors
         dw    i13nwrit ; 03  write sectors
         dw    i13verfy ; 04  verify sectors
         dw    i13swrit ; 05  format track
         dw    i13swrit ; 06  format track with bad sector flags
         dw    i13pass  ; 07  format drive
         dw    i13pass  ; 08  get drive parameters
         dw    i13pass  ; 09  init drive pair characteristics
         dw    i13lread ; 0a  read long  (516 bytes per sector)
         dw    i13lwrit ; 0b  write long (516 bytes per sector)
         dw    i13pass  ; 0c  seek
         dw    i13pass  ; 0d  alternate disk reset
         dw    i13sread ; 0e  read sector buffer  (only 1 sector)
         dw    i13swrit ; 0f  write sector buffer (only 1 sector)

         dw    i13pass  ; 10  test drive ready
         dw    i13pass  ; 11  recalibrate
         dw    i13pass  ; 12  controller ram diagnostic
         dw    i13pass  ; 13  drive diagnostic
         dw    i13pass  ; 14  controller internal diagnostic
         dw    i13pass  ; 15  read dasd type 
         dw    i13pass  ; 16  get change line status 
         dw    i13pass  ; 17  set dasd type for format 

         dw    i13pass  ; 18  reset disk    \
         dw    i13pass  ; 19  get status     \   emulex hard disk
         dw    i13nread ; 1a  read sectors   /
         dw    i13nwrit ; 1b  write sectors /

         page
;------------------------ int 13h entry -----------------------------;
;        Note that hard disk does not use dma channel, so no         ;
;        staging -- but leave the logic there in case some           ;
;        3rd-party drive needs it patched in.                        ;
;--------------------------------------------------------------------;

entinr13 label near
         sti
	 push  ds
         pushf

         cmp   dl,80h                ; ***** exit if dma not used *****

dmajump  label word		; this is nop'ed out if hard disk uses dma
         jae   fastex13 

         cmp   ah,1bh                ; boundary check
         ja    fastex13

	 mov   ds,cs:[myselect]
         mov   [usercx],cx
         mov   [userdx],dx

	 cmp   ah,6		     ; formats are very dma boundary sensitive
	 ja    i13not46
	 cmp   ah,4		     ; stupidly enough, so are verifies!
	 jae   stage
i13not46:
         mov   dx,bx                 ; compute starting seg address
         mov   cl,4
         shr   dx,cl
         mov   cx,es
         add   dx,cx
         cmp   dh,[dmabank]          ; below switched partitions?
         jae   stage                 ; no, go do staging
         mov   cx,[usercx]           ; yes, resume normally
         mov   dx,[userdx]
fastex13:
         popf
	 pop   ds
         cli
         jmp   cs:[oldint13]         ; enter original bios
stage:
         pop   [userflag]
         push  di
         push  si

         mov   [userax],ax
         mov   [userbx],bx
         mov   [useres],es

	if	SLOW
	mov	es,[selvideo]
	xor	byte ptr es:[1],77h
	xor	byte ptr es:[3],77h
	endif

         xor   bh,bh
         mov   bl,ah
         shl   bx,1
         jmp   word ptr [int13tab+bx]
         page
;----------------------- dma read requests --------------------------;

i13nread label near
         mov   bx,512
         jmp   short i13read
i13lread label near
         mov   bx,516
         jmp   short i13read
i13sread label near
         mov   al,1
         mov   bx,512
i13read:
         push  bx                    ; save length per sector
         call  calclen               ; compute data length
         pop   bx
         jc    i13error
         cmp   ax,[buffsize]         ; check if too big for buffer
         ja    i13error

         push  bx
         mov   [iolength],ax         ; save data length

         cmp   ax,[mxlength]         ; track maximum length
         jna   i13rskp1
         mov   [mxlength],ax
i13rskp1:
         mov   es,[buffaddr]
         mov   bx,0
         mov   ax,[userax]           ; setup int 13
         mov   cx,[usercx]
         mov   dx,[userdx]
         push  [userflag]
         cli
         call  dword ptr [oldint13]
         pushf
         pop   [userflag]            ; save returned flags and ax
         mov   [userax],ax

         pop   bx                    ; recover length per sector

         test  ah,80h                ; time out?
         jnz   i13rskp2              ; yes, not safe to move data

         mov   cx,[iolength]

         mov   es,[useres]              ; move data to user area
         mov   di,[userbx]
         mov   si,0
         push  ds
         mov   ds,[buffaddr]
         shr   cx,1
         cld
         rep   movsw
         pop   ds
i13rskp2:
         jmp   i13exit
         page
;------------------- error exit for buffer overflow -----------------;

i13error label near
         or    byte ptr [userflag],01h  ; set carry for failed operation
         mov   word ptr [userax],0bb00h ; indicate undefined error in ah
         jmp   i13exit

;----------------------- dma write requests -------------------------;

i13nwrit label near
         mov   bx,512
         jmp   short i13write
i13lwrit label near
         mov   bx,516
         jmp   short i13write
i13swrit label near
         mov   al,1
         mov   bx,512
i13write:
         call  calclen               ; compute ax from bx & al
         jc    i13error
         cmp   ax,[buffsize]         ; check if too big for buffer
         ja    i13error

         push  ds
         mov   cx,ax 
         shr   cx,1
         mov   es,[buffaddr]            ; move data from user buffer
         mov   di,0
         mov   si,[userbx]
         mov   ds,[useres]
         cld
         rep   movsw
         pop   ds

i13verfy label near		     ; verify enters here
         mov   es,[buffaddr]
         mov   bx,0
         mov   ax,[userax]           ; setup int 13
         mov   cx,[usercx]
         mov   dx,[userdx]
         push  [userflag]
         cli
         call  dword ptr [oldint13]
         pushf
         pop   [userflag]            ; save returned flags and ax
         mov   [userax],ax

         jmp   i13exit
         page
i13pass  label near

	if	SLOW
	push	ds
	mov	ds,cs:[selvideo]
	xor	byte ptr ds:[1],77h
	xor	byte ptr ds:[3],77h
	pop	ds
	endif

         mov   ax,[userax]
         mov   bx,[userbx]
         mov   cx,[usercx]
         mov   dx,[userdx]
         mov   es,[useres]
         push  [userflag]
         popf
         pop   si
         pop   di
	 pop   ds
         jmp   dword ptr cs:[oldint13]

i13exit  label near

	if	SLOW
	push	ds
	mov	ds,cs:[selvideo]
	xor	byte ptr ds:[1],77h
	xor	byte ptr ds:[3],77h
	pop	ds
	endif

         mov   ax,[userax]
         mov   bx,[userbx]
         mov   cx,[usercx]
         mov   dx,[userdx]
         mov   es,[useres]
         push  [userflag]
         popf
         pop   si
         pop   di
	 pop   ds
farret13 proc  far
         ret   2
farret13 endp

calclen  proc  near
         cmp   byte ptr [userdx],80h ; hard disk?
         jae   skipflop              ; yes, skip
         mov   es,[mfazero]
         les   si,dword ptr es:[0078h] ; address diskette parm table
         mov   cl,es:[si+3]          ; load bytes/sector indicator
         mov   bx,128
         shl   bx,cl                 ; bx is now correct bytes/sector
skipflop:
         xor   ah,ah
         mul   bx
         ret
calclen  endp
         page
;--------------------------------------------------------------------;
;                         Request Handler                            ;
;--------------------------------------------------------------------;

rhentry  label near
         push  ds
         push  si

	 mov   ds,cs:[myselect]

         mov   al,ah
         cmp   al,rhtablen/2            ; invalid function codes are ignored
         jae   rhexit
         xor   ah,ah
         shl   ax,1
         mov   si,ax
         call  [rhtable+si]

rhexit   label near
         pop   si
         pop   ds
vmfarret proc  far
         ret
vmfarret endp

         even

rhtable	label word
	dw	vreboot		;  0 reboot the system
	dw	valloc		;  1 allocate extended memory
	dw	vrelease	;  2 deallocate extended memory
	dw	vremap		;  3 remap allocated memory
	dw	vunmap		;  4 unmap allocated memory
	dw	vphymap		;  5 remap physical extended memory
	dw	vprotect	;  6 write-protect memory range
	dw	vunprot		;  7 disable write protect
	dw	vsetiop		;  8 set i/o permission
	dw	vclriop		;  9 clear i/o permission
	dw	vdeclare	; 10 declare 80286 selector
	dw	vsdrange	; 11 set range for "auto" declarations
	dw	vclrauto	; 12 clear "auto" declarations
rhtablen equ	$-rhtable

         page
;--------------------------------------------------------------------;
;              Request Handler Function 00h (reboot)                 ;
;--------------------------------------------------------------------;
;                   No parameters are required.                      ;
;--------------------------------------------------------------------;

vreboot  label near

;	The plan here is to create a double fault with the double
;	fault exception handler marked "not present"; this seems to 
;	have the handy effect of causing the processor to reset.

	cli				 ; no external interrupts please
	mov	ds,[selidt]		 ; address interrupt descriptor table
	and	byte ptr ds:[8*08+5],7fh ; invalidate double-fault entry
	and	byte ptr ds:[8*11+5],7fh ; invalidate not-present entry
	and	byte ptr ds:[8*13+5],7fh ; invalidate protection exception
	int	13h			 ; push the domino....

;-------------------------- Dummy Routines --------------------------;

vprotect proc	near
vunprot  label	near
vsetiop  label	near
vclriop  label	near
	 ret
vprotect endp

         page
;--------------------------------------------------------------------;
;              Request Handler Function 01h (allocate)               ;
;--------------------------------------------------------------------;
;   If the allocation request cannot be satisfied, the largest       ;
;   available block is returned. The variable parmused is dynami-    ;
;   cally maintained to indicate how much extended memory is used.   ;
;--------------------------------------------------------------------;
;   input:  cx = number of banks desired                             ;
;   output: ax = 0 if successful, 1 if less allocated than requested ;
;           bx = starting bank number                                ;
;           cx = actual number of banks allocated                    ;
;           other registers are preserved                            ;
;--------------------------------------------------------------------;

valloc   proc  near                     ; cx is # banks requested
         push  si
         push  di
         push  dx

	 xor   bx,bx
         xor   ax,ax
         mov   [trash1],ax              ; tracks position of biggest block
         mov   [trash2],ax              ; tracks size     of biggest block
         mov   [trash3],ax              ; default return code
valloop1:
         cmp   bx,PARLIMIT              ; check for limit
         jae   valnofit
         call  addrmap                  ; address bx'th parmap bit in di:dl
         test  byte ptr [parmap+di],dl 
         jnz   valavail                 ; jump if page is available
         inc   bx                       ; bump index
         jmp   valloop1 
valavail:
         xor   ax,ax                    ; ax counts pages found
         mov   si,bx                    ; si saves starting index
valloop2:
         call  addrmap
         test  byte ptr [parmap+di],dl  ; test the entry
         jz    valnotav                 ; jump if not available
         inc   ax
         inc   bx                       ; bump index
         cmp   ax,cx                    ; got enough?
         jae   valgotit                 ; yes, jump
         cmp   bx,PARLIMIT              ; check for limit
         jb    valloop2
valnotav:
         cmp   ax,[trash2]              ; is this biggest so far?
         jna   valloop1
         mov   [trash2],ax              ; yes, save size & page number
         mov   [trash1],si
         jmp   valloop1
valnofit:
         mov   word ptr [trash3],1      ; return code for ax
         mov   ax,[trash2]              ; biggest chunk will have to do
         mov   si,[trash1]
valgotit:
         mov   cx,ax                    ; number of banks
         mov   bx,si                    ; starting bank number
         or    ax,ax
         jz    valdone
valloop3:
         call  addrmap
         xor   byte ptr [parmap+di],dl  ; flag it busy
         inc   bx
         dec   ax
         jnz   valloop3
         mov   bx,si
valdone:
         add   [parmused],cx            ; keep running tally
         mov   ax,[trash3]              ; return code

         pop   dx
         pop   di
         pop   si
         ret
valloc   endp

addrmap  proc  near
         push  cx
         mov   dl,01h
         mov   cl,bl
         and   cl,07h
         shl   dl,cl
         mov   di,bx
         mov   cl,3
         shr   di,cl
         pop   cx
         ret
addrmap  endp

         page
;--------------------------------------------------------------------;
;              Request Handler Function 02h (release)                ;
;--------------------------------------------------------------------;
;   parmused is maintained.                                          ;
;--------------------------------------------------------------------;
;   input:  bx = starting bank number to release                     ;
;           cx = number of banks                                     ;
;   output: ax = 0 if no errors                                      ;
;                1 if releasing unallocated blocks, or if cx=0       ;
;           bx,cx destroyed                                          ;
;--------------------------------------------------------------------;

vrelease proc  near 
         push  di
         push  dx
         mov   ax,1
         or    cx,cx
         jz    vrelexit
vreloop1:
         call  addrmap
         test  byte ptr [parmap+di],dl  ; test the entry
         jnz   vrelexit                 ; error if not allocated
         or    byte ptr [parmap+di],dl 
         dec   word ptr [parmused]
         inc   bx
         loop  vreloop1
         xor   ax,ax
vrelexit:
         pop   dx
         pop   di
         ret
vrelease endp

;--------------------------------------------------------------------;
;               Request Handler Function 03h (remap)                 ;
;--------------------------------------------------------------------;
;   input:  bx = starting bank number to map into meg0               ;
;           cx = number of banks                                     ;
;           es = segment address (must be multiple of granule size)  ;
;   output: ax = 0                                                   ;
;--------------------------------------------------------------------;

vremap   proc  near 
         push  bx
         push  cx
         mov   ax,bx
         mov   bx,es
         mov   bl,bh
         xor   bh,bh

         cmp   bl,[dmabank]             ; maintain lowest remapped bank
         jae   vremcont
         or    bl,bl
         jz    vremcont
         mov   [dmabank],bl
vremcont:
         call  remap
         xor   ax,ax
         pop   cx
         pop   bx
         ret
vremap   endp

         page
;--------------------------------------------------------------------;
;               Request Handler Function 04h (unmap)                 ;
;--------------------------------------------------------------------;
;   input:  cx = number of banks                                     ;
;           es = segment address (must be multiple of granule size)  ;
;   output: ax = 0                                                   ;
;--------------------------------------------------------------------;

vunmap   proc  near 
         push  es
         push  bx
         push  cx
         mov   ax,es
         mov   al,ah
         xor   ah,ah
         pushf
         cli
         call  selfmap
         popf
         xor   ax,ax
         pop   cx
         pop   bx
         pop   es
         ret
vunmap   endp

;--------------------------------------------------------------------;
;           Request Handler Function 05h (physical remap)            ;
;--------------------------------------------------------------------;
;   input:  bx = starting physical bank number to map into meg0      ;
;           cx = number of banks                                     ;
;           es = segment address (must be multiple of granule size)  ;
;   output: ax = 0                                                   ;
;--------------------------------------------------------------------;

vphymap  proc  near 
         push  bx
         push  cx
         mov   ax,bx
         mov   bx,es
         mov   bl,bh
         xor   bh,bh
         call  phymap
         xor   ax,ax
         pop   cx
         pop   bx
         ret
vphymap  endp

	page
;--------------------------------------------------------------------;
;           Request Handler Function 0Ah (Declare Segment)           ;
;--------------------------------------------------------------------;
;   input:  bx = Segment address (paragraph) being declared          ;
;           cl = 0 if data segment 				     ;
;	         1 if code segment				     ;
;	         FF to "undeclare" the segment			     ;
;   output: ax = 0                                                   ;
;--------------------------------------------------------------------;

vdeclare proc	near
	push	es
	push	bx
	push	cx
	push	si
	push	di
	mov	ax,bx

	mov	es,[selgdt]		; compute relocation factor in si
	xor	bl,bl
	mov	si,es:[bx+3]
	shr	bx,4
	sub	si,bx

	mov	bx,ax			; point es:bx to table entry
	call	addrdes

	mov	ch,al			; compute 24-bit address in ax:ch
	shl	ch,4
	shr	ax,4
	add	ax,si			; adjust using relocation factor

	cmp	cl,-1			; UNdeclare request?
	je	vdundo			; yes, jump

	cmp	byte ptr es:[bx+5],11100000b
	jae	vddup			; jump if already declared
	mov	es:[bx+2],ch		; plug in the relocated address
	mov	es:[bx+3],ax
	and	byte ptr es:[bx+5],11110111b ; make it a data selector
	or	cl,cl			; code segment?
	jz	vdecdone		; no, skip
	or	byte ptr es:[bx+5],00001000b ; yes, make it executable
vdecdone:
	or	byte ptr es:[bx+5],01100000b ; set dpl=3 
	and	byte ptr es:[bx+6],11111000b ; clear "auto" flag
	jmp	short vdcmain
vddup:
	cmp	es:[bx+2],ch		; address matches?
	je	vdwrap			; yes, just exit
					; no, remove the declare
vdundo:
	and	byte ptr es:[bx+5],10010111b ; set dpl=0,type=data

;	Remove UNdeclared entry from chain

	mov	es,[selldt]		; make sure neither entry is needed
	test	byte ptr es:[bx+5],01100000b
	jnz	vdwrap
	mov	es,[selgdt]		; chain exists only in the gdt
	test	byte ptr es:[bx+5],01100000b
	jnz	vdwrap
	mov	di,bx			; di saves this entry index
	xor	bl,bl			; point bx to entry for 4k boundary
vduloop:
	mov	si,bx			; si tracks "previous" entry
	mov	bx,es:[si+6]		; bx tracks "next" entry
	and	bl,11111000b
	cmp	bx,di			; are we pointing to it yet?
	jb	vduloop			; no, keep looking
	ja	vdwrap			; exit if we pass it (always true if
					;   it's the 4K boundary entry)
	mov	ax,0007h
	mov	bx,es:[di+6]		; point previous entry to new entry
	and	bl,11111000b		;  while preserving bits 0-2 
	and	word ptr es:[si+6],ax
	or	es:[si+6],bx
	and	word ptr es:[di+6],ax	; just cosmetic cleanup
	jmp	short vdwrap

;	Add declared entry to the chain

vdcmain	label	near
	mov	es,[selgdt]		; chain exists only in the gdt
	mov	di,bx			; di saves this entry index
	xor	bl,bl			; point bx to entry for 4k boundary
	jmp	short vdentry
vdloop:
	mov	si,bx			; si tracks "previous" entry
	mov	bx,es:[si+6]		; bx tracks "next" entry
	and	bl,11111000b
vdentry:
	cmp	bx,di			; are we pointing past it yet?
	jb	vdloop
	je	vdwrap			; exit if new entry already in chain

	mov	ax,0007h
	and	es:[di+6],ax
	or	es:[di+6],bx		; point new entry to next entry
	and	es:[si+6],ax
	or	es:[si+6],di		; point previous entry to new entry
vdwrap:
	xor	ax,ax
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	es
	ret
vdeclare endp

;--------------------------------------------------------------------;
;           Request Handler Function 0Bh (Set Dynamic Range)         ;
;--------------------------------------------------------------------;
;   input:  bx = Starting segment address 			     ;
;           cx = Segment length (in paragraphs)			     ;
;   output: ax = 0                                                   ;
;--------------------------------------------------------------------;

vsdrange proc	near
	mov	ax,bx
	mov	[dabegin],ax
	add	ax,cx
	mov	[daend],ax
	xor	ax,ax
	ret
vsdrange endp

;--------------------------------------------------------------------;
;           Request Handler Function 0Ch (Clear "auto" declares)     ;
;--------------------------------------------------------------------;
;   input:  nothing						     ;
;   output: ax = 0                                                   ;
;--------------------------------------------------------------------;

vclrauto proc	near
	call	autodel			; purge "auto" entries from tables
	call	resetin			; reset timer and exception counters
	add	[newtime],TIME1		; effect the startup-delay interval
	mov	[fastmode],'S'		; force slow mode
	mov	[cscount],0		; disable zapping of code selectors
	xor	ax,ax
	ret
vclrauto endp

	page
;--------------------------------------------------------------------;
;        Remapping routine.  bx is starting logical page number,     ;
;        ax is starting physical page (ah is megabytes), cx is       ;
;        number of pages to be mapped.  remember that a page is      ;
;        4k bytes (1000 hex) in length.                              ;
;--------------------------------------------------------------------;

smret	label	near
	ret

selfmap	proc	near
	mov	ah,0
	mov	bx,ax

remap	label	near
phymap	label	near

	if	DEBUG
	push	ax
	mov	es,[selvideo]
	mov	di,8
	call	disphex
	mov	al,ah
	call	disphex
	mov	al,bl
	call	disphex
	mov	al,bh
	call	disphex
	mov	al,cl
	call	disphex
	mov	al,ch
	call	disphex
	pop	ax
	endif

	jcxz	smret			; just in case of "null" remap

	pushf
	push	es
	push	ds
	push	dx

	cli

	mov	es,[selldt]
	mov	ds,[selgdt]
	sub	ax,bx			; convert ax to a relocation factor
	shl	ax,4			; and make it a multiple of 256 bytes
	shl	bx,8			; make bx a multiple of 16 bytes
	shl	cx,8			; convert cx to a stop address
	add	cx,bx
	jnz	smloop
	sub	cx,8			; use FFF8 if wrap to 0
smloop:
	and	bl,11111000b
	mov	dx,bx			; compute dx = address bits 8-23
	shr	dx,4
	add	dx,ax
	mov	ds:[bx+3],dx		; relocated address bits to gdt/ldt
	mov	es:[bx+3],dx
	mov	bx,[bx+6]		; load next pointer
	cmp	bx,cx
	jb	smloop

	pop	dx
	pop	ds

;---------- Must invalidate selector cache after any remap ----------;

	push	di			; save scratch register

	push	ds			; es:di indexes cache table
	pop	es
	mov	di,offset selcache
	mov	ax,0fffeh
	mov	bx,6
	cld

	stosw				; do this 16 times (80 clock cycles)
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw
	add	di,bx
	stosw

	pop	di
	pop	es
	popf
	ret
selfmap	endp

         page
;--------------------------------------------------------------------;
;                    turn on address bit 20 gate                     ;
;--------------------------------------------------------------------;

bit20on  proc  near
         push  ax
         cli
         call  clr8042
         mov   al,0d1h
         out   64h,al
         call  clr8042
         mov   al,0dfh
         out   60h,al
         call  clr8042
skip8042:
         pop   ax
         ret
bit20on  endp

clr8042  proc  near
         in    al,064h               ; read status port
         and   al,02h                ; loop until buffer empty
         jnz   clr8042
         ret
clr8042  endp

;--------------------------------------------------------------------;
;                     binary-to-decimal routine                      ;
;--------------------------------------------------------------------;

bintodec proc  near
         push  cx
btdloop1:
         div   word ptr [wordten]    ; dx:ax is source integer
         add   dl,'0'                ; cx is length of target
         mov   [bx],dl               ; bx is end of target
         dec   bx
         xor   dx,dx
         loop  btdloop1
         pop   cx
btdloop2:
         inc   bx
         dec   cx
         jz    btdret
         cmp   byte ptr [bx],'0'
         jne   btdret
         mov   byte ptr [bx],' '
         jmp   btdloop2
btdret:
         ret
bintodec endp

	page
;--------------------------------------------------------------------;
;                      Abnormal Termination                          ;
;--------------------------------------------------------------------;

badint	label	near			; error exit 
	call	trace
	jmp	$

entint06 label	near
	call	trace
	jmp	$

;--------------------------------------------------------------------;
;              Protection exception interrupt entry                  ;
;--------------------------------------------------------------------;

entint0d label	near			; enter here 
	cmp	sp,offset p0error   	; was an error code supplied?
	jne	normi13			; no, jump

	mov	sp,offset laax+2	; save user's general registers
	pusha				;   with "pusha" instruction
	push	es			; also save user's es and ds
	mov	sp,offset lads+2
	push	ds
	mov	sp,offset p0error	; recover stack pointer

;	Of course there is more to save into the loadall data area,
;	but at least anything else we might need is saved SOMEwhere.

	mov	si,base-mainseg		; si is a constant index value

;	Throughout the following code are many occurrences of the form
;	[label-base+si].  These have the same effect as just specifying
;	[label], except that we are taking advantage of the fact that
;	it is possible to have a 1-byte displacement when an index
;	register is used, thereby shortening instructions and execution
;	time.

	mov	ax,ss			; address main data segment
	mov	ds,ax
	mov	es,ax

	pop	ax			; get error code in ax
	or 	ax,ax			; reference using zero segment?
	jz 	jrefzero		; yes, jump 
	test	al,03h			; segment load exception?
	jnz	badint			; no, something is wrong

;------------- Segment Load Exception - Vector by Opcode ------------;

	mov	ax,[p0cs]		; compute user's code address in bl:ax

	mov	bx,ax			; do fast version of call getadr3
	xor	bl,bh
	and	bx,0078h
	cmp	ax,[selcache+bx]
	jne	slcsno
	mov	ax,[selcache+2+bx]
	mov	bx,[selcache+4+bx]
slcsok:
	mov	es,[selgdt-base+si]
	mov	word ptr es:[gdtwork-gdt+2],ax
	mov	byte ptr es:[gdtwork-gdt+4],bl
revector:				; reenter here after segment override
	mov	di,[p0ip-base+si]
	mov	es,[selwork-base+si]	; es:di addresses the opcode
	mov	cx,es:[di]		; ch saves 2nd instruction byte
	mov	bp,es:[di+2]		; bp saves 3rd & 4th instruction bytes

	mov	bl,cl
	xor	bh,bh
	shl	bx,1
	jmp	[optable+bx]
jrefzero:
	jmp	short refzero
slcsno:
	call	g3cont
	jmp	slcsok

	page
;------------------ Process a "Normal" Interrupt --------------------;

normi13	label	near
	mov	sp,offset laax+2	; duplicate entry code from above
	pusha
	push	es
	mov	sp,offset lads+2
	push	ds
	mov	si,base-mainseg
	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	mov	sp,offset p0ip 

	mov	di,13*4			; identify the interrupt to emulate

normint	label	near
	mov	ax,[p0ss]		; address user's stack 
	call	getadr3
	mov	es,[selgdt-base+si]
	mov	word ptr es:[gdtwork-gdt+2],ax
	mov	byte ptr es:[gdtwork-gdt+4],bl
	mov	es,[selwork-base+si]
	mov	bx,[p0sp-base+si]		; es:bx is it

	sub	bx,6			; put flags,cs,ip on user's stack
	mov	ax,[p0flags]
	mov	es:[bx+4],ax
	mov	ax,[p0cs]
	mov	es:[bx+2],ax
	mov	ax,[p0ip-base+si]
	mov	es:[bx],ax

	mov	[p0sp-base+si],bx	; set new sp for user

	mov	es,[selzero-base+si]
	mov	ax,es:[di]		; set new cs:ip from interrupt vector
	mov	[p0ip-base+si],ax
	mov	ax,es:[di+2]
	mov	[p0cs],ax

	and	byte ptr [p0flags+1-base+si],11111101b	; disable interrupts
	jmp	resume

;--------------------------------------------------------------------;
;     Handle situations where memory reference might have used       ;
;     a null selector, or memory write may have been attempted       ;
;     using a code selector (cs override or cs value loaded into     ;
;     a data segment register).  In particular, some adjustments     ;
;     must be made if a string instruction is to be restarted.       ;
;--------------------------------------------------------------------;

refzero	label	near
	mov	ax,[p0cs]		; compute instruction address
	call	getadr3
	mov	es,[selgdt-base+si]
	mov	word ptr es:[gdtwork-gdt+2],ax
	mov	byte ptr es:[gdtwork-gdt+4],bl
	mov	di,[p0ip-base+si]
	mov	es,[selwork-base+si]	; es:di addresses the instruction
	mov	cx,es:[di]		; grab 2 code bytes

	xor	dx,dx			; dx=0 means no prefix
	cmp	cl,0f2h			; rep prefix used?
	je	rzrep			; yes, jump
	cmp	cl,0f3h
	jne	rztest
rzrep:
	mov	cl,ch			; cl is "main" opcode (not a prefix)
	inc	dx			; dx=1 means rep prefix is present
rztest:
	mov	al,cl
	and	al,11111110b		; remove size bit

	cmp	al,0a4h			; movs?
	je	rzmovs
	cmp	al,0a6h			; cmps?
	je	rzcmps
	cmp	al,0aah			; stos?
	je	rzstos
	cmp	al,0ach			; lods?
	je	rzlods
	cmp	al,0aeh			; scas?
	je	rzscas

	jmp	resume

rzlods	label	near
	call	rzcalc			; lods - adjust si and maybe cx
	add	[lasi-base+si],ax
	shl	dx,1
	add	[lacx-base+si],dx
	jmp	resume

rzstos	label	near
	call	rzcalc			; stos - adjust di and maybe cx
	add	[ladi-base+si],ax
	shl	dx,1
	add	[lacx-base+si],dx
	jmp	resume

rzscas	label	near
	call	rzcalc			; scas - adjust si and maybe cx
	add	[lasi-base+si],ax
	shl	dx,1
	add	[lacx-base+si],dx
	jmp	resume

rzmovs	label	near
	call	rzcalc			; movs - adjust si, maybe di, maybe cx
	add	[lasi-base+si],ax
	add	[lacx-base+si],dx
	test	[lads-base+si],0fffch	; did source cause the exception?
	jz	rzmovsx			; yes, then we are done
	add	[ladi-base+si],ax	; no, must fix destination index
	add	[lacx-base+si],dx	; and count again
rzmovsx:
	jmp	resume

rzcmps	label	near
	call	rzcalc			; cmps - adjust di, maybe si, maybe cx
	add	[ladi-base+si],ax
	test	word ptr [laes-base+si],0fffch ; did es cause the exception?
	jz	rzcmpsx			; yes, then we are done
	add	[lasi-base+si],ax	; no, must fix si
	add	[lacx-base+si],dx	; and count (if repeated)
rzcmpsx:
	jmp	resume
	
rzcalc	proc	near
	mov	al,cl			; extract size bit from opcode
	and	ax,1
	inc	ax			; 1=byte, 2=word
	test	byte ptr [p0flags+1-base+si],4	; direction flag set?
	jnz	rzcalcx			; yes, we're done
	neg	ax			; no, negate it
rzcalcx:
	ret
rzcalc	endp

	page
;--------------------------------------------------------------------;
;                     Timer 0 Interrupt Entry                        ;
;--------------------------------------------------------------------;
;  For displaying sampled exceptions, we want to make sure we see    ;
;  the timer interrupts before anybody else -- the idea is to keep   ;
;  from excessively "sampling" any logic triggered by MOS's timer    ;
;  handler... this would be a big problem if we just wait for the    ;
;  timer count to change when processing protection exceptions.      ;
;--------------------------------------------------------------------;

entint08 label	near
	mov	sp,offset laax+2	; standard entry code
	pusha
	push	es
	mov	sp,offset lads+2
	push	ds
	mov	si,base-mainseg
	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	mov	sp,offset p0ip 

	if	LIGHTS
	xor	ax,ax
	xchg	ax,[trtally]
	or	ax,ax
	jz	light4			; jump if no exceptions
	shr	ax,3
	cmp	ax,00011111b		; if beyond max, turn on all 5 lights
	jb	light0
	mov	al,00011111b
light0:
	cmp	byte ptr [fastmode-base+si],'F'	; if fast mode
	jne	light1
	or	al,10000000b
light1:
	cmp	byte ptr [trreason-base+si],'1'	; if unusable selector
	jne	light2
	or	al,01000000b
light2:
	cmp	byte ptr [trtype-base+si],'C'	; if code selector exception
	jne	light3
	or	al,00100000b
light3:
	mov	[litally],36
	jmp	short lightout
light4:
	cmp	[litally],0
	jne	lightny
	ror	[litbits],1
	mov	ax,[litbits]
lightout:
	mov	dx,3bch			; parallel port address
	out	dx,al
	inc	[litally]
lightny:
	dec	[litally]
	endif

	mov	di,08*4			; identify the interrupt to emulate
	jmp	normint

	page
;---------------------- Fix Descriptors and Resume ------------------;

resdsno	label	near
	call	g3cont
	jmp	short resdsbak

resesno	label	near
	call	g3cont
	jmp	short resesbak

resssno	label	near
	call	g3cont
	jmp	short resssbak

;-------------------- Resume logic begins here ----------------------;

resume 	label	near
	mov	dx,0078h		; to speed up calculations below
	mov	di,offset selcache

;----------------------- Process DS register ------------------------;

	mov	ax,[lads]
	mov	bx,ax			;  2  \ 
	xor	bl,bh			;  2    \
	and	bx,dx			;  2      \   This is less than 1/3
	cmp	ax,[di+bx]		;  7       >  the time required if
	jne	resdsno			;  3      /   not using the cache...
	mov	ax,[di+bx+2]		;  5    /
	mov	bx,[di+bx+4]		;  5  /
resdsbak:
	mov	word ptr [ladsdc],ax
	mov	byte ptr [ladsdc+2-base+si],bl

;----------------------- Process ES register ------------------------;

	mov	ax,[laes]
	mov	bx,ax			; randomize to get cache index 
	xor	bl,bh
	and	bx,dx
	cmp	ax,[di+bx]		; is desired selector already cached?
	jne	resesno			; no, jump
	mov	ax,[di+bx+2]		; yes, we have a fast answer
	mov	bx,[di+bx+4]
resesbak:
	mov	word ptr [laesdc],ax
	mov	byte ptr [laesdc+2-base+si],bl

;----------------------- Process SS register ------------------------;

	mov	ax,[p0ss]
	mov	[lass],ax
	mov	bx,ax			; randomize to get cache index 
	xor	bl,bh
	and	bx,dx
	cmp	ax,[di+bx]		; is desired selector already cached?
	jne	resssno			; no, jump
	mov	ax,[di+bx+2]		; yes, we have a fast answer
	mov	bx,[di+bx+4]
resssbak:
	mov	word ptr [lassdc],ax
	mov	byte ptr [lassdc+2-base+si],bl

;----------------------- Process CS register ------------------------;

	mov	ax,[p0cs]

;	Translate ax from code selector table, if appropriate;
;	note that cx, di, and es are trashed

	mov	cx,[cscount-base+si]	; get number of active table entries
	jcxz	rescs2			; skip if empty table
	push	di
	mov	es,[seldata-base+si] 
	mov	di,offset cstab1
	cld
	repne	scasw			; scan cstab1 for a matching entry
	jne	rescs1			; skip if none
	mov	ax,[di+cstab2-cstab1-2] ; load FFxx selector from cstab2
rescs1:
	pop	di
rescs2:

;	End of code selector translation

	mov	[lacs],ax
	mov	bx,ax			; randomize to get cache index 
	xor	bl,bh
	and	bx,dx
	cmp	ax,[di+bx]		; is desired selector already cached?
	jne	rescsno			; no, jump
	mov	ax,[di+bx+2]		; yes, we have a fast answer
	mov	bx,[di+bx+4]
rescsbak:
	mov	word ptr [lacsdc],ax
	mov	byte ptr [lacsdc+2-base+si],bl

;	test	bh,08h			; is this a code segment with dpl=3?
;	jz	resback			; no, jump
;	or	byte ptr [lacs-base+si],03h ; set rpl=3 if code selector
;resback:

;------------------- Process IP, SP, Flags and Exit -----------------;

	mov	ax,[p0ip-base+si]
	mov	[laip],ax

	mov	ax,[p0sp]
	mov	[lasp],ax

	mov	ax,[p0flags]
	or	ah,00110000b			; make sure iopl=3
	and	ah,10111111b			; clear nested-task flag
	mov	[laflags],ax

	mov	byte ptr [override-base+si],'N' ; clear seg-override switch
	db	0fh,05h				; execute loadall instruction

;------------------- Fix CS descriptor and resume -------------------;

rescsno	label	near
	call	g3cont
	jmp	rescsbak

	page
;------------------ mov segreg,mem/reg instructions -----------------;

op8e	label	near
	call	ambdcode		; get data in ax and update ip
	test	ch,00010000b		; ss or ds?
	jnz	op8essds		; yes, jump
	mov	[laes],ax
	jmp	short op8ex
op8essds:
	test	ch,00001000b		; ds?
	jnz	op8eds			; yes, jump
	mov	[p0ss],ax
	jmp	short op8ex
op8eds:
	mov	[lads],ax
op8ex:
	call	dtmaint			; descriptor table maintenance
	jmp	resume

;-------------------- Indirect far CALLs and JMPs -------------------;

opff	label	near
	mov	bl,ch
	and	bx,0038h
	shr	bx,2
	jmp	word ptr [optff+bx]

	even
optff   label   word
        dw	opmisc   ; ff  inc  mem/reg (word)
        dw	opmisc   ; ff  dec  mem/reg (word)
        dw	opmisc   ; ff  call mem/reg (Near Indirect)
        dw	opcallfi ; ff  call mem     (Far Indirect)
        dw	opmisc   ; ff  jmp  mem/reg (Near Indirect)
        dw	opjumpfi ; ff  jmp  mem     (Far Indirect)
        dw	opmisc   ; ff  push mem
        dw	opmisc   ; ff  Invalid

	page
;--------------------- Segment override prefixes --------------------;

opsegds	label	near
	mov	ax,[lads]
	jmp	short opseg

opseges	label	near
	mov	ax,[laes]
	jmp	short opseg

opsegss	label	near
	mov	ax,[p0ss]
	jmp	short opseg

opsegcs	label	near
	mov	ax,[p0cs]
opseg:
	mov	[overseg],ax
	mov	byte ptr [override-base+si],'Y'
	inc	word ptr [p0ip-base+si]
	jmp	revector

;--------------------- pop segreg instructions ----------------------;

oppopes	label	near
	call	pop
	mov	[laes],ax
	jmp	resume

oppopds	label	near
	call	pop
	mov	[lads],ax
	jmp	resume

oppopss	label	near
	call	pop
	mov	[p0ss],ax
	jmp	resume

pop	proc	near
	mov	ax,[p0ss]		; address user's stack 
	call	getadr3
	mov	es,[selgdt-base+si]
	mov	word ptr es:[gdtwork-gdt+2],ax
	mov	byte ptr es:[gdtwork-gdt+4],bl
	mov	bx,[p0sp-base+si]	; ds:bx is it
	mov	es,[selwork-base+si]
	mov	ax,es:[bx]
	add	word ptr [p0sp-base+si],2
	inc	word ptr [p0ip-base+si]
	call	dtmaint			; descriptor table maintenance
	ret
pop	endp

	page
;--------------- Intersegment CALLs, JMPs, RETs, IRET ---------------;

opcallfd label	near
	call	callpush		; do stack updates except ip
	mov	ax,[p0ip-base+si]	; update ip to user stack
	add	ax,5
	mov	es:[bx],ax

opjumpfd label	near
	mov	es,[selwork-base+si]	; es:di points to instruction
	mov	ax,es:[di+1]		; set new cs:ip from immediate data
	mov	[p0ip-base+si],ax
	mov	ax,es:[di+3]
	mov	[p0cs],ax

	mov	cx,[cscount-base+si]	; see if ax is in code selector table
	jcxz	ojfdbye			; skip if empty table
	mov	bx,di			; save instruction address in bx
	mov	es,[seldata-base+si] 
	mov	di,offset cstab1
	cld
	repne	scasw
	jne	ojfdbye			; jump if no matching entry
	mov	ax,[di+cstab2-cstab1-2] ; get corresponding pm selector
	mov	es,[selwork-base+si]
	mov	es:[bx+3],ax		; zap it into the jmp instruction
ojfdbye:

	call	dtmcode
	jmp	resume

opcallfi label	near
	call	callpush		; do stack updates except ip
	push	es
	push	bx
	call	ambdcode		; get new ip,cs values in ax,dx...
					; selwork:di point to the doubleword
	xchg	[p0ip-base+si],ax	; now ax points after the call
	pop	bx
	pop	es
	mov	es:[bx],ax		; complete stack update
	mov	ax,dx			; new cs is in ax
	mov	[p0cs],ax

	mov	cx,[cscount-base+si]	; see if ax is in code selector table
	jcxz	ocfibye			; skip if empty table
	mov	bx,di			; save offset to doubleword in bx
	mov	es,[seldata-base+si] 
	mov	di,offset cstab1
	cld
	repne	scasw
	jne	ocfibye			; jump if no matching entry
	mov	ax,[di+cstab2-cstab1-2] ; get corresponding pm selector
	mov	es,[selwork-base+si]
	mov	es:[bx+2],ax		; zap it into the call operand
ocfibye:

	call	dtmcode
	jmp	resume

opjumpfi label	near
	call	ambdcode		; get new ip,cs values
	mov	[p0ip-base+si],ax
	mov	ax,dx
	mov	[p0cs],ax

	mov	cx,[cscount-base+si]	; see if ax is in code selector table
	jcxz	ojfibye			; skip if empty table
	mov	bx,di			; save offset to doubleword in bx
	mov	es,[seldata-base+si] 
	mov	di,offset cstab1
	cld
	repne	scasw
	jne	ojfibye			; jump if no matching entry
	mov	ax,[di+cstab2-cstab1-2] ; get corresponding pm selector
	mov	es,[selwork-base+si]
	mov	es:[bx+2],ax		; zap it into the jmp operand
ojfibye:

	call	dtmcode
	jmp	resume

callpush proc	near
	mov	ax,[p0ss]		; address user's stack 
	call	getadr3
	mov	es,[selgdt-base+si]
	mov	word ptr es:[gdtscum-gdt+2],ax
	mov	byte ptr es:[gdtscum-gdt+4],bl
	mov	es,[selscum-base+si]
	mov	bx,[p0sp-base+si]	; es:bx is it
	sub	bx,4			; put "resume" cs,ip on user's stack
	mov	ax,[p0cs]
	mov	es:[bx+2],ax
	mov	[p0sp-base+si],bx	; set new sp for user
	ret
callpush endp

	page
opretf	label	near
	mov	ax,[p0ss]		; address user's stack 
	call	getadr3
	mov	es,[selgdt-base+si]
	mov	word ptr es:[gdtscum-gdt+2],ax
	mov	byte ptr es:[gdtscum-gdt+4],bl
	mov	es,[selscum-base+si]
	mov	bx,[p0sp-base+si]	; es:bx is it
	add	word ptr [p0sp-base+si],4
	jmp	short opretx

opretf3	label	near
	mov	ax,[p0ss]		; address user's stack 
	call	getadr3
	mov	es,[selgdt-base+si]
	mov	word ptr es:[gdtscum-gdt+2],ax
	mov	byte ptr es:[gdtscum-gdt+4],bl
	mov	es,[selscum-base+si]
	mov	bx,[p0sp-base+si]	; es:bx is it
	mov	ax,bp			; compute sp adjustment
	mov	ah,al
	mov	al,ch
	add	ax,4
	add	[p0sp],ax
	jmp	short opretx

opiret	label	near
	mov	ax,[p0ss]		; address user's stack 
	call	getadr3
	mov	es,[selgdt-base+si]
	mov	word ptr es:[gdtscum-gdt+2],ax
	mov	byte ptr es:[gdtscum-gdt+4],bl
	mov	es,[selscum-base+si]
	mov	bx,[p0sp-base+si]	; es:bx is it
	add	word ptr [p0sp-base+si],6
	mov	ax,es:[bx+4]
	mov	[p0flags],ax
opretx:
	mov	ax,es:[bx]
	mov	[p0ip-base+si],ax
	mov	ax,es:[bx+2]
	mov	[p0cs],ax
	call	dtmcode
	jmp	resume

	page
;----------------------------- lds, les -----------------------------;

oplds	label	near
	call	ambdcode		; get operands in ax/dx and update ip
	mov	[lads-base+si],dx	; value for ds
	mov	bl,ch			; compute index in bx
	shr	bl,2
	and	bx,000eh		; extract reg bits
	neg	bx
	mov	[laax+bx],ax		; value for general register
	mov	ax,dx
	call	dtmaint			; descriptor table maintenance
	jmp	resume

oples	label	near
	call	ambdcode		; get operands in ax/dx and update ip
	mov	[laes-base+si],dx	; value for es
	mov	bl,ch			; compute index in bx
	shr	bl,2
	and	bx,000eh		; extract reg bits
	neg	bx
	mov	[laax+bx],ax		; value for general register
	mov	ax,dx
	call	dtmaint			; descriptor table maintenance
	jmp	resume

;------ Segment load exception is not a recognized instruction ------;

opmisc	label	near
	jmp	refzero			; just restart the instruction

	page
;--------------------------------------------------------------------;
;  Decode addressing mode byte in ch; returns the first word of the  ;
;  operand in ax, second word (if memory operand) in dx.  This       ;
;  routine is designed to work with lds, les, indirect far jumps     ;
;  and calls, and "mov segreg,mem/reg" type instructions.  All of    ;
;  these use word or doubleword data operands.                       ;
;--------------------------------------------------------------------;
;  Input:  ch = addressing mode byte                                 ;
;          bp = 3rd and 4th instruction bytes (displacement)         ;
;          override, overseg, laax-ladi, lads, p0ss                  ;
;                                                                    ;
;  Output: ax = first operand word                                   ;
;          dx = second operand word if memory addressing             ;
;          p0ip = updated to point to next instruction               ;
;          bx,cl,di destroyed                                        ;
;--------------------------------------------------------------------;

ambdcode proc	near

	mov	bl,ch
	mov	bh,bl
	and	bx,1100000000000111b
	rol	bx,3			; bx bits 4-0 are r/m followed by mod
	xor	di,di			; di accumulates the offset
	jmp	word ptr [bx+ambtable]

	even
ambtable label	word

	dw	offset ambbxsi0		; 000 00 = [bx+si]
	dw	offset ambbxsi1		; 000 01 = [bx+si+d8]
	dw	offset ambbxsi2		; 000 10 = [bx+si+d16]
	dw	offset ambax		; 000 11 = ax

	dw	offset ambbxdi0		; 001 00 = [bx+di]
	dw	offset ambbxdi1		; 001 01 = [bx+di+d8]
	dw	offset ambbxdi2		; 001 10 = [bx+di+d16]
	dw	offset ambcx		; 001 11 = cx

	dw	offset ambbpsi0		; 010 00 = [bp+si]
	dw	offset ambbpsi1		; 010 01 = [bp+si+d8]
	dw	offset ambbpsi2		; 010 10 = [bp+si+d16]
	dw	offset ambdx		; 010 11 = dx

	dw	offset ambbpdi0		; 011 00 = [bp+di]
	dw	offset ambbpdi1		; 011 01 = [bp+di+d8]
	dw	offset ambbpdi2		; 011 10 = [bp+di+d16]
	dw	offset ambbx		; 011 11 = bx

	dw	offset ambsi0  		; 100 00 = [si]
	dw	offset ambsi1  		; 100 01 = [si+d8]
	dw	offset ambsi2  		; 100 10 = [si+d16]
	dw	offset ambsp		; 100 11 = sp

	dw	offset ambdi0  		; 101 00 = [di]
	dw	offset ambdi1  		; 101 01 = [di+d8]
	dw	offset ambdi2  		; 101 10 = [di+d16]
	dw	offset ambbp		; 101 11 = bp

	dw	offset amb2    		; 110 00 = d16
	dw	offset ambbp1  		; 110 01 = [bp+d8]
	dw	offset ambbp2  		; 110 10 = [bp+d16]
	dw	offset ambsi		; 110 11 = si

	dw	offset ambbx0  		; 111 00 = [bx]
	dw	offset ambbx1  		; 111 01 = [bx+d8]
	dw	offset ambbx2  		; 111 10 = [bx+d16]
	dw	offset ambdi		; 111 11 = di

	page

;------------------------- Register forms ---------------------------;

ambax 	label	near
	add	word ptr [p0ip-base+si],2
	mov	ax,[laax]
	ret

ambbx 	label	near
	add	word ptr [p0ip-base+si],2
	mov	ax,[labx]
	ret

ambcx 	label	near
	add	word ptr [p0ip-base+si],2
	mov	ax,[lacx]
	ret

ambdx 	label	near
	add	word ptr [p0ip-base+si],2
	mov	ax,[ladx]
	ret

ambsp 	label	near
	add	word ptr [p0ip-base+si],2
	mov	ax,[lasp]
	ret

ambbp 	label	near
	add	word ptr [p0ip-base+si],2
	mov	ax,[labp]
	ret

ambsi 	label	near
	add	word ptr [p0ip-base+si],2
	mov	ax,[lasi]
	ret

ambdi 	label	near
	add	word ptr [p0ip-base+si],2
	mov	ax,[ladi]
	ret

	page
;-------------- Addressing forms not using si, di, or bp ------------;

amb2  	label	near
	add	word ptr [p0ip-base+si],4
	add	di,bp
	mov	ax,[lads]
	jmp	ambmemx

ambbx0	label	near
	add	word ptr [p0ip-base+si],2
	add	di,[labx-base+si]
	mov	ax,[lads]
	jmp	ambmemx

ambbx1	label	near
	add	word ptr [p0ip-base+si],3
	mov	ax,bp
	cbw
	add	di,ax
	add	di,[labx-base+si]
	mov	ax,[lads]
	jmp	ambmemx

ambbx2	label	near
	add	word ptr [p0ip-base+si],4
	add	di,bp
	add	di,[labx-base+si]
	mov	ax,[lads]
	jmp	ambmemx

;--------------- Addressing forms using si but not bp ---------------;

ambbxsi0 label	near
	add	di,[labx-base+si]
	jmp	short ambsi0

ambbxsi1 label	near
	add	di,[labx-base+si]
	jmp	short ambsi1

ambbxsi2 label	near
	add	di,[labx-base+si]
	jmp	short ambsi2

ambsi0	label	near
	add	word ptr [p0ip-base+si],2
	add	di,[lasi-base+si]
	mov	ax,[lads]
	jmp	ambmemx

ambsi1	label	near
	add	word ptr [p0ip-base+si],3
	mov	ax,bp
	cbw
	add	di,ax
	add	di,[lasi-base+si]
	mov	ax,[lads]
	jmp	ambmemx

ambsi2	label	near
	add	word ptr [p0ip-base+si],4
	add	di,bp
	add	di,[lasi-base+si]
	mov	ax,[lads]
	jmp	ambmemx

	page
;--------------- Addressing forms using di but not bp ---------------;

ambbxdi0 label	near
	add	di,[labx-base+si]
	jmp	short ambdi0

ambbxdi1 label	near
	add	di,[labx-base+si]
	jmp	short ambdi1

ambbxdi2 label	near
	add	di,[labx-base+si]
	jmp	short ambdi2

ambdi0	label	near
	add	word ptr [p0ip-base+si],2
	add	di,[ladi-base+si]
	mov	ax,[lads]
	jmp	ambmemx

ambdi1	label	near
	add	word ptr [p0ip-base+si],3
	mov	ax,bp
	cbw
	add	di,ax
	add	di,[ladi-base+si]
	mov	ax,[lads]
	jmp	ambmemx

ambdi2	label	near
	add	word ptr [p0ip-base+si],4
	add	di,bp
	add	di,[ladi-base+si]
	mov	ax,[lads]
	jmp	ambmemx

;-------------------- Addressing forms using bp ---------------------;

ambbpsi0 label	near
	add	di,[lasi-base+si]
	jmp	short ambbp0

ambbpsi1 label	near
	add	di,[lasi-base+si]
	jmp	short ambbp1

ambbpsi2 label	near
	add	di,[lasi-base+si]
	jmp	short ambbp2

ambbpdi0 label	near
	add	di,[ladi-base+si]
	jmp	short ambbp0

ambbpdi1 label	near
	add	di,[ladi-base+si]
	jmp	short ambbp1

ambbpdi2 label	near
	add	di,[ladi-base+si]
	jmp	short ambbp2

ambbp0	label	near
	add	word ptr [p0ip-base+si],2
	add	di,[labp-base+si]
	mov	ax,[p0ss]
	jmp	ambmemx

ambbp1	label	near
	add	word ptr [p0ip-base+si],3
	mov	ax,bp
	cbw
	add	di,ax
	add	di,[labp-base+si]
	mov	ax,[p0ss]
	jmp	ambmemx

ambbp2	label	near
	add	word ptr [p0ip-base+si],4
	add	di,bp
	add	di,[labp-base+si]
	mov	ax,[p0ss]
	jmp	ambmemx

	page
;----------------- Wrap up memory addressing forms ------------------;

ambmemx label	near
	cmp	byte ptr [override-base+si],'Y'
	jne	ambmx1
	mov	ax,[overseg]
	mov	byte ptr [override-base+si],'N'
ambmx1:
	call	getadr3
	mov	es,[selgdt-base+si]
	mov	word ptr es:[gdtwork-gdt+2],ax
	mov	byte ptr es:[gdtwork-gdt+4],bl
	mov	es,[selwork-base+si]
	mov	ax,es:[di]
	mov	dx,es:[di+2]
	ret

ambdcode endp

	page
;--------------------------------------------------------------------;
;                     Descriptor Table Maintenance                   ;
;--------------------------------------------------------------------;

dtmaint	proc	near
	cmp	byte ptr [wsmaint],'Y'  ; are we collecting info?
	jne	dtmret			; no, fast exit
	push	dx

	if	SLOW+DEBUG
	mov	byte ptr [trtype-base+si],'D' ; for trace
	endif

	mov	dh,0			; indicate data selector
	jmp	short dtmcont

dtmcode	label	near
	cmp	byte ptr [wsmaint],'Y'  ; are we collecting info?
	jne	dtmret			; no, fast exit
	push	dx

	if	SLOW+DEBUG
	mov	byte ptr [trtype-base+si],'C' ; for trace
	endif

	mov	dh,1			; indicate code selector
	jmp	short dtmcont
dtmret:
	ret
dtmcont:
	push	es
	push	bx
	push	ax

	if	SLOW+DEBUG
	mov	[trsegadr-base+si],ax		; save selector for trace
	mov	byte ptr [trreason-base+si],'O' ; for trace
	endif

	cmp	ax,[dabegin-base+si]	; check if inside "dynamic area"
	jb	dtmaine
	cmp	ax,[daend-base+si]
	jae	dtmaine

	if	SLOW+DEBUG
	mov	byte ptr [trreason-base+si],'W'	; for trace
	endif

	cmp	byte ptr [fastmode-base+si],'F'	; fast mode?
	je	dtmcont2			; yes, skip
	mov	es,[selzero-base+si]		; get current timer
	mov	bx,es:[046ch]
	sub	bx,[newtime-base+si]
	cmp	bx,TIME1			; TIME1/18 seconds elapsed?
	jb	dtmaine				; no, exit
dtmcont2:
	mov	bx,ax
	call	addrdes			; point es:bx to table entry
	shl	al,4			; al is address bits 0-7
	mov	dl,es:[bx+5]		; get access mode byte

	if	SLOW+DEBUG
	mov	ah,dl			; for trace
	shl	ah,1
	shr	ah,6
	or	ah,'0'
	mov	[trreason-base+si],ah
	endif

	mov	ah,dl			; save original amb in ah

	and	dl,01100000b		; dpl=0 means it's a virgin
	jz	jdtmzero		; dpl=1 means it's already unusable
	cmp	dl,2*32			; dpl=2 means we were here before
	je	dtm2			; dpl=3 means it's already in use

;------------------------------ Exit --------------------------------;

dtmaine	label	near
	if	SLOW+DEBUG
	call	trace
	endif
dtmainx	label	near
	pop	ax
	pop	bx
	pop	es
	pop	dx
	ret
jdtmzero:
	jmp	dtmzero

;-------------------------- DPL=2 Selector --------------------------;

dtm2	label	near
	cmp	al,es:[bx+2]		; are low address bits equal?
	jne	dtmoops			; no, got a problem to fix

;------------- Repeat encounter of old fixable selector -------------;

	cmp	byte ptr [fastmode-base+si],'F' ; are we in "fast mode"?
	je	dtmaine				; yes, exit
	inc	word ptr [excount-base+si] 	; bump exception counter
	cmp	byte ptr es:[bx],0ffh		; 255 yet for this selector?
	je	dtm2skp1			; yes, skip
	mov	dl,1				; dh is 1 if code, else 0
	add	es:[bx],dx			; count total and code refs
dtm2skp1:
	push	ds				; get current timer
	mov	ds,[selzero-base+si]
	mov	ax,ds:[046ch]
	pop	ds
	sub	ax,[newtime-base+si]		; compute elapsed time
	cmp	ax,TIME2			; TIME2/18 seconds elapsed?
	jbe	dtmaine				; no, exit

;---------------------- Time interval has expired -------------------;

	mov	ax,[excount-base+si]	; get exception count
	cmp	ax,[excmax-base+si]	; is the overhead heavy enough?
	jae	dtmfast			; yes, jump
	call	resetin			; no, start new interval
	jmp	dtmaine

;---------------------- Transition to fast mode ---------------------;

dtmfast	label	near
	call	autoset			; declare strategic DPL=2 selectors
	mov	ax,[cscslow]		; activate zapping of code selectors
	mov	[cscount],ax
	mov	byte ptr [fastmode-base+si],'F'
	jmp	dtmaine

;--------------------- Address conflict discovered ------------------;

dtmoops	label	near
	mov	byte ptr es:[bx+5],10110010b ; flag it as unusable (dpl=1)
	cmp	byte ptr [fastmode-base+si],'F'
	je	dtmgoslo		; if fast mode, go to slow mode
	call	resetin			; start new time interval either way
	jmp	dtmaine
dtmgoslo:
	call	resetin
	mov	byte ptr [fastmode-base+si],'S' ; go slow again
	call	autoclr
	mov	byte ptr [cscount-base+si],0	; no code selector zapping
	jmp	dtmaine

;--------------------- New selector encountered ---------------------;

dtmzero label	near
	mov	es:[bx+2],al			; set low address bits
	mov	byte ptr es:[bx+5],11010010b	; dpl=2,data,acc=no
	or	byte ptr es:[bx+6],1		; indicate an "auto" entry
	mov	word ptr es:[bx],0000h		; init counters
	call	resetin				; start new time interval
	cmp	byte ptr [fastmode-base+si],'F' ; are we in "fast mode"?
	jne	dtmzer1				; no, skip
	mov	byte ptr [fastmode-base+si],'S' ; yes, it's time to not be
	call	autoclr				; clear auto-declarations
	mov	byte ptr [cscount-base+si],0	; no code selector zapping
dtmzer1:
	call	autoadd				; add bx into gdt chain
	jmp	dtmaine

dtmaint	endp

;-------- Start new time interval, return garbage in ax -------------;

resetin	proc	near
	push	bx
	push	cx
	push	es
	push	ds

	mov	bx,[dabegin]		; must clear counters in GDT/LDT
	mov	cx,[daend]
	mov	es,[selldt]
	mov	ds,[selgdt]
reseti1:
	mov	al,es:[bx+5]
	and	al,01100000b
	cmp	al,01000000b		; dpl=2?
	jne	reseti2			; no, skip
	mov	word ptr es:[bx],0	; yes, clear counters
reseti2:
	mov	al,ds:[bx+5]
	and	al,01100000b
	cmp	al,01000000b		; dpl=2?
	jne	reseti3			; no, skip
	mov	word ptr ds:[bx],0	; yes, clear counters
reseti3:
	mov	bx,[bx+6]
	and	bl,11111000b
	cmp	bx,cx
	jb	reseti1

	pop	ds

	mov	es,[mfazero]		; now, reset timer
	mov	ax,es:[046ch]
	sub	ax,TIME1
	mov	[newtime],ax

	mov	[excount],0		; clear exception counter

	pop	es
	pop	cx
	pop	bx

	ret
resetin	endp

;-------------------- Add selector to GDT chain ---------------------;

autoadd	proc	near
	push	si
	push	di
	mov	es,[selgdt-base+si]	; chain exists only in the gdt
	mov	di,bx			; di saves this entry index
	mov	bx,[dabegin-base+si]	; point bx to first entry in chain
	mov	ax,0007h
autoad1:
	mov	si,bx			; si tracks "previous" entry
	mov	bx,es:[si+6]		; bx tracks "next" entry
	and	bl,11111000b
	cmp	bx,di			; are we pointing past it yet?
	jb	autoad1			; no, keep looping
	je	autoad3			; exit if new entry already in chain
	and	es:[di+6],ax
	or	es:[di+6],bx		; point new entry to next entry
	and	es:[si+6],ax
	or	es:[si+6],di		; point previous entry to new entry
autoad3:
	pop	di
	pop	si
	ret
autoadd	endp

;------------------ Remove all "auto" declarations ------------------;

autodel	proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	bp
	push	ds
	push	es
	mov	bx,[dabegin]		; point bx to first entry in chain
	mov	cx,[daend]
	mov	bp,-1
	mov	es,[selldt]
	mov	ds,[selgdt]		; chain exists only in the gdt
	jmp	short autode6		; enter the loop
autode1:
	xor	al,al			; al to indicate if remove from chain
	mov	dx,es:[bx+5]
	test	dh,1			; "auto" entry?
	jnz	autode2			; yes, jump
	test	dl,01100000b 		; check if dpl=0
	jnz	autode3			; no, jump
autode2:
	mov	es:[bx],bp
	and	dx,1111100010011110b 	; clear auto,dpl,acc
	mov	es:[bx+5],dx
	inc	al			; ldt entry is trashable
autode3:
	mov	dx,ds:[bx+5]
	test	dh,1			; "auto" entry?
	jnz	autode4			; yes, jump
	test	dl,01100000b 		; check if dpl=0
	jnz	autode6			; no, jump
autode4:
	mov	ds:[bx],bp
	and	dx,1111100010011110b 	; clear auto,dpl,acc
	mov	ds:[bx+5],dx
	inc	al			; gdt entry is trashable

	cmp	al,2			; are both entries trashable?
	jb	autode6			; no, must keep it
	or	bl,bl			; is bx on a 4K boundary?
	jz	autode6			; yes, must keep it
	mov	ax,[bx+6]		; remove current entry from chain
	and	al,11111000b
	and	word ptr [di+6],0007h
	or	[di+6],ax
	mov	bx,di
autode6:
	mov	di,bx			; di is "previous" entry
	mov	bx,[bx+6]		; bx is "current" entry
	and	bl,11111000b
	cmp	bx,cx
	jb	autode1
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
autodel	endp

;--------------- Activate strategic "auto" declarations -------------;

autoset	proc	near
	push	ax
	push	bx
	push	cx
	push	ds
	mov	bx,[dabegin-base+si]	; point bx to first entry in chain
	mov	cx,[daend-base+si]
	mov	es,[selldt-base+si]
	mov	ds,[selgdt-base+si]	; chain exists only in the gdt
autose1:
	mov	ax,es:[bx+5]
	test	ah,1				; "auto" flag set?
	jz	autos1x				; no, skip
	and	al,01100000b
	cmp	al,01000000b			; dpl=2?
	jne	autos1x				; no, skip
	mov	ax,es:[bx]			; get counters
	cmp	al,16				; got enough references?
	jb	autos1x				; no, skip
	mov	word ptr es:[bx],0ffffh
	mov	byte ptr es:[bx+5],11110010b	; set dpl=3,type=data
	shr	al,1
	cmp	ah,al				; are most of them code?
	jb	autos1x				; no, skip
	mov	ax,es				; allocate a code selector
	call	setacs
autos1x:
	mov	ax,ds:[bx+5]
	test	ah,1				; "auto" flag set?
	jz	autos2x				; no, skip
	and	al,01100000b
	cmp	al,01000000b			; dpl=2?
	jne	autos2x				; no, skip
	mov	ax,ds:[bx]			; get counters
	cmp	al,16				; got enough references?
	jb	autos2x				; no, skip
	mov	word ptr ds:[bx],0ffffh
	mov	byte ptr ds:[bx+5],11110010b	; set dpl=3,type=data
	shr	al,1
	cmp	ah,al				; are most of them code?
	jb	autos2x				; no, skip
	mov	ax,ds				; allocate a code selector
	call	setacs
autos2x:
	mov	bx,[bx+6]
	and	bl,11111000b
	cmp	bx,cx
	jb	autose1
	pop	ds
	pop	cx
	pop	bx
	pop	ax
	ret
autoset	endp

;-------- Perform descriptor table changes for code selector --------;

setacs	proc	near
	push	di
	push	ds
	push	es
	mov	es,ax				; es addresses ldt or gdt
	mov	al,es:[bx+2]			; look at address bits 4-5
	and	al,00110000b
	cmp	al,00110000b			; rpl=3?
	jne	setacs1				; no, jump
	mov	byte ptr es:[bx+5],11111010b	; yes, set type=code
	jmp	short setacsx
setacs1:
	mov	ds,cs:[seldata-base+si]
	cmp	byte ptr [cchange],'Y'		; ok to change cs?
	jne	setacsx				; no, exit
	mov	di,word ptr [cscslow-base+si]	; get number of entries active
	cmp	di,CSTMAX			; table full?
	jae	setacsx				; yes, exit
	shl	di,1				; di indexes new table entry
	inc	word ptr [cscslow-base+si]
	mov	ax,[cstseln]			; next selector value to use
	mov	[cstab2+di],ax
	sub	[cstseln],8

	push	dx				; now we'll create a gdt
	push	di				;  entry for the new selector
	push	ds
	and	al,11111000b
	mov	di,ax				; di is FFxx, a ldt index
	mov	ax,es:[bx+2]			; get address in dl:ax
	mov	dl,es:[bx+4]
	mov	ds,[selldt-base+si]		; ds:di addresses ldt entry
 	mov	ds:[di+2],ax			; turn it into a code selector
 	mov	ds:[di+4],dl
 	mov	byte ptr ds:[di+5],0fah
	pop	ds
	pop	di
	pop	dx

	shr	al,4				; calc original segreg value
	and	ax,0007h
	or	ax,bx
	mov	[cstab1+di],ax			; put it into selector table
setacsx:
	pop	es
	pop	ds
	pop	di
	ret
setacs	endp

;------------------- Clear all "auto" declarations ------------------;

autoclr	proc	near
	push	ax
	push	bx
	push	cx
	push	ds
	mov	bx,[dabegin-base+si]	; point bx to first entry in chain
	mov	cx,[daend-base+si]
	mov	es,[selldt-base+si]
	mov	ds,[selgdt-base+si]	; chain exists only in the gdt
autocl1:
	mov	ax,es:[bx+5]
	test	ah,1			; "auto" flag set?
	jz	autocl2			; no, skip
	cmp	al,11100000b		; dpl=3?
	jb	autocl2			; no, skip
	mov	byte ptr es:[bx+5],11010010b ; dpl=2,data,acc=no
	mov	word ptr es:[bx],0	; clear exception counters
autocl2:
	mov	ax,ds:[bx+5]
	test	ah,1
	jz	autocl3
	cmp	al,11100000b
	jb	autocl3
	mov	byte ptr ds:[bx+5],11010010b
	mov	word ptr ds:[bx],0
autocl3:
	mov	bx,[bx+6]
	and	bl,11111000b
	cmp	bx,cx
	jb	autocl1
	pop	ds
	pop	cx
	pop	bx
	pop	ax
	ret
autoclr	endp

;-------------- Compute descriptor address from selector ------------;

addrdes	proc	near
	test	bl,00000100b		; ldt selector?
	jnz	adldt			; yes, jump
	and	bl,11111000b		; remove flag bits
	mov	es,[selgdt]
	ret
adldt:
	and	bl,11111000b		; remove flag bits
	mov	es,[selldt]
	ret
addrdes endp

;--------------- Compute absolute address from selector -------------;

getadr3	proc	near
	mov	bx,ax			; randomize to get cache index 
	xor	bl,bh
	and	bx,0078h
	cmp	ax,[selcache+bx]	; is desired selector already cached?
	jne	g3cont			; no, jump
	mov	ax,[selcache+2+bx]	; yes, we have a fast answer
	mov	bx,[selcache+4+bx]
	ret

g3cont	label	near			; call here if above already done
	mov	[selcache+bx],ax	; set selector in cache
	push	di			; save scratch register
	push	bx			; save cache index

;	cmp	ax,0f003h		;test; trying to handle address space
;	jbe	g3cc			;test;  wrap by translating most
;	or	al,al			;test;  addresses of the form
;	jnz	g3cc			;test;  0Fxxxx to FFxxxx.
;	shl	ax,4			;test;
;	mov	bx,00ffh		;test;
;	jmp	short g3wrap		;test;
;g3cc:					;test;

	mov	bx,ax			; get gdt or ldt selector in es
	and	ax,0004h
	add	al,al
	add	ax,[selgdt-base+si]	; assuming [selldt] = [selgdt]+8
	mov	es,ax

	mov	ax,bx
	and	bl,11111000b		; remove flag bits
	cmp	byte ptr es:[bx+5],11100000b ; dpl=3?
	jb	g38086			; no, jump
	mov	ax,es:[bx+2]		; yes, get info from descriptor
	mov	bx,es:[bx+4]		; ar byte is returned in bh
	jmp	short g3wrap
g38086:
	mov	es,[selgdt-base+si]	; address gdt entry for which
	xor	bl,bl			;   address bits 0-11 are zero
	mov	bx,es:[bx+3]		; bx bits 4-15 are address bits 12-23
	and	bl,0f0h
	xor	ah,ah			; put address bits 0-11 in ax 0-11
	shl	ax,4
	or	ah,bl
	mov	bl,bh
	xor	bh,bh			; return bh=0
g3wrap:
	pop	di			; restore cache index
	mov	[selcache+2+di],ax	; update remainder of cache entry
	mov	[selcache+4+di],bx
	pop	di			; restore di and exit
	ret
getadr3	endp

	page
;------------------------- debugging --------------------------------;

	even
trcount	dw	1
trtally	dw	0
trtime	dw	7fffh
trvidoff dw	160*25-(23*2)
trchar	db	':',0
hextable db	'0123456789ABCDEF'

trace	proc	near

	if	DEBUG
	else
      	inc	[trtally]
	endif

	if	LIGHTS
	else

	push	es
	push	di
	push	ax
	push	bx
	push	cx

	if	DEBUG
	else
	mov	es,[selzero]
	mov	ax,es:[46ch]
	mov	bx,ax
	sub	ax,[trtime]
	cmp	ax,18			; 1 second elapsed?
      	jb	trexit			; no, exit
	mov	[trtime],bx
	endif

	mov	es,[selvideo]
	mov	di,[trvidoff]
	if	DEBUG
	add	di,160
	cmp	di,160*24
	jb	dbskip1
	mov	di,160-(23*2)
dbskip1:
	mov	[trvidoff],di
	endif
	mov	al,byte ptr [trtally+1]
	call	disphex
	mov	al,byte ptr [trtally]
	call	disphex

	mov	al,' '
	call	dispchar
	mov	al,[fastmode]
	call	dispchar
	mov	al,[trtype]
	call	dispchar
	mov	al,[trreason]
	call	dispchar
	mov	al,' '
	call	dispchar

	mov	al,byte ptr [p0cs+1]
	call	disphex
	mov	al,byte ptr [p0cs]
	call	disphex
	mov	al,[trchar]
	call	dispchar
	xor	[trchar],14h			; alternate ':' and '.'

	mov	al,byte ptr [p0ip+1]
	call	disphex
	mov	al,byte ptr [p0ip]
	call	disphex
	mov	al,' '
	call	dispchar

	mov	al,byte ptr [trsegadr+1]
	call	disphex
	mov	al,byte ptr [trsegadr]
	call	disphex

;	mov	al,' '			; Display instruction bytes (cx)
;	call	dispchar
;	pop	ax
;	push	ax
;	call	disphex
;	mov	al,ah
;	call	disphex
;	mov	ax,bp
;	call	disphex
;	mov	al,ah
;	call	disphex

	if	DEBUG
	inc	[trtally]
	else
      	mov	[trtally],0
	endif

trexit:
	pop	cx
	pop	bx
	pop	ax
	pop	di
	pop	es

	endif

	ret
trace	endp

disphex proc	near
	push	ax
	push	bx
	mov	ah,al
	xor	bh,bh
	mov	bl,al
	shr	bl,4
	mov	al,[bx+hextable]
	call	dispchar
	mov	bl,ah
	and	bl,0fh
	mov	al,[bx+hextable]
	call	dispchar
	pop	bx
	pop	ax
	ret
disphex endp

dispchar proc	near
	cld
	stosb
	mov	al,70h
	stosb
	ret
dispchar endp

         page
;--------------------------------------------------------------------;
;                   parameters available to user                     ;
;--------------------------------------------------------------------;

         even
parms    label word
parmrhad dw    2 dup(0)         ; address of request handler
parmfeat label word             ; special features:
                                ;   8000h = all memory is managed
                                ;   4000h = i/o trapping supported 
                                ;   2000h = write protection supported
				;   1000h = use mapping for context switching
				;   0800h = declare call supported (286 only)
	 dw    8800h
parmgran dw    4096,0           ; granularity is 4k per page
parmtot  dw    0,0              ; total extended memory (pages)
parmused dw    0,0              ; used  extended memory (pages)
parm6ec  dw    0		; error code for int 6

;		0 - Writing to protected memory
;		1 - Operation exception
;		2 - Protection exception (not due to i/o or write protection)
;      		3 - in al,xx 
;      		4 - in ax,xx 
;      		5 - out xx,al
;      		6 - out xx,ax
;      		7 - in al,dx 
;      		8 - in ax,dx 
;      		9 - out dx,al
;     	       10 - out dx,ax

parm6adr dw    0,0		; address or i/o instruction for int 6
parmscb  dw    01fch,0		; scb address - filled in by mos 

	 page
;--------------------- dma staging buffer parameters ----------------;

         even
buffaddr dw    0                ; disk staging buffer seg address
mxlength dw    0                ; maximum i/o length encountered

;--------------------------- assorted data --------------------------;

rhoff    dw    0                ; request header pointer
rhseg    dw    0		; this must immediately follow rhoff!
pendaddr dw    offset progend   ; retained length before staging buffer
meg0old  dw    0080h            ; original nbr meg0 banks
dmabank  db    0ffh,0           ; bank above which disk staging needed
iolength dw    0
oldint13 dd    0
workaddr dw    0d000h,0         ; address of initialization work area
videoadr dw    0b000h           ; seg address of video ram
trash1   dw    -1               ; scratch areas 
trash2   dw    -1
trash3   dw    -1

userax   dw    0
userbx   dw    0
usercx   dw    0
userdx   dw    0
useres   dw    0
userflag dw    0

parmap   db    PARLIMIT/8 dup(0)        ; bit map of reserved banks

	page
;--------------------------------------------------------------------;
;                   Retained Task State Segment                      ;
;--------------------------------------------------------------------;

         org   ($-mainseg+15)/16*16     ; align to paragraph boundary
         db	'******TSS2******'
tss2     label	word
         dw	0                        ; link to previous tss
         dw	offset p0stack           ; sp/ss for level 0 stack switch
         dw	gdtdata-gdt  
         dw	0,0                      ; sp/ss for level 1 stack switch
         dw	0,0                      ; sp/ss for level 2 stack switch
         dw	offset pmstart           ; initial instruction pointer

         db	00000010b                ; sf=0,zf=0,0,af=0,0,pf=0,1,cf=0
         db	00000000b                ; 0,nt=0,iopl=00,of=0,df=0,if=0,tf=0

         dw	0                        ; ax
         dw	0                        ; cx
         dw	0                        ; dx
         dw	0                        ; bx
t2sp     dw	0                        ; sp
         dw	0                        ; bp
         dw	0                        ; si
         dw	0                        ; di

         dw	gdtdata-gdt              ; segment regs
         dw	gdtcode-gdt
         dw	gdtdata-gdt
         dw	gdtdata-gdt

         dw	gdtldts-gdt             ; task ldt selector 

tss2len  equ   $-tss2

progend  label byte                  ; end of retained code

	page
;--------------------------------------------------------------------;
;                Task State Segment for Initialization               ;
;--------------------------------------------------------------------;

         org   ($-mainseg+15)/16*16     ; align to paragraph boundary
         db	'******TSS1******'
tss1     label	word
         dw	0                        ; link to previous tss
         dw	offset p0stack           ; sp/ss for level 0 stack switch
         dw	gdtdata-gdt  
         dw	0,0                      ; sp/ss for level 1 stack switch
         dw	0,0                      ; sp/ss for level 2 stack switch
         dw	offset pmstart           ; initial instruction pointer

         db	00000010b                ; sf=0,zf=0,0,af=0,0,pf=0,1,cf=0
         db	00000000b                ; 0,nt=0,iopl=00,of=0,df=0,if=0,tf=0

         dw	0                        ; ax
         dw	0                        ; cx
         dw	0                        ; dx
         dw	0                        ; bx
         dw	0                        ; sp
         dw	0                        ; bp
         dw	0                        ; si
         dw	0                        ; di

         dw	gdtdata-gdt              ; segment regs
         dw	gdtcode-gdt
         dw	gdtdata-gdt
         dw	gdtdata-gdt

         dw	gdtldts-gdt              ; task ldt selector 

tss1len  equ   $-tss1

	page
;--------------------------------------------------------------------;
;                Model for Global Descriptor Table                   ;
;--------------------------------------------------------------------;

         org   ($-mainseg+15)/16*16     ; align to paragraph boundary

gdt      dw	4 dup(0)		; null selector must be first

gdttss1  label	byte                     ; 0008  task state segment
         dw	tss1len-1,offset tss1    ; limit, base
         db	0                        ; base bits 16-23
         db	10000001b                ; p=1,dpl=0,s=0,type=1
         dw	0                        ; reserved 

gdttss2  label	byte                     ; 0010  task state segment
         dw	tss2len-1,offset tss2    ; limit, base
         db	0                        ; base bits 16-23
         db	10000001b                ; p=1,dpl=0,s=0,type=1
         dw	0                        ; reserved 

gdtldts  label	byte                     ; 0018  ldt system selector 
         dw	0ffffh,0		 ; limit, base
         db	00h                      ; base bits 16-23 (64k beyond gdt)
         db	10000010b                ; p=1,dpl=0,s=0,type=2
         dw	0                        ; reserved 

gdtcode  label	byte                     ; 0020  this driver's code segment
         dw	0ffffh,0                 ; limit, base
         db	0                        ; base bits 16-23
         db	10011010b                ; p=1,dpl=0,s=1,e=1,c=0,r=1,a=0
         dw	0                        ; reserved 

gdtdata  label	byte                     ; 0028  this driver's data segment
         dw	0ffffh,0                 ; limit, base
         db	0                        ; base bits 16-23
         db	10010010b                ; p=1,dpl=0,s=1,e=0,ed=0,w=1,a=0
         dw	0                        ; reserved 

gdtzero  label	byte                     ; 0030  segment at 00000
         dw	0ffffh,0                 ; limit, base
         db	0                        ; base bits 16-23
         db	10010010b                ; p=1,dpl=0,s=1,e=0,ed=0,w=1,a=0
         dw	0                        ; reserved 

gdtwork  label	byte                     ; 0038  scratch descriptor
         dw	0ffffh,0                 ; limit, base
         db	0                        ; base bits 16-23
         db	10010010b                ; p=1,dpl=0,s=1,e=0,ed=0,w=1,a=0
         dw	0                        ; reserved 

 					 ; 0040  segment at 00400
         dw	0ffffh,0400h             ; limit, base
         db	0                        ; base bits 16-23
         db	11110010b                ; p=1,dpl=3,s=1,e=0,ed=0,w=1,a=0
         dw	0                        ; reserved 

gdtscum  label	byte                     ; 0048  scratch descriptor
         dw	0ffffh,0                 ; limit, base
         db	0                        ; base bits 16-23
         db	10010010b                ; p=1,dpl=0,s=1,e=0,ed=0,w=1,a=0
         dw	0                        ; reserved 

gdtdummy label	byte                     ; 0050  Model for remainder
         dw	0ffffh,0                 ; limit, base
         db	0                        ; base bits 16-23
         db	10010010b                ; p=1,dpl=0,s=1,e=0,ed=0,w=1,a=0
         dw	0                        ; reserved 

gdtsize	equ	$-gdt

	page
;--------------------------------------------------------------------;
;        Data to Initialize LOADALL Area for Protected Mode          ;
;--------------------------------------------------------------------;

lidata	label	word
	db	6 dup(0)	; unused
     	dw	0fff1h		; Machine Status Word
	db	14 dup(0)	; unused
    	dw	gdttss2-gdt	; Task Register
       	dw	3002h		; Flags Register (iopl=3)
    	dw	offset ementry	; Instruction Pointer
     	dw	gdtldts-gdt	; ldt Selector
    	dw	0		; ds Selector
    	dw	0		; ss Selector
    	dw	0		; cs Selector
    	dw	0		; es Selector
    	dw	0		; di
    	dw	0		; si
    	dw	0		; bp
    	dw	0		; sp
    	dw	0		; bx
    	dw	0		; dx
    	dw	0		; cx
    	dw	0		; ax

      	db	3 dup(0)	; es base address
	db	11110010b	;  p=1,dpl=11,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit

      	db	3 dup(0)	; cs base address
	db	11110010b	;  p=1,dpl=11,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit

      	db	3 dup(0)	; ss base address
	db	11110010b	;  p=1,dpl=11,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit

      	db	3 dup(0)	; ds base address
	db	11110010b	;  p=1,dpl=11,1,e=0,d=0,w=1,a=0
	dw	0ffffh		;  limit

      	dw	0		; offset gdt	; gdtr base 
	db	0,0
      	dw	0ffffh		; limit

        dw	0		; offset gdt	; ldt base address
	db	01h		;  64k beyond gdt
	db	10000010b	;  p=1,dpl=00,0,type=ldt
	dw	0ffffh		;  limit

      	dw	0		; offset idt	; idtr base 
	db	0,0
      	dw	8*256-1		; limit

       	dw	offset tss2	; tss base address
	db	0
	db	10000001b	;  p=1,dpl=00,0,type=avtss
	dw	tss2len-1	;  limit

	page
;--------------------------------------------------------------------;
;              Miscellaneous Data for Initialization                 ;
;--------------------------------------------------------------------;

msgpm    db    'Protected mode activated; ','$'
msgem    db    'nnnnK total RAM found.',13,10,'$'
msgsize  db    'Cannot initialize 80286 driver with less than '
         db    '132K extended memory!',13,10,'$'

         page
;--------------------------------------------------------------------;
;                      Initialization Code                           ;
;--------------------------------------------------------------------;

init	label	near

;---------------------- get video ram address -----------------------;

         mov   es,[mfazero]
         mov   ax,es:[0410h]         ; get equip_flag
         and   al,30h
         cmp   al,30h                ; monochrome card?
         je    skipcolr              ; yes, skip
         mov   [videoadr],0b800h     ; no, set address for color card
skipcolr:

;---------------- determine original base memory size ---------------;

         mov   es,[mfazero]
         mov   ax,es:[0413h]         ; get default value
         mov   bx,ax

	 add   ax,3		     ; ps/2 is 639k

         shr   ax,1
         shr   ax,1                  ; convert to a multiple of 4k
         mov   [meg0old],ax
         mov   [parmused],ax
         mov   [dmabank],al          ; for dma logic

;---------------------- parse device command line -------------------;

         les   bx,dword ptr [rhoff]
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

         cmp   al,'P'                   ; ps/2 needs 16k dma buffer
         jne   ddsendp
	 mov   ax,4000h 
	 jmp   short ddsdma
ddsendp:
	 cmp   al,'E'			; emulex needs 64k dma buffer
	 jne   ddsende
	 mov   ax,0ffffh 
	 jmp   short ddsdma
ddsende:
	 cmp   al,'X'			; xt needs 9k dma buffer
	 jne   ddsendx
	 mov   ax,18*512 
ddsdma:
	 mov   [buffsize],ax
	 mov   [dmajump],9090h		; nop out conditional jump
	 jmp   short ddsdone
ddsendx:
ddsdone:

;------------------- Relocate various descriptors -------------------;

	mov	ax,ds			; compute our address in bl/ax
	mov	bl,ah
	shl	ax,4
	shr	bl,4

	mov   word ptr [gdtcode+2],ax	; init some descriptors
	mov   byte ptr [gdtcode+4],bl
	mov   word ptr [gdtdata+2],ax
	mov   byte ptr [gdtdata+4],bl

	add   word ptr [gdttss1+2],ax
	adc   byte ptr [gdttss1+4],bl
	add   word ptr [gdttss2+2],ax
	adc   byte ptr [gdttss2+4],bl

	mov     [t2sp],sp

;---------- Allocate extended memory for idt, gdt, and ldt ----------;

	mov	ax,[emstart]		; page number for start of ext memory
	shl	ax,4			; make it a multiple of 256 bytes

	mov	word ptr [wsidtr+3],ax	; set idt address
	add	ax,10h			; idt is 2k, but waste a 4k page

	mov	word ptr [wsgdtr+3],ax	; set gdt address
	add	ax,0100h		; gdt length is 64k

	mov	word ptr [gdtldts+3],ax	; set ldt address
	add	ax,0100h		; ldt length is 64k

	shr	ax,4
	mov	[emstart],ax
	add	[parmused],0021h

;------- Ensure that at least 132k extended memory is present -------;

	call	bit20on			; turn on address bit 20 gate

	mov	ax,word ptr [gdtldts+3]	; let es address ldt
	call	addrem			;   and disable interrupts
	mov	di,0fffeh
	mov	ax,7654h
	mov	es:[di],ax
	cmp	es:[di],ax
	sti
	je	$+5
	jmp	errsize

;-------------------- Build Interrupt Jump Table --------------------;

	mov	di,offset ijtable	; ds:di indexes table
	xor	dx,dx			; dx is displacement for instruction
bijloop:
	mov	byte ptr [di],2eh	; cs override prefix
	mov	word ptr [di+1],2effh	; far indirect jump with 
	mov	word ptr [di+3],dx	;   16-bit displacement
	add	di,5
	add	dx,4
	cmp	dx,0400h
	jb	bijloop

;----------------- Build Interrupt Descriptor Table -----------------;

	mov	ax,[wsidtr+3]		; address idt with es
	call	addrem			;   and disable interrupts

	mov	ax,cs			; compute ijtable absolute address
	shl	ax,4			;  note it must fall within 1st 64k
	add	ax,offset ijtable
	xor	di,di			; es:di indexes idt
	mov	cx,256			; number of entries
bidloop:
	mov	word ptr es:[di],ax	; offset
	mov	word ptr es:[di+2],0fff7h ; fff4 selector with rpl=3
	mov	word ptr es:[di+4],0e600h ; p=1,dpl=3,s=0,Type=6
	mov	word ptr es:[di+6],0	; reserved area
	add	ax,5
	add	di,8
	loop	bidloop

	mov	di,8*6			; address invalid-opcode entry
	mov	word ptr es:[di],offset entint06
	mov	word ptr es:[di+2],gdtcode-gdt

	mov	di,8*08			; address timer 0 interrupt entry
	mov	word ptr es:[di],offset entint08
	mov	word ptr es:[di+2],gdtcode-gdt

	mov	di,8*13			; address protection exception entry
	mov	word ptr es:[di],offset entint0d
	mov	word ptr es:[di+2],gdtcode-gdt

	sti

;------------------- Build Global Descriptor Table ------------------;

	mov	ax,word ptr [wsgdtr+3]	; let es address gdt
	call	addrem			;   and disable interrupts

	mov	si,offset gdt		; move initial gdt data to gdt
	xor	di,di
	mov	cx,gdtsize/2
	cld
	rep	movsw

	mov	di,gdtdummy-gdt		; es:di indexes the table
	mov	ax,(gdtdummy-gdt)*16	; bl/ax is physical address
	mov	bx,9200h		; bh is access rights byte
bgdtloop:
	mov	word ptr es:[di],-1	; limit
	mov	word ptr es:[di+2],ax	; base bits 0-15
	mov	word ptr es:[di+4],bx   ; base 16-23 and access rights byte
	mov	word ptr es:[di+6],0	; reserved area
	add	ax,0080h
	adc	bl,0
	add	di,8
	jnz	bgdtloop

;---------- Build GDT chain entries for remapping purposes ----------;

	xor	ax,ax
bgcloop:
	mov	di,ax			; each entry for a 4k boundary is
	inc	ah			;   set to point to the next one
	mov	es:[di+6],ax
	jnz	bgcloop
	dec	word ptr es:[di+6]	; set entry at offset ff06 to ffff

	sti

;------------------- Build Local Descriptor Table -------------------;

	mov	ax,word ptr [gdtldts+3]	; let es address ldt
	call	addrem			;   and disable interrupts

	xor	di,di			; es:di indexes the table
	mov	ax,0040h		; bl/ax is physical address
	mov	bx,9200h		; bh is access rights byte
bldtloop:
	mov	word ptr es:[di],-1	; limit
	mov	word ptr es:[di+2],ax	; base bits 0-15
	mov	word ptr es:[di+4],bx   ; base 16-23 and access rights byte
	mov	word ptr es:[di+6],0	; reserved area
	add	ax,0080h
	adc	bl,0
	add	di,8
	jnz	bldtloop

	mov	word ptr es:[0fff0h+2],0000h  ; fff4 selector points to 000000
	mov	word ptr es:[0fff0h+4],0fa00h ; Code segment with dpl=3

	mov	word ptr es:[0ffe8h+2],0000h  ; ffec selector points to 000000
	mov	word ptr es:[0ffe8h+4],0f200h ; Data segment with dpl=3

	mov	ax,[wsidtr+3]		      ; ffe4 selector points to idt
	mov	byte ptr es:[0ffe0h+5],0f2h   ; Data segment with dpl=3
	mov	byte ptr es:[0ffe0h+2],00h 
	mov	word ptr es:[0ffe0h+3],ax
	mov	[selidt],0ffe4h

	mov	ax,word ptr [gdtldts+3]	      ; ffdc selector points to ldt
	mov	byte ptr es:[0ffd8h+5],0f2h   ; Data segment with dpl=3
	mov	byte ptr es:[0ffd8h+2],00h 
	mov	word ptr es:[0ffd8h+3],ax
	mov	[selldt],0ffdch

	mov	ax,[wsgdtr+3]		      ; ffd4 selector points to gdt
	mov	byte ptr es:[0ffd0h+5],0f2h   ; Data segment with dpl=3
	mov	byte ptr es:[0ffd0h+2],00h 
	mov	word ptr es:[0ffd0h+3],ax
	mov	[selgdt],0ffd4h

	mov	ax,[videoadr]		      ; ffcc points to video ram
	shr	ax,4
	mov	byte ptr es:[0ffc8h+5],0f2h   ; Data segment with dpl=3
	mov	byte ptr es:[0ffc8h+2],00h 
	mov	word ptr es:[0ffc8h+3],ax
	mov	[selvideo],0ffcch

	mov	word ptr es:[0ffc0h+2],0700h  ; ffc4 selector points to 000700
	mov	word ptr es:[0ffc0h+4],0fa00h ; Code segment with dpl=3

	sti

;------------------- Initialize loadall data area -------------------;

	push	ds
	pop	es

	mov	di,offset lastart
	mov	si,offset lidata
	mov	cx,lalen/2
	cld
	rep	movsw

	mov	ax,ds

	mov	[lacs],ax
	mov	[lads],ax
	mov	[laes],ax
	mov	[lass],ss
	mov	[lasp],sp

	mov	bl,ah			; compute 20-bit absolute address
	shr	bl,4
	shl	ax,4

	mov	word ptr [laesdc],ax	; relocate descriptor cache contents
	mov	byte ptr [laesdc+2],bl
	mov	word ptr [lacsdc],ax
	mov	byte ptr [lacsdc+2],bl
	mov	word ptr [ladsdc],ax
	mov	byte ptr [ladsdc+2],bl

	add	word ptr [latssdc],ax
	adc	byte ptr [latssdc+2],bl

	mov	ax,ss			; setup for ss (passed from caller)
	mov	[lass],ax
	mov	bl,ah
	shr	bl,4
	shl	ax,4
	mov	word ptr [lassdc],ax
	mov	byte ptr [lassdc+2],bl

	mov	ax,word ptr [wsidtr+3]	; set descriptor table addresses
	mov	word ptr [laidtr+1],ax
	mov	ax,word ptr [wsgdtr+3]
	mov	word ptr [lagdtr+1],ax
	mov	ax,word ptr [gdtldts+3]
	mov	word ptr [laldtdc+1],ax

;------------------ transfer to protected mode ----------------------;

	mov	ax,0fff1h		; ax will load into msw
	mov	dx,gdtdata-gdt

	cli

	db	0fh,01h,00010110b	; lgdt using disp16
	dw	offset wsgdtr

	db	0fh,01h,00011110b	; lidt 
	dw	offset wsidtr

	mov	ss,dx			; dummy value in ss so lmsw will work

;------------ Stack is no longer usable until the loadall -----------;

	db	0fh,01h,11110000b	; lmsw ax - enter protected mode

	jmp   $+2			; clear prefetch queue

;--------------------- Now in protected mode ------------------------;

	db	0eah                    ; direct intersegment jump loads cs
	dw	offset $+4
	dw	gdtcode-gdt

	mov	ax,gdtdata-gdt          ; load other segregs
	mov	ds,ax
	mov	es,ax
	mov	ss,ax

	mov	ax,gdtldts-gdt
	db	0fh,00h,11010000b	; lldt from ax

	mov	ax,gdttss1-gdt          ; gdt selector for tss1
	db	0fh,00h,11011000b       ; ltr from ax 

	db	0eah                    ; direct intersegment jump
	dw	0,gdttss2-gdt           ; goes to pmstart via tss gate

pmstart	label near

;--------------------- Execute LOADALL Instruction ------------------;

	db	0fh,05h			; all registers/flags are reloaded

;---------------------- Emulation is now active! --------------------;

ementry	label	near
 	mov	[mfazero],0ffech	; set new "zero" selector

	mov	ah,9			; write message to screen
	lea	dx,[msgpm]
	int	21h

	page

;---------------------- save/set disk i/o vector --------------------;

         mov   es,[mfazero]
         mov   ax,es:[004ch]         ; save int 13h vector
         mov   word ptr [oldint13],ax
         mov   ax,es:[004eh]
         mov   word ptr [oldint13+2],ax

         mov   word ptr es:[004eh],cs	; set new int 13h vector
         mov   word ptr es:[004ch],offset entinr13

;---------------------- init some more pointers ---------------------;

         mov   [parmrhad+0],offset rhentry
         mov   [parmrhad+2],0ffc4h+3

;-------------------- extended memory initialization ----------------;

	cli
	mov	dx,[emstart]		; 4k page number after idt/gdt/ldt
initlop1:
	sti				; allow timer updates
	cli
	mov	bx,[workaddr+1]		; use 4k address space at d0000
	mov	ax,dx
	mov	cx,1			; init 1 4k bank at a time
	call	remap
	mov	es,[workaddr]
	mov	ax,7777h
	mov	es:[0],ax
	cmp	es:[0],ax
	jne	izdone			; exit if no ram there

	cld
	xor	di,di			; init the 4K bank to zeros
	xor	ax,ax
	mov	cx,2048
	rep	stosw

	xor	di,di			; then test the whole bank
	mov	cx,2048			; (yes, this IS necessary!)
	repe	scasw
	jne	izdone

	inc	dx
	cmp	dx,PARLIMIT
	jb	initlop1
izdone:
	sub	dx,[emstart]		; compute total memory
	add	dx,0021h		;  (idt/gdt/ldt space already used)
	add	dx,[meg0old]
	mov	[parmtot],dx

;------------- Flag unused extended memory as available -------------;

	mov	bx,[emstart]		; starting physical bank number
	mov	cx,[parmtot]		; compute number of banks in cx
	sub	cx,[meg0old]		;   don't include meg0 ram
	sub	cx,0021h		;   don't include idt/gdt/ldt
	jle	izfskip
izfloop:
	call	addrmap
	or	[parmap+di],dl
	inc	bx
	loop	izfloop
izfskip:

;------------------ extended memory is initialized ------------------;

         xor   ax,ax
         mov   cx,256
         call  selfmap               ; reinitialize meg0 mapping

	 sti

;-------------------- write total memory size -----------------------;

         mov   ax,[parmtot]             ; compute kbytes of extended memory
         shl   ax,1
         shl   ax,1

         xor   dx,dx
         lea   bx,[msgem+3]
         mov   cx,4
         call  bintodec

         mov   ah,9
         lea   dx,[msgem]
         int   21h

         page
;--------------------------------------------------------------------;
;       compute buffer location - must not cross 64k boundary        ;
;--------------------------------------------------------------------;

         mov   ax,[pendaddr]
         add   ax,15
         mov   bx,[buffsize]
         mov   cl,4
         shr   ax,cl
         shr   bx,cl

         mov   dx,0070h
         add   ax,dx                 ; buffer begin paragraph address in ax
         add   bx,ax                 ; buffer end in bx

         push  ax
         and   ax,0f000h
         and   bx,0f000h
         cmp   ax,bx
         pop   ax
         je    bufadrok              ; jump if segment not crossed

         add   ax,0fffh              ; bump to next segment
         and   ax,0f000h
bufadrok:
         mov   [buffaddr],ax

         les   bx,dword ptr [rhoff]
         mov   dx,[buffsize]            ; compute end of buffer
         mov   cl,4
         shr   dx,cl
         inc   dx
         add   ax,dx

;--------------- Move data area used by IBM ESDI BIOS ---------------;

	 push  es
	 mov   es,[mfazero]
	 mov   dx,es:[040eh]
	 cmp   dx,9fc0h			; data area at 9fc0:0000?
	 jne   mieskip
	 mov   es:[040eh],ax		; yes, replace its address
	 mov   es,ax			;   and move its data to the new area
	 push  ds
	 mov   ds,dx			; source address 
	 xor   si,si
	 xor   di,di
	 mov   cx,512			; length is 1k 
	 cld
	 rep   movsw
	 pop   ds
	 add   ax,0040h			; bump ending segment by 1k
mieskip:
	 pop   es

;------------------ Set end address of this driver ------------------;

         mov   word ptr es:[bx+14],0	; set this driver's end address
         mov   word ptr es:[bx+16],ax

;---------------------- Declare some segments -----------------------;

    	mov	bx,ds			; declare 0070 as a data selector
    	mov	cl,0
    	call	vdeclare

   	mov	bx,007fh		; declare 007f as a code selector
   	mov	cl,1
   	call	vdeclare

   	mov	bx,[buffaddr]		; declare staging buffer as data
   	mov	cl,0
   	call	vdeclare

   	mov	bx,0f000h		; declare BIOS code selector
   	mov	cl,1
   	call	vdeclare

;--------------------- Initialization completed ---------------------;

         jmp   donestat

;----------------------- write error messages -----------------------;

errsize  label near
         mov   ah,9
         lea   dx,[msgsize]
         int   21h
         jmp   $

;--------------------- decimal-to-binary routine --------------------;

dectobin proc  near
         xor   ax,ax                 ; ax will contain the result
dtbloop:                             ; es:bx is source address
         mov   dl,es:[bx]
         cmp   dl,'0'
         jb    dtbwrap
         cmp   dl,'9'
         ja    dtbwrap
         push  dx
         mul   [wordten]
         pop   dx
         and   dx,000fh
         add   ax,dx
         inc   bx
         jmp   dtbloop
dtbwrap:
         ret
dectobin endp

;--------------------------------------------------------------------;
;                  Address-Extended-Memory Procedure                 ;
;                                                                    ;
;   Given ABCD in ax, this routine sets the ES descriptor cache      ;
;   register to point to location ABCD00.  Real mode only.           ;
;--------------------------------------------------------------------;

addrem	proc	near
	pusha				; Too bad the 8086 won't do this

	mov	[laes],0f000h		; making es as harmless as possible
	mov	word ptr [laesdc+1],ax	; set up es descriptor cache

	mov	ax,ds			; preserve segment registers
	mov	[lads],ax
	mov	bl,ah
	shr	bl,4
	shl	ax,4
	mov	word ptr [ladsdc+0],ax
	mov	byte ptr [ladsdc+2],bl

	mov	ax,ss
	mov	[lass],ax
	mov	bl,ah
	shr	bl,4
	shl	ax,4
	mov	word ptr [lassdc+0],ax
	mov	byte ptr [lassdc+2],bl

	mov	ax,cs
	mov	[lacs],ax
	mov	bl,ah
	shr	bl,4
	shl	ax,4
	mov	word ptr [lacsdc+0],ax
	mov	byte ptr [lacsdc+2],bl

	mov	[lasp],sp
	mov	[laip],offset aemcont
	cli				; we will leave interrupts disabled
	pushf
	pop	[laflags]

	db	0fh,05h			; loadall
aemcont:
	popa
	ret
addrem	endp

         even
progsize equ   $

mainseg  ends
         end   begin
