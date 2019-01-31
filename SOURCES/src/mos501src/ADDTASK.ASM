	include page.inc
	title	addtask.asm - add a new mos task
	subttl	addtask memsize,{taskid},{class},{batfile},{termid,port,{{baud}}
comment ^===============================================================
		     development specification

 program name:	moxaddta.com		   assigned to: martin stitt
 module name:	moxaddta		   assign date: 10/27/86
 entry points:	moxaddta		   completed:
 entry from:	command processor
 entry method:	exec
 purpose:	add a new mos task
 refer to:	n/a
 last update:	04/06/92

=======================================================================

mjs 02/24/87	cooking mods: before read 4 bytes from the device driver, 
		must put it in raw mode.

mjs 002/24/87	misc mods: check for 32k min memory size, decrement 
		the port number

dam 03/10/87	pass #k to mositask and not paragraphs. new memory message

jsm 04/30/87	slice fix, put value of scbslice into tcbslice for new task.

sah 05/15/87	low smp abort from itask

rbr 06/10/87	remove reference to tcbkbmap

sah 07/12/87	int 21 80+ calls change to int 38 00+ calls

sah 07/28/87	place a limit of 800k on addtask

jsm 07/30/87	set tcbttry and tcbntry for new tasks

sah 08/08/87	change messages for invalid baud rate or no serial 
		driver installed on system also check out port 
		limit of 24 currently

sah 08/18/87	if no memory management on system then memory usage 
		message will not be display.

jsm 08/18/87	corrected spelling in message "Improper MOS verson number"

jrb 09/29/87	ali changes (baud rate not required)

sah 04/06/88	corrected errorlevel so that it returns errorlevel of 2

jrb 05/20/88	wasn't picking up correct scbtcbpc for tcbvram also 
		dec [portnum] if not vna master console so port 0
		(vna 0) is allowed

rkg 09/08/88	cleanup

rdg 01/10/89	modified vrchk3 to get the tcb address of the
		executing task (parent task)
		modified skip5-skip9 to save the startbat
		in the tcb and to record the parent task tcb
		in the tcb if not using memory management.

sah 02/20/89	converted int 38h calls into int services

mjs 03/10/89	changed the method of checking for a serial driver from
		an int21 call which tries to open $$sc to an int14
		function 6 call.  the int14 method is more generic and
		allows a pcterm workstation task to be added to an
		iona serial port.

sah 03/13/89	convert old int 38 calls 00h and 01h to use new api
		function 22h to add the task.

mjs 05/03/89	moved testing of valid task id number to mosint38.
		also, modified the data structure for int38fun22

sah 07/19/89	added logic for srterm, if baudrate is specified

bwr 11/17/89	messages marked for foreign language translation.

sah 02/20/90	added max option for maximum memory to add

sah 03/21/90	corrections for baudrate if no baudrate is specified.

sah 04/06/90	corrections for vgna, vna, viewport stations.

sah 04/10/90	correction to mistake above.

sah 04/13/90	corrections so slice command in config.sys will work

mjs 08/13/90	removed logic which checks for 15/16 max vna 
		workstations.  this check should be done within vna.sys.
		it now is.

SAH 11/15/91  	Correct problem with VGNA+\maxtation

SAH 04/06/92	Updated for max of 33 users

mjs 09/17/92	removed shareticks and sharetry equates to prevent
		conflict with recent change to mostcb.inc.

=======================================================================^

	subttl	addtask macros, equates, data
	page

;	standard handles

stdin	equ	0000
stdout	equ	0001
stderr	equ	0002

;	dos calls

openfil equ	3dh
closfil equ	3eh
readfil equ	3fh
writfil equ	40h
parsfil equ	29h
quit	equ	4ch
freemem equ	49h
modmem	equ	4ah
getmem	equ	48h
ioctrl	equ	44h

; interupt 38 calls

gftcb	equ	000h
itask	equ	001h
gfscb	equ	002h
gtcba	equ	004h			; get tcb address
atask	equ	022h

;	misc equ's

true	equ	0ffh
false	equ	0

cr	equ	13
lf	equ	10
eof	equ	1ah
tab	equ	9
bell	equ	7
bs	equ	8
bslash	equ	'\'
fslash	equ	'/'
escape	equ	27

true?	macro	testflag
	cmp	testflag,true
	endm

resflg	macro	flag
	mov	byte ptr flag,false
	endm

setflg	macro	flag
	mov	byte ptr flag,true
	endm

mos	macro	fn
	mov	ah,fn
	int	21h
	endm

mos38	macro	fn
	mov	ah,fn
	int	services
	endm

	include	macros.inc
	include options.inc
	include addtask.pub

tcb segment at 0			; use this data segment to reference the
	include mostcb.inc		; labels in the tcb
tcb ends

scbs	segment at	99
	assume	cs:scbs
	include mosscbdf.inc		; used to print memory stats
	assume	cs:nothing
scbs	ends

codeseg segment para

segstart equ	$

	assume cs:codeseg,ds:codeseg,es:codeseg
	org 100h

	.list

start:
	jmp	entrypnt

madd	struc
tsize	dw	0			; task size
tid	dw	0			; task id
tclass	db	' '			; task class
tbatch	dd	0			; task startup batchfile
tdriver dd	0			; task terminal driver
tport	dw	0			; task port
tbaud	dd	0			; task baud rate
; offset +13h
tmemtot dd	0			; total ext mem     (return)
tmemalc dd	0			; ext mem allocated	(return)
tsmpal	dw	0			; task smp allocate (return)
tsmpsiz dw	0			; task smp size (return)
tpercent dw	0			; task percent heap (return)
tres	db	3 dup (0)		; reserved for future
madd	ends


	subttl parse
	page
;======================================================================
; .func: parse
;
; input:
;	ds:si -> string to parse
;
; output:
;	ds:si advanced
;	[prsfcb] filled
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
parse	proc
	push	cx
	push	di
	xor	ax,ax			; initialize the fcb to 0's
	lea	di,[prsfcb]
	mov	cx,12
	cld
	rep	stosb
	lea	di,[prsfcb]
	mov	al,0fh			; control byte
	mos	parsfil
	or	al,al			; set flags on al
	pop	di
	pop	cx
	ret
parse	endp


	subttl str2numdw
	page
;======================================================================
; .func: str2numdw
;
; input:
;	ds:si -> string to convert
;
; output:
;	dx:ax = binary value of string
;	cy if error
;
; comments:
;	converts the numeric string at ds:si to a value in dx:ax, the
;	cy flag will be set for errors or overflow out of dx:ax
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
str2numdw:
	push	bx
	push	cx
	push	di
	push	bp
	xor	ax,ax			; init starting values
	xor	dx,dx			; "     "	"
	cld
	lodsb				; get the first digit
	cmp	al,'0'
	jb	sn2			; invalid number
	cmp	al,'9'
	ja	sn2			; ditto
	sub	al,'0'			; convert from ascii to numeric
	mov	bp,ax			; save intermeadiate value in bp:si
	xor	di,di
sn1:
	lodsb				; get next digit
	cmp	al,'0'
	jb	sn3			; must be end of string
	cmp	al,'9'
	ja	sn3			; end of string
	sub	al,'0'			; if 0-9, convert and mul the previous
	xchg	ax,bp			; value in bp:di by 10
	xchg	dx,di
	sal	ax,1			; multiply by 10 using the equation
	rcl	dx,1			; 10x = 8x + 2x
	jc	sn4			; overflow, value to high
	mov	bx,ax
	mov	cx,dx
	sal	ax,1
	rcl	dx,1
	jc	sn4			; overflow
	sal	ax,1
	rcl	dx,1
	jc	sn4			; overflow
	add	ax,bx
	adc	dx,cx
	jc	sn4			; one more time!
	xchg	ax,bp
	xchg	dx,di
	add	bp,ax			; add the new digit to the tally
	adc	di,dx
	jc	sn4			; ok, really this is the last time!
	jmp	sn1
sn3:
	mov	ax,bp
	mov	dx,di
	clc
sn4:
	pop	bp
	pop	di
	pop	cx
	pop	bx
	ret
sn2:
	stc
	jmp	sn4


	subttl bin2dec
	page
;======================================================================
; .func: bin2dec
;
; input:
;	dx:ax = source data
;	ds:bx -> end of target buffer
;	cx = length of buffer
;
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
bin2dec: 
	push	si
	push	di
	push	cx
	mov	si,cx
	cmp	si,4			; is it real long?
	jle	btdloop1		; no, skip
	div	[w10000]		; yes, do it piecemeal
	mov	cx,4
	mov	di,ax
	mov	ax,dx
	xor	dx,dx
btdloop1:
	div	[w10]
	add	dl,'0'
	mov	[bx],dl
	dec	bx
	xor	dx,dx
	loop	btdloop1
	mov	ax,di
	xchg	cx,si
	sub	cx,4
	jg	btdloop1
	pop	cx
btdloop2:
	inc	bx
	dec	cx
	jz	btdret
	cmp	byte ptr [bx],'0'
	jne	btdret
	mov	byte ptr [bx],' '
	jmp	btdloop2
btdret:
	pop	di
	pop	si
	ret

;		vars for bin2dec

w10000	dw	10000
w10	dw	10


	subttl getparm
	page
;======================================================================
; .func: getparm
;
; input:
;	ds:si -> parsing location
;
; output:
;	cy if error
;	nc if no error
;	  ax = value
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
getparm:
	xor	dx,dx
	call	parse
	cmp	byte ptr [fcbname],0
	clc
	mov	ax,0
	je	gp1
	cmp	byte ptr [fcbname],'0'	; did they enter a 0
	stc
	je	gp1			; yes error
	clc
	push	si
	lea	si,[fcbname]
	call	str2numdw
	pop	si
gp1:
	ret


dec10	dw	10			; constant

	subttl	dec2asc - decimal 2 ascii conversion
	page
;======================================================================
; .func: dec2asc - decimal 2 ascii conversion
;
; input:
;	ax = 16-bit value
;	ds:dx -> 5 byte area to store ascii string result
;
; output:
;	ds:dx -> ascii string
;
; comments:
;	decimal to ascii convertion routine.
;	buffer must be 5 bytes long as it is cleared to blanks.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:nothing, es:nothing, ss:nothing
dec2asc:
	push	ax
	push	dx
	push	si
	mov	si,dx
	mov	byte ptr [si],' '	; clear buffer
	mov	word ptr [si+1],'  '	; "     "
	mov	word ptr [si+3],'  '	; "     "
	pushf
	add	si,4			; point to end of buffer
dec2lp:
	xor	dx,dx
	div	[dec10] 		; isolate next digit
	add	dl,'0'			; convert to ascii
	mov	[si],dl 		; store in buffer
	dec	si			; next digit position
	or	ax,ax			; is that all?
	jnz	dec2lp			; no
	popf
	pop	si
	pop	dx
	pop	ax
	ret


	subttl dofstr - print formated string
	page
;======================================================================
; .func: dofstr - print formated string
;
; input:
;	ax = 16-bit value
;	ds:bx -> 5 byte area to store ascii string result
;
; output:
;
; comments:
;	convert ax value to ascii decimal and print string pointed to by
;	ds:bx without leading spaces.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
	assume	ds:codeseg, es:nothing, ss:nothing
dofstr:
	shl	ax,1			; calc total k
	shl	ax,1
	mov	dx,bx
	call	dec2asc
clrspc:
	cmp	byte ptr [bx],' '
	jne	dostr
	inc	bx
	jmp	clrspc
dostr:
	mov	dx,bx
	mov	ah,9
	int	21h
	ret


;--------------------------- variables -------------------------

workbuf db	128 dup(?)		; general purpose buffer

	dw	0			; space for cr and lf
mmmsg	db	40 dup(0),13,10,'$'	; space for transfer of memman message

prsfcb	db	?			; fcb for the parse procedure
fcbname db	36 dup(?)

memsize dw	0			; convert memsize string into here
finddrv db	0			; flag, true if a driver spec is found
portnum dw	0			; port number value
baudrate dd	0			; baud rate value
taskid	dw	0			; task id value
startbat db	9 dup(0)		; startup batch file name
killtcb db	0			; flag, true if error after tcb was allocated
commafg db	0		; flag to indicate comma was process
drvhndl dw	0			; handle of the terminal device driver
parnttcb dw	0			; tcb of parent task		; rg9006

ddrvstr db	'$$', 7 dup(0)		; terminal driver name

scbptr	dd	?			; pointer to mos scb
slice	db	?			; default time slice for task

strtmsg db	13,10,'Starting task number '  ;@@xlat
strtnum db	'000',13,10,'$'

percmsg db	'00 percent of System Memory Pool (SMP) used.             ',13,10,'$'  ;@@xlat

extmm	db	'00000k of $  ' 	;@@xlat
extmm2	db	'00000k memory used.       ',13,10,'$'	;@@xlat

addparm  madd	<>


;--------------------------- start of code -------------------------


	assume	cs:codeseg,ds:codeseg,es:codeseg
entrypnt:
	jmp	vrchk1			; skip around the data

version label	byte
	include version.inc

vermsg	db	13,10,'Improper MOS Version    ',13,10,'$'  ;@@xlat

vrchk1:
	mov	ah,30h
	mov	bx,ax			; read the mos version number
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax,word ptr [version]
	je	vrchk2
	lea	dx,[vermsg]		; report mismatch
	push	cs
	pop	ds
	mov	ah,9
	int	21h
	mov	al,2			; errorlevel 2
	mov	ah,4ch			; and terminate
	int	21h
vrchk2:
	cld				; for the duration of the program
	mov	ax,offset [endofprog]	; calc size for this program
	add	ax,512			; add space for stack
	mov	sp,ax
	add	ax,15			; round up to next whole paragraph
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	mov	bx,ax
	mos	modmem			; shrink back to just what's needed
	ljc	error5
	push	es
	mov	ah, gtcba		; get tcb address
	mov	bx, -1			; we want address of our tcb
	int	services		; call mos
	mov	[parnttcb], es		; save it for later
	mov	ah,gfscb		; get scb address
	int	services
	assume	es:scbs
	mov	word ptr [scbptr],bx
	mov	word ptr [scbptr+2],es	; store scb address
	mov	al,[bx+scbslice]	; default time slice for later
	mov	[slice],al
	pop	es
	assume	es:nothing
	mov	si,80h			; check the length of the parameter line
	mov	bl,[si]
	or	bl,bl
	ljz	error1
	inc	si
	xor	bh,bh
	mov	byte ptr [si+bx],0	; make sure there is a 0 end marker
ps0:
	lodsb
	cmp	al,' '
	je	ps0
	cmp	al,09			; or tabs
	je	ps0
	dec	si			; point back to char
	cmp	al,','
	lje	error1

; get memory size of task

	call	parse			; parse out memory size
	cmp	byte ptr [fcbname],0	; anything there?
	lje	error1			; must have a memory size parameter

	push	si
	lea	si,[fcbname]

; check if value is "MAX" if so then
; adjust to maximum avaliable task size

	cmp	word ptr ds:[si],'AM'	; check for 'MAX'
	jne	skipmax
	cmp	byte ptr ds:[si+2],'X'
	jne	skipmax
	pop	si
	mov	ah,2dh			; get max task size
	int	services
	mov	ax,dx
	mov	cl,6
	shr	ax,cl
	jmp	short setsize
skipmax:
	call	str2numdw		; get value into dx:ax
	pop	si
	ljc	error2			; syntax error (or they asked for 4.3 gigak)
	or	dx,dx			; if dx <> 0, value too large
	ljnz	error2
	cmp	ax,800			; limit of 800k
	lja	error3
	cmp	ax,32
	ljb	error1			; must have a minimum of 32k
setsize:
	mov	cl,6
	mov	[memsize],ax		; record memory size in paragraphs

; get the task id number

	call	getparm 		; parse the task id
	ljc	error2
	or	dx,dx			; if dx <> 0, value too large
	ljnz	error2
	mov	[taskid],ax

; get starting class for task access

	call	parse			; parse the class letter
	cmp	byte ptr [fcbname],0
	je	skip2
	cmp	byte ptr [fcbname+1],20h
	ljne	error2			; syntax error if > 1 char
	mov	al,byte ptr [fcbname]
	mov	[addparm.tclass],al
skip2:
	call	parse			; parse out the startup batch file
	cmp	byte ptr [fcbname],0
	je	skip6
	push	si
	mov	byte ptr [fcbname+8],' '
	lea	si,[fcbname]
	lea	di,[startbat]
	cld
nloop:
	lodsb
	cmp	al,' '
	je	nout
	stosb
	jmp	nloop
nout:
	pop	si

; get terminal driver id

skip6:
	call	parse			; parse out terminal driver id
	cmp	byte ptr [fcbname],0	; one specified?
	je	skip1			; no
	push	si
	mov	byte ptr [fcbname+8],' '
	lea	si,[fcbname]
	lea	di,[ddrvstr+2]
	cld
dloop:
	lodsb				; copy driver name to ddrvstr
	cmp	al,' '
	je	dout
	stosb
	jmp	dloop
dout:
	setflg	[finddrv]
	pop	si

; get terminal port number

skip1:
	call	getparm 		; parse the port number
	ljc	error2
	or	dx,dx			; if dx <> 0, value too large
	ljnz	error2
	or	ax,ax
	jnz	prtnmok
	cmp	byte ptr [fcbname],0	; was a term driver given?
	ljz	skip3			; no, skip the folowing
	jmp	ernoport		; port number must be specified
prtnmok:
	dec	ax			; compensate for numbering sheme
	mov	[portnum],ax

; get ports baud rate

	cmp	byte ptr ds:[si],','
	jne	skipcomma
	inc	[commafg]
skipcomma:
	call	parse			; parse out the baud rate
	mov	[nobaud],'Y'
	push	es
	push	si
	les	si,[scbptr]
	assume	es:scbs
	mov	es,[si+scbtcbpf]
	assume	es:tcb

; no baud rate specified, must be vna

	cmp	[commafg],0
	ljne	vnax
	cmp	byte ptr [fcbname],0
	ljne	vnax

; the following code was added for sunriver

	test	[tcbvram],4		; sunriver
	jz	nosr
	cmp	word ptr [ddrvstr+2],'RS'
	jne	notsr
	inc	[portnum]		; increment port for sunriver station
notsr:
	pop	si
	pop	es
	jmp	skip3
nosr:
	test	[tcbvram],8		; vna bit
	assume	es:nothing
	pop	si
	pop	es
	jz	vnax3
;
; SAH 11/05/91 The following fix was added for handing coexistence with
; non-coexistence workstation
;
	push	si
	push	ds
	lds	si,cs:[scbptr]
	assume	ds:scbs
	mov	ds,ds:[si+scbtcbpf]
	assume	ds:tcb
	lds	si,dword ptr ds:[tcbcondd]
	mov	ax,word ptr ds:[0ch]	
	cmp	ax,word ptr cs:[ddrvstr+2]
	pop	ds
	assume	ds:codeseg
	pop	si
	jne	vnax3	
;
	inc	[portnum]
vnax3:
	jmp	skip3
vnax:
	mov	[nobaud],'N'
	cmp	[portnum],32		; we now support 33 users
	jb	portok
	jmp	err0a
portok:
	mov	ah,6
	int	14h
	test	ah,80h			; check for a serial driver
	ljz	err0c
	push	si
	lea	si,[fcbname]
	cmp	byte ptr [fcbname],'H'	; using h1 or h2?
	je	hspec
	call	str2numdw		; get baud into dx:ax
	pop	si
	ljc	error2
skip4:
	mov	word ptr [baudrate],ax
	mov	word ptr [baudrate+2],dx
	jmp	skip3
hspec:					; check for a 1 or 2 after the h
	inc	si
	call	str2numdw
	pop	si
	ljc	error2
	or	dx,dx			; if dx <> 0, value too large
	ljnz	error2
	mov	bx,ax
	mov	ax,0c200h
	mov	dx,1			; put 115200 in dx:ax
	cmp	bx,1
	je	skip4
	cmp	bx,2
	ljne	error2			; the number after the 'H' must be 1 or 2
	shr	dx,1
	rcr	ax,1			; divide 115200 by 2
	jmp	skip4

; get task id number
; all the command line info has been read, now allocate tcb
; and attempt to start task

skip3:
	true?	[finddrv]		; was a drive identifier specified?
	ljne	skip5
	lea	dx,[ddrvstr]
	xor	al,al
	mos	openfil 		; open the terminal device driver
	ljc	error6
	mov	[drvhndl],ax

; $$$$$$ future  verify that a device driver was opened using ioctrl
; if fail on open, attempt to add the device

	mov	bx,[drvhndl]
	mov	ax,4400h
	int	21h			; set this device to raw mode
	and	dx,00ffh
	or	dx,20h
	mov	ax,4401h
	int	21h
	mov	cx,4
	lea	dx,addparm.tdriver
	mos	readfil 		; read the first 4 bytes from the driver
	ljc	error7
	mov	bx,[drvhndl]
	mos	closfil 		; close the driver
	ljc	error7

; $$$$$$$$$ future verify existance of $$memman driver
; if find, push as below, else calc addresses within current partition
; and push those values.

skip5:
	mov	ax,[taskid]
	mov	[addparm.tid],ax
	mov	ax,word ptr [baudrate]
	mov	word ptr [addparm.tbaud],ax
	mov	ax,word ptr [baudrate+2]
	mov	word ptr [addparm.tbaud+2],ax
	mov	ax,[portnum]
	mov	[addparm.tport],ax
	mov	ax,[memsize]
	mov	[addparm.tsize],ax
	mov	ax,offset startbat
	mov	word ptr [addparm.tbatch],ax
	mov	ax,cs
	mov	word ptr [addparm.tbatch+2],ax
skip9:
	push	cs			; store the codeseg
	pop	ds			; restore ds to the codeseg
	assume	cs:codeseg, ds:codeseg, es:tcb, ss:nothing
	lea	si,addparm
	mos38	atask			; create a new task
	ljc	baditask
	push	cs
	pop	ds
	assume	ds:codeseg

; the following is done so that slice value will be set in tcb

	push	es
	mov	bx,[tcbid]
	mos38	gtcba
	assume	es:tcb
	mov	al,[slice]
	mov	[tcbslice],al
	pop	es
	mov	ax,[tcbid]		; report task #
	push	dx
	xor	dx,dx
	lea	bx,[strtnum+2]
	mov	cx,3
	call	bin2dec
	pop	dx
	lea	dx,strtmsg		; display 'Starting task number '
	mov	ah,9
	int	21h
	push	es			; save tcb address
	les	bx,[scbptr]		; get scb address again
	assume	es:scbs
	cmp	[bx+scbmmfg],'N'	; is memory management use on system
	je	nomem
	test	[bx+scbmmfea],80h	; even if scbmmfg == 'Y', still need
	jz	nomem			; to see if paging capable (286n)
	push	ds
	lds	bx,dword ptr [bx+scbmmptr]  ; get pointer to used memory
	assume	ds:nothing
	mov	ax,[bx+14]		; pages in use
	mov	bx,[bx+10]		; total pages
	pop	ds
	assume	ds:codeseg
	push	bx
	lea	bx,extmm
	call	dofstr
	pop	ax
	lea	bx,extmm2
	call	dofstr
nomem:
	pop	es
	assume	es:tcb
	mov	ax,[addparm.tpercent]	; get % heap
	mov	word ptr [percmsg],ax	; set in message
	lea	dx,percmsg		; display the percent of heap used
	mov	ah,9
	int	21h
	jmp	cleanexit

;--------------------------- error handlers -------------------------

ernoport:
	lea	dx,ermsgpt
	mov	bp,1
	jmp	showerror
ermsgpt db	'Port number MUST be specified.     ',13,10,'$'  ;@@xlat

badget: 				; error decoding after gettcb call
	cmp	ah,18			; out of heap space?
	lje	errora
	jmp	errorb			; general failure (31)

ermsg0a db	'Invalid port number             ',13,10,'$'  ;@@xlat
ermsg0b db	'Invalid baud rate        ',13,10,'$'  ;@@xlat
nobaud	db	'N'
erali	db	'Error initializing workstation          ',13,10,'$'  ;@@xlat
ermsg0c db	'Serial driver not installed!          ',13,10,'$'  ;@@xlat
ermsgusr db	'Error - maximum number of users already installed!       ',13,10,'$'  ;@@xlat

baditask:
	push	cs
	pop	ds
	assume	ds:codeseg
	cmp	al,8			; insufficient memory?
	lje	error3
	cmp	al,11			; bad format
	je	error0
	cmp	al,87			; invalid parameter - task id not in [1..99]
	lje	error4
	cmp	al,85			; already assigned - task id in use
	lje	error8
	cmp	al,18			; low smp (don't run or errors occurs)
	lje	errora
	jmp	error9			; assume command processor not found

; bad format of information in tcb (invalid port # or baud rate)

error0:
	cmp	ah,1			; bad port #?
	je	err0a			; yes
	cmp	ah,2			; bad baud?
	je	err0b			; yes
	cmp	ah,3			; users exceeded?
	je	errusers		; yes
	jmp	err0b			; bad baud rate from termial driver
err0a:
	lea	dx,ermsg0a
	xor	bp,bp
	jmp	showerror
err0b:
	lea	dx,erali		; ali error if no baud rate specified
	cmp	[nobaud],'Y'
	je	err0b1
	lea	dx,ermsg0b		; else baud rate error
err0b1:
	xor	bp,bp
	jmp	showerror
errusers:
	lea	dx,ermsgusr
	xor	bp,bp
	jmp	showerror
err0c:
	lea	dx,ermsg0c
	xor	bp,bp
	jmp	showerror
error1:
	lea	dx,ermsg1
	mov	bp,1
	jmp	showerror
ermsg1	db	'Invalid memory size (minimum: 32k)      ',13,10,'$'  ;@@xlat

error2:
	lea	dx,ermsg2
	mov	bp,1
	jmp	showerror
ermsg2	db	'Invalid Command form error   ',13,10,'$'  ;@@xlat

error3:
	lea	dx,ermsg3
	xor	bp,bp
	jmp	showerror
ermsg3	db	'Insufficient memory available      ',13,10,'$'  ;@@xlat

error4:
	lea	dx,ermsg4
	xor	bp,bp
	jmp	showerror
ermsg4	db	'Task ID number must be in the range: 1 to 99    ',13,10,'$'  ;@@xlat

error5:
	lea	dx,ermsg5
	xor	bp,bp
	jmp	showerror
ermsg5	db	'Memory allocation error          ',13,10,'$'  ;@@xlat

error6:
	lea	dx,ermsg6
	xor	bp,bp
	jmp	showerror
	ermsg6	db	'Unable to open terminal device driver  ',13,10,'$'  ;@@xlat
error7:
	lea	dx,ermsg7
	xor	bp,bp
	jmp	showerror
ermsg7	db	'Access denied or invalid handle          ',13,10,'$'  ;@@xlat

error8:
	lea	dx,ermsg8
	xor	bp,bp
	jmp	showerror
ermsg8	db	'Specified task ID already in use     ',13,10,'$'  ;@@xlat

error9:
	lea	dx,ermsg9
	xor	bp,bp
	jmp	showerror
ermsg9	db	'Can not find command processor      ',13,10  ;@@xlat
	db	'Check COMSPEC=[d:][path]filename       ',13,10,'$'  ;@@xlat

errora:
	lea	dx,ermsga
	xor	bp,bp
	jmp	showerror
ermsga	db	'Insufficient System Memory Pool (SMP) available                 ',13,10,'$'  ;@@xlat

errorb:
	lea	dx,ermsgb
	xor	bp,bp
	jmp	showerror
ermsgb	db	'General failure when allocating TCB    ',13,10,'$'  ;@@xlat

msgdea	db	'Could not deallocate TCB!    ',13,10,'$'  ;@@xlat

msgcrlf db	13,10,'$'

showerror:
	push	dx
	lea	dx,msgcrlf
	mov	ah,9
	int	21h
	pop	dx
	mov	ah,9
	int	21h
	or	bp,bp
	jz	nohelp
	lea	dx,[helpmsg]
	mov	ah,9
	int	21h
	jmp	nohelp


helpmsg db	'Correct form:      ',13,10  ;@@xlat
	db	'ADDTASK memsize [id] [class] [batchname] [driver port [baudrate]]             ',13,10,'$'  ;@@xlat

nohelp:
dirtyexit:
	mov	al,2			; errorlevel 2
	jmp	done
cleanexit:
	xor	al,al			; errorlevel 0
done:
	mos	quit

endofprog label byte

codeseg ends
	end	start
