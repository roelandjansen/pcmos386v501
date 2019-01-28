	include page.inc
	title	DDTW99GT.ASM - Wyse 99GT Terminal driver module
comment ^============================================================== 
		development specification				
									
 program name:	ddtw99gt.asm			assigned to: jim bean			
 module name:	ddtw99gt			assign date: 09/03/86			
 entry points:	mosterm 			completed: 				
 entry from:	mosint10, mosint16, mosvidrm				
 entry method:	call dword [vector] with ah = function number		
 calls:		i10old (boot interrupt 10h)				
 purpose:	mos interface wyse 99gt					
 refer to:	n/a							
 last update:								
=======================================================================
 implementation notes:							
									
 added mode 80h to setmode - setting hercules mode			
 added bit 4 to register - enabling hercules mode setting		

=======================================================================
									
bwr 11/21/89	messages marked for foreign language translation.       

mjs 05/24/91	added dummy printer status function.

======================================================================^

	include ddtw99gt.pub

true	equ	1
false	equ	1

xpcok	 equ	true		; false to set protocol according to PROTOCOL
cgarptok equ	true		; true if wyse fixes cga rpt bug
hgcrptok equ	true		; true if wyse fixes hgc rpt bug
crsok	 equ	true		; true when wyse fixes bit cursor bug

MOD_TEXT equ	20h
MOD_HERC equ	22h
MOD_CGA  equ	23h


	subttl	group segments and include block definitions
	page

;-----------------------------------------------------------------------;
; access to partition saved registers					;
;-----------------------------------------------------------------------;
;	include MOSREGS.INC

ddtrec	struc
	dd	?
logscr	dd	?
crsofs	dw	?
cols	db	?
port	dw	?
baud	dd	?

attrib	db	?
cursor	dw	?
normal	db	?
print	db	?
string	db	8 dup(0)
tmpatr	db	?		; used by scrolling code
mode	db	?
ctrl	db	?		; last written to terminal control port
crstyp	dw	?		; last cursor type set
	db	?		;rsrvd
ddtrec	ends

ddt	segment para public 'data'	; To force loading with data
	assume	cs:ddt,ds:nothing,es:nothing,ss:nothing

MOSDDTSH equ	this byte
	dd	-1		; filled in with pointer to next driver
	dw	8000h		; signifying a character device
	dw	strat		; device strategy entry point
	dw	inter		; device interrupt entry point
	db	'$$WY99GT'	; device name

if not xpcok
ISXONOFF equ	01h		; which protocol to use
ISXPC	equ	02h
ISDTR	equ	04h
CGAOK	equ	08h
HGCOK	equ	10h

PROTOCOL db	ISXPC or CGAOK or HGCOK
endif


request dd	0

fn	dw	ddtinit	; 0 - init
	dw	ddtnull	; 1 - media check
	dw	ddtnull	; 2 - build bpb
	dw	ddtnull	; 3 - ioctl input
	dw	ddtread	; 4 - read
maxfn	equ	($-fn)/2

strat	proc	far
	mov	word ptr [request],bx
	mov	word ptr [request+2],es
	ret
strat	endp

inter	proc	far
	push	es
	push	ds
	push	si
	push	bx
	push	ax
	mov	bx,cs
	mov	ds,bx

	assume	ds:ddt

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
	mov	es:[bx+3],ax	; store result status
	pop	ax
	pop	bx
	pop	si
	pop	ds
	pop	es
	ret
inter	endp

; null device driver call does nothing
ddtnull proc	near
	mov	ax,0100h	; return no error, done
	ret
ddtnull endp

	subttl	ddtread - return the terminal function vector
	page

; read just returns the terminal function vector
ddtread proc	near
	lds	si,es:[bx+14]
	mov	cx,es:[bx+18]
	mov	word ptr es:[bx+18],0	; nothing read if error
	mov	ax,8103h		; error, done, unknown command
	cmp	cx,4
	jne	ddtrd1			; if not reading exactly 4 bytes
	mov	es:[bx+18],cx				; else read 4 bytes
	mov	word ptr ds:[si],offset SHTERM	; and these are them
	mov	ds:[si+2],cs
	mov	ax,0100h		; no error, done
ddtrd1:
	ret
ddtread endp

	subttl	termfn - all the terminal and keyboard functions for mos
	page

int14h	dd	0

do14h	macro
	pushf
	cli
	call	cs:int14h
	endm

tfn	dw	register
	dw	inkbdata
	dw	outkbctl
	dw	setmode
	dw	setcrstyp
	dw	setcursor
	dw	scrollup
	dw	scrolldn
	dw	wrchatr
	dw	setpalet
	dw	wrtty
	dw	wrstr
	dw	setwindow
	dw	wrcho
	dw	readch
	dw	getscr
	dw	prch
	dw	prstr
	dw	print_stat
endtfn	equ	($-tfn)/2

	assume	ds:nothing,es:nothing,ss:nothing

SHTERM	proc	far
	push	ds
	push	bp
	cmp	ah,endtfn
	jae	termfn1
	mov	bp,bx
	mov	bl,ah
	xor	bh,bh
	shl	bx,1
	xchg	bx,bp
	call	tfn[bp]
termfn1:
	pop	bp
	pop	ds
	ret
SHTERM	endp

	; Error codes
	if	0 eq 0		; No publics for PS

BADPRT	equ	1		; Bad port number
BADBAU	equ	2		; Bad baud rate

	endif

	subttl	register - register port address, receive key buffer flag
	page
;-----------------------------------------------------------------------;
;									;
; register - register port address, receive key buffer flag		;
;									;
;   AH = 00H								;
;	DX = port address 						;
;	DS:SI -> tcbddt for this terminal for this partition		;
;									;
;   returns:								;
;	ES:BX -> key buffer flag					;
;	key buffer flag is <> 0 while scan codes are buffered		;
;	AL = 80H if master console					;
;	     00H if not master console					;
;	AH = 0 if no error						;
;	   = 1 if bad port number 					;
;	   = 2 if bad baud rate						;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
register:
	cmp	word ptr [int14h+2],0
	jne	reg1
	push	ds
	xor	ax,ax
	mov	ds,ax
	lds	ax,dword ptr ds:[14h*4]
	mov	word ptr [int14h],ax
	mov	word ptr [int14h+2],ds
	pop	ds
reg1:
	mov	[si].cursor,-1
	mov	[si].print,-1
	mov	[si].normal,-1
	mov	[si].attrib,-1
	mov	[si].crstyp,-1
	mov	dx,[si].port
	mov	ah,13		; 13 - register the port with SUPERCOM
	do14h
	or	ah,ah		; AH=FF if invalid port number
	jz	reg2
	mov	ah,BADPRT	; Bad port error
	jmp	reg5
reg2:
	push	es
	push	bx
	mov	dx,[si].port
	mov	bx,word ptr [si].baud
	mov	cx,word ptr [si].baud+2
	mov	ax,0403h	; Extended port init, AL=8 data, 1 stop,
	do14h			;   no parity
	or	ah,ah		; =FF if invalid baud rate
	jz	reg3
	mov	ah,BADBAU	; Invalid baud rate error
	jmp	reg4
reg3:
if xpcok
	mov	ax,0502h
	mov	bx,6765h
else
	mov	bx,6765h		; if xpc not supported, then
	mov	ax,0500h		; set protocol according to bits in
	test	[PROTOCOL],ISXPC	; protocol flag
	jz	reg3a
	or	al,02h
reg3a:
	test	[PROTOCOL],ISXONOFF
	jz	reg3b
	or	al,02h
	mov	bx,1311h
reg3b:
	test	[PROTOCOL],ISDTR
	jz 	reg3c
	or	al,04h
reg3c:
endif
	mov	dx,[si].port
	do14h			; No errors returned from this one

	call	settext
	call	setherc
	call	settext

;	mov	ax,6496h	; 96 64 08	; text
;	call	putword		; 00 64 0a	; hercules
;	mov	ax,0020h	; 96 64 08	; text
;	call	putword
;	mov	ax,2264h
;	call	putword
;	mov	ax,6496h
;	call	putword
;	mov	al,20h
;	call	putbyte

	mov	ax,1bh+'u'*256
	call	putword		; attempt to leave monitor mode (if on)
	call	setpcterm
;	mov	[si].ctrl, MOD_TEXT	; in PC text mode
	mov	al,3
	call	setmode
	xor	ah,ah		; No errors
reg4:
	pop	bx
	pop	es
reg5:
	mov	al,50h		; not a master console, 640x200 graphics and
				; hercules graphics allowed, no color
	ret

	subttl	inkbdata - input keyboard scan code
	page
;-----------------------------------------------------------------------;
;									;
; inkbdata - input keyboard scan code					;
;									;
;   AH = 01H								;
;	DS:SI -> tcbddt							;
;									;
;   returns:								;
;	AL = bit 7   - key break if 1, key make or key repeat if 0	;
;	     bits 6-0 - key scan code 01H - 07DH			;
;	key scan code is read non-destructively				;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

inkbdata:
	mov	dx,[si].port
	mov	ah,08h		; receive a character
	do14h
	jnz	kbdat1		; nz if a char is ready
	xor	al,al		; else signal MOS that there is no key
	ret
kbdat1:
	or	al,al
	jnz	kbdat2
	mov	dx,[si].port
	mov	ah,02h
	do14h
	xor	al,al
kbdat2:
	ret

	subttl	outkbctl - clear current scan code from terminal driver
	page
;-----------------------------------------------------------------------;
;									;
; outkbctl - clear current scan code from terminal driver		;
;									;
;   AH = 02H								;
;     AL = bit	7   - clear buffered scan code if 1, ignored if 0	;
;	   bits 6-0 - ignored						;
;     DS:SI -> tcbddt							;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

outkbctl:
	test	al,80h
	jz	kbctl1
	mov	dx,[si].port
	mov	ah,02h
	do14h
kbctl1:
	ret

	subttl	setmode - set terminal mode
	page
;-----------------------------------------------------------------------;
;									;
; setmode - set terminal mode						;
;									;
; AH = 03H								;
;   AL = 00H, 01H - 40x25 text						;
;	02H, 03H, 07H - 80x25 text					;
;	04H, 05H - 320x200 graphics					;
;	06H - 640x200 graphics						;
;									;
;	80H - Hercules graphics mode					;
;									;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> screen buffer					;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

setmode:
	mov	[si].mode,al
	mov	di,cs
	mov	es,di
	cmp	al,4
	jb	setmdt		; setting cga text mode
	cmp	al,7
	je	setmdt		; setting mono text mode
	ja	setmdh		; else probably herc graphics

	cmp	[si].ctrl, MOD_TEXT
	je	setmdg
; here if currently not in text mode and setting cga graphics mode
	call	settext
setmdg:
	mov	ax, 2364h
	call	escword		; into herc graphics
;	mov	[si].ctrl, MOD_CGA
;	call	zeroaddr
;	mov	ax, 0		; clear screen
;	call	putword
;	mov	ax, 0195h
;	call	putword		; duplicate 0
;	mov	ax, 8000 - 1
;	xchg	al, ah
;	call	putword
;	mov	ax, 0B64h
;	call	escword
;	call	zeroaddr
	ret

setmdt:
; here if setting mono or cga text mode
	cmp	[si].ctrl, MOD_TEXT
	je	setmd4		; e if already in text mode
	call	settext
	call	setherc
	call	settext
	; here while setting text mode after in text mode
setmd4:
	mov	[si].attrib,-1
	mov	[si].cursor,-1
	mov	[si].crstyp,-1
	call	setpcterm
	mov	cx,0b0ch
	call	setcrstyp	; set line cursor type
	mov	ah,07h
	call	setattrib	; normal char attribute
	mov	dx,0
	call	xsetcrs		; home cursor
	mov	al,40h
	call	escbyte	; clear screen
	ret
;
; here when setting non-bios mode
setmdh:
	cmp	al,80h
	je	setmdh1	; e when hercules graphics
	ret			; invalid mode being set

setmdh1:
	; setting 720x348 hercules graphics
	cmp	[si].ctrl, MOD_TEXT
	je	setherc
	; currently in cga or hercules graphics
	; switch to text mode (a must if in CGA)
	call	settext


setherc:			; now in text mode, switch to hercules
	mov	ax, 0264h
	call	escword		; into herc graphics
	mov	[si].ctrl, MOD_HERC
	call	zeroaddr
	mov	ax, 0		; clear screen
	call	putword
	mov	ax, 0195h
	call	putword		; duplicate 0  3FFFh times
	mov	ax, 3FFFh
	xchg	al, ah
	call	putword
	mov	ax, 0A64h	; into herc, enable screen
	call	escword
	call	zeroaddr
	ret
	

settext:
	mov	ax, 2064h
	call	escword
	mov	[si].ctrl, MOD_TEXT
	mov	al,40h
	call	escbyte	; clear screen
	mov	ax, 2864h
	call	escword
	ret

setpcterm:
	mov	al,1bh  	; change to pc term except from pcterm
	call	putbyte
	mov	ax,'?v'
	call	putword
	mov	al,1bh		; change to pc graphics from pcterm
	call	putbyte
	mov	ax,'?~'
	call	putword
	ret


zeroaddr:			; set video RAM address to 0
	mov	al, 93h
	call	putbyte
	xor	ax, ax
	call	putword
	ret
	
	subttl	setcrstyp - set cursor type
	page
;-----------------------------------------------------------------------;
;									;
; setcrstyp - set cursor type						;
;									;
; AH = 04H - set cursor type						;
;   CH = begin scan line						;
;   CL = end scan line							;
;   DH = row								;
;   DL = col								;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> screen buffer @ page/row/col			;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

setcrstyp:
	cmp	[si].mode,7	; ignore set cursor type in graphics modes
	je	setct3		; send it exactly for mode 7
	cmp	[si].mode,4
	jb	setct1
	ret
setct1:
; scan lines 00h - 0ch are available - in cga modes we'll be told to
; set 00h - 07h so we double each and make sure neither's > 12
	shl	cl,1
	cmp	cl,12
	jb	setct2
	mov	cl,12
setct2:
	shl	ch,1
	cmp	ch,12
	jb	setct3
	mov	ch,12
setct3:
	cmp	cx,[si].crstyp
	je	setct4
	mov	[si].crstyp,cx
	mov	ah,ch		; start scan line
	mov	al,20h		; code for set cursor attribute
	call	escword
	mov	al,cl		; end scan line
	call	putbyte
setct4:
	ret

	subttl	setcrspos - set physical cursor position
	page
;-----------------------------------------------------------------------;
;									;
; setcrspos - set physical cursor position				;
;									;
; AH = 05H - set physical cursor position				;
;   DH = row								;
;   DL = col								;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> screen buffer @ page/row/col			;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

setcursor:
	cmp	[si].mode,7	; ignore set cursor mode in graphics modes
	je	setcp0
	cmp	[si].mode,4
	jb	setcp0
	ret
setcp0:
	mov	ax,[si].cursor
	inc	al
	cmp	ax,dx
	jne	xsetcrs		; new position = 1 + old position
	mov	[si].cursor,dx
	push	es
	push	di
	push	bx
	les	di,[si].logscr	; just send the character
	mov	ax,es:[di-2]
	mov	bl,al
	call	setattrib
	mov	al,bl
	call	putchar
	pop	bx
	pop	di
	pop	es
	ret

; off to set the cursor
xsetcrs:
	cmp	dx,[si].cursor
	je	xsetc1
	push	cx
	mov	[si].cursor,dx
	mov	al,dh
	xor	ah,ah
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	mov	cx,ax
	shl	ax,1
	shl	ax,1
	add	ax,cx
	xor	dh,dh
	add	ax,dx
	xchg	ah,al
	call	escword
	pop	cx
xsetc1:
	ret

	subttl	scrollup - as described for the IBM PC scroll up function
	page
;-----------------------------------------------------------------------;
;									;
; scrollup - as described for the IBM PC scroll up function		;
; AH = 06H - scroll up							;
;   AL = number of lines to scroll (0 to clear region)			;
;   BL = attribute to use on blanked lines				;
;   CH = top-left-corner row						;
;   CL = top-left-corner col						;
;   DH = bottom-right-corner row					;
;   DL = bottom-right-corner col					;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> screen buffer @ page/row/col			;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

scrollup:
	mov	[si].tmpatr,bl	; attribute for scrolled-in lines
	mov	ah,bl
	mov	bl,al
	push	dx
	call	setattrib	; current attribute for blanked lines
	pop	dx
	or	cl,cl
	jz	sup0a		; z if box starts at col 0
	jmp	sboxup
sup0a:
	mov	al,[si].cols
	dec	al
	cmp	dl,al
	jnb	sup0b		; nb if box ends at last col
	jmp	sboxup

;-----------------------------------------------------------------------;
; here if scrolling/blanking entire lines				;
;-----------------------------------------------------------------------;
sup0b:
	mov	al,bl
	or	al,al
	jz	sup0c
	cmp	al,25
	jb	sup0d
sup0c:
	mov	al,25
sup0d:
	or	al,0c0h	; wyse approach to scrolling up (note that
	mov	ah,ch	;   wyse doc is in error about bit 5)
	call	escword
	mov	al,cl
	mov	ah,dh
	call	putword
	mov	al,dl
	mov	ah,[si].tmpatr
	call	putword
	jmp	supx

;-----------------------------------------------------------------------;
; scrolling/blanking less than entire lines				;
;-----------------------------------------------------------------------;
sboxup:
	push	[si].cursor
	inc	dh
	sub	dh,ch
	or	bl,bl
	jnz	sbxu1
	mov	bl,dh
sbxu1:
	sub	dh,bl
	jbe	sbxu7		; be if clearing box

;-----------------------------------------------------------------------;
; scrolling/blanking less than entire lines				;
; scrolling some, blanking some 					;
;-----------------------------------------------------------------------;
	inc	dl
	sub	dl,cl
	mov	bh,dl		; bh = length of each line

;-----------------------------------------------------------------------;
; write dh lines of length bh getting chars to write starting from	;
;   row ch+bl and col cl in screen buffer				;
;-----------------------------------------------------------------------;
	push	bx
	mov	al,ch
	add	al,bl
	mul	[si].cols
	mov	di,ax
	mov	al,cl
	xor	ah,ah
	add	di,ax
	shl	di,1
	add	di,word ptr [si].logscr ; starting position to copy from
	mov	bl,dh		; number of lines to write
	mov	dx,cx		; starting position for write
; di to start of first line to copy from
sbxu2:
	push	dx
	push	di
	push	di
	call	xsetcrs		; cursor to copy to (start of box line)
	pop	di
	mov	es,word ptr [si].logscr+2
	mov	cl,bh
	xor	ch,ch
sbxu3:
	mov	ax,es:[di]
	push	es
	push	di
	push	ax
	call	setattrib
	pop	ax
	call	putchar
	pop	di
	pop	es
	add	di,2
	loop	sbxu3
	pop	di
	mov	al,[si].cols	; set di -> start of next box line to copy from
	xor	ah,ah
	add	di,ax
	add	di,ax
	pop	dx
	inc	dh
	dec	bl
	jnz	sbxu2
	pop	bx
	call	clrbox		; then blank the rest
	pop	dx
	call	xsetcrs
	jmp	supx

;-----------------------------------------------------------------------;
; scrolling/blanking less than entire lines				;
; clearing the box							;
;-----------------------------------------------------------------------;
sbxu7:
	inc	dl
	sub	dl,cl
	mov	bh,dl		; bh = number of chars/row, bl = number of rows
	mov	dx,cx		; start of box
	call	clrbox
	pop	dx
	call	xsetcrs
supx:
	ret

;-----------------------------------------------------------------------;
; starting at cursor position dx, for bl rows of length bh, clear box	;
;-----------------------------------------------------------------------;
clrbox:
	push	dx
	mov	ah,[si].tmpatr	; attribute for new lines
	call	setattrib
	pop	dx
cbx8:
	push	dx
	call	xsetcrs		; for each line in box
	mov	cl,bh
	xor	ch,ch
cbx9:
	mov	al,' '		; write spaces through the end of the box
	call	putchar
	loop	cbx9
	pop	dx
	inc	dh
	dec	bl
	jnz	cbx8
	ret

	subttl	scrolldn - as described for the IBM PC scroll down function
	page
;-----------------------------------------------------------------------;
;									;
; scrolldn - as described for the IBM PC scroll down function		;
;									;
; AH = 07H - scroll down						;
;   AL = number of lines to scroll (0 to clear region)			;
;   BL = attribute to use on blanked lines				;
;   CH = top-left-corner row						;
;   CL = top-left-corner col						;
;   DH = bottom-right-corner row					;
;   DL = bottom-right-corner col					;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> screen buffer @ page				;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

scrolldn:
	mov	[si].tmpatr,bl	; save attribute for scrolled-in lines
	mov	ah,bl
	mov	bl,al
	push	dx
	call	setattrib	; set attribute for blanked lines
	pop	dx
	or	cl,cl
	jz	sdn0a		; z if box begins at left edge of screen
	jmp	sboxdn		; (else not scrolling entire lines)
sdn0a:
	mov	al,[si].cols
	dec	al
	cmp	dl,al
	jnb	sdn0b		; nb if box ends at right edge of screen
	jmp	sboxdn		; (else not scrolling entire lines)

;-----------------------------------------------------------------------;
; scrolling/blanking entire lines					;
;-----------------------------------------------------------------------;
sdn0b:
	mov	al,bl
	or	al,al
	jz	sdn0c
	cmp	al,25
	jb	sdn0d
sdn0c:
	mov	al,25
sdn0d:
	or	al,0e0h	; wyse approach to scrolling down (note that
	mov	ah,ch	;   wyse doc is in error about bit 5)
	call	escword
	mov	al,cl
	mov	ah,dh
	call	putword
	mov	al,dl
	mov	ah,[si].tmpatr
	call	putword
	jmp	sdnx

;-----------------------------------------------------------------------;
; scrolling/blanking less than entire lines				;
;-----------------------------------------------------------------------;
sboxdn:
	push	[si].cursor
	inc	dh
	sub	dh,ch
	or	bl,bl
	jnz	sbxd1
	mov	bl,dh
sbxd1:
	sub	dh,bl
	jbe	sbxd7		; be if clearing box

;-----------------------------------------------------------------------;
; scrolling/blanking less than entire lines				;
; scrolling some, blanking some 					;
;-----------------------------------------------------------------------;
	inc	dl
	sub	dl,cl
	mov	bh,dl		; bh = length of each line

;-----------------------------------------------------------------------;
; write dh lines of length bh getting chars to write starting from	;
;   row ch+bl and col cl in screen buffer				;
;-----------------------------------------------------------------------;
	push	cx
	push	bx
	mov	al,ch
	add	al,bl
	mov	bl,dh		; number of lines to copy
	mov	dh,al		; start row to copy to
	mov	dl,cl
	mov	al,ch
	mul	[si].cols
	mov	di,ax
	mov	al,cl
	xor	ah,ah
	add	di,ax
	shl	di,1
	add	di,word ptr [si].logscr ; starting position to copy from
; di to start of first line to copy from
sbxd2:
	push	dx
	push	di
	push	di
	call	xsetcrs		; cursor to copy to (start of box line)
	pop	di
	mov	es,word ptr [si].logscr+2
	mov	cl,bh
	xor	ch,ch
sbxd3:
	mov	ax,es:[di]
	push	es
	push	di
	push	ax
	call	setattrib
	pop	ax
	call	putchar
	pop	di
	pop	es
	add	di,2
	loop	sbxd3
	pop	di
	mov	al,[si].cols	; set di -> start of next box line to copy from
	xor	ah,ah
	add	di,ax
	add	di,ax
	pop	dx
	inc	dh
	dec	bl
	jnz	sbxd2

	pop	bx
	pop	dx		; start of box
	call	clrbox		; blank top bl lines of box
	pop	dx
	call	xsetcrs
	jmp	sdnx

;-----------------------------------------------------------------------;
; scrolling/blanking less than entire lines				;
; clearing the box							;
;-----------------------------------------------------------------------;
sbxd7:
	inc	dl
	sub	dl,cl
	mov	bh,dl		; bh = number of chars/row, bl = number of rows
	mov	dx,cx		; start of box
	call	clrbox
	pop	dx		; restore cursor position
	call	xsetcrs
sdnx:
	ret


	subttl	wrchatr - write character and attribute
	page
;-----------------------------------------------------------------------;
;									;
; wrchatr - write character and attribute				;
;									;
; AH = 08H - write character and attribute at row & col & page		;
;   AL = char to write							;
;   BL = attribute to write						;
;   CX = number of times to write					;
;   DH = row								;
;   DL = col								;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> screen buffer @ page/row/col			;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

wrchatr:
	les	di,[si].logscr
	mov	ah,bl
	mov	bx,ax
wrcha1:
	scasw
	jne	wrcha3
	inc	dl
	cmp	dl,[si].cols
	jb	wrcha2
	xor	dl,dl
	inc	dh
	cmp	dh,25
	jae	wrchax
wrcha2:
	loop	wrcha1
	ret
wrcha3:
	sub	di,2
	dec	cx
	jz	wrcha4
	add	di,cx
	add	di,cx
	inc	cx
	std
	repe scasw
	cld
wrcha4:
	inc	cx
	push	dx
	call	setattrib
	pop	dx
wrcha5:
	cmp	dh,24
	jb	wrcha6
	cmp	dl,79
	jae	wrchax
wrcha6:
	push	dx
	call	setcursor
	mov	al,bl
	call	putchar
	pop	dx
	inc	byte ptr [si].cursor	; not col>=80 causes [si].cursor <>
	inc	dl			;   dx and cursor is explictly set
	cmp	dl,[si].cols		;   next time
	jb	wrcha8
	xor	dl,dl
	inc	dh
wrcha8:
	loop	wrcha5
wrchax:
	ret

	subttl	setpalet - set color palette or background color
	page
;-----------------------------------------------------------------------;
;									;
; setpalet - set color palette or background color			;
;									;
; AH = 09H - set color palette or background color			;
;   BL = byte as stored in crt_palette by IBM BIOS			;
;   (BL and 1Fh = background color)					;
;   (BL and 20h = 20h for palette 1 else palette 0			;
;   DS:SI -> tcbddt							;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

setpalet:
	ret

	subttl	wrtty - as described by the IBM PC write tty function
	page
;-----------------------------------------------------------------------;
;									;
; wrtty - as described by the IBM PC write tty function 		;
;									;
; AH = 0AH - write tty at row & col & page				;
;   AL = char to write							;
;   DH = row								;
;   DL = col								;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> screen buffer @ page/row/col			;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
wrtty:
	cmp	al,07h
	jne	wrtty1
	mov	al,42h
	call	escbyte
	jmp	wrttyy
wrtty1:
	cmp	al,08h
	jne	wrtty2
	jmp	wrtty08
wrtty2:
	cmp	al,0ah
	je	wrtty0a
	cmp	al,0dh
	je	wrtty0d
	mov	bl,al
	mov	cx,dx
	call	setcursor
	mov	dx,cx
	les	di,[si].logscr
	mov	ah,es:[di+1]
	call	setattrib
	mov	al,bl
	call	putchar
	inc	dl
	cmp	dl,[si].cols
	jnb	wrtty3		; >= 80 and cursor will be explicitly set next
	mov	[si].cursor,dx
	jmp	wrttyy		;   time it's used
wrtty3:
	xor	dl,dl
	inc	dh
	mov	[si].cursor,dx
	cmp	dh,25
	jb	wrttyy
	dec	dh
	mov	[si].cursor,-1
	mov	di,word ptr [si].logscr
	mov	cx,dx
	dec	cl
	xor	ch,ch
	sub	di,cx
	sub	di,cx
	mov	word ptr [si].logscr,di
	xor	dl,dl
	jmp	wrtty4
wrtty0a:
	inc	dh
	cmp	dh,25
	jb	wrttyx
	dec	dh
wrtty4:
	push	word ptr [si].attrib
	mov	ax,0c1h		; scroll 1 line up (note that wyse
	call	escword		;   doc is in error about bit 5)
	mov	ax,1800h
	call	putword
	mov	al,4fh
	les	di,[si].logscr
	mov	ah,es:[di+1]
	mov	[si].attrib,ah
	call	putword
	pop	ax
	mov	ah,al
	call	setattrib
	jmp	wrttyx
; carriage return unless already at col 0
wrtty0d:
	or	dl,dl
	jz	wrttyy
	xor	dl,dl
	jmp	wrttyx
; backspace, if not at col 0
wrtty08:
	or	dl,dl
	jz	wrttyy
	dec	dl
; set the new cursor position
wrttyx:
wrttyy:
	ret

	subttl	wrstr - write a string of characters and attributes
	page
;-----------------------------------------------------------------------;
;									;
; wrstr - write a string of characters and attributes			;
;									;
; AH = 0BH - write string of characters and attributes at row/col	;
;									;
;   CX = number of chars to write (word length of string)		;
;   AL:DH = row								;
;   DL = col								;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> screen buffer @ page/row/col			;
;   ES:DI -> string							;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
wrstr:
	cmp	[si].mode,4
	jb	wrs0
	cmp	[si].mode,7
	je	wrs0
	jb	wrstrg	; write string to cga graphics
	jmp	wrstrh	; write string to hercules graphics
wrs0:
	cmp	dh,24
	jb	wrs1
	cmp	dl,79
	jae	wrsx
wrs1:
	mov	word ptr [si].logscr,di
	mov	bx,es:[di]
	add	di,2
	push	es
	push	di
	push	dx
	call	xsetcrs
	mov	ah,bh
	call	setattrib
	mov	al,bl
	call	putchar
	pop	dx
	pop	di
	pop	es
	inc	byte ptr [si].cursor	; >=80 means <> dx and cursor pos
	inc	dl			;   will be explictly set next time
	cmp	dl,[si].cols
	jb	wrs3
 	xor	dl,dl
	inc	dh
wrs3:
	loop	wrstr
wrsx:
	ret

; write a string of cga graphics characters to the terminal
wrstrg:
	cld
	push	bp
; position bit cursor @ position for refresh
; dh = line
; dl = col offset
; position is dh * 80 + dl
	shr	dl,1
	cmp	dh,200
	jb	wrstrg0
	pop	bp
	ret
wrstrg0:
	mov	bl,dh
	xor	bh,bh
	shl	bx,1
	shl	bx,1
	shl	bx,1
	shl	bx,1
	mov	ax,bx	; bx = bx * 16
	shl	bx,1
	shl	bx,1
	add	bx,ax	; bx = ( bx * 16 ) * 5 = bx * 80
	mov	al,dl
	xor	ah,ah
	shl	ax,1		; word to byte offset
	add	bx,ax	; + column
	or	bh,80h	; msbit always set
	mov	al,93h	; (set video ram address)
	mov	ah,bh	; msbyte of address
	call	putword
if not crsok
;#### workaround 99gt bug
		cmp	bl,96h
	je	wrsg0
	cmp	bl,64h
	jne	wrsg1
wrsg0:
	dec	bl	; back one word in bit pos
	dec	bl
	dec	dl	; back one word offset
	dec	di	; back one word in buf
	dec	di
	inc	cx	; one more word to write
wrsg1:
;#### end bug workaround
endif
	mov	al,bl	; lsbyte of address
	call	putbyte
wrstrg1:
	mov	ax,es:[di]
	inc	di
	inc	di
	dec	cx
	inc	dl
	call	grword
	jcxz	wrstrgx
	cmp	dl,40
	jb	wrstrg2
	mov	dl,0
	inc	dh
	cmp	dh,200
	jb	wrstrg0
	jmp	wrstrgx
;#jrb >>>> following patched out until wyse fixes repeat write
wrstrg2:
if not cgarptok
if not xpcok
	test	[protocol],CGAOK
	jz	wrstrg1
else
	jmp	wrstrg1
endif
endif
	mov	bp,cx
	mov	bl,40	; can't repeat more than through the end of
	sub	bl,dl	;   the line
	xor	bh,bh
	cmp	bx,cx
	jae	wrstrg3
	mov	cx,bx
wrstrg3:
	mov	bx,cx
	repe scasw
	je	wrstrg4	; e if repeat through end of line
	dec	di		; else back up onto mismatch
	dec	di
	inc	cx
wrstrg4:
	sub	bx,cx	; bx = # words to repeat
	mov	cx,bp
	or	bx,bx
	jz	wrstrg1
	dec	di
	dec	di
	inc	cx
	dec	bx
	jz	wrstrg1		; can't repeat 1
	inc	di
	inc	di
	dec	cx
	inc	bx
	sub	cx,bx	; update words left to send
	mov	al,95h	; send repeats
	mov	ah,bl	; note that first word was sent above
	add	dl,bl
	call	putword
	jcxz	wrstrgx
	cmp	dl,40
	jb	wrstrg1
	mov	dl,0
	inc	dh
	cmp	dh,200
	jae	wrstrgx
	jmp	wrstrg0
;#jrb <<<< end patched out
wrstrgx:
	pop	bp
	ret



; write a string of hercules graphics characters to the terminal
; note that dl is a valid offset into the line,
;   al:dh is the column number
wrstrh:
	push	bp
	cld
	shr	dl,1	; starting word offset
	mov	ah,al
	mov	al,dh
	mov	bp,ax
	cmp	ax,348
	jb	wrstrh1
	pop	bp
	ret
wrstrh1:
; position bit cursor @ position for refresh
; ax = line
; dl = col
; position is ( ax mod 4 ) * 2000h + ( ax div 4 ) * 90 + dl
	mov	ax,bp
	ror	ax,1
	ror	ax,1		; al = ax div 4 (since ax < 1024)
; compute offset of buffer
	shr	ah,1
	and	ah,60h
	mov	dh,ah	; buffer offset / 256
; compute offset into buffer
	mov	ah,00h
	mov	bx,ax	; ax = dh div 4
	shl	ax,1
	shl	ax,1
	add	ax,bx	; ax = ax * 5
	mov	bx,ax	; bx = ax * 5
	shl	ax,1
	shl	ax,1
	shl	ax,1
	add	ax,bx	; ax = ( ax * 5 ) * 9 = ax * 45
	shl	ax,1		; ax = ( ax * 45 ) * 2 = ax * 90
	mov	bl,dl
	xor	bh,bh
	shl	bx,1		; take it to a byte offset
	add	bx,ax	; + column position
	add	bh,dh	; + buffer offset
	or	bh,80h	; msbit always set
	mov	al,93h	; (set video ram address)
	mov	ah,bh	; msbyte of address
	call	putword
if not crsok
;#### workaround 99gt bug
		cmp	bl,96h
	je	wrsh0
	cmp	bl,64h
	jne	wrsh1
wrsh0:
	dec	bl	; back one word in bit pos
	dec	bl
	dec	dl	; back one word offset
	dec	di	; back one word in buf
	dec	di
	inc	cx	; one more word to write
wrsh1:
;#### end bug workaround
endif
	mov	al,bl	; lsbyte of address
	call	putbyte
wrstrh2:
	mov	ax,es:[di]
	inc	di
	inc	di
	dec	cx
	inc	dl
	call	grword
	jcxz	wrstrhx
	cmp	dl,45	; words / line
	jb	wrstrh3
	mov	dl,0
	inc	bp
	cmp	bp,348
	jb	wrstrh1
	jmp	wrstrhx
;#jrb >>>> this code is patched out until repeated write is fixed by wyse
wrstrh3:
if not hgcrptok
if not xpcok
	test	[protocol],HGCOK
	jz	wrstrh2
else
	jmp	wrstrh2
endif
endif
	push	bp
	mov	bp,cx
	mov	bl,45	; words / line
	sub	bl,dl
	xor	bh,bh
	cmp	bx,cx
	ja	wrstrh4
	mov	cx,bx
wrstrh4:
	mov	bx,cx
	repe scasw
	je	wrstrh5	; e if repeated through end of line
	dec	di		; else back up onto differing char
	dec	di
	inc	cx
wrstrh5:
	sub	bx,cx		; bx = number of repeated words
	mov	cx,bp
	pop	bp
	sub	cx,bx		; update remaining to send
	or	bx,bx
	jz	wrstrh2		; no repeats
	dec	di
	dec	di
	inc	cx
	dec	bx
	jz	wrstrh2		; can't repeat 1
	inc	di
	inc	di
	dec	cx
	inc	bx
	mov	al,95h		; send repeats, char to repeat sent above
	mov	ah,bl
	add	dl,ah		; update word offset into line
	call	putword
	jcxz	wrstrhx
	cmp	dl,45
	jb	wrstrh2
	mov	dl,0
	inc	bp
	cmp	bp,348
	jae	wrstrhx
	jmp	wrstrh1
;#jrb <<<< patched out
wrstrhx:
	pop	bp
	ret

; send one graphics word to the terminal, adjusting for control codes
grword:
	push	ax
	cmp	al,97h
	ja	grwrd2
	cmp	al,93h
	jb	grwrd2
; first byte is control escape
	push	ax
	mov	ah,00h
	call	putword
	pop	ax
	mov	al,ah
	mov	ah,00h
	cmp	al,97h
	ja	grwrd1
	cmp	al,93h
	jae	grwrd3
grwrd1:
; first byte is control escape, second byte isn't
	call	putbyte
	pop	ax
	ret
grwrd2:
; first byte isn't control escape
	cmp	ah,97h
	ja	grwrd3	; neither byte is control escape
	cmp	ah,93h
	jb	grwrd3	; neither byte is control escape
; second byte is control escape
	push	ax
	call	putbyte
	pop	ax
	mov	al,ah
	mov	ah,00h
grwrd3:
	call	putword
	pop	ax
	ret
	
	subttl	setwindow - re-display the top or bottom 24 lines
	page
;-----------------------------------------------------------------------;
;									;
; setwindow - re-display the top or bottom 24 lines			;
;									;
; AH = 0CH - put screen 						;
;   AL = 0 - re-display top lines of screen				;
;	1 - re-display bottom lines of screen				;
;   CX = screen length (words)						;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> screen buffer @ page/row/col			;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
setwindow:
	les	di,[si].logscr
	xor	dx,dx
	cmp	[si].mode,4
	jb	setw0
	cmp	[si].mode,7
	jb	setwcg
	jne	setwch
setw0:
	call	wrstr
	ret

setwch:
	push	bp
	mov	cx,348/4
	mov	bx,45
	mov	bp,2000h-90
	mov	ax,-2000h*3
	jmp	setwcg1
setwcg:
	push	bp
	mov	cx,200/4
	mov	bx,40
	mov	bp,-2000h
	mov	ax,bp
setwcg1:
	push	cx
	push	ax
	push	dx
	mov	al,dh
	mov	dh,dl
	xor	dl,dl
	mov	cx,bx
	push	bx
	call	wrstr
	pop	bx
	pop	dx
	inc	dx
	sub	di,bx
	sub	di,bx
	add	di,2000h

	push	dx
	mov	al,dh
	mov	dh,dl
	xor	dl,dl
	mov	cx,bx
	push	bx
	call	wrstr
	pop	bx
	pop	dx
	inc	dx
	add	di,bp

	push	dx
	mov	al,dh
	mov	dh,dl
	xor	dl,dl
	mov	cx,bx
	push	bx
	call	wrstr
	pop	bx
	pop	dx
	inc	dx
	sub	di,bx
	sub	di,bx
	add	di,2000h

	push	dx
	mov	al,dh
	mov	dh,dl
	xor	dl,dl
	mov	cx,bx
	push	bx
	call	wrstr
	pop	bx
	pop	dx
	inc	dx
	pop	ax
	add	di,ax
	pop	cx
	loop	setwcg1
	pop	bp
	ret

	subttl	wrcho - write char only
	page
;-----------------------------------------------------------------------;
;									;
; AH = 0DH - write char only at row & col				;
;   AL = char to write							;
;   CX = number of times to write					;
;   DH = row								;
;   DL = col								;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> screen buffer @ page/row/col			;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
wrcho:
	les	di,[si].logscr
	mov	bl,al
wrcho1:
	scasb
	jne	wrcho3
	inc	di
	inc	dl
	cmp	dl,[si].cols
	jb	wrcho2
	xor	dl,dl
	inc	dh
	cmp	dh,25
	jae	wrchox
wrcho2:
	loop	wrcho1
	ret
wrcho3:
	dec	di
	dec	cx
	jz	wrcho4
	add	di,cx
	add	di,cx
	std
wrcho3a:
	scasb
	jne	wrcho4
	dec	di
	loop	wrcho3a
wrcho4:
	cld
	inc	cx
	inc	di
wrcho5:
	cmp	dh,24
	jb	wrcho5a
	cmp	dl,79
	jae	wrchox
wrcho5a:
	mov	bh,es:[di]
	add	di,2
	push	es
	push	di
	push	dx
	call	setcursor
	mov	ah,bh
	call	setattrib
	mov	al,bl
	call	putchar
	pop	dx
	pop	di
	pop	es
	inc	byte ptr [si].cursor
	inc	dl
	cmp	dl,[si].cols
	jb	wrcho6
	xor	dl,dl
	inc	dh
wrcho6:
	loop	wrcho5
wrchox:
	ret

	subttl	readch - read char/attribute at row & col & page
	page
;-----------------------------------------------------------------------;
;									;
; AH = 0EH - read char/attribute at row & col & page			;
;     (master console only)						;
;   DH = row								;
;   DL = col								;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> screen buffer @ row/col/page			*
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
readch:
	ret

	subttl	getscr - get screen
	page
;-----------------------------------------------------------------------;
;									;
; AH = 0FH - get screen 						;
;     (master console only)						;
;   DS:SI -> tcbddt							;
;   [tcbddt] = dword -> logical screen buffer				;
;   CX = word length to get						;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
getscr:
	ret

	subttl	prch - print a character on the terminal's local printer
	page
;-----------------------------------------------------------------------;
;									;
; prch - print a character on the terminal's local printer		;
;									;
;   AH = 10H								;
;     AL = char to print						;
;	DS:SI -> tcbddt							;
;									;
;   returns AH as in INT 17H call					;
;									;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
prch:
	mov	ah,11h
	ret

	subttl	prstr - print a string on the terminal's local printer
	page
;-----------------------------------------------------------------------;
;									;
; prstr - print a string on the terminal's local printer		;
;									;
;   AH = 11H								;
;   ES:DI -> string to print						;
;   CX = length (bytes) to print					;
;   DS:SI -> tcbddt							;
;									;
;   returns AH as in INT 17H call if all of string can't be printed	;
;	and DI -> first char not printed, CX = number not printed 	;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
prstr:
	mov	al,es:[di]
	inc	di
	push	es
	push	di
	call	prch
	pop	di
	pop	es
	loop	prstr
	ret

	subttl print_stat - get printer status
	page
;======================================================================
;,fs
; print_stat - get printer status
;
; in:	ah = 12h
;	ds:si -> tcbddt
;	al = 0 to initiate a status request
;	   = 1 to check the status and fresh-flag
;
; out:	returns ah as in int 17h call for bad status
;	al = 1 (fresh flag)
;	bx = 0f3c9h  (signature to verify this function is supported)
;
;,fe
;=====================================================================
	assume	ds:nothing,es:nothing,ss:nothing
print_stat proc near
	mov	ah,11h
	mov	al,1
	mov	bx,0f3c9h		; signature
	ret
print_stat endp

	subttl	setattrib - set current attribute
;-----------------------------------------------------------------------;
; set current attriubte to AH						;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
setattrib:
; first normalize the attribute according to the way it should display
; (took hercules + card as the measure for abnormal attributes display)
	push	ax
	mov	al,ah
	and	al,88h
	and	ah,not 88h
	jz	setat2		; char is invisible
	cmp	ah,70h
	jne	setat1
	and	al,not 08h	; reverse video isn't bright
	jmp	setat2
setat1:
	and	ah,not 70h
	cmp	ah,01h
	je	setat2
	mov	ah,07h
setat2:
	or	ah,al
	cmp	[si].attrib,ah
	je	setat3
	mov	[si].attrib,ah
	mov	al,80h
	call	escword
setat3:
	pop	ax
	ret

; send escape prefix, then al, then ah to the terminal
; note: prefix is 0 in text modes, 96 in graphics modes
escword:
	push	ax
	call	escbyte
	pop	ax
	mov	al,ah
	call	putbyte
	ret

; send escape prefix, then al to the terminal
; note: prefix is 0 in text modes, 96 in graphics modes
escbyte:
	mov	ah,al
	xor	al,al
	cmp	[si].ctrl, MOD_TEXT
	je	putword
	mov	al,96h
; send al, then ah to the terminal
putword:
	call	putbyte
	mov	al,ah
	call	putbyte
	ret

	subttl	putchar - prepare to send character to display
;-----------------------------------------------------------------------;
; prepare to send character to display					;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing

; send al to the terminal unless it's 00h, in which case send space
putchar:
	or	al,al
	jnz	putbyte
	mov	al,' '

; send al to the terminal
putbyte:
	push	dx
	push	ax
putby1:
	mov	dx,[si].port
	mov	ah,01h
	do14h
	or	ah,ah
	js	putby1
	pop	ax
	pop	dx
	ret

	subttl	ddtinit - mos device driver init
	page
;-----------------------------------------------------------------------;
; initialization - set driver length and exit				;
;-----------------------------------------------------------------------;
ddtinit proc	near
	lea	dx, ddtmsg
	mov	ah, 9
	int	21h
	mov	word ptr es:[bx+14],offset ddtinit
	mov	es:[bx+16],cs
	mov	ax,0100h
	ret
ddtinit endp

ddtmsg	db	'WY99GT terminal device driver installed           ',13,10,'$';@@XLAT

ddt	ends
	end


