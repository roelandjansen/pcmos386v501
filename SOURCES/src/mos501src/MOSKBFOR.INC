
;	MOS Common Foreign Keyboard Driver Code

;	All common driver code was placed here to eliminate
;	duplicated code in foreign keyboard drivers.

; RKG	04/04/89 Use E0 prefix on numpad for cursor keys, since
;		 NUMLOCK is usually wrong on terminals

; mjs 08/14/89	cleanup code - convert to action chart - bring up
;		to date with new e0 handling methods

	.xlist
TCB	segment at 0
	include	mostcb.inc
TCB	ends

SCBX	segment at 0
	assume cs:scbx
	include mosscbdf.inc
SCBX	ends
	.list
	
;----------------------------------------------------------------;
;                    DEVICE  HEADER                             ;
;----------------------------------------------------------------;
code	segment	para
	assume	cs:code, ds:nothing, es:nothing, ss:nothing

begin:
	dd	-1
	dw	8000h		; this is a character device
	dw	stratg		; pointer to strategy routine
	dw	interupt	;   "     " interrupt   "
	db	'$$MOSKB '

oldkeyb	dd	0		; pointer to previous keyboard driver

request	dd	0		; area to store request by MOS

stratg	proc	far
	mov	word ptr [request],bx
	mov	word ptr [request+2],es
	ret
stratg	endp


interupt proc	far
	push	es
	push	bx
	les	bx,[request]
	cmp	byte ptr es:[bx+2],0
	jne	i1
	push	ds
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	ax
	lds	si,es:[bx+18]	; point to command line
	call	init
	les	bx,[request]
	mov	es:[bx+14],dx
	mov	es:[bx+16],ds
	pop	ax
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
i1:
	mov	word ptr es:[bx+3],0100h	; store result status
	pop	bx
	pop	es
	ret
interupt endp
	page


IKBSTAT equ	17H	;; BIOS keyboard shift/lock flags

NUMPAD_LO equ	71	;; Lowest keycode from numeric pad
NUMPAD_HI equ	83	;; Highest keycode from numeric pad

K_F1	equ	59	;; Function key 1
K_F2	equ	60	;; Function key 2

KBS_RSHF equ	01h	;; Right Shift pressed
KBS_LSHF equ	02h	;; Left Shift pressed
KBS_SHF	 equ	03h	;; Any Shift key pressed
KBS_CTL	 equ	04h	;; Ctrl key pressed
KBS_ALT	 equ	08h	;; Alt key pressed
KBS_SCRL equ	10h	;; Scroll locked
KBS_NUM	 equ	20h	;; Numpad locked
KBS_CAP	 equ	40h	;; Caps locked
KBS_INS	 equ	80h	;; Insert state

KBC_E1	 equ	01h	;; E1 prefix last
KBC_E0	 equ	02h	;; E0 prefix last
KBC_RCTL equ	04h	;; Right control key pressed
KBC_RALT equ	08h	;; Right alt key pressed
KBC_101	 equ	10h	;; 101/102 keyboard installed
KBC_US	 equ	20h	;; US driver wanted
KBC_KEYB equ    0C0h	;; type of keyboard installed

;-----------------------------------------------------------------------;
;		SCAN CODE TO KEY SCAN CODE TRANSLATION			;
;-----------------------------------------------------------------------;
;
;	ENTER:	AL = scan code
;		DS -> TCB
;		ES -> GRP
;	EXITS:	DX = Function
;		if DX = 0
;			AX = -1
;				ignore scan code
;			AX <> -1 and BX = -1
;				buffer AX = key code  (normal case)
;			AX <> -1 and BX <> -1
;				buffer BX, then AX (accent shift failed)
;		else DX <> 0
;			DX = 1 process a shift prtsc
;			DX = 2 process a cntrl-break
;			DX = 3 process a ctrl-alt-del
;
;	DESTROYS	AX, BX, CX, DX, SI, ES, DS
;----------------------------------------------------------------------
	assume cs:code, ds:tcb

translat:
	mov	ch,[tcbkshft]

; if the us standard is in effect, test for cntrl-alt-f2
; revert to foreign kyb if detected

	test	[tcbkbctl],kbc_us 
	jz	mkb1 
	cmp	al,k_f2 or 80h 
	jne	mkb2 
	test	ch,kbs_ctl 
	jz	mkb2
	test	ch,kbs_alt 
	jz	mkb2 
	and	[tcbkbctl],not kbc_us
	jmp	short mkb1
mkb2:
	jmp	[oldkeyb]
mkb1: 
	push	ds
	pop	es			; tcb goes to es, code in ds
	push	cs
	pop	ds
	assume	cs:code, ds:code, es:tcb
	mov	cl,al			; cl retains scan code

; get table to use in si

	test	ch,kbs_alt or kbs_ctl 
	jz	mkb5 
	test	[tcbkbctl],kbc_ralt	; test altgr pressed
	jnz	mkb6 
	mov	si,offset ctrltbl
	test	ch,kbs_alt 		; handle ctrl/alt combos
	jz	mkb7 
	mov	si,offset alttbl

; handle alt-shift like ctrl-alt for some keyboards


ifdef altsh
	test	ch,kbs_ctl or kbs_shf
else
	test	ch,kbs_ctl 
endif
	jz	mkb7 

mkb6:
	mov	si,offset calttbl
	jmp	short mkb7
mkb5:
	mov	si,offset basetbl
	cmp	al,numpad_lo		; if not numpad
	jb	mkb3 
	cmp	al,numpad_hi 
	jna	mkb8 
mkb3:
	test	ch,kbs_shf 		; if not shifted
	jz	mkb7 
	jmp	short mkb9
mkb8:	;else
	test	[tcbkbctl],kbc_e0 
	jnz	mkb7 
	test	ch,kbs_num or kbs_shf
	jp	mkb7 
mkb9:
	mov	si,offset shfttbl
mkb7:

; si -> correct key table
; al, cl = scan code
; ch = shift states

	mov	[tcblscan],cl
	add	al,al			; get index into table
	xor	ah,ah
	mov	bx,si			; table + 2 * scan
	add	bx,ax
	mov	ax,[bx]			; get translated code from table
	xor	dx,dx			; initialize function return
	cmp	ah,0			; ah = z means the value is to be interpreted
	jne	mkb11 
	mov	bx,ax			; some special key function to be performed
	add	bx,bx
	call	cs:[keyvct+bx]		; call special function
mkb11:

; dx = function code from special routine
; ax = key code from table or special routine
;    = -1  for nulls
;    al = 0   for function keys
;    ah > 128 for accent shift

	mov	bx,-1			; initialize auxiliary return
	and	[tcbkbctl],not (kbc_e0 or kbc_e1)
	cmp	cl,0e0h 
	jne	mkb12 
	or	[tcbkbctl],kbc_e0	; set prefix flag
	jmp	short mkb13
mkb12:
	cmp	cl,0e1h 
	jne	mkb14 
	or	[tcbkbctl],kbc_e1	; set prefix flag
	jmp	short mkb13
mkb14:
	test	cl,80h 			; if a break code
	jnz	mkb13 

; test pc keyboard and alternate lookup
; keyb = 0/default=enhanced 1/pc 2/at 3/enhanced

	test	[tcbkbctl],kbc_keyb
	jp	mkb15 
mkb16:
	sub	si,2
	cmp	cl,[si+1] 		; test pc alternate key
	ja	mkb15
	jne	mkb16 
	mov	ax,[si]			; get incompatible key for pc keyboard
	cmp	al,8 			; test accent shift key in pc table
	ja	mkb15 
	or	ah,80h			; mark an accent shift
mkb15: 

; handle caps lock on alphabetic

	cmp	ax,-1 
	je	mkb13 
	cmp	al,0 
	je	mkb20 
	test	ch,kbs_cap 		; if capslock
	jz	mkb21 
	call	caseshft		; toggle case of character
mkb21:
	cmp	byte ptr [tcblastky],0 
	je	mkb22 
	call	accented		; last was accent key, accent this
	test	ah,80h			; test this is accent
	jz	mkb20 
	mov	ax,bx			; return first accent key only
	mov	bx,-1
	jmp	short mkb20
mkb22:
	test	ah,80h			; test this is accent shift
	jz	mkb20 
	mov	[tcblastky],ax		; soft accent shift, save type
mkb13:
	mov	ax,-1			;  but don't buffer
	jmp	short mkb23
mkb20:
	mov	word ptr [tcblastky],0
mkb23:
	retf


	subttl		CAPS LOCK AND ACCENT SHIFT
	page

;	CASESHFT if capslock is enabled, alphabetic chars must
;	be case shifted.  ASCII chars are XORed and foreign chars
;	are found in the table.
;
;	ENTER:	AL = Char to case shift
;	EXITS:	if ZR AL = case shifted character
;		if NZ lookup failed

	even			; *** for bit twiddle lookup ***
	dw	XEND - XCASTBL	; for repeat length
XCASTBL	db	'éÑèÜíëÄáêÇ•§ôîöÅ'
XTHOR	db	'ùõ'		; for norwegian
XEND	label	byte

CASESHFT:
	cmp	al,'z'		; test AL is ASCII
	ja	cashftoth
	cmp	al,'A'
	jb	cashftxit	; not ASCII and not shiftable
	cmp	al,'Z'
	jbe	cashftasc	; ASCII case shift
	cmp	al,'a'
	jb	cashftxit	; not ASCII and not shiftable
CASHFTASC:
	xor	al,'a'-'A'	; case shift ASCII chars
CASHFTXIT:
	ret

CASHFTOTH:			; find char in foreign char table
	mov	si,offset xcastbl
	call	findchr
	jne	cashftxit	; exit if char not found in list
	xor	si,1		; get to associated character
	mov	al,[si]		; get case shifted char
	ret
	
;	FINDCHR searches list for char in AL
;
;	ENTER:	DS:SI => Table
;			[SI-2] = Byte Length of table
;		AL = Char to search
;	EXITS:	NZ if char not in table
;		ZR if char found  DS:DI points to character

FINDCHR:
	push	cx
	mov	cx,[si-2]	; get length of list
	dec	si		; for increment and set NZ
	jcxz	findxit
FINDLUP:
	inc	si
	cmp	al,[si]		; test equal
	loopne	findlup		; loop for length of list or chars match
FINDXIT:
	pop	cx
	ret


;	ACCENT SHIFT Tables

;	Structure:	Character if accent shift fails
;			Number of base characters
;			Base character list
;			Accented character list

;	ACCENT SHIFT 01 IS `
	DB	'`'
	DW	A1E - A1
A1	DB	'aeiou'
A1E	DB	'Öäçïó'

;	ACCENT SHIFT 02 IS ~
	DB	'~'
	DW	A2E - A2
A2	DB	'cCnN'
A2E	DB	'áÄ§•'

;	ACCENT SHIFT 03 IS ^
	DB	'^'
	DW	A3E - A3
A3	DB	'aeiou'
A3E	DB	'Éàåìñ'

;	ACCENT SHIFT 04 IS UMLAT (é)
	DB	0		; no char if accent fails
	DW	A4E - A4
A4	DB	'aeiouyAOU'
A4E	DB	'ÑâãîÅòéôö'

;	ACCENT SHIFT 05 IS ¯
	DB	'¯'
	DW	A5E - A5
A5	DB	'aA'
A5E	DB	'Üè'

;	ACCENT SHIFT 06 IS , combined with ~

;	ACCENT SHIFT 07 IS _
	DB	'_'
	DW	A7E - A7
A7	DB	'ao'
A7E	DB	'¶ß'

;	ACCENT SHIFT 08 IS '
	DB	''''
	DW	A8E - A8
A8	DB	'aEeiou'
A8E	DB	'†êÇ°¢£'

;	List of accent tables indexed by accent type
ACNTVCT	DW	A1,A2,A3,A4,A5,A2,A7,A8,offset ACCNTSPC

;	ACCENTED accents AL using the accent lists.
;	Enter:	AL = char to accent
;		[TCBLASTKY] = accent index and scan code
;	Exits:	if accentable char
;			AX = accented character
;			DX = -1
;		else DX = accent char / scan code

ACCENTED:
	mov	bx,[TCBLASTKY]
	and	bh,7Fh		; strip off accent flag
	mov	si,bx
	and	si,15		; TCBLAST = accent type
	dec	si		; get accent table address
	add	si,si
	mov	si,[ACNTVCT+si]
	mov	bl,[si-3]	; and char if accent fails
	test	bl,bl		; if not a char set BX=-1
	jnz	acntok
	mov	bx,-1
ACNTOK:
	mov	cx,[si-2]	; get length of list
	call	findchr		; test character in list
	jne	acntxit		; not accentable char exit with BX, AX
	add	si,cx		; get to accented char
	mov	al,[si]
	mov	bx,-1		; don't buffer accent char
ACNTXIT:
	ret
	
	SUBTTL	SPECIAL KEY FUNCTIONS SUBROUTINES
	page

@caps:
	mov	al,KBS_CAP
	jmp	toggle
@num:
	mov	al,KBS_NUM
	jmp	toggle
@scroll:
	mov	al,KBS_SCRL

;	TOGGLE	Handles toggle states (Scroll, Numlock, Caplock)
;		Sets/Resets TGGL bit.  If first make toggles SHFT bit.
;	ENTER:	AL = bit to set / reset

TOGGLE:
	or	cl,cl		; test break / make
	js	togglclr
	test	[TCBKTGGL],al	; test first make
	jnz	togglxit	; no just exit
	or	[TCBKTGGL],al
	xor	[TCBKSHFT],al	; set TGGL bit / flip SHFT bit
	call	updshft
TOGGLXIT:
	mov	ax,-1		; no key to return
	ret
TOGGLCLR:
	not	al		; clear toggle bit
	and	[TCBKTGGL],al
	jmp	togglxit


;	UPDSHFT	updates keyboard status at 40:17 from KSHFT

biosseg	dw	40h

UPDSHFT:
	push	ds
	mov	ds,[biosseg]	; get addressability of BIOS data
	mov	al,[TCBKSHFT]
	mov	ds:[IKBSTAT],al
	pop	ds
	ret

; alt shift with alt num-pad capability
@alt:
	mov	al,KBS_ALT
	test	[TCBKBCTL],KBC_E0	; test right Alt key
	jz	@altleft
	mov	al,KBC_RALT		; Fake out for ALT-GR
	call	control
@altleft:
	mov	al,KBS_ALT
	call	shift
	or	cl,cl
	jns	@altxit		; finished if make of ALT
	cmp	byte ptr [TCBALTNUM+1],0
	je	@altxit		; test numbered entered during ALT
	xor	ax,ax		; clear / get ALTNUM
	xchg	ax,word ptr [TCBALTNUM]
	xor	ah,ah		; flag key came from Alt-numpad
	and	cl, 07Fh	; reset key-break flag, so this looks normal
@altxit:
	ret

@ctrl:
	test	[TCBKBCTL],KBC_E0	; test right Alt key
	jz	@ctrlleft
	mov	al,KBC_RCTL		; flag right control
	call	control
@ctrlleft:
	mov	al,KBS_CTL
	jmp	short shift

@lshift:
	mov	al,KBS_LSHF
	jmp	short shift
@rshift:
	mov	al,KBS_RSHF

; 	SHIFT	sets / clears bits in TCBKSHFT
;	ENTER:	AL = bits to set on make / reset on break of key

SHIFT:
	or	[TCBKSHFT],al
	or	cl,cl		; test make / break of key
	jns	shftxit
	not	al		; key break - clear bits
	and	[TCBKSHFT],al
SHFTXIT:
	call	updshft
	mov	ax,-1
	ret

; 	CONTROL	sets / clears bits in TCBKBCTL
;	ENTER:	AL = bits to set on make / reset on break of key

CONTROL:
	or	[TCBKBCTL],al
	or	cl,cl		; test make / break of key
	jns	ctrlxit
	not	al		; key break - clear bits
	and	[TCBKBCTL],al
CTRLXIT:
	ret


@insert:
	mov	al,KBS_INS	; toggle insert flag
	call	toggle
	or	cl,cl
	js	@insrtxit
	mov	ax,5200h	; if key make, return INS code as well as
@insrtxit:			;   handling toggle bit
	ret

; shift PrtSc key
@prtscr:
	or	cl,cl
	js	@prtsc1 	; skip if releasing the key
	mov	dx,1
@prtsc1:
	mov	ax,-1
	ret

; ignore pause key
@pause:
	or	[TCBBRKFG],10h
	mov	ax,-1
	ret

; Ctrl Scroll-Lock
@break:	or	cl,cl
	js	@break1 	; skip if releasing the key
	mov	dx,2
@break1:
	mov	ax,-1
	ret


	; handle alt-numpad character entry
	; accumulate number in TCBALTNUM, if 999 entered toggle flag

@altnum:
 	or	cl,cl		; key make?
	js	@altnxit
	
	mov	bl,cl		; lookup ASCII value
	add	bl,bl		; word index
	xor	bh,bh
	mov	bl,byte ptr [SHFTTBL+bx]
	and	bl,15		; BX = key's value
	mov	al,10
	mul	[TCBALTNUM]	; multiply old number by 10
	add	ax,bx		; add new digit
	cmp	ax,999  	; alt 999 ?
	je	@altn999
	or	ah,80h		; flag alt-number seen
	mov	word ptr [TCBALTNUM],ax
@altnxit:
	mov	ax,-1		; no key to return
	ret

@altn999:			; Toggle ALT999 and init ALTNUM
	mov	word ptr [TCBALTNUM],0
	xor	[TCBALT999],0ffh
	jmp	@altnxit

;	Ctrl-Alt-F1 reverts to US keyboard
;	Ctrl-Alt-F2 reverts to foreign keyboard

@uskeyb:
	or	[TCBKBCTL],KBC_US
	mov	ax,-1		; revert to US keyboard
	ret

;	Ctrl-Alt-Del return reboot function
;	Check Alt-Gr is not pressed

@reboot:
	mov	ax,-1
	test	[TCBKBCTL],KBC_RALT
	jnz	@rebtxit
	mov	dx,3		; return reboot function
@rebtxit:
	ret


	SUBTTL	KEYBOARD SCAN CODE TABLE MACROS
	page

; KEY <VALUE>
;  macro to put key value + scan code into table
;  this is a normal key returning a value in al and scan code in ah

KEY	macro	VALUE
	db	VALUE, scan
	scan = scan + 1
	endm


;	CTRLKEY <VALUE>
; macro to put a control key + scan code into table
; makes a control key out of value, then deposits a key

CTRLKEY	macro	VALUE
	db	VALUE AND 01Fh, scan
	scan = scan + 1
	endm


;	NOKEY <VALUE>
;  macro to suppress a key
;  application never sees key press

NOKEY	macro	VALUE
	dw	-1
if2
  ifnb	<VALUE>
    if	VALUE-SCAN
      noerr VALUE, %SCAN
    endif
  endif
endif
	scan = scan + 1
	endm

NOERR	macro	val, scn
	%out	NOKEY DIFFERS  VALUE=&val  SCAN=&scn
	endm



;	FN <VALUE>
;  macro to put 0 + value into table
;  this is a function key returning 0 in al and the value in ah

FN	macro	VALUE
	db     0,VALUE
	scan = scan + 1
	endm


; EXTENDED FUNCTION KEY
FNX	macro	VALUE
	db	VALUE,7FH
	scan = scan + 1
	endm


;	SPCKEY <NAME>
;  macro for key requiring special handling
;  @NAME is the subroutine to handle the key
;  SPCVCT <NAME> must appear in the keyvct table above

SPCKEY	macro	VALUE
	dw	@@&VALUE
	scan = scan + 1
	endm


;	ACCENT <NUMBER>
;  macro for accent shift key
;  number defines which accent mark (see subroutine accented)

ACCENT	macro	VALUE
	db	VALUE, scan+128
	scan = scan + 1
	endm



;	Macro to check the length of a table

CHKLEN	macro	message
	if scan ne 128
	  if1
	    %out	message
	  endif
	endif
	endm

; defining table of vectors to special key subroutines
SPCVCT	macro	VALUE
@@&VALUE equ	($-keyvct)/2
	dw	@&VALUE
	endm

; VECTORS INTO SUBROUTINES FOR KEYS WHICH REQUIRE SPECIAL HANDLING

KEYVCT	label	word
	spcvct	caps
	spcvct	num
	spcvct	scroll
	spcvct	alt
	spcvct	ctrl
	spcvct	lshift
	spcvct	rshift
	spcvct	insert
	spcvct	prtscr
	spcvct	pause
	spcvct	break
	spcvct	altnum
	spcvct	uskeyb
	spcvct	reboot

; Vectors are last so they can be extended keyboard specific vectors
