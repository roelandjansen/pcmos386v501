	title	DISPSER.ASM - PC-MOS Serial # Display Utility
;-----------------------------------------------------------------------;
;		development specification				;
;									;
; Program name: DISPSER.ASM	Assigned to: Stewart Hyde		;
; Module name:	DISPSER		Assign Date: 07/25/90			;
; Entry points: 		Completed: 07/25/90			;
; Entry from:	command processor					;
; Entry method: dispser							;
; Calls:								;
; Purpose:	Display Serial # of MOS on System			;
; Refer to:	Stewart Hyde (MOSINIT2.ASM)				;
; Last Update:	07/25/90						;
;-----------------------------------------------------------------------;

cgroup	group	cseg
cseg	segment	public word 'CODE'

	assume	cs:cgroup,ds:nothing,es:nothing,ss:nothing

	org	100h
start:
	jmp	begin

AskMsg	db	13,10
	db	'Insert next disk to check into Drive A:',13,10
	db	'Press ESC to quit, any other key to check disk.',13,10,10,'$'

created db	'MOS.SYS Serial # '		   
serial	db	'11-99999998$'
loaderr db	'System Disk not in Drive A:    ',13,10,'$'  
readerr1 db	'Error reading $      '				     
readerr db	'MOS.SYS into memory!      '			     
bmoserr db	'Invalid version of PC-MOS detected!      ',13,10,'$'      

CRLF	db	13,10,'$'

curdrive db	0
mosfile	db	'A:\'
	db	'$$MOS.SYS',0

scanmsg	db	'[MOS]'		; text to scan for inside MOS

findoff  dw	0			; offset to [MOS] in buffer
scanoff  dw	0			; offset to [MOS] in INIT code
hidoff	 dw	0			; offset to hidden serial in init code
realoff  dw	0			; offset to real serial message in init code
serialoff dw	0			; offset to serial message in INIT code
startseg dw	0			; start of buffer to store code
lastseg	dw	0			; last segment read in
lastoff dw	0			; last offset read in

single	db	'Single$'
mosmsg	db	' User $'	

;
; The following procedure is use to load the $$MOS.SYS into memory
; This will read the code into memory after code and stack of this 
; program. It will return an error message if $$MOS.SYS is not in
; current directory or error reading program into memory.
;

LoadFile proc	near
	push	es
	mov	ax,[startseg]
	add	ax,1800h
	mov	es,ax
	mov	cx,8000h
	xor	di,di
	rep	stosw
	pop	es
	
	push	ds
	mov	ax,3d00h	; open kernel
	int	21h
	jc	LFError
	mov	bx,ax
	mov	ax,4200h
	mov	cx,1
	mov	dx,0B000h
	int	21h
	mov	ax,[startseg]
	add	ax,1B00h
	mov	[lastseg],ax
	mov	[lastoff],0
LoadLoop:
	mov	cx,0fff0h		; load up to 64k of program into
	mov	ds,cs:[lastseg]		; memory 
	mov	dx,cs:[lastoff]
	mov	ah,3fh
	int	21h
	jc	LRerror
	or	ax,ax			; are we finish reading the program
	jz	LoadEnd			; into memory if so than we are dibe
	mov	dx,ax
	and	dx,000fh		; get remain non-paragraph offset
	mov	cs:[lastoff],dx
	mov	cl,4
	shr	ax,cl
	add	word ptr cs:[lastseg],ax
	jmp	short LoadLoop		; continue on with next read
LoadEnd:
	mov	ah,3eh			; close file
	int	21h
	pop	ds
	clc
	ret
LFError:
	pop	ds			; We had an error opening file
	mov	dx,offset loaderr
	stc
	ret
LRerror:
	mov	dx,offset readerr1	; we had error reading file into
	mov	ah,9			; memory 
	int	21h
	call	disp2$
	mov	dx,offset readerr
	stc
	ret
LoadFile endp

;
; The following routine is use to patch the serial #'s into $$MOS.SYS on
; there disk.
;

CheckMOS proc	near
	push	ds
	mov	ax,[StartSeg]
	add	ax,1B00h		; we want to access init code
	mov	ds,ax
	xor	si,si
	cld
scanlp:
	cmp	si,0f000h		; go to far...then we did not find it
	jna	scancont
	jmp	ModifyErr
scancont:
	lodsb
	cmp	al,byte ptr cs:[scanmsg]
	jne	scanlp
	mov	[findoff],si
	dec	word ptr [findoff]
	lodsw
	cmp	ax,word ptr cs:[scanmsg+1]
	jne	scanlp
	lodsw
	cmp	ax,word ptr cs:[scanmsg+3]
	jne	scanlp
	lodsw
	mov	[scanoff],ax
	lodsw
	mov	[hidoff],ax
	lodsw
	mov	[realoff],ax
	lodsw
	mov	[serialoff],ax
	mov	ax,[findoff]
	sub	ax,[scanoff]
	add	[hidoff],ax
	add	[realoff],ax
	add	[serialoff],ax

	push	es
	push	cs
	pop	es
	mov	si,[serialoff]
	mov	di,offset serial
	cld
	movsw
	mov	al,'-'
	stosb
	mov	cx,4
	rep	movsw
	pop	es

	pop	ds
	clc
	ret
ModifyErr:
	mov	dx,offset bmoserr
	pop	ds
	stc
	ret
CheckMOS endp

;
; This routine is use to display 2 $, which is use for display $$MOS as
; status messages to the user
;

disp2$ 	proc	near
	mov	dl,'$'
	mov	ah,2
	int	21h
	mov	dl,'$'
	mov	ah,2
	int	21h
	ret
disp2$	endp

AskDisk	proc	near
	mov	dx,offset askmsg
	mov	ah,9
	int	21h
	mov	ah,08h
	int	21h
	cmp	al,1bh
	je	AskAbort
	clc
	ret	
AskAbort:
	stc
	ret
AskDisk endp

;
; Start of main code
;

begin:
	mov	ax,offset endofmos+300h	; reserver space for stack
	cli
	mov	sp,ax
	sti
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	ax,cs
	mov	bx,offset endofmos+30fh	; reserving space for stack and code
	mov	cl,4
	shr	bx,cl			; convert to paragraphs
	add	ax,bx
	mov	[StartSeg],ax		; save start segment


MainLoop:	
	call	AskDisk
	jc	AllDone
	mov	dx,offset mosfile
	call	LoadFile		; load image of $$MOS.SYS into memory	
	jnc	loadok
	jmp	badparms
loadok:
	call	CheckMOS		; modified image of MOS
	jc	badparms
	cmp	[serial],'0'
	jne	notsingle
	cmp	[serial+1],'1'
	jne	notsingle
	mov	dx,offset single
	mov	ah,9
	int	21h
	jmp	short douser
notsingle:
	mov	dl,[serial]
	cmp	dl,'0'
	je	not10
	mov	ah,2
	int	21h
not10:
	mov	dl,[serial+1]
	mov	ah,2
	int	21h
douser:
	mov	dx,offset mosmsg
	mov	ah,9
	int	21h
	call	disp2$		; display $$
	mov	dx,offset created
	mov	ah,9
	int	21h
	mov	dx,offset crlf
	mov	ah,9
	int	21h
	jmp	short MainLoop
badparms:
	mov	ah,9
	int	21h
	jmp	Short MainLoop
AllDone:
	mov	ax,4c00h
	int	21h


endofmos label	byte


cseg	ends
	end	start

