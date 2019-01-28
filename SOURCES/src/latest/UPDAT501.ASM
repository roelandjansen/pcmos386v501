	include page.inc
	title	updat501.asm
	subttl	updat501.asm - generic patch driver for pc-mos 5.01
comment ^===============================================================
		     development specification

 program name:	updat501.sys		   assigned to: martin stitt
 module name:	updat501.asm		   assign date: 03/31/92
 entry points:	strat/intr		   completed:
 entry from:	todriver
 entry method:	device driver call
 purpose:	patches in repairs to mos 5.01
 refer to:	n/a
 last update:	09/15/92
                                                      vernum
 Latest version of Driver supported by this Driver:   1.13

======================================================================

NOTE:	comments for each patch go directly in the patch template.

	to locate this doc quickly, search for the string 'who:'
	and then use your editor's search-again function to step
	through each patch template.

NOTE:	to find all points where the version number has to be updated,
	search for the string 'vernum'.

======================================================================^

;==== version specific data

MO2SEG_OFS	equ	1082h
SCBORG		equ	240h

;==== patch template

comment #
,e0
!!!!!!!!!!!!!!! START OF PATCH TEMPLATE  (DON'T COPY THIS LINE) !!!!!!!!!
if 0 eq 0
;===============================================<< start of patch section
patch_ver ???

comment ^
,es
Version: x.xx	Creation date: mm/dd/yy

!!!!! tech support notes go here

,ee

who: 

!!!!! r&d notes go here

^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing


;--<< patch lists (non-resident)

plist_start 
plist_end

;--<< init code (non-resident)

ifunc_start
	assume ds:dgroup,es:nothing,ss:nothing
ifunc_end 

;-----------<< end of patch section
endif

!!!!!!!!!!!!!!! END OF PATCH TEMPLATE  (DON'T COPY THIS LINE) !!!!!!!!!!!
,e1
#

;==== misc include files

.xlist
	include macros.inc
	include options.inc
	include mosregs.inc
	include mospsp.inc
	include mostfb.inc
	include mosgfb.inc
	include mosbdb.inc

tcb	segment at 0
	include mostcb.inc
tcb	ends

scbx	segment at 0
	assume cs:scbx
	org	SCBORG
	include mosscbdf.inc
scbx	ends
.list

;==== define the segment ordering

dgroup	group	_TEXT,INITSEG,LSEG1,LSEG2,LSEG3

_TEXT	segment para public 'CODE'
_TEXT	ends

INITSEG	segment para public 'CODE'
INITSEG	ends

LSEG1	segment para public 'DATA'
lseg1_start label byte
LSEG1	ends

LSEG2	segment para public 'DATA'
lseg2_start label word
LSEG2	ends

LSEG3	segment para public 'DATA'
lseg3_start label byte
LSEG3	ends

;==== patch language macros

include patchmac.inc

;==== start of driver code/data

_TEXT	segment
        assume  cs:dgroup,ds:nothing,es:nothing,ss:nothing
begin:
	dd	-1
	dw	8000h			; this is a character device
	dw	stratg			; pointer to strategy routine
	dw	interupt		;   "     " interrupt	"
	              ;vernum
	db	'_501_113'

request dd	0			; area to store request by mos

stratg:
	mov	word ptr cs:[request],bx
	mov	word ptr cs:[request+2],es
	retf

interupt:
	pushset bx,es
	les	bx,cs:[request]
	cmp	byte ptr es:[bx+2],0
	jne	i1
	call	init
i1:
	popset	bx,es
	retf

;==== resident global variables

sbios		dw	40h
zeroseg		dw	0

mos_seg		dw	?		; location of mos segment
mo2_seg		dw	?		; location of mo2 segment
scb_seg		dw	?		; location of scb segment
init_seg	dw	?		; location of init segment
tcb_seg		dw	?		; location of tcb segment for task 0

;==== start of patch code

if 0 eq 0
;===============================================<< start of patch section
patch_ver 001		; correction to ms2a in mosmiman

comment ^
,es
Version: 0.01	Creation date: 04/02/92 

fix for problem where keying cntrl-enter or cntrl-j during a read of
the pipe driver would cause a crash.  same problem could occur during
the read of any character device other than con.  reported by john
englezou on 24 feb 1992.

,ee

who: mjs

below is function ms2a, located within mosmiman.asm.  it needs to
have a prologue that pushes ax, bx and cx and an epilogue that pops
these registers.

   mo2:4645 8d1e9c05      lea      bx,[059c]
   mo2:4649 b90100        mov      cx,0001
   mo2:464c b004          mov      al,04
   mo2:464e e89ef2        call     38ef
   mo2:4651 c3            ret
^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing
p100a:
	push	ax
	push	bx
	push	cx
	lea	bx,[tcb%dbuf]
	mov	cx,1
	fc_p2m	MO2,464ah	; call to far/near calling shell
	pop	cx
	pop	bx
	pop	ax
	fj_p2m	MO2,4651h

;--<< init code (non-resident)

fj_m2p	MO2, 4645h, p100a
fcs_m	MO2, 464ah, 38efh

;-----------<< end of patch section
endif


if 0 eq 0
;===============================================<< start of patch section

patch_ver 002		; fix print screen on enhanced kybd

comment ^
,es
Version: 0.02	Creation date: 04/08/92 

corrects problem where the printscreen key on an enhanced keyboard
was being ignored if it was pressed by itself.  

,ee

who: mjs

below is the prtscr function from mosint16.asm.  it must be replaced
with the new prtscr function shown below.  also, the entry for
the printscrn scancode (37h) within the base table must be changed
so that the prtscr function is called.  this entry is located
at address mos:b532

mos:b430 0ac9          or	cl,cl
mos:b432 7803          js	b437
mos:b434 ba0100        mov	dx,0001
mos:b437 b8ffff        mov	ax,ffff
mos:b43a c3            ret

^

;--<< patch code (resident)

kbs_rshf equ	01h			; right shift pressed
kbs_lshf equ	02h			; left shift pressed
kbc_e0	 equ	02h			; e0 prefix last

	assume	ds:nothing,es:tcb,ss:nothing
@prtscr:
	or	cl,cl
	js	@prtsc1 		; skip if releasing the key

; if last code was e0, always do print screen
; else, only do if a shift key is down
; else, return a '*' (must have gotten here from the base case)

	test	[tcbkbctl],kbc_e0
	jnz	@prtsc0
	test	[tcbkshft],(kbs_lshf + kbs_rshf)
	jnz	@prtsc0
	mov	ax,372ah
	jmp	short @prtsc2
@prtsc0:
	mov	dx,1
@prtsc1:
	mov	ax,-1
@prtsc2:
	fj_p2m	mos, 0b43ah

;--<< patch lists (non-resident)

plist_start mos
	dw	0b532h
	db	2
	db	8,0
	dw	0ffffh
plist_end

;--<< init code (non-resident)

fj_m2p	mos, 0b430h, @prtscr

;-----------<< end of patch section
endif


if 0 eq 0
;===============================================<< start of patch section

patch_ver 003  		; patch for INT 21h fun 12 (Lanlink Pro)

comment ^
,es
Version: 0.03	Creation date: 04/15/92 

corrections for DOS 5.0 to MOS 5.01 lanlink pro

,ee

who: sah

corrections for dos 5.0 to mos 5.01 lanlink pro and int 21h function
12h, we were not setting attribute correct for non-extended fcb case.

The following code is a the start mosfun12, where we are setting
secoper to 0, we need to zero out ah (user as serarch method) because
ah was never being set for non-extended FCB case.  I found that DOS
only search normal files for non-extended FCB's (DOS doc is really not
clear on this issue).  The following is portion of code in 5.01 kernel
that is question.

MO2:0280 36		SS:
MO2:0281 C6470400     MOV BYTE PTR [BX+4],0
MO2:0285 26		ES:
^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing

p102a:
	xor	ah,ah
	mov	byte ptr ss:[bx+4],0	      ;	mov byte ptr [bx].secoper,0
	retf

;--<< init code (non-resident)

fc_m2p  MO2, 280h, p102a

;-----------<< end of patch section
endif


if 0 eq 0
;===============================================<< start of patch section

patch_ver 004		; modify mosddcon to use i16f10/11 for ehanced kybd

comment ^
,es
Version: 0.04	Creation date: 04/17/92 

modify mos to recognize f11 and f12 properly.  this is necessary to
support the corresponding changes to spool -- so hotkeys such as
alt-f11 can be used.

,ee

who: mjs

modify mosddcon to be sensitive to the type of keyboard.  make
i16f10/11 calls for enhanced keyboards and to internally convert an
e0 prefix to a 0 prefix.

^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing

call16 proc near
	push	bx
	push	es
	mgetzero es
	mov	bl,byte ptr es:[496h]
	and	bl,10h
	or	ah,bl
	pop	es
	pop	bx
	int	16h
	ret
call16 endp

;----

p004a:				; below in28loop
	mov	ah,1
	call	call16
	jz	p004a1
	fj_p2m	MOS,4371h
p004a1:
	fj_p2m	MOS,4363h

;----

p004b:				; below in28loop
	xor	ah,ah
	call	call16
	fc_p2m	MOS,437bh	; far/near shell @437b, near call to 43ce
	or	ax,ax
	jnz	p004b1
	mov	ax,0103
p004b1:
	fj_p2m	MOS,4384h

;----

p004c:				; below in28loop
	mov	ah,1
	call	call16
	jnz	p004c1
	fj_p2m	MOS,43b9h
p004c1:
	fj_p2m	MOS,4354h

;----

p004d:				; keytrans
	cmp	al,0e0h
	jne	p004d1
	xor	al,al
p004d1:
	cmp	byte ptr ss:[801],0ffh
	fj_p2m	MOS,43d4h

;----

p004e:				; ndinput
	mov	ah,1
	call	call16
	jz	p004e1
	fj_p2m	MOS,4432h
p004e1:
	fj_p2m	MOS,444ah

;----

p004f:				; instat
	mov	ah,1
	call	call16
	pop	ax
	fj_p2m	MOS,446ah

;----

p004g:				; inflsh
	mov	ah,1
	call	call16
	jz	p004g1
	xor	ah,ah
	call	call16
	jmp	short p004g
p004g1:
	fj_p2m	MOS,447fh


;--<< init code (non-resident)

fj_m2p MOS,436bh,p004a		; below in28loop
fj_m2p MOS,4376h,p004b		; below in28loop
fcs_m MOS,437bh,43ceh		; below in28loop
fj_m2p MOS,43b3h,p004c		; below in28loop
fj_m2p MOS,43ceh,p004d		; keytrans
fj_m2p MOS,442ch,p004e		; ndinput
fj_m2p MOS,4465h,p004f		; instat
fj_m2p MOS,4473h,p004g		; inflsh

;-----------<< end of patch section
endif


if 0 eq 0
;===============================================<< start of patch section

patch_ver 005		; correction for pack EXE's

comment ^
,es
Version: 0.05	Creation date: 04/17/92 

additional corrections for exec logic handling of packed exe files.  

,ee

who: sah

I found that enlarging the enviroment is not always possiable (ie ms
mouse.com frees the enviroment before going tsr).  so what it does
instead is allocated an additional piece of memory so that exepack
programs will not conflict with 1st 4k of memory.

^

;--<< patch lists (non-resident)

plist_start mos
	dw      06221h
	db	8
	db	02bh, 05eh, 0b2h, 0b4h
	db	048h, 090h, 090h, 090h
	dw	0ffffh
plist_end

;-----------<< end of patch section
endif

if 0 eq 0
;===============================================<< start of patch section

patch_ver 006

comment ^
,es
Version: 0.06	Creation date: 04/21/92 

corrected two addresses in my version 0.04 fix that were causing a
stall when dir/p was used.  correction for the brooks
drug/dbts/decstation problem.

,ee

who: mjs

when a task has an int15 intercept and the irq14 or irq6 occurs
during switchtask, can crash.  added logic to mask off irq14 and irq6
during switchtask.

the first section is simply a patch replacement for the 
switchif function.  it was necessary to relocate it to this
patch driver to make room in the kernel for the two calling shells
required for the switchtask patch.

switchif:
mos:90fa 2e            cs:
mos:90fb 803ef99059    cmp	byte ptr [90f9],59
mos:9100 7407          jz	9109
mos:9102 50            push	ax
mos:9103 8cd0          mov	ax,ss
mos:9105 e80d00        call	9115
mos:9108 58            pop	ax
mos:9109 c3            ret

switchtask:
mos:910a 8cc0          mov	ax,es
mos:910c e877fd        call	8e86
mos:910f 8bd8          mov	bx,ax
mos:9111 e858fd        call	8e6c
mos:9114 c3            ret
^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing

p006a:
	push	es
	mov	es,cs:[mos_seg]
	cmp	byte ptr es:[90f9h],059h
	pop	es
	jz	p006a1
	push	ax
	mov	ax,ss
	fc_p2m	MOS,9105h
	pop	ax
p006a1:
	fj_p2m	MOS,9109h

;----

p006b:
	in	al,021h			
	push	ax
	or	al,40h			; mask off irq6
	out	021h,al
	in	al,0a1h			
	push	ax
	or	al,40h			; mask off irq14
	out	0a1h,al
	mov	ax,es
	fc_p2m	MOS,90ffh
	mov	bx,ax
	fc_p2m	MOS,9111h
	pop	ax
	out	0a1h,al			; restore irq14
	pop	ax
	out	021h,al			; restore irq6
	mov	ax,es
	jmp	short p006a1

;--<< patch lists (non-resident)

plist_start mos
	dw      09108h
	db	1
	db	0cbh
	dw      09114h
	db	1
	db	0cbh
	dw	0ffffh
plist_end

;--<< init code (non-resident)

fj_m2p MOS,90fah,p006a
fcs_m MOS,90ffh,8e86h
fj_m2p MOS,910ah,p006b

;-----------<< end of patch section
endif


if 0 eq 0
;===============================================<< start of patch section
patch_ver 007

comment ^
,es
Version: 0.07	Creation date: 04/27/92

This correction solves lockup problems on serial terminals (both
$serial.sys and inteligent serial drivers) in specific condition.
The condition that we found was with Gallop Printing FoxPro 2.0 
application.

,ee

who: SAH

Channges to suppend2 so that intsl is save, set to 0,
and then restored. If this is not done, in some sitituations
when tsl logic returns out tsl, intsl could be non-zero thus
allowing for no others tasks to be executed.

The following code is in 5.01 kernel's suspend2

suspend2:
mos:D988 1E            PUSH	DS                                 
mos:D989 2E            CS:	                                   
mos:D98A 8E1E8A10      MOV	DS,[108A]                          
mos:D98E 36            SS:	                                   
mos:D98F FF368A00      PUSH	[008A]                             
mos:D993 E81900        CALL	D9AF                               
mos:D996 36            SS:	                                   
mos:D997 8F068A00      POP	[008A]                             
mos:D99B 1F            POP	DS                                 
mos:D99C C3            RET	                                   

^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing


suspend2 proc far
	assume	ss:tcb
	push	[tcbsp]
	mov	al,ds:[0ff2h]		; intsl is located at ds:0ff2
	push	ax
	mov	byte ptr ds:[0ff2h],0	; intsl is located at ds:0ff2
	fc_p2m	MOS,0d993h		; far/near shell @d993, near call to d9af
					; call suspendx
	pop	ax
	mov	ds:[0ff2h],al		; intsl is located at ds:0ff2
	pop	[tcbsp]
	assume	ss:nothing
	fj_p2m	MOS,0d99bh

suspend2 endp 


;--<< init code (non-resident)

fj_m2p MOS,0d98eh,suspend2
fcs_m MOS,0d993h,0d9afh		; call to suspendx

;-----------<< end of patch section
endif

if 0 eq 0
;===============================================<< start of patch section
patch_ver 100

comment ^
,es
Version: 1.00	Creation date: 05/07/92

Correct problem where running format on a write protected diskette
doesn't result in a critical error message.

,ee

who: mjs

within mosfun44.asm, restored "add ax,19" to the io0d function.  

from the io0d function (mosfun44.asm):

1b02:2770 247f          and	al,7f
1b02:2772 f6c480        test	ah,80
1b02:2775 7505          jnz	277c
1b02:2777 33c0          xor	ax,ax
1b02:2779 eb03          jmp	277e
1b02:277b 90            nop
ioctl0db:
1b02:277c 32e4          xor	ah,ah
ioctl0dx:
1b02:277e 5c            pop	sp
1b02:277f 5d            pop	bp
1b02:2780 c3            ret

^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing

; for the io0d function (mosfun44.asm):

io0dfix:
	jnz	io0df1
	xor	ax,ax
	jmp	short io0df2
io0df1:
	xor	ah,ah
	add	ax,19
io0df2:
	fj_p2m	MO2,277eh


;--<< init code (non-resident)

fj_m2p MO2,2775h,io0dfix

;-----------<< end of patch section
endif

if 0 eq 0
;===============================================<< start of patch section
patch_ver 101

comment ^
,es
Version: 1.01	Creation date: 05/19/92

This fix allows user to screen switch to his own task.  This can be use
by serial termial users to refresh the screen.

,ee

who: SAH

Just NOP out the je when test so see if the id is the same as requested

^


plist_start mos
	dw	0b8d2h
	db	2
	db	90h
	db	90h
	dw      0ffffh
plist_end

;--<< init code (non-resident)


;-----------<< end of patch section
endif

if 0 eq 0
;===============================================<< start of patch section

patch_ver 102

comment ^
,es
Version: 1.02	Creation date: 05/28/92

This corrections fix the problem with MOS 5.01 not displaying video 
information to terminals.

,ee

who: sah

set cx to scbtimer after calling savecrit, savecrit destroys cx register

^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing


;--<< patch lists (non-resident)

plist_start mos
	dw	0da05h
	db	21
	db	0fah,80h,3eh,95h,04h,00h,75h,18h
	db	0c6h,06h,95h,04h,01h,0fbh,0e8h,12h
	db	0f9h,8bh,0eh,1bh,05h
	dw	0ffffh
plist_end

;--<< init code (non-resident)

;-----------<< end of patch section
endif


if 0 eq 0
;===============================================<< start of patch section
patch_ver 103

comment ^
,es
Version: 1.03	Creation date: 07/11/92

Corrects lock-up problem when a user tries to execute a file that is
classified as execute-only.

,ee

who: mjs

nop out test of entry flags in mosfun3d.  sah's change to make sim21
do stack biasing cause the entry flags to be changed.  this was 
a strange type of entry parameter to use in the first place.

^

;--<< patch lists (non-resident)

plist_start mo2
	dw	1497h
	db	7
	db	90h,90h,90h,90h,90h,90h,90h
	dw	0ffffh
plist_end

;-----------<< end of patch section
endif

if 0 eq 0
;===============================================<< start of patch section
patch_ver 104

comment ^
,es
Version: 1.04	Creation date: 07/21/92

Corrects MOS's file sharing logic to make it match DOS's in all cases.
This fix is necessary for llnetbios.

,ee

who: mjs

replaced the chkacc function.

^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing

;======================================================================
; chkacc - check access to a file or device
; 
; make sure requested access is permitted by others
; make sure access permitted others is consistent with access 
; already granted others
; 
; in:	al = reqested access
;	 bits 2-0 = requested access
;	 bits 6-4 = requested permission
;	ds -> bdb
;	es -> gfb
;	ss -> tcb
; 
; out:	c if access can't be granted
;	 ax = error code
;	nc if access can be granted
;	 ax = undefined
; 
;====================================================================^

share_compt	equ	0    	; compatibility
share_dn_rw	equ	1	; deny read/write
share_dn_w	equ	2	; deny write
share_dn_r	equ	3	; deny read
share_dn_no	equ	4	; deny none

access_r	equ	0	; read access
access_w	equ	1	; write access
access_rw	equ	2	; read/write access
access_none	equ	3	; no access (special mos-specific value)

rdx	equ	00h			; read operation
wrx	equ	01h			; write operation

accdeny equ	5			; access denied
share	equ	32			; sharing violation
ro	equ	01h			; read-only

failx	equ	08h			; fail not allowed
retryx	equ	10h			; retry not allowed
ignorex equ	20h			; ignore not allowed
allx	equ	failx or retryx or ignorex
sysx	equ	failx or retryx 	; ignore not allowed in system areas
dosx	equ	00h or allx		; dos area of disk?
fatx	equ	02h or sysx		; fat area
dirx	equ	04h or sysx		; dir area
datax	equ	06h or allx		; data area

gfbseg		equ	bp+0

timloc		equ	006ch

chkacc proc near
	push	bp
	push	bp
	mov	bp,sp
	mov	[gfbseg],es
	push	es
	push	si
	push	cx
	push	bx
	push	dx
	push	di

; check for open of a character device 

	cmp	es:[gfbdev],0
	je	ch0
	clc
	jmp	chkacy
ch0:

; derive share and access values from entry al

	mov	bl,al
	mov	bh,al
	and	bl,07h			; bl = new.access
	shr	bh,1
	shr	bh,1
	shr	bh,1
	shr	bh,1
	and	bh,07h			; bh = new.share

; check for write access to a read-only file

	xor	di,di			; init read_only flag
	test	es:[gfbattr],ro
	jz	ch1
	mov	di,1			; set read_only flag
	cmp	bl,access_r
	je	ch1
	cmp	bl,access_none		; special "no access" value
	je	ch1
	mov	ax,accdeny
	stc
	jmp	chkacy
ch1:

; check for critical error situations
;
; if new requested share mode is compatibility
; and if have any existing open that is not compatibility
; then retry, issuing critical error when exhausted

	cmp	bh,share_compt
	ljne	ch2
ch13:
	mov	cx,ss:[tcbntry]
	inc	cx			; tcbntry retries + first try
ch14:
	mov	es,[gfbseg]
	assume	es:gfb
	mov	dx,es:[gfbtfb]
ch4:
	or	dx,dx
	ljz	ch2
	mov	es,dx				  
	assume	es:tfb
	mov	ah,es:[tfbalow]		; fetch tfb.share
	and	ah,07h			; strip off inheritance bit

; special case test for read-only files

	or	di,di
	jz	ch20
	cmp	ah,share_dn_w
	je	ch3
	cmp	ah,share_dn_no
	je	ch3
ch20:
	cmp	ah,share_compt
	je	ch3
	dec	cx
	jcxz	ch5

; setup for and call suspend

	push	es
	push	ax
	mov	ax,40h
	mov	es,ax
	mov	ax,es:[timloc]		; get current system timer
	mov	ss:[tcbwinfo],ax	; store current system time for polling
	mov	word ptr ss:[tcbpoll],2ac6h  ; offset mo2:sharepoll
	mov	ax,cs:[mo2_seg]
	mov	word ptr ss:[tcbpoll+2],ax
	pop	ax
	pop	es
	and	ss:[tcbwait],not 06h	; clear bits 2,1
	or	ss:[tcbwait],01h	; set bit 0

	fc_p2m	MO2,02974h	; shell for callmos1 suspend

	jmp	short ch14
ch5:

; setup for and call toint24

	mov	es,[gfbseg]
	assume	es:gfb
	cmp	es:[gfbdev],0
	jne	chkacx1
	mov	al,ds:[bdbid]
chkacx1:
	push	ds
	lds	si,es:[gfbdrvr]
	push	di
	mov	di,12			; general error sent to int 24h
	mov	ss:[tcberrcod],share	; sharing violation
	mov	ah,dosx and (not ignorex)  ; ah as defined by int 24 doc

	fc_p2m	MO2,02970h	; shell for toint24

	pop	di
	pop	ds
	ljc	chkacy			; fail chosen
	ljnz	chkacy			; ignore chosen
	jmp	ch13
ch3:
	assume	es:tfb
	mov	dx,es:[tfbngfb]
	jmp	ch4
ch2:

; check for sharing violations
;
; if new requested share mode is not compatibility
; and if have existing open in compatibility
; then return a sharing violation error

	cmp	bh,share_compt
	je	ch6
	mov	es,[gfbseg]
	assume	es:gfb
	mov	dx,es:[gfbtfb]
ch7:
	or	dx,dx
	jz	ch6
	mov	es,dx				  
	assume	es:tfb
	mov	ah,es:[tfbalow]		; fetch tfb.share
	and	ah,07h			; strip off inheritance bit
	cmp	ah,share_compt
	jne	ch8

; special case test for read-only files

	or	di,di
	jz	ch21
	cmp	bh,share_dn_w
	je	ch8
	cmp	bh,share_dn_no
	je	ch8
ch21:
	mov	ax,share
	stc
	jmp	chkacy
ch8:
	mov	dx,es:[tfbngfb]
	jmp	short ch7
ch6:

; if basic conflict between existing and new modes
; then return a sharing violation error

	mov	es,[gfbseg]
	assume	es:gfb
	mov	dx,es:[gfbtfb]
ch9:
	or	dx,dx
	jz	ch10
	mov	es,dx				  
	assume	es:tfb
	mov	ah,es:[tfbalow]		; fetch tfb.share
	and	ah,07h			; strip off inheritance bit
	mov	al,bl			; fetch new.access

	fc_p2m	MO2,0296ch	; shell for accok

	jc	ch12
	mov	ah,bh			; fetch new.share
	mov	al,es:[tfbacc]		; fetch tfb.access

	fc_p2m	MO2,0296ch	; shell for accok

	jc	ch12
	mov	dx,es:[tfbngfb]
	jmp	short ch9
ch12:
	mov	ax,share
	stc
	jmp	chkacy
ch10:

; if make it through all error checking, return "ok"

	xor	ax,ax
chkacy:
	pop	di
	pop	dx
	pop	bx
	pop	cx
	pop	si
	pop	es
	pop	bp
	pop	bp

	fj_p2m	mo2,02ac5h		; to a ret in the kernel

chkacc endp

;--<< patch lists (non-resident)

plist_start MO2			; setup calling shell for suspend
	dw	02974h
	db	6
	db	0e8h,035h,04ch,09dh,0d9h,0cbh
	dw	0ffffh
plist_end

;--<< init code (non-resident)

fj_m2p MO2,02967h,chkacc

fcs_m MO2,0296ch,02ae2h		; shell for accok

fcs_m MO2,02970h,07bd5h		; shell for toint24

;-----------<< end of patch section
endif

if 0 eq 0
;===============================================<< start of patch section
patch_ver 105

comment ^
,es
Version: 1.05	Creation date: 08/06/92

Correct problems with INT D4h function 1b01h

,ee

who: SAH

change jnc into jnz

^
;--<< patch lists (non-resident)

plist_start MOS
	dw	854ah
	db	1
	db	75h
	dw	0ffffh
plist_end


;-----------<< end of patch section
endif

patch_ver 106

comment ^
,es
Version: 1.06	Creation date: 08/06/92

Corrected INT 29h, simptons would mostly like be invalid
characters to screen

,ee

who: SAH

Save BX around INT org INT d4h call

^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing


NewINT29 proc   far
	push	bx
	mov	bx,7
	mov	ah,0eh
	int	10h
	pop	bx
	ret
NewINT29 endp


plist_start MOS
	dw	6be1h
	db	2
	db	90h,90h
	dw	0ffffh
plist_end



fc_m2p  MOS, 6bdch, NewINT29


;-----------<< end of patch section

if 0 eq 0
;===============================================<< start of patch section
patch_ver 107

comment ^
,es
Version: 1.07	Creation date: 08/11/1992

Corrects minor security leak.  If you're not signed on to security
but you know the name of a secured directory, you can make a call to
int21 function 3b (the change directory function) and make that
secured directory the current directory.  You won't be able to read
or write any files, but you can change your current directory to one
that is secured.  This patch prevents int21 function 3b from allowing
this in the first place.

Note: Due to other system calls made, you can't use the CD command to
test this fix.

,ee

who: mjs

added call to classlvl to i21f3b

^

dclass0 equ	13			; offset of class byte

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing

;	assume	ds:bdb,es:dbb,ss:tcb
p1:
	mov	al,es:[dbbbuf+si+dclass0]
	fc_p2m	MO2,1189h		; call classlvl
	cmp	al,1
	mov	ax,5
	jnb	p1a
	fj_p2m	MO2,1280h		; mosf3bx
p1a:
	mov	cx,ds:[bdbroot]		; root directory cluster for the real drive
	mov	[bp-6],cx
	mov	bl,ds:[bdbid]
	fj_p2m	MO2,118fh


;--<< init code (non-resident)

fj_m2p	MO2,1184h,p1
fcs_m	MO2,1189h,75d2h			; classlvl

;-----------<< end of patch section
endif

if 0 eq 0
;===============================================<< start of patch section
patch_ver 108

comment ^
,es
Version: 1.08	Creation date: 08/12/1992

Necessary for LANLink Pro to support the copy /c command.  Must be
used with at least version 5.04 of $$SHELL.SYS (should also use
version #5.03 of CLASS.COM with llpro and the 5.04 version of
$$SHELL.SYS)

Bottom line -- for LLPRO use:
 UPDAT501.SYS version 1.08 (or newer)
 $$SHELL.SYS version 5.04  (or newer)
 CLASS.COM version 5.03    (or newer)

,ee

who: mjs

establish intercepts of intd4 and scbfar38 to add function 31h.
this function is used by version 5.04+ of $$shell.sys to read
and set the tcbcdft field.  this hook was necessary for copy /c to
work across lanlink pro.  llpro needed a way to know when the command
processor was changing the default output class.

^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing

orig_d4		dd	?
orig_f38	dd	?

icept_guts:
	push	es
	mov	es,cs:[scb_seg]
	mov	es,es:[scbtcbpc]
	or	al,al
	je	ig1
	mov	es:[tcbcdft],dl
	jmp	short ig2
ig1:
	mov	dl,es:[tcbcdft]
ig2:
	pop	es
	ret

icept_d4:
	cmp	ah,31h
	je	id4a
	jmp	cs:[orig_d4]
id4a:
	call	icept_guts
	iret

icept_f38:
	cmp	ah,31h
	je	i38a
	jmp	cs:[orig_f38]
i38a:
	call	icept_guts
	iret

;--<< init code (non-resident)

ifunc_start
	assume ds:dgroup,es:nothing,ss:nothing
	cli
	xor	ax,ax
	mov	es,ax

; hook intd4

	mov	ax,es:[0d4h*4]
	mov	word ptr cs:[orig_d4],ax
	mov	ax,es:[0d4h*4+2]
	mov	word ptr cs:[orig_d4+2],ax
	mov	word ptr es:[0d4h*4],offset icept_d4
	mov	word ptr es:[0d4h*4+2],cs

; hook scbfar38

	mov	es,[scb_seg]
	mov	ax,word ptr es:[scbfar38]
	mov	word ptr cs:[orig_f38],ax
	mov	ax,word ptr es:[scbfar38+2]
	mov	word ptr cs:[orig_f38+2],ax
	mov	word ptr es:[scbfar38],offset icept_f38
	mov	word ptr es:[scbfar38+2],cs
	sti
ifunc_end 

;-----------<< end of patch section
endif

if 0 eq 0
;===============================================<< start of patch section
patch_ver 109

comment ^
,es
Version: 1.09	Creation date: 08/19/1992

When copy/c is used to change a file's class to one which you do
not currently have access, an access denied message is displayed.
This patch fixes this problem.

,ee

who: mjs

rem out security check in id4f03 -- shouldn't be one.

^

;--<< patch lists (non-resident)

plist_start mos
	dw	7731h
	db	8
	db	90h,90h,90h,90h,90h,90h,90h,90h
	dw	0ffffh
plist_end

;-----------<< end of patch section
endif


if 0 eq 0
;===============================================<< start of patch section
patch_ver 110

comment ^
,es
Version: 1.10	Creation date: 08/25/92

This corrections fixes problems with PC-Support and
possiably other TSRs

,ee

who: SAH

During INT 21h function 31h, if dx is less than 6 than set DX to 6.  I
verify this under DOS.

^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing

FixFun31 proc	far							 
	mov	bx,[bp+14h]
	cmp	bx,6
	jae	fixfun31a
	mov	bl,6
fixfun31a:
	mov	[bp+16h],bx
	ret
FixFun31 endp

;--<< patch lists (non-resident)

plist_start MOS
	dw	570dh
	db	1
	db	90h
	dw	0ffffh
plist_end

fc_m2p  MOS, 5708h, FixFun31

;-----------<< end of patch section
endif


if 0 eq 0
;===============================================<< start of patch section
patch_ver 111

comment ^
,es
Version: 1.11	Creation date: 08/31/92

Change default setting of MOSADM HOLD COMx to 0 instead of 15 secs

,ee

who: SAH

^

;--<< patch lists (non-resident)

plist_start MOS
	dw	0edb7h
	db	2
	db	0ebh,13h
	dw	0ffffh
plist_end

;--<< init code (non-resident)

ifunc_start
	assume ds:dgroup,es:tcb,ss:nothing
	cli
	push	es
	push	di

	mov	es,[tcb_seg]	
	xor	ax,ax
	mov	cx,24/2
	cld
	mov	di,offset tcb_com_hold
	rep	stosw

	pop	di
	pop	es
ifunc_end 

;-----------<< end of patch section
endif

if 0 eq 0
;===============================================<< start of patch section
patch_ver 112

comment ^
,es
Version: 1.12	Creation date: 09/14/92

Corrections BusinessWorks accounting package which cause a protection
exception during INT 21h function 68h

,ee

who: SAH

call findphdl to convert handle to system handle, for INT 21h function
68h search loop for handle.

^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:nothing

FixFun68 proc	far
	mov	ax,6
	mov	bx,[bp+12h]
	fc_p2m	MO2,225ch		; call findphdl
	assume	ss:tcb	
	mov	ds,[tcbtfbpf]		; first tfb for this tcb.
	fj_p2m  MO2,2262h
FixFun68 endp	

fj_m2p	MO2,2257h,FixFun68
fcs_m	MO2,225ch,0a0ebh  		; findphdl

;-----------<< end of patch section
endif


if 0 eq 0
;===============================================<< start of patch section
patch_ver 113

comment ^
,es
Version: 1.13	Creation date: 09/15/92

Corrections for DIRMAGIC under PC-MOS which was causing a internal error
during function 4bh

,ee

who: SAH

If application free a mcb, then resizes it...we need to mark it as
allocated.

^

;--<< patch code (resident)
	assume ds:nothing,es:nothing,ss:tcb

FixFun4a proc	far
	mov	ds,bx
	mov	bx,[bp+12h]
	cmp	word ptr ds:[1],0 	; if requested block is free
	jne	fun4askip		; no...
	push	ax
	mov	ax,[tcbpsp]		; we must set owner of request
	mov	ds:[1],ax		; block to current psp
	pop	ax
fun4askip:
	ret
FixFun4a endp

fc_m2p  MOS, 5AFAh, FixFun4a


;-----------<< end of patch section
endif


;==== init code

end_res label	byte
	nop
                                                                     ;vernum
instmsg 	db	13,10,'UPDAT501.SYS driver installed, version 1.13           ',13,10,'$'  ;@@xlat
notmosmsg	db	13,10,'UPDAT501.SYS must only be used with PC-MOS version 5.01                 ',7,7,13,10,'$'  ;@@xlat
notmos501	db	13,10,'UPDAT501.SYS detects mismatched kernel code           ',7,7,13,10,'$'  ;@@xlat
notsmpmsg	db	13,10,'UPDAT501.SYS must be loaded globally                ',7,7,13,10,'$'	;@@xlat
syn_err		db	13,10,'UPDAT501.SYS syntax error         ',13,10,'$'  ;@@xlat
syserr		db	13,10,'UPDAT501.SYS system error         ',13,10,'$'  ;@@xlat
chng_msg	db	13,10,'Deactivated versions: $             ' ;@@xlat

changed		db	0		; signals deactivation from switches
w100		dw	100
w10		dw	10
crlf		db	13,10,'$'
hundred		db	100
ten		db	10

;chk100		dw	?		; offset within segment
;		db	?		; # of bytes in list
;		db	?		; the list

	subttl chk_code - verify code match in kernel
	page
;======================================================================
;.fs
; chk_code - verify code match in kernel
;
; verify that a certain section of the kernel contains the expected
; binary code by comparing with a local reference string.  the format
; for the local reference string is:
;
;	dw	x		; offset within segment
;	db	x		; # of bytes in list
;	db	x,x,x...	; the list
;
; in:	ax = kernel segment to check
;	si = offset of list
;
; out:	zr if match, else nz
;	all other regs preserved
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
chk_code proc near
	pushset cx,si,di,ds,es
	cld
	mov	es,ax
	mov	cx,cs
	mov	ds,cx			; need ds:si -> reference string
	mov	di,[si]
	mov	cl,[si+2]		; need cx = # of bytes
	xor	ch,ch
	add	si,3
	rep	cmpsb			; return with zr or nz flags
	popset	cx,si,di,ds,es
	ret
chk_code endp

	subttl ismos - test for mos
	page
;======================================================================
;.fs
; ismos - test for mos
;
; verify that this program is running under the pc-mos operating system
; before mos specific system calls are made.
;
; in:	none
;
; out:	nz flag if the os is mos
;	zr flag if not
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
ismos	proc	near
	pushset ax,bx,cx,dx
	mov	ax,3000h
	mov	bx,ax			; set ax == bx == cx == dx
	mov	cx,ax			; to read the mos version #
	mov	dx,ax
	int	21h
	push	ax
	mov	ax,3099h		; now insure ax is different
	int	21h			; to read the dos version #
	pop	bx
	cmp	bx,ax			; if bx != ax then mos
	popset	ax,bx,cx,dx
	ret
ismos	endp

	subttl chk_active - determine if a patch version has been deactivated
	page
;======================================================================
;.fs
; chk_active - determine if a patch version has been deactivated
;
; in:	ax = the patch version number
;
; out:	nc if a match found for the patch version number in LSEG2
;	  bh != 0 if active
;	  bh == 0 if inactive
;	cy if a no match found for the patch version number in LSEG2
;
;.fe
;=====================================================================^
        assume  ds:dgroup,es:nothing,ss:nothing
chk_active proc near
	pushset cx,di,es
	mov	di,offset dgroup:lseg2_start
	mov	cx,cs
	mov	es,cx
	mov	cx,lseg2_words
	cld
	repne	scasw
	je	cav1
	stc
	jmp	short cav2
cav1:
	sub	di,offset dgroup:lseg2_start+2
	shr	di,1
	add	di,offset dgroup:lseg3_start
	mov	bh,[di]
	clc
cav2:
	popset cx,di,es
	ret
chk_active endp

	subttl deactivate - deactivate a patch version
	page
;======================================================================
;.fs
; deactivate - deactivate a patch version
;
; in:	ax = the patch version number
;
; out:	nc if a match found for the patch version number in LSEG2
;	cy if a no match found for the patch version number in LSEG2
;
;.fe
;=====================================================================^
        assume  ds:nothing,es:nothing,ss:nothing
deactivate proc near
	pushset bx,cx,di,ds,es
	mov	di,offset dgroup:lseg2_start
	mov	cx,cs
	mov	es,cx
	assume	es:dgroup
	mov	ds,cx
	assume	ds:dgroup
	mov	cx,lseg2_words
	cld
	repne	scasw
	je	dea1
	stc
	jmp	short dea2
dea1:
	sub	di,offset dgroup:lseg2_start+2
	shr	di,1
	add	di,offset dgroup:lseg3_start
	mov	byte ptr [di],0
	mov	[changed],1
	clc
dea2:
	popset bx,cx,di,ds,es
	ret
deactivate endp

	subttl pars_help1 - helper function for parse
	page
;======================================================================
;.fs
; pars_help1 - helper function for parse
;
; in:	ds:si -> what should be a 3 digit decimal number
;	es -> dgroup
;
; out:	ax = binary value of #
;	 si -> character after 3rd digit
;	ax = ffff if syntax error
;
;.fe
;=====================================================================^
        assume  ds:nothing,es:dgroup,ss:nothing
pars_help1 proc near
	pushset bx,cx
	lodsb
	cmp	al,'0'
	jb	psh1
	cmp	al,'9'
	ja	psh1
	mov	bh,al
	sub	bh,'0'
	lodsb
	cmp	al,'0'
	jb	psh1
	cmp	al,'9'
	ja	psh1
	mov	bl,al
	sub	bl,'0'
	lodsb
	cmp	al,'0'
	jb	psh1
	cmp	al,'9'
	ja	psh1
	sub	al,'0'

; at this point, 100s digit is in bh, 10s in bl and 1s in al

	xor	ah,ah
	mov	cx,ax
	mov	al,bh
	mul [hundred]
	add	cx,ax
	mov	al,bl
	mul [ten]
	add	ax,cx
	jmp	short parshx
psh1:
	mov	ax,0ffffh
parshx:
	popset bx,cx
	ret
pars_help1 endp

	subttl parse - check for deactivation switches
	page
;======================================================================
;.fs
; parse - check for deactivation switches
;
; in:	ds:si -> parameter line, terminated with cr or lf
;	es -> dgroup
;
; out:	nc if no parsing error
;	cy if error (message will have been displayed already)
;
;.fe
;=====================================================================^
        assume  ds:nothing;es:dgroup,ss:nothing
parse proc near
	pushset ax,bx,cx,dx,si,di,bp
	cld
prs1:
	lodsb
	cmp	al,' '
	je	prs1
	cmp	al,9
	je	prs1
	cmp	al,13
	je	prs2
	cmp	al,10
	je	prs2
	cmp	al,'/'
	jne	prs3
	call	pars_help1
	cmp	ax,0ffffh
	je	prs3
	mov	bp,ax

; check for a range specification

	cmp	byte ptr [si],'-'
	jne	prs4
	inc	si
	call	pars_help1
	cmp	ax,0ffffh
	je	prs3
prs4:

; here, bp = the starting patch version number.
; and ax = the ending patch version number.

	cmp	bp,ax
	ja	prs3
	mov	bx,ax
prs5:
	mov	ax,bp
	call	deactivate
	cmp	bp,bx
	je	prs6
	inc	bp
	jmp	short prs5
prs6:
	jmp 	prs1
prs2:
	clc
	jmp	short parsx
prs3:
	push	ds
	mov	ax,cs
	mov	ds,ax
	mov	dx,offset dgroup:syn_err
	mov	ah,9
	int	21h
	pop	ds
	stc
parsx:
	popset ax,bx,cx,dx,si,di,bp
	ret
parse endp

	subttl get_m_seg - return the segment value corresponding to a segment code
	page
;======================================================================
;.fs
; get_m_seg - return the segment value corresponding to a segment code
;
; in:	al = segment code
;	ds -> dgroup
;
; out:	ax = segment value
;
;.fe
;=====================================================================^
        assume  ds:dgroup,es:nothing,ss:nothing
get_m_seg proc near
	cmp	al,MOS
	jne	gms1
	mov	ax,[mos_seg]
	jmp	short gms2
gms1:
	cmp	al,MO2
	jne	gms3
	mov	ax,[mo2_seg]
	jmp	short gms2
gms3:
	cmp	al,MOSINIT
	jne	gms4
	mov	ax,[init_seg]
	jmp	short gms2
gms4:
	mov	ax,0f800h		; give'em something harmless
gms2:
	ret
get_m_seg endp

	subttl process_plist - generic table driven patcher routine
	page
;======================================================================
;.fs
; process_plist - generic table driven patcher routine
;
; in:	ds:si-> patch list:   (terminated with offset of ffffh)
;	es -> code segment to patch
;
;	  offset  size   description
;	  ------  ----   -----------
;	    0	  word   offset to start patching
;	    2	  byte   size of array 
;	    3     var	 array of above size
;
; can repeat the above record format.
; use ffff to mark end of list.
;
; out:	
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
process_plist proc near
	pushset ax,cx,si,di
	cld
plp1:
	lodsw
	cmp	ax,0ffffh
	je	plp2
	mov	di,ax
	lodsb
	mov	cl,al			; get size
	cmp	cl,0
	je	plp1
	xor	ch,ch
	rep	movsb			; move array
	jmp	short plp1
plp2:
	popset ax,cx,si,di
	ret
process_plist endp

	subttl process_lseg1 - process the entries in the LSEG1 segment
	page
;======================================================================
;.fs
; process_lseg1 - process the entries in the LSEG1 segment
;
; in:	
;
; out:	nc if no error
;	cy if system error
;
;.fe
;=====================================================================^
        assume  ds:nothing,es:nothing,ss:nothing
process_lseg1 proc near
	pushset ax,bx,si,ds
	mov	ax,cs
	mov	ds,ax
	assume	ds:dgroup
	mov	si,offset dgroup:lseg1_start
	cld

; turn interrupts off through the entire list parsing process

	cli
prl1:

; fetch the operation code

	lodsb
	cmp	al,LCODE_EOL
	lje	prl2
	mov	bl,al

; fetch the patch version number and see if it has been
; deactivated.  set bh = 0 for inactive, != 0 for active.

	lodsw
	call	chk_active
	ljc	prlx

; decode the operation code

	cmp	bl,LCODE_SETSEG
	jne	prl4
	cmp	bh,0
	je	prl5
	mov	al,[si]
	call	get_m_seg
	mov	bx,[si+1]
	mov	[bx],ax
prl5:
	add	si,3
	jmp 	prl6
prl4:
	cmp	bl,LCODE_SETFJM
	jne	prl7
	cmp	bh,0
	je	prl8
	mov	al,[si]
	call	get_m_seg
	mov	es,ax
	mov	di,[si+1]
	mov	cx,[si+3]
	mov	al,FAR_JMP_OPCODE
	stosb
	mov	ax,cx
	stosw
	mov	ax,cs
	stosw
prl8:
	add	si,5
	jmp 	prl6
prl7:
	cmp	bl,LCODE_SETFCM
	jne	prl9
	cmp	bh,0
	je	prl10
	mov	al,[si]
	call	get_m_seg
	mov	es,ax
	mov	di,[si+1]
	mov	cx,[si+3]
	mov	al,FAR_CALL_OPCODE
	stosb
	mov	ax,cx
	stosw
	mov	ax,cs
	stosw
prl10:
	add	si,5
	jmp 	prl6
prl9:	
	cmp	bl,LCODE_INITCALL
	jne	prl11
	cmp	bh,0
	je	prl12
	sti
	pushf
	pushset ax,bx,cx,dx,si,di,bp,ds,es
	call	word ptr [si]
	popset ax,bx,cx,dx,si,di,bp,ds,es
	popf
	cli
prl12:
	add	si,2
	jmp 	prl6
prl11:
	cmp	bl,LCODE_PLIST
	jne	prl13
	cmp	bh,0
	je	prl14
	mov	al,[si]
	call	get_m_seg
	mov	es,ax
	push	si
	mov	si,[si+1]
	call	process_plist
	pop	si
prl14:
	add	si,3
	jmp 	prl6
prl13:
	cmp	bl,LCODE_CSHELL
	jne	prl15
	cmp	bh,0
	je	prl16
	mov	al,[si]
	call	get_m_seg
	mov	es,ax
	mov	di,[si+1]
	mov	cx,[si+3]
	sub	cx,di
	sub	cx,3
	mov	al,NEAR_CALL_OPCODE
	stosb
	mov	ax,cx
	stosw
	mov	al,FAR_RET_OPCODE
	stosb
prl16:
	add	si,5
	jmp 	prl6
prl15:
	stc
	jmp	short prlx
prl6:
	jmp 	prl1
prl2:
	clc
prlx:
	sti
	popset ax,bx,si,ds
	ret
process_lseg1 endp

	subttl report_chngs - report the deactivated versions.
	page
;======================================================================
;fs
; report_chngs - report the deactivated versions.
;
; in:	none
;
; out:	none
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
report_chngs proc near
	mov	ax,cs
	mov	ds,ax
	assume	ds:dgroup
	mov	dx,offset dgroup:chng_msg
	mov	ah,9
	int	21h
	mov	si,offset dgroup:lseg2_start
	mov	di,offset dgroup:lseg3_start
	mov	cx,lseg2_words
	xor	bp,bp			; once flag
	cld
rpc1:
	lodsw
	cmp	byte ptr [di],0
	jne	rpc3
	or	bp,bp
	je	rpc2
	push	ax
	mov	dl,','
	mov	ah,2
	int	21h
	mov	dl,' '
	mov	ah,2
	int	21h
	pop	ax
rpc2:
	xor	dx,dx
	div	[w100]
	push	dx
	mov	dl,al
	add	dl,'0'
	mov	ah,2
	int	21h
	pop	ax
	xor	dx,dx
	div	[w10]
	push	dx
	mov	dl,al
	add	dl,'0'
	mov	ah,2
	int	21h
	pop	dx
	add	dl,'0'
	mov	ah,2
	int	21h
	mov	bp,1
rpc3:
	inc	di
	loop	rpc1
	mov	dx,offset dgroup:crlf
	mov	ah,9
	int	21h
	ret
report_chngs endp

	subttl init - initialize this device driver
	page
;======================================================================
;fs
; init - initialize this device driver
;
; verify mos is the os, then dynamically patch the kernel
;
; in:	none
;
; out:	none
;
;.fe
;=====================================================================^
	assume	ds:nothing,es:nothing,ss:nothing
init proc near
	pushset ax,bx,cx,dx,si,di,bp,ds,es
	mov	ax,cs
	mov	ds,ax
	assume	ds:dgroup

; make sure this is mos

	call	ismos
	jnz	yesmos
	mov	dx,offset dgroup:notmosmsg
	xor	cx,cx
	jmp	initx
yesmos:

; make sure this is version 5.01

	mov	ax,3000h
	mov	bx,ax			; set ax == bx == cx == dx
	mov	cx,ax			; to read the mos version #
	mov	dx,ax
	int	21h
	xchg	ah,al
	cmp	ax,0501h
	je	is501
	mov	dx,offset dgroup:notmosmsg
	xor	cx,cx
	jmp	initx
is501:

; make sure this driver is loaded within the smp

	mov	dx,cs
	mov	ah,25h
	int	services
	or	ax,ax
	jnz	in_smp
	mov	dx,offset dgroup:notsmpmsg
	xor	cx,cx
	jmp	initx
in_smp:

; setup es -> scb for later use within interrupt disabled section
; note: its ok to use the intd4fun02 method since this driver will
; not be used with any version after 5.01

	mov	ah,02
	int	services
	assume	es:nothing
	mov	[scb_seg],es

; at the time device drivers are called for initialization, the
; high word of tcbdta points to the init code segment.
; Also save task 0's tcb segment 

	mov	es,es:[scbtcbpf]
	mov	[tcb_seg],es
	mov	ax,word ptr es:[tcbdta+2]
	mov	[init_seg],ax

; use es->scb to fetch the mos segment and then use that
; to derive the mo2 segment value

	mov	es,[scb_seg]
	mov	ax,es:[scbmosadr]
	mov	[mos_seg],ax
	mov	es,ax
	mov	ax,es:[MO2SEG_OFS]
	mov	[mo2_seg],ax


;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

; check to see if code is correct

;	mov	si,offset dgroup:chk100 	; int16      (ver 1.00/1.06)
;	call	chk_code
;	jnz	badcode
;	jmp	short goodcode
;badcode:
;	mov	dx,offset dgroup:notmos501
;	xor	cx,cx
;	jmp	initx

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


goodcode:

; fetch the parameter pointer from the request header and make
; make ds:si point to the first character code that is less than
; or equal to a blank space.  then parse any parameter switches

	push	ds
	les	bx,[request]
	lds	si,es:[bx+18]
	assume	ds:nothing
	cld
init0:
	lodsb
	cmp	al,' '
	ja	init0
	dec	si
	mov	ax,cs
	mov	es,ax
	assume	es:dgroup
	call	parse
	pop	ds
	assume	ds:dgroup,es:nothing
	jnc	initw
	xor	cx,cx
	jmp	inity
initw:

; install the patches

	call	process_lseg1
	jnc	initw1
	mov	dx,offset dgroup:syserr
	mov	ah,9
	int	21h
	xor	cx,cx
	jmp	inity
initw1:

; display load message and return driver's ending point

	mov	dx,offset dgroup:instmsg
	mov	cx,offset dgroup:end_res
initx:
	mov	ah,9
	int	21h

; if the changed flag is set, scan through LSEG2 and LSEG3 
; and report the deactivated versions.

	cmp	[changed],0
	je	inity
	push	cx
	call	report_chngs
	pop	cx
inity:
	les	bx,cs:[request]
	mov	es:[bx+14],cx
	mov	es:[bx+16],cs
	mov	word ptr es:[bx+3],0100h
	popset	ax,bx,cx,dx,si,di,bp,ds,es
	ret
init endp

_TEXT	ends

LSEG1	segment
	db	LCODE_EOL		; end of list marker
LSEG1	ends

LSEG2	segment
lseg2_words	equ	($-lseg2_start)/2
LSEG2	ends

	end	begin

