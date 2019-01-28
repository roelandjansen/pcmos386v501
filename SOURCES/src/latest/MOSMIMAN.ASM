	include page.inc
	title	 mosmiman - console middle manager
comment ^===============================================================
			development specification

 program name:	$$mos.sys		assigned to: david a. morrow
 module name:	mosmiman		assign date: 09/29/86
 entry points:	n/a			completed:
 entry from:	n/a
 entry method: 	n/a
 calls:	 	n/a
 purpose:	character pre-processor for console i/o
 last update:	08/18/1992
========================================================================

this driver is responsible for decoding and acting on special
keys for buffered input (func 0a and 3f (cooked)), and for expanding
tab codes to the next tab stop.

==== values for tcbconfg

  func	  echo	  wait	  expl	  min	 control  command code
  call	 tab(0)	  (1)	  l/f(2)  buf(3) keys(4)  for realcon
  ---	 -----	  ----	  ----	  ----	  ----	  -----------
  1	   1	   1	   1	   1	   1	   #4
  2	   1	   x	   x	   1	   1	   #8
  3	   x	   0	   x	   1	   1	   #5
  4	   x	   0	   x	   1	   1	   #5
  5	   x	   0	   x	   1	   1	   #5
  6 (inp) 0	   0/1	   1	   1	   0	   #5, (if key, #4)
  6 (out) 0	   x	   x	   1	   0	   #8, echo no tab
  7	   0	   1	   1	   1	   0	   #4
  8	   0	   1	   1	   1	   1	   #4
  9	   1	   x	   x	   1	   1	   #8
  0a	   1	   1	   0	   0	   1	   #4  note 1
  0b	   x	   0	   x	   1	   1	   #5
  3f (r)   0	   1	   1	   1	   0	   #4
  3f (c)   1	   1	   0	   1	   1	   #4  note 2


==== definition of control bits (tcbconfg)

echo/tab    bit # 0

when set, input keys will be echoed to the real con device and tabs
will be expanded on echo and on command #8 output.  when not set, no
echo (hence no tab expansion) on input.

explicit len/func keys and min buf	  bits # 2 and #3

when set, return when the specified number of bytes have been keyed
with no special treatment for extended codes.	when not set, the min
buf bit must also be tested.  if min buf is set (func 3f cooked
mode), then buffer up to 128 (including the cr) and append a lf to
the end.	if the request is >= 128 bytes, allow (request - 1)
bytes to be input before beeping.  a lf code must still be included
by sending it on the next call.  if less than (request - 1) bytes are
keyed, return the lf in that same call.  if min buf is not set (func
0a) don't append a LF code and use the requested length value no
matter what it is (1-ff).

control keys	 bit #4

when this bit is set, if a cntrl-c, cntrl-s, cntrl-p or cntrl-prtsc
is keyed,the appropriate action will be taken.  if not set, these
keys will be treated like any other keys.

updated: 07/26/88: made it work as intended.

note 1  function 0a pecularities:

no lf code is added, just the cr.  beep when reach the requested
length.  mosmiman will return a length which doesn't include the cr. 
max of 255 bytes (including the cr)

note 2  function 3f (cooked) pecularities:

since the minimum buffer bit is set, if the requested byte count is
less than 128, allow 127 bytes to be entered, with the cr
constituting the 128th.	on subsequent calls to 3f, return the
remainder of the buffered data.  an lf code will be returned, one way
or another.

=======================================================================

mjs 02/24/87	completed cooked and raw behavior

jsm 03/18/87	large volume support

mjs 03/31/87	modified printer echoing to match mods to mosint17

jsm 04/28/87	special handling for nul device

jsm 05/06/87	made cntrl-prtsc toggle printer like cntrl-p

sah 05/15/87	responces for esc, cntrl-pgup & cntrl-pgdn

sjc 10/19/87	optimization, local jump some macros

jsm 10/27/87	fixed buffinp to work in cases where user requests
		fewer characters than the system buffer contains.

sah 11/25/87	added clear input functionality (#7) to callcon to
		completed implement int 21 function 0ch

sah 01/20/88	change scbseg and zero seg access to mgetxxxx macros

rbr/sah 02/20/88 move ddt code to mo2 group.

rdg 07/08/88	ptr (0018)  rewrote readguts so that binary (raw)
		console i/o is handled properly.  optimized character
		device code between readguts and feof.

sah 07/26/88	change readguts so that if caller requests that control
		keys not to be acted on, test for tcbconfg to so that
		rest of logic will act correctly. also clean module up.

sah 07/29/88	place actuall test in buffinp so responce is better

sah 09/07/88	correct control-p responce by making sure it was flush
		during cdevoutp.

sah 11/10/88	enable switching while console output is being done.
		this corrects a problem with type of a large file will
		suspend all other tasks.  note this is only done which
		console output and any changes to console output where
		switching should be disable, one should should notice
		that this is one more possiablity where switching is on.

sah 12/03/88	modified readguts for the case where so that nowait
		would act correctly, before int 21 function 06 dl=ff
		would wait for key thus causing applications which call
		it to stall because they are waiting for a key.
		also removed dependency on mosscbex.inc

rkg 12/28/88	include macros.inc deleted macro definitions

rkg 02/23/89	truncating a file to zero length did not deallocate
		first cluster.	this gave directory/cluster error in
		verify. rkg020

mjs 10/10/89	modified sector size calculations.

bwr 11/29/89	marked messages for foreign language translation.

sah 04/04/90	corrections for readguts if reading binary mode on a
		device.

bwr 11/05/90	compatibility fix for corel cd-worm driver.  device
		driver being called with wrong request header length.
		due to some weird microsoft convention, the device
		header length field does not consider the volume id
		fields as part of the request header length for dos
		versions < 4.00.  for dos 4.0 or later, the entire
		header is included in the length field.
		the corel driver was deciding that the request
		header was a dos 4.00 request header based on the fact
		that the rh length was not 22 bytes, causing him to
		look for the starting sector number at a different
		location in the rh, and to make matters worse, he was
		looking for a double-word sector number at that
		location which was, of course, garbage.	 the side
		effect of all this wound up being a divide overflow
		condition within the driver.

sah 04/09/91	corrections for chineese characters sets, must call int
		10h function 3 directly instead of accessing tcbcpos

mjs 12/16/91	dlg mods: fixed bug in truncguts where the attribute within
		the cl register was getting crashed.

================ 5.01 Kernel Ends Here ====================================

mjs 05/22/92	modified the ms2a function to preserve ax, bx and cx.
		these registers being crashed was causing a system
		crash when someone would press cntrl-enter or cntrl-j
		during a read from a non-con character device 
		(e.g. $pipe.sys).
		updat501.sys version 0.01

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
;	include mosmiman.pub
	include group.inc
	include mosregs.inc
	include moscdb.inc
	include mosgfb.inc
	include mostfb.inc
	include mosrlb.inc
	include mosbdb.inc
	include macros.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends
.list

gdata	segment
	extrn scbstdcon:dword,scbkey:dword,scbnoswt:byte
	extrn scbstdin:dword,scbstdout:dword
gdata	ends

if 0 eq 0				; trick public.com

; error codes defined

invfn	equ	1			; invalid function (or sub-function)
filenf	equ	2			; file not found (or invalid name)
pathnf	equ	3			; path not found (or invalid path)
manyfil equ	4			; too many files open
accdeny equ	5			; access denied
invhdl	equ	6			; invalid handle (file not open)
invacc	equ	12			; invalid access code specified
drivenf equ	15			; drive not found (or invalid drive)
delcurd equ	16			; attempt to delete current directory
diffdev equ	17			; not the same device
nomore	equ	18			; no more files found
share	equ	32			; sharing violation
locke	equ	33			; lock violation
shareov equ	36			; share buffer overflow (couldn't alloc RLB)
filexst equ	80			; file already exists
fail24h equ	83			; fail chosen from int 24h (as defined by dos)
syshdl	equ	127 or 8000h		; attempt to dup or fdup a non-psp handle
xshare	equ	share or 8000h		; fail from int 24h sharing
xlock	equ	locke or 8000h		; fail from int 24h locking
err24h	equ	fail24h or 8000h	; fail error from int 24h (signal for moserror)
intern	equ	80ffh			; internal error

; directory entry fields

datr	equ	11			; offset of attribute byte
dclass0 equ	13			; offset of class byte
dtime	equ	22			; offset of time word
ddate	equ	24			; offset of date word
dsize	equ	28			; offset of size dword
dclust	equ	26			; offset of bof cluster word

; directory entry file attribute bits defined

override equ	80h			; dir search class level override
arch	equ	20h			; archive
dir	equ	10h			; directory
lbl	equ	08h			; label
sys	equ	04h			; system
hid	equ	02h			; hidden
ro	equ	01h			; read-only

; critical error coding

rdx	equ	00h			; read operation
wrx	equ	01h			; write operation

failx	equ	08h			; fail not allowed
retryx	equ	10h			; retry not allowed
ignorex equ	20h			; ignore not allowed
allx	equ	failx or retryx or ignorex
sysx	equ	failx or retryx		; ignore not allowed in system areas

dosx	equ	00h or allx		; dos area of disk?
fatx	equ	02h or sysx		; fat area
dirx	equ	04h or sysx		; dir area
datax	equ	06h or allx		; data area

cr	equ	0dh
lf	equ	0ah

endif

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume	cs:mo2,ds:nothing,es:nothing,ss:tcb

mosmiman label near

	public mosmiman

	extrn mosint10:near, writdev:near

; extrn's from MOSFUTIL.ASM

	extrn sbios2:word
	extrn iolock:near, getclust:near, blkread:near
	extrn decrypt:near, devwrite:near,alloclust:near, flushdir:near
	extrn getfat:near, putfat:near, dealloc:near, encrypt:near
	extrn blkwrite:near, classlvl:near, exclude:near, timestamp:near
	extrn rddir:near, wrsector:near, okchar:near, makelbl:near
	extrn devread:near, create:near, todriver:near, findtfb:near

; publics for mosfun0f and mosfun39

	public	readguts, writeguts, truncguts, creatguts, checkexon
	public	callcon, buffinp, cdevinp, cdevoutp

; the following are local subroutines used by the line editor

;======================================================================
;,fs
; doint10 - low overhead substitute for an int 10h call
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
doint10 proc
	push	es
	mgetzero2 es
	pushf
	call	dword ptr es:[10h*4]
	pop	es
	ret
doint10 endp

;======================================================================
;,fs
; echoprn
;
; in:	ds:si -> point to buffer
;	cx = # of bytes to send
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
echoprn proc
	push	ax
	push	cx
	push	dx
	push	si
	push	di
	push	es
	jcxz	epn2
	mov	bx,4			; handle for stdprn
	call	findtfb
	mov	ax,ds			; address buffer in ax:dx
	mov	dx,si
	mov	di,cx			; write length
	callmos1 writdev
epn2:
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret
echoprn endp

;======================================================================
;,fs
; callcon
;
; in:	es:bx -> point to buffer (only for 4 and 8)
;	cx = # of bytes requested (should be 1 for #5)
;	al = command #	(4,5 or 8) (sah include 7)
;
; out:	cx = returned count (for #5, cx = 1 if a char)
;	al = returned char (for #5 only, else undefined)
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lproc	callcon
lstring reqhead,26
	push	bx
	push	dx
	push	si
	push	di
	push	es
	push	ax
clc3:
	mov	byte ptr [reqhead], 22	; set rh length
	mov	byte ptr [reqhead+2],al ; set the command code
	mov	word ptr [reqhead+14],bx ; set xfer address
	mov	word ptr [reqhead+16],es ; (only need for 4,8 but won't
					 ; hurt to set for #5)
	mov	word ptr [reqhead+18],cx ; set xfer count
	push	ds
	mgetscb2 ds
	assume	ds:grp
	cmp	al,8
	je	clc2
	lds	si,[scbstdin]
	jmp	short clc2a
clc2:
	lds	si,[scbstdout]
clc2a:
	assume	ds:nothing
	push	ss
	pop	es
	lea	bx,[reqhead]
	mov	ah,80h
	xor	cx,cx
	call	todriver
	mov	cx,word ptr [reqhead+18]
	pop	ds
	pop	ax
	cmp	al,5			; command #5 ?
	jne	clc1
	mov	al,[reqhead+13]		; get the byte read
	mov	cx,1
	mov	bx,word ptr [reqhead+3] ; get status word
	test	bx,200h
	jz	clc1
	xor	cx,cx			; return cx = 0 to say no char ready
clc1:
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	bx

lundef	reqhead,26
lendp	callcon

;======================================================================
;,fs
; initdbuf
;
; initialize tcb%dbuf to blanks for use with tab expansion
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
initdbuf proc
	push	ax
	push	cx
	push	di
	lea	di,[tcb%dbuf]
	mov	cx,8
	mov	al,' '
	cld
	rep	stosb
	pop	di
	pop	cx
	pop	ax
	ret
initdbuf endp

;======================================================================
;,fs
; setindex
;
; set bp as an index to the proper save buffer
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
setindex proc
	xor	bp,bp			; set bp = 0 for function 0a
	test	[tcbconfg],8
	jnz	sin1
	ret				; set bp = 6 for function 3f
sin1:
	mov	bp,6
	ret
setindex endp

;======================================================================
;,fs
; indev
;
; read 1 char from the con device
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
indev proc
	push	bx
	push	cx
	mov	cx,1
	mov	al,4
	lea	bx,[tcb%dbuf]
	call	callcon
	mov	al,byte ptr [tcb%dbuf]
	pop	cx
	pop	bx
	ret
indev endp

;======================================================================
;,fs
; findtab
;
; in:	es:di -> start of buffer
;	cx = buffer length (must be > 0)
;
; out:	cx = countinuation count
;	when cx = 0, don't call again
;	es:di -> continuation point in buffer
;	ax = number of chars to send to display
;	bl = char at es:[di-1] (bl=9 when a tab was found)
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
findtab proc
	push	dx
	mov	dx,di
	mov	al,9			; scan for a tab code
	cld
	repne	scasb
	mov	bl,[di-1]
	je	ct1
	mov	ax,di			; no tabs found
	sub	ax,dx
	pop	dx
	ret
ct1:
	mov	ax,di			; calc number of chars passed
	sub	ax,dx
	dec	ax			; don't count the tab code
	pop	dx
	ret
findtab endp

;======================================================================
;,fs
; getcurpos
; 
; returns current cursor position in dx
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
getcurpos proc
	push	ax
	push	bx
	push	cx
	mov	ah,3
	mov	bh,[tcbpage]
	call	doint10			; get the cursor position
	pop	cx
	pop	bx
	pop	ax
	ret
getcurpos endp

;======================================================================
;,fs
; setcurpos
;
; sets the current cursor position from dx
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
setcurpos proc
	push	ax
	push	bx
	mov	bh,[tcbpage]
	mov	ah,2
	call	doint10			; set the cursor position
	pop	bx
	pop	ax
	ret
setcurpos endp

;======================================================================
;,fs
; calcexp
;
; supply a cursor position in dx, return tab expansion in cx
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
calcexp proc
	mov	cl,dl
	add	cl,8
	and	cl,0f8h			; calc next tab stop
	sub	cl,dl
	xor	ch,ch			; calc number of spaces to fill tab
	ret
calcexp endp

;======================================================================
;,fs
; odv1
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
odv1	proc				; internal subroutine for outdev
	push	ax			; cx=byte count ss:dx->buffer
	push	bx
	push	cx
	push	dx
	push	di
	push	es
odv2:
	test	[tcbconfg],8		; if set, echo stdout, else con
	jnz	odv2a
	or	[tcb%flgs],20h		; ignore printer echoing
	mov	bx,1			; handle for stdout
	call	findtfb			; echo to stdout for function 0a
	mov	ax,ss			; address buffer in ax:dx
	mov	di,cx			; write length
	callmos1 writdev
	and	[tcb%flgs],0dfh		; remove printer echo ignore flag
	jmp	odv2b
odv2a:					; echo to con
	mov	bx,dx
	mov	al,8
	call	callcon
odv2b:
	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
odv1	endp

;======================================================================
;,fs
; outdev
;
; test flag, if 0a, echo to stdout
; else echo to console.  tcb%ltc and ttc are set here
;
; in:	ss:dx -> buffer, 
;	cx = length.  
;	if bp <> 0, don't write to CON, just update ltc and ttc
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
outdev proc
	push	ax
	push	cx
	push	dx
	push	di
	mov	[tcb%ltc],0
	mov	[tcb%ttc],0
	mov	di,dx			; get buffer addressability with es:di
odv3:
	call	findtab
	push	cx
	mov	cx,ax
	jcxz	odv6
	call	odv1
odv6:
	add	dx,ax			; advance pointer past tab
	inc	dx
	cmp	bl,9
	jne	odv5
	push	dx
	call	getcurpos
	call	calcexp
	pop	dx
	add	[tcb%ltc],cx
	inc	[tcb%ttc]
odv4:
	call	initdbuf
	push	dx			; send cx blanks to fill out the tab
	lea	dx,[tcb%dbuf]
	call	odv1
	pop	dx
odv5:
	pop	cx
	or	cx,cx
	jnz	odv3
	pop	di
	pop	dx
	pop	cx
	pop	ax
	ret
outdev endp

;======================================================================
;,fs
; dispchar
;
;	echo the entered key.  use outdev so 0a/3f is managed
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
dispchar proc  near
	push	dx
	push	cx
	mov	byte ptr [tcb%dbuf],dl
	lea	dx,[tcb%dbuf]
	mov	cx,1
	call	outdev
	pop	cx
	pop	dx
	ret
dispchar endp

;======================================================================
;,fs
; dispcsstr
;
; in:	ds:dx -> string
;	cx = length
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
dispcsstr proc	near
	push	si
	push	ds
	jcxz	dcsdone
	push	cs
	pop	ds
	mov	si,dx
	cld
dcsloop:
	lodsb
	mov	dl,al
	call	dispchar
	loop	dcsloop
dcsdone:
	pop	ds
	pop	si
	ret
dispcsstr endp

;======================================================================
;,fs
; dispblanks
;
; send cx blanks.  use outdev so 0a/3f is managed
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
dispblanks proc	 near
	jcxz	db2
	push	dx
	push	cx
	call	initdbuf
	shr	cx,1
	shr	cx,1
	shr	cx,1			; divide count by 8
	lea	dx,[tcb%dbuf]
	jcxz	db1a
db1:
	push	cx
	mov	cx,8			; send 8 byte sets of blanks
	call	outdev
	pop	cx
	loop	db1
db1a:
	pop	cx
	push	cx
	and	cx,7			; check for a remainder
	jcxz	db2a
	call	outdev
db2a:
	pop	cx
	pop	dx
db2:
	ret
dispblanks endp

;======================================================================
;,fs
; linecursor
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
linecursor proc near
	push	ax
	push	cx
	mov	cl,[tcb%cbot]
	mov	ch,cl
	dec	ch
	mov	ah,1
	call	doint10
	pop	cx
	pop	ax
	ret
linecursor endp

;======================================================================
;,fs
; blockcursor
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
blockcursor proc near
	push	ax
	push	cx
	mov	ch,3
	mov	cl,[tcb%cbot]
	mov	ah,1
	call	doint10
	pop	cx
	pop	ax
	ret
blockcursor endp

;======================================================================
;,fs
; nupdcursor
;
; setup si for a normal call to updcursor
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
nupdcursor proc near
	push	si
	xor	si,si
	call	updcursor
	pop	si
	ret
nupdcursor endp

;======================================================================
;,fs
; updcursor
;
; update the cursor position based on tcb%ecol and the number
; of tabs in the buffer (si must be 0)
; this routine is also used to calc dlen for a special case in
; the insert char in mid buffer logic.  must save ecol, set ecol
; to blen+1 and set si<>0
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
bp2xy	proc	near			; internal subroutine for updcursor
	push	ax			; on entry bp = (ecol + stcl)
	push	bx			; on exit, dh = row, dl = col
	push	cx
	mov	ax,bp
	mov	bl,[tcbcols]
	xor	bh,bh
	cmp	ax,bx			; see if a wrap around is involved
	ja	bp2b
	mov	dx,bp
	dec	dx			; simple case, no wrap
	mov	dh,[tcb%nstln]
	jmp	bp2a
bp2b:					; special calcs because the cursor is wrapped
	xor	dx,dx
	div	bx			; ax = # of wraps
	mov	cx,ax
	mul	bx			; int(ecol/scw) * scw = # of cols in wraps
	mov	dx,bp
	sub	dx,ax			; calc offset in row
	dec	dx
	push	dx
	mov	ax,cx
	add	al,[tcb%nstln]		; add # of wraps to starting line #
	pop	dx
	mov	dh,al
bp2a:
	pop	cx
	pop	bx
	pop	ax
	ret
bp2xy	endp

;======================================================================
;,fs
; updcursor
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
updcursor proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	bp
	mov	bp,[tcb%ecol]
	mov	cx,bp
	mov	al,[tcb%stcl]
	xor	ah,ah
	mov	dx,ax
	add	bp,ax			; calc real row offset in bp
	lea	di,[tcb%ebuf]		; make es:di address the edit buffer
	dec	cx			; cx = ecol - 1 (# of chars to check for tabs)
	jcxz	uc1			; if ecol = 1, don't check for tabs
uc2:
	call	findtab
	cmp	bl,9
	jne	uc1			; no tabs found
	push	cx
	add	dx,ax
	inc	dx			; add 1 to account for the tab
	push	dx
	push	bp
	mov	bp,dx			; calc spaces for tab based on dx
	call	bp2xy			; which is a predictive real row offset
	pop	bp
	mov	ax,dx
	pop	dx
	mov	cl,al
	add	cl,8
	and	cl,0f8h			; calc next tab stop
	sub	cl,al
	xor	ch,ch			; calc number of spaces to fill tab
	dec	cx
	add	dx,cx
	add	bp,cx			; update real column offset
	pop	cx
	or	cx,cx
	jnz	uc2
uc1:
	or	si,si
	jz	uc7
	mov	al,[tcb%stcl]
	xor	ah,ah
	sub	bp,ax
	dec	bp
	mov	[tcb%dlen],bp		; special case, set dlen
	jmp	uc6
uc7:
	call	bp2xy
	call	setcurpos
	cmp	[tcb%insf],0ffh
	je	uc5
	call	linecursor		; set the cursor type
	jmp	uc6
uc5:
	call	blockcursor
uc6:
	pop	bp
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
updcursor endp

;======================================================================
;,fs
; calcdlen
;
; calc the length of the display line, return in cx
; note: only use this when tcb%nstln is current
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
calcdlen proc
	push	ax
	push	dx
	mov	al,[tcb%maxl]
	sub	al,[tcb%nstln]
	xor	ah,ah
	mov	cl,[tcbcols]
	xor	ch,ch
	mul	cx
	mov	cx,ax
	xor	ah,ah
	mov	al,[tcb%maxc]
	sub	al,[tcb%stcl]
	cbw
	add	cx,ax
	pop	dx
	pop	ax
	ret
calcdlen endp

;======================================================================
;,fs
; calctail
;
; calc the length of the display's tail to be erased
; return count in cx and update tcb%dlen, tcb%maxc and maxl
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
calctail proc
	push	ax
	push	bx
	push	dx
	call	getcurpos
	mov	[tcb%maxc],dl
	mov	[tcb%maxl],dh
	call	calcdlen
	mov	ax,cx
	mov	cx,[tcb%dlen]
	cmp	ax,cx
	ja	cta1
	sub	cx,ax
	jmp	cta2
cta1:
	xor	cx,cx			; (for up or down arrow, new line shorter)
cta2:
	mov	[tcb%dlen],ax
	pop	dx
	pop	bx
	pop	ax
	ret
calctail endp

;======================================================================
;,fs
; updstln
;
; update tcb%nstln (starting line) to manage cursor positioning
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
updstln proc

; need length of display line, but can't use CalcDlen since it
; relies on tcb%nstln.	an adjustment to tcb%nstln is what is being
; checked for here.

	mov	cx,[tcb%dlen]
	mov	bl,[tcb%stcl]
	xor	bh,bh
	add	cx,bx
	inc	cx
	cmp	cx,[tcb%stgc]		; is (line length + stcl) > stgc  ?
	jna	ups1
	mov	al,[tcbcols]		; yes, we did new wrap
	xor	ah,ah
	add	[tcb%stgc],ax		; update staging counter
	call	getcurpos
	cmp	dh,[tcb%lref]		; same line as original starting line ?
	jne	ups1
	dec	[tcb%nstln]		; update starting line to account for wrap
	mov	[tcb%lref],dh
	jmp	updstln
ups1:
	ret
updstln endp

;======================================================================
;,fs
; writechar
;
; write the char in ah into the current edit point of tcb%ebuf
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
writechar proc near
	push	bx
	lea	bx,[tcb%ebuf]
	add	bx,[tcb%ecol]
	mov	[bx-1],ah
	pop	bx
	ret
writechar endp

;======================================================================
;,fs
; updsbuf
;
; update the save buffer
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
updsbuf proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	call	setindex
	cmp	[tcb%blen],0
	jmpe	ua5			; skip if the edit buffer is empty
	mov	cx,[tcb%rs0a+bp]
	cmp	cx,[tcb%blen]
	jne	ua1c			; if lengths not equeal, save the line
	mov	si,[tcb%rp0a+bp]
	mov	si,[si]
	lea	di,[tcb%ebuf]
	cld
	repe	cmpsb
	jne	ua1c
	mov	bx,[tcb%cp0a+bp]	; if lengths match, compensate
	sub	bx,2			; pointers and skip saving
	cmp	bx,[tcb%rp0a+bp]
	jnb	ua1d
	or	bp,bp
	jnz	ua1e
	mov	bx,offset [topsb0a-2]
	jmp	ua1d
ua1e:
	mov	bx,offset [topsb3f-2]
ua1d:
	mov	[tcb%cp0a+bp],bx	; update current pointer for next time
	jmp	ua5
ua1c:
	cmp	[tcb%rs0a+bp],0
	jmpe	ua3			; jmp if the save buffer is empty
ua2:
	mov	bx,[tcb%rp0a+bp]	; calc free space in buffer
	mov	ax,[bx]
	add	ax,[tcb%rs0a+bp]
	sub	bx,ax
	sub	bx,2			; bx is now free size for new line
	jnc	ua2a
	xor	bx,bx			; must have been only 1 byte left!
ua2a:
	cmp	bx,[tcb%blen]
	jae	ua1
	lea	bx,[topsb0a-4]		; remove the oldest entry from the buffer
	or	bp,bp
	jz	ui1
	lea	bx,[topsb3f-4]
ui1:
	mov	si,[bx]
	lea	di,[tcb%sb0a]
	or	bp,bp
	jz	ui2
	lea	di,[tcb%sb3f]
ui2:
	mov	dx,si
	sub	dx,di			; calc adjustment factor
	mov	bx,[tcb%rp0a+bp]
	mov	cx,[bx]
	add	cx,[tcb%rs0a+bp]
	sub	cx,si
	cld
	rep	movsb			; shift the data
	lea	di,[topsb0a-2]
	or	bp,bp
	jz	ui3
	lea	di,[topsb3f-2]
ui3:
	mov	si,di
	sub	si,2
	std
	mov	cx,di
	sub	cx,[tcb%rp0a+bp]
	shr	cx,1
	rep	movsw
	add	[tcb%rp0a+bp],2		; update the root pointer
	mov	si,[tcb%rp0a+bp]
ua6:
	sub	[si],dx			; apply adjustment factor to
	add	si,2			; each pointer
	or	bp,bp
	jnz	ui4
	cmp	si,offset [topsb0a]
	jne	ua6
	jmp	ua2
ui4:
	cmp	si,offset [topsb3f]
	jne	ua6
	jmp	ua2
ua1:
	mov	bx,[tcb%rp0a+bp]	; add the new entry
	mov	di,[bx]
	add	di,[tcb%rs0a+bp]
	sub	bx,2
	jmp	ua4
ua3:					; set up for first time
	lea	bx,[topsb0a-2]
	lea	di,[tcb%sb0a]
	or	bp,bp
	jz	ua4
	lea	bx,[topsb3f-2]
	lea	di,[tcb%sb3f]
ua4:
	mov	[bx],di
	mov	[tcb%rp0a+bp],bx
	mov	[tcb%cp0a+bp],bx
	mov	cx,[tcb%blen]
	mov	[tcb%rs0a+bp],cx
	cld
	lea	si,[tcb%ebuf]
	rep	movsb
ua5:
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
updsbuf endp

;======================================================================
;,fs
; testdelims
;
; supply char in al to check for inclusion in delimset
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb

delimset db	':;,= \/.()><|"',9,0	; set of delimiters

testdelims proc
	push	ds
	push	cs
	pop	ds
	push	si
	lea	si,[delimset-1]
ts2:
	inc	si
	cmp	byte ptr [si],0
	je	ts3
	cmp	al,byte ptr [si]
	je	ts1
	jmp	ts2
ts3:
	xor	al,al
	cmp	al,1
ts1:
	pop	si
	pop	ds
	ret
testdelims endp

;======================================================================
;,fs
; getofs
;
; supply ds:si pointing to a list, and the code to match in ah
; the offset will return in bx
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
getofs proc near
	push	ds
	push	cs
	pop	ds
	xor	bx,bx
	cld
go1:
	lodsb
	or	al,al
	jz	go2
	cmp	al,ah
	je	go3
	add	si,2
	jmp	go1
go3:
	mov	bx,[si]
go2:
	pop	ds
	ret
getofs endp

; be sure to retain the following tables and strings in mo2!
; set of extended key codes which get acted on

funcset db	82			; insert
	dw	mo2:inskey
	db	83			; delete
	dw	mo2:delkey
	db	71			; home
	dw	mo2:homekey
	db	79			; end
	dw	mo2:endkey
	db	48h			; up arrow
	dw	mo2:uparrow
	db	4bh			; left arrow
	dw	mo2:lfarrow
	db	4dh			; right arrow
	dw	mo2:rgarrow
	db	50h			; down arrow
	dw	mo2:dnarrow
	db	114			; cntrl-prtsc
	dw	mo2:contp
	db	115			; cntrl-left arrow
	dw	mo2:clfarrow
	db	116			; cntrl-right arrow
	dw	mo2:crgarrow
	db	117			; cntrl-end
	dw	mo2:clend
	db	132			; cntrl-pgup
	dw	mo2:cpgup
	db	118			; cntrl-pgdn
	dw	mo2:cpgdn
	db	0			; end of list marker

; set of control codes which get acted on

contset db	3			; cntrl-c
	dw	mo2:contc
	db	1bh			; esc
	dw	mo2:esckey
	db	0dh			; cr
	dw	mo2:cargret
	db	10h			; cntrl-p
	dw	mo2:contp
	db	8			; bs
	dw	mo2:backspace
	db	07fh			; cntrl-bs
	dw	mo2:clbacksp
	db	0			; end of list marker

; messages use in cooking

bsavmsg db	'<saved>      '		;@@xlat
bclrmsg db	'<cleared>    '		;@@xlat

;======================================================================
;,fs
; buffinp
;
; fancy cooked input for the standard input device.
;
; in:	ss -> tcb   
;	es:di -> buffer	
;	cx = charactor count
;	tcbconfg flags must be set properly
;
; out:	cx = return count   
;	cy if error, ax = error code
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lproc buffinp
ldword bufpntr
lword bufsize
	push	bx
	push	dx
	push	si
	push	di
	push	ds
	push	es
	push	bp
	mov	[bufsize],cx
	mov	word ptr [bufpntr],di
	mov	word ptr [bufpntr+2],es
	push	ss			; be able to address tcb data via ds and es
	pop	ds
	push	ss
	pop	es
	test	[tcbconfg],2
	jnz	$+5			; jmp ms2   simulate command #5 via #4 to
	jmp	ms2			; accomodate redirection handling method
	test	[tcbconfg],4
	jz	$+5			; jmp ms6   if flag set to honor byte count
	jmp	ms6			; explicitly
	test	[tcbconfg],8
	jnz	ms7			; jmp to ms7 if doing func 3fh

; flow through for fun 0a

	mov	cx,[bufsize]		; get rqb  (requested byte count)
	dec	cx
	mov	[tcb%nmxb],cx		; use as max byte count
	jmp	ms10
ms7:
	cmp	[tcb%blen],0		; any chars left in the buffer?
	jmpne	ms8
	test	[tcb%flgs],10h		; lf flag set?
	jnz	ms9
	mov	[tcb%nmxb],127		; max edit count for 3fh case
	jmp	ms10
ms9:
	and	byte ptr [tcb%flgs],11101111b  ; reset the addlf flag
	les	di,[bufpntr]		; get es:di pointing to user's buffer
	mov	al,0ah			; write a lf code in the user's buffer
	stosb
	mov	cx,1			; setup for returned byte count
	jmp	ms12
ms10:					; entry point for the buffered editor sequence
	and	[tcb%flgs],00010100b	; init the flags, preserve the
					; print echo flag and addlf flag
restart:
	call	getcurpos
	mov	[tcb%stcl],dl
	mov	[tcb%maxc],dl
	mov	[tcb%nstln],dh
	mov	[tcb%lref],dh
	mov	[tcb%maxl],dh
	mov	al,[tcbcols]
	xor	ah,ah
	mov	[tcb%stgc],ax
	mov	[tcb%ecol],1
	mov	[tcb%blen],0
	mov	[tcb%dlen],0
	mov	cx,[tcbctyp]
	and	cx,000fh
	mov	[tcb%cbot],cl
	call	nupdcursor
getkey:
	call	indev			; get a key from con
	or	al,al
	mov	ah,al
	jmpz	gk1			; extended key?
	cmp	al,10			; line feed?
	je	getkey			; if yes, ignore
	cmp	al,7			; bell?
	je	getkey			; if yes, ignore
	lea	si,[contset]
	call	getofs			; is the key in contset?
	or	bx,bx
	jz	gk2
	cmp	bx,offset [uparrow]
	je	noreset
	cmp	bx,offset [dnarrow]
	je	noreset
	and	[tcb%flgs],0fch		; reset up and down arrow flags
noreset:
	jmp	bx
gk2:
	and	[tcb%flgs],0fch		; reset up and down arrow flags
gk4:
	mov	bx,[tcb%blen]
	cmp	bx,[tcb%ecol]		; adding to end of line ?
	jmpb	gk5			; jump if yes
	cmp	[tcb%insf],0ffh		; insert mode 'on' ?
	jmpe	gk6

;==== overwrite mode

	or	[tcb%flgs],8
	push	ax
	cmp	ah,9			; if in overwrite mode and key a tab
	jne	gk4b
	cmp	bx,[tcb%ecol]
	jmpe	gk4a			; if overwriting last char, jmp
	lea	si,[tcb%ebuf-1]
	add	si,[tcb%ecol]
	cmp	byte ptr [si],9		; if current char is already a tab, done
	jne	gk4g
	inc	[tcb%ecol]
	pop	ax
	jmp	update
gk4g:
	call	writechar		; write the tab code
	call	getcurpos
	call	calcexp
	dec	cx
	jnz	extab			; sjc - expand tab
	jmp	gk4ax
extab:
	lea	si,[tcb%ebuf]
	add	si,[tcb%ecol]
	mov	di,si
	mov	ax,si
	sub	ax,offset [tcb%ebuf]
	mov	bx,[tcb%blen]
	sub	bx,ax
	cmp	bx,cx			; shorten the expansion count if it runs
	jnb	gk4d			; out of the buffer
	mov	cx,bx
gk4d:
	cld
gk4e:
	lodsb
	cmp	al,9
	loopne	gk4e			; see if a tab code exists within the
	mov	ax,si			; expansion range, shorten the range if yes
	sub	ax,offset [tcb%ebuf]
	mov	cx,[tcb%blen]
	cmp	cx,ax
	jbe	gk4f
	sub	cx,ax
	cld
	rep	movsb
gk4f:
	sub	si,di
	sub	[tcb%blen],si
	call	delupd
	inc	[tcb%ecol]
	pop	ax
	jmp	update
gk4b:
	lea	si,[tcb%ebuf-1]
	add	si,[tcb%ecol]
	xor	bx,bx
	cmp	byte ptr [si],9		; about to overwrite a tab ?
	je	gk4h
	and	[tcb%flgs],not 8	; reset the delupd control bit
	jmp	gk4a
gk4h:
	call	getcurpos
	call	calcexp
	xor	bx,bx
	dec	cx
	jz	gk4a
	xor	bx,bx			; init truncation adjustment factor
	mov	ax,[tcb%blen]		; check for buffer overflow
	add	ax,cx
	cmp	ax,[tcb%nmxb]
	jna	gk4c			; jmp if enough room
	sub	ax,[tcb%nmxb]
	mov	bx,ax			; calc truncation factor
gk4c:
	lea	si,[tcb%ebuf-1]
	add	si,[tcb%blen]
	sub	si,bx
	mov	di,si
	add	di,cx
	std
	push	cx
	mov	cx,[tcb%blen]
	sub	cx,[tcb%ecol]		; calc tail length
	rep	movsb
	pop	cx
	push	cx
	lea	di,[tcb%ebuf]
	add	di,[tcb%ecol]
	mov	al,' '
	cld
	rep	stosb
	pop	cx
	add	[tcb%blen],cx
	sub	[tcb%blen],bx		; adjust buffer length
gk4a:
	pop	ax
	call	writechar		; simple overwrite in mid line
	inc	[tcb%ecol]
	mov	dl,ah
	call	dispchar
	or	bx,bx
	jz	jgk00			; ljz getkey
	test	[tcb%flgs],8
	jz	upd0			; skip this call if bit 8 not set
	call	delupd
upd0:	
	jmp	update
gk4ax:
	pop	ax
jgk00:	jmp	getkey

;==== adding to the end of the line

gk5:
	mov	bx,[tcb%blen]
	cmp	bx,[tcb%nmxb]		; buffer full ?
	je	bufferfull
	call	writechar		; write char in buffer
	mov	dl,ah
	call	dispchar
	cmp	dl,9			; just display a tab ?
	jne	gk6b
	mov	ax,[tcb%ltc]
	add	[tcb%dlen],ax
	jmp	gk6c
gk6b:
	inc	[tcb%dlen]		; update display line length for simple char
gk6c:
	call	getcurpos
	mov	cl,[tcb%maxc]
	mov	ch,[tcb%maxl]
	cmp	dx,cx
	jna	gk6a
	mov	[tcb%maxc],dl
	mov	[tcb%maxl],dh
gk6a:
	inc	[tcb%ecol]		; check for wrap around
	inc	[tcb%blen]
	call	updstln
	jmp	getkey

;==== inserting into mid line 

gk6:
	mov	bx,[tcb%blen]
	cmp	bx,[tcb%nmxb]		; buffer full ?
	jne	gk3
bufferfull:
	mov	dl,7
	call	dispchar		; if full, send a bell
	jmp	getkey
gk3:
	push	ax
	lea	si,[tcb%ebuf]		; shift buffer contents one place to right
	add	si,[tcb%blen]
	mov	di,si
	dec	si
	mov	cx,[tcb%blen]
	sub	cx,[tcb%ecol]
	inc	cx
	mov	bp,cx			; save for display update
	std
	rep	movsb
	pop	ax
	call	writechar
	call	linecursor		; use a small cursor when repaint tail of line
	mov	dl,ah
	call	dispchar
	mov	ax,[tcb%ecol]
	inc	[tcb%blen]
	mov	bx,[tcb%blen]
	inc	bx
	mov	[tcb%ecol],bx
	mov	si,1
	call	updcursor		; special case to update tcb%dlen
	mov	[tcb%ecol],ax
	lea	dx,[tcb%ebuf]
	add	dx,[tcb%ecol]
	mov	cx,bp
	call	outdev
	call	updstln
	call	getcurpos
	mov	ch,[tcb%maxl]
	mov	cl,[tcb%maxc]
	cmp	dx,cx
	jna	gk3d
	mov	[tcb%maxc],dl
	mov	[tcb%maxl],dh
gk3d:
	inc	[tcb%ecol]
update:
	call	nupdcursor		; restore cursor location and type
jgk0:	
	jmp	getkey
gk1:
	call	indev			; get the extended key
	lea	si,[funcset]
	mov	ah,al
	call	getofs
	or	bx,bx
	jz	jgk0			; ignore function keys not in table
	jmp	bx

;==== backspace 

backspace:				; destructive backspace
	mov	ax,[tcb%ecol]
	cmp	ax,1
	je	jgk0
	cmp	ax,[tcb%blen]
	jna	bs1
	dec	[tcb%blen]
	dec	[tcb%ecol]
	call	linecursor
	call	nupdcursor
	jmp	bs2
bs1:
	lea	si,[tcb%ebuf-1]
	add	si,[tcb%ecol]
	mov	di,si
	dec	di
	mov	dx,di			; save a copy for the display call
	mov	cx,[tcb%blen]
	sub	cx,[tcb%ecol]
	inc	cx
	cld
	rep	movsb
	dec	[tcb%ecol]
	call	linecursor
	call	nupdcursor
	dec	[tcb%blen]
bs2:
	call	delupd
	jmp	update

;==== escape 

esckey:					; escape key
	mov	ax,[tcb%blen]
	inc	ax
	mov	[tcb%ecol],ax
	call	nupdcursor
	mov	dl,'\'
	call	dispchar
	call	nextpos
	jmp	restart
nextpos:
	mov	dl,cr
	call	dispchar
	mov	dl,lf
	call	dispchar
	mov	cl,[tcb%stcl]
	xor	ch,ch
	call	dispblanks
	ret

; test left character -- placed here by sjc
; apparently only for use in control-backspace code.

testlc:					; test char to left
	lea	di,[tcb%ebuf]
	mov	al,[bx+di-2]		; assuming bx still has tcb%ecol !!!!
	call	testdelims
	ret

;==== control backspace 

clbacksp:
	mov	bx,[tcb%ecol]
	cmp	bx,[tcb%blen]
	jna	cl5
	cmp	bx,1
	jz	jgk1			; null line - ignore
	call	testlc			; test char to left
	jnz	cl4			; if not delim, keep on
					; else ignore char
jgk1:
	jmp	getkey			; global jumping off point
cl5:
	lea	di,[tcb%ebuf]
	mov	al,[bx+di-1]		; read char from the buffer
	call	testdelims
	jz	dkp
cl6:
	cmp	bx,1
	jz	cl3
	call	testlc
	jz	cl3
	jmp	cl4
dkp:
	cmp	bx,1
	je	delkey			; treat as if del was keyed
	call	testlc
	jz	delkey
cl4:
	call	cleft			; move cursor to start of word
	call	nupdcursor		; restore cursor location and type
cl3:
	xor	cx,cx
cl1:
	push	cx
	call	delchar
	pop	cx
	ja	cl2
	inc	cx
	mov	bx,[tcb%ecol]
	lea	di,[tcb%ebuf]
	mov	al,[bx+di-1]		; read char from the buffer
	call	testdelims
	jnz	cl1
cl2:
	call	delupd
	jmp	update

;==== insert 

inskey:
	cmp	[tcb%insf],0ffh
	jne	ik1
	mov	[tcb%insf],0
	call	linecursor
	jmp	getkey
ik1:
	mov	[tcb%insf],0ffh
	call	blockcursor
jgk01:	jmp	getkey

;==== delete 

delkey:
	call	delchar			; if come out of delchar with 'above'
	ja	jgk01			; condition set, no display update needed
	call	delupd
	jmp	update

;======================================================================
;,fs
; delchar
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
delchar proc	near
	mov	ax,[tcb%ecol]
	cmp	ax,[tcb%blen]
	ja	de2			; if ecol > blen, at end of line, ignore
	je	de1			; if ecol = blen, deleting last char
	lea	si,[tcb%ebuf]
	add	si,[tcb%ecol]
	mov	di,si
	dec	di
	mov	cx,[tcb%blen]
	sub	cx,[tcb%ecol]
	cld
	rep	movsb
de1:
	dec	[tcb%blen]
	xor	ax,ax			; reset 'above' condition
de2:
	ret
delchar endp

;======================================================================
;,fs
; delupd
;
; update display after calling delchar
;
; in:	cx = number of chars deleted
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
delupd	proc	near
	call	linecursor		
	mov	ax,[tcb%ecol]
	cmp	ax,[tcb%blen]
	ja	du1
	lea	dx,[tcb%ebuf-1]
	add	dx,[tcb%ecol]
	mov	cx,[tcb%blen]
	sub	cx,ax
	inc	cx
	call	outdev
du1:
	call	calctail
	call	dispblanks
	ret
delupd	endp

;==== home 

homekey:
	mov	[tcb%ecol],1
	jmp	update

;==== end 

endkey:
	mov	ax,[tcb%blen]
	inc	ax
	mov	[tcb%ecol],ax
	jmp	update

;==== control left arrow 

clfarrow:
	call	cleft
	jmp	update

;======================================================================
;,fs
; cleft
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
cleft	proc near
	xor	dl,dl			; clear staging flag
	mov	bx,[tcb%ecol]
	cmp	bx,1
	je	cla1
	dec	bx
cla1:
	cmp	bx,1
	je	cla4			; set (or keep) ecol at column 1
	lea	di,[tcb%ebuf]
	mov	al,[bx+di-1]		; read char from the buffer
	call	testdelims		; is it a delim ?
	jnz	cla3
	or	dl,dl
	jz	cla2
	inc	bx
	jmp	cla4			; new setting for ecol
cla2:
	dec	bx
	jmp	cla1
cla3:
	mov	dl,1
	jmp	cla2
cla4:
	mov	[tcb%ecol],bx
	ret
	cleft	endp

;==== control right arrow 

crgarrow:
	xor	dl,dl			; clear staging flag
	mov	bx,[tcb%ecol]
cra1:
	cmp	bx,[tcb%blen]
	jna	cra0
jgk2:
	jmp	getkey			; found end of buffer, no change to ecol
cra0:
	lea	di,[tcb%ebuf]
	mov	al,[bx+di-1]		; read char from the buffer
	call	testdelims		; is it a delim ?
	jz	cra3
	or	dl,dl
	jz	cra2
	mov	[tcb%ecol],bx
	jmp	update			; found the new setting for ecol
cra2:
	inc	bx
	jmp	cra1
cra3:
	mov	dl,1
	jmp	cra2

;==== control end 

clend:
	mov	ax,[tcb%ecol]
	dec	ax
	mov	[tcb%blen],ax
	call	delupd
	jmp	update

;==== control pgup 

cpgup:
	call	updsbuf			; put the current line in the save buffer
	lea	dx,[bsavmsg]
	mov	cx,7
	jmp	dopgmsg

;==== control pgdn 

cpgdn:
	call	setindex
	mov	[tcb%rs0a+bp],0		; nullify the save buffer
	lea	dx,[bclrmsg]
	mov	cx,9
dopgmsg:
	mov	ax,[tcb%blen]		; place cursor on next edit line
	inc	ax
	mov	[tcb%ecol],ax
	push	dx
	push	cx
	call	nupdcursor
	call	nextpos
	pop	cx
	pop	dx
	call	dispcsstr		; display the string to console
	call	nextpos			; place cursor on next edit line
	jmp	restart

;==== up arrow 

uparrow:
	call	setindex		; bp = 0 for 0a, bp = 6 for 3f
	cmp	[tcb%rs0a+bp],0		; ignore if save buffer is empty
	je	jgk2			; lje getkey
	mov	[tcb%ecol],1
	call	nupdcursor		; home the cursor
	test	[tcb%flgs],2		; was last command down arrow?
	jz	uar6
	mov	bx,[tcb%cp0a+bp]	; if yes, advance before take and advance
	add	bx,2
	or	bp,bp
	jnz	uar7a
	cmp	bx,offset [topsb0a]
	jmp	uar7b
uar7a:
	cmp	bx,offset [topsb3f]
uar7b:
	jne	uar7
	mov	bx,[tcb%rp0a+bp]
uar7:
	mov	[tcb%cp0a+bp],bx
uar6:
	and	[tcb%flgs],0fch		; reset up and down arrow flags
	or	[tcb%flgs],1		; set flag to indicate last command was
					; an up arrow
	mov	bx,[tcb%cp0a+bp]
	mov	si,bx
	add	bx,2
	or	bp,bp
	jnz	uar1b
	cmp	bx,offset [topsb0a]
	jmp	uar1a
uar1b:
	cmp	bx,offset [topsb3f]
uar1a:
	jne	uar1
	mov	bx,[tcb%rp0a+bp]
uar1:
	mov	[tcb%cp0a+bp],bx	; update current pointer for next time
	cmp	si,[tcb%rp0a+bp]
	je	uar2
	mov	cx,[si-2]
	sub	cx,[si]
	jmp	uar3
uar2:
	mov	cx,[tcb%rs0a+bp]
uar3:					; entry point for down arrow
	cmp	cx,[tcb%nmxb]
	jna	uar3a
	mov	cx,[tcb%nmxb]		; limit size of restored line to mxb
uar3a:
	mov	[tcb%blen],cx
	mov	si,[si]
	lea	di,[tcb%ebuf]
	push	cx
	cld
	rep	movsb			; update edit buffer from save buffer
	call	linecursor
	pop	cx
	lea	dx,[tcb%ebuf]
	call	outdev
	call	getcurpos
	mov	[tcb%maxc],dl		; set maxc/l on new line
	mov	[tcb%maxl],dh
	mov	ax,[tcb%blen]		; calc dlen for new line
	add	ax,[tcb%ltc]		; blen + total tab expansion - # of tabs
	sub	ax,[tcb%ttc]
	mov	cx,[tcb%dlen]		; get last dlen
	mov	[tcb%dlen],ax		; update dlen
	cmp	ax,cx
	ja	uar8			; skip blanking of tail if new line longer
	sub	cx,ax
	call	dispblanks
uar8:
	call	updstln
	jmp	endkey

;==== down arrow 

dnarrow:
	call	setindex		; bp = 0 for 0a, bp = 6 for 3f
	cmp	[tcb%rs0a+bp],0		; ignore if save buffer is empty
	je	jgk3			; lje	getkey
	mov	[tcb%ecol],1
	call	nupdcursor		; home the cursor
	test	[tcb%flgs],1		; was last command up arrow?
	jz	dar4
	mov	bx,[tcb%cp0a+bp]	; if yes, dec before dec and take
	sub	bx,2
	cmp	bx,[tcb%rp0a+bp]
	jnb	dar5
	or	bp,bp
	jnz	dar5a
	mov	bx,offset [topsb0a-2]
	jmp	dar5
dar5a:
	mov	bx,offset [topsb3f-2]
dar5:
	mov	[tcb%cp0a+bp],bx	; update current pointer for next time
dar4:
	and	[tcb%flgs],0fch		; reset up and down arrow flags
	or	[tcb%flgs],2		; set flag to indicate last command was
					; a down arrow
	mov	bx,[tcb%cp0a+bp]
	sub	bx,2
	cmp	bx,[tcb%rp0a+bp]
	jnb	dar1
	or	bp,bp
	jnz	dar1a
	mov	bx,offset [topsb0a-2]
	jmp	dar1
dar1a:
	mov	bx,offset [topsb3f-2]
dar1:
	mov	[tcb%cp0a+bp],bx	; update current pointer for next time
	mov	si,bx
	cmp	si,[tcb%rp0a+bp]
	je	dar2
	mov	cx,[si-2]
	sub	cx,[si]
	jmp	dar3
dar2:
	mov	cx,[tcb%rs0a+bp]
dar3:
	jmp	uar3

;==== left arrow 

lfarrow:
	cmp	[tcb%ecol],1
	jne	lfa0			; lje	getkey
jgk3:
	jmp	getkey
lfa0:
	dec	[tcb%ecol]
	jmp	update

;==== right arrow 

rgarrow:
	mov	ax,[tcb%blen]
	cmp	ax,[tcb%ecol]
	jb	jgk3			; ljb getkey
	inc	[tcb%ecol]
	jmp	update

;==== control c 

;======================================================================
;,fs
; dispcontc
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
dispcontc proc
	test	[tcbconfg],1
	jz	dcc1			; ifnecho dcc1 - the echo bit is on
	mov	dl,'^'
	call	dispchar
	mov	dl,'C'
	call	dispchar
	mov	dl,cr
	call	dispchar
	mov	dl,lf
	call	dispchar
dcc1:
	ret
dispcontc endp

contc:
	test	[tcbbrkfg],2		; ignore control-c ?
	jnz	jgk3			; ljnz	getkey
	test	[tcbconfg],10h		; ignore control characters
	jz	jgk3
	or	byte ptr [tcbbrkfg],01	; set the control-c flag bit
	cmp	byte ptr [tcbnest],1
	jne	contc1			; only display ^c if not nested and
	call	dispcontc
contc1:
	mov	[tcb%blen],0		; no more data for later calls
	and	[tcb%flgs],not 10h	; reset the add line feed flag
	mov	cx,0
	jmp	ms12

;==== control p 

contp:
	test	[tcbconfg],10h		; ignore control characters
	jz	contp1
	xor	[tcb%flgs],4		; toggle the printer flag
contp1:
	jmp	getkey

;==== carriage return 

cargret:
	mov	ax,[tcb%blen]		; insure cursor is at end of line
	inc	ax
	mov	[tcb%ecol],ax
	call	nupdcursor
	call	linecursor
	call	updsbuf			; update the save buffer
	mov	ah,cr
	call	writechar
	inc	[tcb%blen]
	mov	dl,cr
	call	dispchar
	test	[tcb%flgs],4
	jz	cg1			; ifnprtgl cg1
	lea	si,[tcb%ebuf]
	mov	cx,[tcb%blen]
	dec	cx			; don't send the CR to the printer
	call	echoprn
cg1:
	test	[tcbconfg],8
	jz	ms13			; ifnminb ms13
					; enter here for func 3fh
	mov	dl,lf			; only for 3f (not for 0as)
	call	dispchar
	or	byte ptr [tcb%flgs],10h ; set the addlf flag to add a lf code
	jmp	ms8
ms13:					; xfer to users buffer for func 0ah
	lea	si,[tcb%ebuf]
	mov	cx,[tcb%blen]
	mov	dx,cx
	pop	bp
	les	di,[bufpntr]
	push	bp
	cld
	rep	movsb
	mov	cx,dx
	dec	cx			; don't count the CR in the returned cnt
	mov	[tcb%blen],0		; clear counter for fun 3f
	jmp	ms12
ms8:
	lea	si,[tcb%ebuf]		; xfer the edit buffer to the user's
	mov	dx,[tcb%blen]
	pop	bp
	les	di,[bufpntr]
	mov	cx,[bufsize]		; get original requested bytes
	push	bp
	cmp	cx,dx			; rqb > tcb%blen ?  if no, must
	jna	ms11			; return data piecemeal
	mov	cx,dx			; use tcb%blen as xfer counter
	cld
	rep	movsb
	mov	al,0ah			; buffer and add a lf
	stosb
	and	byte ptr [tcb%flgs],11101111b  ; reset the addlf flag
	mov	cx,[tcb%blen]
	inc	cx			; calc return byte count
	mov	[tcb%blen],0
	jmp	ms12
ms11:
	mov	dx,cx
	sub	[tcb%blen],cx		; adjust the edit buffer counter
	cld				; use rqb as counter (already in cx)
	rep	movsb
	push	ss
	pop	es
	mov	cx,[tcb%blen]
	lea	di,[tcb%ebuf]		; edit buffer to the front
	rep	movsb
	mov	cx,dx
	jmp	ms12			; use rqb as the returned byte count

; enter this sequence when the flag bit exlf is set (in tcbconfg) which
; says to honor the length request explicitly and don't decode function
; keys   (ie func 6,7 and 8)

ms6:
	mov	cx,[bufsize]		; get rqb  (requested byte count)
	push	cx
ms14:
	call	indev			; get a key from standard input
	test	[tcbconfg],10h		; ifncont ms15
	jz	ms15			; jmp ms15 if bit flag for ^c, ^p is false
	cmp	al,3			; was it ^c ?
	jne	ms18
	test	[tcbbrkfg],2		; ignore control-c ?
	jnz	ms14
	or	byte ptr [tcbbrkfg],01	; set the control-c flag bit
	cmp	byte ptr [tcbnest],1
	jne	ms14a			; only display ^c if not nested and
	call	dispcontc
ms14a:
	pop	cx
	mov	cx,1
	jmp	ms12
ms18:
	cmp	al,10h			; was it ^p ?
	jne	ms15
	xor	[tcb%flgs],4		; toggle the printer flag
	jmp	ms14
ms15:
	test	[tcbconfg],1
	jz	ms16
	cmp	al,9			; was it a tab code ?
	je	ms17
	mov	dl,al
	call	dispchar
	jmp	ms16
ms17:					; expand the tab
	call	getcurpos
	call	calcexp
	call	dispblanks
ms16:					; write the key in the user's buffer
	pop	dx			; get cx off of stack, but don't crash
	pop	bp			; current cx
	les	di,[bufpntr]
	push	bp
	push	dx
	cld
	stosb
	loop	ms14
	pop	cx
	jmp	ms12

;======================================================================
;,fs
; ms2a
;
; enter this sequence when using command #4 with the wait bit cleared
; to simulate a command #5.  done this way because of re-direction
; method used.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
ms2a proc near
	push	ax
	push	bx
	push	cx
	lea	bx,[tcb%dbuf]		; use dbuf as a temporary buffer
	mov	cx,1
	mov	al,4			; get the key out of the type ahead buffer
	call	callcon
	pop	cx
	pop	bx
	pop	ax
	ret
ms2a endp

ms2:
	or	[tcbconfg],2		; set wait bit to signal no char is ready
	mov	cx,1			; buffer address doesn't matter for #5
	mov	al,5
	call	callcon			; is a key waiting?
	or	cx,cx
	jz	ms12			; jmp if no char
	test	[tcbconfg],10h		; control characters allow
	jz	ms3
	cmp	al,3			; is it ^c ?
	je	ms4
	cmp	al,10h			; is it ^p ?
	jne	ms3
	call	ms2a			; get the key out of the buffer
	xor	[tcb%flgs],4		; toggle the printer flag
	jmp	ms2
ms4:
	test	[tcbbrkfg],2		; ignore control-c ?
	jnz	ms2
	call	ms2a			; get the key out of the buffer
	or	byte ptr [tcbbrkfg],01	; set the control-c flag bit
	cmp	byte ptr [tcbnest],1
	jne	ms4a			; only display ^c if not nested and
	call	dispcontc
ms4a:
	mov	cx,1
	jmp	ms12
ms3:
	and	[tcbconfg],0fdh		; reset wait bit to signal a char is ready
	pop	bp
	les	di,[bufpntr]
	push	bp
	cld
	stosb				; write the char in the users buffer
ms12:

; return count should be in cx
; cy set for error ax = errorcode

	clc
	pop	bp
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	bx
lundef	bufpntr
lundef	bufsize
lendp	buffinp

;======================================================================
;,fs
; cdevinp
;
; simple cooked input for a character device (other than stdin)
;
; in:	ss -> tcb   
;	es:di -> buffer	
;	cx = charactor count
;	ds -> gfb
;
; out:	cx = return count   
;	cy if error
;	 ax = error code
;
;,fe
;======================================================================
	assume	ds:gfb,es:nothing,ss:tcb
cdevinp proc
	push	ax
	push	dx
	push	di
	mov	dx,di			; save initial count
cde1:
	jcxz	cde2			; all done
	push	cx
	mov	cx,1
	push	di
	call	devread
	jc	cde6			; error handler based on current push'es !!
	pop	di
	inc	di
	pop	cx
	cmp	byte ptr es:[di-1],0dh	; just read a cr ?
	je	cde3
	cmp	byte ptr es:[di-1],1ah	; just read a cntrl-z ?
	je	cde3
	dec	cx
	jmp	cde4
cde3:
	xor	cx,cx			; if find a stop char, mod the count
cde4:
	push	cx
	mov	cx,1			; buffer address doesn't matter for #5
	mov	al,5
	call	callcon			; is a key waiting?
	mov	[tcbkbcnt],0		; counteract dis mode
	or	cx,cx
	pop	cx
	jz	cde1
	cmp	al,0ah			; filter out the lf's
	jne	cde8
	call	ms2a			; get the key out of the buffer
	jmp	cde1
cde8:
	cmp	al,3			; is the key a cntrl-c ?
	jne	cde1
	test	[tcbconfg],10h		; control characters allow
	jz	cde1
	call	ms2a			; get the key out of the buffer
	or	byte ptr [tcbbrkfg],01	; set the control-c flag bit
	cmp	byte ptr [tcbnest],1
	jne	cde2			; only display ^c if not nested and
	call	dispcontc
cde2:
	mov	cx,di
	sub	cx,dx			; calc count of chars sent
cde5:
	clc
cde7:
	pop	di
	pop	dx
	pop	ax
	clc
	ret
cde6:
	pop	ax			; balance stack and return with cy for error
	pop	ax
	jmp	cde7
cdevinp endp

;==== local subroutines for cdevoutp

;======================================================================
;,fs
; cdo7
;
; send cx chars to the device (stdout) and to the printer if 
; flagged to echo
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
cdo7	proc
	push	ax
	push	bx
	push	di
	push	cx
	mov	di,si
	call	devwrite
	jc	cdo7b			; error handler based on current push'es !!
	test	[tcb%flgs],4
	jz	cdo7a			; ifnprtgl cdo7a
	test	[tcb%flgs],20h
	jnz	cdo7a			; skip echoing if ignore bit is set
	pop	cx
	push	cx
	mov	di,si
	push	ds
	push	es
	pop	ds
	call	echoprn			; echo the line to the printer
	pop	ds
cdo7a:
	clc
cdo7b:
	pop	cx
	pop	di
	pop	bx
	pop	ax
	ret
cdo7	endp

;======================================================================
;,fs
; cdo14
;
; set nz flag if stdout
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:gfb,es:nothing,ss:tcb
cdo14	proc
	push	ds
	lds	si,[gfbdrvr]
	test	word ptr [si+4],2	; is this device stdout ?
	pop	ds
	ret
cdo14	endp

;======================================================================
;,fs
; cdo15
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
cdo15	proc
	push	es
	push	ss
	pop	es
	call	indev			; get the charactor out of the buffer
	pop	es
	ret
cdo15	endp

;======================================================================
;,fs
; cdevoutp
;
; cooked output for a charactor device
;
; in:	ss -> tcb   
;	es:di -> buffer	
;	cx = charactor count
;	ds -> gfb
;
; out:	cx = return count   
;	cy if error, 
;	 ax = error code
;
;,fe
;======================================================================
	assume	ds:gfb,es:nothing,ss:tcb
cdevoutp proc
	push	bx
	push	dx
	push	si
	push	di
	push	bp
	xor	bp,bp			; use bp as a char count tally
cdo1:
	push	cx
	mov	cx,1			; buffer address doesn't matter for #5
	mov	al,5
	call	callcon			; is a key waiting?
	mov	[tcbkbcnt],0		; counteract dis mode
	or	cx,cx
	pop	cx
	jz	cdo2
	cmp	al,3			; is the key a cntrl-c ?
	je	cdo11
	cmp	al,16			; control-p ?
	je	cdo12
	call	cdo14
	jz	cdo2			; skip control-s check if not stdout
	cmp	al,19			; control-s ?
	jne	cdo2
	call	cdo15			; get the char out of the buffer
	call	cdo15			; wait for a key (pause on ^s)
	cmp	al,3
	jne	cdo2
	test	[tcbbrkfg],2		; ignore bit set for ^c ?
	jnz	cdo2
cdo13:
	or	byte ptr [tcbbrkfg],01	; set the control-c flag bit
	cmp	byte ptr [tcbnest],1
	jne	cdo0
	push	es
	lea	di,[tcb%dbuf]
	push	ss
	pop	es
	mov	cx,4
	mov	word ptr [tcb%dbuf],'C^'
	mov	word ptr [tcb%dbuf+2],0a0dh
	call	devwrite
	pop	es
	jc	cdo10a			; error handling stack dependant !!
cdo0:	
	jmp	cdo10			; get out
cdo11:
	test	[tcbbrkfg],2		; ignore bit set for ^c ?
	jnz	cdo2
	call	cdo15			; get the key out of the buffer
	jmp	cdo13
cdo12:
	xor	[tcb%flgs],4		; toggle the printer flag
	call	cdo15			; sah make sure you flush it
cdo2:
	push	di
	xor	dx,dx			; use dx as a remainder count
	cmp	cx,40
	jna	cdo3
	mov		dx,cx
	sub	dx,40			; limit to 40 chars each pass to give control
	mov	cx,40			; keys a chance to be detected.
cdo3:
	mov	al,1ah
	mov		bx,di
	mov	si,cx
	cld
	repne	scasb			; scan ahead for a control-z code
	jne	cdo3a
	xor	dx,dx			; zero out the remainder when find a ^z
	mov		cx,di
	sub	cx,bx			; mod the char count, don't include the ^Z
	test	[tcbconfg], 8		; ctrl-z echoing if function 0a
	jz	cdo4
	dec	cx
	jz	cdo9			; found a ^z in the first position
	jmp	cdo4
cdo3a:
	mov		cx,si		; no ^z code, recover original cx
cdo4:
	pop	di			; recover buffer pointer
	add	bp,cx			; tally bytes sent
	call	cdo14			; is the device stdout ?
	jnz	cdo5			; jmp if yes
	push	di
	call	devwrite
	pop	di
	jc	cdo10a			; error handling stack dependant !!
	add	di,cx			; advance the pointer
cdo6:
	mov	cx,dx			; recover the remainder
	jcxz	cdo10
	jmp	cdo1			; recycle if more chars
cdo9:
	pop	di			; balance stack
cdo10:
	clc
cdo10a:
	mov	cx,bp
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	bx
	ret
cdo10b:
	pop	cx
	jmp	cdo10a
cdo5:					; special handling for stdout (expand tabs)
	mov	si,di			; save a copy of the starting pointer value
	push	ds
	push	es
	pop	ds
	call	findtab
	pop	ds
	push	cx
	mov	cx,ax			; ax is number of chars up to the tab (if any)
	call	cdo7
	jc	cdo10b			; error handler based on current push'es !!
	cmp	bl,9			; was a tab found ?
	jne	cdo8
	push	dx
	call	getcurpos
	call	calcexp			; calc the expansion
	pop	dx
	push	es
	push	ss
	pop	es
	call	initdbuf
	lea	si,[tcb%dbuf]
	call	cdo7			; send cx spaces
	pop	es
	jc	cdo10b			; error handling stack dependant !!
cdo8:
	pop	cx
	jcxz	cdo6
	jmp	cdo5
cdevoutp endp

	subttl readguts - the guts of all file and device reads
	page
;======================================================================
;,fs
; readguts - the guts of all file and device reads
;
; readguts - the guts of all file and device reads
;
; in:	ds:dx -> transfer buffer
;	cx = number of bytes to read
;	tfbpos = position to start read
;	es = tfb
;
; out:	cx = number of bytes read
;	c if error and ax = error code
;	else nc and ax = 0
;	bx, dx, si, di, ds, es undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:tfb,ss:tcb
lproc	readguts
lword	numread
ldword	buffer
	mov	word ptr [buffer],dx	; store the buffer offset
	mov	word ptr [buffer+2],ds	; and segment in local storage
	mov	[numread],0		; initialize number read
	mov	ax,accdeny		; initial status to access denied
	cmp	[tfbacc],1		; is access allowed to this tfb
	je	rcookx			; exit now if access not allowed
	mov	ds,[tfbgfb]		; get the pointer to the gfb
	assume	ds:gfb
	xor	ax,ax			; zero ax
	jcxz	rcookx			; exit if requested to read 0 chars
	cmp	[gfbdev],0		; is this a character mode device
	je	readga			; jump if block mode device

; read from a character mode device

	test	[tfbioctl],004h		; is this device null
	jnz	rcook5			; treat as end of file if null
	test	[tfbioctl],020h		; is the device in binary mode
	jz	rcook2			; jump if not in binary mode
rcook1:
	test	[tfbioctl],001h		; is this the stdin device
	jz	rcook1a			; jump if not stdin
	test	[tcbconfg],2
	jnz	rcook1a
	jmp	rcook2a			; if nowait use cook output
rcook1a:
	push	es			; save the pointer to the tfb
	les	di,[buffer]		; point es:di to the buffer
	call	devread			; call the device driver directly
	jmp	short rcook4		; go wrap it up
rcook2:
	test	[tfbioctl],001h		; is this the stdin device
	jz	rcook3			; jump if not stdin
rcook2a:
	push	es			; save the pointer to the tfb
	les	di,[buffer]		; point es:di to the buffer
	call	buffinp			; use stdin fancy cooked input
	jmp	short rcook4		; go wrap it up
rcook3:
	test	[tcbbrkfg],002h		; is [ctrl] [c] disabled
	jnz	rcook1			; treat like binary if yes
	push	es			; save the pointer to the tfb
	les	di,[buffer]		; point es:di to the buffer
	call	cdevinp			; use simple cooked input
rcook4:
	pop	es			; restore the pointer to the tfb
	mov	[numread],cx		; save the count of chars read
	jc	rcookx			; jump if error while reading
	xor	ax,ax			; clear the error status
	and	[tfbioctl],not 040h	; reset the eof flag
	or	cx,cx			; did we get any characters
	jnz	rcookx			; exit if characters read
rcook5:
	or	[tfbioctl],040h		; set eof if no characters read
rcookx:
	jmp	readgx			; go wrap up readguts

; read from a file - see if current position is at or past eof, and if
;   prior to eof, see if read length goes past eof, and if so, adjust
;   read length to number of bytes until eof

readga:
	xor	ax,ax			; no error if read access level fails
					; (cause some dos utilities don't check carry)
	cmp	[tfblvl],2		; make sure we have read access to file
	jb	rcookx			; exit if no read access

	mov	bx,word ptr [tfbpos]
	mov	dx,word ptr [tfbpos+2]
	mov	si,word ptr [gfbsize]
	mov	di,word ptr [gfbsize+2]
	sub	si,bx
	sbb	di,dx
	jc	rcookx			; exit
	jnz	readgb			; length to eof >= 64k
	cmp	si,cx
	jae	readgb
	mov	cx,si			; length to eof < read length
readgb:
	jcxz	readgx

; see if read conflicts with any locks

	xor	si,si			; length to check for lock is si:di
	mov	di,cx
	mov	dx,word ptr [tfbpos]
	mov	cx,word ptr [tfbpos+2]
	call	iolock
	mov	ax,xlock
	jc	readgx			; error if locked by others
	mov	cx,di
	mov	ax,word ptr [tfbpos]
	mov	dx,word ptr [tfbpos+2]
	call	getclust
	jc	readgx

; dx = absolute cluster number of read start
; ax = file-relative cluster num of read start
; bx = sector ofs within cluster of read start
; si = byte offset within sector of read start
; cx = still set to rdlen
; read buffer
; decrypt buffer if necessary

	push	es
	les	di,[buffer]
	call	blkread
	pop	es
	pushf				; save error signal if any
	cmp	[gfbclass],' '
	je	rdgb1
	cmp	[gfbclass],0
	je	rdgb1
	push	ds			; decrypt when nz or space class
	push	si
	lds	si,[buffer]
	call	decrypt
	pop	si
	pop	ds
rdgb1:
	popf
	jc	readgx

; update current position, current cluster

	mov	[numread],cx
	add	word ptr [tfbpos],cx
	adc	word ptr [tfbpos+2],0
	mov	[tfbclus],dx		; current absolute cluster
	mov	[tfbrccur],ax		; current relative cluster (from file start)

; update max relative cluster encountered if appropriate

	cmp	ax,[gfbrcmax]
	jbe	readgc
	mov	[gfbrcmax],ax
	mov	[gfbcmax],dx
readgc:
	xor	ax,ax
readgx:
	mov	cx,[numread]
	or	ax,ax
	jz	readgy
	stc
readgy:

lundef	numread
lundef	buffer

lendp	readguts

	subttl writeguts - the guts of all file and device writes
	page
;======================================================================
;,fs
; writeguts - the guts of all file and device writes
;
; in:	ds:dx -> transfer buffer
;	cx = number of bytes to write
;	tfbpos = position to start write
;	es = tfb
;
; out:	cx = number of bytes write
;	c if error and ax = error code
;	else nc and ax = 0
;	bx, dx, si, di, ds, es undefined
;
;,fe
;======================================================================
	assume	ds:nothing,es:tfb,ss:tcb
lproc	writeguts
lword	numwritten
ldword	buffer
	mov	[numwritten],0
	mov	word ptr [buffer],dx
	mov	word ptr [buffer+2],ds
	mov	ax,accdeny
	cmp	[tfbacc],0
	je	jwgx0
	mov	ds,[tfbgfb]
	assume	ds:gfb
	mov	[gfbwrtn],'Y'
	cmp	[gfbdev],0
	je	writega

; write to a character device

	xor	ax,ax			; no error if nothing to write
	mov	si,cx
	jcxz	jwgx0
	push	es
wcook2:
	test	[tfbioctl],4		; is nul device?
	jnz	wcook3			; if nul, do binary mode output
	test	[tfbioctl],20h		; is binary bit set ?
	jnz	wcook3
	test	[tcbconfg],10h
	jz	wcook3			; ifncont wcook3
	les	di,[buffer]

; set scbnoswt to 0 so that if scbnoswt is set
; and we are doing console io for a large count ie function 40
; with large cx, switching is enable during this time so that
; other task will get selected.

	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	al,[scbnoswt]		; get current noswitch flag
	mov	[scbnoswt],0		; enable switching
	pop	ds
	assume	ds:gfb
	push	ax			; save current switch flag on stack
	call	cdevoutp		; cooked mode write to device
	pop	ax			; retrieve current switch flag off stack
	push	ds
	mgetscb2 ds
	assume	ds:grp
	mov	[scbnoswt],al		; restore noswitch flag
	pop	ds
	assume	ds:gfb
	jmp	wcook1
wcook3:
	les	di,[buffer]
	call	devwrite		; raw mode write to device
wcook1:
	mov	[numwritten],cx
	pop	es
	jc	jwgx0
	xor	ax,ax
jwgx0:	jmp	writegx

; write to a file - see if write conflicts with any locks

writega:
	mov	ax,accdeny
	cmp	[tfblvl],3
	jb	jwgx0
	mov	di,cx
	or	[tfbioctl],40h		; signal file has been written
	mov	dx,word ptr [tfbpos]
	mov	cx,word ptr [tfbpos+2]
	xor	si,si
	call	iolock
	mov	ax,xlock
	jc	jwgx0			; error if locked by others
	mov	si,di

; see if write will extend the file

	mov	cx,word ptr [tfbpos]
	mov	bx,word ptr [tfbpos+2]
	add	cx,si
	adc	bx,0
	sub	cx,word ptr [gfbsize]
	sbb	bx,word ptr [gfbsize+2]
	jmpc	writegg			; c if end of write < eof
	or	cx,bx
	jmpz	writegg			; z if end of write = eof

; file will be longer, more cluster(s) needed?
;   compute cluster number of end of file

	cmp	[gfbcbof],0		; certainly need more if none yet
	jne	writega1		; e if no clusters allocated yet
	push	ds			; allocate the first one
	mov	ds,[gfbbdb]
	assume	ds:bdb
	mov	dx,0ffffh
	call	alloclust
	pop	ds
	assume	ds:gfb
	jmpc	writegi
	mov	[gfbcbof],dx		; remember the first cluster
	mov	[gfbcmax],dx		; (is same for max cluster)
	mov	[tfbclus],dx		; (and current cluster for tfb)

; compute new key for file encryption if only now allocating first
; cluster

	push	dx
	mov	ax,[gfbcbof]
	sub	ax,2			; cluster is 2-based
	mov	dx,26			; 26 possible classes
	mul	dx
	mov	cl,[gfbclass]
	sub	cl,'A'			; class is 'A'-based
	xor	ch,ch
	add	ax,cx
	adc	dx,0
	push	ds
	mgetscb2 ds
	assume	ds:grp
	add	ax,word ptr [scbkey+2]
	adc	dx,word ptr [scbkey]
	pop	ds
	assume	ds:gfb
	mov	word ptr [gfbkey],ax
	mov	word ptr [gfbkey+2],dx
	pop	dx
writega1:
	push	ds
	mov	ds,[gfbbdb]
	assume	ds:bdb
	mov	ax,[bdbssiz]		; prepare a divisor to convert a
	mov	bl,[bdbcsiz]		; file size to a relative cluster
	xor	bh,bh			; number.  this is done by:
	mul	bx			; cl# = fsiz / (byte/sct * sct/cl)
	mov	bx,ax
	pop	ds
	assume	ds:gfb
	mov	ax,word ptr [gfbsize]
	mov	dx,word ptr [gfbsize+2]
	mov	cx,dx
	or	cx,ax			; 0-1024 = cluster 0, 1025-2048 = 2, etc.
	jz	writega2
	sub	ax,1
	sbb	dx,0			; adjust for above ranges
writega2:
	div	bx
	mov	di,ax			; di = relative cluster of eof

; compute cluster number of current position + length to write

	mov	ax,word ptr [tfbpos]
	mov	dx,word ptr [tfbpos+2]
	add	ax,si			; si = length to write (still)
	adc	dx,0

; add clusters if byte count > even cluster size.

	mov	cx,dx
	or	cx,ax			; is pos + len to write == 0?
	jz	writegb1		; if 0, don't decrement extension byte ct.
	sub	ax,1			; assume we have allocated current cluster
	sbb	dx,0
writegb1:
	div	bx
	sub	ax,di			; ax = amount to extend file if needed
	jmpbe	writegf			; be if no new clusters needed

; add ax clusters to file

	mov	cx,ax			; number to allocate
	push	si
	push	cx
	mov	ax,word ptr [gfbsize]
	mov	dx,word ptr [gfbsize+2]
	mov	cx,dx
	or	cx,ax			; if at 0, still cluster 0
	jz	writegc2
	sub	ax,1
	sbb	dx,0			; figure out cluster based on 0-1024 = 0,
					; 1025-2048 = 1, etc.
writegc2:
	call	getclust		; (setting gfbcmax to eof cluster also)
	pop	cx			; number of clusters to allocate
	pop	si			; number of bytes to write
	jc	jwgx1
	mov	bx,cx
	add	bx,ax			; new max relative cluster number
	mov	ds,[gfbbdb]
	assume	ds:bdb
	jcxz	writegd1
writegd:
	call	alloclust
	jc	writege1
	loop	writegd
writegd1:
	call	flushdir		; force anything changed to be updated
	jc	writege			; c if couldn't flush them
	mov	ds,[tfbgfb]
	assume	ds:gfb
	mov	[gfbcmax],dx		; new max cluster number
	mov	[gfbrcmax],bx		;   and relative number
	jmp	writegf

; if there's an error during allocation, recover by deallocating

writege1:				; mod error code for
	xor	ax,ax			; disk full condition
writege:
	mov	si,ax			; remember error code
	push	ds
	mov	ds,[tfbgfb]
	assume	ds:gfb
	mov	dx,[gfbcmax]		; this was the last cluster in the file
	pop	ds
	assume	ds:bdb
	call	getfat
	mov	cx,ax
	mov	ax,si
	jc	jwgx1			; give up recovery on any other error
	cmp	cx,0fff8h
	jnc	jwgx1			; nothing to deallocate
	push	cx			; else set eof cluster to eof mark
	mov	ax,0ffffh
	call	putfat
	pop	dx
	mov	ax,si
	jc	jwgx1
	call	dealloc			; and deallocate the remaining clusters
	mov	ax,si
jwgx1:	jmp	writegx

; successfully extended file, set new length

	assume	ds:gfb
writegf:
	mov	ax,word ptr [tfbpos]
	mov	dx,word ptr [tfbpos+2]
	add	ax,si
	adc	dx,0
	mov	word ptr [gfbsize],ax
	mov	word ptr [gfbsize+2],dx
	xor	ax,ax
	mov	cx,si
	jcxz	jwgx1
	jmp	writegh

; file doesn't need to be extended, see if anything needs to be written

writegg:
	mov	cx,si
	or	si,si
	jz	writgtrc
	jmp	writegh			; nz if something to write

; else truncating file at current position

writgtrc:
	xor	ax,ax			; no error
	cmp	[gfbcbof],0		; if nothing to truncate 'cause
	je	jwgx2			; nothing allocated yet
	mov	ax,word ptr [tfbpos]
	mov	dx,word ptr [tfbpos+2]
	mov	word ptr [gfbsize],ax
	mov	word ptr [gfbsize+2],dx
	mov	cx,dx
	or	cx,ax
	jnz	writegg2		; not truncating to 0 len

; truncating to 0 len, deallocate all clusters

	mov	[gfbcmax], ax		; clear first cluster values
	mov	[gfbrcmax], ax
	mov	[tfbclus], ax
	mov	dx, [gfbcbof]		; get first cluster to deallocate
	mov	[gfbcbof], ax		; clear files first cluster
	mov	ds, [gfbbdb]
	jmp	short writegg3
writegg2:
	sub	ax,1
	sbb	dx,0			; 0-1024 -> cluster 0, 1025-2048 -> 1, etc.
	call	getclust		; get to current cluster
	jc	jwgx1
	mov	[gfbcmax],dx
	mov	[gfbrcmax],ax
	mov	[tfbclus],dx
	mov	[tfbrccur],ax
	mov	ds,[gfbbdb]
	assume	ds:bdb
	call	getfat			; next cluster starts deallocation
	jc	jwgx2
	mov	cx,ax
	xor	ax,ax
	cmp	cx,0fff8h
	jnc	jwgx2			; no clusters to deallocate
	push	cx
	mov	ax,0ffffh
	call	putfat			; set this one to eof
	pop	dx
	jc	jwgx2
writegg3:
	call	dealloc			; deallocate all the rest
	jc	jwgx2
	call	flushdir		; force everything to be updated
	jc	writegx
	xor	ax,ax
jwgx2:	jmp	writegx

; else just go write it

	assume	ds:gfb
writegh:
	mov	ax,word ptr [tfbpos]
	mov	dx,word ptr [tfbpos+2]
	call	getclust		; cluster number here is ok as is
	jc	writegx

; dx = absolute cluster number of write
; ax = file-relative cluster num of write
; bx = sector ofs within cluster of write
; si = byte offset within sector of write
; encrypt buffer first (if file class is active)
; write it
; then decrypt buffer (if file class is active)

	cmp	[gfbclass],' '
	je	wrgh1
	cmp	[gfbclass],0
	je	wrgh1
	push	ds
	push	si
	lds	si,[buffer]
	call	encrypt
	pop	si
	pop	ds
	push	cx
	push	es
	les	di,[buffer]
	call	blkwrite
	pop	es
	pop	di			; byte length encrypted
	pushf
	push	ds
	push	si
	push	cx
	lds	si,[buffer]
	mov	cx,di			; byte length encrypted
	call	decrypt
	pop	cx
	pop	si
	pop	ds
	popf
	jmp	wrgh2
wrgh1:
	push	es
	les	di,[buffer]
	call	blkwrite
	pop	es
wrgh2:
	jc	writegx

; update current position, current cluster

	mov	[numwritten],cx
	add	word ptr [tfbpos],cx
	adc	word ptr [tfbpos+2],0
	mov	[tfbclus],dx
	mov	[tfbrccur],ax

; update max cluster encountered if appropriate

	cmp	ax,[gfbrcmax]
	jbe	writegi
	mov	[gfbrcmax],ax
	mov	[gfbcmax],dx
writegi:
	xor	ax,ax
writegx:
	mov	cx,[numwritten]
	or	ax,ax
	jz	writegy
	stc
writegy:
lundef	numwritten
lundef	buffer
lendp	writeguts

	subttl truncguts - the guts of truncating a dir entry to 0 length
	page
;======================================================================
;,fs
; truncguts - the guts of truncating a dir entry to 0 length
;
; in:	ss:bx -> sector location of dir entry
;	si = sector offset of dir entry
;	es = dbb containing sector
;	ds = bdb
;	cl = attribute to match to dir entry
;	ah = access level
;
; out:	c and ax = error code if error
;	else nc and ax = 0
;	cx, dx, di undefined
;
;,fe
;======================================================================
	assume	ds:bdb,es:dbb,ss:tcb
truncguts:
	push	di
	cmp	ah,3			; must have read/write access at parent dir
	mov	ax,accdeny		;   to truncate
	jb	truncgx
	mov	al,[dbbbuf+si+dclass0]
	call	classlvl
	cmp	al,3			; must have read/write access to dir entry
	mov	ax,accdeny		;   in order to truncate
	jb	truncgx
	mov	ch,[dbbbuf+si+datr]
	test	ch,ro or dir or lbl
	jnz	truncgx			; existing and read-only or dir or label fails
	and	ch,hid			; if hid set in dir entry, then
	push	cx
	and	cl,ch			;   it must also be set in supplied attribute
	cmp	cl,ch
	pop	cx
	jne	truncgx

; must be able to establish exclusive access to file

	call	exclude
	jc	truncgx

; record truncation, date, time and attribute in dir entry

truncga:
	push	cx
	call	timestamp
	mov	di,cx
	pop	cx
	call	rddir
	jc	truncgx
	assume	es:dbb
	mov	word ptr [dbbbuf+si+dtime],di  ; setting new date and time
	mov	word ptr [dbbbuf+si+ddate],dx
	mov	[dbbbuf+si+datr],cl	       ; set new attribute to the one supplied
	mov	word ptr [dbbbuf+si+dsize],0   ; new size is 0
	mov	word ptr [dbbbuf+si+dsize+2],0
	mov	dx,word ptr [dbbbuf+si+dclust] ; (remember it to dealloc it)
	mov	word ptr [dbbbuf+si+dclust],0  ; new starting cluster is 0
	call	wrsector
	jc	truncgx
	call	dealloc			; deallocate all allocated clusters
	jc	truncgx
	call	flushdir		; flush out dir sector and changed fat sectors
	jc	truncgx
	xor	ax,ax
truncgx:
	or	ax,ax
	jz	truncgy
	stc
truncgy:
	pop	di
	ret

	subttl	creatguts - the guts of creating a dir entry
	page
;======================================================================
;,fs
; creatguts - the guts of creating a dir entry
;
; in:	ss:bx -> buffer for sector number
;	dx = parent dir cluster
;	es:di -> name for dir entry
;	ds = bdb
;	cl = attribute for dir entry
;	ah = access level to parent dir
;
; out:	c and ax = error code if error
;	else nc and ax = 0
;	 bx = sector of created entry
;	 si = offset of created entry
;	cx, dx, di undefined
;
;,fe
;======================================================================
	assume	ds:bdb,es:nothing,ss:tcb
lproc	creatguts
lbyte	clvl
lword	secbuf
	mov	[secbuf],bx		; save buffer pointer
	mov	[clvl],ah
	mov	bh,cl
	mov	cx,11

; make sure all the fcb chars are valid for a dir entry

creatga1:
	mov	bl,es:[di]
	cmp	bl,'?'
	mov	ax,pathnf
	je	creatgx
	mov	al,bl
	call	okchar
	mov	bl,al
	mov	ax,pathnf
	jc	creatgx
	mov	al,bl
	stosb
	loop	creatga1
	sub	di,11
	mov	ah,bh
	test	ah,lbl
	jz	creatga

; create a label dir entry in root if none already there

	push	bx
	mov	bx,[secbuf]
	call	makelbl
	pop	bx
	jnc	creatgb
	jmp	creatgx

; validate drive, path, name if attribute not dir

creatga:
	test	ah,dir
	mov	ax,accdeny
	jnz	creatgx			; fail if dir entry attribute bit set (accdeny)
	cmp	[clvl],3
	jb	creatgx
	mov	al,bh
	mov	bx,[secbuf]
	call	create			; make a directory entry
	jc	creatgx			; (probably root full)

; flush out dir and fat sectors whether new or existing dir entry

creatgb:
	call	flushdir		; flush out dir entry sector
	jc	creatgx
	xor	ax,ax
creatgx:
	or	ax,ax
	jz	creatgy
	stc
creatgy:
lundef	clvl
lundef	secbuf
lendp	creatguts

	subttl checkexon - checks the +except/+only exception lists
	page
;======================================================================
;,fs
; checkexon - checks the +except/+only exception lists
;
; in:	ds:si -> 11 byte file name, parsed format
;
; out:	nc if ok to use the file, cy if it should not be used
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
checkexon proc
	cmp	[tcbactseg],0		; does a list exist ?
	jnz	cex6
	clc
	ret				; if no list, return a normal indication
cex6:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	es
	xor	dx,dx			; dh is 'must find' flag, dl is 'did find' flag
	mov	ax,[tcbactseg]
cex15:
	mov	es,ax
	assume	es:nothing
	xor	di,di
	test	byte ptr es:[di],2
	jz	cex16
	mov	dh,1			; when find an 'only' block, must find a match
cex16:					; in an 'only' block to get a normal return
	mov	bx,si
	mov	di,5			; offset of first name in block
	cld
cex11:
	mov	bp,di
	cmp	byte ptr es:[di],'*'
	je	cex7			; done with file name
	mov	cx,8
cex8:
	cmp	byte ptr es:[di],'?'	; a '?' matches anything
	jz	cex9
	mov	al,[si]
	cmp	al,es:[di]
	jne	cex10
cex9:
	inc	di
	inc	si
	loop	cex8
cex7:
	mov	di,bp
	add	di,8
	cmp	byte ptr es:[di],'*'
	je	cex12
	mov	cx,3
	mov	si,bx
	add	si,8
cex13:
	cmp	byte ptr es:[di],'?'
	jz	cex14
	mov	al,[si]
	cmp	al,es:[di]
	jne	cex10
cex14:
	inc	di
	inc	si
	loop	cex13
	jmp	cex12			; made it through - its a match
cex10:					; not a match
	mov	si,bx
	mov	di,bp
	add	di,11
	cmp	byte ptr es:[di],0
	jz	cex5			; found end of block
	jmp	cex11
cex12:
	xor	di,di
	test	byte ptr es:[di],2
	jz	cex2			; found a match in an except list, all done
	mov	dl,1			; set the did find flag
cex5:
	mov	si,bx
	mov	di,1
	mov	ax,es:[di]		; get next pointer
	or	ax,ax
	jnz	cex15			; end of list ?
	or	dh,dh
	jz	cex1
	or	dl,dl
	jnz	cex1
cex2:
	stc
	jmp	cex3
cex1:
	clc
cex3:
	pop	es
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
checkexon endp

ddt	ends
	end

