	include page.inc
        title SETMOUSE - Mouse Setup program for PC-MOS/386
;
;*****************************************************************************
;*                                                                           *
;*                        MOS Development Specification                      *
;*                                                                           *
;* Command type:  EXTERNAL              Assigned to:      Stewart Hyde       *
;* Command name:  SETMOUSE              Date assigned:    Sept 10, 1988      *
;*                                      Date completed:   Sept 11, 1988      *
;* Command format: SETMOUSE Port IRQ                                         *
;*                 	                                                     *
;* Purpose:        Sets up mouse driver to port and IRQ                      *
;* Refer to:                                                                 *
;* Last Update:                         By:                                  *
;*                                                                           *
;*      External                Values                  Values               *
;*      routines                passed                  returned             *
;* ------------------------------------------------------------------------- *

;------------------------------------------------------------------;
; SAH 10/03/88	Added support for Microsoft Mouse 6.14		   ;
;------------------------------------------------------------------;
; SAH 01/19/89	Added support for Microsoft Mouse 6.24		   ;
;------------------------------------------------------------------;
; SAH 03/21/89	Remove 386 reference.				   ;
;------------------------------------------------------------------;
; BWR 11/30/89	Marked messages for foreign language translation.  ;
;------------------------------------------------------------------;
disp	macro	msg
	mov	dx,offset msg
	mov	ah,9
	int	21h
	endm

mainseg  segment para
	assume cs:mainseg,ds:mainseg
	org	80h
operands label byte	     ; drive:path specified here
	org	100h

start:
	jmp	begin
	db	3 dup (8), 3 dup (' ')

	page
;--------------------------------------------------------------------;
;			    data areas				     ;
;--------------------------------------------------------------------;

msghelp db    13,10
	db    'PC-MOS Mouse Setup v1.02 Release 03/21/89',13,10 ;@@XLAT
	db    '(c) Copyright 1988, 1989 The Software Link, Incorporated',13,10 ;@@XLAT
	db    'All rights reserved worldwide ',13,10,10 ;@@XLAT
	db    '$',8,' ',26

minstall db	' succesfully patched.         ',13,10,'$' ;@@XLAT
mfail	db	'Mouse driver not patched.  $       ' ;@@XLAT
mdriver db	13,10
	db	'Driver is not currently supported           ' ;@@XLAT
	db      'by SETMOUSE.COM.        ',13,10,'$' ;@@XLAT
mnone	db	'Driver is not in current directory.             ',13,10,'$' ;@@XLAT
mbadirq db	'Invalid IRQ (Only IRQ 2 - 7).            ',13,10,'$' ;@@XLAT
msyntax	db	'Invalid command line.        ',13,10 ;@@XLAT
	db	'Syntax:  SETMOUSE Port Irq - To setup new mouse driver                      ' ;@@XLAT
	db	13,10
	db	'         SETMOUSE ?        - for list of supported drivers                  ' ;@@XLAT
	db	13,10,'$'
mabort	label	byte
msgcrlf	db	13,10,'$'
msgspc	db	'00:  $'
ask1	db	'Do you wish to create a $        ' ;@@XLAT
ask2	db	' Mouse Driver (Y/N)       ',13,10,10,'$'  ;@@XLAT
mouse2a	db	'Use $     ' ;@@XLAT
mouse2b db	' 2 to activate MOUSE.                          ',13,10,'$' ;@@XLAT
msglist	db	'Current Mouse drivers supported:      ',13,10,10,'$' ;@@XLAT
msg611	db	'Microsoft Mouse driver version 6.11$    ' ;@@XLAT
msg614	db	'Microsoft Mouse driver version 6.14$    ' ;@@XLAT
msg624	db	'Microsoft Mouse driver version 6.24$    ' ;@@XLAT
msg341	db	'Logitech Mouse driver version 3.41$     ' ;@@XLAT
portirq	db	' Using Hardware Port    ' ;@@XLAT
mport	db	'xxxx and IRQ ' ;@@XLAT
mirq	db	'x',13,10,'$'
mouse   db	'MOUSE.COM',0
newmouse db	'M'
nport	db	'xxxxI'
nirq	db	'x.COM',0
yesmsg	db	'Yes   ' ;@@XLAT
nomsg	db	'No    ' ;@@XLAT
word16	dw	16
cleanfg db	'N'
drvfound db	'N'		; is driver found on disk
dolist	db	'N'		; flag to indicate to do support list
port	dw	0		; storage for port
irq	db	0		; storage for irq
driver  db	00		; driver type specify
				; 01 = Microsoft
dmsg	dw	0		; driver message
dset	dw	0		; driver setup
dinstr	dw	0		; driver instruction
drvseg	dw	0		; driver segment for load
drvlen	dw	0		; driver lenght
virq	db	0		; irq interupt value
vmask	db	0		; irq mask value

;
;	The following is a list of supported MOUSE's

mlist	label	word
	dw	offset	msg611	; Microsoft MOUSE.COM Version 6.11
	dw	offset	msg614	; Microsoft MOUSE.COM Version 6.14
	dw	offset	msg624	; Microsoft MOUSE.COM Version 6.24
	dw	offset  msg341  ; Logictech MOUSE.COM Version 3.41
	dw	0		; *** End of List ***


	subttl CHKPARM - check command line parameters
	page
;-----------------------------------------------------------------------;
; CHKPARM								;
;									;
; Check command parameters and setup associated variables		;
; OUTPUT:								;
;	Carry:								;
;		if dolist = 'Y'  user request list of drivers		;
;		otherwise command line error				;
;	No Carry:							;
;		[port] = requested port					;
;		[irq]  = requested irq					;
;-----------------------------------------------------------------------;

chkparm	proc	near
	mov	si,offset operands+1
	call	nextopnd
	jz	cpbad
	cmp	byte ptr [si],'?'		; cleck for list command
	jne	cpcont
	mov	[dolist],'Y'			; indicate to do list
	jmp	cpbad
cpcont:
	mov	bx,si
	call	hextobin
	mov	[port],ax
	call	nextopnd
	jz	cpbad
	mov	bx,si
	call	hextobin
	cmp	al,2
	jb	cpbadirq
	cmp	ax,7
	ja	cpbadirq
	mov	[irq],al
	clc
	ret
cpbadirq:
	mov	dx,offset mbadirq
	jmp	error
cpbad:
	stc	
	ret
chkparm endp


	subttl CHKDRIVER - reads driver into memory and check if it is ok
	page
;-----------------------------------------------------------------------;
; CHKDRIVER								;
;									;
; Reads driver into memory and setups driver specific memory		;
; Returns:								;
;	[driver] = 00	- driver not found or not supported.		;
;	[driver] <> 00  - driver verify and loaded into memory		;
;		[dmsg]  - offset driver specific message for display	;
;		[dset]	- driver specific setup routine			;
;									;
; Current drivers supported:						;
;	01 - Microsoft Mouse version 6.11				;
;-----------------------------------------------------------------------;

chkdriver proc	near
	push	es
;
;	calculate place to put driver
;
	mov	ax,cs
	lea	bx,endofmos+15
	mov	cl,4
	shr	bx,cl
	add	ax,bx
	mov	[drvseg],ax
;
;	open driver
;	
	lea	dx,mouse
	mov	ax,3d00h
	int	21h
	jc	chk00
	mov	[drvfound],'Y'
	mov	bx,ax
	xor	dx,dx
	mov	ds,[drvseg]
	mov	cx,0f000h
	mov	ah,3fh
	int	21h
	jnc	chk01
chk00:
	jmp	chkdone
chk01:
	mov	cs:[drvlen],ax
	mov	ah,3eh
	int	21h
	push	ds
	pop	es
	push	cs
	pop	ds
;
;	check	for Microsoft Mouse 611
;	'6.11'	at offset 3831h of bufffer
;
	cmp	word ptr es:[3831h],2e36h
	jne	not611
	cmp	word ptr es:[3833h],3131h
	je	ms611
not611:
;
;	check for Microsoft Mouse 614
;	'6.14' at offset 3891
;
	cmp	word ptr es:[3891h],2e36h
	jne	not614
	cmp	word ptr es:[3893h],3431h
	je	ms614
not614:
;
;	check for Microsoft Mouse 624
;	'6.24' at offset 3906h
;
	cmp	word ptr es:[3906h],2e36h
	jne	not624
	cmp	word ptr es:[3908h],3432h
	je	ms624
not624:
;
;	check for LogicTech MOUSE 341
;	'3.41' at offset 2e0ah of buffer
;
	cmp	word ptr es:[2e0ah],2e33h
	jne	not341
	cmp	word ptr es:[2e0ch],3134h
	je	lt341
not341:
	jmp	chkdone
ms624:
	mov	[driver],04h
	mov	[dmsg],offset msg624
	mov	[dset],offset set624
	jmp	chkdone
lt341:
	mov	[driver],03h
	mov	[dmsg],offset msg341
	mov	[dset],offset set341
	mov	[dinstr],offset instr341
	jmp	chkdone	
ms614:
        mov	[driver],02h
	mov	[dmsg],offset msg614
	mov	[dset],offset set614
	jmp	chkdone
ms611:	
	mov	[driver],01h
	mov	[dmsg],offset msg611
	mov	[dset],offset set611
chkdone:
	push	cs
	pop	ds
	pop	es
	ret
chkdriver endp

	subttl - Utility Routines
	page
;
; Utility routine to make new driver in the format or
;		 M[port]I[irq].COM
;

makenew	proc	near
	lea	bx,nport+3
	mov	cx,4
	mov	ax,[port]
	call	bintohex
	mov	al,[irq]
	add	al,'0'
	mov	[nirq],al
	ret
makenew	endp

;
; Utility routine to write out new driver
;

writedrv proc	near
	push	ds
	call	makenew	
	lea	dx,newmouse
	mov	ah,3ch
	xor	cx,cx
	int	21h
	mov	bx,ax
	mov	cx,[drvlen]
	mov	ds,[drvseg]
	xor	dx,dx
	mov	ah,40h
	int	21h
	mov	ah,3eh
	int	21h
	pop	ds
	ret
writedrv endp	

;
; Utility routine to display driver, port and irq to user
;

dispdriver proc	near
	mov	dx,[dmsg]
	mov	ah,9
	int	21h
	lea	bx,mport+3
	mov	ax,[port]
	mov	cx,4
	call	bintohex
	mov	al,[irq]
	add	al,'0'
	mov	[mirq],al
	disp	portirq
	ret
dispdriver endp

;
; Utility routine to display new driver
;

dispnew	proc	near
	lea	si,newmouse
askloop:
	lodsb
	or	al,al
	jz	asknext
	mov	dl,al
	mov	ah,2
	int	21h
	jmp	short askloop
asknext:
	ret
dispnew	endp

;
; Utility routine to ask use if driver info is ok
;

askdriver proc	near
	call	makenew
	disp	ask1
	call	dispnew
	disp	ask2
asklp:
	mov	ah,07h
	int	21h
	and	al,0dfh
	cmp	al,[yesmsg]
	je	askyes
	cmp	al,[nomsg]
	jne	asklp
	stc
	ret
askyes:
	clc	
	ret
askdriver endp

;
; Utility routine to setup irq INT and MASK
;

setirq	proc	near
	mov	al,[irq]
	mov	cl,al
	add	al,8		; change IRQ 2 to INT 8 ....
	mov	[virq],al
	xor	ch,ch
	mov	al,1
siloop:
	shl	ax,1
	loop	siloop
	not	al
	mov	[vmask],al
	ret
setirq	endp

	subttl DISPLIST - display list of drivers
	page
;-----------------------------------------------------------------------;
; DISPLIST								;
;									;
; Diplays list of drivers supported by this program.  The list is a     ;
; group of offset to messages terminated by word of 0			;
;-----------------------------------------------------------------------;
	
displist proc	near
	 disp	msglist
	 lea	si,mlist
dlloop:
	lodsw
	or	ax,ax
	jz	dldone
	push	ax
	cmp	byte ptr [msgspc+1],'9'
	jne	dl1
	mov	byte ptr [msgspc+1],'0'
	inc	byte ptr [msgspc]
	jmp	short dl2
dl1:
	inc	byte ptr [msgspc+1]
dl2:
	disp	msgspc
	pop	ax
	mov	dx,ax
	mov	ah,9
	int	21h
	disp 	msgcrlf
	jmp	short dlloop
dldone:
	xor	al,al
	ret
displist endp


	subttl - SET611 - setup mouse driver for Microsoft MOUSE.COM 6.11
	page
;-----------------------------------------------------------------------;
; SET611 								;
;									;
;	Offset		value 		description			;
; --------------------------------------------------------------------- ;
;	00A1h (WORD)	 [port]		COM Port			;
;	00A3h		 [virq]		IRQ Interupted			;
;	00A4h		 [vmask]	IRQ 8259 Mask			;
;	0748h		 1BEBh		patch code			;
;	07AFh		 F877h		patch code			;
;-----------------------------------------------------------------------;
	
set611	proc	near
	push	es
;
;	process IRQ information
;
	call	setirq
	mov	es,[drvseg]
	mov	al,[virq]
	mov	byte ptr es:[0a3h],al
	mov	al,[vmask]
	mov	byte ptr es:[0a4h],al
	mov	word ptr es:[748h],1bebh
	mov	word ptr es:[7afh],0f877h
;
;	process port information
;
	mov	ax,[port]
	mov	word ptr es:[0a1h],ax
	pop	ds
	ret
set611	endp

	subttl - SET614 - setup mouse driver for Microsoft MOUSE.COM 6.14
	page
;-----------------------------------------------------------------------;
; SET614 								;
;									;
;	Offset		value 		description			;
; --------------------------------------------------------------------- ;
;	00A2h (WORD)	 [port]		COM Port			;
;	00A4h		 [virq]		IRQ Interupted			;
;	00A5h		 [vmask]	IRQ 8259 Mask			;
;	071Ah		 1BEBh		patch code			;
;	0781h		 77h		patch code			;
;	0789h		 77h		patch code			;
;-----------------------------------------------------------------------;
	
set614	proc	near
	push	es
;
;	process IRQ information
;
	call	setirq
	mov	es,[drvseg]
	mov	al,[virq]
	mov	byte ptr es:[0a4h],al
	mov	al,[vmask]
	mov	byte ptr es:[0a5h],al
	mov	word ptr es:[71ah],1bebh
	mov	byte ptr es:[781h],077h
	mov	byte ptr es:[789h],077h
;
;	process port information
;
	mov	ax,[port]
	mov	word ptr es:[0a2h],ax
	pop	ds
	ret
set614	endp


	subttl - SET624 - setup mouse driver for Microsoft MOUSE.COM 6.24
	page
;-----------------------------------------------------------------------;
; SET624								;
;									;
;	Offset		value 		description			;
; --------------------------------------------------------------------- ;
;	00A3h (WORD)	 [port] 	COM Port			;
;	00A5h		 [virq] 	IRQ Interupted			;
;	00A6h		 [vmask]	IRQ 8259 Mask			;
;	0724h		 1bebh		patch code			;
;	078bh		 77h		patch code			;
;	07a2h		 77h		patch code			;
;	088dh		 77h		patch code			;
;-----------------------------------------------------------------------;
	
set624	proc	near
	push	es
;
;	process IRQ information
;
	call	setirq
	mov	es,[drvseg]
	mov	al,[virq]
	mov	byte ptr es:[0a5h],al
	mov	al,[vmask]
	mov	byte ptr es:[0a6h],al
	mov	word ptr es:[724h],1bebh
	mov	byte ptr es:[78bh],077h
	mov	byte ptr es:[7a2h],077h
	mov	byte ptr es:[88dh],077h
;
;	process port information
;
	mov	ax,[port]
	mov	word ptr es:[0a3h],ax
	pop	ds
	ret
set624	endp

	subttl - SET341 - setup mouse driver for Logictech MOUSE.COM 3.41
	page
;-----------------------------------------------------------------------;
; SET341 								;
;									;
;	Offset		value 		description			;
; --------------------------------------------------------------------- ;
;	0153h	(WORD)	[Port]		COM Port			;
;	0155h		[virq]		IRQ Interupt			;
;	0156h		[vmask]		IRQ 8259 Mask			;
;-----------------------------------------------------------------------;
	

set341  proc	near
	push	es
	call	setirq
	mov	es,[drvseg]
	mov	di,153h		
	mov	ax,[port]
	stosw
	mov	al,[virq]
	stosb
	mov	al,[vmask]
	stosb
	pop	es
	ret
set341  endp

instr341 proc	near
	disp	mouse2a
	call	dispnew
	disp	mouse2b
	ret
instr341 endp

	subttl	Main Code
	page
;--------------------------------------------------------------------;

begin:
	disp	msghelp
	call	chkparm		; check parms
	jnc	b1
	cmp	[dolist],'Y'
	je	listout
	mov	dx,offset msyntax
	jmp	short error
b1:
	call	chkdriver	; chkdriver
	cmp	[driver],00	; driver ok
	jne     b2
	cmp	[drvfound],'Y'	; driver found
	je	b1a
	mov	dx,offset mnone
	jmp	short error
b1a:	
	mov	dx,offset mdriver
	jmp	short error
b2:	
	call	dispdriver
	call	askdriver
	jnc	noerror
	mov	dx,offset mabort
	jmp	short error

noerror:
	call	word ptr [dset]	; set up driver
	call	writedrv	; write new driver out
	mov	dx,[dmsg]
	mov	ah,9
	int	21h
	disp	minstall 
	cmp	word ptr [dinstr],0
	je	noinstr
	call	word ptr [dinstr]
noinstr:
	xor	al,al
	jmp	short done

listout:
	call	displist
	jmp	short done

error:
	push	dx
	disp	mfail			; display fail message
	pop	dx
	mov	ah,9			; display error message
	int	21h
	mov	al,1			

done:
	mov	ah,4ch
	int	21h


	subttl - Utility routines from MOXMOS.INC
	page
;------------------- binary-to-hexadecimal routine ------------------;
bintohex proc
	push  si
	mov   dl,4
bthloop1:
	mov   si,ax
	and   si,000fh
	mov   cl,[hextable+si]
	mov   [bx],cl
	mov   cl,4
	shr   ax,cl
	dec   bx
	dec   dl
	jg    bthloop1
	pop   si
	cmp   [cleanfg],'Y'
	je    clean
	ret
clean:
	mov	cx,4
	push	bx
cleanlp:
	inc	bx
	cmp	byte ptr [bx],'0'
	jne	cleandn
	mov	byte ptr [bx],' '
	loop	cleanlp
cleandn:
	pop	bx
	ret
hextable db    '0123456789ABCDEF'
bintohex endp

;---------------------hexadecimal-to-binary routine --------------------;
hextobin proc
	xor   ax,ax		    ; ax will contain the result
hexloop:
	mov   dl,[bx]
	cmp   dl,'0'
	jb    hexwrap
	cmp   dl,'9'
	jbe   noltr
	and   dl,0dfh		    ; insure uppercase
	cmp   dl,'A'
	jb    hexwrap
	cmp   dl,'F'
	ja    hexwrap
	sub   dl,'A'
	inc   dl
	add   dl,'9'
noltr:
	push  dx
	mul   [word16]
	pop   dx
	xor   dh,dh
	sub   dl,'0'
	add   ax,dx
	inc   bx
	jmp   hexloop
hexwrap:
	ret
hextobin endp

;------------------------ locate next operand -----------------------;
nextopnd proc
	cmp   byte ptr [si],0dh     ; check for end
	je    nextoprt
	cmp   byte ptr [si],','     ; skip comma'S
	je    nextopl2
	cmp   byte ptr [si],20h     ; scan for space
	je    nextopl2
	inc   si
	jmp   nextopnd
nextopl2:
	inc   si
	cmp   byte ptr [si],0dh
	je    nextoprt
	cmp   byte ptr [si],20h     ; scan for non-space
	je    nextopl2
nextoprt:
	ret			    ; zf=1 means end of operands
nextopnd endp

endofmos:

	if1
	 %out pass 1  completed
	else
	 %out pass 2  completed
	endif

mainseg  ends
	end   start
