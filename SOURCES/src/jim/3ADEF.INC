;	Terminal definition file for ADM 3A terminals

defname	macro
	db	"$$3ATERM"	;; device driver name
				;; must be 8 characters long
	endm

; TELETYPE equ	1		; define for glass teletype terminal support

capable	dw	BINCUR		; where the capability bits live

SCRROW	equ	24		; rows on the screen
SCRCOL	equ	80		; columns on the screen

maxrow	db	SCRROW - 1	; 0 based maximum row number
maxcol	db	SCRCOL - 1	; 0 based maximum column number
extrar	db	25 - SCRROW	; rows off screen
setup	db	0		; set-up string for terminal

;	Cursor position strings.

crintro	db	2,1bh,'='	; introducer for cursor position
crsep	db	0		; separator character for cursor position
croffs	db	20h		; add to zero-based cursor position
crterm	db	0		; cursor position terminator

crrt	db	1,0ch		; move the cursor right one column

rgintro	db	0		; introducer for scrolling region
rgsep	db	0		; separator character for region definition
rgoffs	db	20h		; offset for zero-based region string
rgterm	db	0		; terminating string for region

;	Comm protocol to use

PROTOCOL equ	PR_RXON or PR_TXON	; use xon/xoff on both sides

;	Incoming character mask.

CHARMASK equ	7fh			; mask for incoming characters

;	Flow control characters to use.

XON	equ	011h	; start transmit character
XOFF	equ	013h	; stop transmit character

;	Characters for key code matching.

crttctlp db	1bh			; command prefix
crttcurp db	0			; cursor prefix
crttcuru db	0bh			; ^K
crttcurd db	0ah			; ^J
crttcurl db	08h			; ^H
crttcurr db	0Ch			; ^L
crtthome db	1eh			; ^^

;	String table for generic terminal functions.

ceos	   label byte			; erase to end of screen
	db	0
ceoln	   label byte			; erase to end of line
	db	0
insertline label byte
	db	0
deleteline label byte
	db	0
linecursor label byte
	db	0
boxcursor  label byte
	db	0
nocursor   label byte
	db	0
monitoron  label byte
	db	0
monitoroff label byte
	db	0
printon    label byte
	db	2,1bh,'@'
printoff   label byte 
	db	2,1bh,'A'
attrsoff   label byte
	db	0
reverseon  label byte
	db	0
blinkon	   label byte
	db	0
underon	   label byte
	db	0
boldon	   label byte
	db	0
blankon	   label byte
	db	0

;	Keyboard translation table for normal characters.

keycodes label byte		; translation from ASCII chars to scan codes
	db	03, CTL or LSH,	30, CTL,	48, CTL	; ^@, ^A, ^B
	db	46, CTL,	32, CTL,	18, CTL	; ^C, ^D, ^E
	db	33, CTL,	34, CTL,	35, CTL	; ^F, ^G, ^H
	db	15, NRM,	36, CTL,	37, CTL	; tab, ^J, ^K
	db	38, CTL,	28, NRM,	49, CTL	; ^L, enter, ^N
	db	24, CTL,	25, CTL,	16, CTL	; ^O, ^P, ^Q
	db	19, CTL,	31, CTL,	20, CTL	; ^R, ^S, ^T
	db	22, CTL,	47, CTL,	17, CTL	; ^U, ^V, ^W
	db	45, CTL,	21, CTL,	44, CTL	; ^X, ^Y, ^Z
	db	01, CTL,	43, CTL,	27, CTL	; esc, ^\, ^]
	db	07, CTL or LSH,	12, CTL or LSH,	57, NRM	; ^^, ^_, ' '
	db	02, LSH,	40, LSH,	04, LSH	;  !,  ",  #
	db	05, LSH,	06, LSH,	08, LSH	;  $,  %,  &
	db	40, NRM,	10, LSH,	11, LSH	;  ',  (,  )
	db	09, LSH,	13, LSH,	51, NRM	;  *,  +,  ,
	db	12, NRM,	52, NRM,	53, NRM	;  -,  .,  /
	db	11, NRM,	02, NRM,	03, NRM	;  0,  1,  2
	db	04, NRM,	05, NRM,	06, NRM	;  3,  4,  5
	db	07, NRM,	08, NRM,	09, NRM	;  6,  7,  8
	db	10, NRM,	39, LSH,	39, NRM	;  9,  :,  ;
	db	51, LSH,	13, NRM,	52, LSH	;  <,  =,  >
	db	53, LSH,	03, LSH,	30, LSH	;  ?,  @,  A
	db	48, LSH,	46, LSH,	32, LSH	;  B,  C,  D
	db	18, LSH,	33, LSH,	34, LSH	;  E,  F,  G
	db	35, LSH,	23, LSH,	36, LSH	;  H,  I,  J
	db	37, LSH,	38, LSH,	50, LSH	;  K,  L,  M
	db	49, LSH,	24, LSH,	25, LSH	;  N,  O,  P
	db	16, LSH,	19, LSH,	31, LSH	;  Q,  R,  S
	db	20, LSH,	22, LSH,	47, LSH	;  T,  U,  V
	db	17, LSH,	45, LSH,	21, LSH	;  W,  X,  Y
	db	44, LSH,	26, NRM,	43, NRM	;  Z,  [,  \
	db	27, NRM,	07, LSH,	12, LSH	;  ],  ^,  _
	db	41, NRM,	30, NRM,	48, NRM	;  `,  a,  b
	db	46, NRM,	32, NRM,	18, NRM	;  c,  d,  e
	db	33, NRM,	34, NRM,	35, NRM	;  f,  g,  h
	db	23, NRM,	36, NRM,	37, NRM	;  i,  j,  k
	db	38, NRM,	50, NRM,	49, NRM	;  l,  m,  n
	db	24, NRM,	25, NRM,	16, NRM	;  o,  p,  q
	db	19, NRM,	31, NRM,	20, NRM	;  r,  s,  t
	db	22, NRM,	47, NRM,	17, NRM	;  u,  v,  w
	db	45, NRM,	21, NRM,	44, NRM	;  x,  y,  z
	db	26, LSH,	43, LSH,	27, LSH	;  {,  |,  }
	db	41, LSH,	14, NRM			;  ~,  ctl <-

txtbl	label	byte		; translate characters for display 
	db	020h,020h,020h,020h,020h,020h,020h,020h		; 00 - 07
	db	020h,020h,020h,020h,020h,020h,020h,020h		; 08 - 0f
	db	020h,020h,020h,020h,020h,020h,020h,020h		; 10 - 17
	db	020h,020h,020h,020h,020h,020h,020h,020h		; 18 - 1f
	db	020h,021h,022h,023h,024h,025h,026h,027h		; 20 - 27
	db	028h,029h,02ah,02bh,02ch,02dh,02eh,02fh		; 28 - 2f
	db	030h,031h,032h,033h,034h,035h,036h,037h		; 30 - 37
	db	038h,039h,03ah,03bh,03ch,03dh,03eh,03fh		; 38 - 3f
	db	040h,041h,042h,043h,044h,045h,046h,047h		; 40 - 47
	db	048h,049h,04ah,04bh,04ch,04dh,04eh,04fh		; 48 - 4f
	db	050h,051h,052h,053h,054h,055h,056h,057h		; 50 - 57
	db	058h,059h,05ah,05bh,05ch,05dh,05eh,05fh		; 58 - 5f
	db	060h,061h,062h,063h,064h,065h,066h,067h		; 60 - 67
	db	068h,069h,06ah,06bh,06ch,06dh,06eh,06fh		; 68 - 6f
	db	070h,071h,072h,073h,074h,075h,076h,077h		; 70 - 77
	db	078h,079h,07ah,07bh,07ch,07dh,07eh,020h		; 78 - 7f
	db	020h,020h,020h,020h,020h,020h,020h,020h		; 80 - 87
	db	020h,020h,020h,020h,020h,020h,020h,020h		; 88 - 8f
	db	020h,020h,020h,020h,020h,020h,020h,020h		; 90 - 97
	db	020h,020h,020h,020h,020h,020h,020h,020h		; 98 - 9f
	db	020h,021h,022h,023h,024h,025h,026h,027h		; a0 - a7
	db	028h,029h,02ah,02bh,02ch,02dh,02eh,02fh		; a8 - af
	db	030h,031h,032h,033h,034h,035h,036h,037h		; b0 - b7
	db	038h,039h,03ah,03bh,03ch,03dh,03eh,03fh		; b8 - bf
	db	040h,041h,042h,043h,044h,045h,046h,047h		; c0 - c7
	db	048h,049h,04ah,04bh,04ch,04dh,04eh,04fh		; c8 - cf
	db	050h,051h,052h,053h,054h,055h,056h,057h		; d0 - d7
	db	058h,059h,05ah,05bh,05ch,05dh,05eh,05fh		; d8 - df
	db	060h,061h,062h,063h,064h,065h,066h,067h		; e0 - e7
	db	068h,069h,06ah,06bh,06ch,06dh,06eh,06fh		; e8 - ef
	db	070h,071h,072h,073h,074h,075h,076h,077h		; f0 - f7
	db	078h,079h,07ah,07bh,07ch,07dh,07eh,020h		; f8 - ff
