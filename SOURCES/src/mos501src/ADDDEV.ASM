	include page.inc
	title addev.asm - add a device to device driver chain and activate the driver from any task.

;-----------------------------------------------------------------------;
;			development specification			;
;									;
; program name: adddev.com		assigned to: bob wright 	;
; module name:	adddev.asm		assign date: 4/13/87		;
; entry from:	exec							;
; purpose:	to add a device driver after bootup			;
;-----------------------------------------------------------------------;
; sah 07/12/87	converted 80+ to int 38h 00+ calls			;
;-----------------------------------------------------------------------;
; mjs 7/10/88	Had to fix some bugs in here with command line parsing	;
;		and couldn't deal with the mess - so I overhauled it.   ;
;-----------------------------------------------------------------------;
; mjs 10/22/88	Modify to support task specific device driver loading.	;
;-----------------------------------------------------------------------;
; mjs 12/23/88	Modify command parsing to accept an optional K after	;
;		the memory size.					;
;-----------------------------------------------------------------------;
; SAH 02/20/89	Converted INT 38h calls into MOS SERVICES		;
;-----------------------------------------------------------------------;
; SAH 03/21/89	Remove 386 Reference					;
;-----------------------------------------------------------------------;
; mjs 04/16/89	Modified handling of parameter line which is passed	;
;		to a driver.  Now saving and restoring the character	;
;		that seperates the driver name from the parm tail.	;
;-----------------------------------------------------------------------;
; mjs 08/31/89	Detect and respond to the case where a device driver 	;
;		terminates with cs:0000 as its resident size.  In this 	;
;		case, report an error and terminate.			;
;-----------------------------------------------------------------------;
; BWR 11/16/89  All messages in file marked for foreign language        ;
;               translation.                                            ;
;-----------------------------------------------------------------------;


codeseg segment word public 'code'
	assume cs:codeseg;ds:codeseg;es:codeseg,ss:codeseg

	org	100h
adddev:
	jmp	begin

	include options.inc
	include adddev.pub
	include macros.inc

;======================== EQUATES ==================================

params	equ	80h	; offset for command line variables
true	equ	0ffffh
false	equ	0
cr	equ	13
lf	equ	10

;======================== RELOCATED CODE SECTION =======================

; the following section of code and data is relocated to the top of 
; the tpa memory when a task specific device driver load is to be done.
; this section is designed to start at offset 103h so that subroutine calls
; within this section will have the correct offsets in both the relocated and
; non-relocated cases.

	org	103h

err_fil_rd	db	cr,lf,'Error reading the device driver file    ',cr,lf,'$' ;@@XLAT
err_fil_cls	db	cr,lf,'Error closing the device driver file      ',cr,lf,'$';@@XLAT
outofmem	db	cr,lf,'Device driver larger than available task memory             ',cr,lf,'$';@@XLAT
eojtcb		db	cr,lf,'Device driver installed - task specific                     ',cr,lf,'$';@@XLAT
loadfail 	db	cr,lf,'Failure in device driver installation             ',cr,lf,'$';@@XLAT

buffer	dw	0	; segment address of allocated heap
handle	dw	0	; file handle of device driver file
filesiz dw	0	; least significant word of size
	dw	0	;  most significant word of size
workbuf2 db	128 dup(0) ; second command line parsing buffer
savechar db	0	; temp storage for char in parm lin

;-----------------------------------------------------------------------------;
;			   print string routine 			      ;
;   on entry  cs:dx->  string to be printed that is terminated with a '$'     ;
;-----------------------------------------------------------------------------;
print:
	push	ax
	push	ds
	push	cs
	pop	ds
	mov	ah,9h
	int	21h
	pop	ds
	pop	ax
	ret

;-----------------------------------------------------------------------;
;			       findend					;
;    supply address in ds:si, searches for 0, ds:si points to 0 	;
;-----------------------------------------------------------------------;
findend:
	push	ax
fe1:
	cld
	lodsb
	or	al,al
	jnz	fe1
	dec	si
	pop	ax
	ret

;-----------------------------------------------------------------------;
; load_file								;
;									;
; presumes an open file, handle stored in [handle] and valid data	;
; in the variables [buffer] and [filesiz]				;
; if the file is greater than 64k then load the excess in 32k blocks	;
; and then load the remainder of the file.				;
; close the file							;
;									;
; NOTE: this proc will not return normally in the event of an error.	;
;-----------------------------------------------------------------------;
load_file:
	push	ds
	mov	ds,cs:[buffer]
	assume	ds:nothing
	mov	cx,cs:[filesiz+2]
	jcxz	lastblock
	shl	cx,1		; hi word * 2 to calc # of 32k blocks
rd_loop1:
	push	cx
	mov	cx,8000h	; read 32k
	xor	dx,dx
	mov	bx,cs:[handle]
	mov	ah,3fh
	int	21h
	jc	bad_read
	mov	ax,ds
	add	ax,800h 	; advance to next 32k block
	mov	ds,ax
	pop	cx
	loop	rd_loop1
lastblock:
	mov	cx,cs:[filesiz] ; read the remainder
	jcxz	doneread
	xor	dx,dx
	mov	bx,cs:[handle]
	mov	ah,3fh
	int	21h
	jc	bad_read
doneread:
	pop	ds

; close the device driver file

	mov	ah,3eh
	mov	bx,cs:[handle]
	int	21h
	jc	bad_close
	ret

; error reading the file

bad_read:
	pop	ds
	lea	dx,[err_fil_rd]
	jmp	err_cntrl

; error closing the file

bad_close:
	lea	dx,[err_fil_cls]

err_cntrl:
	cmp	cs:[taskspec],true
	ljne	error_out	; if taskspec == false then it will
err_cntrl2:			; work ok to jump to error_out
	call	print
	mov	ax,4c01h	; errorlevel 1
	int	21h

;-----------------------------------------------------------------------;
; enter_reloc
;-----------------------------------------------------------------------;
enter_reloc:
	call	load_file
	lea	si,[workbuf2]
	call	findend
	mov	byte ptr [si],' '	; remove the 0 seperating the file
	mov	es,[buffer]		; name from the parm line
	xor	bx,bx
	lea	dx,[workbuf2]
	push	cs
	pop	ds

; es:bx -> device driver   ds:di -> parameters of device driver

	mov	ax,0b02h		; call mos to install driver in 
	int	SERVICES		; tcbddpf list (al = 0 to use the
	mov	si,dx			; task specific list)
	mov	dx,offset loadfail
	cmp	al,0			; error from 380b?
	jnz	err_cntrl2
	sub	si,[buffer]		; si is next free seg so calc # 
	jz	err_cntrl2		; of paras to leave resident.
	mov	dx,si
	add	dx,10h			; account for psp
	push	dx
	mov	dx,offset eojtcb	; report loaded ok
	call	print
	pop	dx
	mov	ax,3100h
	int	21h

end_reloc:

;================ END OF RELOCATED CODE SECTION =======================

;================== MESSAGES AND STRING CONSTANTS ==================

	db	8,8,8,'   '
tsl:	db	cr,lf,'PC-MOS Add Device Utility  4.00  ',cr,lf ;@@XLAT
	db	'(c) Copyright 1987, 1988, 1989 The Software Link, Incorporated.' ;@@XLAT
	db	cr,lf
	db	'All rights reserved worldwide. ',cr,lf,'$' ;@@XLAT
	db	8,' '
syntax:
	db	cr,lf,'Syntax:   .Adddev Memsize,DevDriver [Param],[Param]          ',cr,lf,lf ;@@XLAT
	db	      '          Where <Memsize>   =  Is number of K required by driver     ',cr,lf ;@@XLAT
	db	      '                <DevDriver> =  Name of Device driver      ',cr,lf ;@@XLAT
	db	      '                <Param>     =  Are parameters that might be                  ',cr,lf ;@@XLAT
	db	      '                               required by the device driver.       ',cr,lf,'$' ;@@XLAT
	db	8,' ',26

err_dosver	db	cr,lf,'Incorrect MOS Version ',cr,lf,'$' ;@@XLAT
bad_params	db	cr,lf,'Parameters are missing or incorrect    ',cr,lf,'$' ;@@XLAT
out_mem 	db	cr,lf,'Insufficient space in System Memory Pool to add Device.                        ',cr,lf ;@@XLAT
out_mem2	db	'xxxxk Memory available     ',cr,lf,lf,'$' ;@@XLAT
alloc_err	db	cr,lf,'An error occured when program called INT 38H function 0Ah and it was unable    ',cr,lf ;@@XLAT
		db	'to allocate memory from the System Memory Pool',cr,lf,'$' ;@@XLAT
bad_file	db	cr,lf,'Error opening the device driver file.  Check filename and path    ',cr,lf,'$' ;@@XLAT
seek_err	db	cr,lf,'Error seeking EOF of device driver file                        ',cr,lf,'$' ;@@XLAT
install_err	db	cr,lf,'An error was detected when MOS attempted to install driver             ',cr,lf,'$' ;@@XLAT
eojscb		db	cr,lf,'Device driver installed - globally accessible                   ',cr,lf,'$' ;@@XLAT

;======================== DATA AREA ================================

version label	byte
	include version.inc

memsize dw	0	; size of memory device driver
			; needs to be activated
bytes	dw	0	; number of bytes to read from device driver file
allocated dw	false	; flag to show if function int 38h 0ah was called
workbuf1 db	128 dup(0)	; buffer for command line parsing
end_fname dw	0		; store pointer to end of d:\path\fname string
taskspec db	0	; flag to indicate that a task specific driver load
			; is to be done

;======================== RESIDENT SUBROUTINES ==========================

;-----------------------------------------------------------------------;
;				 copystr				;
;  source ds:si, dest es:di.  For cx = 0 xfer until find 0 (0 xfered)	;
;  for cx <> 0, use cx as byte count					;
;-----------------------------------------------------------------------;
copystr:
	push	ax
	push	cx
	jcxz	cs1
	cld
	rep	movsb
	jmp	short cs3
cs1:
	cld
	lodsb
	stosb
	or	al,al
	jnz	cs1
cs3:
	pop	cx
	pop	ax
	ret

;-----------------------------------------------------------------------;
;			       findlen					;
;  supply address in ds:si, returns length in cx (not including the 0)	;
;-----------------------------------------------------------------------;
findlen:
	push	dx
	push	si
	mov	dx,si
	call	findend
	sub	si,dx
	mov	cx,si
	pop	si
	pop	dx
	ret

;-----------------------------------------------------------------------;
;				testdelims				;
;	supply char in al to check for inclusion in delimset		;
;-----------------------------------------------------------------------;
delimset db	';,= ',9,13,0	; set of delimiters

testdelims:
	push	ax
	push	si
	lea	si,[delimset]
	dec	si
ts2:
	inc	si
	cmp	byte ptr [si],0
	je	ts3
	cmp	al,byte ptr [si]
	je	ts1
	jmp	short ts2
ts3:
	xor	al,al
	cmp	al,1
ts1:
	pop	si
	pop	ax
	ret

;-----------------------------------------------------------------------;
;				passdelims				;
;	check for delims at ds:si, on return ds:si points to 1st	;
;	char that isn't a delim, and the char is in al                  ;
;-----------------------------------------------------------------------;
passdelims:
pd1:
	cld
	lodsb
	call	testdelims
	je	pd1
	dec	si
	ret

;-----------------------------------------------------------------------;
;			     finddelim					;
;   ds:si points to the string, on return, ds:si will point to the 1st	;
;   delim charactor found (or a 0) the char will be in al		;
;-----------------------------------------------------------------------;
finddelim:
	cld
fd1:
	lodsb
	call	testdelims
	je	fd2
	or	al,al
	jz	fd2
	jmp	short fd1
fd2:
	dec	si
	ret

;-----------------------------------------------------------------------;
;				low2upper				;
;		convert charactor in reg al to upper case		;
;-----------------------------------------------------------------------;
low2upper:
	cmp	al,'a'
	jb	lu1
	cmp	al,'z'
	ja	lu1
	sub	al,32
lu1:
	ret

;-----------------------------------------------------------------------;
;			     str2upper					;
;	   supply pointer in ds:si, if cx=0 convert the string to upper ;
;  until find a zero, else use cx as the byte count for conversion	;
;-----------------------------------------------------------------------;
str2upper:
	push	si
	push	di
	push	ax
	push	cx
	mov	di,si
	cld
	jcxz	st1
st2:
	lodsb
	call	low2upper
	stosb
	loop	st2
st3:
	pop	cx
	pop	ax
	pop	di
	pop	si
	ret
st1:
	lodsb
	call	low2upper
	stosb
	or	al,al
	jnz	st1
	jmp	short st3

;-----------------------------------------------------------------------;
; convert the incoming number to a ascii string 			;
;									;
; on entry    ds:bx-> place in string to start creating string from	;
;	      right to left.						;
;	      cx   =  number of digits to make string			;
;	      dx:ax=  hexadecimal value to be printed			;
;-----------------------------------------------------------------------;
bin2dec:
	push	si
	push	di
	push	cx
	xor	di,di
	mov	si,cx		; set si to the number of digits the number has
	cmp	si,4		; is it real long?
	jle	btdloop1	; no, skip
	div	cs:[w10000]	; yes, do it piecemeal
	mov	cx,4		; set counter to reflect a 4 digit number
	mov	di,ax		; save low in di, giving it a non zero value
	mov	ax,dx		; move hi word into ax
btdloop1:
	div	cs:[w10]
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
	jmp	short btdloop2
btdret:
	pop	di
	pop	si
	ret

;vars for bin2dec

w10000	dw	10000		; local variables
w10	dw	10		;   "     "

;-----------------------------------------------------------------------;
;    convert the incoming string to a number				;
;									;
;    on entry	 ds:bx-> pointer to string to be converted to a number	;
;		 cx   =  number of digits to make string		;
;    on exit								;
;		 dx:ax=  hexadecimal value to be printed		;
;-----------------------------------------------------------------------;
asc2bin:
	push	cx
	xor	ch,ch
	mov	cl,[bx]
	sub	cx,48
	mov	ax,cx
	inc	bx
	pop	cx
	dec	cx
	cmp	cx,0
	jbe	lv_routine
asc_loop:
	push	cx
	mov	cx,10
	mul	cx
	xor	ch,ch
	mov	cl,[bx]
	sub	cx,48
	add	ax,cx
	adc	dx,0
	inc	bx
	pop	cx
	loop	asc_loop
lv_routine:
	ret

;-----------------------------------------------------------------------;
; parse command line:							;
;									;
; entry parms:								;
;	ds:[params]-> beginning of line to be parsed			;
; exit parms:								;
;	[taskspec] = true if a 't' is detected in the memsize position	;
;	[memsize] =  requested number of paragraphs			;
;	[workbuf1] = fully formed drive\path\fname.ext of driver file	;
;	terminated by a 0.  right after the 0, in the same buffer, is	;
;	the parameter line to be passed to the driver.			;
;									;
; NOTE: this proc will not return normally in the event of an error.	;
;-----------------------------------------------------------------------;
parse:
	cld
	mov	bl,ds:[80h]		; get command line parameter 
	xor	bh,bh			; length in bx
	or	bx,bx
	ljz	parm_error
	mov	si,81h
	mov	byte ptr [bx+si],0	; convert psp parameter line into
	call	passdelims		; an asciiz string
	cmp	al,0
	lje	parm_error
	mov	bx,si			; save start of memory size parm
	call	finddelim
	mov	al,[bx]
	call	low2upper
	cmp	al,'T'
	jne	pr1
	mov	[taskspec],true
	jmp	pr1a
pr1:
	mov	cx,si
	sub	cx,bx			; calc length of mem size parm
	mov	al,[si-1]
	call	low2upper		; allow for the memory size to end
	cmp	al,'K'			; with a K
	jne	pr1b
	dec	cx
pr1b:
	call	asc2bin
	mov	cl,6
	shl	ax,cl			; convert to paragraphs
	mov	[memsize],ax
pr1a:
	call	passdelims		; find start of file name
	lea	di,[workbuf1]
	xor	cx,cx
	call	copystr
	lea	si,[workbuf1]
	xor	cx,cx
	call	str2upper
	lea	si,[workbuf1]
	mov	bx,0
	cmp	byte ptr [si+1],':'	; have a drive letter?
	jne	pr2
	mov	bx,2			; from now on, bx=0 - no drive spec
pr2:
	cmp	byte ptr [si+bx],'\'	; path from root?
	je	pr3
	lea	di,[workbuf2]
	or	bx,bx
	je	pr4			; when path is not from the root
	mov	cx,2			; and there was a drive spec, copy
	call	copystr 		; the drive spec to workbuf2
	jmp	short pr5
pr4:
	mov	ah,19h
	int	21h
	add	al,'A'			; else, read the default drive
	stosb
	mov	al,':'
	stosb
pr5:
	mov	al,'\'
	stosb
	mov	ah,47h			; then put on current dir for that
	mov	si,di			; drive
	mov	dl,[si-3]
	sub	dl,('A'-1)		; 1 for A:, 2 for B:, etc
	int	21h
	lea	si,[workbuf2]
	call	findend
	cmp	byte ptr [si-1],'\'
	je	pr6
	mov	byte ptr [si],'\'
	mov	byte ptr [si+1],0
	jmp	short pr6
pr3:
	lea	di,[workbuf2]
	or	bx,bx
	je	pr7			; when path is not from the root
	mov	cx,2			; and there was a drive spec, copy
	call	copystr 		; the drive spec to workbuf2
	jmp	short pr6
pr7:
	mov	ah,19h
	int	21h
	add	al,'A'			; else, read the default drive
	stosb
	mov	al,':'
	stosb
pr6:
	lea	si,[workbuf2]
	call	findend
	mov	di,si
	lea	si,[workbuf1]
	add	si,bx
	xor	cx,cx			; should now have fully formed
	call	copystr 		; d:\path\fname.ext spec in workbuf1
	mov	byte ptr [di-1],cr	; now, make the parm line end
	lea	si,[workbuf2]		; with a cr and make the 
	call	finddelim		; d:\path\fname string end with
	mov	al,[si]
	mov	[savechar],al
	mov	byte ptr [si],0 	; a 0
	ret

parm_error:
	lea	dx,[bad_params]
	jmp	exit_error

;-----------------------------------------------------------------------;
; allocate_smp								;
;									;
;  allocate memory from the heap using mos function 0a int38.		;
;  memory that is allocated in this fashion is accessible by all users	;
;  on the system.							;
;									;
; NOTE: this proc will not return normally in the event of an error.	;
;-----------------------------------------------------------------------;
allocate_smp:
	push	es
	assume	es:nothing
	mov	ax,0a00h	; call mosheman to allocate a block
	cmp	[memsize],0	; memsize set to get all available memory?
	jnz	alloc_goget
	mov	dx,0fff0h	; let's get it all
	int	SERVICES
	push	dx
	mov	ax,dx
	xor	dx,dx
	mov	cx,5
	div	cx
	pop	dx
	sub	dx,ax
	mov	[memsize],dx	; dx should contain all free memory
	mov	ah,0ah		; set up for call again
	mov	al,0
alloc_goget:
	mov	dx,[memsize]	; set dx to number of paragraphs needed
	int	SERVICES
	cmp	al,0
	jz	alloc_ok
	cmp	al,1		; see if error was not enough memory
	jnz	alloc_error
	jmp	out_of_heap
alloc_ok:
	mov	[buffer],es	  ; save segment out to buffer
	mov	[allocated],true  ; set flag to show memory was allocated
	pop	es
	assume	es:codeseg
	ret

alloc_error:
	lea	dx,[alloc_err]
	jmp	error_out

;-----------------------------------------------------------------------;
; get_size - open the device driver file and measure it.		;
;									;
; entry parms:	filename string expected in [workbuf2]			;
; exit parms:	file handle in [handle] 				;
;		file size in dword [filesiz]				;
;		ax = # of paragraphs required for filesize (rouned up)	;
;		CY if file size larger than ffff paragraphs		;
;									;
; NOTE: this proc will not return normally in the event of an error.	;
;-----------------------------------------------------------------------;
get_size:

; open the device driver file

	mov	ax,3d32h
	lea	dx,[workbuf2]
	int	21h
	ljc	no_file
	mov	[handle],ax

; find the length of device driver file

	mov	ax,4202h	; lseek from end of file, offset 0
	xor	cx,cx
	mov	dx,cx
	mov	bx,[handle]
	int	21h
	ljc	bad_seek
	mov	[filesiz],ax
	mov	[filesiz+2],dx

; rewind the device driver file

	mov	ax,4200h	; lseek from start, offset 0
	xor	cx,cx
	mov	dx,cx
	mov	bx,[handle]
	int	21h
	ljc	bad_seek
	mov	ax,[filesiz+2]	; convert the file size to paragraphs
	mov	bx,[filesiz]
	test	ax,0fff0h
	jnz	chk1
	add	bx,0fh
	mov	cl,4
	shr	bx,cl
	and	ax,0fh
	mov	cl,4
	ror	ax,cl
	or	ax,bx
	clc
	ret
chk1:
	stc
	ret

; error opening up the file

no_file:
	lea	dx,[bad_file]
	jmp	error_out

; error seeking around in file

bad_seek:
	lea	dx,[seek_err]
	jmp	error_out

;======================== MAIN CODE ========================

begin:
	assume	cs:codeseg,ds:codeseg,es:codeseg,ss:codeseg
	mov	ah,30h
	mov	bx,ax		; read the mos version number
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax,word ptr [version]
	jne	vrchk2
	cmp	bx,word ptr [version+2]
	je	goodver
vrchk2:
	lea	dx,[err_dosver] 	; report mismatch
	call	print
	jmp	exit_error

; the parse procedure will test for the task specific option, setting
; the flag [taskspec] to true if detected.

goodver:
	call	parse
	cmp	[taskspec],true
	ljne	ld1

; verify enough space in the task's tpa to hold the file's contents.
; NOTE: even when there is room to load the file - a driver could
; attempt to use more than is available - resulting in a system crash.
; when loading a driver, must know how much room it will need.

	call	get_size	; returns file size and leaves file open
	ljc	insuff_mem
	mov	si,ax		; save file's paragraph count for later

; calculate the size of the chunk of code, data and new stack which will be
; relocated up in the top of available tpa memory.  the new stack will be
; below the moved data/code - in the mirror image position of the psp

	lea	ax,[end_reloc]
	add	ax,0fh
	mov	cl,4
	shr	ax,cl
	mov	bx,cs:[2]	; fetch high segment from psp
	sub	bx,ax		; bx is now starting seg of upper code area
	cli
	mov	ss,bx
	mov	sp,100h 	; start using new stack now
	sti

; calculate size of remaining area and check against file size

	mov	es,bx
	assume	es:nothing	
	mov	ax,cs
	add	ax,10h		; acount for psp
	mov	[buffer],ax
	sub	bx,ax		; bx is now the number of paragraphs that
	cmp	si,bx		; will be available for the driver
	lja	insuff_mem
	mov	si,103h 	; setup to relocate the data/code chunk
	mov	di,si
	lea	cx,[end_reloc]
	sub	cx,103h 	; calc number of bytes in chunk
	cld
	rep	movsb
	push	es
	pop	ds
	push	es
	lea	ax,[enter_reloc]	; enter the relocated code
	push	ax
	retf

; verify enough space in smp buffer for the file's contents
; NOTE: even when there is room to load the file - a driver could
; attempt to use more than is available - resulting in a system crash.
; when using adddev, its important to have an adequate smp margin.

ld1:
	call	get_size	; returns file size and leaves file open
	ljc	out_of_heap
	call	allocate_smp
	cmp	ax,[memsize]
	lja	out_of_heap	; ignoring the file close on error - terminate
	call	load_file	; will do it
	lea	si,[workbuf2]
	call	findend
	mov	al,[savechar]
	mov	byte ptr [si],al	; remove the 0 seperating the file
	mov	es,[buffer]		; name from the parm line
	xor	bx,bx
	lea	dx,[workbuf2]

; es:bx -> device driver   ds:di -> parameters of device driver

	mov	ax,0b00h	; call mos to install driver in scbdrvr
	int	SERVICES	; list (al = 0 for scbdrvr list)
	cmp	al,0
	jnz	error_in_call
	cmp	dx,[buffer]		; if end seg == buffer, driver must 
	jne	load_ok			; have returned cs:0000 as its end 
	lea	dx,[loadfail]		; point
	jmp	load_disp
load_ok:
	lea	dx,[eojscb]
load_disp:
	call	print
	mov	ax,4c00h
	int	21h

;====================== ERROR HANDLERS ===============================

out_of_heap:
	mov	ax,0a00h
	mov	dx,0fff0h
	int	SERVICES
	cmp	[allocated],true	; if a block is allocated, include it
	jne	no_block		; in the accounting
	add	dx,[memsize]
no_block:
	mov	cl,6		; convert paragraphs to # of K
	shr	dx,cl
	mov	ax,dx
	xor	dx,dx
	lea	bx,[out_mem2]
	mov	cx,4		; # of digits to print
	call	bin2dec
	lea	dx,[out_mem]
	jmp	short error_out

insuff_mem:
	lea	dx,[outofmem]
	jmp	short	error_out

error_in_call:
	lea	dx,[install_err]
	jmp	short error_out

exit_error:
	lea	dx,[syntax]

error_out:
	call	print
	cmp	[allocated],true  ; was memory allocated
	jne	no_dealloc	  ; no, jump over this

; deallocate allocated memory if we quit with an error

	mov	es,[buffer]
	mov	dx,[memsize]
	mov	ax,0a01h	; call mosheman to deallocate
	int	SERVICES
no_dealloc:
	mov	ax,4c01h	; errorlevel 1
	int	21h

codeseg ends
	end	adddev

