 	include page.inc
	title	PRINT - print spool data area and pop up window

	subttl	PRINT Development Specification

;-----------------------------------------------------------------------;
;									;
;			Development Specification			;
;									;
; Program Name: PRINT.COM (External)	Assigned to: Martin Stitt	;
;									;
;-----------------------------------------------------------------------;

;*****************************************************************************
;*									     *
;* v2.01 changed closing logic to always output crlf to printer to clear its *
;* buffer.  JSW  01/10/86						     *
;* v2.03 no longer prints a specific class. It will print any closed file tha*
;* it finds regardless of class. This was implemented for those users that re*
;* quire high volume word processing and printing to multiple printers.      *
;* v2.04 combines the best of both 2.02 and 2.03.  The user can now specify  *
;* the default class from the command line with a "/c" where the "c" is the  *
;* new default class. The user can also tell MLPRINT to print any class that *
;* it finds by specifying "/*" on the command line.			     *
;* v2.06 B.M. Wright - fix problem with laser printer dumping out extra pages*
;*  5/12/87 RBR  Messages cleaned up.					     *
;----------------------------------------------------------------------------
;   07/13/87    SAH     Converted int 21 fun 80+ to int 38 00+
;                       remove subversion checking
;----------------------------------------------------------------------------
;   07/16/87    SAH     Modified program to use LPTx instead of INT 17H
;----------------------------------------------------------------------------
;   08/03/87    SAH     During Print.COM LPT1: will be place into raw mode
;----------------------------------------------------------------------------
;   08/19/87    BMW     correct hp laser problem of dumping extra ff's
;----------------------------------------------------------------------------
;   11/23/87    SAH     change version # to 2.00
;----------------------------------------------------------------------------
;   01/20/88    JSW     Added command line option, /FF, to tell PRINT to pass
;                       form feeds for WS v4.0  PRINT version 2.01
;----------------------------------------------------------------------------
;   07/20/88    RDG     PTR 0065 - Added pint24 to automatically retry any
;   RG8202              printer related critical errors up to the limit set
;                       at print startup.  Rewrote the command line parsing
;                       code to accept the new retry (/r=9999) option.
;----------------------------------------------------------------------------
;  SAH  09/07/88        Allow page to be started greated >999 and cleanup
;----------------------------------------------------------------------------
;  RKG  09/18/88        Printing files when Sequence has rolled over. PTR 60
;                       Select next file by date/time.  Validate path.
;----------------------------------------------------------------------------
;  RKG  01/10/89        Rewrite.
;----------------------------------------------------------------------------
;  SAH  02/20/89        Converted INT 38 calls to INT SERVICES
;----------------------------------------------------------------------------
;  BWR  10/12/89        Corrected graphics output problem.
;                       /FF option is now the default instead of /NOFF.
;----------------------------------------------------------------------------
;  BWR  11/30/89        Marked messages for foreign language translation.
;----------------------------------------------------------------------------
;  BWR  5/1/90          DECTOBIN incorrectly handling numeric strings which
;                       caused syntax error on command line arguments.
;----------------------------------------------------------------------------
; BWR   9/19/90         DECTOBIN routine was failing to check for the ASCIIZ
;                       terminator at the end of the command line, causing
;                       a syntax error if the length of the time argument
;                       on /T was less than 2 characters.  Version level
;                       of program is now 4.10
;
;----------------------------------------------------------------------------
; SAH	08/27/91	Corrected bug with Class U-Z not asking for formfeeds
;			Up version to Version 4.11
;----------------------------------------------------------------------------
; RSR   04/17/92        Changed copyright and version number (now 5.01)
;                       changed the default spool directory name to spool
;                       from spool.dir. Fixed a CBK found divide by zero
;                       error if a / param was greater than 10 characters
;----------------------------------------------------------------------------
; RSR/CBK 04/23/92      Boy, Cheryl found a bug-o-mine. added 4 spaces
;                       to the patch and changed pathlen to 9 byte
;                       (programmer error)
;----------------------------------------------------------------------------
; CBK	05/19/92	Changed some headings if dos version for llpro
;----------------------------------------------------------------------------

	include options.inc
	include	print.pub
	include _osmos.def

MOS	MACRO	fn
	mov	ah,fn
	int	21h
	endm

BIOS	segment at 40h
	org	8
printer_base	dw	4 dup (?)
	org	6Ch
tick_cntr	dw	?
BIOS	ends

_text	segment word	public	'code'
	assume cs:_text, ds:_text

	 org	80h
operands label	byte	; drive:path specified here

	 org	100h
start	 label	near
	 jmp	begin

;-----------------------------------------------------------------;
;			data areas				  ;
;-----------------------------------------------------------------;

waitcnt	dw	273		; easy to patch at beginning

;	Structure for class parameters

CLASSTR	struc
printer	db	?	; printer associated with Class
ffskip	db	?	; skip extra formfeeds
pagelen	dw	?	; lines/page
iniz	dw	0	; initialization string
fini	dw	0 	; termination string
CLASSTR	ends

initclas db	'A'		; initial classes to print
curclass db	'*'		; current class
;BWR 10/12/89
cur	CLASSTR	<0, 0, 66>	; current printer, skip, pagelen (LPT1,skip,66)
clsprm	CLASSTR	26 dup(<0, 0, 66>)
;BWR 10/12/89

lstpage	 dw	0		; last page printed
rstrpage dw	0		; page wanted on restarts
curpage  dw	0		; current page number
curline  dw	0		; number lines on current page
stopped  db	0		; ff means printer stopped

switch	db	64 dup(0)	; storage for switch parsing

filfd	dw	-1		; handle to file printing, or -1
pathlen	dw	9		; directory path len, init for 'c:\spool\'

osmos	db	0	; flags which OS is running

CHARDEV	equ	80h	; character device flag		;RG8202
retrys	dw	0	; auto retries to attempt	;RG8202
errcnt	dw	0	; auto retries attempted	;RG8202
int24	dd	0	; original int24 vector		;RG8202

nullname db	'-NOTHING-   ' ;@@XLAT
wildext	 db	'???'	; wildcard extension for finds

FNMEXT	 equ	 9	; offset to file's extension
FNMDISP	 equ	 9	; offset to file name's disposition
FNMPRIOR equ	10	; offset to priority
FNMCLASS equ	11	; offset to file name's priority
FILNMSIZ equ	12	; length of filenames

PATHSIZ	 equ	22	; length of paths below

srchpath db	'             c:\spool\'
srchname db	'sp??????.???',0,0	; Filename for directory scan
filpath	 db	'             c:\spool\'
filname	 db	'splttxxx.dpc',0,0	; Filename being printed
othpath	 db	'             c:\spool\'
othname	 db	'splttxxx.dpc',0,0	; Filename for operator commands
rnampath db	'             c:\spool\'
rnamname db	'splttxxx.dpc',0,0	; Filename for renames

finddta	 db	22 dup(0)	; scratch for find first/next function
findtime dw	0		; time returned from find
finddate dw	0		; date returned
findsize dw	2 dup(0)	; file size
findname db	13 dup(0)	; filename returned by find first/next

; best filename and its time, date, and size found in directory search
besttime dw	0
bestdate dw	0
bestsize dw	2 dup(0)
bestname db	13 dup(0)

keyblen db	0		; length of keyboard buffer
keybcnt	db	0		; number of chars entered
keybuff db	10 dup(' ')	; buffered keyboard data

BUFSIZ	equ	(4*1024)	; number of chars to read
bufflen	dw	0		; chars left in file buffer
buffptr	dw	0		; ptr to next char to print

prtname	db	'LPT'		; LPT printer driver
prtid	db	'1',0		; driver id
prtfd	dw	-1		; printer file descriptor
prtsize dw	2 dup(0) 	; current file bytes printed

; filename for print class init/term strings
prtctlnam db	'PRINT.CTL', 0, 0, 0, 0

ten	dw	   10
hundred dw	  100
w10000	dw	10000	; for bintodec

if notmos 
scrnseg1 db     24,00,'TSL Print Processor v5.01',0 ;@@XLAT
else
scrnseg1 db     24,00,'PC-MOS (TM) Print Processor v5.01',0 ;@@XLAT
endif

;2 ***			*** WARNING ***
;2 *** Menu item descriptions should not exceed 25 chars
;2 *** 1st byte is column, 2nd byte is row, 3rd starts string w/null terminator

	db	13,01
	include	copyrit.inc
	db	0
	db	01,03,'Active Class: *   Now printing -NOTHING-      ' ;@@XLAT
	db	      'Page   0   Size      0    0% Done  ',0 ;@@XLAT
	db	0,06,'----------- Commands -----------',0 ;@@XLAT
	db	0,08,'C - Change active class     ',0 ;@@XLAT
	db	0,09,'F - Flush current listing    ',0 ;@@XLAT
	db	0,10,'L - Change LPT/Class assignment     ',0 ;@@XLAT
	db	0,11,'S - Stop/start printer       ',0 ;@@XLAT
	db	0,12,'R - Restart with new page nbr         ',0 ;@@XLAT
	db	0,13,'M - Modify disp/pri/class        ',0 ;@@XLAT
	db	0,14,'D - Delete file     ',0 ;@@XLAT
if notmos 	
	db	0,15,'X - Exit to OS           ',0 ;@@XLAT
else
	db	0,15,'X - Exit to MOS          ',0 ;@@XLAT
endif
	db	45,05
dsppath	db	'                        ',0	; directory path centered
	db	37,06,'----------------- Files ------------------ ',0 ;@@XLAT
	db	05,18,'Command? ',0 ;@@XLAT
	db	-1

	;	!!! These display position MUST match scrnseg1 postitions !!!

seg2chksm dw	0		; checksum to display when changed

scrnseg2 db	32,03
scrnfile db	'-NOTHING-   ',0 ;@@XLAT

	 db	51,03
scrnpage db	'   0',0

	 db	62,03
scrnsize db	'      0',0

	 db	71,03
scrnpct  db	'  0',0

scrncseg db	15,03
scrnclas db	'* ',0		; current class
	 db	-1
seg2len	equ	($-scrnseg2)/2


seg3ptr	dw	0	; index in scrnseg3
seg3chksm dw	0	; checksum on scrnseg3

scrnseg3 label byte
	irp	lin,<8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23>
	db	37, lin, 20 dup(' '), 0
	endm
	
	irp	lin,<8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23>
	db	59, lin, 20 dup(' '), 0
	endm
	
	db	-1
seg3len	equ	($-scrnseg3)/2


scrnseg4 db	14,18,0, -1

scrnsegc db	05,19,'  New class: ', 0, -1 ;@@XLAT
	
scrnsegc1 db	05,19,'   Enter Class (A-Z):  ',0, -1 ;@@XLAT
	
scrnsegl db	08,20,'Current LPT is ' ;@@XLAT
scrnsglp db	'?', 0
	db	04,20,'    Enter new LPT # (0-3): ',0 ;@@XLAT
	dw	-1
	
scrnsegr db	05,19,'Page number:  ',0, -1 ;@@XLAT
msgnopag db	05,21,'Page not found!      ',0, -1 ;@@XLAT
scrnsegd db	05,19,'Filename:  SP',0, -1 ;@@XLAT
scrnsegm db	05,20,'New DPC:  ',0, -1 ;@@XLAT
msgerror db	05,23,'Hit <Return>:      ',0, -1 ;@@XLAT

msgerrex label byte
	db	14,18,' ',0
	db	05,19,32 dup(' '),0
	db	05,20,32 dup(' '),0
	db	05,21,32 dup(' '),0		;2
	db	05,22,32 dup(' '),0
	db	05,23,32 dup(' '),0
	db	-1

scrncmd	 db	15, 18		; position cursor at command prompt
scrncmdc db	'?', 0
	 db	-1

msgcom	 db	05,22,'Invalid command   ',0, -1 ;@@XLAT
msgclass db	05,22,'Invalid class!   ',0, -1 ;@@XLAT
msgnofil db	05,22,'No listing active!  ',0, -1 ;@@XLAT
msgdelet db	05,22,'Delete failed!      ',0, -1 ;@@XLAT
msgnofnd db	05,22,'File not found!      ',0, -1 ;@@XLAT
msgename db	05,22,'Rename failed!          ',0, -1 ;@@XLAT
msgdpc	 db	05,22,'Invalid entry!    ',0, -1 ;@@XLAT
msgioerr db	05,22,'I/O error! ',0, -1 ;@@XLAT
msgnpage db	05,22,'Insert next page into printer.        ',0, -1 ;@@XLAT
msgnolpt db	05,22,'LPT? not installed!    ',0, -1		;2 ;@@XLAT
	 
msglptset db	05,22,'Class  ' ;@@XLAT
msglpcls db	'?  now assigned to LPT' ;@@XLAT
msglplpt db	'?.',0, -1

msgbadlpt db	05,22,'Invalid LPT number!     ',0, -1 ;@@XLAT
msgproff db	01,04,'PRINTER STOPPED    ',0, -1 ;@@XLAT
msgpron  db	01,04,'                   ',0, -1

msgsyntax db	'Syntax error!     ',13,10,'$' ;@@XLAT
msgpath	db	13,10,'Invalid path!   ',13,10,'$' ;@@XLAT
msgprtctl db	'PRINT.CTL - file error      ', 13, 10, '$' ;@@XLAT


	subttl	Parse the command line
	page
;--------------------------------------------------------------------;
;			  initialization			     ;
;--------------------------------------------------------------------;

begin:
	mov	ah, 30h		; get DOS version
	int	21h
	mov	si, ax
	mov	ah, 30h		; get MOS version
	mov	bx, ax
	mov	cx, ax
	mov	dx, ax
	int	21h
	sub	ax, si		; NZ if MOS
	or	al, ah
	mov	[osmos], al	; save operating system

	call	parse		; parse command line arguments
	mov	al, -1		; give some exec error code
	or	dx, dx		; test for errors
	jnz	initerr

	call	readctl		; read PRINT.CTL
	jnc	continue
initerr:
	MOS	9h		; display error message
	jmp	short exit

continue:
	mov	al, [initclas]	; if a class set with /C=
	mov	[curclass], al	; set [curclass]

	call	dispclr		; clear screen
	lea	si,scrnseg1	; write basic screen
	call	writscrn

	mov	ah, 24h		; intercept critical error
	lea	si, int24	; double word pointer to new handler
	mov	[si+2], cs	; set codeseg in dword pointer
	call	intercept

	call	print		; returns with error message and errcode
	call	disperr
	
	mov	ah, 24h		; restore critical error handler
	lea	si, int24
	call	intercept

exit:
	MOS	4Ch		; return to EXEC with error


;	PARSE digests the command line parameters
;	Exits:	DS:DX => error message (0 if none)

parse:
	lea	si, operands	; pntr to command line
	lodsb			; get length of line
	mov	cl, al		; as a character count
	xor	ch, ch		; convert count to a word
 
parsloop:
	xor	dx, dx		; clear error message
	jcxz	parsxit		; jump if no chars left
	lodsb			; get next char
	dec	cx
	cmp	al, ' '		; skip spaces
	je	parsloop
	cmp	al, 9		; skip tabs
	je	parsloop
	cmp	al, 0Dh		; exit on <CR>
	je	parsxit
	
	cmp	al,'/'		; test for option switch
	je	parswtch
				; must be directory path
	inc	cx
	dec	si		; backup the pntr/cnt
	call	path		; get spool directory
	jnc	parsloop	; returns error flag
	lea	dx, msgpath	; error exit with message
	jmp	short parsxit

parserr:
	lea	dx, msgsyntax
parsxit:
	ret


parswtch:
        cmp     cx,64
        ja      parserrx
	lea	di, switch	; gather switch
	call	scanswtch
	
	; Looking for:
	; /R=nnn  -  Printer retry count
	; /T=nn	  -  Directory scan interval
	; /P=x	  -  set current class
	; /FF	  -  allow Formfeeds
	; /NOFF   -  suppress Formfeeds
	; /{Class}{printer}{pagelen}
	
	cmp	word ptr [switch], '=R'
	je	parsretry
	
	cmp	word ptr [switch], '=T'
	je	parstime
	
	cmp	word ptr [switch], '=P'
	je	parscurr
	
	cmp	word ptr [switch], 'FF'
	je	parsffset
	
	cmp	word ptr [switch], 'ON'
	jne	parsclass
	cmp	word ptr [switch+2], 'FF'
	je	parsffclr
	

parsclass:			; check for a valid class switch
	push	si
	push	cx		; save pntr/count
	call	class
	pop	cx
	pop	si
	jnc	parsloop	; all ok
parserrx:
	jmp	parserr


parstime:
	push	si		; save command line pointer
	push	cx		; and command len
	lea	si, switch+2	; pointer to number
	mov	cx, 2		; length of number
	call	dectobin
	pop	cx
	pop	si
	jc	parserr
	mov	ax, 18		; convert to ticks
	mul	dx
	mov	[waitcnt], ax	; set directory scan interval
	jmp	parsloop

parsretry:
	push	si		; save command line pointer
	push	cx		; and command len
	lea	si, switch+2	; pointer to number
	mov	cx, 3		; length of number
	call	dectobin
	pop	cx
	pop	si
	jc	parserr
	mov	[retrys], dx	; set retry count
	jmp	parsloop

parscurr:
	mov	al, [switch+2]	; get class
	call	classchk	; validate it
	jc	parserrx
	mov	[initclas], al	; set print class(es)
	jmp	parsloop

parsffset:
	mov	[cur.ffskip], 0	; allow formfeeds
	jmp	parsloop

parsffclr:
	mov	[cur.ffskip], 1	; suppress formfeeds
	jmp	parsloop


;	SCANSWTCH accumulates a switch parameter to a buffer
;	accepts everything to '/', space or control char
;	Enter:	DS:SI => source pointer
;		CX = source length
;		ES:DI => destination pointer
;	Exits:	DS:SI => terminating char of switch in source
;		CX = updated source length
;		ES:DI => 0  (terminator of copied switch token)
;
;	NOTE:	Alphabetic chars are uppercased in destination!

scanswtch:
	mov	al, [si]	; get char
	cmp	al, '/'		; test next switch
	je	scansxit
	cmp	al, ' '		; test valid chars
	jbe	scansxit
	cmp	al, '~'		; just about anything
	ja	scansxit

	cmp	al, 'a'		; test lowercase
	jb	scanstor
	cmp	al, 'z'
	ja	scanstor
	and	al, 0DFh	; change case of letter
scanstor:
	inc	si		; incr source
	stosb
	loop	scanswtch	; loop for all

scansxit:
	mov	byte ptr es:[di], 0
	ret	


;	PATH parses and validates the print directory then copies
;	it right justified to ????path variables.  Specially checks
;	for 'x:\' since Find function returns error on root directory.
;	Enter:	DS:SI => command line
;		CX length of command line
;	Exits:	CY set if invalid path
;		DS:SI, CX updated for scanned path
;		[????path] set to scanned directory

path:
	lea	di, filpath		; place to put path
	call	scanswtch		; find the end of the path name
	cmp	byte ptr [di-1], '\'	; delete trailing backslashes
	jne	pathval
	dec	di
	mov	byte ptr [di], 0
	
pathval:				; validate path name
	push	si
	push	cx			; save pointer/len of commmand line
	lea	dx, filpath
	call	pathdir			; is path a directory ?
	jnc	pathok			; yes
patherr:
	stc
	jmp	short pathxit

pathok:
	mov	word ptr [di], '\'	; append slash,null to path
	lea	si, filpath		; copy path to all filenames
	call	strlen			; get length
	mov	[pathlen], cx		; save length of directory path
	lea	di, othname		; right justify path
	sub	di, cx
	rep movsb
	
	lea	si, othpath
	lea	di, srchpath
	mov	cx, PATHSIZ
	rep movsb

	lea	si, othpath
	lea	di, filpath
	mov	cx, PATHSIZ
	rep movsb

	lea	si, othpath
	lea	di, rnampath
	mov	cx, PATHSIZ
	rep movsb

	lea	di, dsppath + 12
	mov	cx, [pathlen]
	shr	cx, 1			; centered in field
	sub	di, cx
	mov	cx, [pathlen]		; get start of directory
	lea	si, filname		; display directory path
	sub	si, cx
	rep movsb
	clc				; flag no errors
pathxit:
	pop	cx
	pop	si			; restore command pointer/len
	ret


;	CLASS validate class switch   /[Class[Printer[Lines]]]
;	found in 'switch'.
;		Class is A-Z or '*' for all classes
;		Printer is 1 to 3 or null for last
;		Lines is class page length
;	Enter:	[switch] contains scanned switch
;		[cur.xxxx] contains default printer/pagelen
;	Exits:	CY if syntax error
;		NC if no errors.  Sets given class parameters
;			which become new defaults.
;	Destroys: ALL

class:
	mov	al,[switch]
	call	classchk		; check for a valid class
	jc	classerr

	mov	al,[cur.printer]	; get default
	mov	ah,[switch+1]		; get printer # on switch
	or	ah, ah			; test any given
	jz	classtor
	
	mov	al, ah
	cmp	al,'0'			; test between 0 and 3
	jb	classerr
	cmp	al,'3'
	ja	classerr
	sub	al,'1'
	jl	classprt		; if null printer bypass port check
	jmp	classprt		; jump if printer exists
	
classerr:
	stc				; give error return
	jmp	classxit
	
classprt:
	mov	[cur.printer], al	; set printer

classlen:				; get/check lines per page
	lea	si, switch+2		; pointer to number
	cmp	byte ptr [si], 0	; test number given
	je	classtor
	mov	cx,5			; max num of chars
	call	dectobin
	jc	classerr
	mov	[cur.pagelen], dx	; valid # store lines/page
	
classtor:
	mov	al,[switch]		; get class
	mov	[curclass], al		; set current
	cmp	al, '*'			; set all classes?
	jne	classset

	mov	al, 'A'			; yes loop for all classes
classlup:
	call	classset
	inc	al			; get next class
	cmp	al, 'Z'
	jle	classlup
	jmp	short classret

classset:
	call	clspset

classret:
	clc				; give success return
classxit:
	ret

;	CLASSCHK checks AL is a valid class '*' or 'A'-'Z'
;	Enter:	AL = class char to check
;	Exits:	AL = uppercase class char
;		NC if AL is a valid class
;		CY if AL is invalid
;	Saves:	ALL

classchk:
	cmp	al, '*'         ;Auto class.
	je	clascok
	and	al, 0DFh	;Convert to upper case.
	cmp	al, 'A'
	jb	clascerr
	cmp	al, 'Z'
	ja	clascerr
clascok:
	clc
	ret
clascerr:
	stc
	ret


;	CLSPGET reads clsprm record into  current class parameters
;	Enter:	AL = Class index in 'clsprm'
;	Uses:	AX, SI, DI

clspget:
	clc			; set move direction
	jmp	short clspmov


;	CLSPSET stores current class parameters into clsprm array
;	Enter:	AL = Class to store 'cur' parameters
;	Saves:	ALL

clspset:
	stc
clspmov:
	push	ax
	push	cx
	push	si
	push	di
	pushf			; save to/from

	call	clspadr		; get pointer to class parms
	lea	di, cur
	popf			; pop CY implying copy direction
	jnc	clspmov0
	xchg	si, di
clspmov0:
	mov	cx, size cur	; length of structure
	rep movsb
	pop	di
	pop	si
	pop	cx
	pop	ax
	ret
	
	
;	CLSPADR returns pointer to class parms clsprm[AL]
;	Enter:	AL = Class to return parms
;	Exits:	SI = pointer to Class parms
;	Uses:	None

clspadr:
	push	ax
	sub	al, 'A'			; array based at 'A'
	mov	ah, size cur		; get size of structure
	mul	ah
	lea	si, clsprm		; get start of array
	add	si, ax
	pop	ax
	ret

;	PATHDIR validate a path is a directory
;	Enter:	DS:DX => ASCII path to validate
;	Exits:	CY set if not a directory
;	Destroys: AX if not a directory

pathdir:
	push	dx
	lea	dx, finddta		; set DTA for find_first
	MOS	1Ah
	pop	dx			; restore path pointer
	push	cx
	mov	cx, 10h			; find directories
	MOS	4Eh			; search for directory
	pop	cx
	ret
	

;	INTERCEPT exchanges BIOS interrupt vector
;	Enter:	AL = interrupt number
;		[DS:SI] dword pointer to new interrupt vector
;	Exits:	[DS:SI] contains old interrupt vector
;	Uses:	AH

intercept:
	push	es
	push	bx		; save regs
	push	ax
	MOS	35h		; get current vector
	mov	ax, es
	xchg	bx, [si]	; save interrupt / get new
	xchg	ax, [si+2]
	mov	es, ax
	MOS	25h		; set new vector
	pop	ax
	pop	bx
	pop	es		; restore regs
	ret


;	PINT24 retries critical errrors on non-block devices 
;	until [errcnt] <= 0

pint24:				; critical error handler	;R8202
	test	ah, CHARDEV	; is it a character device	;R8202
	jz	pint24e
	dec	[errcnt]	; check too many errors
	jle	pint24e
	mov	al, 1		; set for a retry		;R8202
	iret			; let him retry			;R8202
 
pint24e:
	jmp	[int24]		; give it to MOS if block device;R8202


;	SRCHFILE searches for printable file in print directory
;	Exits:	NZ [best????] filled with best print file found
;		ZR if no printable file found

srchfile:
	xor	ax, ax			; iniz file size
	mov	[bestsize], ax
	mov	[bestsize+2], ax
	mov	[bestname+FNMPRIOR], al	; iniz priority
	mov	[bestdate], -1		; set bestdate to worst	PTR 60
	lea	di, scrnseg3
	mov	[seg3ptr], di		; iniz pntr for screen file display

	lea	dx, finddta		; set find's dta=scratch address
	MOS	1Ah

	lea	dx, srchname
	sub	dx, [pathlen]		; get search template
	xor	cx, cx			; set attribute to files
	MOS	4Eh
	jnc	srchloop		; no files match
	jmp	srchend

srchloop:
	mov	di,[seg3ptr]		; get screen display pointer
	cmp	byte ptr [di],-1
	je	srchfull		; no room to display

	add	di,2			; past col, row
	lea	si,findname
	mov	cx, FILNMSIZ
	rep movsb			; move filename to display struct
	mov	ax,[findsize]
	mov	dx,[findsize+2]
	mov	bx,[seg3ptr]		; place file's size in display struct
	add	bx,21			; at last char of structure
	mov	cx,7
	call	bintodec
	add	[seg3ptr],23		; get to next display record

srchfull:				;2.04 ***
	cmp	[findname+FNMDISP],'H'	; check disposition
	je	srchnext
	mov	ax,[findsize]		; be sure length not zero
	or	ax,[findsize+2]
	jz	srchnext

	;	Test all classes are printable
	mov	al, [findname+FNMCLASS]	; get file's class
	cmp	[curclass], '*'		; test printing any class
	je	srchprtr		; yes check printer
	cmp	al, [curclass]
	jne	srchnext		; check printing this class
	
srchprtr:				; check printer is valid
	call	clspadr
	cmp	[si].printer, 0		; is printer associated?
	jl	srchnext		; no try next

srchprior:
	mov	bl,[findname+FNMPRIOR]	; get priority
	cmp	bl,[bestname+FNMPRIOR]
	jl	srchnext
	jg	srchfound		; higher priority found
	
	mov	ax,[findtime]		; compute time difference	PTR 60
	sub	ax,[besttime]		;				PTR 60
	mov	ax,[finddate]		;				PTR 60
	sbb	ax,[bestdate]		; check	created sooner		PTR 60
	jae	srchnext

srchfound:
	mov	ax,[finddate]		; move find items to best items	PTR 60
	mov	[bestdate],ax		; found better file		PTR 60
	mov	ax,[findtime]		;				PTR 60
	mov	[besttime],ax		;				PTR 60

	lea	si,findname
	lea	di,bestname		; save found file's name/size/date/time
	mov	cx, FILNMSIZ
	rep movsb
	mov	ax,[findsize]
	mov	[bestsize],ax
	mov	ax,[findsize+2]
	mov	[bestsize+2],ax

	; get next Spool file in directory
	
srchnext:
	MOS	4Fh		; find next matching file
	jc	srchend
	jmp	srchloop

srchend:
	mov	al,' '		; blank remainder of file display
	mov	bx,[seg3ptr]
srchblank:
	cmp	byte ptr [bx], -1
	je	srchxit		; test end of screen
	mov	di, bx
	add	di, 2		; get addr of file's name in screen
	mov	cx, 20
	rep stosb
	add	bx, 23
	jmp	srchblank

srchxit:
	mov	al, [bestname+FNMPRIOR]
	or	al, al		; return any file found flag
	ret

;	OPEN opens file [bestname] found from directory search
;	Enter:	[bestname] set to file name
;	Exits:	CY set if error on open
;		AX = file handle
;		clears [bufflen]

open:
	lea	si,bestname
	lea	di,scrnfile	; move name to display area
	mov	cx, FILNMSIZ
	rep movsb

	mov	ax,[bestsize]	; format file size for display
	mov	dx,[bestsize+2]
	lea	bx,scrnsize+6
	mov	cx,7
	call	bintodec

	mov	al, [bestname+FNMCLASS]
	call	clspget		; get class's parms for printing

	call	dispscrn	; display file for errors

	mov	[buffptr], offset buffer
	mov	[bufflen], 0	; init the buffer vars
	
	lea	si,bestname	; prepare to open
	lea	di,filname
	mov	cx, FILNMSIZ
	rep movsb
	lea	dx,filname
	sub	dx,[pathlen]
	mov	al,2		; open mode=I/O since deleting later
	MOS	3Dh
	jc	openxit
	mov	[filfd], ax	; save file's handle
openxit:
	ret


;	DISPSCRN displays the print statistics and files screen
;	Destroys: ALL

dispscrn:
	mov	al, [curclass]	; set current class
	mov	[scrnclas], al
	
	mov	ax,[curpage]	; format page number
	xor	dx,dx
	lea	bx,scrnpage+3
	mov	cx,4
	call	bintodec

	mov	bx,[bestsize]	; compute percent printed
	mov	cx,[bestsize+2]
	mov	ax,[prtsize]
	mov	dx,[prtsize+2]
	call	normalize	; normalize so no divide fault
	jz	disps0		; if zero print 0
	mov	ax, dx
	mul	[hundred]	; 100*norm prtd / filesize
	div	cx
	xor	dx, dx
disps0:
	lea	bx,scrnpct+2
	mov	cx,3
	call	bintodec

	lea	si,scrnseg2
	mov	cx, seg2len	; check scrn2 has changed
	call	chksum
	cmp	ax,[seg2chksm]
	jz	dispscr3
	mov	[seg2chksm],ax
	call	writscrn

dispscr3:			; check if file display has changed
	lea	si, scrnseg3
	mov	cx,seg3len	; compute checksum on scrnseg3
	call	chksum
	cmp	ax,[seg3chksm]
	je	dispxit		; display only if screen has changed

	mov	[seg3chksm],ax
	call	writscrn
	
dispxit:
	ret


;	NORMALIZE normalizes two long integers by the same number of shifts
;	Enter:	[DX,AX], [CX,BX] long integers
;	Exits:	register pairs left shifted until one's sign bit is filled
;		ZR if all register are 0

normalize:
	push	ax
	or	ax, bx
	or	ax, cx
	or	ax, dx
	pop	ax
	jz	normlxit

normlup:
	test	dh, 80h		; test sign bits
	jnz	normlxit
	test	ch, 80h
	jnz	normlxit

	shl	ax, 1
	rcl	dx, 1
	shl	bx, 1
	rcl	cx, 1
	jmp	normlup

normlxit:
	ret



	subttl	COMMAND processing
	page


cmdlist	label	word		; command chad/routine !!alphabetic order!!
	dw	'C', offset clascmd
	dw	'D', offset deltcmd
	dw	'F', offset flshcmd
	dw	'L', offset lptcmd
	dw	'M', offset modfcmd
	dw	'R', offset rstrcmd
	dw	'S', offset stopcmd
	dw	'X', offset exitcmd
	dw	-1


;	COMMAND dispatch command to list associated routine
;	Calls command routines that return with SI => error message
;	Enter:	AL = command key entered
;	Destroys: ALL

command:
	and	al, 0DFh	; uppercase command key
	jnz	cmdchrok
	mov	al, ' '		; command character turned into a zero
cmdchrok:
	mov	[scrncmdc], al	; display command char
	push	ax
	lea	si, scrncmd
	call	writscrn
	pop	ax
	lea	bx, cmdlist
	lea	si, msgcom	; get unknown command error msg
cmdloop:
	cmp	al, [bx]	; test match
	jz	cmdexec
	jl	cmderr		; not in list - return with error
	add	bx, 4		; get to next char/routine
	jne	cmdloop
	
cmdexec:
	xor	si, si		; clear error message
	call	[bx+2]		; call routine
	or	si, si		; test for error message
	jz	cmdxit

cmderr:
	call	disperr		; display err, wait for CR
cmdxit:
	lea	si, msgerrex	; clear errors/prompts...
	call	writscrn
	ret
	

	
;	CLSCMD ask user for new class to print (A-Z or *)

clascmd:
	lea	si,scrnsegc	; ask for new class
	call	writscrn
	mov	ax, 1		; get 1 character
	call	readkeyb
	mov	al,[keybuff]
	lea	si,msgclass	; error mesg if not A-Z,*
	call	classchk
	jc	clasxit		; if not valid return with error

	mov	[curclass], al	; set new printer class
	mov	[scrnclas], al
	lea	si, scrncseg
	call	writscrn
	xor	si, si		; return no error
clasxit:
	ret



;	FLSHCMD flush and disposes the current file

flshcmd:
	lea	si, msgnofil
	cmp	[filfd],-1		; test file printing
	je	flshxit
	call	close			; close file and printer
	call	dispose			; delete/rename file
	call	closelpt
	xor	si, si			; clear error message
flshxit:
	ret
	


;	LPTCMD change the current printer associated with class

lptcmd:
	lea	si,scrnsegc1		;2 *** prompt for class letter to change
	call	writscrn 		;2
	mov	ax, 1			; get 1 char
	call	readkeyb		;2
	mov	al,[keybuff]		;2
	lea	si, msgclass		; if invalid class
	cmp	al,'A'			;2 *** check for valid class ***
	jb	lptxit 			;2 *** below 'a' - error ***
	cmp	al,'Z'			;2
	ja	lptxit			;2 *** above 'z' - error ***
	mov	[msglpcls],al		;2 *** put class letter into msg ***
	
	call	clspget			; get class's parms into cur.
	mov	al, cur.printer
	add	al, '1'
	mov	[scrnsglp],al		;2 Place lpt# in messages
	lea	si,scrnsegl		;2 *** prompt for lpt # ***
	call	writscrn 		;2
	mov	ax, 1			;2 *** read 1 char ***
	call	readkeyb		;2
	mov	al,[keybuff]		;2 *** put char into al ***
	mov	[msglplpt],al		;2 *** put lpt# into msg ***
	
	lea	si, msgbadlpt
	cmp	al,'0'			;2 *** verify valid lpt # ***
	jb	lptxit
	cmp	al,'3'
	ja	lptxit
	sub	al,'1'			;2 *** make an lpt # for int 17 ***
	mov	[cur.printer], al	; set printer #
	
	mov	al, [msglpcls]		; store these parms
	call	classset
	lea	si,msglptset		;2 *** print msg to indicate change made
	
lptxit:
	mov	al, [curclass]		; get current parms
	call	clspget
	ret



;	RSTRCMD restart printing current file at different page

rstrcmd:
	lea	si, msgnofil
	cmp	[filfd],-1
	je	rstrxit

	lea	si,scrnsegr		; ask for new page number
	call	writscrn
	mov	ax, 5			; read keyboard characters
	call	readkeyb

	lea	si,keybuff		; convert to binary
	mov	cx, 5
	call	dectobin
	lea	si, msgdpc		; error message
	cmp	al, ' '			; should terminate with space
	jne	rstrxit
	or	dx, dx			; test 0 entered
	jz	rstrxit
	
	mov	[rstrpage], dx
	call	close			; close file and printer
	call	closelpt
	call	open			; open same
	mov	al, [cur.printer]
	call	openlpt
	
rstrloop:
	call	read			; read until page found
	lea	si, msgnopag
	jc	rstrxit			; EOF before page (no close - still active)
	mov	dx, bx			; pntr to read line
	call	calcline
	add	[prtsize],cx		; sum bytes pseudo-printed
	adc	[prtsize+2],0
	mov	ax, [rstrpage]
	cmp	ax, [curpage]		; wait until [page] = bx
	jnz	rstrloop		; decr page and loop til zero
	xor	si, si			; no error message
rstrxit:
	ret



;	CMDFILE get print filename in 'othname' and checks file exists
;	Exits:	NZ if SI => error message
;		ZR [othname] user entered filename

filecmd:
	lea	si, srchname
	lea	di, othname		; iniz othname template
	mov	cx, FILNMSIZ
	rep movsb
	
	lea	si,scrnsegd		; ask for filename
	call	writscrn
	mov	ax, 6			; get 5 characters
	call	readkeyb
	lea	si,keybuff		; set up asciiz string
	lea	di,othname+2
	mov	cx, 6
	rep movsb

	lea	di, othname+FNMEXT	; search for any extension
	lea	si, wildext
	mov	cx, 3
	rep movsb
	xor	cx,cx			; file attribute
	lea	dx,othname
	sub	dx,[pathlen]
	MOS	4Eh			; find matching file
	lea	si,msgnofnd
	jc	filexit 		; jump if no match
	
	lea	si,findname		; name to delete
	lea	di,othname
	mov	cx, FILNMSIZ
	rep movsb
	xor	si, si
filexit:
	or	si, si
	ret



;	DELTCMD delete print file in print directory

deltcmd:
	call	filecmd
	jnz	deltxit			; return if error

	lea	dx, othname		; get ptr to filename
	sub	dx,[pathlen]
	MOS	41h			; delete file
	lea	si, msgdelet
	jc	deltxit
	call	srchfile		; get new files
	call	dispscrn		; display them
	xor	si, si			; successful return
deltxit:
	ret



;	MODFCMD modify Disposition, Priority, Class of print file

modfcmd:
	call	filecmd
	jnz	modfxit

	lea	si, othname
	lea	di, rnamname
	mov	cx, FILNMSIZ	; copy filename for rename
	rep movsb

	lea	si,scrnsegm	; ask for new dpc
	call	writscrn
	mov	ax, 3		; get 3 characters
	call	readkeyb
	cmp	ax, 3		; be sure they entered 3 bytes
	lea	si, msgdpc
	jne	modfxit

	lea	si,keybuff	; set up new name
	lea	di,rnamname+FNMEXT
	mov	cx,3
	rep movsb

	lea	dx,othname
	sub	dx,[pathlen]
	lea	di,rnamname
	sub	di,[pathlen]
	MOS	56h		; rename file
	lea	si, msgename
	jc	modfxit

	call	srchfile	; redisplay file screen
	call	dispscrn
	xor	si, si
modfxit:
	ret



;	STOPCMD toggles [stopped] which suppresses printing/selections

stopcmd:
	lea	si,msgproff
	xor	[stopped],0ffh	; toggle stop switch
	jnz	stopxit
	lea	si,msgpron
stopxit:
	call	writscrn	; display/blank 'STOPPED'
	xor	si, si		; no error message
	ret



;	EXITCMD exit to command processor

exitcmd:
	mov	al, 24h		; for interupt 024h		;R8202
	lea	si, int24
	call	intercept	; restore critical error vector
	call	dispclr
	xor	al, al		; exit without error
	MOS	4Ch		; terminate


	subttl	PRINT ROUTINE  -  LOOP PRINTING & CHECK KEYBOARD
	page

;	PRINT loop printing available files and checking keyboard

prtwait:
	call	srchfile	; scan print directory for display
	call	dispscrn	; display print statistics
	mov	[scrncmdc], ' '	; blank command char display
	lea	si, scrncmd
	call	writscrn
	call	waitkey 	; wait for keystroke or timeout

print:
	call	keybtest	; test key available
	jz	prtfile		; zero if no key entered
	call	command		; do command processing
	jmp	prtwait		; wait for another command
	
prtfile:
	cmp	[filfd], -1	; a print file open ?
	jne	prtstop		; yes check in stopped state

	call	srchfile	; no file open test any available
	jz	prtwait

	test	[stopped], -1	; check stopped before open
	jnz	prtwait
	call	open		; open print fil
	jc	prterr		; file open error
	mov	al, [cur.printer]
	call	openlpt		; open printer
	
prtstop:
	test	[stopped],-1	; check if printer stopped
	jnz	prtwait		; wait for keystroke

	call	read		; get line to print
	jc	prteof
	mov	dx, bx		; get line ptr to DX

	test	[curline], -1	; test start of page
	jnz	prtprnt
	cmp	[filname+11], 'U'
	jl	prtprnt		; and single sheet printer
	
	push	cx		; save print line length
	push	dx		; and pointer to line
	call	feedpage	; ask user to feed page to printer
	pop	dx
	pop	cx
prtprnt:	

	mov	bx, [prtfd]	; get descr to write to
	call	write		; write line to printer
	jc	prterr

	mov	ax, [curpage]	; redisplay screen on new page
	cmp	ax, [lstpage]
	je	print		; if same page don't display

	mov	[lstpage], ax
	call	dispscrn	; display print statistics
	jmp	print

prteof:
	or	ax, ax		; test real file error
	jc	prterr
	call	close		; close file & finish printing
	call	dispose		; delete/rename print file
	call	closelpt	; output class's terminating string
	jmp	print

prterr:
	lea	si, msgioerr
	ret			; return to EXEC


;	PAGEFEED prompt user to insert page in printer
;	Destroys: ALL

feedpage:
	lea	si,msgnpage	; tell him to insert new page
	call	writscrn
	lea	si,msgerror
	call	writscrn 	; tell him to hit return
	mov	ax, 0		; no chars wanted
	call	readkeyb	; wait for return
	lea	si,msgerrex
	call	writscrn 	; erase message from screen
	ret

	subttl	Hilevel I/O routines

;	READ returns pointer/len of next line in file, line ends with
;	<CR>, <LF> or <FF> or line length > BUFSIZ.
;	Exits:	BX => start of line/page
;		CX = length of line/page
;		SI => pointer to end of line/page
;		CY if file error encountered (ie, end-of-file)
;	Destroys: ALL

read:
	mov	bx, [buffptr]
	mov	cx, [bufflen]
	mov	si, bx			; get pointer to source reg
	jcxz	readread

readloop:
	lodsb
	cmp	al, 0Ch			; test for formfeed
	je	readret
	cmp	al, 0Ah			; or line feed
	je	readline
	cmp	al, 0Dh			; or carriage return
	je	readline
	loop	readloop
;BWR 10/11/89
;
;	If none of the above characters were found in the buffer, don't
;	just keep filling the buffer - it will overflow.  Dump it out
;	and start it over.
;
	jmp	readret
;BWR 10/11/89

readread:
	mov	cx, [bufflen]		; move remainder of buffer
	cmp	cx, BUFSIZ		; if string larger than buffer
	jg	readret			; return it (even without <CR><LF>)
	
	lea	di, buffer
	add	di, cx			; to beginning of buffer
	dec	si
	dec	di			; point to last char
	std				; backwards copy
	rep movsb
	cld
	
	lea	dx, buffer		; append read to buffer remainder
	mov	[buffptr], dx
	add	dx, [bufflen]
	mov	si, dx			; update pointer
	mov	bx, [filfd]
	mov	cx, BUFSIZ
	MOS	3Fh			; read from file
	lea	bx, buffer		; reset regs
	jc	readxit
	or	ax, ax			; test anything read
	jnz	readgot

	test	[bufflen], -1		; EOF test any chars left
	stc				; in buffer
	jz	readxit			; no give error return

	; delete EOF chars (^Z) from end of file
readeof:
	cmp	byte ptr [si-1], 1Ah	; test ^Z was last char
	jne	readend
	dec	si			; backup one char
	dec	[bufflen]

	stc				; exit as EOF
	jz	readxit

	; chars at end of file without <CR> or <LF>	
readend:				; so printer will output line
	mov	word ptr [si], 0A0Dh	; append CR, LF to buffer
	mov	ax, 2
readgot:
	add	[bufflen], ax		; add lengths
	mov	cx, ax			; get additional length of buffer
	jmp	readloop		; scan until line/page


	; found a line/page terminator - return the line
readline:
	dec	cx			; check another char left
	jz	readret
	add	al, [si]		; check for <CR><LF> or <LF><CR>
	cmp	al, 0Dh + 0Ah
	jne	readret
	inc	si			; yes line ends past <CR><LF>
	
readret:
	mov	cx, si			; calc chars in line
	sub	cx, bx
	sub	[bufflen], cx		; update length & pointer
	mov	[buffptr], si
	or	ax, ax			; set beginning page flag / clear err
readxit:
	ret


;	WRITE outputs line to printer, conditionally supresses formfeeds
;	Enter:	BX = printer file descriptor
;		CX = number of chars to output
;		DS:DX => chars to write (ends with FF, CR or LF)
;		[cur.ffskip] to suppress unnecessary formfeeds
;	Exits:	CY on file errors (AX = errcode)
;		[curpage], [curline] updated
;	Uses:	AX, CX

;	WRITALL outputs line without formfeed suppression or page/line
;	calculation.

write:
	clc			; no errors from here
	jcxz	wrtxit		; if no chars exit quick
	call	calcline	; update curline/curpage
writall:
	mov	ax, [retrys]	; reset the error count		;R8202
	mov	[errcnt], ax
	MOS	40h		; write line to printer
wrtxit:
	ret


;	CALCLINE calculate the line/page after printing a string
;	Enter:	Parameters as 'write' above
;	Exits:	[curpage], [curline] [prtsize] updated
;		CX updated if skipping a formfeed
;	Saves:	ALL

calcline:	
	add	[prtsize],cx	; sum characters printed
	adc	[prtsize+2],0

	push	si
	mov	si, dx
	add	si, cx		; LF or FF ends string??
	cmp	byte ptr [si-1], 0Ch
	pop	si
	jne	calclf

calcff:
	cmp	[curline], 0	; already at top of page?
	jnz	calcpage	; no start a new page
	test	[cur.ffskip], -1; skipping extra formfeeds?
	jz	calcpage
	dec	cx		; yes! don't write FF (last char)
	jmp	calcxit

calclf:
	inc	[curline]
	mov	ax, [curline]	; test line starts a page
	cmp	ax, [cur.pagelen]
	jl	calcxit

calcpage:
	inc	[curpage]	; another page/ line 0 after this
	mov	[curline], 0
calcxit:
	ret


;	CLOSE closes the print file.  Possibly delete/rename print file.
;	Exits:	CY if I/O error (AX=errcode)
;	Destroys: ALL

close:
	xor	ax, ax
	mov	[bestsize], ax		; clear file size
	mov	[bestsize+2], ax
	lea	bx,scrnsize+6
	mov	dx, ax			; clear the file size display
	mov	cx,7
	call	bintodec

	mov	bx, [filfd]		; close the print file
	MOS	3Eh
	pushf				; save close status
	mov	[filfd], -1
	lea	si,nullname
	lea	di,scrnfile		; reset display name to 'null'
	mov	cx, FILNMSIZ
	rep movsb
	popf				; restore close status
	ret


;	DISPOSE deletes/renames [filname] depending on disposition
;	Exits:	CY if I/O error (AX=errcode)

dispose:
	cmp	[filname+FNMDISP],'D'	; check for disp=delete
	jne	dsposave 		; no, jump
	lea	dx,filname
	sub	dx,[pathlen]
	MOS	41h			; yes, delete it
	jmp	short dsposxit

dsposave:
	lea	si,filname		; disp=save 
	lea	di,othname
	mov	cx, FILNMSIZ
	rep movsb
	mov	[othname+FNMDISP],'H'	; rename to disp=hold
	lea	dx,filname		; ds:dx is old name
	sub	dx,pathlen
	lea	di,othname		; es:di is new name
	sub	di,[pathlen]
	MOS	56h

dsposxit:				; return with delete/rename error
	ret


;	OPENLPT opens the printer driver and writes iniz string
;	Enter:	AL = binary printer to open 'LPTx'
;	Exits:	CY if file error occurred (AX = errcode)
;		DX = printer handle
;		[prtsize], [curpage], [curline] cleared
;	Destroys: ALL

openlpt:
	add	al, '1'		; construct printer name 'LPTx'
	mov	[prtid], al
	mov	al,1		; open printer driver for writing
	lea	dx,prtname
	MOS	3Dh
	jc	olptxit		; return with CY
	mov	[prtfd], ax

	mov	bx, ax		; place driver in raw mode
	mov	al,0
	MOS	44h
	jc	olptxit

	xor	dh,dh
	or	dl,020h		; place in raw mode set bit 5
	mov	al,1
	MOS	44h

	mov	si, [cur.iniz]	; get iniz string
	call	strlen
	mov	dx, si		; write initialization string
	call	writall		; without formfeed suppression
	jc	olptxit


olptxit:			; return BX = printer's file descr
	ret


;	CLOSELPT writes the termination string and closes the printer
;	Enter:	BX = printer's file descriptor
;	Exits:	CY if I/O error (AX = errcode)

closelpt:
	mov	si, [cur.fini]
	call	strlen
	mov	dx, si		; output termination string
	mov	bx, [prtfd]
	call	write
	jc	clptxit
	
	xor	ax,ax
	mov	[curpage],ax	; clear page/size/line
	mov	[curline],ax
	mov	[prtsize],ax	; clear bytes printed
	mov	[prtsize+2],ax

	mov	al,0		; get device info
	MOS	44h
	jc	clptxit

	xor	dh,dh
	and	dl,0DFh		; revert to ASCII mode ??
	mov	al,1
	MOS	44h
	jc	clptxit

	MOS	3Eh		; close the file
	mov	[prtfd], -1
clptxit:
	ret



;	WAITKEY waits for keystoke available or [waitcnt] ticks
;	Destroys: ALL

waitkey:
	mov	bx, [waitcnt]
	test	[osmos], -1	; running MOS
	jnz	waitmos
	
waitdos:
	push	es
	mov	ax, BIOS
	mov	es, ax		; get to tick counter
	assume	es:BIOS
	mov	cx, [tick_cntr]
watdloop:
	mov	ah, 1		; test key ready
	int	16h
	jnz	watdxit
	mov	dx, [tick_cntr]
	sub	dx, cx		; get ticks elapsed
	cmp	bx, dx
	ja	watdloop
watdxit:
	pop	es
	assume	es:_text
	ret
	
	

waitmos:
	mov	ax, 703h	; wait for time out or keystroke
	int	SERVICES	; MOS extended function
	ret

	subttl	Subroutines
	page


;	READCTL reads the 'PRINT.CTL' file, digests it, and sets the
;	iniz/fini pointers in the 'clsprm' array
;	Exits:	CY if I/O error (AL = errorcode) DS:DX => error message
;		NC if control file successfully read/formatted

readctl:
	lea	si, prtctlnam	; get filename
	lea	di, othname
	mov	cx, FILNMSIZ	; place in other for path prefix
	rep movsb

	lea	dx, othname	; get beginning of name
	sub	dx, [pathlen]
	mov	al, 0		; for reading
	MOS	3Dh		; open the file
	lea	dx, msgprtctl
	jnc	rdctlopn
	cmp	ax, 2		; test not found
	jne	rdctlxit	; give error if another fault

	mov	cx, 0		; read 0 chars
	lea	si, buffer + (2 * BUFSIZ)
	jmp	rdctlnul

rdctlopn:
	mov	bx, ax		; returned file descr
	lea	dx, buffer (2 * BUFSIZ)
	mov	si, dx		; save for later
	mov	cx, -1		; read entire file
	MOS	3Fh
	lea	dx, msgprtctl
	jc	rdctlxit
	mov	cx, ax

	MOS	3Eh		; close the file

rdctlnul:	
	mov	di, si		; digest control file
	mov	al, 'A'
	
rdctlfmt:
	call	clspget		; get class parameters
	push	ax		; save class
	mov	[cur.iniz], di
	call	ctlform		; format the control line
	mov	[cur.fini], di
	call	ctlform		; and the termination line
	pop	ax		; store class parms
	call	clspset
	inc	al		; next class
	cmp	al, 'Z'
	jle	rdctlfmt

	clc			; return without error
rdctlxit:
	ret


;	CTLFORM transforms control escapes in the printer control file
;	to Ascii chars.  
;	Enter:	DS:SI => printer control source line, terminated by
;			some control char or CX = 0
;		ES:DI => buffer to store transformed control file
;		CX = length of printer control line
;	Exits:	DS:SI => updated to end of line (after <CR>,<LF>)
;		ES:DI => end of stored control line (terminated with null)
;		CX = remaining chars in control file/line

ctlform:
	xor	ah, ah		; AH flags last char was '^'
	jcxz	ctlfxit
ctlfnext:
	lodsb
	cmp	al, 0Ah		; check LF
	je	ctlfeol
	cmp	al, 0Dh		; or CR
	je	ctlfeol
	cmp	al, 1Ah		; or ^Z for EOF
	je	ctlfeol
	cmp	al, '^'		; test control char escape
	jne	ctlfsto
	xor	ah, -1		; set/test last was '^'
	jne	ctlflup
	
ctlfsto:
	or	ah, ah		; turn this into control char?
	jz	ctlfnctl
	and	al, 1Fh		; turn into control char
ctlfnctl:
	stosb
	xor	ah, ah		; clear make-control flag
ctlflup:
	loop	ctlfnext	; loop until EOL or CX = 0

ctlfxit:			; EOF or EOL
	xor	al, al
	stosb			; terminate digested line
	ret

ctlfeol:			; found <CR> or <LF>
	dec	cx
	jcxz	ctlfxit		; no more chars
	add	al, [si]	; test for <CR><LF> or <LF><CR>
	cmp	al, 0Ah + 0Dh
	jne	ctlfxit

	inc	si		; yes scarf next char
	dec	cx
	jmp	ctlfxit


;	BINTODEC translates binary long to Ascii string.  Ascii is spaced
;	for leading zeroes (0).
;	Enter:	DS:BX => rightmost ASCII char
;		DX,AX = long unsigned number
;		CX = number of digits to produce
;	Exit:	DS:BX => most significant digit
;	Destroys: AX, CX, DX


bintodec:
	push	cx		; save destination length 
	div	[w10000] 	; cut length to 4 digits
	push	ax		; save quotient
	mov	ax,dx
	call	btdword		; decode least significant
	pop	ax
	jcxz	btdsmall
	call	btdword		; decode most significant
btdsmall:
	pop	cx
	dec	cx		; get dest length to zero suppress
	jz	btdxit
btdspace:
	inc	bx
	cmp	byte ptr [bx], '0'
	jnz	btdxit		; turn leading zeroes into spaces
	mov	byte ptr [bx], ' '
	loop	btdspace
btdxit:
	ret
	
	
btdword:
	mov	ch,4		; 4 digits per loop
btdloop:
	xor	dx,dx
	div	[ten]		; dx:ax is source integer
	add	dl,'0'		; cx is length of target
	mov	[bx],dl		; bx is end of target
	dec	bx
	dec	cl
	jz	btdlupx
	dec	ch
	jnz	btdloop
btdlupx:
	xor	ch,ch		; return len remaining
	ret

;----- Function DECTOBIN ---------------------------------------------------
;
;  Conversion of ASCII decimal number to unsigned value.
;
;	Input:	DS:SI	=> ASCII string to be converted.
;		CX	=  Length of string to be considered.
;
;	Output: AL = Last character read-in.
;		DX = Value.
;		CF - Set if a non-numeric character has been discovered.
;
;  All registers except DX saved.
;
;----------------------------------------------------------------------------
dectobin	proc	near

	push	cx
	push	si

	xor	dx, dx
dtbloop:
	mov	al,[si] 	;Get next character.
        cmp     al, 0           ;End of ASCIIZ string?
        je      dtb_OK          ;If so, stop scan
	cmp	al, '0'
	jb	dtb_error
	cmp	al, '9'
	ja	dtb_error

	mov	ax, dx		;Multiply present value by 10, add new digit.
	mul	[ten]
	mov	dx, ax
	xor	ah, ah
	lodsb
	push	ax		;Hold the character for return if end of loop.
	sub	al, '0'
	add	dx, ax
	pop	ax
	loop	dtbloop
dtb_OK:
	clc
	jmp short dtb_exit

dtb_error:
	stc

dtb_exit:
	pop	si
	pop	cx
	ret

dectobin        endp

;	WRITSCRN displays entire array of screen structures
;	Enter:	DS:SI => array of screen structures, terminated by -1
;		screen struct: col, row, ASCIIZ message 
;	Uses:	AX, BX, SI

writscrn:
	lodsw			; get col, row
	mov	dx, ax
	or	al,al		; check for end
	js	wrscexit
	mov	ah,2		; set cursor position
	mov	bh,0		; page number
	int	10h

wrscloop:
	lodsb			; get next char
	or	al, al		; test string terminator
	jz	writscrn	; end of string
	mov	ah,0Eh
	mov	bx,7		; display char (dim, white)
	int	10h
	jmp	wrscloop
	
wrscexit:
	ret


;	READKEYB reads AL keys from buffered keyboard input
;		User must press <Return> to complete entry
;	Enter:	AL = number of char wanted (0 to 10)
;	Exits:	AX = number of chars entered
;		ZR if no keys entered
;		[keybuff] = chars read (uppercased!) + spaced to number wanted
;	Saves:	ALL

readkeyb:
	push	si
	push	dx
	push	cx
	inc	al
	mov	[keyblen], al	; set length of buffer
	lea	dx, keyblen	; start of buffer
	MOS	0Ah		; wait for <CR>
	
	lea	si, keybuff
	mov	cl, [keybcnt]	; get pointer, length for uppercase loop
	xor	ch, ch
	jcxz	rdkbspace
rdkbupcas:
	lodsb			; get char
	cmp	al, 'a'
	jb	rdkblup1
	cmp	al, 'z'		; test uppercase
	ja	rdkblup1
	and	byte ptr [si-1], 0DFh
rdkblup1:
	loop	rdkbupcas

rdkbspace:
	mov	cl, [keyblen]
	sub	cl, [keybcnt]	; number of chars to space
	jz	rdkbxit
rdkblup2:
	mov	byte ptr [si], ' '
	inc	si
	loop	rdkblup2

rdkbxit:
	mov	al, [keybcnt]	; return count of chars entered
	and	ax, 0FFh	; and set ZR
	pop	cx
	pop	dx
	pop	si
	ret


;	STRLEN returns chars to terminating 0 (null) in ES:DI
;	Enter:	ES:SI => null terminated string
;	Exits:	CX = length of string
;	Saves:	ALL

strlen:
	push	di
	mov	di, si
	push	ax		; search for terminating 0 (null)
	xor	ax, ax
	mov	cx, -1		; get a large number
	repne scasb		; find null
	not	cx
	dec	cx		; turn into positive length
	pop	ax
	pop	di		; restore pointer
	ret
	

;	KEYBTEST Check if key is ready, returns any key available
;	Exits:	ZR if no key available
;		NZ if AX = scan code | key code
;	Uses:	AX

keybtest:
	mov	ah, 1		; check anything available
	int	16h
	jz	keybxit
	xor	ah, ah		; get the key
	int	16h
	or	ax, ax		; flag got a key
keybxit:
	ret


;	DISPERR displays error message and 'Hit Return' (msgerror) waits
;	for user acknowledge, then clears all error messages displayed.
;	Enter:	DS:SI => error message
;	Destroys: ALL

disperr:
	call	writscrn	; display error message
	lea	si,msgerror
	call	writscrn	; then confirm
	mov	[keybuff],1
	xor	ax, ax		; just wait for <CR>
	call	readkeyb
	lea	si, msgerrex	; erase messages/errors from screen
	call	writscrn
	ret

;	DISPCLR clears the screen by scrolling it 25 lines
;	and places cursor at top left
;	Destroys: ALL

dispclr:
	mov	ax,600h		; scroll window and blank it
	mov	bh,7		; attribute
	xor	cx,cx		; begin row, col
	mov	dx,184Fh	; end row, col
	int	10h
	mov	ah,02		; position cursor
	mov	bh,00		; page number
	xor	dx,dx		; row, col
	int	10h
	ret


;	CHKSUM checksum a block of memory.
;	Enter:	DS:SI => Memory to checksum
;		CX = Length of block (WORDS)
;	Exits:	AX = Checksum computed
;	Uses:	CX

chksum:
	push	si
	xor	ax, ax		; clear accumulator

chksmlup:
	ror	ax, 1
	xor	ax, [si]
	add	si, 2
	loop	chksmlup

	pop	si
	ret
	

;	Print File Buffer  -  read file into this Buffer

buffer	label	byte		; print file read into here


;	PRINT.CTL is buffered here after print file buffer
;	2*BUFSIZ is allowed for length of print file buffer

_text   ends
	end	start
