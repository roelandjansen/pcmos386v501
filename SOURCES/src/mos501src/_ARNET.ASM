	include page.inc
	title	ARNET.ASM - MOS Arnet Inteligent serial port device driver
	.sall
comment ^==============================================================
		      development specification

 program name:	_arnet.asm			assigned to: Stewart Hyde
 module name:	$arnet.sys			assign date: 04/11/91
 entry points: 	mosint14			completed:   05/21/91
 entry from:   	anywhere
 entry method: 	int 14h
 calls:
 purpose:	provide interupt driven serial i/o for all int 14
		functions.
 refer to:	n/a
 last update:	09/15/92

 Portions of this source code is copyrighted 1987, 1989 arnet corporation
						     all rights reserved  

=======================================================================

 config.sys line is:

  device=$serial.sys /port params /port params ... /port params

      port params are:
	   param=value,...,param=value

  param	      default	acceptable

 ad= port addr   03f8 & 02f8	0 < ad < 8000
 ib= input buffer size    64	32 <= ib < 65536
 ob= output buffer size 1024	16 <= ob < 65536
 hs= handshaking	    n	none & dtr & rts & xoff & xpc
     (note: hs=drp is valid and results in dtr, rts and xpc protocols)
 in= interrupt level	3 & 4	0 or 1 or 2 or 3 or 4 or 5 or 6 or 7
 cn= connection	       local & remote & terminate remote

 note that all options except port numbers are "sticky".  they apply
 to all subsequent ports on the command line as well as the current
 port.


 ***** notice ***** function numbers in the range 30 thru 39 inclusive
                    are reserved for oem use!

=======================================================================
  SAH 09/16/92	Corrections for SmartPort Plus
======================================================================^

	.286				; requires memman, so use 286 
					; instructions
;	queue descriptor offsets:

q_start		equ	0000h		;start of queue area
q_size		equ	0002h		;physical size of queue area
q_head		equ	0004h		;head pointer
q_tail		equ	0006h		;tail pointer

imq_start	equ 	0000h		;offset to input message q descr.
omq_start	equ 	0008h		;offset to output message q descr.
icq_start	equ 	0010h		;offset of input char q descr.
ocq_start	equ	0018h		;offset to inp. char q descr.

SRC_OFFSET	equ	100h		;fun 18 source offset	
DST_OFFSET	equ	104h		;fun 18 desr offset
STR_LEN		equ	108h		;fun 18 string lenght    
EXEC_OFFSET	equ	10ah		;fun 19 exec offset
DUAL_SIZE	equ	112h		;dual port memory size

SRC_OFFSET_NEW	equ	29eh		;fun 18 source offset    (NEW)	
DST_OFFSET_NEW	equ	2a2h		;fun 18 desr offset	 (NEW)
STR_LEN_NEW	equ	2a6h		;fun 18 string lenght    (NEW)
EXEC_OFFSET_NEW	equ	2a8h		;fun 19 exec offset	 (NEW)
DUAL_SIZE_NEW	equ	2b0h		;dual port memory size	 (NEW)

SP_EQUIP	equ	03fdh		
UP_MASK_HI	equ	027Ah
UP_MASK_LOW	equ	0278h
START_COPYR	equ	03adh

;
; The following XONXOFF equate must be non-zero, if Input XON/XOFF
; software stripping is not include 65h's and 67h's will appear in
; input buffer.  I could not find a way for hardware to strip these 
; bytes off.
;
XONXOFF	equ	01

	if	0 eq 0			; hide from public.com
	include options.inc
	endif

	include _arnet.pub


	page

scbs		segment	at	0beach
		assume  cs:scbs
		include mosscbdf.inc
scbs		ends

fastmov	macro	
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep 	movsb
	endm


	page
code	segment para public 'code'
	assume	cs:code, ds:nothing, es:nothing, ss:nothing

begin	equ	this byte
	dd	-1			; for link to next driver
	dw	8000h			; character device
	dw	strat			; device strategy entry point
	dw	inter			; device interrupt entry point
	db	'$$SC    '		; device driver name

numport dw	2			; default number of ports
tocount dw	182			; default timeout (10 seconds)

baseadr	dw	0ee00h			; Base Address for ArNet Memory
					; mapping
base2adr dw	0ef00h			; Base Address for ArNet Memory
					; mapping #2

NoOfBoards dw	0			; # of Boards on system
board	  dw	4 dup (0)		; Port for Communications area
boardType db	4 dup (0)		; Type of board installed
BoardSys  db	4 dup (0)		; Equipment ID 
					; 0 = standard AT Smartport  
					; 1 = Smartport Lite
					; 2 = Smartport/2a				
					; 3 = Smartport Plus
					; 4 = Smartport Plus (MC)
boardpage dw	4 dup (0)		; start page for board

page0	dw	-1			; memman handle for page 0
page1	dw	-1			; memman handle for page 1
snd_msg_busy	dw	0		; nonzero when snd_msg is busy

scbadr	label	dword			; scb address
scboff	dw	0
scbseg	dw	0
memman	dd	0			; memory manager

isize	equ	32
osize	equ	4096

maxport	equ	32		; max of 32 async serial ports

ports	struc
;
; The following Structures are structure definitions for Arnet
;

addr	dw	0			; addresss (High bit means not enable)
kbeflg	db	0			; keyboard empty flag
ioprot	db	0	    		; i/o protocols enabled
					; 80h - waiting for timer wrap
					; 40h - not used
					; 20h - report carrier loss
					; 10h - monitor carrier
					; 08h - rts/cts enabled
					; 04h - dtr/dsr enabled
					; 02h - xmit xon/xoff
					; 01h - rcv xon/xo; novell
iopend	db	0			; protocol state bits
					; 80h - carrier drop reported
					; 40h - carrier drop has occured
					; 20h - xon to be sent
					; 10h - xoff to be sent
					; 08h - rts off
					; 04h - dtr off
					; 02h - xoff rcvd
					; 01h - xoff sent
xoffch		db	0   		; xoff character
xonch		db	0   		; xon character
line_control	db	0		; line control register
Baud_Rate	dd	0		; baud rate

output_desc 	dw	0		; OutPut Descriptor
input_desc	dw	0		; Input Descriptor
msr_psr_reg	dw	0		; offset to msr/psr registers
ibfsiz		dw	isize		; input buffer size (bytes)
obfsiz		dw	osize		; output buffer size (bytes)
BoardNo		dw	0		; board number

reserved	db	8 dup (0)
ports	ends

; default ports to com1, then com2, then alternate com port address map
; must start at 18h in the code segment

portoff	dw	offset porttbl	; pointer to the port table

orig1a	dd	0			; int 1a vector at initialization
orig38	dd	0			; int38 vector at initialization
orig08	dd	0			; INT 8 Vector at Initialization
child	dd	0			; point to next int14 driver

request dd	0			; location of device request


sername db	'$ARNET.SYS V1.01 (920916)               '


SetReg	db	5,4,1,0			; set modem registers for fun 17h
ClearReg db	0,1,4,5			; clear modem regs for fun 17h


brate	dw	110			; 0 -  110 bps
	dw	150			; 1 -  150
	dw	300			; 2 -  300
	dw	600			; 3 -  600
	dw	1200			; 4 - 1200
	dw	2400			; 5 - 2400
	dw	4800			; 6 - 4800
	dw	9600			; 7 - 9600



;	table of csr to baud rate conversion:

baud_rates	label	word
	dw	50			;50 baud (acr[7]=0)
	dw	110			;110 baud
	dw	134
	dw	200
	dw	300
	dw	600
	dw	1200
	dw	1050
	dw	2400
	dw	4800
	dw	7200
	dw	9600
	dw	38400
	dw	75			;75 baud (acr[7]=1)
	dw	110			;110 baud
	dw	134
	dw	150
	dw	300
	dw	600
	dw	1200
	dw	2000
	dw	2400
	dw	4800
	dw	1800
	dw	9600
	dw	19200

baud_divisors	label	word
	dw	0900h	;50
	dw	0417h	;110
	dw	035bh	;134
	dw	0240h	;200
	dw	0180h	;300
	dw	00c0h	;600
	dw	0060h	;1200
	dw	006dh	;1050
	dw	0030h	;2400
	dw	0018h	;4800
	dw	0010h	;7200
	dw	000ch	;9600
	dw	0003h	;38400
	dw	0600h	;75
	dw	0417h	;110
	dw	035bh	;134
	dw	0300h	;150
	dw	0180h	;300
	dw	00c0h	;600
	dw	0060h	;1200
	dw	0039h	;2000
	dw	0030h	;2400
	dw	0018h	;4800
	dw	0040h	;1800
	dw	000ch	;9600
	dw	0006h	;19200


par_wlen	label	byte

	db	00010000b		;xxx00x00 no parity, 5 bits
	db	00010001b		;xxx00x01 no parity, 6 bits
	db	00010010b		;xxx00x10 no parity, 7 bits
	db	00010011b		;xxx00x11 no parity, 8 bits
	db	00000100b		;xxx01x00 odd parity, 5 bits
	db	00000101b		;xxx01x01 odd parity, 6 bits
	db	00000110b		;xxx01x10 odd parity, 7 bits
	db	00000111b		;xxx01x11 odd parity, 8 bits
	db	00010000b		;xxx10x00 no parity, 5 bits
	db	00010001b		;xxx10x01 no parity, 6 bits
	db	00010010b		;xxx10x10 no parity, 7 bits
	db	00010011b		;xxx10x11 no parity, 8 bits
	db	00000000b		;xxx11x00 even parity, 5 bits
	db	00000001b		;xxx11x01 even parity, 6 bits
	db	00000010b		;xxx11x10 even parity, 7 bits
	db	00000011b		;xxx11x11 even parity, 8 bits

stop_bit	label	byte
	db	00000111b		;1 stop bit
	db	00001111b		;2 stop bits



	subttl	async port register definitions
	page

; miscellaneous symbols and equates

tab	equ	008h			; tab
lf	equ	00ah			; line feed
cr	equ	00dh			; carriage return
space	equ	' '			; space
comma	equ	','			; comma


	include	jmpmacro.inc

; user register location on the stack

if	0 eq 0				; hide from public.com
msg_pkt equ	byte ptr [bp]
msg_fn	equ	byte ptr [bp]
msg_port equ	byte ptr [bp+1]
msg_arg1 equ	byte ptr [bp+2]
msg_arg2 equ	byte ptr [bp+3]
scax	equ	word ptr [bp+4]
scbx	equ	word ptr [bp+6]
sccx	equ	word ptr [bp+8]
scdx	equ	word ptr [bp+10]
scsi	equ	word ptr [bp+12]
scdi	equ	word ptr [bp+14]
scbp	equ	word ptr [bp+16]
scds	equ	word ptr [bp+18]
sces	equ	word ptr [bp+20]
scip	equ	word ptr [bp+22]
sccs	equ	word ptr [bp+24]
scfl	equ	word ptr [bp+26]
endif


	subttl  device driver entry points
	page

strat	proc	far			; device strategy entry point
	mov	word ptr [request], bx	; save the request header offset
	mov	word ptr [request+2], es; and the request header segment
	ret				; return to caller
strat	endp


inter	proc	far			; device interupt entry point
	push	es			; save application es
	push	bx			; and bx
	les	bx,[request]		; point es:bx to the request hea
	cmp	byte ptr es:[bx+2], 0	; is this an init request
	jne	inter1			; exit with finished status if no
	push	ds			; save the caller's environment
	push	bp
	push	di
	push	si
	push	dx			 
	push	cx
	push	ax
	lds	si, es:[bx+18]		; point ds:si to command line
	call	init			; initialize the port table
	les	bx, [request]		; point es:bx to the request hea
	mov	es:[bx+14], dx		; tell him were the end of the
	mov	es:[bx+16], ds		;   end of the driver is
	pop	ax			; restore his environment
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
	cmp	word ptr es:[bx+3],0200h; if error already set
	je	inter3			; then leave it
inter1:
	mov	word ptr es:[bx+3], 00100h  ; store status (done no err)
inter3:
	pop	bx			; restore bx
	pop	es			; and es
	ret				; return to the caller
inter	endp

;
;	MapMem =  call Memory manager to physical map in Page AX
;		  into Page0 location or page 0
;
;	AX = Page to map in
;	DX = 0 means Page0, NonZero means Page1
;		 
MapMem	proc	near
	or	dx,dx
	jnz	MapMem1
;
;	handle fast case for Page0
;
	cmp	ax,[Page0]
	je	MapMemExit
	mov	[Page0],ax
	jmp	short MapMem2
;
;	handle fast case for Page1
;
MapMem1:
	cmp	ax,[Page1]
	je	MapMemExit
	mov	[Page1],ax
MapMem2:
	push	bx
	push	cx
	push	es

	mov	bx,ax
	mov	cx,1
	mov	ax,[BaseAdr]		; get base address
	or	dx,dx
	jz	MapMem3
	mov	ax,[Base2adr]		; point to Page1
MapMem3:
	mov	es,ax
	mov	ah,5
	call	[memman]	
				 
	pop	es
	pop	cx
	pop	bx
MapMemExit:
	ret
MapMem	endp


	subttl snd_msg, sng message to 80186
;======================================================================
;
; .func:
;
; input:
;			    
; output:
;
; comments:
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
	       
snd_msg	proc	near
;	this process sends the message which is pointed to by
;	msg_pkt[bp].
;	es is assumed to contain the address of dual-ported ram.

;	since there is only one message queue (to be shared by
;	multiple tasks), access to this subroutine must be
;	serialized.  that is, it must not be allowed for one
;	task to interrupt this subroutine and then call the
;	subroutine.  the following logic prevents this:

wait_for_not_busy:
	cli				;don't allow a task swap
	cmp	snd_msg_busy,0		;is another task using this routine?
	jz	snd_msg_not_busy	;no, branch
	sti				;yes, give the cpu back to other task
	call	moswait
	jmp	short wait_for_not_busy	;now, go see if its finished
snd_msg_not_busy:
	inc	snd_msg_busy		;set the busy flag
	sti				;allow other tasks to run

	pusha
	push	ds

;	first of all, flush any messages in the input message queue:

	mov	bx,imq_start		;q descriptor for input message queue
	mov	ax,es:q_tail[bx]	;get tail pointer
	mov	es:q_head[bx],ax	;advance head ptr to flush q

	cld				;copy in forward direction
	mov	bx,omq_start		;point to output message q descriptor
	lea	si,msg_pkt		;point to message packet
	push	ss
	pop	ds
	mov	di,es:q_tail[bx]	;fill chars in starting at tail
	mov	dx,es:q_size[bx]	;size of queue area

;	wait for 4 bytes to become available:

wait_for_room:
	mov	ax,es:q_head[bx]	;calc head ptr
	sub	ax,di			; minus tail pointer
	jnbe	mod_q_size		; modulo q_size
	add	ax,dx			;add in q_size for mod function
	sub	dx,di			;# bytes before wrap-around
mod_q_size:
	dec	ax			;# of free bytes in the queue
	cmp	ax,4			;do we have room for a packet?
	jnc	ok_for_packet		;yes, branch
	call	moswait			;no, wait a timer tick
	mov	dx,es:q_size[bx]	;size of queue area
	jmp	short wait_for_room		;go try again
ok_for_packet:

;	output the packet:

	mov	cx,4			;4 bytes to move
	add	di,es:q_start[bx]	;add base addr
	cmp	dx,cx			;will we need to wrap around?
	jnbe	one_str_copy		;no, branch
	sub	cx,dx			;# bytes to put at the
	mov	ax,cx			; front of the queue area
	mov	cx,dx			;# bytes to put at end
	rep	movs	es:byte ptr [di],ds:[si]  ;bytes at end of q
	mov	di,es:q_start[bx]	;wrap around to beginning
	mov	cx,ax			;number of bytes left to copy
one_str_copy:
	rep	movs	es:byte ptr [di],ds:[si]	;move the data
	sub	di,es:q_start[bx]	;tail pointer
	cmp	di,es:q_size[bx]	;wrap around?
	jc	dont_wrap		;no,branch
	xor	di,di			;yes, do it
dont_wrap:
	mov	es:q_tail[bx],di	;give new tail pointer to box
got_confirmation:
	pop	ds
	dec	snd_msg_busy		;no longer busy
	popa
	ret
snd_msg	endp


int8	proc	near
	pushf
	call	dword ptr cs:[orig08]
	push	ax
	push	cx
	push	si
	push	di
	push	ds
	push	es
	
	mov	ax,cs
	mov	ds,ax
	assume	cs:code,ds:code
	mov	cx,[numport]
	mov	si,[portoff]
	mov	es,[baseadr]
	
int8lp:
	test	[si].addr,8000h		; is port active
	jnz	int8next
	cmp	[si].kbeflg,0		; is it already set???
	jne	int8next		; yes...skip check
	mov	di,input_desc[si]
	mov	ax,es:q_head[di]
	cmp	ax,es:q_tail[di]
	je	int8next
	mov	[si].kbeflg,0ffh

int8next:
	add	si,type ports
	loop	int8lp

	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	ax
	iret
int8	endp


	subttl	int 14h bios replacement
	page

fntbl	dw	do0			; initialize the port
	dw	do1			; write a character
	dw	do2			; read a character
	dw	do3			; check status
	dw	do4			; extended port initialize
	dw	do5			; set line protocal
	dw	do6			; identify driver function level
	dw	do7			; break modem connection
	dw	do8			; non-destructive read character
	dw	do9			; flush input and output buffers
	dw	do10			; report waiting input characters
	dw	do11			; relinquish the port for another
	dw	do12			; get current setup parameters
	dw	do13	 		; register terminal use of port
	dw	do14			; output a string
	dw	do15			; read a string of characters
	dw	do16			; link to another int14 handler
	dw	do17			; manipulate dtr/rts
	dw	do18			; return driver identification
	dw	do19			; selective buffer flush
	dw	do20			; report waiting output chars
	dw	do21			; write a character
	dw	do22			; read a character
	dw	do23			; declare ownership
        dw      do24                    ; return port status info
fnlen	equ	$-fntbl


;======================================================================
;
; .func: int14 - bios replacement
;
; input:
;
; output:
;
; comments:
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
int14	proc	near
	sti				; hardware interupts ok now
	cld				; set desired direction
	push	es			; save
	push	ds			;  the
	push	bp			;   user's
	push	di			;    context
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	push	ax			; reserving message packet area 
	push	ax			; on users stack
	mov	bp,sp			; set bp to index the user's regs
	mov	bx,cs			; code segment to bx
	mov	ds,bx			; set ds to code segment
	mov	es,bx			; and es also
	assume	cs:code,ds:code,es:code,ss:nothing
	and	dx,07fffh		; mask off the function 11 selection
	and	ah,07fh			; get rid of hi bit
	cmp	ah,16			; is it a register child
	lje	okport			; just go do it if yes
	mov	bx,word ptr [child]	; get next driver offset
	or	bx,word ptr [child+2]	; or his segment to bx
	jz	nochild			; jump if we are the only driver
	cmp	dx,[numport]		; is this for one of our ports
	jb	nochild			; jump if for ours
	pop	ax			; \ this is only to remove stack
	pop	ax			; / space use for message area
	pop	ax			; restore
	pop	bx			;  the
	pop	cx			;   user's
	pop	dx			;    registers
	sub	dx,[numport]		; port number relative to driver
	pop	si			; finish
	pop	di			;  the
	pop	bp			;   context
	pop	ds			;    restore
	pop	es
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
	cmp	ah,12
	jne	int14adj
	pushf
	call	[child]			; pass the call on to the next driver
	retf	2	
int14adj:
	pushf
	call	[child]			; pass the call on to the next driver
	pushf				; save the new flags
	add	dx,[numport]		; restore dx to its original value
	popf				; get the return flags
	retf	2			; retf back to the int 14 caller
	assume	cs:code,ds:code,es:code,ss:nothing
nochild:
	cmp	dx,[numport]		; has he asked for a valid port
	jnb	badfn			; error if invalid port
	mov	[msg_port],dl
	mov	[msg_arg1],0ffh
	mov	[msg_arg2],0ffh
	shl	dx,5			; dx = port * 32 = index to table
	mov	bx,[portoff]		; point bx to start of port table
	add	bx,dx			; set bx to the port entry
	mov	dx,[bx].addr		; get the port address in dx
	test	dx,8000h		; is the port active?
	jz	okport
	cmp	ah,6			; is is driver identification?
	je	okport
	cmp	ah,18			; is it driver identification?
	je	okport
	or	ah,ah			; is this a port initialize?
	jz	okport
	cmp	ah,4			; is is an extended port init?
	je	okport
	cmp	ah,11			; is it disable use of port?
	je	okport
	cmp	ah,12			; is it a get port parameters?
	je	okport
	cmp	ah,13			; is it a register terminal use?
	je	okport
	cmp	ah,23			; is it a declare ownership call?
	jne	badfn
okport:
	and	dx,07fffh		; valid port address
	mov	cx,ax			; move function/data to cx
	mov	al,ah			; function to al
	xor	ah,ah			; convert the function to a word
	mov	si,ax			; function number to si
	shl	si,1			; convert function to an index
	cmp	si,fnlen		; is it a valid function request
	jae	badfn			; jump if invalid
	call	fntbl[si]		; go do as requested
	jmp	short okfn		; jump to the exit routine
badfn:
	mov	byte ptr [scax+1],0ffh	; set all flags in ah
okfn:
	pop	ax			; \ this is only to remove stack
	pop	ax			; / space use for message area
	pop	ax			; restore
	pop	bx			;  the
	pop	cx			;   user's
	pop	dx			;    context
	pop	si
	pop	di
	pop	bp
	pop	ds
	pop	es
	iret				; return to the requestor
int14	endp

	subttl	do0 - int 14h function 00h - initialize the port
	page
;======================================================================
;
; .func: do0 - int 14h function 00h - initialize the port
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 00h
; 	al = bits 7-5 baud rate (see pc doc)
; 	     bits 4-0 line control (see pc doc)
;
; do0 entry:
; 	dx = port address
; 	bx -> port record
; 	cl = int 14h entry al
;
; returns
; 	ax = status (see pc doc)
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing

do0	proc	near
	push	bx
	push	cx
	push	si
	mov	al,cl
	xor	ah,ah
	mov	si,ax
	shr	si,4
	mov	si,brate[si]
	xchg	bx,si		
	xor	cx,cx
	mov	ax,[scax]	
	mov	dx,[scdx]
	call	setbaud			; use set extended mode
	pop	bx
	pop	cx
	pop	si
	call	do3			; get status
	ret				; return to caller
do0	endp

	subttl	do1 - int 14h function 01h - write a char
	page
;======================================================================
;
; .func: do1 - int 14h function 01h - write a char
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 01h
; 	al = char to write
;
; do1 entry:
; 	dx = port address
; 	bx -> port record
; 	cl = int 14h entry al
;
; returns
; 	ah = status (see pc doc)
; 	al = char to write
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code, ds:code,es:nothing,ss:nothing
do1	proc	near
	xor	si,si			;set function 1 to use default t/o
	jmp	do21a			; and use func 21
do1	endp

	subttl	do2 - int 14h function 02h - read a char
	page
;======================================================================
;
; .func: do2 - int 14h function 02h - read a char
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 02h
;
; do2 entry:
; 	dx = port address
; 	bx -> port record
;
; returns
; 	ah = status (see pc doc)
; 	al = char read
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do2	proc	near
	xor	si,si			;set function 2 to use default t/o
	jmp	do22a			; and use func 22
do2	endp

	subttl	do3 - int 14h function 03h - check status
	page
;======================================================================
;
; .func: do3 - int 14h function 03h - check status
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 03h
;
; do3 entry:
; 	dx = port address
; 	bx -> port record
;
; returns
; 	ax = status (see pc doc)
;
; ,calls:
; ,reads:
; ,writes:
;	    
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do3	proc	near
	push	cx
	push	es
	mov	si,bx
	mov	es,[baseadr]

comment	|
	mov	bx,msr_psr_reg[si]	;point to msr/psr reg
	xor	ah,ah			;place to put port status
	xchg	ah,es:1[bx]		;read and reset port status
	cli				;execute next 2 ins. together
	mov	al,es:[bx]		;read modem status
	and	byte ptr es:[bx],0f0h	;clear the delta-bits
	sti
	mov	bl,es:-2[bx]		;get keyboard ready flag
	and	bl,00000001b		;isolate data ready bit

	or	ah,bl			;insert the data ready bit

	|

	xor	ax,ax
	mov	bx,input_desc[si]
	mov	cx,es:q_tail[bx]
	cmp	cx,es:q_head[bx]
	je	do3a
	inc	ah
do3a:

;	transmitter shift empty & transmitter holding empty bits:

	cli				;don't get interrupted
	mov	bx,output_desc[si]	;point to output q descr.
	mov	cx,es:q_tail[bx]	;get tail pointer
	cmp	es:q_head[bx],cx	;is the queue empty?
	jnz	q_not_empty2		;no, branch
	or	ah,01100000b		;yes, both holding & shift are empty
	jmp	short got_stat2		;exit
q_not_empty2:
	inc	cx			;advance tail pointer
	cmp	cx,es:q_size[bx]	;do we need to wrap?
	jc	no_roll4		;no, branch
	xor	cx,cx			;wrap around
no_roll4:
	cmp	cx,es:q_head[bx]	;is the q full?
	jz	hold_reg_full3		;yes, branch
	or	ah,00100000b		;no, holding reg. is empty
hold_reg_full3:
got_stat2:
	sti
	mov	word ptr [scax],ax
	pop	es
	pop	cx
	ret				; return to caller
do3	endp

	subttl	do4 - int 14h function 04h - extended port init
	page
;======================================================================
;
; .func: do4 - int 14h function 04h - extended port init
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	cx:bx = actual baud rate
; 	ah = 04h
; 	al = word size,stop bits, parity
;
; do4 entry:
; 	dx = port address
; 	bx -> port record
; 	cl = int 14h entry al
;
; returns
; 	ah = 0 if no error
; 	   = 0ffh if invalid baud rate
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do4	proc	near
	push	si
	mov	si,bx
	mov	cx,[sccx]
	mov	bx,[scbx]
	mov	ax,[scax]
	mov	dx,[scdx]
	call	setbaud
	mov	ah,0			; indicate ok
	jnc	do4a			
	mov	ah,-1			; indicate error
do4a:
	pop	si
	mov	[scax],ax
	ret
do4	endp

	subttl	do5 - int 14h function 05h - set protocol
	page
;======================================================================
;
; .func: do5 - int 14h function 05h - set comm protocol
;
; int	14 entry:
; 	ah = 05h
; 	al = protocol
; 	     xxxx0000 - no protocol
; 	     xxxxxxx1 - enable/disable rcv xon/xoff  \	bh = xof
; 	     xxxxxx1x - enable/disable xmit xon/xoff /	bl = xon
; 	     xxxxx1xx - enable/disable dtr/dsr
; 	     xxxx1xxx - enable/disable rts/cts
; 	     1xxxxxxx - allow modification of carrier detect mon
; 	     1xx1xxxx - enable/disable carrier detect monitoring
; 	     1x1kxxxxx - enable/disable terminate on carrier drop
;
; at do5 entry:
; 	cl = al at int 14h entry
; 	dx = port address
; 	bx -> port record
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do5	proc	near
	push	es
	mov	es,[baseadr]		; get base address
	push	cx			; save the protocal flags
do5a:
	pop	cx			; restore cx
	test	cl,080h			; does he want to change carrier
	jz	do5b			; jump if not changing carrier
	mov	ch,cl			; copy config to ch
	and	ch,030h			; save only the carrier data
	test	ch,20h
	jz	do5aa			; if the terminate bit is set,
	or	ch,10h			; insure than the cd bit is too
do5aa:
	mov	[bx].ioprot,ch		; store the new values
do5b:
	and	cl,00fh			; throw away carrier data
	and	[bx].ioprot,0f0h	; clear handshake config
	or	[bx].ioprot,cl		; set the new handshake
	or	cl,cl
	jnz	do5c
	mov	[msg_fn],15		; change xon_off parameters
	mov	[msg_arg1],0		; disable xon_off
	call	snd_msg
	jmp	exit5
do5c:
	mov	[msg_fn],15
	mov	ch,cl
	and	ch,1
	shl	ch,1
	shr	cl,1
	and	cl,1
	or	cl,ch
	or	cl,80h			; enable slow processing
	mov	[msg_arg1],cl
	call	snd_msg			
	mov	cx,[scbx]		; get the xon/xoff characters
	mov	[bx].xonch,cl		; store the xon character
	mov	[bx].xoffch,ch		; store the xoff character
	or	cl,cl
	jz	do5d
	or	[msg_arg1],100b
	mov	[msg_arg2],cl
	call	snd_msg
	and	[msg_arg1],11111011b
do5d:
	or	ch,ch
	jz	do5e
	or	[msg_arg1],1000b
	mov	[msg_arg2],ch	
	call	snd_msg
do5e:
	mov	[msg_arg2],0ffh
	xor	cl,cl
	mov	ch,[bx].ioprot
	test	ch,8
	jz	do5f
	or	cl,1
do5f:
	test	ch,4
	jz	do5g
	or	cl,4
do5g:
	mov	[msg_fn],5
	mov	[msg_arg1],cl
	call	snd_msg
	mov	[msg_fn],6
	xor	[msg_arg1],5
	call	snd_msg	
	mov	[msg_fn],40
	mov	[msg_arg1],01h		; strip XON/XOFF characters
	call	snd_msg			
	mov	[msg_fn],3		;change command register
	mov	[msg_arg1],005h		;enable tx/rx
	call	snd_msg			;enable both tx and rx
exit5:
	pop	es
	ret
do5	endp

	subttl	do6 - int 14h function 06h - report functions available
	page
;======================================================================
;
; .func: do6 - int 14h function 06h - report functions available
;
; int	14 entry:
; 	dx = port number
; 	ah = 06h
;
; do6 entry:
; 	dx = port address
; 	bx -> port record
;
; returns
; 	ah = high bit set
; 	al = highest function the driver supports
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do6	proc	near
	mov	ax,fnlen		; length of the function table
	shr	ax,1			; convert to a function count
	dec	ax			; minus 1 for last function numb
	or	ah,080h			; add the high bit of ah
	mov	[scax],ax		; store the status for the user
	ret
do6	endp

 	subttl	do7 - int 14h function 07h - break modem connection
	page
;======================================================================
;
; .func: do7 - int 14h function 07h - break modem connection
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	bx = number of ticks to hold break
; 	ah = 07h
;
; do7 entry:
; 	dx = port address
; 	bx -> port record
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do7	proc	near

	push	es
	mov	es,[baseadr]
	mov	msg_fn,6	;clear output port reg
	mov	msg_arg1,100b		;clear dtr
	call	snd_msg
	mov	msg_fn,5		;set output port reg
	mov	msg_arg1,100b		;set dtr
	call	snd_msg

	mov	msg_fn,3		;start break
	mov	msg_arg1,01100000b
	call	snd_msg

	mov	si,[scbx]		; get the delay count
	inc	si			; make sure its not zero
	call	settime			; set the timers for a wait

keep_break_on:
	call	chktime			;is it time to turn off break?
	jc	break_off		;yes, branch
	call	moswait			;wait a while
	jmp	short keep_break_on	;go try again
break_off:
	mov	msg_arg1,01110000b	;turn break off
	call	snd_msg
	pop	es
	ret
do7	endp

	subttl	do8 - int 14h function 08h - non-destructive read
	page
;======================================================================
;
; .func: do8 - int 14h function 08h - non-desctructive read
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 08h
;
; do8 entry:
; 	dx = port address
; 	bx -> port record
;
; return:
; 	zf = 1 if no chars in buffer
; 	cf = 1 if terminal has disconnected (carrier lost)
; 	else zf = 0 and cf = 0	and al = next char in buffer
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do8	proc	near
	mov	[bx].kbeflg,0		; reset the keyboard empty flag
	or	[scfl],040h		; set no data ready flag
	and	[scfl],not 001h		; reset the disconnected flag
	test	[bx].ioprot,020h	; are we terminating lost tasks
	jz	do8a			; skip if no
	test	[bx].iopend,040h	; have we lost carrier
	jz	do8a			; jump if no
	or	[scfl],001h		; set carry (terminal gone)
	and	[bx].iopend,not 040h	; reset carrier lost flag
	ret				; return to caller
do8a:
	push	es
do8b:
	push	bx
	mov	es,[baseadr]
	mov	bx,input_desc[bx]
	mov	di,es:q_head[bx]	;get head ptr
	cmp	di,es:q_tail[bx]	;are there any characters?
	jz	do8f			;no, br
	add	di,es:q_start[bx]	;point to char
	cmp	di,4096
	jb	do8c	
	mov	ax,di
	shr	ax,12
	add	ax,[BoardPage]
	mov	dx,-1
	call	mapmem
	mov	es,[base2adr]
	and	di,4095
do8c:
	mov	al,es:[di]		;get the character
	pop	bx
	
if	XONXOFF
;
;	if XON/XOFF handshaking is use, we must check xon/xoff characters
;	out of the buffer
;
	test	[bx].ioprot,2
	jz	do8e
     	cmp	al,[bx].xonch
	je	do8d
	cmp	al,[bx].xoffch
	jne	do8e
do8d:
	mov	es,[baseadr]
	mov	di,input_desc[bx]
	mov	ax,es:q_head[di]
	inc	ax
	cmp	ax,es:q_size[di]
	jb	do8da
	xor	ax,ax
do8da:
	mov	es:q_head[di],ax	
	jmp	short  do8b	
endif

do8e:
	mov	[bx].kbeflg,0ffh	; set the keyboard empty flag
	push	bx
	and	[scfl],not 40h		; show he's getting something
	mov	byte ptr [scax],al	; store the character for the usr
do8f:
	pop	bx
	pop	es
	ret				; return to caller
do8	endp

	subttl	do9 - int 14h function 09h - initialize buffers
	page
;======================================================================
;
; .func: do9 - int 14h function 09h - initialize buffers
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 09h
;
; do9 entry:
; 	dx = port address
; 	bx -> port record
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do9	proc	near
	push	es
	mov	es,[baseadr]
	mov	[msg_fn],14		;flush output char q function
	call	snd_msg			;send to smartport
	mov	[bx].kbeflg,0		; reset the keyboard empty flag
	mov	bx,input_desc[bx]	;point to inp. q des.
	mov	ax,es:q_tail[bx]	;get tail pointer
	mov	es:q_head[bx],ax	;advance head pointer
	pop	es
	ret
do9	endp

	subttl	do10 - int 14h function 0ah - report number in input buffer
	page
;======================================================================
;
; .func: do10 - int 14h function 0ah - report number in input buffer
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 0ah
;
; do10 entry:
; 	dx = port address
; 	bx -> port record
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do10	proc	near
	push	es
	mov	es,[baseadr]
	mov	bx,input_desc[bx]	;point to q descriptor
	mov	ax,es:q_tail[bx]	;get tail pointer
	sub	ax,es:q_head[bx]	;minus the head pointer
	jnc	mod_q_size2		;modulo the q size
	add	ax,es:q_size[bx]
mod_q_size2:
	mov	[scax],ax		; store the count
	pop	ax
	ret
do10	endp

	subttl	do11 - int 14h function 0bh - disable sc use of port
	page
;======================================================================
;
; .func: do11 - int 14h function 0bh - disable sc use of port
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	     dh high bit = 0 disables the port
; 	     dh high bit = 1 disable the port if a unique irq
; 	ah = 0bh
;
; do11 entry:
; 	dx = port address
; 	bx -> port record
;
; returns
; 	al = 0 if irq is unique and port was disabled
; 	al = 1 if irq not unique (port not disabled)
; 	al = 2 if irq already reserved
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do11	proc	near
	push	es
	mov	es,[baseadr]
	mov	msg_fn,3		;command reg
	mov	msg_arg1,1010b		;disable tx and rx
	call	snd_msg

	mov	msg_fn,6		;clear output port reg
	mov	msg_arg1,101b		;dtr/rts
	call	snd_msg			;drop dtr and rts
	or	[bx].addr,8000h		; disable port
	pop	es
	ret				; return to caller
do11	endp

	subttl	do12 - int 14h function 0ch - get serial parameters
	page
;======================================================================
;
; .func: do12 - int 14h function 0ch - get current serial parameters
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 0ch
;
; do12 entry:
; 	dx = port address
; 	bx -> port record
;
; return:
; 	al = line control register config
; 	ah = flow control config/connection information
; 	cx:bx = baud rate
; 	dl = xoff character (zero if not using xon/xoff)
; 	dh = xon character (zero if not using xon/xoff)
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do12	proc	near
	mov	cx,word ptr [bx+2].Baud_Rate
	mov	ax,word ptr [bx].Baud_Rate
	mov	[scbx],ax		; store the baud rate ls
	mov	[sccx],cx		; store the baud rate ms
	xor	ax,ax			; not using xon/xoff
	test	[bx].ioprot,003h	; are we using xon/xoff
	jz	do12b			; not xon/xoff characters if no
	mov	al,[bx].xoffch		; get the xoff character
	mov	ah,[bx].xonch		; and the xon character
	mov	[scdx],ax
do12b:
	mov	al,[bx].line_control
	and	al,01fh	 		; save the config info
	mov	ah,[bx].ioprot		; get flow control/connection in
	and	ah,03fh			; mask the other junk
	mov	[scax],ax		; return config info to the user
	ret				; return to caller
do12	endp

	subttl	do13 - int 14h function 0dh - register terminal use of port
	page
;======================================================================
;
; .func: do13 - int 14h function 0dh - register terminal use of port
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 0dh
;
; do13 entry:
; 	dx = port address
; 	bx -> port record
;
; return
; 	es:bx -> key ready flag (<> 0 when scan codes are buffe)
; 	ah = 0 if valid port
; 	   = ff if invalid port
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do13	proc	near
	mov	[sces],cs		; store the structure segment
	lea	ax,[bx].kbeflg		; point to the keyboard empty flag
	mov	[scbx],ax		; store the counter offset
	mov	byte ptr [scax+1],0	; show a successful register
	ret
do13	endp


	subttl	do14 - int 14h function 0eh - string output		    k
	page
;======================================================================
;
; .func: do14 - int 14h function 0eh - output string
;
; int	14 entry:
; 	ah = 14  (8eh)
; 	es:bx -> pointer to string
; 	cx = length of string
; 	dx = port number
; 	si = # of ticks for timeout
;
; do14 entry:
; 	bx = port number as a structure address
; 	sces:scbx -> pointer to string
; 	sccx = length of string
; 	scsi = # of ticks for timeout
; 	es,ds -> code segment
; 	cx = scax   (can ignore here)
; 	dx = port address
;
; do14 exit:
; 	scax = number of characters transferred
; 	scfl = zr if time out (else nz)
;
; int14 exit:
; 	ax = number of characters transferred
; 	zf = 1 if timeout (else zf = 0)
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do14	proc	near
	mov	di,[scbx]		; get destination offset
	mov	[scax],0		; show nothing sent
	and	[scfl],not 40h		; set zf=0 (all completed ok)
	cmp	[sccx],0		; is there anything to send
	jne	do14a			; press on if yes
	ret				; all done if nothing to send
do14a:
	push	di			
	mov	si,[scsi]		; get the timeout value
	or	si,si			; does he want to use the default
	jnz	do14b			; jump if timeout ok
	mov	si,tocount		; get the default
do14b:
	call	settime			; go set the timeout values
do14c:
;
;	check to see if buffer is full
;
	call	IsFull			; get # output full
	jne	do14e
	call	chktime			; go check for a timeout
	jnc	do14d			; jump if there is still time left
	pop	di
	or	[scfl],040h		; show we timed out
do14ca:
	ret				; return to caller
do14d:
	call	moswait			; lets wait a little while
	jmp	short do14c		; go check again
do14e:
	pop	di
;
; 	Place data into buffer
;
	mov	cx,[sccx]		; get count
	sub	cx,[scax]
	push	bx
	push	es
	mov	bx,output_desc[bx]
	mov	es,[baseadr]
	mov	si,di
	mov	[msg_fn],0		; turn off page0 flag
	mov	ax,es:q_tail[bx]
        add	ax,es:q_start[bx]
	cmp	ax,4096			  
	jb	buff1
	inc	[msg_fn]		; set flage for page1 usage
	shr	ax,12
	add	ax,[BoardPage]
	mov	dx,-1
	call	MapMem			; map page in if not already mapin
buff1:	
;
;	Make sure that transfer will not cross 4K limit
;
	mov	dx,es:q_tail[bx]
	add	dx,es:q_start[bx]
	and	dx,4095			
	mov	ax,4096
	sub	ax,dx
	cmp	cx,ax
	jbe	buff2	
	mov	cx,ax
buff2:
;
;	make sure head and tail are correct
;
	mov	ax,es:q_head[bx]
	sub	ax,es:q_tail[bx]		; is output buffer empty
	ja	buff3	
	mov	ax,es:q_size[bx]
	sub	ax,es:q_tail[bx]		; is output buffer empty
	inc	ax				; adjust for decrement below
buff3:
	dec	ax
buff3a:
	cmp	cx,ax
	jbe	buff4
	mov	cx,ax
buff4:

	push	cx
	push	es
	push	ds
	push	di
	mov	si,di
	mov	di,es:q_tail[bx]
	add	di,es:q_start[bx]
	and	di,4095
	cmp	[msg_fn],0
	je	buff5
	mov	es,[base2adr]
buff5:
;

	mov	ax,[sces]
	mov	ds,ax
	fastmov
	pop	di
	pop	ds
	pop	es
	pop	cx
;
; 	adjust tail pointer for bytes transfer
;
	mov	ax,es:q_tail[bx]
	add	ax,cx
	cmp	ax,es:q_size[bx]
	jb	buff6
	sub	ax,es:q_size[bx]
buff6:
	mov	es:q_tail[bx],ax
	sti
	
	pop	es
	pop	bx
	add	[scax],cx
	add	di,cx			; increment to next position
	mov	cx,[sccx]
	sub	cx,[scax]
	or	cx,cx			; are we done
	je	do14f			; try again if more to do
	jmp	do14a
do14f:
	ret
do14	endp

	subttl	do15 - int 14h function 0fh - string input
	page
;======================================================================
;
; .func: do15 - int 14h funcktion 0fh - string input
;
; int	14 entry:
; 	ah = 15  (8fh)
; 	es:bx -> pointer to user's buffer
; 	cx = maximum number of charactors to be read
; 	dx = port number
; 	si = # of ticks for timeout
;
; do15 entry:
; 	bx = port number as a structure address
; 	sces:scbx -> pointer to user's buffer
; 	sccx = maximum number of charactors to be read
; 	scsi = # of ticks for timeout
; 	es,ds -> code segment
; 	cx = scax   (can ignore here)
; 	dx = port address
;
; do15 exit:
; 	scax = number of characters transferred
; 	scfl = zr if time out (else nz)
;
; int14 exit:
; 	ax = number of characters transferred
; 	zr if time out (else nz)
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do15	proc	near
	and	[scfl],not 040h		; intialize the timeout flag
	push	es
	mov	es,[baseadr]
	mov	di,input_desc[bx]
	mov	ax,es:q_head[di]
	cmp	ax,es:q_tail[di]
	pop	es
	jne	do15d
	mov	si,[scsi]		; get the requested timeout
	or	si,si			; should we use the default
	jnz	do15a			; jump if not default
	mov	si,[tocount]		; get the default timeout
do15a:
	call	settime			; set the timeout counters
do15b:
	call	chktime			; have we run out of time
	jc	do15c			; jump if no time left
	call	moswait
;
;	anything in buffer
;
	push	es
	mov	es,[baseadr]
	mov	di,input_desc[bx]
	mov	ax,es:q_head[di]
	cmp	ax,es:q_tail[di]
	pop	es
	jne	do15d
	jmp	short do15b
do15c:
	mov	[bx].kbeflg,0		; reset the keyboard empty flag
	or	[scfl],040h		; show we timed out waiting
	mov	[scax],0		; show nothing read
	ret				; return to caller
do15d:
;
; 	read from buffer
;
	mov	cx,[sccx]		; get count
	push	bx
	push	es
;
;	use stack variables to store xon and xoff characters
;
if	XONXOFF
	mov	al,[bx].xonch		
	mov	[msg_arg1],al		
	mov	al,[bx].xoffch
	mov	[msg_arg2],al
endif
;
	mov	di,input_desc[bx]
	mov	es,[baseadr]
	mov	[msg_fn],0		; turn off page0 flag
	mov	ax,es:q_head[di]
        add	ax,es:q_start[di]
	cmp	ax,4096			  
	jb	do15e
	inc	[msg_fn]		; set flage for page1 usage
	shr	ax,12
	add	ax,[BoardPage]
	mov	dx,-1
	call	MapMem			; map page in if not already mapin
do15e:	
;
;	Make sure that transfer will not cross 4K limit
;
	mov	dx,es:q_tail[di]
	add	dx,es:q_start[di]
	and	dx,4095			
	mov	ax,4096
	sub	ax,dx
	cmp	cx,ax
	jbe	do15f	
	mov	cx,ax
do15f:
;
;	Make sure that we only transfer up to wrap around
;
	mov	ax,es:q_size[di]
	sub	ax,es:q_head[di]
	cmp	cx,ax
	jbe	do15g
	mov	cx,ax
do15g:
;
;	make sure head and tail are correct
;
	mov	ax,es:q_tail[di]
	cmp	ax,es:q_head[di]
	jbe	do15h
	sub	ax,es:q_head[di]
	cmp	cx,ax
	jb	do15h
	mov	cx,ax
do15h:
	push	cx
	push	ds
	push	es
	push	di
	mov	si,es:q_head[di]
	add	si,es:q_start[di]
	and	si,4095
	mov	di,[scbx]
	push	es
	pop	ds
	assume  ds:nothing
	cmp	[msg_fn],0
	je	do15i
	mov	ds,[base2adr]
do15i:
	mov	ax,[sces]
	mov	es,ax

if	XONXOFF
	test	[bx].ioprot,2
	jz	do15l	
	push	bx
	xor	bx,bx
do15j:
	lodsb
	cmp	al,[msg_arg1]
	je	do15k
	cmp	al,[msg_arg2]
	je	do15k
	inc	bx
	stosb
do15k:
	loop	do15j
	mov	ax,bx		; return count it ax
	pop	bx
	pop	di
	pop	es
	pop	ds
	pop	cx
	xchg	ax,cx
	jmp	short do15m	
endif

do15l:
	fastmov
	pop	di
	pop	es
	pop	ds
	pop	cx
	mov	ax,cx
do15m:
	assume 	ds:code
;
; 	adjust head pointer for bytes transfer
;
	add	ax,es:q_head[di]
	cmp	ax,es:q_size[di]
	jb	do15n
	sub	ax,es:q_size[di]
do15n:
	mov	es:q_head[di],ax
	mov	[scax],cx
	xor	cx,cx
	cmp	ax,es:q_tail[di]
	je	do15o
	dec	cl
do15o:
	pop	es
	pop	bx
	mov	[bx].kbeflg,cl		; set keyboard empty flag
	ret				; return to caller
do15	endp

	subttl	do16 - int 14h function 10h - link another serial driver
	page
;======================================================================
;
; .func:	do16 - int 14h funciton 10h - link another serial driver
;
; int	14 entry:
; 	ah = 10h
; 	es:bx cs:ip of child's int 14 entry point
;
; do16 entry:
; 	[sces]:[scbx] cs:ip of child's int 14 entry point
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do16	proc	near
	mov	es,[sces]		; get segment of the child
	mov	bx,[scbx]		; get offset of the child
	mov	ax,word ptr [child]	; get our child offset
	or	ax,word ptr [child+2]	; or in our child segment
	jnz	do16a			; jump if we already have a child
	mov	word ptr [child],bx	; else store the child offset
	mov	word ptr [child+2],es	; and the child segment
	ret				; and then return to the caller
do16a:
	mov	ax,[scax]		; make sure the function is here
	pushf				; store the flag like an int
	call	[child]			; tell our child to handle this one
	ret				; return to caller
do16	endp

	subttl	do17 - int 14h function 11h - manipulate dtr/rts
	page
;======================================================================
;
; .func: do17 - int 14h function 11h - manipulate dtr/rts
;
; int	14 entry:
; 	ah = 17 (91h)
; 	al = value for 8250 mcr (base+4)
; 	dx = port number
;
; do17 entry:
; 	[scax] = as above
; 	dx = port number
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	ds:code,es:nothing,ss:nothing
do17	proc	near
	push	es
	mov	es,[baseadr]
	mov	bx,[scax]
	and	bx,3h
	mov	al,ClearReg[bx]
	or	al,al
	jz	do17a			; if no change skip	
	mov	msg_fn,6		;clear output port reg
	mov	msg_arg1,al		;clear dtr
	call	snd_msg
do17a:
	mov	al,SetReg[bx]
	or	al,al
	jz	do17b
	mov	msg_fn,5		;set output port reg
	mov	msg_arg1,al		;set dtr
	call	snd_msg
do17b:
	pop	es
	ret				; return to caller
do17	endp


	subttl	do18 - int 14h function 12h - return driver description
	page
;======================================================================
;
; .func: do18 - int 14h function 12h - return driver description
;
; int	14 entry
; 	ah = 12h
; 	dx = port
;
; returns:
; 	ax = 0
; 	ds:bx -> 40 byte description of driver
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do18	proc	near
	mov	word ptr [scds],cs	; return message area in ds:bx
	mov	word ptr [scbx],offset sername  ; point to the message
	mov	word ptr [scax],0	; show a valid return
	ret				; return to caller
do18	endp

	subttl	do19 - int 14h function 13h - selective buffer flush
	page
;======================================================================
;
; .func: do19 - int 14h function 13h - selective buffer flush
;
; int	14 entry
; 	ah = 13h
; 	al = 1 to flush input buffer
; 	al = 2 to flush output buffer
; 	al = 3 to flush both
; 	dx = port
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do19	proc	near
	mov	ax,[scax]
	and	ax,3
	cmp	al,3
	jne	do19a
	call	do9
	ret
do19a:
	cmp	al,1
	je	do19b
	cmp	al,2
	je	do19c
	ret
do19b:
	cli				; no interuptions while reseting
	push	es
	mov	es,[baseadr]
	mov	si,input_desc[bx]	;point to inp. q des.
	mov	ax,es:q_tail[si]	;get tail pointer
	mov	es:q_head[si],ax	;advance head pointer
	pop	es
	jmp	short do19d
do19c:
	cli
	push	es
	mov	es,[baseadr]
	mov	[msg_fn],14		;flush output char q function
	call	snd_msg			;send to smartport
	pop	es
do19d:
	sti				; open the flood gates
	ret
do19	endp

	subttl	do20 - int 14h function 14h - report output buffer status
	page
;======================================================================
;
; .func: do20 - int 14h function 14h - report output buffer status
;
; int	14 entry
; 	ah = 14h
; 	dx = port
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do20	proc	near
	push	bx
	push	es
	mov	bx,output_desc[bx]
	mov	es,[baseadr]
	mov	ax,es:q_tail[bx]	;head pointer
	sub	ax,es:q_head[bx]	;minus the tail pointer
	jae	mod_fn			;modulo the q size
	add	ax,es:q_size[bx]	;do mod function
mod_fn:
	pop	es
	pop	bx
	mov	[scax],ax		; store the count
	ret
do20	endp

	subttl	do21 - int 14h function 15h - write a char
	page
;======================================================================
;
; .func: do21 - int 14h function 15h - write a char
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 15h
; 	al = char to write
; 	si = t/o value (0=default,else # of ticks)
;
; do1 entry:
; 	dx = port address
; 	bx -> port record
; 	cl = int 14h entry al
;
; returns
; 	ah = status (see pc doc)
; 	al = char to write
;
; note: function 1 enters this code at do21a with si set for default t/o
; this routine is "assuming" that si will not be destroyed between do21a
; and	do1f.
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do21	proc	near
	mov	si,[scsi]		; get the requested time out
do21a:					; entry point for func 1
	or	si,si			; does he want to use the default
	jnz	do21b			; jump if timeout ok
	mov	si,tocount		; get the default
do21b:
	call	settime			; go set the timeout values
do21c:
;
;	check to see if buffer is full
;
	call	IsFull			; is output full
	jnz	do21e
	call	chktime			; go check for a timeout
	jnc	do21d			; jump if there is still time left
	or	[scfl],040h		; show we timed out
	ret				; return to caller
do21d:
	call	moswait			; lets wait a little while
	jmp	short do21c		; go check again
do21e:
;
; 	Place data into buffer
;
	push	bx
	push	es
	mov	bx,output_desc[bx]
	mov	es,[baseadr]
	cli
	mov	di,es:q_tail[bx]
	add	di,es:q_start[bx]
	push	di
	cmp	di,4096			  
	jb	do21f
	mov	ax,di
	shr	ax,12
	add	ax,[BoardPage]
	mov	dx,-1
	call	MapMem			; map page in if not already mapin
	mov	es,[base2adr]
	and	di,4095
do21f:
	mov	byte ptr es:[di],cl	; store byte in buffer
	pop	di
	mov	es,[baseadr]
	sub	di,es:q_start[bx]
	inc	di
	cmp	di,es:q_size[bx]
	jb	do21h
	xor	di,di
do21h:
	mov	es:q_tail[bx],di
	sti
	pop	es
	pop	bx
	call	do3			; get status
	mov	byte ptr [scax],cl
	ret				; return to caller
do21	endp

	subttl	do22 - int 14h function 16h - read a char
	page
;======================================================================
;
; .func: do22 - int 14h function 16h - read a char
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 16h
; 	si = t/o value (0=default,else # of ticks)
;
; do2 entry:
; 	dx = port address
; 	bx -> port record
;
; returns
; 	ah = status (see pc doc)
; 	al = char read
;
; note: function 2 enters this code at do22a with si set for default t/o
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do22	proc	near
	mov	si,[scsi]		; get the requested timeout
do22a:					;entry point from function 2
	or	si,si			; does he want to use the default
	jnz	do22b			; jump if timeout ok
	mov	si,tocount		; get the default
do22b:
	call	settime			; go set the timeout values
do22c:
;
;	buffer empty?
;
	push	es
	mov	es,[baseadr]
	mov	di,input_desc[bx]
	mov	ax,es:q_head[di]
	cmp	ax,es:q_tail[di]
	pop	es
	jne	do22d
	call	moswait			; wait a while
	call	chktime			; check the time
	jnc	do22c			; wait some more if time
	mov	cx,[scax]
	push	cx			; save the original ax
	call	do3			; get the current status
	or	ah,080h			; add the timeout bit
	pop	bx			; retrieve the original characte
	mov	al,bl			; restore the character to al
	mov	[scax],ax		; return the status/original cha
	ret				; return to caller
do22d:
;
; 	get data from buffer
;
	push	bx
	push	es
	cli
	mov	bx,input_desc[bx]
	mov	es,[baseadr]
	mov	di,es:q_head[bx]
	add	di,es:q_start[bx]
	push	di
	cmp	di,4096			  
	jb	do22f
	mov	ax,di
	shr	ax,12
	add	ax,[BoardPage]
	mov	dx,-1
	call	MapMem			; map page in if not already mapin
	mov	es,[base2adr]
	and	di,4095
do22f:
	mov	al,byte ptr es:[di]	; get byte from buffer
	pop	di
	mov	es,[baseadr]
	sub	di,es:q_start[bx]
	inc	di
	cmp	di,es:q_size[bx]
	jb	do22h
	xor	di,di
do22h:
	mov	es:q_head[bx],di
	sti
	xor	ah,ah
	mov	di,es:q_head[bx]
	cmp	di,es:q_tail[bx]
	je	do22ha
	dec	ah
do22ha:	
	pop	es
	pop	bx
	mov	[bx].kbeflg,ah			; set keyboard empty flag
;     	
if	XONXOFF
	test	[bx].ioprot,2
	jz	do22i	
	cmp	al,[bx].xonch
	je	jdo22b
	cmp	al,[bx].xoffch
	jne	do22i
jdo22b:
	jmp	do22b
endif

do22i:	
	push	ax
	call	do3			; update the status
	pop	ax			; retrieve the character
	mov	byte ptr [scax],al	; store the original al
	ret				; return to caller
do22	endp

	subttl	do23 - int 14h function 17h - declare ownership
	page
;======================================================================
;
; .func: do23 - int 14h function 17h - declare ownership
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
; 	ah = 17h
; 	bx = tcb of owner task
;
; returns: none
;
; this function was implemented for the sake of stargate's cluster
; controller driver.  $serial.sys,vna.sys and vgna.sys have no use
; for it - but must implement this dummy to handle the call.  the
; ddt is who makes a call to this function.
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing
do23	proc	near
	ret
do23	endp


	subttl	do24 - int 14h function 18h - get port information
	page
;======================================================================
;
; .func: do24 - int 14h function 18h - get port information
;
; int	14 entry:
; 	dx = port index (0 - ports-1)
;       es:bx = address of port information record
;       cx = max number of bytes to return in port information record
; 	ah = 18h
;
; returns: cx = actual number of bytes returned
;          @[es:bx] = filled in port information record as follows:
;
;
;      WORD     "AD=" value.  If the port is currently disabled the
;               high bit (8000h) of this word will be set.  If this
;               value is not applicable a driver can return 7FFFh
;               for an enabled port and 0FFFFh for a disabled port.
;
;      WORD     "IB=" value.  Input buffer size in bytes.
;      WORD     "OB=" value.  Output buffer size in bytes.
;
;
;      BYTE     "IN=" value.  IRQ level.  The interrupt used by this port.
;               If this value is not applicable a driver can return
;               0FFh.
;
;      BYTE     k"CN=" value.  Connection type.  Valid values are:
;                      'L' - Local connection
;                      'R' - Remote connection
;                      'T' - Restart task on loss of connection
;                If this value is not applicable a driver can return
;                0FFh.
;
;       BYTE     "HS=" value.  Handshaking information.  Each bit in
;                this byte has a specified value as follows:
;                     80h - reserved
;                     40h - reserved
;
;                     20h - transmitter CTS flow control.  This port
;                         only transmit when the CTS line is active.
;
;                     10h - transmitter DSR flow control.  This port
;                         only transmit when the DSR line is active.
;
;                     08h - receiver RTS flow control.  This port will
;                         drop RTS when the input buffer is 3/4 full,
;                         and will raise RTS when the buffer is 1/4
;                         full.
;
;                     04h - receiver DTR flow control.  This port will
;                         drop DTR when the input buffer is 3/4 full,
;                         and will raise DTR when the buffer is 1/4
;                         full.
;
;                     02h - transmitter XON/XOFF.  This port will pay
;                         kattention to received XON/XOFF characters.
;
;                     01h - receiver XON/XOFF (or XPC) enabled.  This
;                         port will send Xoff when input buffer is 3/4
;                         full, and will send Xon when the buffer is
;                         1/4 full.
;
;                If this value is not applicable a driver can return
;                0FFh.  NOTE: With the current implementation of
;                $SERIAL.SYS certain pairs of bits are always the same
;                because you cannot seperately specify transmit and
;                receive hardware flow control.
;
;       BYTE     Transmit XON character.
;       BYTE     Receive XON character.
;       BYTE     Transmit XOFF character.
;       BYTE     Receive XOFF character.
;
;                NOTE: With the current implementation of $SERIAL.SYS
;                the receive and transmit Xon characters are always
;                equal, as are the receive and transmit Xoff characters.
;
;       BYTE     "IF=" value.  The input FIFO threshold for the port.
;                0 means the FIFO is disabled.
;
;       BYTE     "OF=" value.  The output FIFO transmit burst size.
;                0 means the FIFO is disabled.
;
;       BYTE     UART type code.   A code indicating the type of UART
;                detected for this port.  Values are:
;                   0 - No UART
;                   1 - 8250B
;                   2 - 8250A or 16450
;                   3 - 16550
;                   4 - 16550A  ( required to use FIFOs )
;                 255 - Not applicable (can be used by other drivers)
;                 Other values may be added in the future.
;
; .calls:
; .reads:
; .writes:
;
; .endfn
;================================================================
	assume	cs:code,ds:code,es:nothing,ss:nothing

do24 	proc	near
	push	es
	push	di
		
	mov	di,[scbx]
	mov	es,[sces]
	cld
	mov	ax,[bx].addr
	stosw
	mov	ax,[bx].ibfsiz
	stosw
	mov	ax,[bx].obfsiz
	stosw
	mov	al,0ffh
	stosb
        mov     ah,[bx].ioprot
        mov     al,'L'          ; assume local connect
        and     ah, 00110000b   ; extract correct bits
        jz      do24CN_Ok       ; it is local!
        mov     al,'R'          ; maybe it's remote?
        test    ah, 00100000b   ; did we guess right?
        jz      do24CN_Ok       ; yes
        mov     al,'T'          ; must be terminal mode
do24CN_Ok:
	stosb	
        mov     al,[bx].ioprot  ; get the protocol byte
        mov     ah, al          ; make a copy   (ax = xxxxRDXX xxxxRDXX)
        shl     ah, 1
        shl     ah, 1           ; ax = xxRDXXxx xxxxRDXX
        and     ax, 300Fh       ; ax = 00RD0000 0000RDXX
        or      al, ah          ; al = 00RDRDXX
	stosb
        mov    al,[bx].xonch
	stosb
	stosb
        mov    al,[bx].xoffch
	stosb
	stosb
	xor	ax,ax
	stosw
	mov	al,0ffh
	stosb

	pop	di
	pop	es
	ret
do24	endp

	subttl	$serial.sys subroutines
	page
IsFull  proc	near
	push	bx
	push	es
	mov	bx,output_desc[bx]
	mov	es,[baseadr]
	mov	ax,es:q_tail[bx]	;head pointer
	inc	ax
	cmp	ax,es:q_size[bx]
	jne	IsFull1
	xor	ax,ax	
IsFull1:
	cmp	ax,es:q_head[bx]
	pop	es
	pop	bx
	ret
IsFull  endp



;======================================================================
;
; .func: moswait - give up the cpu
;
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
moswait proc	near
	pushf
	push	ax			; save ax
	push	bx			; save bx
	mov	ah,007h			; mos wait
	mov	al,002h			; wait for timer ticks
	mov	bx,2			; wait for 2 timer ticks
	pushf				; simulate an int
	call	[orig38]		; call int 38
	pop	bx			; restore bx
	pop	ax			; restore ax
	popf
	ret				; return to caller
moswait endp

;======================================================================
;
; .func: settime
;
; get the current time and set si,di and ioprot 080h
; for subsequent time out checks
;
; input	si = timer ticks to wait
;
; ,calls:  
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
settime proc	near
	and	[bx].ioprot,not 080h	; clear waiting rollover flag
	push	ax			; save ax
	push	cx			; and cx
	push	dx			; and dx
	mov	di,0			; initialize timer high
	mov	ah,0			; read the current time
	pushf				; simulate an int
	call	[orig1a]		; get the current time
	add	si,dx			; add ticks to wait to timer low
	adc	di,cx			; add the timer high to timeh
	cmp	di,00018h		; should we wait for a rollover
	jb	st10			; exit if no
	cmp	si,000b0h		; is it beyond date rollover
	jb	st10			; exit if no
	sub	di,00018h		; subtract the rollover
	sub	si,000b0h		; subtract the rollover
	or	[bx].ioprot,080h	; show waiting for a rollover
st10:
	pop	dx			; restore dx
	pop	cx			; and cx
	pop	ax			; and ax
	ret				; return to caller
settime endp

;======================================================================
;
; .func: chktime - check current time against timeout value
;
; cf=1 if time expired
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;================================================================
	assume	cs:code,ds:nothing,es:nothing,ss:nothing
chktime proc	near
	push	ax			; save ax
	push	cx			; and cx
	push	dx			; and dx
	mov	ah,0			; get current time
	pushf				; simulate an int
	call	orig1a			; call the 1a handler
	test	[bx].ioprot,080h	; is a rollover required
	jz	ct10			; jump if no
	cmp	al,0			; did a rollover occur
	je	ct30			; exit if not yet
	and	[bx].ioprot,not 080h	; reset rollover required flag
ct10:
	cmp	cx,di			; check timer high
	jb	ct30			; exit if not time yet
	ja	ct20			; don't check low if greater than
	cmp	dx,si			; check timer low
	jb	ct30			; exit if not time yet
ct20:
	pop	dx			; restore dx
	pop	cx			; and cx
	pop	ax			; and ax
	stc				; show the time has elapsed
	ret				; return to caller
ct30:
	pop	dx			; restore dx
	pop	cx			; and cx
	pop	ax			; and ax
	clc				; show still waiting
	ret				; return to caller
chktime endp



;================================================================
;
; Setbaud - set baud rate
;
; Input:
;	CX:BX = baud rate
;	DX = Port
;	AL = stop, parity...
;       SI = pointer to ports structure.
;
;================================================================

setbaud	proc	near
	or	cx,cx
	jnz	badbaud
	xor	di,di
	mov	cx,13*2
sbloop:
	cmp	baud_rates[di],bx
	jz	sbok
	add	di,2
	loop	sbloop
badbaud:
	stc
	ret
sbok:
	push	es
	and	addr[si],07fffh			; enable port
	mov	es,[baseadr]
	mov	word ptr Baud_Rate[si],bx
	mov	word ptr Baud_Rate[si+2],0 	
	xor	cl,cl				; assume set 1
	cmp	di,13*2
	jb	sb1
	sub	di,13*2
	mov	cl,80h				; set 2!
sb1:
	mov	[msg_arg1],cl		
	mov	[msg_fn],4
	call	snd_msg
	shr	di,1			;position low nibble of clock select reg
	mov	dx,di			;put in scratch reg
	shl	dl,4			;position high nibble
	or	dx,di			;merge the nibbles
	mov	[msg_arg1],dl		;smartport message argument
	mov	[msg_fn],2		;change csr function
	call	snd_msg			;send it to smartport

;	set the partiy and word lengths:

	mov	line_control[si],al	;Save Line control information
	mov	di,ax			;get bios argument
	shr	di,1			;position parity bits
	and	di,00001100b		;isolate parity bits
	mov	cx,ax			;get bios argument
	and	cx,00000011b		;isolate word length
	or	di,cx			;insert word length
	mov	cl,par_wlen[di]		;get smartport argument
	mov	[msg_arg1],cl		;store argument in message packet
	mov	[msg_fn],0		;change mode register 1 function
	call	snd_msg			;send message to smartport

;	set number of stop bits:

	mov	di,ax			;get bios argument
	shr	di,2			;position stopbit specification
	and	di,1b			;isolate stopbit spec.
	mov	cl,stop_bit[di]		;get smartport argument
	mov	[msg_arg1],cl		;store in message packet
	mov	[msg_fn],1		;change mode reg 2 function
	call	snd_msg			;send packet to smartport

;	enable transmitter and receiver:

	mov	[msg_fn],3		;change command register
	mov	[msg_arg1],005h		;enable tx/rx
	call	snd_msg			;enable both tx and rx
sb2:
	clc
	pop	es
	ret
setbaud	endp

;=========================================================================;

EndOfDrv label	byte

porttbl	ports	maxport - ($-porttbl)/type ports dup(<>)


; initialization messages

pmsg1	db	'   User $'
pmsg2	db	' installed at Bank Address '
frame   db	'xxxx0H on Port '
bport	db	'xxxxH.',13,10,'$'


not_inst db     'Cannot install MOS Arnet Inteligent Serial Communications driver!' ;@@XLAT
	db	'            ',cr,lf,'$'

spaces  db	'    $'
loadmsg	db	'    Loading $      '  			;@@XLAT
notfound db	' not found, Using ROM Bios.             ',13,10,'$' ;@@XLAT
NoArnet	db	'Arnet Smartport board not found!             ' ;@@XLAT
        db      cr,lf,'$'
	
NoMOS400  db    'This driver requireks PC-MOS 4.10 or Higher.        '  ;@@XLAT
	db	13,10,'$'

NoMemman  db	'This Driver requires PC-MOS Memory Mangement Driver.       ' ;@@XLAT
	db	13,10,'$'


syntax  db      'Syntax error! ' ;@@XLAT
        db      cr,lf,'$'
MsgErrHS  db    'Invalid handshake specification!              ' ;@@XLAT
        db      cr,lf,'$'
MsgErrCN  db    'Invalid connection specification              ' ;@@XLAT
        db      cr,lf,'$'

msgcrlf	db	13,10,'$'

hextable db    '0123456789ABCDEF'

SP0	db	'Smartport$'
SP1	db	'SmartPort Lite$'
SP2	db	'Smartport/2A$'
SP3	db	'Smartport Plus$'
SP4	db	'Smartport Plus (MC)$'
SPUN	db	'Unknown SmartBoard$'

BoardNames label word
	dw	offset SP0
	dw	offset SP1
	dw	offset SP2
	dw	offset SP3
	dw	offset SP4
UnKnow	dw	offset SPUN

UnKnown equ	(UnKnow-BoardNames)

PortList dw	100h,110h,120h,130h,140h,150h,160h,170h,180h
	 dw	190h,1a0h,1b0h,1c0h,1d0h,1e0h,200h,210h,220h
	 dw	280h,290h,2a0h,2b0h,2c0h,2d0h,300h,310h,340h
	 dw	350h,0

HSOptions db	64 dup ('N')
CNOptions db	64 dup ('L')

box	db	'BOX.BIN',0
box2	db	'BOX2.BIN',0
patch	db	'PATCH.BIN',0
patch2	db	'PATCH2.BIN',0

loaddir	db	65 dup (0)
loadpath db	65 dup (0)
buffsize dw	0
zero	dw	0			; irq/mos data segment

	subttl init - process config parameters
	page
;======================================================================
; .func: init - process config parameters
;
; input:
;	ds:si -> command line following device=
;
;       param	      	    default	acceptable
;
;	ad= port(com1)	       03f8	0 < ad < 8000
;		(com2)         02f8
;	ib= input buffer size    64	16 <= ib < 65536
;	ob= output buffer size 1024	16 <= ob < 65536
;	hs= handshaking		  n	(n)one, (d)tr/dsr, dtr/(r)ts,
;					(x)on/xoff, or x(p)c
;	cn= connection		  l	(l)ocal - direct connect
;					(r)emote - modem
; output:
;
; comments:
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;======================================================================
init	proc	near
	call	dispcopy
	cld
	call	CheckMOS		; is this PC-MOS
	Ljc	abort
	call	GetMemman		; get Memman
	Ljc	abort
	push	cs
	pop	es
	call	GetCurDir		; get current directory
	call	ScanSys			; Scan system
	Ljc	abort
	call	ScanHS			; scan for HS=option and remove
	Ljc	abort			
	call	ScanCN			; scan for CN=option and remove
	Ljc	abort			

	assume	cs:code, ds:nothing, es:code, ss:nothing
init00:
	lodsb				; get a character from the line
	cmp	al, space		; is this the first space
	ja	init00			; look for the first space
	dec	si			; back up one
init02:
	lodsb				; get a character
	cmp	al, cr			; should we use the default
	lje	default			; jump if null config line
	cmp	al, lf			; should we use the default
	lje	default			; jump if null config line
	cmp	al, space		; is it a space or less
	jbe	init02			; look for a real character
	dec	si
	call	hextobin
	jc	default
	mov	[BaseAdr],ax
	or	ax,100h
	mov	[Base2Adr],ax	
default:
	call	ChkFreeMem		; check freemem for valid mem
	ljc	abort
	call	MapBase			; Map Base addresss
	mov	ax, cs			; move the code segment to ax
	mov	ds, ax			; set ds to the code segment
	mov	es, ax			; set es to the code segment
	mov	di,[numport]
	shl	di,1			; 2 Paragraphs per port
	add	ax,di
	assume	cs:code, ds:code, es:code, ss:nothing
	lea	di, EndOfDrv+15		; point 1 paragraph beyond init
	shr	di, 4			; init+15 offset in paragraphs
	add	di, ax			; segment of 1st available buffer
	call	InitPorts		
	push	di			; save the next available segment
	mov	ah, 6			; who are you
	xor	dx, dx			; handling port 0
	int	14h			; see if anyone else is home
	test	ah, 080h		; is another mos driver already here
	jz	init96			; go set int 14 if not already taken
	cmp	al,16			; if function is below 16 then
	jb	init96			; driver is not correct 		
	mov	ax, cs			; move the code segment to ax
	mov	es, ax			; set es to the code segment
	assume	cs:code, ds:code, es:code, ss:nothing
	lea	bx, [int14]		; point to our int 14
	mov	ah, 10h			; register us as his child
	int	14h			; call that other serial driver
	jmp	short init98		; go wrap it all up
init96:
	assume	cs:code, ds:code, es:nothing, ss:nothing
	mov	es,[zero]
	cli				; no interuptions here
	mov	word ptr es:[14h*4], offset int14
	mov	word ptr es:[14h*4+2], cs ; set our int 14 segment
	sti				; open up the gates
init98:
	mov	es,[zero]
	cli				; no interuptions here
	mov	word ptr es:[8h*4], offset int8
	mov	word ptr es:[8h*4+2], cs ; set our int 14 segment
	sti				; open up the gates
	call	DispInfo
	pop	ds			; set ds:dx to the
	xor	dx, dx			;  end of our memory allocation
	ret				; return to the caller
syntaxer:
	lea	dx, syntax		; show a syntax error
abort:
	mov	ax, cs			; set ax to code segment
	mov	ds, ax			; set ds to the code segment
	assume	cs:code, ds:code, es:code, ss:nothing
	mov	ah, 9			; print string
	int	021h			; call mos
	lea	dx, not_inst		; tell him were not installed
	mov	ah, 9			; print string
	int	021h			; call mos
	xor	dx, dx			; set ds:dx to release entire module
	les	bx, [request]
	mov	es:[bx+3],0200h		; set error status
	ret				; return with no memory allocated
init	endp	

assume	ds:nothing,es:nothing

;
; ScanSlash - scans command line for / 
;
ScanSlash proc	near
	lodsb
	cmp	al,cr
	je	NoSlash
	cmp	al,lf
	je	NoSlash
	cmp	al,'/'
	jne	ScanSlash
	mov	di,si
	dec	di
	clc
	ret
NoSlash:
	stc
	ret
ScanSlash endp

;
; ClearSlash - clear /xx=... from  command line
;

ClearSlash proc	near
	push	es
	mov	ax,ds
	mov	es,ax	
	mov	al,' '			; clear with spaces
ClearLoop:
	mov	ah,byte ptr ds:[di]
	cmp	ah,' '
	je	ClearExit
	cmp	ah,cr
	je	ClearExit
	cmp	ah,lf
	je	ClearExit
	stosb
	jmp	short ClearLoop
ClearExit:
	pop	es
	ret	   
ClearSlash endp



;
; ScanHS - scans command line for /HS= option
;

ScanHS	proc	near
	push	si
NextHS:
	call	ScanSlash
	jc	HSok
	lodsw
	cmp	ax,'SH'
	jne	NextHS
	lodsb
	cmp	al,'='
	jne	doHSerr
	push	di
	mov	di,offset HSOptions
HSTabLoop:
	lodsb
	cmp	al,'N'
	je	HSTabOk
	cmp	al,'D'
	je	HSTabOk
	cmp	al,'X'
	je	HSTabOk
	cmp	al,'R'
	je	HSTabOk
	cmp	al,' '
	je	HSDone
	cmp	al,cr
	je	HSDone
	cmp	al,lf
	je	HSDone
	pop	di
DoHSErr:
	mov	dx,offset MsgErrHS
	stc
	jmp	short HSExit
HSTabOk:
	stosb
	jmp	short HSTabLoop
HSDone:	
	pop	di
	call	ClearSlash
HSok:
	clc
HSexit:
	pop	si
	ret
ScanHS  endp
		   
;
; ScanCN - scans command line for /CN= option
;

ScanCN	proc	near
	push	si
NextCN:
	call	ScanSlash
	jc	CNok
	lodsw
	cmp	ax,'NC'
	jne	NextCN
	lodsb
	cmp	al,'='
	jne	doCNerr
	push	di
	mov	di,offset CNOptions
CNTabLoop:
	lodsb
	cmp	al,'L'
	je	CNTabOk
	cmp	al,'R'
	je	CNTabOk
	cmp	al,' '
	je	CNDone
	cmp	al,cr
	je	CNDone
	cmp	al,lf
	je	CNDone
	pop	di
DoCNErr:
	mov	dx,offset MsgErrCN
	stc
	jmp	short CNExit
CNTabOk:
	stosb
	jmp	short CNTabLoop
CNDone:	
	pop	di
	call	ClearSlash
CNok:
	clc
CNexit:
	pop	si
	ret
ScanCN  endp


ChkFreeMem proc	near
	clc
	ret
ChkFreeMem endp

assume	ds:nothing,es:nothing

ScanSys	proc	near
	push	si
	push	ds
	push	cs
	pop	ds
	lea	si,PortList
ScanLoop:
	lodsw
	or	ax,ax
	jz	ScanErr
	mov	dx,ax
	add	dx,2
	in	al,dx
	cmp	al,'S'
	jne	ScanLoop
	inc	dx
	in	al,dx
	cmp	al,'P'
	je	ScanSet
	cmp	al,'1'
	je	ScanSet
	cmp	al,'2'
	jne	ScanLoop
ScanSet:
	mov	[BoardType],al
	and	dx,0fff0h
	mov	[Board],dx	
	clc
	pop	ds
	pop	si
	ret
ScanErr:
	mov	dx,offset NoArnet
	stc
	pop	ds
	pop	si
	ret
ScanSys	endp


ResetBox proc	near
	push	dx
	push	ds
	mov	dx,[Board]
	add	dx,04h
	mov	al,2
	out	dx,al			; initialize port

	push	dx
	xor	ax,ax
	mov	ds,ax
	mov	dx,ds:[46ch]
WaitLoop:
	mov	ax,ds:[46ch]
	sub	ax,dx
	cmp	ax,4
	jb	WaitLoop	
	pop	dx
	
	xor	al,al
	out	dx,al

	mov	dx,ds:[46ch]
WaitLoop2:
	mov	ax,ds:[46ch]
	sub	ax,dx
	cmp	ax,4
	jb	WaitLoop2	
	pop	ds	
	pop	dx
	ret
ResetBox endp


MapBase	proc	near
	push	es
	mov	dx,[Board]
	inc	dx
	in	al,dx
	xor	ah,ah
	shl	ax,4
	mov	[BoardPage],ax
	xor	dx,dx
	call	MapMem		; map first 4k into Page 0 area
	call	LoadBox		; load box in
	mov	es,[BaseAdr]
	mov	al,byte ptr es:[SP_EQUIP]
	mov	[BoardSys],al
;
;	Now we must detected the Number of Serial Ports Installed
;
	call	moswait				; give it chip time
	mov	dx,cs:[Board]
	cmp	[BoardType],'2'		; is this new series
	je	DoNew
	mov	cx,8
	cmp	[BoardSys],2
	jae	SetPorts
	in	al,dx
	cmp	al,0ffh
	je	SetPorts
	sub	cl,4
	cmp	al,0fh
	je	SetPorts
	mov	cl,1
	jmp	short SetPorts
DoNew:
	mov	cx,32
	test	word ptr es:[UP_MASK_HI],0ff00h
	jnz	SetPorts
	mov	cl,24
	test	word ptr es:[UP_MASK_HI],000ffh
	jnz	SetPorts
	mov	cl,16
	test	word ptr es:[UP_MASK_LOW],0ff00h
	jnz	SetPorts
	mov	cl,8
	test	word ptr es:[UP_MASK_LOW],000ffh
	jnz	SetPorts
	mov	cl,4
SetPorts:
	mov	[NumPort],cx
;			
	pop	es
	ret
MapBase	endp

DispInfo proc	near
	push	cs
	pop	ds
	mov	ax,[numport]
	cmp	ax,10
	jb	DI1
	mov	byte ptr [pmsg1],'0'
DILoop:
	cmp	ax,10
	jb	DI1
	inc	byte ptr [pmsg1]
	sub	ax,10
	jmp	short DILoop
DI1:
	mov	byte ptr [pmsg1+1],'0'
	add	byte ptr [pmsg1+1],al
	mov	dx,offset pmsg1
	mov	ah,9
	int	21h	
	mov	bl,[BoardSys]
	xor	bh,bh
	shl	bx,1
	cmp	bx,UnKnown
	jbe	DI2
	mov	bx,UnKnown
DI2:
	mov	dx,word ptr [bx+BoardNames]
	mov	ah,9
	int	21h
	mov	ax,[BaseAdr]
	lea	bx,frame+3
	call	bintohex
	mov	ax,[Board]
	lea	bx,bport+3
	call	bintohex
	mov	dx,offset pmsg2
	mov	ah,9
	int	21h	
	ret
DispInfo endp

InitPorts proc	near
	push	di
	push	es
	mov	es,[baseadr]
	mov	cx,[NumPort]
	or	cx,cx 			; if no ports skip initialization
	jz	IPSkip
	lea	si,porttbl
	mov	ax,10h			; start Input Descripters at 10h
IPLoop:
	push	ax
	push	cx
	push	si

	mov	input_desc[si],ax
	mov	di,ax
	mov	cx,es:q_size[di]
	mov	ibfsiz[si],cx
	add	ax,8
	mov	output_desc[si],ax
	mov	di,ax
	mov	cx,es:q_size[di]
	mov	obfsiz[si],cx
	mov	kbeflg[si],0
	mov	ioprot[si],00h		; initialize no  connection info
	mov	line_control[si],00h
	or	addr[si],8000h

	pop	si
	pop	cx
	pop	ax
	add	si,type ports
	add	ax,16
	loop	IPLoop	
IPSkip:
	pop	es
	pop	di
	ret
InitPorts endp

	subttl hextobin - conversion
	page
;======================================================================
; .func: hextobin - conversion
;
; input:
;
; output:
;
; comments:
;
; ,calls:
; ,reads:
; ,writes:
;
; ,endfn
;======================================================================
hextobin proc	near
	xor	ax, ax			; clear ax
	mov	ch, ah			; clear ch also
	mov	cl, [si]		; get the first character
	cmp	cl, '0'			; is it a digit
	jb	htbx			; set carry and return if no
	cmp	cl, '9'			; is it a digit
	jbe	htbloop			; go process it if yes
	and	cl, 0dfh		; convert alpha to uppercase
	cmp	cl, 'A'			; is it between a and f
	jb	htbx			; set carry and return if no
	cmp	cl, 'F'			; is it between a and f
	ja	htbx			; set carry and return if no
htbloop:
	mov	cl, [si]		; get the next character
	cmp	cl, '0'			; is it a digit
	jb	htbwrap			; exit if all done
	cmp	cl, '9'			; is it a digit
	jbe	htb1			; go process it if yes
	and	cl, 0dfh		; convert alpha to uppercase
	cmp	cl, 'A'			; is it between a and f
	jb	htbwrap			; exit if all done
	cmp	cl, 'F'			; is it between a and f
	ja	htbwrap			; exit if all done
	sub	cl, 7			; convert alpha to hex equivalent
htb1:
	sub	cl, '0'			; convert character to binary
	mov	dx, 16			; each position has 16
	mul	dx			; times more significance
	or	dx, dx			; have we overflowed ax
	jnz	htbwrap			; set carry and exit if yes
	add	ax, cx			; add it to the others
	test	ax,0f000h
	jnz	htbwrap
	inc	si			; bump to get the next character
	jmp	short htbloop		; go check the next character
htbwrap:
	clc				; clear the carry flag (no error)
	ret				; return to caller
htbx:
	stc				; set the carry flag (error)
	ret				; return to caller
hextobin endp

bintohex proc	      	   
	push  si
	mov   dl,4
bthloop1:
	mov   si,ax
	and   si,000fh
	mov   cl,[hextable+si]
	mov   [bx],cl
	shr   ax,4
	dec   bx
	dec   dl
	jg    bthloop1
	pop   si
	ret
bintohex endp

DispIt	proc	near
	push	ds
	push	cs
	pop	ds
DSIloop:
	lodsb	
	or	al,al
	jz	DIdone
	mov	dl,al
	mov	ah,2
	int	21h
	jmp	short DSIloop
DIdone:
	pop	ds
	ret
DispIt	endp

MoveIt	proc	near
	push	ds
	push	cs
	pop	ds
MIloop:
	lodsb	
	or	al,al
	jz	MIdone
	stosb
	jmp	short MIloop
MIdone:
	pop	ds
	ret
MoveIt	endp


LoadBuff proc	near
	pusha
	push	ds
	push	es
	push	bp			
	push	ax
	push	ax
	mov	bp,sp
	mov	es,[baseadr]
	mov	si,offset Buffer
;
;	First We Must download file to board
;
	cmp	[BoardType],'2'
	je	LBNew
	push	word ptr es:[DST_OFFSET]
	jmp	short LBCont
LBNew:
	push	word ptr es:[DST_OFFSET_NEW]
LBCont:
	mov	ax,[buffsize]
LBLoop:
	mov	cx,256
	cmp	ax,cx
	ja	LoadB1
	mov	cx,ax
LoadB1:
	push	ax
	push	cx
	push	si
	push	es

	cmp	[BoardType],'2'		
	je	LoadNew

	mov	di,es:[DUAL_SIZE] 	; size of Dual-Port Ram
	sub	di, 16			; subtract 256 bytes from top
	shl	di,4			; convert to bytes
	mov	es:[SRC_OFFSET],di	; set src offset
	mov	es:[STR_LEN],cx		; set string lenght
	jmp	short LoadIt
	
LoadNew:
	mov	di,es:[DUAL_SIZE_NEW] 	; size of Dual-Port Ram
	sub	di,16			; subtract 256 bytes from top
	shl	di,4			; convert to bytes
	mov	es:[SRC_OFFSET_NEW],di	; set src offset
	mov	es:[STR_LEN_NEW],cx	; set string lenght
LoadIt:
	cmp	di,4096			  
	jb	LoadIt2
	mov	ax,di
	shr	ax,12
	add	ax,[BoardPage]
	mov	dx,-1
	call	MapMem			; map page in if not already mapin
	mov	es,[base2adr]
	and	di,4095
LoadIt2:	
	fastmov

	mov	es,[baseadr]
	mov	[msg_fn],18
	mov	[msg_port],0		
	mov	[msg_arg1],0ffh
	mov	[msg_arg2],0ffh
	call	snd_msg
	call	moswait

	pop	es
	pop	si
	pop	cx
	pop	ax
	cmp	[BoardType],'2'
	je	LincNew
	add	word ptr es:[DST_OFFSET],cx
	jmp	short LincCont
LincNew:
	add	word ptr es:[DST_OFFSET_NEW],cx
LincCont:
	add	si,cx
	sub	ax,cx
	or	ax,ax
	jz	LDoneFinish
	jmp	LBLoop
LDoneFinish:
	cmp	[BoardType],'2'
	je	LDoneNew
	pop	word ptr es:[DST_OFFSET]
	jmp	short LDoneCont
LDoneNew:
	pop	word ptr es:[DST_OFFSET_NEW]
LDoneCont:
;
;	File is download, executed it
;
	mov	[msg_fn],19
	mov	[msg_port],0		
	mov	[msg_arg1],0ffh
	mov	[msg_arg2],0ffh
	call	snd_msg
;
;	Now wait for board to reset
;
	mov	dx,[board]
	mov	si,18*2		; wait for 2 seconds
	call	settime
WaitLoop3:
;	in	al,dx
;	or	al,al
;	jnz	WaitOut	
	call	chktime
	jc	WaitOut
	call	moswait
	jmp	short WaitLoop3	
WaitOut:
	
	pop	ax
	pop	ax	
	pop	bp
	pop	es
	pop	ds	
	popa
	ret
LoadBuff endp
;
; LoadFile - load file into buffer
; Return carry set if file is not available
;
LoadFile proc	near
	push	ds
	push	cs
	pop	ds
	mov	dx,offset LoadPath
	mov	ax,3d00h
	int	21h
	jc	LoadExit
	mov	bx,ax
	mov	dx,offset Buffer
	mov	cx,10*1024
	mov	ah,3fh
	int	21h
	mov	[buffsize],ax
	pushf
	mov	ah,3eh
	int	21h
	popf
LoadExit:
	pop	ds
	ret
LoadFile endp
					
LoadBox	proc	near
	mov	si,offset LoadDir
	mov	di,offset LoadPath
	call	moveit
	mov	si,offset box
	cmp	[BoardType],'2'
	jne	LB1
	mov	si,offset box2
LB1:
	call	moveit
	xor	al,al
	stosb
	call	LoadFile
	jnc	LB1x
	mov	di,offset LoadPath
	mov	si,offset box
	cmp	[BoardType],'2'
	jne	LB1a
	mov	si,offset box2
LB1a:
	call	moveit	
	xor	al,al
	stosb
	call	LoadFile
	jnc	LB1x
	mov	si,offset box
	cmp	[BoardType],'2'
	jne	LB1b
	mov	si,offset box2
LB1b:
	push	ds
	push	cs
	pop	ds
	mov	dx,offset spaces
	mov	ah,9
	int	21h
	call	dispit
	mov	dx,offset notfound
	mov	ah,9
	int	21h
	pop	ds
	jmp	short LB1done
LB1X:
	push	ds
	push	cs
	pop	ds
	mov	dx,offset LoadMsg
	mov	ah,9
	int	21h
	mov	si,offset LoadPath
	call	dispit
	mov	dx,offset msgcrlf
	mov	ah,9
	int	21h
	call	LoadBuff
	pop	ds
LB1done:
	mov	si,offset LoadDir
	mov	di,offset LoadPath
	call	moveit
	mov	si,offset patch
	cmp	[BoardType],'2'
	jne	LB2
	mov	si,offset patch2
LB2:
	call	moveit
	xor	al,al
	stosb
	call	LoadFile
	jnc	LB2x
	mov	di,offset LoadPath
	mov	si,offset patch
	cmp	[BoardType],'2'
	jne	LB2a
	mov	si,offset patch2
LB2a:
	call	moveit	
	xor	al,al
	stosb
	call	LoadFile
	jnc	LB2x
	mov	si,offset patch
	cmp	[BoardType],'2'
	jne	LB2b
	mov	si,offset patch2
LB2b:
	push	ds
	push	cs
	pop	ds
	mov	dx,offset spaces
	mov	ah,9
	int	21h
	call	dispit
	mov	dx,offset notfound
	mov	ah,9
	int	21h
	pop	ds
	jmp	short LB2done
LB2X:
	push	ds
	push	cs
	pop	ds
	mov	dx,offset LoadMsg
	mov	ah,9
	int	21h
	mov	si,offset LoadPath
	call	dispit
	mov	dx,offset msgcrlf
	mov	ah,9
	int	21h
	call	LoadBuff
	pop	ds
LB2done:
	ret
LoadBox	endp


buffer	label	byte


scset   db      'MOS Arnet Inteligent Serial Communications driver v1.01 (920916)' ;@@XLAT
	db	13,10
	db	'(c)Copyright 1991,1992 The Software Link, Incorporated'    ;@@XLAT
	db	13,10
	db	'(c) Portions Copyright 1987-1990 Arnet Corporation'   ;@@XLAT	
	db	13,10,'$'

dispcopy proc	near
	push	ds
	push	cs
	pop	ds
	mov	dx,offset scset
	mov	ah,9
	int	21h
	pop	ds
	ret
dispcopy endp

;
; GetCurDir - gets current directory, location where $ARNET.SYS is located
; 	      at.  Directory is place in [LOADDIR] terminated with a "\"
;	      and place offset next position in [LOADOFF]
;
GetCurDir proc	near
	push	si
	mov	di,offset LoadDir
GCDLoop:
	lodsb
	cmp	al,'$'
	je	GCDExit
	cmp	al,' '
	je	GCDexit
	cmp	al,13
	je	GCDexit
	stosb
	jmp	short GCDloop
GCDExit:
	xor	al,al
	stosb
	pop	si
	ret
GetCurDir endp


;--------------------------------------------------------------------;
; CheckMOS - The following Procedure which see if PC-MOS is Installed;
; If so it will check if Version is 4.00 or higher, if so it will    ;
; scbseg and tcbseg to SCB and TCB segments			     ;
;--------------------------------------------------------------------;

CheckMOS proc	near
	mov	bx,-1
	mov	ah,30h
	int	21h
	push	ax
	mov	ah,30h
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax
	int	21h
	pop	bx
 	cmp	ax,bx
	je	NotMos
	cmp	al,04h
	jb	NotMos
	jne	Not400
	or	ah,ah
	jz	NotMos
Not400:
	mov	ah,2
	int	0d4h
	mov	[scboff],bx
	mov	[scbseg],es
	mov	ax,word ptr es:[bx+scbfar38]
	mov	word ptr [orig38], ax	
	mov	ax,word ptr es:[bx+scbfar38+2]
	mov	word ptr [orig38+2], ax	
;
	mov	es, cs:[zero]		; set es to seg 0
	mov	ax, word ptr es:[1ah*4]	; get the original int 1a offset
	mov	word ptr [orig1a], ax	; set up for calls versus int
	mov	ax, word ptr es:[1ah*4+2] ; get the original int 1a segment
	mov	word ptr [orig1a+2], ax	; set up for calls versus int
;
	mov	ax,word ptr es:[8h*4]
	mov	word ptr [orig08],ax
	mov	ax,word ptr es:[8h*4+2]
	mov	word ptr [orig08+2],ax
	clc
	ret
NotMos:
	mov	dx, offset NoMOS400
	stc
	ret
CheckMOS endp

GetMemman proc	near
	push	si
	push	ds
	lds	si,[scbadr]		
	assume	ds:scbs
	cmp	[si+scbmmfg],'Y'
	jne	NoMemdev
	mov	ax,word ptr [si+scbmmsub]
	mov	word ptr cs:[memman],ax
	mov	ax,word ptr [si+scbmmsub+2]
	mov	word ptr cs:[memman+2],ax
	pop	ds
	pop	si
	clc
	ret
NoMemdev:
	pop	ds
	pop	si
	mov	dx,offset NoMemman
	stc
	ret
GetMemman endp

code	ends
	end
