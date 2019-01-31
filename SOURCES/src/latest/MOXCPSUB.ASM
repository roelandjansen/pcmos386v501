
;========= left off comment conversion at finddelim 



	title	moxcpsub  -   mos command processor subroutines
	include page.inc

comment ^===============================================================

sah 07/07/87	correct problem with piping i.e  cd |

sah 07/11/87	change function 80+ int21 to int 38 00+

mjs 08/16/87	modify resetin and resetout to use origin/out

sah 10/20/87	imported dectobin from mos.asm for switch

sah 05/12/88	added sim38 procedure which simulates a int 38
		call	ro avoid conflicts with ms-c compiled
		programs.   dataflex was causing this problem

sah 11/10/88	correct another flags problem with xor reg,reg
		which was causing problem with creating bad
		file when trying to copy to non-existend dir.

mjs 12/02/88	added new procedures getenvsize and adjustenv as part
		of an overhaul of environment handling.  cleaned up.

rdg 12/27/88	optimized short jumps and lj macros to eliminate
		unneccessary nop's and jumps.

rdg 12/27/88	modified rbl12 to read a 128 byte portion of the batch
		file into workbuf instead of only 32 bytes.
		added label rbl81 to handle the last batch file line
		that may not be terminated with a carriage return.
		modified rbl9 to act as if a carriage return had been
		found at the end of a line when the number of chars
		processed equaled the number read, but was not the
		size of the read done in rbl12.

sah 03/24/89	correct problem with mos map displaying garbage on  fg's
		task because string was terminated by zero in
		initprogname.

mjs 05/24/89	correct chainclr to not reset re-direction unless the
		chain flag is set.  the for command calls chainclr to
		reset chaining but must not reset re-direction.

mjs 06/21/89	added code to manage the $compat$ environment variable.

sah 07/06/89	added code to change vector for int 23 to point to code
		in	data segment so that we can be compatible with tsr
		management utilities like load and unload

sah 11/01/89	added code to display serial # when rel command is
		executed.

bwr 11/29/89	marked messages for foreign language translation.

sah 12/20/89	corrections to my 11/01/89 additions so that new
		$$shell.sys can be release for mos 4.00 code.

bwr 4/5/90	problem with the "cd" command allowing invalid
		directory names entered has been corrected.  new
		routine "qualify_filename" has been added to deal
		with the problem.

mjs 07/23/90	modified batclr to reset batend to 0.

BWR 11/30/90	In certain batch files, a sequence of commands involving
		directory names caused an "invalid directory" error.
		This was happening because the routine "qualify_filename"
		was not adequately checking for the end-of-string (ASCIIZ)
		terminator when scanning for the file extension dot. In
		said cases where the file target in the previous command
		had a longer filename, a stray dot would be left over
		in the parameter buffer.  Since "qualify_filename" was
		not stopping his scan at the \0, he was going past it
		and finding the leftover dot from the previous command.
		Of course, there were cases in which the found dot was
		more than 8 character spaces away from the beginning of
		the file name.	This was causing "qualify_filename" to
		indicate an illegal filename.
	       
BWR 3/22/91	Code cleanup in connection with bug fixes, code overhaul
		and removal of XIF macros.

mjs 07/02/91	had cleaned up formpath in order to analyze a problem
		within moxcpcor.  no net logic change, just a cleanup.

================ 5.01 kernel ends here ====================================

mjs 08/12/92	corrected bug in signon where the wrong segment override 
		was used to reset tcb%rs0a and tcb%rs3f.
		set version 5.04 in moxcpcor.
		patched into release 5.01 by updat501.sys version 1.08.

mjs 09/17/92	modified getsetclass to supply targdrv to id4f31

======================================================================^

include moxcpdat.inc			; data declarations

cmd	group	codeseg

	.xlist
	include mosscbex.inc
	.list

tcb segment at 0

.xlist
include mostcb.inc
.list

tcb	ends

codeseg segment

	include moxcpsub.pub		; to public all routines

	assume cs:cmd

extrn emsgtbl:byte, isonstr:byte, isoffstr:byte, dayofwk:byte, versmsg:byte
extrn delimset:byte, pausmsg:byte, volmsg1:byte, volmsg2:byte, volmsg3:byte
extrn pthstr:byte, prmstr:byte, contbrk:near, cb3:near
extrn criterr:near, ecl1:near, ecl2:near, ecl3:near, comspc:byte,
extrn smlcms:byte, cpatstr:byte, signint23:near

substart:

;======================================================================
;,fs
; basicdisp 
;
; display asciiz string
;
; in:	ds:dx -> string
;	bx = handle
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
basicdisp proc near
	push	si
	push	cx
	push	ax
	push	bp
	mov	si,dx
	call	findlen
	mov	bp,cx
	mos	writfil
	ljc	ecl3			; access denied
	cmp	ax,bp
	ljne	ecl1			; disk full
	pop	bp
	pop	ax
	pop	cx
	pop	si
	ret
basicdisp endp

;======================================================================
;,fs
; dispstr 
;
; display asciiz string
;
; in:	ds:dx -> string
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dispstr proc near
	push	bx
	mov	bx,stdout
	call	basicdisp
	pop	bx
	ret
dispstr endp

;======================================================================
;,fs
; disperr 
;
; display a string to stderr
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
disperr proc near
	push	bx
	mov	bx,stderr
	call	basicdisp
	pop	bx
	ret
disperr endp

;======================================================================
;,fs
; csdispstr 
;
; display asciiz string
; use this proc for string constants in the code segment.
;
; in:	cs:dx -> string
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
csdispstr proc near
	push	ds
	push	cs
	pop	ds
	call	dispstr
	pop	ds
	ret
csdispstr endp

;======================================================================
;,fs
; csdispmsg 
;
; display $ terminated message at cs:dx to standart output
;
; in:	cs:dx -> string
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
csdispmsg proc near
	push	es
	push	di
	push	cx
	push	ax
	mov	ax,cs			; get message segment
	mov	es,ax
	xor	ax,ax			; find length of message
	mov	cx,-1
	mov	di,dx
	repne	scasb
	not	cx
	dec	cx
	mov	al,'$'			; terminate message at $
	mov	di,dx
	repne	scasb
	jne	csdmterm
	mov	byte ptr es:[di-1],0
csdmterm:
	pop	ax
	pop	cx
	pop	di
	pop	es
	jmp	short csdispstr
csdispmsg endp

;======================================================================
;,fs
; csdisperr 
;
; display asciiz string, address in cs:dx
;
; in:	cs:dx -> string
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
csdisperr proc near
	push	ds
	push	cs
	pop	ds
	call	disperr
	pop	ds
	ret
csdisperr endp

;======================================================================
;,fs
; dispeol 
;
; send a crlf pair to the display
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing

eolmsg	db cr,lf,0

dispeol proc near
	push	dx
	lea	dx,[eolmsg]
	call	csdispstr
	pop	dx
	ret
dispeol endp

;======================================================================
;,fs
; dispchar 
;
; in:	dl = char to display
;	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
dispchar proc near
	push	ax
	push	bx
	push	cx
	push	dx
	mov	[dchar],dl
	lea	dx,[dchar]
	mov	bx,stdout
	mov	cx,1
	mos	writfil
	ljc	ecl3			; access denied
	cmp	ax,1
	ljne	ecl1			; disk full
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
dispchar endp

;======================================================================
;,fs
; reporterror 
;
; supply error code in al, 1-88 mos errors, 200+ internal codes
;
; in:	al = errorcode
;	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
reporterror proc near
	push	si
	push	ax
	true?	[nointerr]		; if $compat$=/i is found, leave errlvl alone
	je	re0
	true?	[dointerr]		; only set errlvl if the command is marked
	jne	re0			; for it in the command table
	mov	byte ptr [errlvl],1
re0:
	push	ds
	push	cs
	pop	ds
	mov	ah,al
	cmp	al,0
	je	re1
	lea	si,emsgtbl
	cld
re2:
	lodsb
	cmp	al,0
	je	re1
	cmp	al,ah
	je	re3
	inc	si
	inc	si
	jmp	re2
re3:
	mov	dx,[si]
	call	csdisperr
	lea	dx,[reeol]
	call	csdisperr
re1:
	pop	ds
	pop	ax
	pop	si
	ret
reporterror endp

reeol	db	cr,lf,0

;======================================================================
;,fs
; reportstat 
;
; will display the string followed by 'is off' or 'is on'
;
; in:	al = flag to report on
;	cs:dx -> string
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
reportstat proc near
	push	dx
	call	csdispstr
	or	al,al
	jz	rs1
	lea	dx,cmd:[isonstr]
	jmp	short rs2
rs1:
	lea	dx,cmd:[isoffstr]
rs2:
	call	csdispstr
	call	dispeol
	pop	dx
	ret
reportstat endp

;======================================================================
;,fs
; moddate 
;
; modifies the date display format depending on the country.
; the date is expected in usa format in workbuf. 
; note use of attmpt1
;
; in:	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
moddate proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	mov	al,byte ptr [attmpt1+11]; date separator code
	push	ax
	mov	ax,word ptr [attmpt1]	; get date format code
	or	ax,ax
	jz	mda2			; if ax=0, usa format m d y
	cmp	ax,1			; europe format d m y
	je	mda4
	mov	bl,byte ptr [attmpt2]	; assume japan format y m d
	mov	bh,byte ptr [attmpt2+1]
	mov	dl,byte ptr [attmpt2+3]
	mov	dh,byte ptr [attmpt2+4]
	lea	si,[attmpt2+6]
	lea	di,[attmpt2]
	mov	cx,4
	call	copystr 		; shift year down
	mov	byte ptr [attmpt2+5],bl
	mov	byte ptr [attmpt2+6],bh
	mov	byte ptr [attmpt2+8],dl
	mov	byte ptr [attmpt2+9],dh
	mov	bh,byte ptr [attmpt2+1]
	mov	bh,byte ptr [attmpt2+1]
	pop	ax			; get date separator char in al
	mov	byte ptr [attmpt2+4],al
	mov	byte ptr [attmpt2+7],al
	jmp	short mda3
mda4:
	mov	bl,byte ptr [attmpt2]	; europe format d m y
	mov	bh,byte ptr [attmpt2+1]
	mov	cl,byte ptr [attmpt2+3]
	mov	ch,byte ptr [attmpt2+4]
	mov	byte ptr [attmpt2+3],bl
	mov	byte ptr [attmpt2+4],bh
	mov	byte ptr [attmpt2],cl
	mov	byte ptr [attmpt2+1],ch
mda2:
	pop	ax			; get date separator char in al
	mov	byte ptr [attmpt2+2],al
	mov	byte ptr [attmpt2+5],al
mda3:
	lea	dx,[attmpt2]
	cmp	byte ptr [attmpt2],'0'
	jne	mda1
	mov	byte ptr [attmpt2],' '
mda1:
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
moddate endp

;======================================================================
;,fs
; convertdate 
;
; converts the date to a string in attmpt2
;
; in:	cx = year
;	dh = month
;	dl = day
;	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
convertdate proc near
	push	ax
	push	bx
	push	cx
	push	dx
	mov	al,dh
	xor	ah,ah
	xor	dx,dx			; get month in dx:ax and convert
	lea	bx,[attmpt2+1]
	mov	cx,2
	call	bin2dec
	pop	ax
	xor	ah,ah			; get day into dx:ax and convert
	xor	dx,dx
	lea	bx,[attmpt2+4]
	mov	cx,2
	call	bin2dec
	pop	ax			; pop cx into ax to get year into dx:ax
	xor	dx,dx
	mov	cx,4
	lea	bx,[attmpt2+9]
	call	bin2dec
	mov	byte ptr [attmpt2+10],0
	cmp	byte ptr [attmpt2],' '
	jne	cvd1
	mov	byte ptr [attmpt2],'0'
cvd1:
	cmp	byte ptr [attmpt2+3],' '
	jne	cvd2
	mov	byte ptr [attmpt2+3],'0'
cvd2:
	call	moddate
	pop	bx
	pop	ax
	ret
convertdate endp

;======================================================================
;,fs
; dispdate 
;
; read the current date and day of week and display
;
; in:	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
dispdate proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	mos	getdate
	push	cx
	push	dx
	lea	si,cmd:[dayofwk]
	mov	ah,al
	shl	al,1
	add	al,ah			; multiply day of week by 3 to use as index
	xor	ah,ah
	add	si,ax
	mov	cx,3
dd1:
	mov	dl,cmd:[si]		; display day of week
	inc	si
	call	dispchar
	loop	dd1
	mov	dl,' '
	call	dispchar
	push	ax
	lea	dx,[attmpt1]		; attmpt1 used as a scratch buffer
	xor	al,al			; for country data (32 byte table)
	mos	getcoun
	pop	ax
	pop	dx
	pop	cx
	call	convertdate
	lea	dx,[attmpt2]
	call	dispstr 		; display the string
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
dispdate endp

;======================================================================
;,fs
; disptime 
;
; read the current time and display
;
; in:	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
disptime proc near
	push	ax
	push	bx
	push	cx
	push	dx
	lea	dx,[attmpt1]		; attmpt1 used as a scratch buffer
	xor	al,al			; for country data (32 byte table)
	mos	getcoun
	mov	al,byte ptr [attmpt1+13]; time separator code
	mov	[workbuf+2],al
	mov	[workbuf+5],al
	mov	al,byte ptr [attmpt1+9] ; decimal separator
	mov	[workbuf+8],al
	mos	gettime
	push	dx
	push	cx
	mov	al,ch
	xor	ah,ah
	xor	dx,dx			; get hours in dx:ax and convert
	mov	cx,2
	lea	bx,[workbuf+1]
	call	bin2dec
	pop	ax			; pop cx into ax to get minutes in dx:ax
	xor	ah,ah
	xor	dx,dx
	mov	cx,2
	lea	bx,[workbuf+4]
	call	bin2dec
	cmp	byte ptr [workbuf+3],' '
	jne	dtm1
	mov	byte ptr [workbuf+3],'0'
dtm1:
	pop	ax			; pop dx into ax
	push	ax
	mov	al,ah			; get seconds in dx:ax and convert
	xor	ah,ah
	xor	dx,dx
	mov	cx,2
	lea	bx,[workbuf+7]
	call	bin2dec
	cmp	byte ptr [workbuf+6],' '
	jne	dtm2
	mov	byte ptr [workbuf+6],'0'
dtm2:
	pop	ax
	xor	ah,ah			; get hundreths in dx:ax and convert
	xor	dx,dx
	mov	cx,2
	lea	bx,[workbuf+10]
	call	bin2dec
	cmp	byte ptr [workbuf+9],' '
	jne	dtm3
	mov	byte ptr [workbuf+9],'0'
dtm3:
	mov	byte ptr [workbuf+11],0
	lea	dx,[workbuf]
	call	dispstr 		; display the string
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
disptime endp

;======================================================================
;,fs
; dispblanks 
;
; send blanks to the stdout device.
;
; in:	cx = # of blanks
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dispblanks proc near
	push	ax
	push	dx
	mov	dl,' '
db1:
	call	dispchar
	loop	db1
	pop	dx
	pop	ax
	ret
dispblanks endp

;======================================================================
;,fs
; dispdir 
;
; read the current drive/dir for the default drive and display
;
; in:	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
dispdir proc near
	push	si
	push	dx
	push	ax
	call	dispdrv
	mov	dl,':'
	call	dispchar
	mov	dl,'\'
	call	dispchar
	lea	dx,[dirbuf]
	call	dispstr
	pop	ax
	pop	dx
	pop	si
	ret
dispdir endp

;======================================================================
;,fs
; dispver 
;
; read the version number and display
;
; in:	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
dispver proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	mov	ah,getver
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax			; to get mos version number, ax=bx=cx=dx
	mos	getver
	push	bx
	push	ax
	xor	ah,ah
	xor	dx,dx
	lea	bx,[workbuf+1]
	mov	cx,2
	call	bin2dec
	mov	[workbuf+2],'.'
	pop	ax
	mov	al,ah
	xor	ah,ah
	xor	dx,dx
	mov	cx,2
	lea	bx,[workbuf+4]
	call	bin2dec
	cmp	[workbuf+3],' '
	jne	dv1
	mov	[workbuf+3],'0'
dv1:
	lea	di,[workbuf+5]
	cld
	pop	ax			; pop bx into ax (mos type code)
	or	al,al
	jz	dv2
	stosb
dv2:
	or	ah,ah
	jz	dv3
	mov	al,ah
	stosb
dv3:
	xor	al,al
	stosb
	lea	dx,cmd:[versmsg]
	call	csdispstr
	lea	dx,[workbuf]
	call	dispstr

; the following code was added to displayed the serial #
; this code use function 24h and is only supported on
; release of mos after	4.00

	push	ds
	mov	ah,24h
	call	sim38
	jc	serskip
	push	dx
	mov	dl,' '
	mov	ah,2
	int	21h
	mov	dl,'('
	mov	ah,2
	int	21h
	pop	dx
	mov	ah,9
	int	21h
	mov	dl,')'
	mov	ah,2
	int	21h
serskip:
	pop	ds
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
dispver endp

;======================================================================
;,fs
; dispdrv 
;
; read the current drive and display
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
dispdrv proc near
	push	ax
	push	dx
	mos	getdrv
	add	al,65
	mov	dl,al
	call	dispchar
	pop	dx
	pop	ax
	ret
dispdrv endp

;======================================================================
;,fs
; dispid 
;
; convert and display the current task id
;
; in:	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
dispid proc near
	push	ax
	push	bx
	push	dx
	xor	dx,dx
	mov	ax,[tcbidnum]
	or	ax,ax
	jz	did1
	mov	bx,10			; convert the id number into the filename
	div	bx
did1:
	add	dl,'0'
	add	al,'0'
	push	dx
	mov	dl,al
	call	dispchar
	pop	dx
	call	dispchar
	pop	dx
	pop	bx
	pop	ax
	ret
dispid endp

;======================================================================
;,fs
; dispuser 
;
; display the current user name
;
; in:	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
dispuser proc near
	push	ax
	push	cx
	push	dx
	push	si
	push	ds
	mov	ds,[tcbseg]
	assume	ds:tcb
	lea	si,[tcbuser]
	cld
	mov	cx,4
dus2:
	lodsb
	or	al,al
	jz	dus1
	mov	dl,al
	mov	ah,2
	int	21h
dus1:
	dec	cx
	jnz	dus2
	pop	ds
	assume	ds:nothing
	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret
dispuser endp

;======================================================================
;,fs
; dispprompt 
;
; decode the prompt string and display to stdout
;
; in:	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
dispprompt proc near
	push	ax
	push	dx
	push	si
	mov	[dirbuf],0
	lea	si,[dirbuf]		; force media check here, so things don't
	xor	dl,dl			; halt in the middle of displaying the
	mos	getdir			; prompt
	lea	si,[promstr]
	cld
	lodsb
	or	al,al
	jnz	dp1
	mov	dl,'['
	call	dispchar
	call	dispdir 		; default prompt (when promstr is null)
	mov	dl,']'
	call	dispchar
	jmp	short dp2
dp1:
	or	al,al
	jz	dp2
	cmp	al,'$'
	je	dp3
	mov	dl,al
	call	dispchar
	cld
	lodsb
	jmp	dp1
dp2:
	pop	si
	pop	dx
	pop	ax
	ret
dp3:
	cld
	lodsb
	call	low2upper
	cmp	al,'$'
	je	dp4
	cmp	al,'T'
	je	dp5
	cmp	al,'D'
	je	dp6
	cmp	al,'P'
	je	dp7
	cmp	al,'V'
	je	dp8
	cmp	al,'N'
	je	dp9
	cmp	al,'G'
	je	dp10
	cmp	al,'L'
	je	dp11
	cmp	al,'B'
	je	dp12
	cmp	al,'Q'
	je	dp13
	cmp	al,'H'
	je	dp14
	cmp	al,'E'
	je	dp15
	cmp	al,'_'
	je	dp16
	cmp	al,'I'
	je	dp19
	cmp	al,'U'
	je	dp20
	jmp	short dp17
dp18:
	call	dispchar
dp17:
	cld
	lodsb
	jmp	dp1
dp4:					; '$'
	mov	dl,'$'
	jmp	dp18
dp5:					; time
	call	disptime
	jmp	dp17
dp6:					; date
	call	dispdate
	jmp	dp17
dp7:					; current directory of def drive
	call	dispdir
	jmp	dp17
dp8:					; version number
	call	dispver
	jmp	dp17
dp9:					; default drive
	call	dispdrv
	jmp	dp17
dp10:					; '>'
	mov	dl,'>'
	jmp	dp18
dp11:					; '<'
	mov	dl,'<'
	jmp	dp18
dp12:					; '|'
	mov	dl,'|'
	jmp	dp18
dp13:					; '='
	mov	dl,'='
	jmp	dp18
dp19:
	call	dispid
	jmp	dp17
dp20:
	call	dispuser
	jmp	dp17
dp14:					; destructive backspace
	mov	dl,bs
	call	dispchar
	mov	dl,' '
	call	dispchar
	mov	dl,bs
	call	dispchar
	jmp	dp17
dp15:					; escape code
	mov	dl,escape
	call	dispchar
	jmp	dp17
dp16:					; crlf codes
	call	dispeol
	jmp	dp17
dispprompt endp

;======================================================================
;,fs
; copystr 
;
; in:	ds:si -> source string
;	es:di -> dest buffer
;	cx = bytes to xfer
;	 if cx = 0, xfer until xfer a 0
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
copystr proc near
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
copystr endp

;======================================================================
;,fs
; findend 
;
; in:	ds:si -> string to search
;
; out:	ds:si -> ending 0
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
findend proc near
	push	ax
fe1:
	cld
	lodsb
	or	al,al
	jnz	fe1
	dec	si
	pop	ax
	ret
findend endp

;======================================================================
;,fs
; findlen 
;
; in:	ds:si -> string to measure
;
; out:	cx = length (not including the ending 0)
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
findlen proc near
	push	dx
	push	si
	mov	dx,si
	call	findend
	sub	si,dx
	mov	cx,si
	pop	si
	pop	dx
	ret
findlen endp

;======================================================================
;,fs
; copycmdname 
;
; copy a command name from extrbuf to cmdname
;
; in:	ds -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
copycmdname proc near
	push	si
	push	di
	push	ax
	true?	[specdrv]
	je	cc1
	lea	si,[extrbuf]
cc2:
	lea	di,[cmdname]
	mov	byte ptr [cmdcnt],0
cc3:
	cld
	lodsb
	call	writecmd
	or	al,al
	jnz	cc3
	pop	ax
	pop	di
	pop	si
	ret
cc1:
	lea	si,[extrbuf+2]
	jmp	cc2
copycmdname endp

;======================================================================
;,fs
; writecmd 
;
; if count is ok, write al at es:di, else ignore.  use to write the
; supplied charactor in the buffer cmdname
;
; in:	al = character to write
;	es:di -> write point in command buffer
;	ds -> dataseg
;	[cmdcnt] = length of string currently in command buffer
;
; out:	[cmdcnt] updated
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
writecmd proc near
	push	ax
	push	bx
	mov	bl,cmdmax
	mov	ah,[cmdcnt]
	cmp	bl,ah
	jb	wc1
	cmp	al,'.'
	je	wc2
	cld
	stosb
	inc	ah
	mov	[cmdcnt],ah
	cmp	ah,bl
	je	wc2
wc1:
	pop	bx
	pop	ax
	ret
wc2:
	xor	al,al
	cld
	stosb
	inc	bl
	mov	[cmdcnt],bl
	jmp	wc1
writecmd endp

;======================================================================
;,fs
; formpath
;
; in:	[usedr1] = ?????
;	[usedr2] = ?????
;	[extpath] = ?????
;	[cmdname] = ?????
;	ds -> dataseg
;
; out:	cy if write to attmpt1 spills over into attmpt2
;	 [attmpt1] contains ????????
;	 [attmpt2] contains ???????
;	nc if ok
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
formpath proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	lea	di,[attmpt1]
	mov	al,[usedr1]
	cld
	stosb
	mov	al,':'
	stosb
	cmp	byte ptr [extpath],bslash
	je	fp1
	mov	dl,[usedr1]
	lea	bx,[attmpt1]
	call	fp4
	lea	dx,[attmpt1]		; di now points to byte after the 0
	mov	ax,di			; must check for spill over into attmpt2
	sub	ax,dx
	cmp	ax,80
	ja	fp5
	mov	byte ptr [attmpt2],0
	mov	al,[usedr2]
	or	al,al
	jz	fp3
	lea	di,[attmpt2]
	cld
	stosb
	mov	al,':'
	stosb
	lea	bx,[attmpt2]
	mov	dl,[usedr2]
	call	fp4
	jmp	short fp3
fp1:
	call	fp2
	lea	si,[attmpt1]
	lea	di,[attmpt2]
	xor	cx,cx
	call	copystr
	mov	al,[usedr2]
	mov	byte ptr [attmpt2],al
fp3:
	clc
	jmp	short fp6
fp5:
	stc
fp6:
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
formpath endp

;======================================================================
;,fs
; fp2
;
; in:	di -> ????????
;	[extpath] = ?????
;	[cmdname] = ?????
;	ds -> dataseg
;	es -> dataseg
;
; out:
;
;,fe
;======================================================================
	assume	ds:dataseg,es:dataseg,ss:nothing
fp2 proc near
	lea	si,[extpath]
	xor	cx,cx
	call	copystr
	call	addslash
	lea	si,[cmdname]
	xor	cx,cx
	call	copystr
	dec	di
	mov	al,'.'
	mov	cx,4
	cld
	rep	stosb
	xor	al,al
	stosb
	ret
fp2 endp

;======================================================================
;,fs
; addslash
;
; in:	di -> write point within buffer
;	ds -> dataseg
;	es -> dataseg
;
; out:	di -> next write point within buffer (after slash)
;
;,fe
;======================================================================
	assume	ds:dataseg,es:dataseg,ss:nothing
addslash proc near
	mov	al,bslash
	cmp	al,[di-2]
	je	as1
	mov	[di-1],al
	inc	di
as1:
	dec	di
	ret
addslash endp

;======================================================================
;,fs
; fp4
;
; in:	di -> write point in buffer 
;	bx -> start of buffer
;	dl = drive letter
;	ds -> dataseg
;	es -> dataseg
;
; out:	di -> next write point within buffer
;
;,fe
;======================================================================
	assume	ds:dataseg,es:dataseg,ss:nothing
fp4 proc near
	mov	al,bslash
	cld
	stosb
	mov	si,di
	sub	dl,64
	mov	byte ptr [si],0
	mos	getdir
	mov	si,bx
	call	findend
	mov	di,si
	inc	di
	call	addslash
	call	fp2
	ret
fp4 endp

;======================================================================
;,fs
; low2upper 
;
; convert charactor in reg al to upper case
;
; in:	al = character to convert
;
; out:	al = converted character
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
low2upper proc near
	cmp	al,'a'
	jae	lu1
	ret
lu1:
	cmp	al,'z'
	jbe	lu2
	ret
lu2:
	sub	al,32
	ret
low2upper endp

;======================================================================
;,fs
; bytes2para 
;
; convert the number of bytes in ax to paragraphs in ax
;
; in:	ax = # of bytes
;
; out:	ax = # of paras
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
bytes2para proc near
	push	cx
	add	ax,15			; round up to next whole paragraph
	mov	cl,4
	shr	ax,cl			; divide by 16
	pop	cx
	ret
bytes2para endp

;======================================================================
;,fs
; hibin2dec
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
hibin2dec proc near
	push	bp
	xor	bp,bp
hiloop:
	cmp	dx,3b9ah
	jb	hiok
	ja	hiabove
	cmp	ax,0ca00h
	jb	hiok
hiabove:
	inc	bp
	sub	ax,0ca00h
	sbb	dx,3b9ah
	jmp	short hiloop
hiok:
	push	ax
	mov	al,' '
	or	bp,bp
	jz	hiok2
	mov	al,'0'
	xor	ah,ah
	add	ax,bp
hiok2:
	push	dx
	mov	dl,al
	mov	ah,2
	int	21h
	cmp	dl,' '
	je	hiok3
	mov	dl,','
hiok3:
	mov	ah,2
	int	21h
	pop	dx
	pop	ax
	pop	bp
	call	bin2dec
	ret
hibin2dec endp

;======================================================================
;,fs
; bin2dec 
;
; supply the source value in dx:ax with dx the most signif
; word.  ds:bx should point to the end of the buffer area you
; want filled with the ascii string and cx should hold the number
; of digits you want to allow for.
; max value for cx=9	max dx:ax=999,999,999
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
bn2b:
	cmp	dx,cx			; double word compare dx:ax and cx:bx
	je	bn2c
	ret
bn2c:
	cmp	ax,bx
	ret

bin2dec proc near
	push	bp
	push	si
	push	di
	push	cx
	push	bx
	push	cx
	mov	bp,'9'
	mov	cx,35a4h
	mov	bx,0e900h
	call	bn2b
	ja	bn2d
	mov	bp,'8'
	mov	cx,2fafh
	mov	bx,0800h
	call	bn2b
	ja	bn2d
	mov	bp,'7'
	mov	cx,29b9h
	mov	bx,2700h
	call	bn2b
	ja	bn2d
	mov	bp,'6'
	mov	cx,23c3h
	mov	bx,4600h
	call	bn2b
	ja	bn2d
	mov	bp,'5'
	mov	cx,1dcdh
	mov	bx,6500h
	call	bn2b
	ja	bn2d
	mov	bp,'4'
	mov	cx,17d7h
	mov	bx,8400h
	call	bn2b
	ja	bn2d
	mov	bp,'3'
	mov	cx,11e1h
	mov	bx,0a300h
	call	bn2b
	ja	bn2d
	mov	bp,'2'
	mov	cx,0bebh
	mov	bx,0c200h
	call	bn2b
	ja	bn2d
	mov	bp,'1'
	mov	cx,5f5h
	mov	bx,0e100h
	call	bn2b
	ja	bn2d
	mov	bp,0			; binary zero is ignore signal
	jmp	short bn2e
bn2d:
	sub	ax,bx
	sbb	dx,cx
bn2e:
	pop	cx
	pop	bx
bn2a:
	xor	di,di
	mov	si,cx
	cmp	si,4			; is it real long?
	jle	btdloop1		; no, skip
	div	cmd:[w10000]		; yes, do it piecemeal
	mov	cx,4
	mov	di,ax
	mov	ax,dx
	xor	dx,dx
btdloop1:
	div	cmd:[w10]
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
	mov	ax,bp
	or	ax,ax
	jz	btdloop2
	mov	[bx+1],al
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
	pop	bp
	ret
bin2dec endp

; vars for bin2dec

w10000	dw	10000
w10	dw	10

 
;======================================================================
;,fs
; envsearch 
;
; supply string in workbuf, if no match, carry flag set
; if a match, carry is clear, cx points to the start of the
; entire string and bx points to the start of the right side.
;
; in:	[workbuf] contains string to search for in environment
;	ds -> dataseg
;
; out:	cy if no match
;	nc if match
;	 cx -> start of environment string
;	 bx -> start of right side of environment string
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
envsearch proc near
	push	ds
	push	si
	push	di
	push	ax
	push	bx
	push	cx
	mov	ds,[envaddr]
	xor	si,si			; setup ds:si to address the stock environment
	lea	bx,es:[workbuf]
	dec	bx
	mov	cx,bx			; save incoming bx for later recovery
	mov	di,si			; save si at start of a string
es1:
	cld
	lodsb				; compare memory to the string at bx
	inc	bx
	cmp	al,es:[bx]
	je	es1
	cmp	al,'='
	je	es2			; if stop because of an '=', found a match.
es4:
	call	findend 		; try another string
	inc	si
	cmp	byte ptr [si],0 	; end of environment?
	mov	bx,cx
	mov	di,si
	jne	es1			; if yes, set carry flag
	stc
	pop	cx
	pop	bx
es3:
	pop	ax
	pop	di
	pop	si
	pop	ds
	ret
es2:
	xor	al,al
	cmp	al,es:[bx]
	jne	es4
	mov	cx,di			; set up pointers
	mov	bx,si
	clc
	pop	ax			; compensate stack for original bx and cx
	pop	ax			; push values
	jmp	es3
envsearch endp

;======================================================================
;,fs
; findenvtail 
;
; in:	ds:si -> environment string block
;
; out:	ds:si -> next byte in environment after 0,0
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
findenvtail proc near
	push	ax
	cld
ft1:
	lodsb				; search for 1st zero
	or	al,al
	jnz	ft1
	lodsb				; check for 2nd zero
	or	al,al
	jnz	ft1
	pop	ax
	ret
findenvtail endp

;======================================================================
;,fs
; getenvsize 
;
; measure the current size of an environment block.
;
; in:	ds = segment of environment block
;
; out:	ax = # of paragraphs
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
getenvsize proc near
	push	si
	xor	si,si
	call	findenvtail		; calc current size of master environment
	mov	ax,si
	call	bytes2para
	pop	si
	ret
getenvsize endp

;======================================================================
;,fs
; adjustenv 
;
; attempt to adjust the master environment's allocation to match the
; new request.	if the new request size is less than [envsize], then
; the value of [envsize] will be used instead.
;
; in:	ax = new paragraph count for master environment
;	ds -> dataseg
;
; out:	cy if an error from the 4a call
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
adjustenv proc near
	push	ax
	push	bx
	cmp	ax,[envsize]		; use the larger of the
	jae	ade1			; current size or the last envsize spec
	mov	ax,[envsize]
ade1:
	cmp	ax,[envpara]		; skip if no net change
	je	ade2
	mov	bx,ax
	push	es
	mov	es,[envaddr]
	mos	modmem
	pop	es
	call	memcheck
	jc	ade2
	mov	[envpara],bx
	clc
ade2:
	pop	bx
	pop	ax
	ret
adjustenv endp

;======================================================================
;,fs
; writeinbuf 
;
; write al to inbuf using es:di
;
; in:	al = character to write
;	es:di -> write point in inbuf
;	ds -> dataseg
;	[incnt] = current length of string in inbuf
;
; out:	[incnt] updated
;	es:di -> next byte in buffer
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
writeinbuf proc near
	cmp	byte ptr [incnt],ebufmax
	ja	wi1
	cld
	stosb
	inc	[incnt]
	cmp	byte ptr [incnt],inmax
	jne	wi1
	inc	[incnt]
wi1:
	ret
writeinbuf endp

;======================================================================
;,fs
; writeoutbuf 
;
; write the supplied charactor in outbuf using es:di
;
; in:	al = character to write
;	es:di -> write point in outbuf
;	ds -> dataseg
;	[outcnt] = current length of string in outbuf
;
; out:	[outcnt] updated
;	es:di -> next byte in buffer
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
writeoutbuf proc near
	cmp	byte ptr [outcnt],ebufmax
	ja	wo1
	cld
	stosb
	inc	[outcnt]
	cmp	byte ptr [outcnt],outmax
	jne	wo1
	inc	[outcnt]
wo1:
	ret
writeoutbuf endp

;======================================================================
;,fs
; writeebuf 
;
; use di as the pointer to write the byte in al into extrbuf
; if the buffer has filled, set the counter > ebufmax as an
; indicator and return
;
; in:	al = character to write to extrbuf
;	es:di -> write point in extrbuf
;	es -> dataseg
;
; out:	[extrcnt] updated
;	es:di -> next byte in buffer
;
;,fe
;======================================================================
	assume	ds:nothing,es:dataseg,ss:nothing
writeebuf proc near
	cmp	byte ptr [extrcnt],ebufmax
	ja	we1
	cld
	stosb
	inc	[extrcnt]
	cmp	byte ptr [extrcnt],ebufmax
	jne	we1
	inc	[extrcnt]
we1:
	ret
writeebuf endp

;======================================================================
;,fs
; redirin
;
; establish input redirection
;
; in:	bx = handle of the device or file to be redirected
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
redirin proc near
	push	ax
	push	cx
	push	dx
	xor	al,al
	xor	cx,cx
	xor	dx,dx
	mos	lseek			; reset file pointer
	jc	ri1
	mov	cx,stdin
	mos	forcdup
ri1:
	pop	dx
	pop	cx
	pop	ax
	ret
redirin endp

;======================================================================
;,fs
; redirout
;
; establish input redirection
;
; in:	bx = handle of the device or file to be redirected
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
redirout proc near
	push	cx
	mov	cx,stdout
	mos	forcdup
	pop	cx
	ret
redirout endp

;======================================================================
;,fs
; resetin 
;
; restore normal stdin from console
;
; in:	[origin] = original psp handle table value for handle 0
;	ds -> dataseg
;	es -> psp
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
resetin proc near
	push	bx
	mov	bl,[origin]
	mov	es:[18h],bl
	clc
	pop	bx
	ret
resetin endp

;======================================================================
;,fs
; resetout 
;
; restore normal stdout to console
;
; in:	[origout] = original psp handle table value for handle 1
;	ds -> dataseg
;	es -> psp
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
resetout proc near
	push	bx
	mov	bl,[origout]
	mov	es:[19h],bl
	clc
	pop	bx
	ret
resetout endp

;======================================================================
;,fs
; resetredir 
;
; restore normal stdin and stdout
;
; in:	[origin] = original psp handle table value for handle 0
;	[origout] = original psp handle table value for handle 1
;	ds -> dataseg
;	es -> psp
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
resetredir proc near
	call	resetin
	call	resetout
	ret
resetredir endp

;======================================================================
;,fs
; resetpipe 
;
; truncate the pipe file
;
; in:	bx = handle of file to truncate
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
resetpipe proc near
	push	ax
	push	cx
	push	dx
	xor	al,al
	xor	cx,cx
	xor	dx,dx
	mos	lseek
	mos	writfil
	pop	dx
	pop	cx
	pop	ax
	ret
resetpipe endp

;======================================================================
;,fs
; updpipe 
;
; supply handle in bx,  a dup of the handle is closed to
; update the directory while keeping the orig handle open
;
; in:	bx = handle of file to update
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
updpipe proc near
	push	ax
	push	bx
	mos	duphndl
	jc	up1
	mov	bx,ax
	mos	closfil
up1:
	pop	bx
	pop	ax
	ret
updpipe endp

;======================================================================
;,fs
; updpstat 
;
; supply new value for pipestat in al
;
; in:	al = new value for pipestat
;	ds -> dataseg
;
; out:	[oldpstat] holds previous [pipestat] value
;	[pipestat] holds entry al
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
updpstat proc near
	push	ax
	mov	ah,[pipestat]
	mov	[oldpstat],ah
	mov	[pipestat],al
	pop	ax
	ret
updpstat endp

;======================================================================
;,fs
; testset 
;
; test the asciiz string at cs:si for inclusion of the byte in al
;
; in:	al = character to test for
;	cs:si -> string to test
;
; out:	zr if match
;	nz if no match
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
testset proc near
	push	ax
	push	si
	dec	si
ts2:
	inc	si
	cmp	byte ptr cmd:[si],0
	je	ts3
	cmp	al,byte ptr cmd:[si]
	je	ts1
	jmp	ts2
ts3:
	xor	al,al
	cmp	al,1
ts1:
	pop	si
	pop	ax
	ret
testset endp

;======================================================================
;,fs
; testdelims 
;
; test the delimset string for inclusion of the byte in al
;
; in:	al = character to test for
;
; out:	zr if match
;	nz if no match
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
testdelims proc near
	push	si
	lea	si,cmd:[delimset]
	call	testset
	pop	si
	ret
testdelims endp

;======================================================================
;,fs
; passdelims 
;
; check for delims at ds:si, on return ds:si points to 1st
; char that isn't a delim, and the char is in al
;
; in:	ds:si -> string to process
;
; out:	ds:si -> 1st non-delim character
;	al = the non-delim character
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
passdelims proc near
pd1:
	cld
	lodsb
	call	testdelims
	je	pd1
	dec	si
	ret
passdelims endp

;======================================================================
;,fs
; parse 
;
; ds:si is advanced as the parsing pointer.  prsfcb is data area
;
; in:	ds:si -> string to parse
;	es -> dataseg
;
; out:	ds:si -> next point in string
;	[prsfcb] contains the parsed result
;
;,fe
;======================================================================
	assume	ds:nothing,es:dataseg,ss:nothing
parse proc near
	push	cx
	push	di
	xor	ax,ax			; initialize the fcb to 0's
	lea	di,[prsfcb]
	mov	cx,12
	cld
	rep	stosb
	lea	di,[prsfcb]
	mov	al,0fh			; control byte
	mos	parsfil 		; i21f29
	or	al,al			; set flags on al
	pop	di
	pop	cx
	ret
parse endp

;======================================================================
;,fs
; parsefn 
;
; parse a string until the filename portion is found and parsed.
;
; in:	ds:si -> beginning parsing point
;	es -> dataseg
;
; out:	nc if no errory
;	 ds:si -> stop character in string
;	 al = stop character
;	 bl = 1 if a wildcard filespec was found
;	cy if error (invalid drive spec)
;
;,fe
;======================================================================
	assume	ds:nothing,es:dataseg,ss:nothing
parsefn proc near
	push	dx
	mov	bx,0			; once flag
	mov	dx,si
pf1:
	call	parse
	mov	dl,al
	cmp	bx,0
	jne	pf4
	inc	bx
	cmp	al,0ffh 		; on first parse, test for valid drive spec
	je	pf2
pf4:
	cld
	lodsb
	cmp	al,bslash
	je	pf1
	cmp	al,'.'
	je	pf1
	dec	si
	clc
	jmp	short pf3
pf2:
	stc
pf3:
	mov	bl,dl
	pop	dx
	ret
parsefn endp

;======================================================================
;,fs
; scanstr 
;
; supply pointer in ds:si, char in al.  if cx = 0, will scan
; until find a 0 (for asciiz), if cx > 0, will scan that many bytes.
; on return, z flag means ds:si points to target, nz flag for fail
;
; in:	ds:si -> string
;	al = character to scan for
;	cx = 0 if should scan until find a 0 terminator
;	cx > 0 if should use cx as scan limit count
;
; out:	zr if ds:si points to target
;	nz if no match
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
scanstr proc near
	push	ax
	push	cx
	push	di
	push	es
	push	ds
	pop	es
	cld
	mov	di,si
	jcxz	ss1			; cx = 0, scan until find a 0
	repne	scasb
	mov	si,di
ss2:
	pushf
	dec	si
	popf
	pop	es
	pop	di
	pop	cx
	pop	ax
	ret
ss1:
	mov	ah,al
ss3:
	lodsb
	cmp	al,0
	je	ss4
	cmp	al,ah
	jne	ss3
	jmp	ss2
ss4:
	xor	al,al
	cmp	al,1			; set not zero flag
	jmp	ss2
scanstr endp

;======================================================================
;,fs
; waitkey 
;
; get key without echo, check for cntrl-break
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
waitkey proc near
	push	ax
	mov	al,8
	mos	getkey
	pop	ax
	ret
waitkey endp

;======================================================================
;,fs
; pausesubr 
;
; display 'Strike any key when ready... ' and wait for a key
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
pausesubr proc near
	push	dx
	lea	dx,cmd:[pausmsg]
	call	csdispstr
	call	waitkey
	pop	dx
	ret
pausesubr endp

;======================================================================
;,fs
; oneparmchk 
;
; this proc will check that only one parameter is in parmbuf.
; /p type parameters should have already been removed
;
; in:	
;
; out:	cy if more than one parameter
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
oneparmchk proc near
	push	ax
	push	si
	lea	si,[parmbuf]		; check for invalid parameters
	call	passdelims
	cld
op1:
	lodsb
	cmp	al,0			; pass through parameter, looking for a 0
	je	op2			; or a non-delim
	call	testdelims
	jne	op1
	call	passdelims		; once find end of parameter, should only find
	cmp	al,0			; delims or 0 (should only be one parameter)
	je	op2
	stc
	jmp	short op3		;
op2:
	clc
op3:
	pop	si
	pop	ax
	ret
oneparmchk endp

;======================================================================
;,fs
; getvollbl 
;
; displays the message 'Volume in drive (dl) is ...'
;
; in:	dl = drive #
;	bx = dta address
;	ds -> dataseg
;	es -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:dataseg,ss:nothing
getvollbl proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	lea	di,[prsfcb-7]
	cld
	mov	al,0ffh 		; init the fcb
	stosb
	xor	al,al
	mov	cx,5
	rep	stosb
	mov	al,8			; set attribute for label
	stosb
	mov	al,dl			; get drive #
	stosb
	mov	al,'?'
	mov	cx,11
	rep	stosb
	xor	al,al
	mov	cx,25
	rep	stosb
	mov	cl,dl
	lea	dx,[prsfcb-7]
	mov	ah,11h			; old search for first call
	int	21h
	lea	dx,cmd:[volmsg1]	; display 'Volume in drive ' message
	call	csdispstr
	or	al,al
	jnz	gv1			; no label found
	mov	dx,bx			; display the label from the dta
	add	dx,8
	mov	bx,stdout
	mov	cx,11
	mos	writfil
	cmp	ax,11
	ljne	ecl1			; disk full
	jmp	short gv2
gv1:
	lea	dx,cmd:[volmsg3]
	call	csdispstr
gv2:
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
getvollbl endp

;======================================================================
;,fs
; initprmpth 
;
; initialize prompt and path strings from environment
;
; in:	ds -> dataseg
;	es -> dataseg
;
; out:	
;
;,fe
;======================================================================
	assume	ds:dataseg,es:dataseg,ss:nothing
initprmpth proc near
	mov	byte ptr [pathstr],0	; init path string to null
	push	ds
	push	cs
	pop	ds
	assume	ds:cmd
	lea	si,[pthstr]
	lea	di,[workbuf]
	xor	cx,cx
	call	copystr
	pop	ds
	assume	ds:dataseg
	call	envsearch		; search for a path in the environment
	jc	ipp1
	mov	si,bx
	lea	di,[pathstr]
	xor	cx,cx
	push	ds
	mov	ds,[envaddr]
	assume	ds:nothing
	call	copystr
	pop	ds
	assume	ds:dataseg
ipp1:
	mov	byte ptr [promstr],0	; init prompt string to null
	push	ds
	push	cs
	pop	ds
	assume	ds:cmd
	lea	si,[prmstr]
	lea	di,[workbuf]
	call	copystr
	pop	ds
	assume	ds:dataseg
	call	envsearch		; search for a prompt
	jc	ipp2
	mov	si,bx
	lea	di,[promstr]
	xor	cx,cx
	push	ds
	mov	ds,[envaddr]
	assume	ds:nothing
	call	copystr
	pop	ds
	assume	ds:dataseg
ipp2:
	resflg	[batnonest]
	resflg	[nointerr]
	push	ds
	push	cs
	pop	ds
	assume	ds:cmd
	lea	si,[cpatstr]
	lea	di,[workbuf]
	call	copystr
	pop	ds
	assume	ds:dataseg
	call	envsearch		; search for a prompt
	jc	ipp6
	mov	si,bx
	push	ds
	mov	ds,[envaddr]		; make ds:si point to right side
	assume	ds:nothing
ipp3:
	xor	cx,cx
	mov	al,fslash
	call	scanstr
	jne	ipp5			; no options found this pass
	inc	si
	cld
	lodsb
	call	low2upper
	cmp	al,'N'
	jne	ipp4
	setflg	[batnonest]
	jmp	ipp3
ipp4:
	cmp	al,'I'
	jne	ipp3
	setflg	[nointerr]
	jmp	ipp3
ipp5:
	pop	ds
	assume	ds:dataseg
ipp6:
	ret
initprmpth endp

;======================================================================
;,fs
; str2upper 
;
; in:	ds:si -> string to convert
;	cx = 0 if should convert string until find 0 terminator
;	cx > 0 if should use cx as byte count
;	es = ds
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
str2upper proc near
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
	jmp	st3
str2upper endp

;======================================================================
;,fs
; finddelim 
;
; ds:si points to the string, on return, ds:si will point to the 1st
; delim charactor found (or a 0) the char will be in al
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
finddelim proc near
	cld
fd1:
	lodsb
	call	testdelims
	je	fd2
	or	al,al
	jz	fd2
	jmp	fd1
fd2:
	dec	si
	ret
finddelim endp

;======================================================================
;,fs
; writedrv 
;
; ds:si points to data area and al=0 means use current drive.
; al<>0 means use al as drive #.  on return, si points to 0 on end of
; drive string of form:  'd:\',0
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
writedrv proc near
	push	ax
	push	di
	mov	di,si
	or	al,al			; if al = 0, read current drive
	jnz	wd1			; else al=1 for a, al=2 for b, etc
	mos	getdrv
	inc	al
wd1:
	add	al,64
	cld
	stosb
	mov	al,':'
	stosb
	mov	al,bslash
	stosb
	xor	al,al
	stosb
	mov	si,di
	dec	si
	pop	di
	pop	ax
	ret
writedrv endp

;======================================================================
;,fs
; writedrvpth 
;
; ds:si points to storage area, al=0 for defualt drive, else al=1 for a
; al=2 for b, etc.  the storage area is left with the full drive/path
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
writedrvpth proc near
	push	ax
	push	dx
	push	si
	call	writedrv
	mov	dl,al
	mos	getdir
	pop	si
	pop	dx
	pop	ax
	ret
writedrvpth endp

;======================================================================
;,fs
; genpthstr 
;
; ds:si points to a string, if the string is a valid path, return
; with the string put in proper format and the nc flag.  if not a
; valid path (or invalid drive), string unchanged and cy flag set.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
genpthstr proc near
	push	ax
	push	dx
	push	si
	push	bp
	mov	bp,si			; save start of string
	call	parse
	cmp	al,0ffh
	je	gp1			; invalid drive spec
	lea	si,[savedir]
	mov	al,byte ptr [prsfcb]
	call	writedrvpth		; setup savedir with full path for restoration
	mov	dx,bp
	mos	chdir			; attempt to chdir the supplied string
	jc	gp1			; if not a valid path, skip to end
	mov	si,bp			; if a valid path, reform the string
	mov	al,byte ptr [prsfcb]
	call	writedrvpth		; read current directory
	lea	dx,[savedir]
	mos	chdir			; restore previous directory
	clc
	jmp	short gp2
gp1:
	stc
gp2:
	pop	bp
	pop	si
	pop	dx
	pop	ax
	ret
genpthstr endp

;======================================================================
;,fs
; fullform 
;
; ds:si points to buffer holding a path which could also have a file
; name in it.  on return, the buffer holds the string in a full format.
; if the original string was just a subdir then '/*.*',0 will be
; appended if the original string was just a drive spec (ie 'b:') then
; reg bl will be set to 1 ('\*.*',0 will also be appended).  if cy is
; set, al=0 means invalid directory, al=1 means invalid drive.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
fullform proc near
	push	cx
	push	bp
	push	di
	call	passdelims
	push	si
	xor	bl,bl			; reset drive only flag
	cmp	byte ptr [si+1],':'
	jne	ffr17			; test for drive only by checking for a ':' in
	add	si,2			; the second column and no more chars after tha
	call	passdelims
	pop	si
	push	si
	or	al,al
	jnz	ffr17
	mov	bl,1			; mark as drive only
ffr17:
	call	findfname		; find the file name portion and save for
	mov	cx,si			; use
	call	parse
	sub	si,cx
	lea	di,[flfbuf]
	jz	ffr16
	xchg	si,cx
	call	copystr
ffr16:
	mov	byte ptr [di],0
	pop	si
	push	si
	call	parse			; check for a valid drive specification
	cmp	al,0ffh
	lje	ffr14
	mov	al,byte ptr [prsfcb]
	or	al,al
	jnz	ffr13
	mos	getdrv			; if no drive spec'ed, read the default
	inc	al
ffr13:
	mov	bp,ax			; save the drive number
	pop	si
	push	si
	call	genpthstr		; presume the string is a subdir
	jc	ffr3
	call	findend
ffr1:
	mov	di,si
ffr2:
	call	addstars
	jmp	short ffr12		; original parm was a subdir
ffr3:
	pop	si
	push	si			; when the entered parm is not a subdir
	mov	di,si			; trim it back and try to chdir again
	dec	di
	call	findend
	std
	dec	si
ffr4:
	lodsb
	cmp	al,bslash		; scan back from end, stopping for a \ or
	je	ffr7			; the beginning of the buffer
	cmp	si,di
	jne	ffr4
	mov	ax,bp			; if stop at beginning of the buffer, the parm
	pop	si			; can't be a subdir so read the current one
	push	si
	call	writedrvpth
	call	findend
	cmp	byte ptr [si-1],bslash
	je	ffr5			; put a \ on the end if not one already
	mov	byte ptr [si],bslash
	inc	si
ffr5:
	mov	di,si
ffr11:
	lea	si,[flfbuf]
	call	passdelims
	or	al,al
	ljz	ffr2
	xor	cx,cx
	call	copystr 		; copy remainder of 2nd buffer into 1st
	pop	si
	push	si
	xor	cx,cx
	call	str2upper
	jmp	short ffr12
ffr7:
	cmp	si,di			; when find a \ while scanning back
	je	ffr8			; must check for '\kdfj' or 'c:\dkjf'
	cmp	byte ptr [si],':'	; cases before trimming
	je	ffr8
	mov	byte ptr [si+1],0	; trim off at the \
	jmp	short ffr9
ffr8:
	mov	byte ptr [si+2],0	; trim off just after the \
ffr9:
	pop	si
	push	si
	call	genpthstr		; second attempt to find the subdir
	jc	ffr15
	call	findend
	mov	di,si
	cmp	byte ptr [di-1],bslash	; add a \ on the end if not one already
	je	ffr11
	mov	byte ptr [di],bslash
	inc	di
	jmp	short ffr11
ffr15:
	xor	al,al			; invalid directory error
	stc				; sah place this after xor
	jmp	short ffr12
ffr14:
	stc
	mov	ax,1			; invalid drive spec error
ffr12:
	pop	si
	pop	di
	pop	bp
	pop	cx
	ret
fullform endp

;======================================================================
;,fs
; addstars 
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
addstars proc near
	push	ax
	push	di
	cld
	cmp	byte ptr [di-1],bslash
	je	ast1
	mov	al,bslash
	stosb
ast1:
	mov	al,'*'
	stosb
	mov	al,'.'
	stosb
	mov	al,'*'
	stosb
	xor	al,al
	stosb
	pop	di
	pop	ax
	ret
addstars endp

;======================================================================
;,fs
; findfname 
;
; supply pointer in ds:si to start of full path string.  will return
; with si pointing to the start of the file name portion
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
findfname proc near
	push	ax
	push	dx
	push	di
	mov	di,si
	dec	di			; set up as limit value
	call	findend
	dec	si
	std
	xor	dl,dl			; use dl as a terminate method flag
ffn1:
	lodsb
	cmp	al,bslash		; scan back until find a \, a : or the
	je	ffn2			; start of the entire string
	cmp	al,':'
	je	ffn2
	cmp	si,di
	jne	ffn1
	mov	dl,1
ffn2:
	inc	si			; compensate si to point to the file name
	or	dl,dl
	jnz	ffn3
	inc	si
ffn3:
	pop	di
	pop	dx
	pop	ax
	ret
findfname endp

;======================================================================
;,fs
; substwild 
;
; supply ds:si pointing to the source file name, es:di pointing to
; the destination file name and ds:bx pointing to the wildcard
; pattern (11 bytes from a parsed fcb).  on return, the destination
; file name will have been created
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
substwild proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	si
	mov	cx,8			; length for file name
	cld
	mov	dl,1			; flag to control action when find a .
swd12:					; process file name.
	mov	ah,[bx] 		; read a charactor from the template
	inc	bx
	cmp	dl,1			; has the end of the source name been found?
	jne	swd13
	lodsb				; read a char from the source name (name1)
	cmp	al,'.'			; end of name?
	je	swd13
	cmp	al,0
	jne	swd14
swd13:
	xor	dl,dl			; set dl=0 when find end of source name
	mov	al,' '
swd14:
	cmp	ah,'?'			; if a ? in the template, write al into name2
	je	swd15
	cmp	ah,' '			; skip writing when find a space in the templat
	je	swd6
	mov	al,ah			; write the char from the template
swd15:
	stosb
swd6:
	loop	swd12
swd16:
	dec	di			; trim off trailing blanks and write a .
	cmp	byte ptr es:[di],' '	; on the end of name2
	je	swd16
	inc	di
	mov	al,'.'
	stosb
	dec	si
swd23:
	lodsb				; adjust si to point to the start of the ext
	cmp	al,'.'			; in name1
	je	swd24
	or	al,al
	jnz	swd23
	dec	si
swd24:
	mov	cx,3			; process the extension
	mov	dl,1
swd17:
	mov	ah,[bx]
	inc	bx
	cmp	dl,1
	jne	swd19
	lodsb
	cmp	al,0
	jne	swd18
swd19:
	xor	dl,dl
	mov	al,' '
swd18:
	cmp	ah,'?'
	je	swd20
	cmp	ah,' '
	je	swd7
	mov	al,ah
swd20:
	stosb
swd7:
	loop	swd17
swd21:
	dec	di
	cmp	byte ptr es:[di],' '
	je	swd21
	inc	di
	xor	al,al
	stosb
	cmp	byte ptr es:[di-2],'.'
	je	swd5
swd4:
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
swd5:
	pop	si
	push	si
	call	findend
	cmp	byte ptr [si-1],'.'
	je	swd4
	mov	byte ptr es:[di-2],0
	jmp	swd4
substwild endp

;======================================================================
;,fs
; getoption 
;
; ds:si points to string, supply char (uppercase) in al, ah=0 means
; find option, ah=1 means find any /.  returns zr for find
; if searching for an option (ah=0) and find it, it will be blanked
; out in the buffer
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
getoption proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	mov	bl,al
	mov	dl,0
	mov	dh,1			; set up for nz flag
gop1:
	xor	cx,cx
	mov	al,fslash
	call	scanstr
	jne	gop2			; no options found this pass
	cmp	ah,1
	je	gop3			; if ah=1 (zr flag will be set) return
	inc	si
	cld
	lodsb
	call	low2upper
	cmp	al,bl			; is it the supplied char?
	jne	gop1
	mov	word ptr [si-2],2020h	; blank out the option
	xor	dx,dx			; set up for zr flag
	jmp	gop1			; to simplify later parsing
gop2:
	cmp	dl,dh			; set zr or nz depending on dl,dh
gop3:
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
getoption endp

;======================================================================
;,fs
; readbatline 
;
; supply handle in bx.  returns r/w pointer in cx:dx, truncate status
; in al, eof status in ah and line in linebuf.  if find eof before
; data, nz flag.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
readbatline proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	cld
	lea	di,[linebuf]
	mov	cl,lbufsize
	xor	ch,ch
	xor	al,al
	rep	stosb			; init linebuf to 0's so don't have to worry
					; about end of line marker
	resflg	[dsttrunc]
	resflg	[batlread]
	resflg	[midline]
	mov	bx,[bathandl]
rbl1:
	mov	al,1
	xor	cx,cx			; handle should be in bx already
	xor	dx,dx
	mos	lseek
	push	dx
	push	ax			; save dx:ax on stack (original r/w pointer)
rbl12:
	lea	dx,[workbuf]
	mov	cx,128			; read a buffer full
	mos	readfil 		; read a buffer from the file
	or	ax,ax
	jnz	rbl4
	true?	[midline]
	jne	rbl11
	setflg	[dsttrunc]
	jmp	rbl19
rbl20:
	setflg	[dsttrunc]
rbl11:
	xor	al,al
	cmp	al,1			; set nz flag to indicate eof before data
	jmp	rbl10
rbl4:
	xchg	bx,bp			; handle to bp
	lea	si,[workbuf]		; init source pointer
	xor	bl,bl			; init read counter
	mov	cx,ax
	push	cx
	push	di
	lea	di,[workbuf]
	mov	al,eof
	repne	scasb			; scan the buffer for an eof marker
	mov	ax,di
	pop	di
	pop	cx
	jne	rbl3			; jump if don't find an EOF marker
	sub	ax,offset [workbuf+1]
	jz	rbl20
	mov	cx,ax			; calc new retcount value
	push	cx
	push	di
	lea	di,[workbuf]
	mov	al,cr			; scan the buffer for a cr
	repne	scasb
	mov	ax,di
	pop	di
	pop	cx
	jne	rbl13			; if don't find a CR, leave count modified
	sub	ax,offset [workbuf]
	cmp	ax,cx			; if find a cr before the eof, mod count again
	xchg	cx,ax
	jb	rbl3
	xchg	cx,ax
rbl13:
	setflg	[batlread]
rbl3:
	true?	[midline]
	je	rbl5
	xor	bh,bh			; init char counter
	lea	di,[linebuf]		; init dest pointer
	mov	byte ptr [di],0 	; init dest buffer to null
rbl5:
	lodsb				; get a char from the source buffer
	inc	bl			; inc read counter
	cmp	bh,lbufsize		; char counter >= max val for dest buffer?
	jae	rbl7
	stosb				; write char to dest buffer
	jmp	short rbl8
rbl7:
	setflg	[dsttrunc]		; had to truncate the line, too long
rbl8:
	inc	bh			; inc char counter
	cmp	al,cr			; end of a line?
	jne	rbl9
rbl81:
	mov	byte ptr [di-1],0
	inc	bh			; to account for the lf following the cr
	pop	ax			; get original r/w pointer
	pop	dx
	mov	bl,bh
	xor	bh,bh
	add	ax,bx			; double word addition of char counter
	adc	dx,0			; and the original r/w pointer
	mov	cx,dx
	mov	dx,ax
	xchg	bp,bx			; get handle back in bx
	mov	al,0
	mos	lseek			; update the r/w pointer in batline
	mov	word ptr [batline],ax
	mov	word ptr [batline+2],dx
	true?	[batlread]
	jne	rbl14
	setflg	[bateflg]		; mark this line as the last
rbl14:
	cmp	al,al			; set zr flag
	push	ax			; pre-compensate the stack for up-coming
	push	ax			; compensation
rbl10:
	pushf
	lea	di,[linebuf+lbufsize-1]
	xor	al,al
	stosb
	popf
	pop	ax
	pop	ax			; compensate stack for orig r/w pointer
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
rbl9:
	push	bx
	xor	bh,bh
	cmp	cx,bx			; retcount = read count ?
	pop	bx
	jne	rbl5			; if no, get another charactor
	cmp	cx,128			; did we process the full buffer
	je	rbl91			; jump if line not finished
	inc	di			; add one for the cr we didn't g
	dec	bh			; adjust for code in rbl81
	jmp	rbl81			; treat like a carriage return
rbl91:
	true?	[batlread]
	je	rbl19
	setflg	[midline]
	xchg	bx,bp			; get handle in bx
	jmp	rbl12
rbl19:
	setflg	[bateflg]		; mark this line as the last
	cmp	al,al			; set zr flag
	jmp	rbl10
readbatline endp

;======================================================================
;,fs
; updbattbl 
;
; update the table of %0-%9 offsets on the string in batparms
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
updbattbl proc near
	push	ax
	push	bx
	push	cx
	push	si
	lea	si,[batparms]
	call	findend
	mov	[batprme],si		; store end of string location for later
	lea	si,[batparms]		; restoration by fixbatparms
	lea	bx,[battabl]
	mov	cx,10
x1:					; initialize the battabl with pointers
	call	passdelims		; to each parm %0 - %9
	mov	[bx],si
	add	bx,2
	call	finddelim
	or	al,al
	jz	x2
	mov	byte ptr [si],0 	; mark the end of the parm
	inc	si
x2:
	loop	x1
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
updbattbl endp

;======================================================================
;,fs
; fixbatparms 
;
; restores the batparms string to normal asciiz format
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
fixbatparms proc near
	push	cx
	push	si
	mov	cx,[batprme]		; get the location of the orignal end of
	lea	si,[batparms]		; the batparms string and restore the string
fb1:
	call	findend
	cmp	cx,si
	je	fb2
	mov	byte ptr [si],' '	; convert batparms back into a normal
	jmp	fb1			; asciiz string for storage in the blk stack
fb2:
	pop	si
	pop	cx
	ret
fixbatparms endp

;======================================================================
;,fs
; getforcmd 
;
; sets up linebuf for the next command in the set for for in do
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
getforcmd proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	xor	bx,bx			; init once flag for global processing
	lea	si,[forsbuf]
	lea	di,[linebuf]		; put command in linebuf
	xor	cx,cx
	call	copystr
gf12:					; recycle here when done with global filespec
					; processing and more members exist
	lea	si,[linebuf]
	mov	[mlstrt],si
gf1:
	mov	ah,[forpchr]		; get the char for the parameter to be
gf2:					; replaced
	mov	al,'%'
	xor	cx,cx
	call	scanstr
	ljne	gf4			; done with parameter replacement
	inc	si
	mov	al,[si]
	call	low2upper
	cmp	ah,al
	jne	gf2
	mov	bp,si			; save point where substitution is to start
	dec	bp
	inc	si
	lea	di,[workbuf]		; save remainder of linebuf in workbuf
	xor	cx,cx
	call	copystr
	mov	di,bp
	mov	si,[forsptr]		; get pointer to next set member to be used

;------------------- manage global filespec processing ----------------

	or	bx,bx
	jz	gf2a			; skip if already looked up the file
	lea	si,[attmpt1]
	jmp	gf2b
gf2a:
	push	di
	push	bp
	true?	[forfspec]
	je	gf13
	mov	[forpptr],si		; record start of string as start of path
	call	findfname
	mov	cx,si
	sub	cx,[forpptr]		; calc length of path portion of string
	mov	[forplen],cl
	push	si
	call	parse
	pop	si
	cmp	al,1			; find a global file spec?
	jne	gf15
	lea	dx,[fordta]
	mos	setdta
	mov	dx,si
	xor	cx,cx
	mos	fndfrst
	jmp	short gf16
gf15:
	mov	si,[forpptr]		; restore si to original
	jmp	short gf18
gf13:
	lea	dx,[fordta]
	mos	setdta
	mos	fndnext
gf16:
	jc	gf14
	mov	bx,1			; set once flag
	setflg	[forfspec]
	lea	di,[attmpt1]		; build file name string in here
	cmp	[forplen],0		; is there a path string?
	je	gf19
	mov	si,[forpptr]
	mov	cl,[forplen]
	xor	ch,ch
	call	copystr 		; copy in the path portion
gf19:
	lea	si,[fordta+30]
	xor	cx,cx
	call	copystr 		; copy in the file name
	lea	si,[attmpt1]		; leave si pointing to the string
	jmp	short gf18
gf14:
	resflg	[forfspec]
	pop	bp
	pop	di
	dec	[forscnt]
	jz	gf17
	mov	si,[forsptr]		; update set member pointer
	call	findend
	inc	si
	call	passdelims
	mov	[forsptr],si
	jmp	gf12

gf17:
	setflg	[forstop]		; no more files or members, signal eec
					; sequence to ignore linebuf
	jmp	gf11
gf18:
	pop	bp			; if a global filespec is processed ok, si now
	pop	di			; points to the string (in attmpt1), else si
gf2b:					; is restored to its previous value

;------------------- end of global filespec processing ----------------

	mov	dx,di
	sub	dx,offset [linebuf]	; calc present size of linebuf string
	call	findlen 		; calc length of set string
	inc	cx			; account for the ending 0
	add	cx,dx
	cmp	cx,lbufsize		; too long?
	ja	gf9
	xor	cx,cx
	jmp	short gf3
gf9:
	mov	cx,lbufsize-1
	sub	cx,dx			; calc room left in linebuf (partial copy)
gf3:
	call	copystr
	jcxz	gf5			; skip next sequence if didn't truncate
	lea	si,[linebuf]
	add	si,(lbufsize-1)
	mov	byte ptr [si],0 	; insure an end of string marker is there
	jmp	short gf4
gf5:
	dec	di
	mov	bp,di			; save next search point
	mov	dx,di
	sub	dx,offset [linebuf]	; calc present size of linebuf string
	lea	si,[workbuf]
	call	findlen 		; calc length of workbuf
	inc	cx
	add	cx,dx
	cmp	cx,lbufsize
	ja	gf6			; too long?
	xor	cx,cx
	jmp	short gf7
gf6:
	mov	cx,(lbufsize-1)
	sub	cx,dx
gf7:
	call	copystr
	jcxz	gf8
	lea	si,[linebuf]
	add	si,(lbufsize-1)
	mov	byte ptr [si],0 	; insure an end of string marker is there
	jmp	short gf4
gf8:
	mov	si,bp			; recover next search point
	jmp	gf1			; continue scanning for % parms
gf4:
	true?	[forfspec]		; skip update if processing a global filespec
	je	gf11
	dec	byte ptr [forscnt]	; update set member counter
	jz	gf10
	mov	si,[forsptr]		; update set member pointer
	call	findend
	inc	si
	call	passdelims
	mov	[forsptr],si
	jmp	short gf11
gf10:
	setflg	[forend]		; flag the command as the last of the set
gf11:
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
getforcmd endp

;======================================================================
;,fs
; chkecho 
;
; returns z flag if no echo, nz if echo, test for batch flag
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
chkecho proc near
	true?	[batch]
	je	cke1
	cmp	[echostat],false
	jmp	short cke2
cke1:
	cmp	[batecho],false
cke2:
	ret
chkecho endp

;======================================================================
;,fs
; dispplbuf 
;
; test the appropriate echo flag and display prompt and linebuf
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
dispplbuf proc near
	push	dx
	call	chkecho
	jz	dpl1
	true?	[bat@line]		; don't display if the line started
	je	dpl1			; with an @ symbol
	call	dispprompt
	lea	dx,[linebuf]
	call	dispstr
	call	dispeol
dpl1:
	pop	dx
	ret
dispplbuf endp

;======================================================================
;,fs
; setdtaaddr 
;
; initializes the dta address to dtaaddr
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
setdtaaddr proc near
	push	ax
	push	dx
	mov	dx,dtaaddr
	mos	setdta
	pop	dx
	pop	ax
	ret
setdtaaddr endp

;======================================================================
;,fs
; forpush 
;
; saves the current status of the for vars on the for stack
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
forpush proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	mov	bp,[forstke]
	mov	ax,55			; size of constant area of stack block
	mov	bl,[forsbln]
	xor	bh,bh
	add	ax,bx			; calc total bytes for stack block
	call	bytes2para
	mov	bx,ax
	mos	getmem
	call	memcheck
	ljc	ecl2			; insufficient memory
	mov	[forstke],ax		; update end of stack pointer
	mov	dx,ax
	push	es
	mov	es,ax
	xor	di,di
	cld
	mov	ax,bp			; recover original end of stack pointer
	stosw
	mov	al,[forscnt]
	stosb
	mov	ax,[forsptr]
	stosw
	mov	al,[forpchr]
	stosb
	mov	al,[forsbln]
	stosb
	lea	si,[forsbuf]
	xor	ch,ch
	mov	cl,al
	call	copystr
	mov	al,[forfspec]		; vars for global filespec processing
	stosb
	mov	al,[forstop]
	stosb
	mov	al,[forplen]
	stosb
	mov	ax,[forpptr]
	stosw
	lea	si,[fordta]
	mov	cx,43
	call	copystr
	pop	es
	true?	[batch]
	je	fpu1
	mov	[cforstkl],dx		; if at command level, make cforstke track
fpu1:					; forstke as a limit for +flush or baterr
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
forpush endp

;======================================================================
;,fs
; forpop 
;
; restores the current status of the for vars from the for stack
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
forpop proc near
	push	ax
	push	cx
	push	si
	push	di
	push	ds
	mov	ds,[forstke]
	xor	si,si			; set ds:si to point to the stack block
	cld
	lodsw
	mov	es:[forstke],ax
	lodsb
	mov	es:[forscnt],al
	lodsw
	mov	es:[forsptr],ax
	lodsb
	mov	es:[forpchr],al
	lodsb
	mov	es:[forsbln],al
	lea	di,es:[forsbuf]
	mov	cl,al
	xor	ch,ch
	call	copystr
	lodsb				; vars for global filespec processing
	mov	es:[forfspec],al
	lodsb
	mov	es:[forstop],al
	lodsb
	mov	es:[forplen],al
	lodsw
	mov	es:[forpptr],ax
	lea	di,[fordta]
	mov	cx,43
	call	copystr
	push	ds
	mov	ax,es
	mov	ds,ax
	pop	es
	mos	freemem
	call	memcheck
	pop	es
	pop	di
	pop	si
	pop	cx
	pop	ax
	ret
forpop endp

;======================================================================
;,fs
; forclr 
;
; clears the for stack
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
forclr proc near
	cmp	word ptr [forstke],0
	je	fclr1
	call	forpop			; remove all data on the for stack
	jmp	short forclr
fclr1:
	mov	byte ptr [forscnt],0
	ret
forclr endp

;======================================================================
;,fs
; batclr 
;
; clears the bat stack
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
batclr proc near
	push	ax
	push	bx
	push	si
	resflg	[batch]
	mov	ax,[batend]		; flush the bat stack completely
bclr1:
	or	ax,ax
	jz	bclr2
	push	es
	mov	es,ax
	xor	si,si
	mov	bx,es:[si]		; get the backlink
	mos	freemem
	call	memcheck
	pop	es
	mov	ax,bx
	jmp	short bclr1
bclr2:
	mov	[batend],0
	pop	si
	pop	bx
	pop	ax
	ret
batclr endp

;======================================================================
;,fs
; setvects 
;
; initializes the vectors for 22h, 23h and 24h
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
setvects proc near
	push	ax
	push	dx
	push	ds
	lea	dx,[far23hnl]		; set control break vector
	mov	al,23h
	mos	setvct
	push	cs
	pop	ds
	lea	dx,[cb3]		; set terminate address
	mov	al,22h
	mos	setvct
	lea	dx,[criterr]		; set critical error vector
	mov	al,24h
	mos	setvct
	pop	ds
	pop	dx
	pop	ax
	ret
setvects endp

;======================================================================
;,fs
; strcompare 
;
; ds:si and es:di point to the strings, cx is the length, if dx = 0
; then the cases must match, else the string at si is converted l2upper
; if the strings match, the zr flag is true
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
strcompare proc near
	push	ax
	push	cx
	push	si
	push	di
	cld
sc1:
	lodsb
	mov	ah,es:[di]
	inc	di
	cmp	al,ah
	jne	sc2
sc3:
	loop	sc1
	cmp	al,al
	jmp	short sc5
sc4:
	mov	al,1
	cmp	al,0
sc5:
	pop	di
	pop	si
	pop	cx
	pop	ax
	ret
sc2:
	or	dx,dx
	jz	sc4
	call	low2upper
	cmp	al,ah
	je	sc3
	jmp	sc4
strcompare endp

;======================================================================
;,fs
; str2num 
;
; converts the numeric string at ds:si to a value in ax, the cy flag
; will be set for errors or overflow (max value 65535)
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
str2num proc near
	push	bx
	push	dx
	push	bp
	xor	ah,ah
	mov	bx,10
	cld
	lodsb				; get the first digit
	cmp	al,'0'
	jb	sn2
	cmp	al,'9'
	ja	sn2
	sub	al,48			; convert from ascii to numeric
	mov	bp,ax			; save intermeadiate value in bp
sn1:
	lodsb				; get next digit
	cmp	al,'0'
	jb	sn3
	cmp	al,'9'
	ja	sn3
	sub	al,48			; if 0-9, convert and mul the previous
	xchg	ax,bp			; value in bp by 10
	mul	bx
	or	dx,dx			; check for overflow
	jnz	sn2
	xchg	ax,bp
	add	bp,ax			; add the new digit to the tally
	jc	sn4
	jmp	sn1
sn3:
	mov	ax,bp
	clc
sn4:
	pop	bp
	pop	dx
	pop	bx
	ret
sn2:
	stc
	jmp	sn4
str2num endp

;======================================================================
;,fs
; chainclr 
;
; resets the chaining process by clearing the flags and closing
; and deleting the chain files (if they exist)
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
chainclr proc near
	push	ax
	push	bx
	push	dx
	true?	[chainflg]
	jne	ccl0
	call	resetin 		; sah	reset standard in
	call	resetout		; sah	reset standard out
ccl0:
	resflg	[chainflg]
	true?	[pipefile]
	jne	ccl1
	resflg	[pipefile]
	mov	bx,[pfhandl1]
	mos	closfil
	lea	 dx,[pfname1]
	mos	delfil
	mov	bx,[pfhandl2]
	mos	closfil
	lea	dx,[pfname2]
	mos	delfil
ccl1:
	pop	dx
	pop	bx
	pop	ax
	ret
chainclr endp

;======================================================================
;,fs
; byte2hex 
;
; supply byte in al, es:di pointing to data area for hex chars
; to be written
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
nib2hex proc near
	push	bx			; used internaly by byte2hex
	and	al,0fh
	lea	bx,cs:[hextbl]
	xlat	cs:[hextbl]
	pop	bx
	ret
hextbl	db	'0123456789ABCDEF'
nib2hex endp

byte2hex proc near
	push	ax
	push	cx
	cld
	mov	ah,al
	mov	cl,4
	shr	al,cl
	call	nib2hex
	stosb
	mov	al,ah
	call	nib2hex
	stosb
	pop	cx
	pop	ax
	ret
byte2hex endp

;======================================================================
;,fs
; memcheck 
;
; to be called after any mos call to getmem, freemem or modmem
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
memcheck proc near
	pushf
	jnc	mmc1			; was there an error?
	cmp	ax,7
	je	mmc2			; is it 7 or 9?
	cmp	ax,9
	je	mmc2
mmc1:
	popf
	ret
mmc2:
	lea	dx,cs:[badmem]		; if 7 or 9, report and stall
	call	csdisperr
mmc3:
	jmp	mmc3
badmem	db	'Memory allocation chain corrupted       ',cr,lf  ;@@xlat
	db	'Restart partition or reboot machine           ',cr,lf,0  ;@@xlat
memcheck endp

;======================================================================
;,fs
; moveblock 
;
; copies the data from ds:si to es:di using cx as the size
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
moveblock proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	cx
	mov	ax,ds			; convert ds:si to a physical address in dx:ax
	mov	bx,16
	mul	ax
	add	ax,si
	adc	dx,0
	mov	cx,ax
	mov	bp,dx
	mov	ax,es			; convert es:di to physical address
	mul	ax
	add	ax,di
	adc	dx,0
	cmp	dx,bp			; see if the source is above the dest
	ja	mbk1
	jb	mbk2
	cmp	ax,cx
	ja	mbk1
mbk2:
	pop	cx
	cld				; copy up
	jmp	short mbk3
mbk1:
	pop	cx
	std				; copy down
	add	si,cx
	dec	si
	add	di,cx
	dec	di
mbk3:
	rep	movsb			; do the copy
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
moveblock endp

;======================================================================
;,fs
; setprogname 
;
; supply pointer to name string in ds:si  parse the name and copy
; it into the tcb at tcbprgnm
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
setprogname proc near
	push	cx
	push	si
	push	di
	push	es
	call	parse
	lea	si,[prsfcb+1]
	mov	es,[tcbseg]		; address the tcb with es
	lea	di,[tcbprgnm]		; es:di now points to the name field
	mov	cx,11
	call	copystr
	pop	es
	pop	di
	pop	si
	pop	cx
	ret
setprogname endp

;======================================================================
;,fs
; initprogname 
;
; retores the tcb name var to command or whatever comspec is set
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
initprogname proc near
	push	cs			; use the name on the right side of the = as
	pop	ds			; the name for the new shell
	lea	si,[comspc]
	lea	di,[workbuf]
	xor	cx,cx
	call	copystr 		; put the string comspec in workbuf to prepare
	push	es			; for an environment search.
	pop	ds
	call	envsearch		; search the environment
	jc	sx18a
	mov	ds,[envaddr]
	mov	si,bx			; ds:si point to the right side
	call	findlen
	jmp	short sx18b
sx18a:					; if don't find a comspec string,
	push	cs			; stuff the string command in extrbuf
	pop	ds
	lea	si,[smlcms]
	mov	cx,12
sx18b:
	lea	di,[extrbuf]
	cld
sx18c:
	lodsb
	call	writeebuf
	loop	sx18c
	xor	al,al			; make sure we terminate with an zero
	call	writeebuf
	push	es
	pop	ds
	lea	si,[extrbuf]
	call	findfname
	call	setprogname
	ret
initprogname endp

;======================================================================
;,fs
; settcbidnum 
;
; set the var tcbidnum from tcbid of the current tcb
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
settcbidnum proc near
	push	ax
	push	es
	mov	es,[tcbseg]
	assume	es:tcb
	mov	ax,[tcbid]
	mov	[tcbidnum],ax
	pop	es
	assume	es:dataseg
	pop	ax
	ret
settcbidnum endp

;======================================================================
;,fs
; getsetclass - read and set the default output class
;
; note: counts on [targdrv] holding a valid value
;
; in:	al = 0 to return current class (in dl)
;	al = 1 to set class
;	 dl = new class
;
; out:	for entry al = 0, dl = current class
;
;,fe
;======================================================================
	assume	ds:dataseg,es:nothing,ss:nothing
getsetclass proc near
	push	ax
	push	bx
	mov	bh,dh
	mov	dh,[targdrv]
	mov	ah,31h
	call	sim38
	mov	dh,bh
	pop	bx
	jnc	gsc3

; if id4f31 fails, must be under release 5.01 and $$shell.sys
; 5.04 or newer is being used but updat501.sys version 1.08
; or newer isn't loaded to provide the id4f31 support.

	push	es
	mov	es,[tcbseg]
	assume	es:tcb
	or	al,al
	jnz	gsc1
	mov	dl,[tcbcdft]
	jmp	short gsc2
gsc1:
	mov	[tcbcdft],dl
gsc2:
	pop	es
	assume	es:dataseg
gsc3:
	pop	ax
	ret
getsetclass endp

;======================================================================
;,fs
; checkset 
;
; supply ds:si pointing to buffer where '(set) do' should be
; found.	cy if error, else ds:si points to first param after
; the 'do', bx points to the start of the set, dh is the
; length of the set and dl is the number of members.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
checkset proc near
	push	ax
	push	cx
	call	passdelims
	cmp	al,'('
	jne	chs7
	inc	si
	call	passdelims
	mov	bx,si
	cmp	al,')'
	je	chs7
	or	al,al
	jz	chs7
	inc	si
	xor	cl,cl			; init counter for set members
chs1:
	inc	cl
chs2:
	lodsb
	or	al,al
	jz	chs7
	call	testdelims
	je	chs3
	cmp	al,')'
	jne	chs2
	jmp	short chs4
chs3:
	call	passdelims
	jmp	chs1
chs4:
	push	si
	sub	si,2
	std
chs5:
	lodsb
	call	testdelims
	je	chs5
	add	si,2
	sub	si,bx			; calc length of the set portion and
	mov	dx,si			; save in dx
	pop	si
	cld
	lodsb
	call	testdelims
	jne	chs7
	call	passdelims
	call	low2upper
	cmp	al,'D'
	jne	chs7
	inc	si
	lodsb
	call	low2upper
	cmp	al,'O'
	jne	chs7
	lodsb
	call	testdelims
	jne	chs7
	call	passdelims
	or	al,al
	jz	chs7
	clc
chs6:
	mov	dh,dl
	mov	dl,cl
	pop	cx
	pop	ax
	ret
chs7:
	stc				; signal error
	jmp	chs6
checkset endp

;======================================================================
;,fs
; settcbseg 
;
; set the var tcbseg to the current tcb
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
settcbseg proc near
	push	ax
	push	bx
	push	es
	mov	ah,02h
	call	sim38			; sah to simulate call
	mov	[scbseg],es
	mov	[scboff],bx		; save for later
	mov	ax,es:[scbtcbpc+bx]
	mov	[tcbseg],ax
	pop	es
	pop	bx
	pop	ax
	ret
settcbseg endp

;======================================================================
;,fs
; getsetpre 
;
; al=0 return tcbpreseg in si, al=1 set tcbpreseg from si
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
getsetpre proc near
	push	es
	mov	es,[tcbseg]
	assume	es:tcb
	or	al,al
	jnz	gsp1
	mov	si,[tcbpreseg]
	jmp	short gsp2
gsp1:
	mov	[tcbpreseg],si
gsp2:
	pop	es
	assume	es:dataseg
	ret
getsetpre endp

;======================================================================
;,fs
; getsetact 
;
; al=0 return tcbpreseg in si, al=1 set tcbpreseg from si
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
getsetact proc near
	push	es
	mov	es,[tcbseg]
	assume	es:tcb
	or	al,al
	jnz	gsa1
	mov	si,[tcbactseg]
	jmp	short gsa2
gsa1:
	mov	[tcbactseg],si
gsa2:
	pop	es
	assume	es:dataseg
	ret
getsetact endp

;======================================================================
;,fs
; setclaim 
;
; for al=0 trace an except/only list and set all claim bits
; for al<>1 if claim bit not set, set it, set inbat flag and
; copy batend into the block
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
setclaim proc near
	push	ax
	push	si
	push	es
	push	ax
	xor	al,al			; make es point to the current list
	call	getsetpre
	mov	es,si
	assume	es:nothing
	or	si,si
	pop	ax
	jz	scl2			; no list exists
	xor	di,di
	or	al,al			; check incoming mode spec
	jz	scl1
scl3:
	mov	al,es:[di]		; al <> 0, batch file processing
	test	al,4			; check claim bit
	jz	scl4
scl5:
	mov	ax,es:[di+1]		; get next pointer
	or	ax,ax
	jz	scl2			; done with list
	mov	es,ax
	jmp	scl3
scl4:
	or	byte ptr es:[di],5	; set claim and inbat bits
	mov	ax,[batend]
	mov	es:[di+3],ax		; record batend
	jmp	scl5
scl1:
	or	byte ptr es:[di],4	; set claim bit of each block
	mov	ax,es:[di+1]
	or	ax,ax
	jz	scl2
	mov	es,ax
	jmp	scl1
scl2:
	pop	es
	assume	es:dataseg
	pop	si
	pop	ax
	ret
setclaim endp

;======================================================================
;,fs
; getsetsbuf 
;
; al=0 means copy save buffer for func 0a into cp storage and
; null tcb%rs0a and tcb%rs3f.
; al<>0 means resotre save buffer for func 0a and null tcb%rs3f
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
getsetsbuf proc near
	push	bx
	push	cx
	push	ds
	push	es
	mov	bx,[tcbseg]
	or	al,al
	jnz	gsb1
	mov	ds,bx			; copy the keyboard save buffer
	assume	ds:tcb
	lea	si,[tcb%sb0a]
	lea	di,[save0a]
	mov	cx,519
	call	moveblock
	mov	word ptr [tcb%rs0a],0
	mov	word ptr [tcb%rs3f],0
	jmp	short gsb2
gsb1:					; restore the keyboard save buffer
	assume	es:dataseg
	mov	es,bx			; copy the keyboard save buffer
	assume	es:tcb
	lea	di,[tcb%sb0a]
	lea	si,[save0a]
	mov	cx,519
	call	moveblock
	mov	word ptr [tcb%rs3f],0
gsb2:
	assume	es:dataseg
	pop	es
	pop	ds
	pop	cx
	pop	bx
	ret
getsetsbuf endp

;======================================================================
;,fs
; findparent 
;
; find the parent psp segment and set ds and es to it
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
findparent proc near
	push	ax
	push	bx
	push	si
	mos	getpsp
fpa1:
	mov	ds,bx
	mov	ax,bx
	mov	si,16h
	mov	bx,[si] 		; read the parent pointer of the psp
	cmp	bx,ax			; is the parent = to the psp it came from?
	jne	fpa1			; if not, trace back a step further
	mov	es,ax
	pop	si
	pop	bx
	pop	ax
	ret
findparent endp

;======================================================================
;,fs
; str2numdw 
;
; converts the numeric string at ds:si to a value in dx:ax, the
; cy flag will be set for errors or overflow out of dx:ax
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
str2numdw proc near
	push	bx
	push	cx
	push	di
	push	bp
	xor	ax,ax			; init starting values
	xor	dx,dx			; "     "	"
	cld
	lodsb				; get the first digit
	cmp	al,'0'
	jb	snd2			; invalid number
	cmp	al,'9'
	ja	snd2			; ditto
	sub	al,'0'			; convert from ascii to numeric
	mov	bp,ax			; save intermeadiate value in bp:si
	xor	di,di
snd1:
	lodsb				; get next digit
	cmp	al,','
	je	snd1			; skip over a comma
	cmp	al,'0'
	jb	snd3			; must be end of string
	cmp	al,'9'
	ja	snd3			; end of string
	sub	al,'0'			; if 0-9, convert and mul the previous
	xchg	ax,bp			; value in bp:di by 10
	xchg	dx,di
	sal	ax,1			; multiply by 10 using the equation
	rcl	dx,1			; 10x = 8x + 2x
	jc	snd4			; overflow, value to high
	mov	bx,ax
	mov	cx,dx
	sal	ax,1
	rcl	dx,1
	jc	snd4			; overflow
	sal	ax,1
	rcl	dx,1
	jc	snd4			; overflow
	add	ax,bx
	adc	dx,cx
	jc	snd4			; one more time!
	xchg	ax,bp
	xchg	dx,di
	add	bp,ax			; add the new digit to the tally
	adc	di,dx
	jc	snd4			; ok, really this is the last time!
	jmp	snd1
snd3:
	mov	ax,bp
	mov	dx,di
	clc
snd4:
	pop	bp
	pop	di
	pop	cx
	pop	bx
	ret
snd2:
	stc
	jmp	snd4
str2numdw endp

;======================================================================
;,fs
; clrsetsall 
;
; clear or set all security
; input:	al = 0	 - clear user name, security map, class
; al <> 0  - set secuity to full access
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume ds:dataseg, es:dataseg
clrsetsall proc near
	push	ax
	push	cx
	push	di
	push	es
	mov	es,[tcbseg]		; get tcb segment
	lea	di,tcbcmap		; point to tcb map
	mov	cx,7			; map is seven bytes
	or	al,al
	jz	clrsall

; set security to full access

	mov	al,0ffh
	cld
	rep	stosb
	jmp	short sallexit

; clear security to space class
   
clrsall:
	xor	ax,ax			; just in case somebody changes the code
	cld
	rep	stosb			; zap the map
	mov	es:[tcbcdft],al
	mov	word ptr es:[tcbuser],ax
	mov	word ptr es:[tcbuser+2],ax
sallexit:
	pop	es
	pop	di
	pop	cx
	pop	ax
	ret
clrsetsall endp

;======================================================================
;,fs
; cleansign 
;
; signon security cleanup routine
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume	ds:dataseg,es:dataseg
cleansign proc near
	push	ax
	true?  [signfix1]
	jne	csignmem
	xor	al,al
	call	clrsetsall		; clear all security information
	resflg [signfix1]
csignmem:
	true?  [copyfix2]
	jne	csignexit
	push	es
	mov	es,[copyseg]		; free up buffers
	push	cx
	push	di
	mov	cx,[copysize]		; zap memory use by signon!
	xor	al,al
	xor	di,di
	rep	stosb
	pop	di
	pop	cx
	mos	freemem
	call	memcheck
	pop	es
	resflg [copyfix2]
csignexit:
	push	es
	xor	ax,ax
	mov	es,ax
	assume	es:nothing,ds:csignons
	cmp	word ptr es:[23h*4],offset cmd:signint23
	jne	novectors
	mov	ax,[sign23o]
	cli
	mov	word ptr es:[23h*4],ax
	mov	ax,[sign23s]
	mov	word ptr es:[23h*4+2],ax
	sti
	assume	ds:dataseg
	mov	es,[tcbseg]
	assume	es:tcb,ds:csignons
	mov	al,[organsi]
	mov	[tcbansi],al
novectors:
	pop	es
	assume ds:dataseg,es:dataseg
	pop	ax
	ret
cleansign endp

;======================================================================
;,fs
; dectobin 
;
; decimal-to-binary routine
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume ds:dataseg,es:dataseg
dectobin proc near
	 push	bp
	 xor	bp,bp
	 xor	ax,ax			; ax will contain the result
	 mov	[minsign],'n'
	 cmp	byte ptr [bx],'-'	; check for minus sign
	 jne	dtbloop
	 mov	[minsign],'y'
	 inc	bx
dtbloop:				; bx is source address
	 mov	dl,[bx]
	 cmp	dl,'0'
	 jb	dtbwrap
	 cmp	dl,'9'
	 ja	dtbwrap
	 push	dx
	 xor	dx,dx
	 mul	[wordten]
	 or	dx,dx
	 jz	dtbskip
	 inc	bp
dtbskip:
	 pop	dx
	 and	dx,000fh
	 add	ax,dx
	 inc	bx
	 jmp	dtbloop
dtbwrap:
	 cmp	[minsign],'y'
	 jne	dtbret
	 neg	ax
dtbret:
	 mov	dx,bp
	 pop	bp
	 ret
dectobin endp

;======================================================================
;,fs
; sim38 
;
; function: sim38 - simulate int 38 call to scbfar38 (reach is derived
; when command.com is first execucted and store in variable
; farcall38.	 this is to avoid problems with ms-c compiled
; progrems.	there should not be a single int 38 call in
; $$shell.sys
;
; new calling conventions created by sah on 05/12/88  (dataflex)
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume	ds:dataseg
sim38 proc near
	pushf
	call	dword ptr [farcall38]	; simulate the int 38 call
	ret
sim38 endp


;======================================================================
;,fs
; qualify_filename 
;
; this function checks the submitted dos filename (without path) for
; correct syntax.  the correct syntax of a dos filename is an eight
; character root name followed by a dot and a 3-character file extension
; if specified.  if the name does not qualify, the carry flag is set.
;
; input:
; si -	  positioned to beginning of filename.
;
; output:
; cf set if name does not qualify.
;
; all registers saved.
;
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
qualify_filename proc near
	push	ax
	push	cx
	push	di
	cld				; all scans forward.

; is the filename longer than 12 characters (including extension) ?  if
; so, fail it immediately.

	mov	di,si
	xor	al,al			; look for null terminator.
	mov	cx,13			; scan 1 byte farther than legal size.
	repnz	scasb
	jnz	qf_err			; if not found, name too long.

; Compute the length of the name so the next scan won't go beyond
; the end of the string.  Then search for the file extension dot
; in the filename.

	mov	cx,di			; compute length of filename.
	sub	cx,si

	mov	di,si			; start where si is.
	mov	al,'.'
	repnz	scasb
	jnz	qf_no_extension

; the dot was found.  was it in a position > 8?  if so, the
; root part of filename is too long.

	mov	ax,di
	sub	ax,si
	cmp	ax,9			; remember, di was 1 beyond the dot.
	ja	qf_err

; the rest of the filename must be 1 to 3 characters.	(don't
; accept a filename with a dot, but no extension.)

	cmp	byte ptr [di],0 ; no extension?
	je	qf_err

	mov	cx,4
	xor	al,al			; look for the null terminator.
	repnz	scasb
	jnz	qf_err			; if not found, extension too long.
	clc				; the file is o.k.
	jmp	short qf_exit

; no extension in the file.  the length of the filename must be
; 8 characters or less.

qf_no_extension:
	mov	cx,9
	xor	al,al			; look for the null terminator.
	mov	di,si
	repnz	scasb
	jnz	qf_err			; if not found, filename is too long.
	clc				; filename is ok.
	jmp	short qf_exit
qf_err:
	stc
qf_exit:
	pop	di
	pop	cx
	pop	ax
	ret
qualify_filename endp


;======================================================================
;,fs
; make_file_date 
;
; this function obtains the current system date and time and returns it
; in a format usable for setting a file's time and date.
;
; input:		none
; output: 	cx = system time.
;			dx = system date.
;
; the dx:cx pair may be used immediately to set a file's time and date
; stamp via int 21/57.
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
	assume cs:cmd,ds:dataseg,es:dataseg
make_file_date proc near
	push	ax
	mos	getdate 		; get system date.
	mov	ax,cx			; build date word in ax.
	sub	ax,1980
	mov	cx,4			; make room for month.
	sal	ax,cl
	add	al,dh			; add the month in.
	mov	cx,5			; make room for day of month.
	sal	ax,cl
	add	al,dl			; add the day in.
	push	ax			; save the date word on stack.
	mos	gettime 		; get system time.
	xor	ah,ah			; build time word in ax.
	mov	al,ch			; put hours in ax.
	xchg	ah,al			; make room for minutes entry. (6-bits)
	sar	ax,1
	sar	ax,1
	add	al,cl			; add minutes to the entry.
	mov	cx,5
	sal	ax,cl			; make room for 2-second increments.
	sar	dh,1			; convert seconds entry to 2-second increments.
	add	al,dh			; add to time word.
	mov	cx,ax			; return the time word in cx.
	pop	dx			; get date word back off stack.
	pop	ax
	ret
make_file_date endp

codeseg ends
	end substart
