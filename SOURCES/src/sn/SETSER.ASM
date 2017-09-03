	title	SETSER.ASM - PC-MOS Physical Serial # Initilaizer
;-----------------------------------------------------------------------;
;		development specification				;
;									;
; Program name: INIT.ASM	Assigned to: Stewart Hyde (Self)	;
; Module name:	INIT 		Assign Date: 06/26/90			;
; Entry points: 		Completed:   06/26/90			;
; Entry from:	command processor					;
; Entry method: init serial[,Drive]				      	;
; Calls:								;
; Purpose:	Creates Physical Serial # for PC-MOS 4.10 or higher   	;
; Refer to:	Stewart Hyde (MOSINIT2.ASM)				;
; Last Update:	06/26/90						;
;-----------------------------------------------------------------------;

DEBUG	equ	1

cgroup	group	cseg
cseg	segment	public word 'CODE'

;	include setser.pub

	assume	cs:cgroup,ds:nothing,es:nothing,ss:nothing

	org	100h
start:
	jmp	begin
	db	8,8,8,'   '

msg	db	13,10
	db	'PC-MOS Physical Serial Initializer Version 1.00 (900626)             ',13,10  	;@@XLAT	
	db	'Copyright 1990 The Software Link, Incorporated         ',13,10			;@@XLAT
	db	'For TSL Internal Use Only       ',13,10,10
	db	'$',8,' ',26



msgnbad db	'Invalid Serial # Given!',13,10,'$      '	    ;@@XLAT
msgsyn	db	'Invalid Syntax:     ',13,10		  	    ;@@XLAT
	db	'INIT Serial-NO [,Drive]            '	  	    ;@@XLAT
crlf	db	13,10,'$'

created db	'MOS.SYS created with Serial # '		     ;@@XLAT
serial	db	'11-99999998',13,10,'$'

loaderr db	'MOS.SYS not found in current directory!    ',13,10,'$'  ;@@XLAT
readerr1 db	'Error reading $      '				     ;@@XLAT
readerr db	'MOS.SYS into memory!      '			     ;@@XLAT
backerr db	'Error writing backup file!       ',13,10,'$'	     ;@@XLAT
writerr	db	'Error writing serialize version to disk!      ',13,10,'$' ;@@XLAT
bmoserr db	'Invalid version of PC-MOS detected!      ',13,10,'$'      ;@@XLAT	
baddrv	db	'Invalid destination drive specified!        ',13,10,'$'   ;@@XLAT

curdrive db	0
outfile	db	'A:\'
mosfile	db	'$$MOS.SYS',0
mosback db	'$$MOS.ORG',0
scanmsg	db	'[MOS]'		; text to scan for inside MOS

findoff  dw	0			; offset to [MOS] in buffer
scanoff  dw	0			; offset to [MOS] in INIT code
hidoff	 dw	0			; offset to hidden serial in init code
realoff  dw	0			; offset to real serial message in init code
serialoff dw	0			; offset to serial message in INIT code
startseg dw	0			; start of buffer to store code
lastseg	dw	0			; last segment read in
lastoff dw	0			; last offset read in
readhi	dw	0
readlow	dw	0	      
writehi	dw	0
writelow dw	0		
SetDate	db	'N'			; flag use during SaveFile for date
					; stamping
FileTime dw	0			; file time stamp
FileDate dw	0			; file date stamp

single	db	'Single$'
mosmsg	db	' User $'	


userser	db	10 dup (0)

if	DEBUG
serialmsg db	13,10
	db	'Serial #.......................$'
endif

;
; The following procedure is use to get parameters from user and place the
; serial # and access IF
;
; serial # must be in the following format
;	XX-YYYYYY [,] YYYYYY [ [,] D]  where
;	  X is a digit  (0 - 9)
;         Y is a apha or digit (A - Z or 1 - 9)
;	  D is option drive letter
;

getparms proc	near
	mov	si,81h
gpaccess:
	lodsb
	cmp	al,' '
	je	gpaccess
	cmp	al,','
	je	gpaccess
	cmp	al,13
	je	badaccess
	mov	di,offset userser
	mov	cx,10
	dec	si
accloop:
	lodsb
	cmp	al,'0'
	jb	acc1
	cmp	al,'9'
	jbe	setacc
acc1:
	and	al,0dfh
	cmp	al,'A'
	jb	badaccess
	cmp	al,'Z'
	ja	badaccess
setacc:
	stosb
	loop	accloop
donelp:
	lodsb
       	cmp	al,' '
	je	donelp
	cmp	al,','
	je	donelp
	cmp	al,13
	je	gpend
;
;	check out drive specified on command line
;
	and	al,0dfh
	cmp	al,'A'
	jb	badaccess
	cmp	al,'Z'
	ja	badaccess
	mov	[outfile],al
	sub	al,'A'
	inc	al
	mov	dl,al			; set current drive to destination
	mov	ah,0eh	
	int	21h
	mov	ah,19h			; get current drive
	int	21h
	cmp	al,dl			; is current drive what you expected?
        pushf
	mov	dl,[curdrive]		
	mov	ah,0eh			; set current drive back to original
	int	21h
	popf
	je	gpend			; yes it is what I expected
	mov	dx,offset baddrv	; no issue error message	
	jmp	short baderror	

badaccess:
	mov	dx,offset msgnbad
baderror:
	stc
	ret
gpend:	
	clc
	ret
getparms endp

;
; The following procedure is use to load the $$MOS.SYS into memory
; This will read the code into memory after code and stack of this 
; program. It will return an error message if $$MOS.SYS is not in
; current directory or error reading program into memory.
;

LoadFile proc	near
	push	ds
	mov	ax,3d00h	; open kernel
	int	21h
	jc	LFError
	mov	bx,ax
	mov	ax,5700h	
	int	21h
	jc	LRError
	mov	[FileTime],cx
	mov	[FileDate],dx
	mov	ax,[startseg]
	mov	[lastseg],ax
	mov	[lastoff],0
	mov	[readlow],0
	mov	[readhi],0
LoadLoop:
	mov	cx,0fff0h		; load up to 64k of program into
	mov	ds,cs:[lastseg]		; memory 
	mov	dx,cs:[lastoff]
	mov	ah,3fh
	int	21h
	jc	LRerror
	or	ax,ax			; are we finish reading the program
	jz	LoadEnd			; into memory if so than we are dibe
	add	cs:[readlow],ax
	adc	word ptr cs:[readhi],0	; accumulate size of kernel
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
	call	disp2$			; file must be current directory
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
; This procedure is use to write the file back to disk, It is use to 
; write both the backup file and final modified copy. It will return an
; error if we have problem writing file. If file doesnot exist, it will
; create the file.
;

SaveFile proc	near
	push	ds
	mov	ax,3d02h
	int	21h
	jnc	SFOpen
	mov	ah,3ch	; create new file
	xor	cx,cx
	int	21h
	jnc	SFOpen
	jmp	SaveEnd		; error creating so we must exit
SFOpen:
	mov	bx,ax		; save handle
	mov	ax,[StartSeg]
	mov	[lastseg],ax
	mov	word ptr [lastoff],0
	mov	ax,[readlow]
	mov	[writelow],ax
	mov	ax,[readhi]
	mov	[writehi],ax
SaveLoop:
	mov	cx,0fff0h		; calculate next lenght to write
	cmp	cs:[writehi],0		; depending on size of file readed
	ja	SaveHi			; into memory
	mov	cx,cs:[writelow]	; this will do it in 64k chunks
SaveHi:	
	jcxz	SaveDone		; this will be zero if we are done
	mov	ds,cs:[lastseg]
	mov	dx,cs:[lastoff]
	mov	ah,40h
	int	21h			; write next image to disk
	jc	writend
	push	ax
	mov	dx,ax
	and	dx,000fh	; get remain non-paragraph offset
	mov	cs:[lastoff],dx
	mov	cl,4
	shr	ax,cl
	add	word ptr cs:[lastseg],ax
	pop	ax
	sub	cs:[writelow],ax
	jnc	SaveLoop
	dec	cs:[writehi]
	jmp	short SaveLoop		; continue with next write
SaveDone:
	cmp	[SetDate],'Y'		; are we time stampping
	jne	skipstamp
	mov	ax,5701h
	mov	cx,[FileTime]
	mov	dx,[FileDate]
	int	21h    			; write file time stamp
	jc	writend
skipstamp:
	clc				; indicate every thing is ok
writend:
	pushf				; save flags 
	mov	ah,3eh			; close the file
	int	21h
	popf	   			; restore flags
SaveEnd:
	pop	ds
	ret
SaveFile endp

;
; The following is conditionally assemble debugging logic to display
; the Hidden and visual serial #'s
;

if	DEBUG
dumpinfo proc	near
	 mov	dx,offset serialmsg
	 call	dispit
	 mov	si,[serialoff]		; display visual serial #
	 mov	cx,10
	 call	dumpit
	 mov	dx,offset crlf
	 call	dispit
	 mov	dx,offset crlf
	 call	dispit
	 ret
dumpit:
	 lodsb				; routine use to display serial #'s
	 mov	dl,al
	 mov	ah,2
	 int	21h
	 loop	dumpit
	 ret
dispit:
	push	ds			; routine use to display text message
	mov	ax,cs			; store in cs while dumping serial
	mov	ds,ax			; messages	
	mov	ah,9
	int	21h
	pop	ds
	ret
dumpinfo endp
endif

;
; The following routine is use to patch the serial #'s into $$MOS.SYS on
; there disk.
;

ModifyMOS proc	near
	push	ds
	mov	ax,[StartSeg]
	add	ax,1800h		; we want to access init code
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

	push	ds
	push	es
	push	cs
	pop	es
	push	cs
	pop	ds
	mov	si,offset userser
	mov	di,offset serial
	cld
	movsw
	mov	al,'-'
	stosb
	mov	cx,4
	rep	movsw
	pop	es
	pop	ds

if	DEBUG
	call	dumpinfo
endif

;
; At this point we know the locations, so we must copy serial #'s from
; command line to code in memory
;

	push	es
	mov	ax,ds
	mov	es,ax
	mov	ax,cs
	mov	ds,ax
	mov	si,offset userser
	mov	di,[serialoff]
	mov	cx,5
	rep	movsw
	pop	es
	pop	ds
	clc
	ret
ModifyErr:
	mov	dx,offset bmoserr
	stc
	ret
ModifyMOS endp

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
	mov	dx,offset msg
	mov	ah,9
	int	21h
;
;	Get Current Drive
;
	mov	ah,19h
	int	21h		     	; get current drive
	mov	[curdrive],al		; save current drive
	add	al,'A'
	mov	byte ptr [outfile],al
;
;	Get Parameters from command line	
;	
	call	GetParms		; get parameters from command line
	jnc	goodparms
	jmp	badparms
goodparms:
	mov	ax,cs
	mov	bx,offset endofmos+30fh	; reserving space for stack and code
	mov	cl,4
	shr	bx,cl			; convert to paragraphs
	add	ax,bx
	mov	[StartSeg],ax		; save start segment

	mov	dx,offset mosfile
	call	LoadFile		; load image of $$MOS.SYS into memory	
	jnc	loadok
	jmp	badparms
loadok:
	mov	dx,offset mosback
	mov	[SetDate],'Y'		; we want to set date to original date
	call	SaveFile  		; save back up $$MOS.SYS
	jnc	madeback
	mov	dx,offset backerr	; indicate backup error
	jmp	short badparms
madeback:
	call	ModifyMOS		; modified image of MOS
	jc	badparms		; will error out if wrong version
	mov	dx,offset outfile
	mov	[SetDate],'N'		; we don't want to set date to original date
	call	SaveFile		; save new copy of $$MOS.SYS
	jnc	madesave
	mov	dx,offset writerr	; error making final version
	jmp	short badparms
madesave:
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

	mov	ax,4c00h
	int	21h
badparms:
	mov	ah,9
	int	21h
	mov	ax,4c01h
	int	21h

endofmos label	byte


cseg	ends
	end	start

