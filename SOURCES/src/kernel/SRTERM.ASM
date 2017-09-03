	include page.inc
	title	srterm.asm - mos sunriver ega terminal driver
comment ^=============================================================
			development specification

 program name:	srterm.asm		assigned to: stewart hyde
 module name:	srterm			assign date: 06/10/87 (03/14/88 rod)
 entry points:				completed:   05/07/88 (comdex)
 entry from:
 entry method:	call dword [vector] with ah = function number
 calls: 	i10old (boot interrupt 10h)
 purpose:	mos interface to sunriver fiber optic ega terminal
 refer to:	stewart hyde
 last update:	04/03/91

 this is the source module for the sunriver ega terminal for our
 pc-mos/386 operating system. for detail information on the hardware
 check the sunriver ega documentation or check with stewart.
 this driver will automatically detected and allocated space for up to
 sunriver's theoretical limit of 256 terminals (64 cards).  Pratical
 limit is most likely 2 or 3 cards (8 to 12 terminals).

	config.sys line is as follows:
	device=srterm.sys [workarea]
	where:
		workarea is optional (defaulting to ec000h)
		start of drivers workarea above 640k which must
		be 12k and reserved for drivers used only
		but must be on a 16k boundary

       to invoke terminal do
	addtask mem,,,,,srterm,port
	where:
		mem -	memory size of partition
		port -	port #	1 - maximun # of ports ( 4 per card)

 provisions have been made so that a user can dynamical remove and then
 add	it back again.

 local printer support of sunriver's stations Parrallel port, which is
 is in similar designed as printer ports off of pcterm style terminals
 to access these ports, one will use the mos route lptx to term
 command.

 internal int 14 logic has been added but is primary intended to drive
 mouse off of com1 or com2 on the workstation using mos's Generic
 mouse driver $mouse.sys.

========================================================================

sah 06/08/89	supported list base mapping calls for faster mapping

sah 06/12/89	corrected problem with handling mult-mice off of
		two stations on same chip (ie 1,2 or 3,4). i
		had make sure that reset chanid register of
		both stations at the same time that i sent
		acknoledgement to their stations.

sah 06/21/89	increase input buffer to 32 bytes, adjusted for
		references to tcbstation

sah 06/28/89	corrections for keyboard logic

sah 07/05/89	corrections for beeps, currently does not beep
		but does not stall system.

sah 07/17/89	added function 18 which does mothing on work
		station style stations.

sah 07/31/89	corrected printing.

sah 08/29/89	corrections for freemem requirements 12k instead of 48k

sah 09/25/89	some corrections for vga support, also	made
		using 12k actually use just 12k

sah 10/24/89	corrections for vga version.

bwr 11/30/89	marked messages for foreign language translations.

mjs 05/09/90	added the clr_set_irq dummy function.  it is called by
		int14fun11 within int14.inc (only needed by _serial.asm)

sah 06/20/90	correction for newer boards, base address other than
		f0,000.

sah 06/28/90	added logic to allow pamswitching between non-ega\vga
		workstations (ie vna or terminals)

mjs 08/13/90	modified to use vidchk.inc and a boot_prep function.


sah 04/03/91	modifications for 40:17 support in mos 4.11

mjs 05/24/91	added printer status ddt function.  cleaned up module

=======================================================================^
	page
; conditional assembly equ below

true		equ	1
false		equ	0
version 	equ	true

	subttl	group segments and include block definitions
	page
.xlist
	.286
	include options.inc
	include srterm.pub
	include mosregs.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

scbs	segment at 7000h
	assume cs:scbs
	include mosscbdf.inc
scbs	ends

stall	macro
	local	lstall
	jmp	short lstall
lstall:
	endm

waittm	equ	6000h

	include srterm.def
	include jmpmacro.inc
.list

; definiitions and equates use
; status and control registers

chansel 	equ	0f00h
modereg 	equ	0f01h
chanid		equ	0f02h
devicereg	equ	0f03h
intcontrol	equ	0f04h
irqsel		equ	0f05h
intlatch	equ	0f06h

; device indentification bits

poweron 	equ	000b		; power on interupt
keyboard	equ	001b		; keyboard interupt
egacontrol	equ	010b		; ega controller interupt
serial2 	equ	011b		; serial port 2 interupt
serial1 	equ	100b		; serial port 1 interupt
parrallel	equ	101b		; parrallel port interupt
timer		equ	110b		; timer interupt

; switch memory definitions

resetsys	equ	0		; reset fiber optic station
bankselreg	equ	1		; bank select register
rearmcontrol	equ	4		; rearm interupt controller
actintrq	equ	5		; activate station intrq pin
resetintrq	equ	6		; reset station intrq pin
egaenable	equ	7		; ega enable\diable

; keyboard controller definitions

keystatus	equ	0064h		; keyboard status
keyoutput	equ	0060h		; keyboard output buffer
keydatainp	equ	0060h		; keyboard data input
keycmdinp	equ	0064h		; keyboard command input

; parallel port controller definitions

pardata 	equ	03bch		; parallel port data
parcontrol	equ	03beh		; parallel port control
parstatus	equ	03bdh		; parallel port status

; serial port definitions

com1tx		equ	03f8h		; com1 txbuffer
com1rx		equ	03f8h		; com1 rcbuffer
com1lsb 	equ	03f8h		; com1 divisor latch lsb
com1msb 	equ	03f9h		; com1 divisor latch msb
com1enable	equ	03f9h		; com1 interupt enable
com1id		equ	03fah		; com1 interupt id
com1linectrl	equ	03fbh		; com1 line control
com1modctrl	equ	03fch		; com1 modem control
com1linestat	equ	03fdh		; com1 line status
com1modstat	equ	03feh		; com1 modem status

com2tx		equ	02f8h		; com2 txbuffer
com2rx		equ	02f8h		; com2 rcbuffer
com2lsb 	equ	02f8h		; com2 divisor latch lsb
com2msb 	equ	02f9h		; com2 divisor latch msb
com2enable	equ	02f9h		; com2 interupt enable
com2id		equ	02fah		; com2 interupt id
com2linectrl	equ	02fbh		; com2 line control
com2modctrl	equ	02fch		; com2 modem control
com2linestat	equ	02fdh		; com2 line status
com2modstat	equ	02feh		; com2 modem status

; ega port definitions

feat_adr	equ	03dah		; pega features register
hrc_adr 	equ	03bfh		; pega hercules register
attr_adr	equ	03c0h		; pega attribute controller
misc_adr	equ	03c2h		; pega misc register
seq_adr 	equ	03c4h		; pega sequencer controller
graph_adr	equ	03ceh		; pega graphics controller
crt_adr 	equ	03d4h		; pega crt controller
par_adr 	equ	03d8h		; pega paradise register
plr_adr 	equ	03ddh		; pega plantronics register
atr_adr 	equ	03deh		; pega at&t register
ext_adr 	equ	03dfh		; pega special purpose register

; vga related definitions

; station driver status definition

active		equ	00000001b	; mark if card is available
online		equ	00000010b	; mark if card is online
kbsize		equ	32		; 32 maximum keys in buffer
maxisr		equ	32		; max of 32 passes though isr

; async adapter port and status definitions

txdat	equ	0			; data transmitter
rxdat	equ	0			; data receiver
divll	equ	0			; baud rate divisor latch lsb
divlm	equ	1			; baud rate divisor latch msb
iereg	equ	1			; interupt enable register
enmsi	equ	000001000b		; enable modem status interupts
enlsi	equ	000000100b		; enable line status interupts
entei	equ	000000010b		; enable transmitter empty inter
endri	equ	000000001b		; enable data ready interupts
iireg	equ	2			; interupt identification regist
noint	equ	000000001b		; no interupt pending
lcreg	equ	3			; line control register
divla	equ	010000000b		; divisor latch access control
stbrk	equ	001000000b		; set break condition
mcreg	equ	4			; modem control register
stot2	equ	000001000b		; set out 2 (enable interupts)
stot1	equ	000000100b		; set out 1
strts	equ	000000010b		; set rts
stdtr	equ	000000001b		; set dtr
lsreg	equ	5			; line status register
tsre	equ	001000000b		; transmitter shift reg empty
thre	equ	000100000b		; transmitter holding reg empty
brki	equ	000010000b		; break indicator
frerr	equ	000001000b		; framing error
paerr	equ	000000100b		; parity error
overr	equ	000000010b		; data overrun error
drdy	equ	000000001b		; data ready
msreg	equ	6			; modem status register
carst	equ	010000000b		; status of carrier detect (rlsd)
rngst	equ	001000000b		; status of ring indicator (ri)
dsrst	equ	000100000b		; status of data set ready (dsr)
ctsst	equ	000010000b		; status of clear to send (cts)
carch	equ	000001000b		; change in carrier detect (rlsd)
trlri	equ	000000100b		; trailing end of ring indicator
dsrch	equ	000000010b		; change in data set ready (dsr)
ctsch	equ	000000001b		; change in clear to send (cts)

	page
code	segment para public 'data'	; to force loading with data
	assume	cs:code,ds:nothing,es:nothing,ss:nothing

mosddtsh equ	this byte
	dd	-1			; filled in with pointer to next driver
	dw	8000h			; signifying a character device
	dw	strat			; device strategy entry point
	dw	inter			; device interrupt entry point
srname	db	'$$SRTERM'		; device name

request dd	0

fn	dw	ddtinit 		; 0 - init
	dw	ddtnull 		; 1 - media check
	dw	ddtnull 		; 2 - build bpb
	dw	ddtnull 		; 3 - ioctl input
	dw	ddtread 		; 4 - read
maxfn	equ	($-fn)/2

	subttl strat - device driver strategy function
	page
;======================================================================
;,fs
; strat - device driver strategy function
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
strat proc far
	mov	word ptr [request],bx
	mov	word ptr [request+2],es
	ret
strat endp

	subttl intr - device driver interrupt function
	page
;======================================================================
;,fs
; intr - device driver interrupt function
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
inter proc far
	push	es
	push	ds
	push	si
	push	bx
	push	ax
	mov	bx,cs
	mov	ds,bx
	assume	ds:code
	mov	ax,0100h
	les	bx,[request]
	mov	si,es:[bx+2]
	and	si,0ffh
	cmp	si,maxfn
	jae	inter1
	shl	si,1
	call	fn[si]
inter1:
	assume	ds:nothing
	les	bx,[request]
	mov	es:[bx+3],ax		; store result status
	pop	ax
	pop	bx
	pop	si
	pop	ds
	pop	es
	ret
inter endp

; null device driver call does nothing

	subttl ddtnull - null handler
	page
;======================================================================
;,fs
; ddtnull - null handler
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
ddtnull proc near
	mov	ax,0100h		; return no error, done
	ret
ddtnull endp

	subttl ddtread - return the terminal function vector
	page
;======================================================================
;,fs
; ddtread - return the terminal function vector
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
ddtread proc near
	lds	si,es:[bx+14]
	mov	cx,es:[bx+18]
	mov	word ptr es:[bx+18],0	; nothing read if error
	mov	ax,8103h		; error, done, unknown command
	cmp	cx,4
	jne	ddtrd1			; if not reading exactly 4 bytes
	mov	es:[bx+18],cx		; else read 4 bytes
	mov	word ptr ds:[si],offset srterm	; and these are them
	mov	ds:[si+2],cs
	mov	ax,0100h		; no error, done
ddtrd1:
	ret
ddtread endp

	subttl	local data area - storage area for data
	page

maxid	equ	64			; temporary set up for 64

scbptr	label	dword
scboff	dw	0			; offset to scb
scbseg	dw	0			; segment of scb
memman	dd	0			; memmory manager caller
mapvma	dd	0			; video memory area mapper
tcbseg	dw	0			; segment of tcb (caller)
ddtoff	dw	0			; offset (ds:si)
maxterm dw	0			; max sunriver terminals on system
workarea dw	0			; menman work area for driver
workio	dw	0			; current workarea io handle
baseaddr dw	0			; base address
curega	db	0			; current ega port
temp	db	0
mcdriver dd	0			; master console driver
mctcb	dw	0			; master console tcb
irq	db	0			; selected irq
rearm	dw	0			; re-arm port
irqmask db	0			; irq mask
oldirq	dd	0			; old irq
actvid	db	255			; activid
ofs10	dw	0			; original int 10 offset
seg10	dw	0			; original int 10 segment
kbbios	db	'N'			; is kbbios set
orges	dw	0			; orginal es values
workswt dw	0			; switch work area
workmap dw	0			; mapping register work area
saveid	db	0			; save id during irq logic
endofdata dw	0			; segment of end of data area, end of keep
					; code and data
station dw	0			; station interupted pointed used in irq
vgabios db	'N'			; y indicates that system has vga bios
savlast dw	0			; saved lastff value during bankin
dochval db	0ffh			; channel value use to manage dochan
moudriver   db	'$$MOUSE',0		; mouse driver
isrcount  db	 0			; isr count for serial logic
once	db	'N'			; gone through irq once already

listsr	label	word
	dw	5			; this is for physical remap call
	dw	0b800h			; map into text display memory
asr1	dw	00f28h			; use physical bank 0f28h
	dw	4			; map 4 banks for 16k
	dw	0
	dw	0			; no second page
	dw	5			; this is for physical remap call
	dw	0a000h			; map into graphics display memory
asr2	dw	00f10h			; use physical bank 0f10h
	dw	16			; map 16 banks for 64k
	dw	0
	dw	0			; no second page

listmc	label	word
	dw	4			; this is for unmap call
	dw	0b800h			; map into text display memory
	dw	0			; unmap
	dw	4			; unmap 4 banks for 16k
	dw	0
	dw	0			; no second page
	dw	4			; this is for unmap call
	dw	0a000h			; map into graphics display memory
	dw	0			; use physical bank 0f10h
	dw	16			; map 16 banks for 64k
	dw	0
	dw	0			; no second page

; the following is data for serial (int 14 needs)

sportseg    dw	    0			; segment location of start of port area
portoff     dw	    0			; offset of port table from start of code
child	    dd	    0			; segment and offset of child int 14 handler
numport     dw	    0			; # of com ports on system
tocount     dw	    182 		; default timeout count (10 seconds)
orig38	    dd	    0			; original int 38 vector
orig1a	    dd	    0			; original int 1a vector

sername     db	    'SunRiver Serial Ports v2.10 (910403)    '	;@@xlat

;======================================================================
;  irqtab - the following table defines the four possiable irq which the
;	    the sunriver board can used.  the table has the following
;	    fields.
;
;	    interupt	byte	interupt which irq uses
;	    global	word	global reset port (sunriver)
;	    display	word	display value used.
;======================================================================

irqtab	label	word			; constants pg 3-10 (sunriver doc)
	db	0dh
	dw	02f5h			; irq 5
	dw	'5 '
	db	11011111b
	db	0fh
	dw	02f7h			; irq 7
	dw	'7 '
	db	01111111b
	db	74h
	dw	06f4h			; irq 12
	dw	'21'
	db	11101111b
	db	77h
	dw	06f7h			; irq 15
	dw	'51'
	db	01111111b

; irqfun - irq function table

irqfun	label	word
	dw	offset	power		; power on interupt
	dw	offset	keybd		; keyboard handling
	dw	offset	egasys		; ega vertical scan interupt
	dw	offset	ser2		; serial port 2 handling
	dw	offset	ser1		; serial port 1 handling
	dw	offset	par		; parallel port handling
	dw	offset	time		; timer interupt

;======================================================================
;  sun structure - the following is use in a dynamic task table which
;		   is created at init time when the driver check to see
;		   how many active cards are on the system.
;
; please note: changing the lenght of structure here requires init code,
;	       findptr and taskptr routines to be alter.
;======================================================================

sun	struc
termid	db	?			; terminal id (0 - maxterm-1)
status	db	?			; status byte
taskid	dw	?			; tcb of task allocated for console
kbget	dw	?
kbput	dw	?
kbready db	?
kbbuff	db	32	dup (0)
unreg	dd	0			; prevous unregister call
kbstat	db	0			; keyboard led status bits
reserve db	2 dup (0)
sun	ends

;======================================================================
;   port structure - this structure defines necessary information for
;		     com port int 14 logic. currently it is 32 bytes
;		     in size and there are 2 entry for each station on
;		     the system.
;======================================================================

isize	equ	32			; 64 byte default input buffer
osize	equ	16			; 16 byte default output buffer

ports	struc
addr	dw	0			; physical port address
prtirq	db	4			; default irq line for port
kbeflg	db	0			; keyboard empty flag
modmst	db	0			; current modem status register
linest	db	0			; current line status register
ioprot	db	0			; i/o protocols enabled
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
xoffch	db	0			; xoff character
xonch	db	0			; xon character
datovr	db	0			; flag to indicate data overrun
bufovr	db	0			; flag to indicate buffer overrun
ibfsiz	dw	isize			; input buffer size (bytes)
obfsiz	dw	osize			; output buffer size (bytes)
ibfseg	dw	0			; input buffer segment
ibfcnt	dw	0			; count of bytes in buffer
ibfget	dw	0			; next byte from buffer
ibfput	dw	0			; next empty buffer location
obfseg	dw	0			; output buffer segment
obfcnt	dw	0			; count of bytes in buffer
obfget	dw	0			; next byte from buffer
obfput	dw	0			; next empty buffer location
ports	ends

	subttl	termfn - all the terminal and keyboard functions for mos
	page

tfn	dw	register
	dw	inkbdata
	dw	outkbctl
bgnvid	equ	($-tfn)/2
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
endvid	equ	($-tfn)/2
	dw	prch
	dw	prstr
	dw	print_status
endtfn	equ	($-tfn)/2

	subttl srterm - terminal function handler
	page
;======================================================================
;,fs
; srterm - terminal function handler
;
; the following is the drivers terminal function vector routine.  it has
; the function ffh (for the swrealram call) and necessary terminal calls
; it is designed similar to vnas handler.   the 3 bytes before handler
; (sah) are use for detection of driver.
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
	db	'SAH'			; author id for detection of driver
srterm proc far
	cmp	ah,0feh 		; check if fe function
	jne	sht0
	pushf
	cli
	push	word ptr [tcbseg]
	push	word ptr [ddtoff]
	push	word ptr [orges]
	mov	[tcbseg],ds
	mov	[ddtoff],si
	mov	[orges],es
	push	ds
	push	es
	mov	es,[workarea]
	push	cs
	pop	ds
	assume	ds:code
	push	ax
	xor	ax,ax			; switch all sunriver stations out
	mov	[curega],al
	call	switchega
	pop	ax
	pop	es
	pop	ds
	assume	ds:tcb

; we must now call the feh handle for the master console to switch
; out the ega for co-existence with vna

	push	bx
	push	ds
	lds	bx,[scbptr]
	assume	ds:scbs
	cmp	[bx+scbvnasys],'Y'
	jne	skipfe
	mov	ds,[bx+scbtcbpf]
	call	dword ptr [mcdriver]
skipfe:
	pop	ds
	pop	bx
shtfe2:
	jmp	short srtout
sht0:
	cmp	ah,0ffh 		; is this switch real ram call
	jne	sht1
	pushf
	cli
	assume	ds:nothing
	push	word ptr [tcbseg]
	push	word ptr [ddtoff]
	push	word ptr [orges]
	mov	[tcbseg],ds
	mov	[ddtoff],si
	mov	[orges],es
	push	ds
	push	es
	mov	es,[workarea]

; do swrealram processing - switch in channel or master console
; depending of value in port record (0 is master console

	call	bankin
	assume	 ds:nothing
	pop	es
	pop	ds
srtout:
	pop	word ptr [orges]
	pop	word ptr [ddtoff]
	pop	word ptr [tcbseg]
	popf
	ret
sht1:
	mov	[tcbseg],ds
	mov	[ddtoff],si
	mov	[orges],es		; save necessary state for restoration
	push	ds
	push	es
	mov	es,[workarea]

; following is use for normal terminal function

	assume	ds:tcb
	cmp	byte ptr [si].port,0	; if on master console, use master
	je	sht3
	or	ah,ah			; is this register call
	jnz	sht4a
	call	bankin			; for a bankin
	jmp	short sht5
sht4a:
	cmp	ah,endtfn		; if not a srterm function, use master
	jae	sht2			; this should take account of fe fun
	cmp	ah,bgnvid		; if function is video function
	jb	sht5			; use the master console
	cmp	ah,endvid
	jae	sht5
sht4:
	cmp	ah,4			; for set cursor type or set cursor
	je	sht2
	cmp	ah,5
	jne	sht3
sht2:
	call	bankin			; bank task in
sht3:
	cmp	byte ptr [si].port,0
	je	sht6
	cmp	ax,0a07h
	je	termfn1
sht6:
	push	cs
	pop	ds
	assume	ds:code
	call	master			; call the master console driver
	mov	cs:[orges],es
	jmp	short termfn1
sht5:
	assume	ds:nothing
	push	bp
	push	ds
	mov	ds,[tcbseg]
	assume	ds:tcb
	mov	bp,bx
	mov	bl,ah
	xor	bh,bh
	shl	bx,1
	xchg	bx,bp
	push	si
	call	tfn[bp] 		; call driver function
	pop	si
	pop	ds
	assume	ds:code
	pop	bp
termfn1:
	pop	es
	mov	es,cs:[orges]
	pop	ds
	ret
srterm endp

	subttl register - register port address, receive key buffer flag
	page
;======================================================================
;,fs
; register - register port address, receive key buffer flag
;
; in:	ah = 00h
;	dx = port address
;	ds:si -> tcbddt for this terminal for this partition
;
; out:	es:bx -> key buffer flag
;	 key buffer flag is <> 0 while scan codes are buffered
;	al = 80h if master console
;	   = 00h if not master console
;	ah = 0 if no error
;	   = 1 if bad port number
;	   = 2 if bad baud rate
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
register proc near
	push	ds
	mov	bl,byte ptr [si].port	; get port
	xor	bh,bh
	or	bx,bx
	jnz	reg1
regabort:
	pop	ds			; got a bad port....sorry
	mov	ah,1
	ret
reg1:
	dec	bx
	mov	ax,ds
	push	cs
	pop	ds
	assume	ds:code
	call	taskptr 		; get pointer to task
	jnz	reg2
	jmp	regabort
reg2:
	cmp	word ptr [bx].taskid,0ffffh  ; test if already allocated
	jne	regabort
	push	word ptr [curega]

; the following logical will cause the host adapter to generated a
; poweron interupt for the terminal desired. this has been added so
; that when task is added that we are assured that a physical terminal
; is actually on the station

	push	ax
	push	bx
	push	dx
	mov	dx,[rearm]
	out	dx,al
	mov	al,[bx].termid
	inc	ax
	pushf
	cli
	mov	[curega],al
	call	switchega
	stall
	stall
	or	byte ptr es:[modereg],04h  ; turn switch on
	push	es
	mov	es,[workswt]
	mov	byte ptr es:[resetsys],al  ; reset the terminal
	pop	es
	and	byte ptr es:[modereg],not 04h  ; turn switch off
	popf
	push	cx
	xor	cx,cx			; stall awhile...give it time
	loop	$
	pop	cx
	pop	dx
	pop	bx
	pop	ax
	test	[bx].status,active	; is status card available
	jnz	reg3
	jmp	regbad
reg3:
	test	[bx].status,online	; is stations on line
	jnz	reg4
	jmp	regbad
reg4:
	mov	[bx].taskid,ax		; allocated
	pop	ax			; pop	word ptr [curega]
	pop	ds
	push	ds
	push	ax			; push	word ptr [curega]
	assume	ds:tcb

; initialize master console ddt record

	mov	[si].dcpherc,'N'
	mov	[si].dcmode,3
	mov	[si].dcvmode,3
	mov	[si].dcpcrs,25*256
	mov	[si].dcpcol,80
	mov	[si].dcaddr,03d4h
	mov	[si].dcpscr,0b800h
	mov	[si].dcpscrl,80*25*2
	mov	[si].dcbios,1
	mov	[si].dcsnow,0

; call old unregister call into local storage...this allows for chaining

	push	cx
	push	si
	push	di
	push	es
	push	cs
	pop	es
	lea	si,[tcbunreg]
	lea	di,[bx].unreg
	mov	cx,2
	cld
	rep	movsw
	pop	es
	pop	di
	pop	si
	pop	cx

; set keyboard ready flag

	lea	bx,[bx].kbready 	; setup keyboard ready flag
	mov	[orges],cs

; set unregister call

	mov	word ptr [tcbunreg],offset unregister
	mov	word ptr [tcbunreg+2],cs

; set video initialization routine

	mov	word ptr [tcbvidset],offset vidinit
	mov	word ptr [tcbvidset+2],cs
	mov	ax,00ech		; mc, graphics, ali, no video io
	jmp	short	regend
regbad:
	mov	ah,1			; bad port
regend:
	pop	word ptr [curega]
	push	ax
	push	cs
	pop	ds
	assume	ds:code
	mov	al,[curega]
	call	switchega
	pop	ax
	pop	ds
	assume	ds:tcb
	mov	cx,0b800h		; physical buffer address for srterm
	ret				;   (stuffed into tcbvidad)
register endp

	subttl inkbdata - input keyboard scan code
	page
;======================================================================
;,fs
; inkbdata - input keyboard scan code
;
; in:	ah = 01h
;	ds:si -> tcbddt
;
; out:	al = bit 7   - key break if 1, key make or key repeat if 0
;	     bits 6-0 - key scan code 01h - 07dh
;	key scan code is read non-destructively
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
inkbdata proc near
	mov	bx,ds
	push	ds
	push	cs
	pop	ds
	assume	ds:code
	call	findptr 		; get task structure
	jnz	insklp
	xor	al,al
	pop	ds
	ret
insklp:
	cmp	[kbbios],'Y'		; skip this if kbbios not support
	jne	kbdat0
	cmp	cx,dx			; cx must equal dx
	jne	kbdat0
	cmp	dh,-1			; dh must be 0ffh
	jne	kbdat0
	push	dx
	push	di
	push	es
	mov	es,[workmap]
	mov	al,dl
	mov	di,bx
	shl	di,1
	call	setleds
	pop	es
	pop	di
	pop	dx
kbdat0:
	mov	al,byte ptr cs:[bx].kbready
	or	al,al
	jz	notinsk 		; any keys ready
	push	si
	mov	si,word ptr cs:[bx].kbget
	mov	al,byte ptr cs:[bx+si].kbbuff
	pop	si
notinsk:
	pop	ds
	ret
inkbdata endp

	subttl outkbctl - clear current scan code from terminal driver
	page
;======================================================================
;,fs
; outkbctl - clear current scan code from terminal driver
;
; in:	ah = 02h
;	al = bit 7 - clear buffered scan code if 1, ignored if 0
;	     bits 6-0 - ignored
;	ds:si -> tcbddt
;
; out:
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
outkbctl proc near
	test	al,80h
	jz	outend
	push	ds
	mov	bx,ds
	push	cs
	pop	ds
	assume	ds:code
	call	findptr 		; point by tcb
	jz	outsk
	push	si
	pushf
	cli
	mov	al,byte ptr cs:[bx].kbready
	or	al,al
	je	gk2
	mov	si,word ptr cs:[bx].kbget
	inc	si
	cmp	si,kbsize		; buffer above max
	jb	gk1
	xor	si,si			; set it to beginning
gk1:
	mov	word ptr cs:[bx].kbget,si
	cmp	si,word ptr cs:[bx].kbput  ; any keys ready
	jne	gk2
	mov	byte ptr cs:[bx].kbready,00h  ; indicate that no keys are
gk2:
	popf
	pop	si
	pop	ds
	ret
outsk:
	xor	ax,ax
	pop	ds
outend:
	ret
outkbctl endp

	subttl prch - print a character on the terminal's local printer
	page
;======================================================================
;,fs
; prch - print a character on the terminal's local printer
;
; in:	ah = 10h
;	al = char to print
;	ds:si -> tcbddt
;
; out:	returns ah as in int 17h call
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
prch proc near
	call	prchar			; call lowlevel routine
	ret
prch endp

	subttl prstr - print a string on the terminal's local printer
	page
;======================================================================
;,fs
; prstr - print a string on the terminal's local printer
;
; in:	ah = 11h
;	es:di -> string to print
;	cx = length (bytes) to print
;	ds:si -> tcbddt
;
; out:	returns ah as in int 17h call if all of string can't be printed
;	di -> first char not printed, cx = number not printed
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
prstr proc near
	push	si
	push	di
	push	ds
	mov	ds,[orges]
	mov	si,di
	push	cx
prstrlp:
	lodsb
	call	prchar
	test	ah,1h
	jnz	prserr
	loop	prstrlp
	pop	di			;dis-regraud saved cx
	pop	ds
	pop	di
	pop	si
	ret
prserr:
	pop	di			; get old cx in di
	push	ax
	mov	ax,di
	sub	ax,cx			; calculate # printer so far
	dec	si
	mov	di,si
	pop	ax
	pop	ds
	pop	si			; old di value
	pop	si
	ret
prstr endp

	subttl print_status - printer status
	page
;======================================================================
;,fs
; print_status - printer status
;
; for the non-sherwood case, where a good printer status is 
; imediately available the fresh-flag will be returned as 1.  
; when mosint17 sees the fresh-flag come back as 1 when the 
; entry al == 0, it will know that there is no need to call getkeys. 
;
; in:	al = 0 to initiate a status request
;	   = 1 to check the status and fresh-flag
;	bx = 0  (caller should use this value anyway)
;
; out:	ah = status as in int17fun02
;	al = the state of the fresh-flag (always 1)
;	bx = 0f3c9h  (signature to verify this function is supported)
;
;,fe
;=====================================================================
print_status proc near
	push	es
	mov	es,[workmap]
	mov	ah,byte ptr es:[parstatus]  ; get printer status
	and	ah,0f8h 		; clear unused bits
	xor	ah,048h			; invert signals
	mov	al,1
	mov	bx,0f3c9h
	pop	es
	ret
print_status endp 


	subttl unregister - un-register task with driver
	page
;======================================================================
;,fs
; unregister - un-register task with driver
;
; called by a far call to tcbunreg
;
; in:	ds -> tcb when called
;
; out:
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
unregister proc far
	push	ax
	push	bx
	push	si
	push	ds

; now do unregister of sunriver driver variable

	mov	bx,ds
	push	cs
	pop	ds
	assume	ds:code
	call	findptr
	jz	unr2
	mov	al,byte ptr [bx].status ; get status
	and	al,active		; set only active
	mov	si,word ptr [bx].termid
	call	initcvars		; initialize termianl variables
unr1:

; do the unregister chaining by calling next call on the
; list if not zero

	pop	ds
	pop	si
	cmp	word ptr cs:[bx+2].unreg,0
	je	unr2
	call	dword ptr cs:[bx].unreg
unr2:
	pop	bx
	pop	ax
	ret
unregister endp

	subttl bankin - switch in the desired station
	page
;======================================================================
;,fs
; bankin - switch in the desired station
;
; in:	ds -> tcb when called
;
; out:
;
;,fe
;=====================================================================
	assume	ds:tcb,es:nothing,ss:nothing
bankin proc near
	pushf
	cli
	push	ax
	push	bx
	push	ds
	lds	bx,cs:[scbptr]
	assume	ds:scbs
	mov	ax,[bx+scblastff]	; check scblastff
	or	ax,ax
	jz	bankcont		; skip feh call if noone in
	mov	bx,ds
	cmp	ax,bx
	jne	bankstart
	pop	ds			; optimize if same bank
	pop	bx
	pop	ax
	popf
	ret
bankstart:
	pop	ds
	push	ds
	assume	ds:tcb
	push	ax
	push	es
	mov	es,ax
	assume	ds:nothing,es:tcb
	mov	ax,word ptr [tcbcondd]	; if last terminal driver is not
	mov	bx,word ptr [tcbcondd+2]; as same as us than we will need
	assume	ds:tcb,es:nothing	; to call their feh handle
	cmp	ax,word ptr [tcbcondd]
	jne	bankdiff
	cmp	bx,word ptr [tcbcondd+2]
bankdiff:
	pop	es
	pop	ax
	je	bankcont
	mov	ds,ax
	assume	ds:tcb
	lea	si,[tcbcondd]
	mov	ah,0feh 		; bank out last station
	call	dword ptr [si]
bankcont:
	pop	ds
	mov	cs:[savlast],ds
	pop	bx
	mov	al,byte ptr [si].port
	cmp	word ptr [tcbcondd],offset srterm
	je	banknvna

; this is special case handle for co-existence with vna style
; workstations, when vna calls what it believes is the master
; console but actually it will be pointing to srterm.sys handler

	push	cs
	pop	ds
	assume	ds:code
	xor	al,al
	mov	[curega],al		; bank all sunrivers out
	call	bankswitch
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	lds	bx,[scbptr]		; unmap all area use by
	assume	ds:scbs 		; sunriver
	cmp	byte ptr [bx+scbvnasys],'Y'
	jne	skipvna
	mov	word ptr [bx+scbtcbvr],0
	mov	word ptr [bx+scbtcbvs],0
	pop	ds
	assume	ds:code
	mov	dx,0a000h
	mov	cx,32			; unmap all of memory
	xor	al,al
	call	dword ptr [mapvma]
skipvna:
	pop	di
	pop	si
	pop	dx
	pop	cx
	mov	ah,0feh
	call	master
	jmp	short bankout
banknvna:
	push	cs
	pop	ds
	assume	ds:code
	mov	[curega],al
	call	switchega		; do the actual switch
	push	bx
bankout:
	push	ds
	lds	bx,scbptr
	assume	ds:scbs
	mov	ax,[savlast]
	mov	[bx+scblastff],ax	; set lastff to tcb
	pop	ds
	pop	bx
	pop	ax
	popf
	ret
bankin endp

	subttl bankswitch - low-level context switcher for sunriver
	page
;======================================================================
;,fs
; bankswitch - low-level context switcher for sunriver
;
; this routine switch the host adapter to desired station, master
; console if port is 0 or greater than maximun terminals on system.
; derives the desired channel values (for stations, 1 less than the
; port), ffh for master console
;
; in:	al = port address
;	es = points to host adapter's status and control registers
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
bankswitch proc near
	pushf
	cli
	xor	ah,ah
	cmp	ax,[maxterm]
	ja	swega0
	or	al,al
	jnz	swega1
swega0:
	mov	ax,256			; diable all channels
swega1:
	dec	ax
swega2:
	call	getchan
	call	dochan			; set channel
	cmp	al,0ffh
	je	swega2a
	and	byte ptr es:[modereg],not 04h  ; turn offswitching
swega2a:
	popf
	ret
bankswitch endp

	subttl switchega - actual context switcher for sunriver host adapter
	page
;======================================================================
;,fs
; switchega - actual context switcher for sunriver host adapter
;
; this routine switch the host adapter to desired station, master
; console if port is 0 or greater than maximun terminals on system.
; this routine does the following steps:
;	1. call low-level routine bankswitch to switch station in
;	2. switch in the video
;	3. if master console, call mosddtmc's ffh routine
;
; note: this is where special case handling of vga cards will be handle
;
; in:	al = port address
;	es = points to host adapter's status and control registers
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
switchega proc near
	push	ax
	call	bankswitch
	call	mapvid			; map in video
	cmp	ax,-1
	jne	swega3
	pop	ax
	jmp	short swega4a
swega3:
	cmp	al,0ffh 		; was this a master console call
	pop	ax
	jne	swega5
swega4:
	push	ax
	mov	ah,0ffh 		; call mosddtmc ff routine
	call	master
	pop	ax
	mov	es,[workarea]
swega4a:

; this is being done on the master console

	cmp	byte ptr [vgabios],'Y'	; vga bios used
	jne	swega7
	push	ax			; this logic for enable the vga
	mov	al,0eh			; enable host vga
	jmp	short swega6
swega5:

; this is being done on sunriver station

	cmp	byte ptr [vgabios],'Y'
	jne	swega7
	push	ax			; this code is use to disable the vga
	mov	al,06h			; disable host vga
swega6:

; do out 46e8h depend on station

	push	dx			; this is the way sunriver\paradise
	mov	dx,46e8h		; the special cable
	out	dx,al
	pop	dx
	pop	ax
swega7:
	ret
switchega endp

	subttl mapvid - map in desired video
	page
;======================================================================
;,fs
; mapvid - map in desired video
;
; this routine is use to map in 128k between a000h and c000h, it use
; the special scbmapvma calls which are designed so that drivers like
; the sunriver driver can map it physical memory management needs and
; still have multible mouse support.
;
; in:	al = channel to map in (0 - maxterm - 1 or ffh for master
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
mapvid proc near
	push	bx
	push	es
	les	bx,cs:[scbptr]
	assume	es:scbs
	cmp	byte ptr [bx+scbbankin],'N'
	je	mvexit
	mov	word ptr [bx+scbtcbvr],0
	mov	word ptr [bx+scbtcbvs],0
	push	ax
	push	cx
	push	dx
	mov	cx,2			; to record in list base
	mov	bx,cs
	mov	[actvid],al
	cmp	ax,[maxterm]
	jae	mvmc

; map in the physical memory at f10,000h into the region
; between a0000h and c0000h

	and	byte ptr es:[modereg],not 04h
	mov	al,3			; make list base call
	lea	dx,listsr		; point to list
	call	dword ptr [mapvma]
	jmp	short mvexit1
mvmc:
	mov	al,3			; make list base call
	lea	dx,listmc		; point to list
	call	dword ptr [mapvma]
mvexit1:
	pop	dx
	pop	cx
	pop	ax
mvexit:
	pop	es
	pop	bx
	ret
mapvid endp

	subttl irqhnd - sunriver irq handle
	page
;======================================================================
;,fs
; irqhnd - sunriver irq handle
;
; the following is sunriver driver irq handler.  it is use to control
; the following functions for the terminal.
;	1. power on interupt -- terminal will send one of these when
;	   some turns on the stations or when the host driver request
;	   one.  the register command uses this feature to reconized
;	   if terminal is actually there.
;	2. keyboard interupt -- this is use when a user presseds a key
;	   on the stations keyboard.
;	3. video interupt - this is use for ega vertical scan interupt
;	4. serial port interupts - these are use to control the serial
;	   ports on the terminal.
;	5. parallel port interupt -- these are use control printers off
;	   the back of the terminal
;	6. timer interupt -- for the speaker on terminal
;
; the basic functionality of the handler is to find out which station
; and type of interupt cause the interupt and service it.
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
irqhnd proc far
	cli
	pusha
	push	ds
	push	es
	mov	bx,cs
	mov	ds,bx
	assume	ds:code
	mov	es,[workarea]
	push	word ptr [curega]
	xor	si,si
	inc	si
	mov	ax,si
	call	bankswitch
	mov	es,[workarea]
	dec	si
irqloop:
	mov	ax,si
	call	dochan			; set channel
	test	byte ptr es:[intcontrol],04h  ; check if bit 2 is low
	jz	irqtest
irqnext:
	inc	si
	inc	si
	cmp	si,[maxterm]
	jbe	irqloop
irqiret:
	jmp	irqfin
irqtest:
	mov	byte ptr es:[intlatch],al  ; send any data to irq latch
	mov	al,byte ptr es:[chanid] ; get channel id
	mov	byte ptr [saveid],al
	call	calcmask
	shl	bx,1			; point to time out
	test	al,bl
	jnz	irqfound
	jmp	short irqtmout
irqnxt:
	inc	si
	call	calcmask
	shl	bx,1
	test	al,bl			; test for timeout
	jz	irqtmout2		; is this a timeout
	shr	bx,1
	test	al,bl			; test for irq
	jz	irqcont 		; has channel have an  irq
	dec	si
	jmp	irqnext
irqtmout2:
	dec	si
irqtmout:
	mov	bl,[saveid]
	not	bl
	call	clearbit		; clear timeout bit
	jmp	irqfin
irqfound:
	shr	bx,1			; point irq flag
	test	al,bl
	jnz	irqnxt
irqcont:
	mov	bx,si
	push	bx
	push	di
	mov	al,bl
	call	dochan			; set channel
	mov	[station],bx		; save station pointer
	and	byte ptr es:[modereg],not 04h
	mov	[station],bx		; save station pointer
	call	taskptr 		; get task pointer
	jz	irqnot
	mov	di,bx			; save it in di for calls
	mov	bl,byte ptr es:[devicereg]
	xor	bh,bh
	shl	bx,1
	call	[irqfun+bx]
	or	byte ptr es:[modereg],04h
	push	es
	mov	es,[workswt]
	mov	al,byte ptr es:[resetintrq]  ; reset interupt
	pop	es
	and	byte ptr es:[modereg],not 04h
irqnot:
	pop	di
	pop	bx
	call	calcmask
	mov	al,bl
	not	al
	cmp	al,[saveid]		; dual-interupt sitiution
	jne	irqcskip
	pushf				; not dual-interupt, so we
	cli				; we need so set chanid and
	and	byte ptr es:[chanid],al ; continue on
	jmp	short irqexit1
irqcskip:

; if we come here, we have 2 stations off of a single chip interupting
; concurrently, this means that we must handle both interupts

	cmp	[once],'Y'		; has it came through once already
	je	irqonce 		; yes...on second port of chip

; at this point we are done with one of the 2 ports on chip, and must do
; it now for the other port

	mov	[once],'Y'
	mov	si,[station]		; get current station
	xor	si,01h			; toggle low bit for other station
	jmp	irqcont 		; continue
irqonce:

; at this point we done with both stations on dual-interupt system
; and must not set channel id and acknoledge the stations
; notice: it is very important that both stations are acknolodge at
; the time when channel id is reset

	mov	[once],'N'
	pushf
	mov	al,[saveid]
	mov	byte ptr es:[chanid],al ; reset channel id register
	call	ackterm 		; acknolodge current station
	mov	si,[station]
	xor	si,01h			; toggle to other station
	mov	ax,si
	call	dochan			; activate other station
irqexit1:

; we will now acknologe station, we can come here via 2 methods
;     1. by a single port being interupted (from jump above irqcskip)
;     2. by other port on dual-interupt condition (see above)

	call	ackterm
	popf
irqfin:
	pop	word ptr [curega]
	mov	al,[curega]
	xor	ah,ah
	call	bankswitch

; rearm sunriver controller

	cli
	mov	dx,[rearm]
	out	dx,al			; set global re-arm
	call	resetsr
	pop	es
	pop	ds
	assume	ds:nothing
	popa
	iret
irqhnd endp

	subttl calcmask - irq support function
	page
;======================================================================
;,fs
; calcmask - irq support function
;
; in:	si = channel
;
; out:	bx = bit mask
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
calcmask proc near
	mov	bx,0001h
	test	si,0001h
	jz	cmdone
	shl	bx,1
	shl	bx,1
cmdone:
	ret
calcmask endp

	subttl clearbit - clears the bit in channel id register
	page
;======================================================================
;,fs
; clearbit - clears the bit in channel id register
;
; in:	bl = bit to mask out
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
clearbit proc near
	push	ax
	mov	al,bl
	not	al
	and	byte ptr es:[chanid],al
	pop	ax
	ret
clearbit endp

	subttl resetsr - reset the master and slave interupt controllers
	page
;======================================================================
;,fs
; resetsr - reset the master and slave interupt controllers
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
resetsr proc near
	mov	dx,0020h
	mov	al,dl
	cmp	byte ptr [irq],0fh
	jbe	irqlow
	mov	dx,00a0h
	out	dx,al			; re-arm slave
	stall
	stall
	mov	dl,al
irqlow:
	out	dx,al
	stall
	ret
resetsr endp

	subttl power - power on interrupt
	page
;======================================================================
;,fs
; power - power on interrupt
;
; used when station does a power on interupt - status online
; (driver specific) is turn on by this routine and task can not
; be added onless this bit is on.
;
; in:	di -> to station specific task info
;	es -> control registers.
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
power proc near
	or	byte ptr [di].status,online  ; indicate station is on
	push	es
	mov	es,[workmap]
	mov	byte ptr es:[parcontrol],08h  ; init printer
	push	cx
	mov	cx,8000h		; stall a little bit
	loop	$
	pop	cx
	mov	byte ptr es:[parcontrol],0ch
	pop	es
	or	byte ptr es:[modereg],04h  ; turn switch on
	push	es
	mov	es,[workswt]
	mov	byte ptr es:[resetintrq],00h
	mov	byte ptr es:[bankselreg],08h
	mov	byte ptr es:[bankselreg],00h
	pop	es
	and	byte ptr es:[modereg],not 04h  ; turn switch off
	ret
power endp

	subttl keybd - station's keyboard handler
	page
;======================================================================
;,fs
; keybd - station's keyboard handler
;
; put the the key scan codes into the driver 32 byte keyboard
; buffer in task information table.
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
keybd proc near
	push	ax
	push	cx
	push	si
	push	es
	mov	es,[workmap]
	call	kbwout
	mov	byte ptr es:[keycmdinp],0adh  ; disable keyboard
	xor	cx,cx
	pushf
	cli
kbd1:
	mov	ah,byte ptr es:[keystatus]
	test	ah,1			; outfull full
	loopz	kbd1
	mov	al,byte ptr es:[keydatainp]  ; get data
	cmp	al,0feh 		; resend
	je	kbd2
	cmp	al,0fah 		; achnolodge
	jne	kbd3

; do keyboard achnolodge

	jmp	kbover
kbd2:

; do keyboard resend

	jmp	kbover
kbd3:
	cmp	al,0ffh 		; overrun.....
	je	kbover
	cmp	byte ptr [di].kbready,00h  ; any characters
	je	kbempty
	push	si
	mov	si,word ptr [di].kbget
	cmp	si,word ptr [di].kbput	; overflow in buffer
	pop	si
	je	kbover
kbempty:
	mov	byte ptr [di].kbready,0ffh  ; flag keyboard ready flag
	mov	si,word ptr [di].kbput	; get point to que
	push	di
	add	di,si
	mov	byte ptr [di].kbbuff,al
	pop	di
	cmp	[kbbios],'Y'
	je	skipkb
	call	doleds			; handle leds on station
skipkb:
	inc	si
	cmp	si,kbsize		; test to see if over limit
	jb	kbset
	xor	si,si
kbset:
	mov	word ptr [di].kbput,si	; save new pointer
kbover:
	call	kbwout
	mov	byte ptr es:[keycmdinp],0aeh  ; enable keyboard
	popf
	pop	es
	pop	si
	pop	cx
	pop	ax
	ret
keybd endp

	subttl doleds - set the keyboard status leds on the keyboard
	page
;======================================================================
;,fs
; doleds - set the keyboard status leds on the keyboard
;
; done by checking the 40:17 status save in the tcb as
; tcbkshft (this is necessary because keyboard irq could and will get
; get call when another task is switch into memory).  if status is
; is different that prevous saved status, then the routine will access
; memory map area to change the leds.
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
doleds proc near
	push	ax
	push	es
	mov	es,word ptr [di].taskid ; get tcb for station
	assume	es:tcb
	mov	al,tcbkshft		; get keyboard status
	pop	es
	assume	es:nothing
	call	setleds
	pop	ax
	ret
doleds endp

	subttl setleds - lowlevel routine supporting 40:17 modifications
	page
;======================================================================
;,fs
; setleds - lowlevel routine supporting 40:17 modifications
;
; in:	al = value at 40:17
;	di = pointer to sun structure
;	es = segment of port area
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setleds proc near
	shr	al,4			; format it for the output
	and	al,7			; to keyboard
	cmp	al,byte ptr [di].kbstat ; same as saved?
	jne	dleds
	ret
dleds:

; we must now change the keyboard leds

	mov	byte ptr [di].kbstat,al
	mov	byte ptr es:[keydatainp],0edh
	call	kbwout
	call	keyack			; wait for ack
	mov	al,byte ptr [di].kbstat
	mov	byte ptr es:[keydatainp],al  ; set byte to keyboard
	call	keyack			; wait for ack
	call	kbwout
skipled:
	ret
setleds endp

	subttl keyack - used by doleds to check for ack from keyboard
	page
;======================================================================
;,fs
; keyack - used by doleds to check for ack from keyboard
;
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
keyack proc near
	push	cx
	mov	cx,8000h
kaloop:
	mov	al,byte ptr es:[keydatainp]  ; get data
	cmp	al,0fah 		; is it ack
	loopnz	kaloop			; loop if not
	pop	cx
	ret
keyack endp


	subttl ser1 - serial support function
	page
;======================================================================
;,fs
; ser1 - serial support function
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
ser1 proc near
	push	dx
	xor	dx,dx			; point to first port
	jmp	short sercom
ser2:
	push	dx
	mov	dx,1			; point to second port
sercom:
	call	doisr			; call isr routine
	pop	dx
	ret
ser1 endp

par:
time:
egasys:
	ret

	subttl initkb - initialize keyboard controller
	page
;======================================================================
;,fs
; initkb - initialize keyboard controller
;
; used to initial the stations keyboard controller so
; that it will send scan codes to host adapter which will generate
; irq so that driver can place the scan code into the keyboard buffer
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initkb proc near
	push	ax
	push	cx
	push	es
	mov	es,[workmap]
	call	kbwout
	mov	byte ptr es:[keycmdinp],0aah  ; reset keyboard controller
	call	kbwout
	mov	byte ptr es:[keycmdinp],060h
	call	kbwout
	mov	byte ptr es:[keydatainp],049h  ; setup keyboard controller
	call	kbwout
	mov	byte ptr es:[keycmdinp],0aeh  ; enable keyboard controller
ikbend:
	pop	es
	pop	cx
	pop	ax
	ret
initkb endp

	subttl kbwout - wait for output buffer is empty
	page
;======================================================================
;,fs
; kbwout - wait for output buffer is empty
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
kbwout proc near
	xor	cx,cx
kbwl:
	mov	ah,byte ptr es:[keystatus]
	test	ah,2
	loopnz	kbwl
	ret
kbwout endp

	subttl enableega, disableega - vga only for enabling and disable vga
	page
;======================================================================
;,fs
; enableega, disableega - vga only for enabling and disable vga
;
; enableega means to disable vga, disableega means to enable vga
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
enableega proc near
	mov	al,1
	jmp	short enableit
disableega:
	xor	al,al
enableit:
	push	ds
	or	byte ptr es:[modereg],04h
	mov	ds,cs:[workswt]
	mov	byte ptr ds:[egaenable],al
	and	byte ptr es:[modereg],not 04h
	pop	ds
	ret
enableega endp

	subttl vidinit - video initialization routine
	page
;======================================================================
;,fs
; vidinit - video initialization routine
;
; this routine is pointed by tcbvidset and is use to set up the terminal
; when the task's context is finally inplace.
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
vidinit proc far
	pusha
	push	ds
	push	es
	push	cs
	pop	ds
	push	word ptr [curega]
	mov	bx,es
	call	findptr
	jne	vicont
	jmp	viskip
vicont:
	inc	ax
	mov	[curega],al
	mov	es,[workarea]
	call	switchega
	call	initkb

; the following code is to enable vga display on vga stations
; this is necessary because the folks at sunriver disable the
; display when display is first power up.

	cmp	byte ptr [vgabios],'Y'
	je	vivga
	jmp	viega
vivga:
	push	dx
	push	es
	pushf
	push	ds
	mov	cx,-1
	loop	$
	mov	ds,[workmap]
	call	enableega
	mov	byte ptr ds:[03c2h],00h
	call	disableega
	mov	es,cs:[workswt]
	mov	bx,cs:[baseaddr]
	add	bx,4			; point to 5 bank
	mov	cx,1
	mov	ah,5
	call	dword ptr cs:[memman]
	mov	byte ptr es:[46e8h-4000h],10h
	mov	byte ptr ds:[102h],01h
	mov	byte ptr es:[46e8h-4000h],08h
	mov	bx,cs:[baseaddr]
	add	bx,10h
	mov	cx,1
	mov	ah,5
	call	dword ptr cs:[memman]
	mov	es,[workarea]
	mov	al,byte ptr ds:[3ceh]
	mov	al,byte ptr ds:[3ceh]
	mov	byte ptr ds:[3ceh],0fh
	mov	byte ptr ds:[3cfh],05h
	mov	byte ptr ds:[3ceh],0eh
	mov	byte ptr ds:[3cfh],00h
	mov	byte ptr ds:[3ceh],0dh
	mov	byte ptr ds:[3cfh],00h
	mov	byte ptr ds:[3ceh],0ch
	mov	byte ptr ds:[3cfh],00h
	call	enableega
	mov	byte ptr ds:[3c2h],00h
	call	disableega
	mov	al,byte ptr ds:[3dah]
	mov	al,byte ptr ds:[3bah]
	mov	byte ptr ds:[3c0h],20h
	pop	ds
	popf
	pop	es
	pop	dx
viega:
	call	enable
	mov	ax,0303h
	call	master
	mov	es,[workarea]
	pop	word ptr [curega]
	mov	al,[curega]
	call	switchega
viskip:
	pop	es
	pop	ds
	popa
	ret
vidinit endp

	subttl master - call ddtmc
	page
;======================================================================
;,fs
; master - call ddtmc
;
; used to call mosddtmc master console routines if necessary
; by driver. notice that es will change during this call and
; must be handle correctly
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
master proc near
	push	si
	push	ds
	mov	es,[orges]		; get original es value
	mov	ds,[tcbseg]		; get ds:si
	mov	si,[ddtoff]
	push	ds
	push	si
	assume	ds:tcb
	call	dword ptr cs:[mcdriver] ; call mosddtmc
	pop	word ptr [ddtoff]
	pop	word ptr [tcbseg]
	pop	ds
	pop	si
	ret
master endp

	subttl ackterm - rearm controller
	page
;======================================================================
;,fs
; ackterm - rearm controller
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
ackterm proc near
	pushf
	cli
	or	byte ptr es:[modereg],04h  ; turn switch on
	push	es
	mov	es,[workswt]
	mov	byte ptr es:[rearmcontrol],al  ; rearm control
	pop	es
	and	byte ptr es:[modereg],not 04h  ; turn switch off
	popf
	ret
ackterm endp

	subttl taskptr - return task pointer to internal table
	page
;======================================================================
;,fs
; taskptr - return task pointer to internal table
;
; assumes that task structure is 16 bytes
;
; in:	bx = task id = 0 - max - 1
;
; out:	bx = ffffh (if error)
;	bx = offset into table
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
taskptr proc near
	cmp	bx,[maxterm]
	jae	tperr
	push	ax
	shl	bx,4			;  offset = srtab + (id)*48
	mov	ax,bx
	shl	ax,1
	add	bx,ax
	pop	ax
	add	bx,offset srtab
	cmp	bx,-1			; clear zero flag
	ret
tperr:
	mov	bx,-1			; indicated error
	cmp	bx,-1			; set zero flag
	ret
taskptr endp

	subttl findptr - find task pointer in drivers data structures
	page
;======================================================================
;,fs
; findptr - find task pointer in drivers data structures
;
; in:	bx = tcb of task (taskid)
;
; out:	ax = terminal id
;	bx = task id (or ffffh if not found)
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
findptr proc near
	push	cx
	push	si
	mov	si,offset srtab
	mov	cx,[maxterm]
fploop:
	cmp	cs:[si].taskid,bx	; is this the task
	je	fpfound
	add	si,30h			; assume that structure if 48 bytes
	loop	fploop
	mov	bx,-1			; not found - indicate error
	jmp	short fpdone
fpfound:
	xor	bh,bh
	mov	bl,cs:[si].termid
	mov	ax,bx			; place termid in ax
	mov	cx,bx
	shl	bx,1
	add	bx,cx			; bx=termid*3
	shl	bx,4			; bx = bx * 16 (termid*48)
	add	bx,offset srtab
fpdone:
	pop	si
	pop	cx
	cmp	bx,-1			; if not found - set zero flag
	ret
findptr endp

	subttl prchar - print a character to local printer
	page
;======================================================================
;,fs
; prchar - print a character to local printer
;
; in:	al = character to print
;
; out:	ah = printer status
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
prchar proc near
	push	cx
	push	es
	mov	es,[workmap]
	mov	byte ptr es:[pardata],al; write byte to port
	mov	cx,14h
pcloop1:
	push	cx
	xor	cx,cx
pcloop2:

; test to see if port is busy

	test	byte ptr es:[parstatus],80h
	jnz	pcok
	loop	pcloop2
	pop	cx
	loop	pcloop1
	mov	al,byte ptr es:[parstatus]  ; get printer status
	mov	ah,al
	and	ah,0f8h 		; clear unused bits
	or	ah,1			; set error
	jmp	short pcdone
pcok:

; printer is not busy and character printed

	pop	cx
	mov	byte ptr es:[parcontrol],0dh  ; strobe high
	jmp	short $+2
	jmp	short $+2
	mov	byte ptr es:[parcontrol],0ch  ; strobe low
	mov	al,byte ptr es:[parstatus]  ; get printer status
	mov	ah,al
	and	ah,0f8h
pcdone:
	xor	ah,48h			; invert signals
	pop	es
	pop	cx
	ret
prchar endp

	subttl dochan - set channel, wait until channel is not busy
	page
;======================================================================
;,fs
; dochan - set channel, wait until channel is not busy
;
; in:	al = channel to set ah=0
;	es = segment fo work area
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
dochan proc near
	cmp	[dochval],0ffh
	je	dochan3
	push	cx
	mov	cx,-1
dochan1:
	test	byte ptr es:[irqsel],4
	jz	dochan2
	loop	dochan1
dochan2:
	pop	cx
dochan3:
	mov	[dochval],al
	mov	byte ptr es:[chansel],al
	ret
dochan endp

	subttl getchan - get current channel from curega
	page
;======================================================================
;,fs
; getchan - get current channel from curega
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
getchan proc near
	mov	al,[curega]
	or	al,al
	jz	gcmc
	xor	ah,ah
	cmp	ax,[maxterm]
	ja	gcmc
	dec	ax
	ret
gcmc:
	mov	ax,255
	ret
getchan endp

	subttl enable - turn on the stations ega io mappings
	page
;======================================================================
;,fs
; enable - turn on the stations ega io mappings
;
; turns on the stations ega io mappings so that outs to ega
; register will go to station physical memory at base
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
enable proc near
	cmp	[vgabios],'Y'
	jne	doenable
	ret
doenable:
	pushf
	push	ax
	push	es
	cli
	or	byte ptr es:[modereg],04h  ; turn switch memory on
	mov	es,[workswt]
	or	byte ptr es:[egaenable],01h
	mov	al,byte ptr es:[actintrq]
	pop	es
	and	byte ptr es:[modereg],not 04h  ; turn switch memory off
	pop	ax
	popf
	ret
enable endp

	subttl chantest - see if channel is present
	page
;======================================================================
;,fs
; chantest - see if channel is present
;
; used to test to see if channel is present during init
; time - notice that i said channel and not station.  station presince
; is taking place during the register call when a reset to station is
; done.
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
chantest proc near
	push	ax
	mov	ax,si
	mov	byte ptr es:[chansel],al; set channel
	mov	byte ptr es:[modereg],0fch  ; set mode to fch
	cmp	byte ptr es:[modereg],04h  ; if not 04h - channel fail
	jne	ctfail
	mov	byte ptr es:[modereg],01h  ; set to mode 1
	clc				; success
	jmp	ctdone
ctfail:
	stc				; failed
ctdone:
	pop	ax
	ret
chantest endp

	subttl initcvars - initialize the channel specific variables
	page
;======================================================================
;,fs
; initcvars - initialize the channel specific variables
;
; in:	al = status to set channel to
;	bx = pointer to task information table
;	si = terminal id
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
initcvars proc near
	mov	word ptr [bx].termid,si
	or	byte ptr [bx].status,al
	mov	word ptr [bx].taskid,-1 ; no task is added yet
	xor	ax,ax			; clear ax value below
	mov	byte ptr [bx].kbready,al
	mov	word ptr [bx].kbput,ax
	mov	word ptr [bx].kbget,ax
	ret
initcvars endp

	include vidchk.inc

	subttl boot_prep - prepare the video state for a reboot
	page
;======================================================================
;,fs
; boot_prep - prepare the video state for a reboot
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
boot_prep proc near
	mov	es,[workarea]
	xor	ax,ax
	mov	[curega],al		; make sure master console is switchin
	call	switchega
	ret
boot_prep endp

	subttl farpatch - call memman
	page
;======================================================================
;,fs
; farpatch - call memman
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
farpatch proc far
	cmp	cx,8
	ja	farskip
	mov	es,dx
	call	dword ptr cs:[memman]
farskip:
	ret
farpatch endp

; the following include statement are for installing of mos
; generalize int 14 code, suniomac.inc is definitions of macros
; which is use in the sunriver case

	include suniomac.inc
	include int14.inc
	include isrsub.inc

	subttl clr_set_irq - dummy (only needed by _serial.asm)
	page
;======================================================================
;,fs
; clr_set_irq - dummy (only needed by _serial.asm)
;
; in:	ch = 0 to clear, 1 to set
;	cl = irq number
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
clr_set_irq proc near
	ret
clr_set_irq endp

	subttl sckport - verify serial port existance
	page
;======================================================================
;,fs
; sckport - verify serial port existance
;
; used by int 14 main logic to verify is port actually exist on
; the sunriver work station returns zero if not online
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
sckport proc near
	push	ax
	push	bx
	mov	bx,[scdx]		; get port
	shr	bx,1
	shl	bx,4			;  offset = srtab + (port/2)*48
	mov	ax,bx
	shl	ax,1
	add	bx,ax
	test	byte ptr cs:[bx+srtab].status,online
	pop	bx
	pop	ax
	ret
sckport endp

	subttl doisr - isr routines for accessing com ports
	page
;======================================================================
;,fs
; doisr - isr routines for accessing com ports
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
doisr proc near
	pusha
	push	ds
	push	es
	pushf
	cld				; make sure direction flag is clear
	cli
	push	cs
	pop	ds
	assume	ds:code
	mov	bx,[station]		; get station
	shl	bx,1			; 2 ports per station
	add	bx,dx			; take account of which port
	mov	cl,5
	shl	bx,cl			; each port structure is 32 bytes
	add	bx,[portoff]
	mov	dx,[bx].addr
	or	dx,dx
	jle	disisr			; is port disable
	mov	[isrcount],maxisr
isrloop:
	dec	[isrcount]
	push	dx
	rdiir
	test	al,noint		; is it interupting
	jnz	noisr
	mov	[isrcount],0
	and	ax,0fh			; keep only lower 4 bits
	mov	si,ax
	call	inttbl[si]		; call interupt routine
	pop	dx
	jmp	short	disisr
noisr:
	pop	dx
	cmp	[isrcount],0
	jne	isrloop
disisr:
	popf
	pop	es
	pop	ds
	popa
	ret
doisr endp

	subttl ddtinit - mos device driver init
	page
;======================================================================
;,fs
; ddtinit - mos device driver init
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
ddtinit proc near
	push	bx
	push	es
	call	initddt
	jnc	okmos
	jmp	derror
okmos:
	assume	es:scbs

; test for memory managemnet

	cmp	[bx+scbmmfg],'Y'	; memory management use
	je	mmok
	mov	dx,offset nomm
	jmp	derror
mmok:
	call	clinetest		; command line test
	jc	derror1
	call	mastertest		; test for master console driver
	jc	derror1
	call	egatest 		; test for ega
	jnc	okega			; ega bios!
derror1:
	jmp	derror
okega:
	call	setmmptr		; setup mm pointer

; detect if sunriver host adapter is on system

	mov	es,[workarea]
	call	initsun
	cmp	[maxterm],0
	jne	okhost
	mov	dx,offset nohost
	jmp	derror
okhost:
	call	install14		; install int 14 handler
	push	es
	mov	ah,2
	pushf
	call	[orig38]
	assume	es:scbs

; get kbbios parameter

	cmp	byte ptr es:[bx+scbkbbios],'Y'
	jne	nobios
	mov	[kbbios],'Y'
nobios:
	pop	es
	assume	es:nothing

; initial host adapter and data area

	mov	ax,[maxterm]		;\
	mov	ah,al			; \
	shl	ah,1			;  [maxterm * 3]
	add	al,ah			; /
	xor	ah,ah			;/
	shl	ax,1
	shl	ax,1
	shl	ax,1			;   [maxterm * 3]*16
	shl	ax,1			;	+ srtab
	mov	[srsize],ax
	push	cs
	pop	es
	mov	cx,ax
	shr	cx,1
	xor	ax,ax			; initialize table to zeros
	mov	di,offset srtab
	rep	stosw

; initialize serial int 14 data area

	lea	ax,srtab+15
	add	ax,[srsize]
	mov	cl,4			; calculate startsegment of
	shr	ax,cl			; serial data area
	mov	cx,cs
	add	ax,cx
	mov	[sportseg],ax		; save it
	mov	es,ax

; calculate start of buffer area
; ie startseg = sportseg + [maxterm] * 2

	mov	ax,[maxterm]
	shl	ax,1
	add	ax,[sportseg]
	mov	si,ax

; now loop through all of data structures, initializing necessary
; bytes and all of the rest to zero

	mov	dx,03f8h		; first port is com1
	xor	di,di
	mov	cx,[maxterm]
	shl	cx,1			; remember 2 ports
iploop:
	push	cx
	push	di
	xor	ax,ax
	mov	cx,16
	rep	stosw
	pop	di
	mov	word ptr es:[di].addr,dx; save port
	or	word ptr es:[di].addr,8000h  ; disable port
	dec	dh
	cmp	dh,1h			; toggle bettween port
	ja	ipport			; 03f8 and 02f8h
	mov	dh,3h
ipport:
	mov	word ptr es:[di].ibfseg,si
	mov	word ptr es:[di].ibfsiz,isize
	add	si,(isize/16)
	mov	word ptr es:[di].obfseg,si
	mov	word ptr es:[di].obfsiz,osize
	add	si,(osize/16)
	pop	cx
	add	di,32
	loop	iploop
	mov	[endofdata],si

; initialize serial related data

	mov	cx,cs
	mov	ax,[sportseg]
	sub	ax,cx
	shl	ax,1
	shl	ax,1
	shl	ax,1			; convert segment to offset
	shl	ax,1
	mov	[portoff],ax		; save port offset
	mov	ax,[maxterm]
	shl	ax,1			; 2 com ports per station
	mov	[numport],ax

; setup listsr (list base memory) table for baseaddress other that 0f0,0000

	cmp	[baseaddr],0f00h
	je	slistsr
	mov	bx,[baseaddr]
	sub	bx,0f00h
	add	[asr1],bx
	add	[asr2],bx
slistsr:

; initialize sunriver hardware now

	mov	es,[workarea]
	call	mapio
	xor	al,al
	mov	byte ptr es:[chansel],al
	mov	bl,byte ptr es:[irqsel]
	and	bl,03h
	shl	bl,1
	mov	bh,bl
	shl	bh,1
	add	bl,bh
	xor	bh,bh			; mult by 6 to get table entry
	mov	al,byte ptr [irqtab+bx] ; get irq
	mov	[irq],al
	mov	ax,word ptr [irqtab+bx+1]  ; get re-arm port address
	mov	[rearm],ax
	mov	ax,word ptr [irqtab+bx+3]  ; get ascii irq value
	mov	word ptr [irqst],ax
	mov	al,byte ptr [irqtab+bx+5]  ; get irq mask
	mov	[irqmask],al
	mov	bx,[maxterm]
insloop:
	mov	si,bx
	push	bx
	dec	si
	dec	bx
	call	taskptr 		; get offset to task structure
	jz	insskip
	call	chantest
	jc	insfail
	mov	al,active		; mark it as active
	pushf
	cli
	call	enable
	popf
insfail:
	call	initcvars
insskip:
	pop	bx
	dec	bx
	jnz	insloop
	jmp	ddtinok
derror:
	push	dx
	mov	dx,offset ninsmsg
	mov	ah,9
	int	21h
	pop	dx
	int	21h			; display approviated message
	mov	dx,[errout]
	mov	ah,9
	int	21h
	pop	es
	pop	bx
	mov	word ptr [srname],'\\'	; can't be opened
	mov	word ptr es:[bx+14],offset request
	mov	es:[bx+16],cs
	ret
ddtinok:
	mov	dx,offset insmsg
	mov	ah,9
	int	21h
	mov	dx,offset warea
	mov	ah,9
	int	21h
	mov	ax,[maxterm]
	xor	dx,dx
	div	[wordten]
	or	ax,ax
	jnz	ddtin1
	mov	al,' '
	jmp	ddtin2
ddtin1:
	add	al,'0'
ddtin2:
	mov	ah,dl
	add	ah,'0'
	mov	word ptr [statmsg],ax
	mov	dx,offset statmsg
	cmp	byte ptr [statmsg],' '
	jne	ddtdisp
	inc	dx
ddtdisp:
	cmp	[vgabios],'Y'
	je	dovga
	mov	byte ptr [vgamsg],'E'
dovga:
	push	dx
	mov	dx,offset vermsg
	mov	ah,9
	int	21h
	mov	dx,offset vgamsg
	mov	ah,9
	int	21h
	pop	dx
	mov	ah,9
	int	21h
	mov	dx,offset irqmsg
	mov	ah,9
	int	21h
alldone:

; activate selected irq

	xor	ax,ax
	mov	es,ax
	mov	bl,[irq]
	xor	bh,bh
	shl	bx,1
	shl	bx,1
	mov	ax,word ptr es:[bx]
	mov	word ptr [oldirq],ax
	mov	ax,word ptr es:[bx+2]
	mov	word ptr [oldirq+2],ax
	lea	ax,irqhnd
	cli
	mov	word ptr es:[bx],ax
	mov	word ptr es:[bx+2],cs
	sti
	cmp	byte ptr [irq],0fh
	ja	highirq
	cli
	in	al,21h
	stall
	and	al,[irqmask]
	out	21h,al
	jmp	endirq
highirq:
	cli
	in	al,0a1h
	stall
	and	al,[irqmask]
	out	0a1h,al
endirq:
	sti

; set vidcheck routine for pam switching and reboot

	push	bx
	mov	ah,2
	int	services
	assume	es:scbs
	mov	word ptr es:[bx+scbvidchk],offset vidchk
	mov	word ptr es:[bx+scbvidchk+2],cs
	pop	bx

; set master console to us and arm controler

	mov	es,[mctcb]
	assume	es:tcb
	or	[tcbvram],0ch		; set sunriver interface
	mov	word ptr [tcbcondd.port],0
	mov	word ptr [tcbcondd],offset srterm
	mov	word ptr [tcbcondd+2],cs
	push	dx
	mov	dx,[rearm]
	out	dx,al
	pop	dx
	pop	es
	pop	bx
	push	bx
	mov	ax,[endofdata]
	mov	bx,cs
	sub	ax,bx
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	pop	bx
	mov	word ptr es:[bx+14],ax
	mov	es:[bx+16],cs
	mov	ax,0100h
	ret
ddtinit endp

	subttl mapio - map in the stations io
	page
;======================================================================
;,fs
; mapio - map in the stations io
;
; this routine does the following mapping:
;	1. maps control register at base + f000h to workarea
;	2. maps switch memory at base + 10000h to workarea + 400h
;	3. maps registers at base to work area + 800h
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
mapio proc near
	push	ax
	push	bx
	push	cx
	mov	bx,[baseaddr]
	add	bx,00fh
	mov	cx,1
	mov	ah,5
	call	dword ptr [memman]
	push	es
	mov	bx,[baseaddr]
	mov	es,[workswt]
	add	bx,010h
	mov	cx,1
	mov	ah,5
	call	dword ptr [memman]
	mov	es,[workmap]
	mov	bx,[baseaddr]
	mov	cx,1
	mov	ah,5
	call	dword ptr [memman]
	pop	es
	call	getchan
	call	dochan			; set channel
	cmp	al,0ffh
	je	mapio1
	and	byte ptr es:[modereg],not 04h  ; turn offswitching
mapio1:
	pop	cx
	pop	bx
	pop	ax
	ret
mapio endp

statmsg db	' 0 SunRiver Stations detected on system.         ',13,10,'$'  ;@@xlat
insmsg	db	'installed with work area at $       '	;@@xlat
warea	db	'nnnn0H.',13,10,'$'
ninsmsg db	'not installed.      ',13,10,'$'  ;@@xlat
nohost	db	'SunRiver Host Adapter$        '  ;@@xlat
errmsg	db	' is required for SRTERM to function correctly.        ',13,10,'$'  ;@@xlat
crlf	db	13,10,'$'
irqmsg	db	'IRQ '
irqst	db	' 0 Selected for station interupt control            ',13,10,'$'  ;@@xlat
vgamsg	db	'VGA System Detected.',13,10,'$'  ;@@xlat
vermsg	db	'Version 2.10 (910403) - $'  ;@@xlat

errout	dw	offset errmsg
wordten dw	10
srsize	dw	0

	subttl - init code which is removed from driver at run time
	page

; the following label srtab must be the last byte in the object code
; this is where driver places the dynamic task structure.  init
; code could be place down here to reduce total size of drivers
; code in the smp.

srtab	label	byte

; the following messages are overlay with srtab data

nomm	db	'Memory Mangement Driver$      '  ;@@xlat
noega	db	'EGA Bios$       '	;@@xlat
nowork	db	'Correct Work Area address$      '  ;@@xlat
badmos	db	'PC-MOS Rel 4.00 or greater$        '  ;@@xlat
ddtmsg	db	13,10,'SunRiver EGA terminal device driver $        '  ;@@xlat
twice	db	'SRTERM should not be loaded twice!$        '  ;@@xlat
nmouse	db	'SRTERM must be loaded before PC-MOS MOUSE driver$               '  ;@@xlat

	subttl clinetset - command line test
	page
;======================================================================
;,fs
; clinetset - command line test
;
; test command line for work space address
;
; in:
;
; out:	return carry set if entry is bad
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
clinetest proc near
	les	bx,dword ptr [request]
	les	bx,dword ptr es:[bx + 18]  ; get parameter pointer
scan1:
	inc	bx
	mov	al,es:[bx]		; scan for blank
	cmp	al,0dh
	jne	scan1a
	jmp	scandone		; return terminates
scan1a:
	cmp	al,20h
	jne	scan1			; repeat until blank
scan2:
	inc	bx			; scan for non-blank
	cmp	byte ptr es:[bx],' '
	je	scan2
	cmp	byte ptr es:[bx],'0'
	je	scan2
	cmp	byte ptr es:[bx],0ah
	jne	scan2a
	jmp	scandone
scan2a:
	xor	dx,dx			; zero work address
	xor	cx,cx
	xor	ah,ah
	lea	di,warea
scan3:
	mov	al,byte ptr es:[bx]	; get hex value
	inc	bx
	cmp	al,'0'
	jb	scanchk
	cmp	al,'9'
	ja	scanhex
	sub	al,'0'
	jmp	scannext
scanhex:
	cmp	al,'a'
	jb	scanhex2
	cmp	al,'f'
	ja	scanchk
	sub	al,'a'-10
	jmp	scannext
scanhex2:
	cmp	al,'A'
	jb	scanchk
	cmp	al,'F'
	ja	scanchk
	sub	al,'A'-10
scannext:				; adjust value
	shl	dx,1
	shl	dx,1
	shl	dx,1
	shl	dx,1
	add	dx,ax
	cmp	al,10
	jb	scanlow
	add	al,'A'-10
	jmp	scanout
scanlow:
	add	al,'0'
scanout:
	mov	cs:[di],al
	inc	di
	inc	cx
	cmp	cx,4
	jb	scan3
scanchk:
	cmp	cx,4			; for bytes
	jne	scanbad
	cmp	dx,0c000h		; can't be lest than c000h
	jb	scanbad
	mov	ax,dx			; check for 4k bondary
	and	ax,0ff00h
	cmp	ax,dx
	je	scangood
scanbad:
	stc
	mov	dx,offset nowork
	ret
scandone:
	mov	dx,0ec00h		; default to ec000h
	mov	word ptr cs:[warea],'CE'
	mov	word ptr cs:[warea+2],'00'
scangood:
	mov	[workarea],dx		; save work area
	add	dx,0100h
	mov	[workswt],dx		; set switch memory
	add	dx,0100h
	mov	[workmap],dx		; set map memory
	clc
	ret
clinetest endp

	subttl mastertest - get master console driver
	page
;======================================================================
;,fs
; mastertest - get master console driver
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:code,es:nothing,ss:nothing
mastertest proc near
	lds	bx,cs:[scbptr]		; point to scb
	assume	ds:scbs
	push	bx
	push	ds
	mov	ds,[mctcb]
	assume	ds:tcb
	lds	bx,[tcbcondd]
	cmp	word ptr [bx-3],'AS'	; chech if loaded twice
	jne	not2x
	cmp	byte ptr [bx-1],'H'
	jne	not2x
	mov	word ptr [errout],offset crlf
	mov	dx,offset twice
	stc
	jmp	short mtexit
not2x:
	mov	word ptr [mcdriver],bx
	mov	word ptr [mcdriver+2],ds
	clc
mtexit:
	pop	ds
	pop	bx
	push	cs
	pop	ds
	assume	ds:nothing
	ret
mastertest endp

	subttl egatest - detect if ega is on system
	page
;======================================================================
;,fs
; egatest - detect if ega is on system
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
egatest proc near
	push	ds
	mov	ds,cs:[mctcb]
	assume	ds:tcb
	mov	al,[tcbstation] 	; get station of master console tcb
	pop	ds
	cmp	al,5			; ok if monochrome ega (5)
	je	etok
	cmp	al,2			; error is below ega (2)
	jb	etbad
	je	etok			; ok if equal to ega
	cmp	al,6			; ok if monochrome vga (6)
	je	etvga
	cmp	al,3			; error if above vga (3)
	ja	etbad
etvga:
	mov	cs:[vgabios],'Y'	; set flag to indicate that we have vga
etok:
	clc
	ret
etbad:
	stc
	mov	dx,offset noega 	; return error message address
	ret
egatest endp

	subttl setmmptr - setup memory manager pointer
	page
;======================================================================
;,fs
; setmmptr - setup memory manager pointer
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
setmmptr proc near
	push	cs
	pop	es
	lds	bx,cs:[scbptr]
	assume	ds:scbs
	lea	si,[bx+scbmmsub]
	lea	di,memman
	mov	cx,2
	rep	movsw
	lea	si,[bx+scbmapvmf]
	lea	di,mapvma
	mov	cx,2
	rep	movsw
	push	cs
	pop	ds
	assume	ds:code
	ret
setmmptr endp

	subttl initsun - init sun river hardware
	page
;======================================================================
;,fs
; initsun - init sun river hardware
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initsun  proc near
	push	bx
	push	si
	mov	bx,0f00h
isunlp:
	call	isun1
	add	bx,0040h
	cmp	bx,0fc0h
	jb	isunlp
	pop	si
	pop	bx
	ret
isun1:
	push	ax
	push	bx
	push	word ptr [baseaddr]
	mov	[baseaddr],bx
	call	mapio
	pop	word ptr [baseaddr]
	xor	si,si
	mov	byte ptr es:[chansel],00h
isun2:
	call	chantest
	jc	isun3
	mov	[baseaddr],bx		; save base address
	inc	[maxterm]
	inc	[maxterm]
	mov	byte ptr es:[modereg],01; set mode to 1
	mov	byte ptr es:[intlatch],al  ; write data to latch
	mov	al,byte ptr es:[chanid]
	mov	byte ptr es:[chanid],00h; set channel reg to 00
	mov	byte ptr es:[intcontrol],01  ; set int cntrl reg to 1
	jmp	isun4
isun3:
isun4:
	inc	si
	inc	si
	cmp	si,maxid
	jb	isun2
	pop	bx
	pop	ax
	ret
initsun  endp

	subttl initddt - ddt init logic
	page
;======================================================================
;,fs
; initddt - ddt init logic
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
initddt proc near
	push	cs
	pop	ds
	call	patchmos		; patch mos
	jc	initexit
	call	chkmouse		; check for mouse  driver
	jc	nomouse
	mov	word ptr [errout],offset crlf
	lea	dx,nmouse		; display mouse error
	stc
	jmp	initexit
nomouse:
	mov	ah,02h
	int	services
	assume	es:scbs
	mov	[scbseg],es
	mov	[scboff],bx
	mov	dx,[bx+scbtcbpf]	; get foreground tcb
	mov	[mctcb],dx		; save it for later
	clc
initexit:
	pushf
	push	dx
	lea	dx,ddtmsg
	mov	ah,9
	int	21h
	pop	dx
	popf
	ret
initddt endp

	subttl patchmos - patch mos if necessary.
	page
;======================================================================
;,fs
; patchmos - patch mos if necessary.
;
; return error message if not atleast pc-mos/386 rel 4.00
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
patchmos proc  near
	mov	ah,30h
	int	21h			; get dos version
	push	ax
	mov	ah,30h
	mov	bx,ax
	mov	cx,ax
	mov	dx,cx
	int	21h			; get mos version
	pop	cx
	cmp	ax,cx
	je	patchbad
	cmp	al,04h
	jb	patchbad
	clc
	ret
patchbad:

if version
	stc
	mov	dx,offset badmos
else
	clc
endif

	ret
patchmos endp

	subttl chkmouse - check for mouse
	page
;======================================================================
;,fs
; chkmouse - check for mouse
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
chkmouse proc near
	push	ds
	push	cs
	pop	ds
	lea	dx,[moudriver]
	mov	ax,3d00h
	int	21h
	pop	ds
	ret
chkmouse endp

	subttl install14 - install int14 handler
	page
;======================================================================
;,fs
; install14 - install int14 handler
;
; in:
;
; out:
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
install14 proc near
	mov	ah,6			; check to see if int 14 handler, already
	xor	dx,dx
	int	14h			; is install, if not then install our handler
	test	ah,80h			; test high bit to see if installed
	jz	setint14

; if we come here this means that we must link our driver in as child

	push	es
	push	cs
	pop	es
	lea	bx,int14		; register child with serial driver
	mov	ah,10h
	int	14h
	pop	es
	jmp	short donein14

; this is were we would install our int 14 handler

setint14:
	push	ds
	push	cs
	pop	ds
	lea	dx,int14		; install our int 14 handler
	mov	ax,2514h
	int	21h
	pop	ds
donein14:
	push	es
	push	bx
	mov	ax,3500h+services
	int	21h			; save 38 vector for serial logic
	mov	word ptr cs:[orig38],bx
	mov	word ptr cs:[orig38+2],es
	mov	ax,351ah
	int	21h			; save 1a vector for serial logic
	mov	word ptr cs:[orig1a],bx
	mov	word ptr cs:[orig1a+2],es
	pop	bx
	pop	es
	ret
install14   endp

if1
	%out - pass 1 completed.
else
	%out - pass 2 completed.
endif

code	ends
	end

