	include page.inc
comment ^===============================================================
			       internal commands

07/07/87 sah	correct problem with if exist - actually goto
			del *.xxx with read-only file

07/08/87 sah	correct problem with / with cd, dir & echo

07/11/87 sah	converted 80h int 21h to int 38h 00+

07/28/87 jsm	added code to prevent copy command from
			reporting "cannot copy file to itself" if the
			source file does not exist.

08/06/87 sah	correct problem with rename /m option

08/16/87 mjs	change open method in copy and type command
			to work with multiple access to the pipe driver

mjs 10/21/87	correct system crashing problem when do
		"del \xyz.dir /y'

11/11/87 sjc	re-modified open method in type and copy to
			allow read-only types and copies.  should have
			been mod'd for deny none, read access

11/20/87 jsm	changed copy command to kill trailing blanks
			on target operand after copying it out of
			parmbuf.

mjs 11/30/87	corrected problem with	'dir /sn /d /w'

mjs 12/2/87	corrected spinoff effect of sjc's earlier correction to
		the 'copy' command regarding read only files.  removing
		write access from the open mode meant that the form:
		'copy x1 + x2  x1' would fail.	added a test for a read
		only file and used different open mode for each case.
		removed two lines from rename that sah put in on
		8/6/87.

mjs 1/29/88	complete overhaul of the rename command to remove bugs,
		get rid of patchy logic and add new feature to allow
		a subdirectory to be renamed.

sah 05/12/88	change int 38 calls to simualated calls

jrb 08/05/88	set copy buffer to 512 byte boundary instead of 128

rkg 11/03/88	changes to facilitate foreign language conversion

sah 11/10/88	remove 08/05/88 update which cause mcb chain corrupts

mjs 11/15/88	add mkdir to command list

sah 11/18/88	corrected bug date command line version because of an
		oversight of not get country information for use later.

sah 11/29/88	made corrections to envsize and set commands necessary
		becauses of changes made for command processor's
		enviroment area being in seperated mcb need for novell's
		mosnet.com.  also i temporary comment uses to console
		stack buffer because it is currently not implemented.
		please note: if implemented changes will likely need to
		made because of the aboved.

mjs 12/02/88	overhaul envsize and set commands.

rdg 12/16/88	modified cpy99 to make sure that even when the full
		source and target pathnames are not identical, that they
		do not (via an alias) identify the same file.  this is
		accomplished by calling pathchek who does a find first
		with each pathname and then compares the information
		returned in the dta area.  this fixes the zero file
		length error caused by an invalid copy command (i.e.
		copy test.000a:\).

rdg 12/19/88	added code to badparm to make sure that verify is reset
		and	that memory is released when a bad parameter
		(badparm1 - badparm8) is encountered.

rkg 01/18/89	date prompt was not translating add year,month,day lits

rkg 02/27/89	pause displays remainder of line if non-null

mjs 06/06/89	modified the type command to not output a cntrl-z.

mjs 06/21/89	added code to manage the $compat$ environment variable.

sah 08/15/89	made cls use int function 0f and 00, so ansi is nolonger
		required and that we have better respond serially.

mjs 08/16/89	corrections for signon which make it turn on ansi
		support temporary. must be modified if ansi support is
		ever going to me move to a seperated driver.

bwr 4/5/90	problem with the "cd" command allowing invalid
		directory names entered has been corrected.

mjs 05/17/90	corrected code around cpy11c.  issuing a command
		such as  copy xyz con:	  with trailing spaces
		was causing an improper error condition.

bwr 8/29/90	corrected code in cdir.  when a command such as the
		following is entered

			dir ..\misc

		the specified directory underneath the parent was
		being listed correctly.  however, the command

			dir ..\misc\*.*

		was resulting in the current directory being listed.
		this was happening because the parsing logic was not
		considering the possibility of a wildcard entry at the
		end of the string.  it therefore appended "\*.*" to it,
		confusing the logic into thinking the command was
		dir *.*.


bwr 8/30/90	simplified above change (8/29) by using routine "parse"
		in	moxcpsub to determine presence of wildcards in the
		filename.

bwr 8/31/90	corrected two problems:

		1) rename command when issued with only 1 parameter
		   was giving the wrong error message.	now correctly
		   tells user he entered wrong # of parameters.

		2) a file located on another drive could not be renamed.
		   for example:

			ren c:\misc\test1.txt  newname.txt

		   would not work.  now it works.

bwr 11/20/90	corrected problem with type command.  in the case where
		the user invoked the following command:

			type file1 >> file1

		the partition appeared to hang.  the partition did not
		hang.  after the redirection output to the same file
		was done, type was continuing to read the file which
		was then longer than it started out.  this continued
		unabated until either the disk filled up or the partition
		was shut down.	type now knows to check the length of
		the file before starting so it won't continue reading
		its own output in this special case!

bwr 12/17/90	rewrote logic to handle copying of files to themselves.
		this is done via the following command:

			copy [/b] filename+,,

		although a relatively unknown "feature" of dos and mos
		command processors, it is a method by which a file may
		be truncated at the first dos eof character (0x1a).  it
		is also, using the /b argument, a crude method of perfoming
		a unix type "touch" command to update the file date/time
		stamp.	the logic handling said update has also been updated
		to set the date/time stamp as required by the above syntax.

bwr 2/19/91	prepared command tables for foreign language translation.
		(russian)

mjs 07/16/91	version 4.16, corrected problem with open mode for
		copy command.  using 3d00 if [findplus] not true.  need
		3d00 for sbt's install program, otherwise, need deny none,
		read/write to accomodate "copy x1+x2 x1".  moxcpcor was
		changed to effect the new version number.

sah 09/10/91	version 4.17, corrected problem with great plains
rsr		install batch file. need to convert tabs into spaces

rsr 02/28/92	change for cleanup of release of mos 5.  added
		brackets around subdirectory names to be similar
		to dos 5.

mjs 03/07/92	make sure the reported path is current if do a path
		command right after running novell's login.exe.

rsr/sah 03/26/92 fixes for 1.4 gig drive

rsr	03/27/92 bug fix for beta 2 5.01

rsr	05/04/92 added rmdir for roel jansen. (re badmouthing fax)

mjs 09/17/92	added code to copy command to set targdrv.
		cleaned up module.

======================================================================^

include moxcpdat.inc			; data declarations

cmd	group	codeseg

tcb segment at 0
	org	00801h
tcbansi db	?			; ansi.sys emulation flag non-zero = on
tcb	ends

codeseg segment

	assume	cs:cmd,ds:dataseg,es:dataseg

include moxcpint.pub			; public defs

include moxcpsxt.inc			; external declarations for moxcpsub

extrn cmfl : near, cmf1 : near, issueprompt : near, baterr : near
extrn bateof : near, batresume : near, echostr : byte, processlbuf : near
extrn bater1 : near, closebat : near, openbat : near, batresume : near
extrn brkstr : byte, onstr : byte, offstr : byte, pthstrg : byte
extrn prmstrg : byte, verstr : byte, ecl1 : near, ecl2 : near
extrn ecl3 : near, yesmsg:byte, nomsg:byte, qualify_filename:near
extrn make_file_date:near
extrn hibin2dec:near

;--------------------------- start of code -------------------------

intstart:

cmdtbl	db	'ECHO    '		;@@xlat
	dw	offset cmd:cecho
	db	0			; don't clear/set errlvl

	db	'FOR     '		;@@xlat
	dw	offset cmd:cfor
	db	0			; don't clear/set errlvl

	db	'GOTO    '		;@@xlat
	dw	offset cmd:cgoto
	db	0			; don't clear/set errlvl

	db	'IF      '		;@@xlat
	dw	offset cmd:cif
	db	0			; don't clear/set errlvl

	db	'PAUSE   '		;@@xlat
	dw	offset cmd:cpause
	db	0			; don't clear/set errlvl

	db	'REM     '		;@@xlat
	dw	offset cmd:crem
	db	0			; don't clear/set errlvl

	db	'CD      '		;@@xlat
	dw	offset cmd:cchdir
	db	0ffh			; clear/set errlvl

	db	'CLS     '		;@@xlat
	dw	offset cmd:ccls
	db	0			; don't clear/set errlvl

	db	'COMMAND '		;@@xlat
	dw	offset cmd:ccommand
	db	0			; don't clear/set errlvl

	db	'COPY    '		;@@xlat
	dw	offset cmd:ccopy
	db	0ffh			; clear/set errlvl

	db	'DATE    '		;@@xlat
	dw	offset cmd:cdate
	db	0			; don't clear/set errlvl

	db	'DEL     '		;@@xlat
	dw	offset cmd:cerase
	db	0ffh			; clear/set errlvl

	db	'DIR     '		;@@xlat
	dw	offset cmd:cdir
	db	0ffh			; clear/set errlvl

	db	'ERASE   '		;@@xlat
	dw	offset cmd:cerase
	db	0ffh			; clear/set errlvl

	db	'EXIT    '		;@@xlat
	dw	offset cmd:cexit
	db	0			; don't clear/set errlvl

	db	'MD      '		;@@xlat
	dw	offset cmd:cmkdir
	db	0ffh			; clear/set errlvl

	db	'MKDIR   '		;@@xlat
	dw	offset cmd:cmkdir
	db	0ffh			; clear/set errlvl

	db	'PATH    '		;@@xlat
	dw	offset cmd:cpath
	db	0ffh			; clear/set errlvl

	db	'PROMPT  '		;@@xlat
	dw	offset cmd:cprompt
	db	0ffh			; clear/set errlvl

	db	'RENAME  '		;@@xlat
	dw	offset cmd:crename
	db	0ffh			; clear/set errlvl

	db	'REN     '		;@@xlat
	dw	offset cmd:crename
	db	0ffh			; clear/set errlvl

	db	'RD      '		;@@xlat
	dw	offset cmd:crmdir
	db	0ffh			; clear/set errlvl

	db	'RMDIR   '		;@@xlat
	dw	offset cmd:crmdir
	db	0ffh			; clear/set errlvl

	db	'SET     '		;@@xlat
	dw	offset cmd:cset
	db	0ffh			; clear/set errlvl

	db	'TIME    '		;@@xlat
	dw	offset cmd:ctime
	db	0			; don't clear/set errlvl

	db	'TYPE    '		;@@xlat
	dw	offset cmd:ctype
	db	0ffh			; clear/set errlvl

	db	'ENVSIZE '		;@@xlat
	dw	offset cmd:cenvsiz
	db	0ffh			; clear/set errlvl

	dw	0			; end of table marker

;===================== echo ============================

	assume	ds:dataseg,es:dataseg
cecho:
	true?	[nullparm]
	je	cec1
	lea	si,[parmbuf]
	call	passdelims
	call	low2upper
	cmp	al,'O'			; if first non-delim = 'O', could be on or off
	je	cec2
cec5:
	lea	dx,[parmbuf+1]		; dump the string parameter
	call	dispstr
	call	dispeol
	jmp	cmfl
cec1:					; display echo status
	lea	dx,cmd:[echostr]
	true?	[batch]
	je	cec3
	mov	al,[echostat]
cec4:
	call	reportstat
	jmp	cmfl
cec3:
	mov	al,[batecho]
	jmp	cec4
cec2:					; check for 'ON' or 'OFF'
	inc	si
	cld
	lodsb
	call	low2upper
	cmp	al,'N'
	je	cec6			; check for 'ON'
	cmp	al,'F'
	jne	cec5			; dump
	lodsb
	call	low2upper
	cmp	al,'F'			; check for 'OFF'
	jne	cec5
	call	passdelims
	or	al,al
	jnz	cec5
	true?	[batch]			; turn the flag off
	je	cec7
	resflg	[echostat]
	jmp	cmfl
cec7:
	resflg	[batecho]
	jmp	cmfl
cec6:
	call	passdelims
	or	al,al
	ljnz	cec5			; dump
	true?	[batch]			; turn the flag on
	je	cec8
	setflg	[echostat]
	jmp	cmfl
cec8:
	setflg	[batecho]
	jmp	cmfl

;====================== for in do =======================

	assume	ds:dataseg,es:dataseg
cfor:
	call	chainclr
	true?	[nullparm]
	lje	badparm6
	lea	si,[parmbuf]
	cld
	call	passdelims
	cmp	al,'%'
	ljne	badparm6
	inc	si
	lodsb
	call	testdelims
	lje	badparm6
	or	al,al
	ljz	badparm6
	call	low2upper
	mov	ch,al			; save the char after the % for replacement
	lodsb
	call	testdelims
	ljne	badparm6
	call	passdelims
	call	low2upper
	cmp	al,'I'
	ljne	badparm6
	inc	si
	lodsb
	call	low2upper
	cmp	al,'N'
	ljne	badparm6
	lodsb
	call	testdelims
	ljne	badparm6
	call	checkset		; check for (set) do spec
	ljc	badparm6		; returns data in si, bx, dx
	cmp	byte ptr [forscnt],0	; test present value of forscnt to
	lje	cfr10			; check for nesting for for commands
	call	forpush
	resflg	[forfspec]
cfr10:
	mov	[forpchr],ch		; save the char after the % for replacement
	mov	[forscnt],dl		; all syntax checks passed, store set count
	xor	cx,cx			; si points to start of command
	lea	di,[forsbuf]		; copy the command to forsbuf
	call	copystr
	mov	[forsptr],di		; mark the position in forsbuf where the
	mov	dl,dh			; set string will go
	xor	dh,dh
	mov	cx,dx
	mov	si,bx			; recover pointer to the start of the
	call	copystr			; set string in parmbuf
	mov	byte ptr [di],0		; mark end of set string in forsbuf
	mov	ax,di
	inc	ax
	sub	ax,offset [forsbuf]
	mov	[forsbln],al		; calc and record original length of forsbuf
	mov	si,[forsptr]
	mov	cl,[forscnt]
	xor	ch,ch
cfr8:					; convert the set string into substrings
	call	passdelims
	call	finddelim
	mov	byte ptr [si],0
	inc	si
	loop	cfr8
	call	getforcmd		; resets mlstrt, replaces parm and updates
					; forscnt and forsptr for next time
	call	chkecho
	ljz	cfr9
	call	dispeol
cfr9:
	call	dispplbuf		; test echo and display line
	jmp	processlbuf

;======================= goto ========================

	assume	ds:dataseg,es:dataseg
cgoto:
	true?	[batch]
	ljne	cmfl			; ignore if not in a batch file
	mov	ax,[forstke]		; ignore if the for stack is not empty
	cmp	ax,[batforse]
	ljne	cmf1
	true?	[nullparm]
	lje	gt1
gtplus1:				;!!!!!!! entry point from +call command
	call	openbat			; open the batch file
	mov	word ptr [batline],0
	mov	word ptr [batline+2],0
gt2:
	mov	bx,[bathandl]
	mov	dx,word ptr [batline]
	mov	cx,word ptr [batline+2]
	xor	al,al
	mos	lseek			; get batline and seek the next line to be read
	ljc	bater1
	call	readbatline		; read a batch file line into linebuf
	ljnz	gt6
	lea	si,[linebuf]
	call	passdelims
	cmp	al,':'			; if the line starts with a :, its a label
	jne	gt2
	inc	si
	mov	di,si
	lea	si,[parmbuf]		; find the start of the parameter
	call	passdelims
gt2lp:
	lodsb				; see if goto :label
	cmp	al, ':'
	je	gt2lp			; next char
	dec	si
	mov	cx,8
	cld
	xor	dl,dl			; init a once flag
gt3:
	lodsb				; get a char from the parameter
	call	low2upper
	mov	ah,al
	mov	al,[di]
	inc	di
	call	low2upper
	cmp	al,ah
	jne	gt4
	or	al,al
	jz	gt4			; if both strings end at same time, gt4
	mov	dl,1			; set flag to show at least one matching
	loop	gt3			; set of chars was found (not 0 and 0)
gt5:
	call	closebat		; close the batch file
	call	chkecho
	jz	gt5a
	call	dispeol
gt5a:
	mov	byte ptr [forscnt],0
	jmp	batresume
gt4:
	or	dl,dl
	ljz	gt2			; try another line
	call	testdelims
	je	gt7			; if the mismatch due to end of linebuf string
	cmp	al,0			; then the parmbuf string must end too
	jz	gt7
	jmp	gt2			; try another line
gt7:
	mov	al,ah			; see if parmbuf string ends
	call	testdelims
	je	gt5
	or	al,al
	jz	gt5
	jmp	gt2			; try another line
gt6:
	call	closebat		; close the batch file
gt1:
	mov	al,213			; label not found
	call	reporterror
	jmp	baterr

;=========================== if ========================

	assume	ds:dataseg,es:dataseg

errstr	db	'ERRORLEVEL'
notstr	db	'NOT'
exisstr db	'EXIST'

cif:
	true?	[nullparm]
	lje	badparm6
	lea	si,[parmbuf]
	call	passdelims
	xor	bp,bp			; reset not flag
	push	cs
	pop	es
	lea	di,[notstr]
	mov	dx,1			; mod si string to ucase
	mov	cx,3
	call	strcompare		; found 'NOT'
	jne	cif1
	mov	bp,1			; set not flag
	add	si,3
	call	passdelims
cif1:
	lea	di,[errstr]
	mov	cx,10
	call	strcompare
	lje	cif2			; found 'ERRORLEVEL'
	lea	di,[exisstr]
	mov	cx,5
	call	strcompare
	push	ds
	pop	es
	lje	cif3			; found 'EXIST'
	mov	di,si			; treat as 'string1 == string2' case
	call	finddelim
	mov	bx,si
	call	passdelims
	mov	dx,si
	mov	cx,si
	sub	cx,bx			; calc length of space between strings
	mov	si,bx
	mov	al,'='
	call	scanstr
	ljne	badparm6
	cmp	byte ptr [si+1],'='	; check for '=='
	ljne	badparm6
	mov	cx,bx
	sub	cx,di			; calc length of first string
	mov	si,dx			; make si point to second string
	push	si
	mov	bx,si
	call	finddelim
	sub	si,bx
	mov	ax,si			; length of second string in ax
	pop	si
	cmp	cx,ax
	jne	cif4a
	push	si
	mov	si,di
	call	str2upper
	pop	si
	mov	dx,1
	call	strcompare
	pushf
	call	finddelim
	call	passdelims		; make si point to start of command
	or	al,al
	jz	cif7
	popf
	lje	cif6
	jmp	cif4
cif7:
	pop	ax			; compensate stack for pushf
	jmp	badparm6
cif2:					; 'ERRORLEVEL' case
	push	ds
	pop	es
	add	si,10
	call	passdelims		; make si point to start of number
	call	str2num
	ljc	badparm6		; syntax error
	push	ax
	call	passdelims
	pop	ax
	or	ah,ah
	ljnz	badparm6
	cmp	[errlvl],al
	jae	cif6
	jmp	cif4
cif3:					; 'EXIST' case
	add	si,5
	call	passdelims		; make si point to start of file name
	mov	dx,si
	call	finddelim
	cmp	byte ptr [si],0
	lje	badparm6		; syntax error
	mov	byte ptr [si],0
	inc	si
	call	passdelims		; make si point to start of command
	xor	cx,cx
	mos	fndfrst
	jc	cif4
cif6:
	or	bp,bp
	jz	cif5
	jmp	cmfl
cif4a:
	call	finddelim
	call	passdelims		; make si point to start of command
cif4:
	or	bp,bp
	ljz	cmfl
cif5:					; the if statement is true, execute the command
	lea	di,[linebuf]		; put command in linebuf
	mov	[mlstrt],di
	xor	cx,cx
	call	copystr
	jmp	processlbuf

;=========================== pause ========================

	assume	ds:dataseg,es:dataseg

cpause:
	true?	[nullparm]		; check for null parameters
	je	cpauswt
	lea	dx, parmbuf+1		; else display remainder of line
	call	dispstr
	call	dispeol			; and newline
cpauswt:
	call	pausesubr
	call	dispeol
	jmp	cmfl

;=========================== rem ========================

crem:
	jmp	 cmfl

;=========================== chdir ========================

	assume	ds:dataseg,es:dataseg

trimback proc
	push	ax
	push	si
	call	findend
	dec	si
	std
tmb1:
	lodsb
	call	testdelims
	jz	tmb1
	mov	byte ptr [si+2],0
	pop	si
	pop	ax
	ret
trimback endp


cchdir:
	lea	si,[parmbuf]
	call	trimback
	call	parse			; parse the parameter for a drive spec
	cmp	al,0ffh
	lje	badparm4		; invalid drive spec
	call	oneparmchk		; should only be one parameter at most
	ljc	badparm5		; invalid directory
	cmp	byte ptr [si],fslash
	lje	badparm2
	cmp	byte ptr [prsfcb+1],0
	jne	ccd1			; check for a path name
	cmp	byte ptr [si],bslash
	je	ccd1
	lea	si,[parmbuf]
	call	passdelims		; check for . or .. entry
	cmp	al,'.'
	je	ccd1
	mov	dl,byte ptr [prsfcb]
	or	dl,dl
	jnz	ccd2			; if parsed drive is 0, must read default drv
	mos	getdrv
	inc	al
	mov	dl,al
ccd2:
	lea	si,[workbuf]
	mov	al,dl			; write drive letter, ':' and '\' in workbuf
	add	al,64
	mov	[si],al
	mov	byte ptr [si+1],':'
	mov	byte ptr [si+2],bslash
	add	si,3
	mos	getdir			; read the current directory, drive in dl
	ljc	badparm4
	lea	dx,[workbuf]
	call	dispstr			; display the directory
	call	dispeol
	jmp	cmfl
ccd1:
	lea	si,[parmbuf]
	call	passdelims
	mov	dx,si			; attempt the chdir the parameter
	call	findfname
	cmp	byte ptr [si],0		; just a \ ?
	je	ccskip
	mov	al,[si]
	call	testdelims
	jz	ccskip1
	cmp	word ptr [si],2e2eh	; a .. ?
	je	ccskip
	call	qualify_filename	;is the filename legitimate?
	ljc	badparm5		;invalid directory name.
	xor	al,al
	call	getsetact		; temporarily suspend any +except/+only
	mov	[tempseg],si		; list(s) which may be active
	xor	si,si
	mov	al,1
	call	getsetact
	mov	cx,12h
	mos	fndfrst
	pushf
	push	ax
	mov	si,[tempseg]		; restore original tcbactseg
	mov	word ptr [tempseg],0
	mov	al,1
	call	getsetact
	pop	ax
	popf
	ljc	badparm5		; this test put in to prevent a cd to a
ccskip:					; directory that you cannot normally see
	mos	chdir
	ljc	badparm5		; invalid directory
	jmp	cmfl
ccskip1:
	mov	byte ptr [si],0
	jmp	ccskip

;=========================== cls ========================

	assume	ds:dataseg,es:dataseg

clsstr	db	27,'[2J',0

ccls:
	push	ds
	mov	ds,[tcbseg]
	assume	ds:tcb
	mov	bl,[tcbansi]		; get current ansi emulation
	mov	[tcbansi],0ffh		; put system in ansi emulation
	lea	dx,cs:[clsstr]
	call	csdispstr
	mov	[tcbansi],bl
	pop	ds
	assume	ds:dataseg
	jmp	cmfl

;=========================== command ========================

ccommand:

; note, this label is used only as an address reference. never jump here

;=========================== copy ========================

;======================================================================
;,fs
; cpy20  - process options for a source file spec
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume	ds:ccopys
cpy20 proc near
	call	passdelims
	cmp	al,fslash
	jne	cpy26
	mov	al,[si+1]
	call	low2upper
	cmp	al,'A'
	je	cpy27
	cmp	al,'B'
	je	cpy28
	stc
	ret
cpy26:
	clc
	ret
cpy27:
	setflg	[csaopt]
	resflg	[csbopt]
	jmp	cpy29
cpy28:
	setflg	[csbopt]
	resflg	[csaopt]
cpy29:
	setflg	[specsopt]
	mov	word ptr [si],2020h
	jmp	cpy20
cpy20 endp

;======================================================================
;,fs
; cpy72 - close the target file (if one exists)
;
; in:
;
; out:
;
;,fe
;======================================================================
cpy72 proc near
	true?	[existrg]
	ljne	cpy69
	true?	[ctaopt]
	jne	cpy74
	true?	[spectopt]
	jne	cpy74
	true?	[trgdev]
	je	cpy74
	mov	cx,1			; if ctaopt is true, write a 1a to the file
	mov	bx,[trghndl]
	mov	ax,[copyseg]
	mov	ds,ax
	xor	dx,dx
	xor	si,si
	mov	byte ptr [si],1ah
	mos	writfil
	push	es
	pop	ds
	cmp	ax,1
	ljne	cpy75			; disk full error
cpy74:
	true?	[movedate]
	jne	cpy71
	true?	[trgdev]
	je	cpy71
	mov	bx,[trghndl]
	mov	cx,[newtime]		; get the time and date from the source file
	mov	dx,[newdate]
	mov	al,1
	mos	57h			; set the target file's time and date
	lea	dx,[trgbuf]		; path of the target file
	lea	bx,[cdatbuf]
	mov	al,1
	mov	ah,03h			; set user, creation date/time
	call	sim38			; be the same as the target file's class)
	jmp	short cpy71a
cpy71:
	true?	[set_sysdate]
	jne	cpy71a
	mov	bx, [trghndl]
	call	make_file_date		; get system date/time in dx:cx
	mov	al, 1
	mos	57h
cpy71a:
	mov	bx,[trghndl]
	mos	closfil			; close the target file
	mov	[trghndl],0
cpy69:
	ret
cpy72 endp

;======================================================================
;,fs
; cpy76 - display the file name
;
; in:
;
; out:
;
;,fe
;======================================================================
cpy76 proc near
	push	dx
	lea	dx,[workbuf]
	call	dispstr
	pop	dx
	ret
cpy76 endp

;======================================================================
;,fs
; cpy100 - copy/c logic
;
; procedure to change a file's class by copying it into a temp file.
; call with source in workbuf.	uses attmpt1 for target
;
; in:
;
; out:
;
;,fe
;======================================================================
cpy100 proc
	lea	si,[workbuf]		; on entry, bp is a skip flag
	lea	di,[attmpt1]
	xor	cx,cx
	call	copystr			; put the source file's drive and path in
	lea	si,[attmpt1]		; attmpt1 to create the target file string
	call	findfname
	mov	di,si
	cld
	mov	al,'$'
	stosb
	stosb
	mov	al,' '
	stosb
	stosb
	mov	al,'$'
	stosb
	stosb
	xor	al,al
	stosb				; create the file name '$$  $$'
	lea	dx,[workbuf]
	lea	di,[attmpt1]		; attmpt1 is now the source file buffer
	mos	rename
	ljc	copyerr
	xor	al,al
	call	getsetact		; temporarily suspend any +except/+only
	mov	[tempseg],si		; list(s) which may be active
	xor	si,si
	mov	al,1
	call	getsetact
	lea	dx,[attmpt1]
	mov	al,00100000b		; inherit, deny write, read access
	mos	openfil			; open the source file ($$  $$)
	pushf
	push	ax
	mov	si,[tempseg]		; restore original tcbactseg
	mov	word ptr [tempseg],0
	mov	al,1
	call	getsetact
	pop	ax
	popf
	ljc	cpy100er1
	mov	[srchndl],ax
	lea	dx,[attmpt1]
	lea	bx,[cdatbuf]
	mov	al,0
	mov	ah,03h			; get user, creation date/time of source file
	call	sim38			; simulate int 38 call
	ljc	cpy100er1		; be the same as the target file's class)
	mov	al,0			; read current default output class
	call	getsetclass
	lea	bx,[cdatbuf+1]
	mov	[bx],dl			; set current default output class
					; in the buffer
	lea	dx,[workbuf]
	xor	cx,cx			; normal attribute
	mos	cretfil			; create the target
	ljc	cpy100er1x
	mov	[trghndl],ax
	call	cpy101			; check for raw mode
cpy100a:
	mov	bx,[srchndl]
	mov	cx,[copysize]
	mov	ds,[copyseg]
	xor	dx,dx
	assume	ds:nothing
	mos	readfil			; read a buffer from the source
	push	es
	pop	ds
	assume	ds:ccopys
	ljc	cpy100er2
	mov	si,ax
	mov	cx,ax
	jcxz	cpy100c			; if read 0, done
	mov	bx,[trghndl]
	mov	ds,[copyseg]
	assume	ds:nothing
	xor	dx,dx
	mos	writfil			; write the buffer to the temp file
	push	es
	pop	ds
	assume	ds:ccopys
	ljc	cpy100er2
	cmp	ax,si
	ljne	cpy100er3		; disk full error
cpy100c:
	cmp	si,[copysize]
	je	cpy100a			; transfer another buffer full
	mov	bx,[srchndl]
	xor	al,al			; get source file's date and time
	mos	57h
	ljc	cpy100er2
	mov	bx,[trghndl]
	mov	al,1
	mos	57h			; set the target file's time and date
	ljc	cpy100er2
	mov	bx,[srchndl]
	mos	closfil
	ljc	cpy100er2
	or	bp,bp
	jnz	cpy100skip		; don't close the target if bp <> 0
	mov	bx,[trghndl]
	mos	closfil
	ljc	cpy100er2
	lea	dx,[workbuf]
	lea	bx,[cdatbuf]
	mov	al,1
	mov	ah,03h			; set user, creation date/time of target file
	call	sim38			; simulate int 38 call
	ljc	cpy100er2		; be the same as the target file's class)
cpy100skip:
	xor	al,al
	call	getsetact		; temporarily suspend any +except/+only
	mov	[tempseg],si		; list(s) which may be active
	xor	si,si
	mov	al,1
	call	getsetact
	lea	dx,[attmpt1]
	mov	al,1
	xor	cx,cx
	mos	43h			; insure the file can be deleted
	mos	delfil
	pushf
	push	ax
	mov	si,[tempseg]		; restore original tcbactseg
	mov	word ptr [tempseg],0
	mov	al,1
	call	getsetact
	pop	ax
	popf
	ljc	cpy100er2
	ret
cpy100er1x:				; when error creating file - must delete 1st
	lea	dx,[workbuf]
	mos	delfil
cpy100er1:
	push	ax
	lea	di,[workbuf]		; rename $$  $$ file back to original
	lea	dx,[attmpt1]
	mos	rename
	pop	ax
	jmp	copyerr
cpy100er2:
	push	ax			; save error code
	lea	dx,[attmpt1]
	mov	al,1
	xor	cx,cx
	mos	43h			; insure the file can be deleted
	mos	delfil			; attempt to delete temp file
	pop	ax
	jmp	copyerr
cpy100er3:				; disk full error
	lea	sp,[stacktop]		; reset stack since could enter from proc 72
	mov	bx,[trghndl]
	mos	closfil
	mov	al,218
	jmp	copyerr
cpy100	endp

;======================================================================
;,fs
; cpy101 - if ctbopt is true, set trghndl to raw mode
;
; in:
;
; out:
;
;,fe
;======================================================================
cpy101 proc near
	true?	[ctbopt]
	jne	cpy101a
	push	ax
	push	bx
	push	dx
	mov	bx,[trghndl]
	mov	ax,4400h
	mos	ioctrl
	xor	dh,dh
	or	dl,32			; set binary bit
	mov	ax,4401h
	mos	ioctrl
	pop	dx
	pop	bx
	pop	ax
cpy101a:
	ret
cpy101	endp


;----------------------- main code for copy command ---------------------

	assume	ds:ccopys,es:dataseg,ss:nothing
ccopy:

; must have at least one paramter

	true?	[nullparm]
	lje	badparm1

; init flags

	resflg	[assumtrg]
	setflg	[ctaopt]
	resflg	[ctbopt]
	resflg	[specsopt]
	resflg	[spectopt]
	resflg	[findplus]
	resflg	[cvopt]
	resflg	[orgtrggl]
	resflg	[trgdev]
	resflg	[srcdev]
	resflg	[crettrg]
	resflg	[ccopt]
	resflg	[movedate]
	mov	[coptcl],0
	mov	word ptr [copycnt],0
	mov	word ptr [trghndl],0
	call	setdtaaddr

; allocate the largest block possible (up to 64k).  if have to
; settle for less, round down to nearest 512 byte mutiple.
; store segment of block in copyseg and store # of bytes in copysize.
; set copyfix2 for error handling cleanup.

	mov	bx,4096
cpy36:
	mos	getmem
	call	memcheck
	jnc	cpy46
	or	bx,bx
	ljz	badparm7
	and	bx,-128
	jmp	cpy36
cpy46:
	mov	[copyseg],ax
	mov	cl,4
	shl	bx,cl
	dec	bx
	mov	[copysize],bx
	setflg	[copyfix2]

; check for and process /v switch

	lea	si,[parmbuf]
	mov	ax,'V'
	call	getoption
	jne	cpy15a
	setflg	[cvopt]
	mos	getverf
	or	al,al
	jnz	cpy15a
	setflg	[copyfix1]
	mov	al,1
	mos	setverf
cpy15a:

; check for a /c option (si still points to parmbuf).
; if find, blank out, set ccopt and record class letter in cloptcl.

	xor	cx,cx			
	mov	al,fslash
	call	scanstr
	jne	cpy15
	inc	si
	cld
	lodsb
	call	low2upper
	cmp	al,'C'
	jne	cpy15a
	mov	word ptr [si-2],2020h
	setflg	[ccopt]
	mov	[coptcl],0
	lodsb
	or	al,al
	jz	cpy15a
	mov	byte ptr [si-1],20h
	cmp	al,'-'
	jne	cpy15b
	mov	[coptcl],al
	jmp	cpy15a
cpy15b:
	call	low2upper
	cmp	al,'A'
	ljb	badparm2
	cmp	al,'Z'
	lja	badparm2
	mov	[coptcl],al
	jmp	cpy15a

; pass all options infront of the first fname

cpy15:
	lea	si,[parmbuf]
	call	passdelims		
	cmp	al,fslash
	jne	cpy6
	call	finddelim
cpy6:
	call	passdelims
cpy2:
	or	al,al
	jz	cpy77
	call	testdelims		; find a delim, a '+' or a '/'
	je	cpy77
	cmp	al,'+'
	je	cpy77
	inc	si
	mov	al,[si]
	jmp	cpy2
cpy77:
	call	passdelims
	or	al,al
	ljz	cpy3			; found end of parmbuf, no target
	cmp	al,'+'			; find a combine operator?
	je	cpy1
	cmp	al,fslash		; find an option?
	je	cpy2
	jmp	cpy4
cpy1:					; check for +,, case
	setflg	[findplus]
	inc	si
	cld
cpy7:
	lodsb
	cmp	al,' '
	je	cpy7
	dec	si
	cmp	al,','
	jne	cpy6
	cmp	byte ptr [si+1],','
	jne	cpy6
cpy4:					; si points to the start of the target
	setflg	[set_sysdate]
	call	passdelims
	or	al,al
	ljz	cpy3
	mov	bp,si			; store starting location of target
	dec	si

; trace back to find the end of the source string. stop for 
; a comma to protect the 'copy b:*.*+,, b:' case.
; then terminate the source parameter and truncate off any ':'

cpy8:
	std
	lodsb
	call	testdelims
	jne	cpy45			
	cmp	al,','			
	jne	cpy8			
cpy45:
	mov	byte ptr [si+2],0
	cmp	al,':'
	jne	cpy45a
	mov	byte ptr [si+1],0
cpy45a:

; check for /a and /b in the target

	mov	si,bp
	xor	ah,ah			
	mov	al,'A'
	call	getoption
	jne	cpy9
	setflg	[ctaopt]
	resflg	[ctbopt]
	setflg	[spectopt]
cpy9:
	mov	al,'B'
	call	getoption
	jne	cpy11
	setflg	[ctbopt]
	resflg	[ctaopt]
	setflg	[spectopt]
cpy11:

; should be no remaining switch parameters at this point

	mov	ah,1
	call	getoption
	lje	badparm2
	mov	si,bp

; once find the target and remove any option should only 
; be one parameter

	call	finddelim		
	call	passdelims		
	or	al,al
	ljnz	badparm6

; copy the target into attmpt1

	mov	si,bp
	mov	di,offset attmpt1
	xor	cx,cx
	call	copystr

; scan back from tail, trimming off all trailing whitespace

	mov	si,offset attmpt1
	call	findend
	dec	si
	std
cpy11d:
	lodsb
	cmp	al,09h
	je	cpy11d1
	cmp	al,' '
	jne	cpy11c
cpy11d1:
	mov	byte ptr [si+1],0
	jmp	short cpy11d
cpy11c:

; if the target ends with a ':', measure its length.
; if != 2 chars, can't be a drive spec so trim off the ':'

	mov	si,offset attmpt1
	call	findend
	dec	si
cpy11b:
	std
	lodsb
	call	testdelims
	je	cpy11b
	inc	si
	cmp	byte ptr [si],':'
	jne	cpy11a
	mov	cx,si
	sub	cx,offset [attmpt1]
	cmp	cx,1
	je	cpy11a
	mov	byte ptr [si],0
cpy11a:

; form the string into a full d\path\fname.ext

	mov	si,offset attmpt1
	call	fullform		
	jnc	cpy5
	or	al,al
	ljz	badparm5
	jmp	badparm4

; if no target, build one, using the default drive

cpy3:
	setflg	[assumtrg]
	lea	si,[attmpt1]
	xor	al,al
	call	writedrvpth
	lea	si,[attmpt1]
	call	findend
	mov	di,si
	call	addstars
	jmp	cpy44

; test the original target for globals.

cpy5:
	mov	si,bp
	call	parsefn
	cmp	bl,1
	jne	cpy44
	setflg	[orgtrggl]
cpy44:

; now have fully formed target in attmpt1.
; test for globals in the derived target.

	resflg	[trgglbl]		
	lea	si,[attmpt1]
	call	parsefn			
	cmp	bl,1			
	jne	cpy10
	setflg	[trgglbl]
cpy10:

; read the target drive for use with calls to getsetclass
; (lansat needs the drive #)

	mov	al,[attmpt1]
	sub	al,('A'-1)
	mov	[targdrv],al

; read current default output class and record for later recovery

	xor	al,al			
	call	getsetclass		
	mov	[origclass],dl		

; save a copy of the original target in attmpt2 for 
; later restoration

	lea	si,[attmpt1]
	lea	di,[attmpt2]
	xor	cx,cx
	call	copystr

; when the target is not assumed, and it contains a global 
; spec, presume to be in hold first mode until find otherwise

	mov	al,[assumtrg]
	not	al
	and	al,[orgtrggl]
	mov	[holdfrst],al

; prepare to enter loop

	resflg	[srconce]
	resflg	[srcglbl]
	resflg	[existrg]
cpy38:
	setflg	[csaopt]
	resflg	[csbopt]
	resflg	[hfmastr]
	resflg	[skipform]
	resflg	[setskip]
	lea	si,[parmbuf]
	mov	[srcpntr],si
cpy12:					; normal recycle point
	true?	[srcglbl]
	jne	cpy13
	mos	fndnext
	ljnc	cpy32
	true?	[holdfrst]		; ending point for hold first name mode
	lje	cpy21
	resflg	[srcglbl]
cpy13:					; recycle to here after each source file name
	mov	si,[srcpntr]		; when in hold first name mode
	jmp	cpy14
cpy16:
	true?	[srconce]
	ljne	badparm1
	true?	[holdfrst]		; when find end of source buffer, if in hold
	lje	cpy38			; first name mode, recycle to cpy38
	jmp	cpy21
cpy17:
	true?	[srconce]
	ljne	badparm6
	inc	si
	cld
cpy30:
	lodsb				; check for +,, case
	cmp	al,' '
	je	cpy30
	dec	si
	cmp	al,','
	jne	cpy14
	cmp	byte ptr [si+1],','
	jne	cpy14
	mov	byte ptr [copycnt],1
	jmp	cpy21
cpy14:
	call	cpy20			; check for options
	ljc	badparm2
	or	al,al
	ljz	cpy16
	cmp	al,'+'
	lje	cpy17
	setflg	[srconce]
	mov	bp,si			; save start of present file name
	call	parsefn
	ljc	badparm4
	mov	[srcpntr],si		; update srcpntr for next cycle
	mov	cx,si
	sub	cx,bp			; calc length of file name and copy
	mov	si,bp			; into workbuf
	lea	di,[workbuf]
	call	copystr
	xor	al,al
	stosb
	lea	si,[workbuf]		; form the full d\path\fname.ext for the
	call	fullform		; source file spec and use parsefn to set
	jnc	cpy25			; for the source file spec
	or	al,al
	ljz	badparm5
	jmp	badparm4
cpy25:
	cmp	bl,1			; check for drive only case in source file spec
	lje	cpy21
	call	parsefn			; bl=1 if there are any globals
	mov	al,[holdfrst]		; when in hold first name mode and the source
	and	al,[hfmastr]		; is not the first, jmp to cpy39
	ljnz	cpy39
	lea	si,[workbuf]
	lea	di,[workbuf2]		; save a copy of the original in workbuf2
	xor	cx,cx			; for later restoration
	call	copystr
	resflg	[srcglbl]
	cmp	bl,1			; are there globals in the source?
	lje	cpy40
	true?	[hfmastr]		; if no globals in the source and its the first
	lje	cpy19			; source file spec, reset holdfrst
	resflg	[holdfrst]
	jmp	cpy19
cpy40:
	setflg	[srcglbl]		; mark the source file spec as global
	lea	dx,[workbuf]
	xor	cx,cx
	mos	fndfrst
	ljc	cpy21			; 0 files copied, done
	jmp	cpy31
cpy32:					; enter here after find next matching file
	lea	si,[workbuf2]		; to restore workbuf as it was before the
	lea	di,[workbuf]		; last mods.
	xor	cx,cx
	call	copystr
	true?	[holdfrst]
	jne	cpy31
	mov	si,[srcpntr]		; if did the find next and entered cpy32 due
	call	cpy20			; to a recycle from hold first name mode, must
	call	parsefn			; update srcpntr as if parsing the first source
	mov	[srcpntr],si		; again.  also want to use cpy20 to pick up
	call	cpy20			; any /a and /b option again.
cpy31:
	lea	si,[workbuf]		; trim off the file spec and copy in the one
	call	findfname		; from the dta
	mov	di,si
	mov	si,[dtaaddr+30]
	xor	cx,cx
	call	copystr
	mov	al,[hfmastr]		; if in hold first name mode and it is the
	not	al			; first file spec then save a copy of the
	and	al,[holdfrst]		; file name in hfname for later translation
	jz	cpy19			; onto remaining source file specs
	mov	si,[dtaaddr+30]
	mov	cx,11
	lea	di,[hfname]
	call	copystr
cpy19:
	mov	si,[srcpntr]
	call	cpy20			; check for options
	ljc	badparm2
	cmp	al,'+'
	jne	cpy18			; if find a + sign, and
	true?	[trgglbl]
	jne	cpy34
	true?	[assumtrg]
	je	cpy34			; if the derived target has globals and
	true?	[orgtrggl]		; if the target was not assumed, did the
	je	cpy18			; original target have globals?  if no, the
					; want to set setskip true
					; (ie copy b:*.* + ,, b: )
cpy34:
	setflg	[setskip]
cpy18:
	true?	[skipform]
	lje	cpy22
	mov	al,[trgglbl]
	not	al
	and	al,[srcglbl]
	or	[setskip],al		; if sg and not tg then setskip, else leave
					; as is (setskip true means make only one tg)
	true?	[trgglbl]
	je	cpy33
	jmp	cpy23
cpy39:
	lea	si,[workbuf]
	call	fullform		; form the string into a full d\path\fname.ext
	jnc	cpy42
	or	al,al
	ljz	badparm5
	jmp	badparm4
cpy42:
	lea	si,[workbuf]		; when in hold first name mode and have found
	call	findfname		; a source file spec other than the first
	mov	bp,si			; parse the found spec into cpyptt as a pattern
	call	parse			; and use the original fname.ext (held from the
	lea	si,[prsfcb+1]		; most recent first file spec) as the source.
	lea	di,[cpyptt]		; the destination for the call to substwild wil
	mov	bx,di			; be the starting point in workbuf of the file
	mov	cx,11			; name.
	call	copystr
	lea	si,[workbuf]
	lea	si,[hfname]
	mov	di,bp
	call	substwild
	jmp	cpy22

; form target file spec in attmpt1 using name in workbuf as source and
; original contents of attmpt1 (parsed into cpyptt) as the wild card template

cpy33:
	lea	si,[attmpt2]
	lea	di,[attmpt1]
	xor	cx,cx			; restore the original target string
	call	copystr			; into attmpt1
	lea	si,[attmpt1]
	call	findfname		; find start of file name for second parm
	mov	bp,si			; and record in name2
	call	parse
	lea	si,[prsfcb+1]
	lea	di,[cpyptt]		; save the fcb fname.ext as the template.
	mov	cx,11			; (this will convert *.* to ????????.???)
	call	copystr
	lea	si,[workbuf]		; find start of file name for 1st parameter
	call	findfname
	mov	di,bp			; set di to start of destination filespec
	lea	bx,[cpyptt]		; wildcard pattern
	call	substwild		; derive the destination name from the source
					; name and the wildcard pattern
cpy23:
	call	cpy72			; close target file (if one exists)
	lea	si,[attmpt1]
	call	findlen
	mov	dx,cx
	lea	di,[workbuf]
	push	si
	mov	si,di
	call	findlen
	pop	si
	cmp	cx,dx
	jne	cpy99
	mov	cx,dx
	xor	dx,dx
	call	strcompare
	je	cpy51
cpy99:
	call	pathchek		; make sure they are the same
	je	cpy51			; jump if pointing to same file
	setflg	[crettrg]		; set flag so target is created after
	jmp	cpy22			; find source file
cpy51:
	cmp	word ptr [copycnt],0
	je	cpy48
	true?	[assumtrg]
	lje	cpy66			; skip copying altogether
	mov	al,217			; content of destination lost before copy
	call	reporterror
	jmp	cpy66
cpy48:
	true?	[findplus]		; if not combining files, then must
	lje	cpy50			; report an error 'Cannot copy file onto itself
	true?	[srcglbl]
	jne	cpy49
	true?	[trgglbl]
	ljne	cpy50
cpy49:					; source and target names are the same
					; if not /c option, error
	true?	[ccopt]
	je	cpy49a
	call	setdtaaddr		; check if file can be opened
	push	ax
	push	cx
	push	dx
	xor	cx,cx
	lea	dx,[workbuf]		; where the file's name lives
	mos	fndfrst
	pop	dx
	pop	cx
	pop	ax
	mov	al,2
	jc	cpy49x1			; if file could not be found to copy
	mov	al,216			; cannot copy file onto itself
cpy49x1:
	jmp	copyerr
cpy49a:
	mov	dl,[coptcl]
	or	dl,dl			; if coptcl=0, leave default
	je	cpy49b			; output class as is
	cmp	dl,'-'
	jne	cpy49c
	xor	dl,dl			; if /c- was found, set default output
					; class to 0 for space
cpy49c:
	mov	al,1
	call	getsetclass		; change the default output class
	setflg	[copyfix3]
cpy49b:
	true?	[srcglbl]		; if a global source filespec, must build
	je	cpy49d			; a list of file names
	call	cpy76
	call	dispeol
	push	bp
	xor	bp,bp
	call	cpy100			; convert the file named in workbuf
	pop	bp
	mov	[copycnt],1
	resflg	[crettrg]
	jmp	cpy21
cpy49d:					; build name list in main memory block
	call	setdtaaddr		; and then relocate it to the top and modify
					; copysize.  this will enable small tasks to
					; do global class changes without running
	lea	dx,[workbuf2]		; out of memory.
	xor	cx,cx
	mos	fndfrst
	ljc	copyerr
	xor	di,di
	mov	bp,[copysize]
	mov	es,[copyseg]
	assume	es:nothing
	dec	bp			; reserve one byte for the ending 0
cpy49g:
	mov	si,dtaaddr+30
	call	findlen			; predict memory needed to add next string
	inc	cx			; account for ending 0
	add	cx,di
	cmp	cx,bp
	lja	cpy49h			; insufficient memory
	xor	cx,cx
	call	copystr			; copy the name into the list
	mos	fndnext
	jnc	cpy49g
	mov	byte ptr es:[di],0	; mark end of list
	inc	bp
	mov	si,di			; relocate the list to the top of the
	mov	cx,di			; memory block
	inc	cx
	mov	di,bp
	sub	bp,cx			; mod copysize to protect the list
	std
	mov	bx,ds
	push	es
	pop	ds
	assume	ds:nothing
	rep	movsb
	mov	ds,bx
	assume	ds:ccopys
	mov	es,bx
	assume	es:dataseg
	mov	[copysize],bp
	lea	si,[workbuf]
	call	findfname
	mov	dx,si			; save end of source path in dx
	xor	bx,bx
	inc	bp
cpy49i:					; get each name from the list and form
					; the source d\path\fname.ext string
	mov	ds,[copyseg]
	assume	ds:nothing
	mov	si,bp			; use ds:si to address file name list
	cmp	byte ptr [si],0
	je	cpy49j			; found end of list marker
	mov	di,dx			; es:di address end of source path string
	xor	cx,cx			; in workbuf
	call	copystr
	mov	bp,si
	push	es
	pop	ds
	assume	ds:ccopys
	push	bx
	push	dx
	push	bp
	call	cpy76
	call	dispeol
	xor	bp,bp
	call	cpy100			; do the file xfer
	pop	bp
	pop	dx
	pop	bx
	inc	bx
	jmp	cpy49i
cpy49j:
	push	es
	pop	ds
	resflg	[crettrg]
	mov	[copycnt],bx
	jmp	cpy21
cpy49h:					; insufficient memory
	push	ds
	pop	es
	mov	ax,8
	jmp	copyerr
cpy50:					; open the target file for concatenation
	true?	[ccopt]			; using /c option?
	ljne	cpy50b
	mov	dl,[coptcl]
	or	dl,dl			; if coptcl=0, leave default
	je	cpy50d			; output class as is
	cmp	dl,'-'
	jne	cpy50c
	xor	dl,dl			; if /c- was found, set default output
cpy50c:
	mov	al,1
	call	getsetclass		; change the default output class
cpy50d:
	push	bp
	mov	bp,1			; bp=1 will leave the target file open
	call	cpy100
	pop	bp
	lea	di,[attmpt1]		; restore attmpt1 from workbuf
	lea	si,[workbuf]
	xor	cx,cx
	call	copystr
	mov	bx,[trghndl]
	xor	cx,cx
	xor	dx,dx
	xor	al,al			; reset file pointer to start
	mos	lseek
	ljc	copyerr
	mov	ax,[trghndl]
	call	cpy76
	jmp	cpy52
cpy50b:
	lea	dx,[attmpt1]
	call	cpy76			; display file name (from workbuf)
	push	cx
	mov	ax,4300h		; if file is read only, can't get open with
	int	21h			; write access.  if doing a concatonating
	jc	geterr			; type of copy, need write access.  if trying
	test	cx,1			; to concat to a ro file, should get error
	jnz	getro
	mov	al,01000010b		; inherit, deny none, read/write access
	jmp	getxx
getro:
	mov	al,00100000b		; inherit, deny write, read access
getxx:
	pop	cx
	true?	[findplus]
	je	getxx1
	xor	al,al
getxx1:
	mos	openfil
	jnc	cpy52
geterr:
	mov	cx,2
	call	dispblanks
	mov	al,2			; file not found error
	jmp	copyerr
cpy52:
	setflg	[existrg]
	call	dispeol
	mov	[trghndl],ax
	call	cpy101			; check for raw mode
	true?	[ctaopt]
	je	cpy53
	mov	bx,ax			; handle in bx for lseek call
	xor	cx,cx
	xor	dx,dx
	mov	al,2
	mos	lseek			; set r/w pointer at end of target file
	jmp	cpy56_020
cpy53:
	resflg	[lastread]

; this section of code deals with the special case where a user has
; specified only a source filename in a copy.	for example:
;
;	copy [/b] filename+,,
;
; the above construct means to rewrite the existing file under the
; same name.  if the /b option is not used, the command results in
; a file truncated at the first dos eof character encountered. (0x1a).
; if the /b option is specified, the entire file is copied over itself.
; this particular function provides the user with a way to truncate
; ascii files as well as a crude method of performing a "touch" on
; the file to update the time/date stamp.

	mov	word ptr sourceptr,0
	mov	word ptr sourceptr[2],0
	mov	word ptr targptr,0
	mov	word ptr targptr[2],0
cpy56:
	mov	bx,trghndl
	mov	cx,copysize
	push	ds			; save ds for a sec.
	mov	ds,copyseg		; ds=>data segment for copying.
	xor	dx,dx			; ds:dx=>buffer to be read to
	mos	readfil			; read the file.
	pop	ds			; recover ds.
	ljc	copyerr			; if an error on the file read....
	cmp	ax,copysize		; was the read complete?
	je	cpx1			; if so, not last read yet.
	setflg	lastread		; set the last read flag.
cpx1:

; update the source file pointer with the amount of data read.

	add	word ptr sourceptr,ax
	adc	word ptr sourceptr[2],0

; is this a binary file we're copying?  (i.e., did the user specify
; the /b option?  if so, skip past the scan for the eof character.

	true?	csbopt			; /b option specified?
	je	cpy56_010		; if so, forget the scan for ctrl-z.

; scan through the data in the copy buffer for a ctrl-z character.

	push	ax
	push	es

	xor	di,di			; es:di=> at copy segment.
	mov	es,copyseg
	cld				; scan forward
	mov	cx,ax			; scan for length of data read.
	mov	al,1ah			; ctrl-z
	repne	scasb

	pop	es
	pop	ax

	jne	cpy56_010		; if not found, copy everything.
	mov	ax,di			; only copy (di) chars. (including ctrl-z)
	setflg	lastread		; don't read any more of the file either.

; get the current pointer to the "target" file and write the data
; to it.

cpy56_010:
	push	ax			; save the length to write to file.
	xor	al,al			; seek relative to file beginning.
	mov	bx,trghndl		; get file handle.
	mov	dx,word ptr targptr	; get current "target" pointer.
	mov	cx,word ptr targptr[2]
	mos	lseek			; position to "target" location.
	pop	ax			; get length of last read.
	add	word ptr targptr,ax	; move our pointer up.
	adc	word ptr targptr[2],0

; now, we can write to the file at the "target" location.

	mov	bx,trghndl		; the handle of the file.
	mov	cx,ax			; the amount read above.
	push	ds			; save ds.
	mov	ds,copyseg
	xor	dx,dx			; ds:dx => data buffer.
	mos	writfil			; write to the file.
	pop	ds			; recover ds, again.

; the file section has been written.  any more to write?

	true?	lastread		; end of file yet?
	je	cpx2			; if so, that's it.

; yes, there's more to write.  Position the file pointer at
; the location specified by the "source" pointer.

	xor	al,al			; seek relative to file beginning.
	mov	bx,trghndl		; get file handle.
	mov	dx,word ptr sourceptr	; get current "source" pointer.
	mov	cx,word ptr sourceptr[2]
	mos	lseek			; position to "source" location.
	jmp	cpy56

; the read is done.  truncate the file at the last position
; written and exit out.

cpx2:
	mov	bx,trghndl
	xor	cx,cx			; write 0 bytes.
	mos	writfil
cpy56_020:
	setflg	existrg			; indicates target file to close.
	setflg	skipform		; process next file name.
	jmp	cpy66
cpy22:
	true?	[setskip]
	jne	cpy35
	setflg	[skipform]
cpy35:
	resflg	[movedate]
	true?	[findplus]
	je	cpy58
	true?	[srcglbl]
	jne	cpy57
	true?	[trgglbl]
	jne	cpy58
cpy57:
	setflg	[movedate]
	true?	[specsopt]
	je	cpy58
	setflg	[csbopt]
	resflg	[csaopt]
cpy58:
	true?	[spectopt]
	je	cpy60
	mov	al,[csbopt]		; if no specific target options, make them
	mov	[ctbopt],al		; same as the source options
	mov	al,[csaopt]
	mov	[ctaopt],al
cpy60:
	lea	si,[workbuf]
	call	findend
	dec	si
	cmp	byte ptr [si],':'
	jne	cpy59
	mov	byte ptr [si],0
cpy59:
	true?	[skipform]		; if skipform check for a string match
	jne	cpy78
	lea	si,[attmpt1]
	call	findlen
	mov	dx,cx
	lea	di,[workbuf]
	push	si
	mov	si,di
	call	findlen
	pop	si
	cmp	cx,dx
	jne	cpy78
	mov	cx,dx
	xor	dx,dx
	call	strcompare
	jne	cpy78
	true?	[assumtrg]		; if a match, with an assumed target, skip
	lje	cpy66
	mov	al,217			; content of destination lost before copy
	call	reporterror
	jmp	cpy66
cpy78:
	lea	dx,[workbuf]		; open the source file
	mov	al,01000000b		; sjc - inherit, deny none, read access
	true?	[findplus]
	je	getxx2
	xor	al,al
getxx2:
	mos	openfil
	ljc	cpy67
	setflg	[copyfix4]
	mov	[srchndl],ax
	lea	dx,[workbuf]		; path of source file
	lea	bx,[cdatbuf]
	mov	al,0
	mov	ah,03h
	call	sim38			; sah simulate int 38 call
	true?	[ccopt]			; /c option used?
	jne	cpy78b
	mov	dl,[coptcl]
	or	dl,dl			; if coptcl=0, leave default
	je	cpy78c			; output class as is
	cmp	dl,'-'
	jne	notspace
	xor	dl,dl			; if /c- was found, set default output
	jmp	notspace		; class to 0 for space
cpy78c:
	mov	al,0			; put current class in cdatbuf
	call	getsetclass
	jmp	cpy78d
notspace:
	mov	al,1
	call	getsetclass		; change the default output class
cpy78d:
	lea	bx,[cdatbuf+1]
	mov	[bx],dl			; update class in cdatbuf
	setflg	[copyfix3]
	jmp	cpy78a
cpy78b:
	mov	bx,[srchndl]
	xor	al,al
	mos	ioctrl
	test	dx,80h			; see if the source is a device
	jnz	cpy78a			; if yes, leave class as is
	lea	bx,[cdatbuf+1]		; address class of source
	mov	dl,[bx]
	mov	al,1
	call	getsetclass		; set output class to be same as the source
	setflg	[copyfix3]
cpy78a:
	true?	[crettrg]
	ljne	cpy84
	resflg	[crettrg]
	lea	si,[attmpt1]
	lea	di,[trgbuf]
	xor	cx,cx
	call	copystr			; save a copy the the target name for func 83
	lea	dx,[attmpt1]
	xor	cx,cx
	mov	word ptr [trghndl],0
	setflg	[copyfix5]

; the following code was added to fix copying to and from the pipe device
; mjs  8/10/87

	mov	ax,3d42h		; open, deny none, read/write access
	int	21h
	jc	cpp1			; if error, create the file
	mov	bx,ax
	mov	ax,4400h		; see if the target is a device
	int	21h
	test	dx,80h
	mov	ax,bx			; handle in ax, just like return from 3c call
	jnz	cpp2
	mov	ax,4000h		; truncate the file
	xor	cx,cx
	push	bx
	int	21h
	pop	ax
	jmp	cpp2			; handle in ax, just like return from 3c call
cpp1:
	lea	dx,[attmpt1]
	xor	cx,cx
	mos	cretfil			; create the target file
	ljc	copyerr
cpp2:
	mov	[trghndl],ax
	setflg	[existrg]
	mov	bx,ax
	xor	al,al
	mos	ioctrl
	test	dx,80h			; see if the target is a device
	jz	cpy84a
	setflg	[trgdev]
	true?	[spectopt]
	je	cpy84a
	setflg	[ctaopt]
	resflg	[ctbopt]
	jmp	cpy84
cpy84a:
	call	cpy101			; check for raw mode
cpy84:
	true?	[setskip]
	jne	cpy84b
	mov	word ptr [copycnt],1
	jmp	cpy82
cpy84b:
	mov	al,[holdfrst]		; don't increment CopyCnt when in hold first
	and	al,[hfmastr]		; name mode and not on the first name
	jnz	cpy82
	inc	word ptr [copycnt]
cpy82:
	xor	al,al
	mov	bx,[srchndl]
	mos	ioctrl
	test	dx,80h			; see if the source is a device
	jz	cpy61
	setflg	[srcdev]
	resflg	[movedate]
	true?	[specsopt]
	je	cpy79
	setflg	[csaopt]
	resflg	[csbopt]
	jmp	cpy80
cpy79:
	true?	[csbopt]		; see if a /b was spec'd for a device
	jne	cpy80
	mov	al,215			; cannot do binary reads from a device
	jmp	copyerr
cpy67:
	true?	[holdfrst]
	lje	cpy66			; skip this copy cycle
	true?	[findplus]
	lje	cpy66
	push	ax
	call	cpy76
	mov	cx,2
	call	dispblanks
	pop	ax
	jmp	copyerr
cpy61:
	true?	[trgdev]		; is the target a device?
	jne	cpy80a
	xor	al,al			; if its the console, skip displaying fname
	mov	bx,[trghndl]
	mos	ioctrl
	test	dx,3
	jnz	cpy80
cpy80a:
	call	cpy76			; display the file name from workbuf
	call	dispeol			; (only when source and target not devices)
cpy80:
	true?	[movedate]
	jne	cpy62
	mov	bx,[srchndl]
	xor	al,al			; get source file's date and time
	mos	57h
	mov	[newdate],dx
	mov	[newtime],cx
	jmp	short cpy62a
cpy62:
	true?	[set_sysdate]
	jne	cpy62a

; get the current system date and time to be written out to the
; target file.

	call	make_file_date
	mov	[newdate], dx
	mov	[newtime], cx
	setflg	[movedate]
	resflg	[set_sysdate]
cpy62a:
	resflg	[lastread]
cpy63:
	mov	cx,[copysize]		; number of bytes to read
	mov	bx,[srchndl]
	xor	dx,dx
	mov	ds,[copyseg]
	mos	readfil
	push	es
	pop	ds
	ljc	copyerr
	cmp	ax,[copysize]		; if requested <> returned count, eof
	je	cpy64
	true?	[srcdev]		; when the source is a device, disregard a
	je	cpy64			; difference between requested and returned
	setflg	[lastread]		; counts, else mark as the last read cycle
cpy64:
	mov	bx,ax			; put returned count in bx
	true?	[csaopt]
	ljne	cpy65
	xor	di,di
	mov	cx,ax			; put returned count in cx as a scan limit
	mov	bx,ax			; and save a copy for later restoration
	cld
	mov	ax,[copyseg]
	mov	es,ax
	mov	al,1ah
	repne	scasb			; scan for a control z code
	push	ds
	pop	es
	ljne	cpy65
	or	di,di
	ljz	cpy81			; skip when offset of 1a is 0
	dec	di			; adjust di
	mov	bx,di
	setflg	[lastread]
cpy65:
	mov	cx,bx
	mov	bp,cx
	mov	bx,[trghndl]
	mov	ds,[copyseg]
	xor	dx,dx
	mos	writfil
	push	es
	pop	ds
	ljc	copyerr
	true?	[trgdev]
	je	cpy85			; skip comparison if target is a device
	cmp	ax,bp
	jne	cpy75			; disk full error
cpy85:
	true?	[lastread]
	ljne	cpy63
cpy81:
	mov	bx,[srchndl]
	mos	closfil
	resflg	[copyfix4]
cpy66:
	setflg	[hfmastr]		; signal that the first file spec has just
					; been processed
	true?	[holdfrst]
	lje	cpy13			; if in hold first name mode, recycle to cpy13
	jmp	cpy12			; normal recycle point
cpy75:					; disk full error
	lea	sp,[stacktop]		; reset stack since could enter from proc 72
	setflg	[copyfix5]
	mov	al,218
	jmp	copyerr

;--------------------------- copy error -------------------------

copyerr:
	lea	sp,[stacktop]
	call	reporterror
	cmp	byte ptr [copycnt],0
	je	cpy21
	dec	byte ptr [copycnt]
	jmp	cpy21a
cpy21:					; done entry point
	resflg	[copyfix5]
cpy21a:
	call	cpy72
	true?	[copyfix1]
	jne	cpy68
	resflg	[copyfix1]
	xor	al,al
	mos	setverf			; return verify state to off
cpy68:
	true?	[copyfix2]
	jne	cpy70
	resflg	[copyfix2]
	mov	es,[copyseg]
	mos	freemem
	call	memcheck
	push	ds
	pop	es
cpy70:
	true?	[copyfix3]
	jne	cpy70a
	mov	dl,[origclass]
	mov	al,1
	call	getsetclass
	resflg	[copyfix3]
cpy70a:
	true?	[copyfix4]
	jne	cpy70b
	mov	bx,[srchndl]
	mos	closfil
	resflg	[copyfix4]
cpy70b:
	true?	[copyfix5]		; is there a directory entry to be
	jne	cpy70c			; deleted because of a full disk?
	resflg	[copyfix5]
	mov	bx,[trghndl]
	or	bx,bx
	jz	cpy70d			; close the file if got that far
	mos	closfil
cpy70d:
	lea	dx,[attmpt1]
	mos	delfil
cpy70c:
	mov	cx,4
	call	dispblanks
	lea	dx,cs:[copymsg1]
	call	csdispstr
	mov	ax,[copycnt]
	xor	dx,dx
	lea	bx,[workbuf+4]
	mov	cx,5
	call	bin2dec			; convert copycnt to a string and display
	mov	byte ptr [workbuf+5],0
	lea	dx,[workbuf]
	call	dispstr
	call	dispeol
	jmp	cmfl

copymsg1 db	'Files Copied:      ',0	;@@xlat

;======================================================================
;,fs
; pathchek 
;
; used to insure that the source and target pathnames are not pointing
; to the same file.  this is done by doing a find first with both the
; source and target pathname and then comparing the data provided by
; the find.
;
; in:
;
; out:	zf = 1 same file
;	zf = 0 different files
;
;,fe
;======================================================================
pathchek proc	near
	push	ax			; save
	push	bx			;  the
	push	cx			;   prior
	push	dx			;    environment
	push	si
	push	di
	push	bp
	push	ds
	push	es
	mov	ah, getdta		; get the current dta address
	int	021h			; call the os
	pop	dx			; retrieve es
	push	dx			; and save it again
	push	es			; save the dta segment
	push	bx			; and the dta offset
	mov	es, dx			; restore es to normal
	mov	ah, setdta		; set dta request
	lea	dx, srcentry		; point to the source entry
	int	021h			; call the os
	mov	ah, fndfrst		; find first directory entry
	mov	cx, 0ffffh		; any attribute will do
	lea	dx, workbuf		; point to the first path
	int	021h			; call the os
	jc	pchkerr			; must not be the same if bad fi
	mov	ah, setdta		; set dta request
	lea	dx, trgentry		; point to the target entry
	int	021h			; call the os
	mov	ah, fndfrst		; find first directory entry
	mov	cx, 0ffffh		; any attribute will do
	lea	dx, attmpt1		; point to the target path
	int	021h			; call the os
	jc	pchkerr			; must not be the same if bad fi
	lea	si, srcentry+12		; point to the identifing data
	lea	di, trgentry+12		; point to the targets data
	mov	cx, 18			; check 18 bytes of data
	repe	cmpsb			; keep looking if equal
	jne	pchkerr			; jump if not the same
pchk10:
	cmp	byte ptr [si], 0	; is this the end of the string
	je	pchkexit		; time to quit if yes
	cmpsb				; is the data still the same
	je	pchk10			; keep looking if still the same

pchkerr:
	cmp	si, di			; make sure not equal is set

pchkexit:
	pop	dx			; retrieve dta offset
	pop	es			; and the segment
	pushf				; save the zero/equal flag
	mov	ah, setdta		; set dta request
	int	021h			; ask os to restore dta location
	popf				; restore the return status
	pop	es			; restore
	pop	ds			;  the
	pop	bp			;   original
	pop	di			;    environment
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret				; return to caller
pathchek endp

;=========================== date ========================

	assume	ds:dataseg,es:dataseg

datmsg1 db	' is the current date   ',0  ;@@xlat
datmsg2 db	'New date is  ($        ',0  ;@@xlat
datmsg3 db	cr,lf,'Date not valid    ',0  ;@@xlat
datset	db	'.-/',0
datyear db	'year '			;@@xlat
datmon	db	'month'			;@@xlat
datday	db	'day  '			;@@xlat

cda3 proc
	call	dispchar		; used to display the letter pairs
	call	dispchar		; mm, dd and yy
	mov	dl,bl			; bl holds the separator or ending )
	call	dispchar
	ret
cda3 endp

cda5 proc
	mov	al,byte ptr [si-1]	; check for a proper separator on input
	push	si
	lea	si,[datset]
	call	testset
	pop	si
	ret
cda5 endp

cda14 proc				; mod to full year amount
	cmp	ax,100
	ja	cda6
	add	ax,1900
cda6:
	ret
cda14 endp

cdacoun proc
	lea	dx,[workbuf]
	xor	al,al			; get country data for current country
	mos	getcoun
	mov	ax,word ptr [workbuf]	; get date format code
	mov	bp,ax			; save a copy for later
	ret
cdacoun endp

cda9 proc
	true?	[nullparm]		; date entered after command?
	jz	cda16
	call	cdacoun			; sah must get country information (set bp)
	lea	si,[parmbuf]
	jmp	cda17
cda16:
	call	dispdate
	lea	dx,cmd:[datmsg1]	; show the current date
	call	csdispstr
cda7:
	call	dispeol			; prompt for new date
	lea	dx,cmd:[datmsg2]
	call	csdispmsg
	call	cdacoun			; sah get country information (optimized)
	mov	bl,byte ptr [workbuf+11]; get date separator char
	or	ax,ax
	jnz	cda1
	mov	dl,[datmon]		; usa format  mm-dd-yy
	call	cda3
	mov	dl,[datday]
	call	cda3
	jmp	cda2
cda1:
	cmp	ax,1			; european format  dd-mm-yy
	jne	cda11
	mov	dl,[datday]
	call	cda3
	mov	dl,[datmon]
	call	cda3
	jmp	cda2
cda11:					; swedish (japan too?) format yy-mm
	mov	dl,[datyear]
	call	cda3
	mov	dl,[datmon]
	call	cda3
	mov	dl,[datday]
	jmp	cda12
cda2:
	mov	dl,[datyear]
cda12:
	mov	bl,')'
	call	cda3
	mov	dl,':'
	call	dispchar
	mov	dl,' '
	call	dispchar
	mov	bx,stdin
	mov	cx,128
	lea	dx,[workbuf]
	mos	readfil			; get an input line from the console
	mov	cx,128
	mov	al,cr
	lea	si,[workbuf]
	call	scanstr
	mov	byte ptr [si],0		; convert workbuf to an asciiz string
	lea	si,[workbuf]
cda17:					; if flow in, si points to workbuf, else
					; points to parmbuf
	call	passdelims
	cmp	byte ptr [si],0
	lje	cda10			; null line
	call	str2num			; convert first number
	ljc	cda4
	cmp	bp,2			; test for swedish (japan?) format
	lje	cda13
	or	ah,ah
	jnz	cda4
	mov	dh,al
	call	cda5			; test separator
	jne	cda4
	call	str2num			; convert second number
	jc	cda4
	or	ah,ah
	jnz	cda4
	mov	dl,al
	call	cda5			; test separator
	jne	cda4
	or	bp,bp			; test date format code in bp
	jz	cda8			; 0 for usa format
	xchg	dl,dh			; mod for european format
cda8:
	call	str2num			; convert year
	jc	cda4
	call	cda14			; mod to full year amount
	mov	cx,ax
cda15:
	mos	setdate			; set the new date
	or	al,al
	ljz	cda10
cda4:
	lea	dx,cmd:[datmsg3]	; report invalid date
	call	csdispstr
	jmp	cda7
cda10:
	ret
cda13:					; swedish (japan?) format
	call	cda14			; mod to full year amount
	mov	cx,ax
	call	str2num			; convert month
	ljc	cda4
	or	ah,ah
	jnz	cda4
	mov	dh,al
	call	cda5			; test separator
	jne	cda4
	call	str2num			; convert day
	jc	cda4
	or	ah,ah
	jnz	cda4
	mov	dl,al
	jmp	cda15
cda9 endp

cdate:
	call	cda9
	jmp	cmfl

;=========================== dir ========================

	assume	ds:cdirs

dirmsg1 db	' DIRECTORY FOR   ',0	;@@xlat
dtotmsg db	' BYTES ',0		;@@xlat
dfilmsg db	' FILES ',0		;@@xlat
dbytmsg db	' BYTES REMAINING',cr,lf,0  ;@@xlat

; internal subroutines for dir

cdr28 proc
	push	si
	true?	[dpopt]			; manage end of line for file display
	jne	cdr32
	inc	byte ptr [dlines]
	cmp	byte ptr [dlines],23
	jne	cdr32
	mov	byte ptr [dlines],0	; if /p option and 23 lines, put up
	call	pausesubr		; pause message and wait for a key
	call	dispeol
cdr32:
	pop	si
	ret
cdr28 endp

; display a file name and extension

cdr34 proc
	lea	di,[workbuf]
	mov	cx,40
	mov	ax,2020h		; init workbuf to blanks
	cld
	rep	stosw

	lea	di,[workbuf]
	true?	[dwopt]
	jne	cdr34a
	mov	bx,dtaaddr+19		; check for subdir attribute
	test	byte ptr [bx],10h
	jz	cdr34a
	mov	al,'['
	stosb

cdr34a:
	mov	si,dtaaddr+8		; offset of file name
	cmp	byte ptr [si],'.'	; check for . and .. subdir names
	jne	cdr40
	mov	al,'.'
	stosb
	mov	cx,11
	cmp	byte ptr [si+1],'.'
	jne	cdr44
	stosb
	jmp	cdr44
cdr40:
	mov	si,dtaaddr+8
	mov	cx,4
	rep	movsw			; xfer the file name into workbuf
	lea	di,[workbuf+9]
	true?	[dwopt]
	je	cdr70
	dec	di
	mov	al,'.'
	stosb
cdr70:
	mov	si,dtaaddr+16		; display the file extension
	mov	cx,3
	rep	movsb
cdr44:
	true?	[dwopt]
	jne	cdr44a

	mov	bx,dtaaddr+19		; check for subdir attribute
	test	byte ptr [bx],10h
	jz	cdr44a

	mov	al,']'
	stosb
cdr44a:
	ret
cdr34 endp

; display file name and data, managing /w and /p options

cdr33 proc
	true?	[dwopt]
	lje	cdr36
					; format line for full display
	call	cdr34			; display file name and ext
	mov	bx,dtaaddr+19		; check for subdir attribute
	test	byte ptr [bx],10h
	jz	cdr42
	cld
	lea	di,[workbuf+21]
	push	ds
	push	cs
	pop	ds
	lea	si,[direcstr]
	mov	cx,13			; get size of string			890801
	call	copystr
	pop	ds
	jmp	cdr43

direcstr db	'[DIRECTORY]  '		;@@xlat

cdr42:
	mov	bx,dtaaddr+36
	mov	ax,[bx]			; convert file size value
	mov	dx,[bx+2]
	lea	bx,[workbuf+22]
	mov	cx,9
	call	bin2dec
	cmp	byte ptr [workbuf+19],' '  ; insert commas
	je	cdr43
	mov	cx,6
	lea	di,[workbuf+13]
	mov	si,di
	inc	si
	cld
	rep	movsb
	mov	byte ptr [workbuf+19],','
	cmp	byte ptr [workbuf+15],' '
	je	cdr43
	mov	cx,3
	lea	di,[workbuf+12]
	mov	si,di
	inc	si
	cld
	rep	movsb
	mov	byte ptr [workbuf+15],','
cdr43:
	mov	bx,dtaaddr+19		; check for subdir attribute
	test	byte ptr [bx],10h
	ljnz	skipupdate		; skip next section for subdir
	mov	bx,dtaaddr+32
	mov	ax,[bx]			; date word: yyyy yyym mmmd dddd
	xor	bh,bh			; convert date format to year in cx
	mov	bl,ah			; month in dh and day in dl
	shr	bl,1
	mov	dl,al
	and	dl,1fh
	mov	cl,5
	shr	ax,cl
	and	al,0fh
	mov	dh,al
	mov	cx,bx
	add	cx,1980
	call	convertdate		; convert the date to a string in workbuf
	mov	ax,word ptr [attmpt1]	; get date format code
	cmp	ax,2			; and prepare to shorten the year to 2 digits
	je	cdr54
	lea	si,[attmpt2+8]
	jmp	cdr55
cdr54:
	lea	si,[attmpt2+2]
cdr55:
	mov	di,si
	sub	di,2
	xor	cx,cx
	call	copystr
	lea	si,[attmpt2]		; xfer the date into workbuf
	lea	di,[workbuf+25]
	call	copystr
	mov	byte ptr [workbuf+33],' '  ; compensate for the 0
	mov	bx,dtaaddr+30
	mov	ax,[bx]
	mov	cl,11
	shr	ax,cl
	xor	dx,dx
	lea	bx,[workbuf+36]		; hour in positions 35,36
	mov	cx,2
	call	bin2dec
	mov	al,[attmpt1+13]		; get time separator code
	mov	[workbuf+37],al
	mov	bx,dtaaddr+30
	mov	ax,[bx]
	mov	cl,5
	shr	ax,cl
	and	ax,003fh
	xor	dx,dx
	lea	bx,[workbuf+39]		; minutes in positions 36,37
	mov	cx,2
	call	bin2dec
	or	[workbuf+38],'0'
skipupdate:
	mov	bx,dtaaddr+19		; get the attribute
	mov	al,[bx]
	test	al,20h			; test the archive bit
	jz	cdr71			; jump if not set
	mov	byte ptr [workbuf+41],'*'
cdr71:
	test	al,1			; test the read only bit
	jz	cdr73
	mov	byte ptr [workbuf+43],'R'
cdr73:
	test	al,2			; test for hidden file
	jz	cdr74
	mov	byte ptr [workbuf+44],'H'
cdr74:
	test	al,4			; test for system file
	jz	cdr75
	mov	byte ptr [workbuf+45],'S'
cdr75:
	mov	bx,dtaaddr+19		; check for subdir attribute
	test	byte ptr [bx],10h
	jz	docdate
	mov	bx,dtaaddr+32		; use update date in creation's position
	jmp	doudate
docdate:
					; get creation date first to check for a mos created file
	mov	bx,dtaaddr+28
doudate:
	mov	ax,[bx]			; date word: yyyy yyym mmmd dddd
	xor	bh,bh			; convert date format to year in cx
	mov	bl,ah			; month in dh and day in dl
	shr	bl,1
	mov	dl,al
	xor	dh,dh
	and	dl,1fh
	mov	bp,dx			; save day # for later test
	ljz	getclass		; day # = 0 so skip extended display
	mov	cl,5			; unless there is a class letter
	shr	ax,cl
	and	al,0fh
	mov	dh,al
	mov	cx,bx
	add	cx,1980
	call	convertdate		; convert the date to a string in workbuf
	mov	ax,word ptr [attmpt1]	; get date format code
	cmp	ax,2			; and prepare to shorten the year to 2 digits
	je	cdr54m
	lea	si,[attmpt2+8]
	jmp	cdr55m
cdr54m:
	lea	si,[attmpt2+2]
cdr55m:
	mov	di,si
	sub	di,2
	xor	cx,cx
	call	copystr
	lea	si,[attmpt2]		; xfer the date into workbuf
	lea	di,[workbuf+57]
	call	copystr
	mov	byte ptr [workbuf+65],' '  ; compensate for the 0
	mov	bx,dtaaddr+19		; check for subdir attribute
	test	byte ptr [bx],10h
	jz	doctime
	mov	bx,dtaaddr+30		; use update time in creation's position
	jmp	doutime
doctime:
					; get creation date first to check for a mos created file
	mov	bx,dtaaddr+26
doutime:
	mov	ax,[bx]
	push	ax
	mov	cl,11
	shr	ax,cl
	xor	dx,dx
	lea	bx,[workbuf+68]		; hour in positions 65,66
	mov	cx,2
	call	bin2dec
	mov	al,[attmpt1+13]		; get time separator code
	mov	[workbuf+69],al
	pop	ax
	mov	cl,5
	shr	ax,cl
	and	ax,003fh
	xor	dx,dx
	lea	bx,[workbuf+71]		; minutes in positions 68,69
	mov	cx,2
	call	bin2dec
	or	[workbuf+70],'0'
getclass:
	mov	bx,dtaaddr+21		; get file class
	mov	al,[bx]
	or	al,al
	jz	noclass
	cmp	al,' '
	jz	noclass
	mov	byte ptr [workbuf+48],al
	jmp	nocl2
noclass:
	or	bp,bp			; is day # 0 ?
	jz	notmosfile
nocl2:
	mov	si,dtaaddr+22
	lea	di,[workbuf+51]
	cmp	byte ptr [si],0
	je	writelong
	mov	cx,4
	cld
	rep	movsb			; get user id
writelong:
	mov	byte ptr [workbuf+72],cr
	mov	byte ptr [workbuf+73],lf
	mov	cx,74
	lea	dx,[workbuf]
	mov	bx,stdout		;  write workbuf to the console
	mos	writfil
	cmp	ax,74
	ljne	ecl1
	jmp	endofdisp
notmosfile:
	mov	bx,dtaaddr+19		; check for subdir attribute
	test	byte ptr [bx],10h
	jnz	writelong		; use long buffer for a subdir
	mov	byte ptr [workbuf+46],cr; use short buffer
	mov	byte ptr [workbuf+47],lf
	mov	cx,48
	lea	dx,[workbuf]
	mov	bx,stdout		;  write workbuf to the console
	mos	writfil
	cmp	ax,48
	ljne	ecl1
endofdisp:
	call	cdr28			; manage end of line
	jmp	cdr35
cdr36:					; display in wide (/w) format

	call	cdr34			; display file name and ext
	cmp	byte ptr [dnames],4
	mov	cx,16
	jb	cdr36a
	mov	cx,15
	mov	word ptr [workbuf+13],0a0dh
cdr36a:
	mov	di,cx
	lea	dx,[workbuf]
	mov	bx,stdout
	mos	writfil
	cmp	ax,di
	ljne	ecl1
	inc	byte ptr [dnames]
	cmp	byte ptr [dnames],5
	jne	cdr35
	mov	byte ptr [dnames],0
	call	cdr28			; manage end of line
cdr35:
	ret
cdr33 endp

cdr65 proc				; compare double word. used for file size
	push	di			; and date/time
	push	bx
	push	cx
	mov	si,bx
	mov	si,[si]
	add	si,ax
	mov	di,[di]
	add	di,ax
	mov	ax,[si]
	mov	bx,[si+2]
	mov	dx,[di]
	mov	cx,[di+2]
	cmp	bx,cx
	pop	cx
	pop	bx
	pop	di
	ret
cdr65 endp

cdr43x	proc
	mov	byte ptr [workbuf+11],0
	mov	word ptr [workbuf],2020h
	cmp	byte ptr [workbuf+7],' '; insert commas
	je	cdr43x1
	mov	cx,6
	lea	di,[workbuf+1]
	mov	si,di
	inc	si
	cld
	rep	movsb
	mov	byte ptr [workbuf+7],','
	cmp	byte ptr [workbuf+3],' '
	je	cdr43x1
	mov	cx,3
	lea	di,[workbuf]
	mov	si,di
	inc	si
	cld
	rep	movsb
	mov	byte ptr [workbuf+3],','
cdr43x1:
	ret
cdr43x	endp


;----------------------------- main code for cdir -------------------------

cdir:
	resflg	[dwopt]			; init flags and counters
	resflg	[dpopt]
	resflg	[ddopt]
	resflg	[dsopt]
	resflg	[daopt]
	resflg	[dcopt]
	resflg	[didhead]
	mov	byte ptr [dlines],1	; start at one for the column heading
	mov	byte ptr [dnames],0
	mov	word ptr [dfilecnt],0
	mov	word ptr [dtotbytes],0
	mov	word ptr [dtotbytes+2],0
	mov	dx,dtaaddr		; init dta address
	mos	setdta
	true?	[nullparm]
	lje	cdr30
	lea	si,[parmbuf]		; scan parmbuf for /s and /c options
cdr46:
	xor	cx,cx
	mov	al,fslash
	call	scanstr
	jne	cdr18			; done with /s and /c
	inc	si
	cld
	lodsb
	call	low2upper
	cmp	al,'S'
	je	cdr2

; cmp al,'C'
; jne cdr46
;
; $$$$$$$$$ code to work with date entry after /c

	jmp	cdr46
cdr2:
	setflg	[dsopt]			; found a /s  sorting
	lodsb
	call	low2upper
	mov	byte ptr [sorttype],0
	cmp	al,'N'
	je	cdr17
	mov	byte ptr [sorttype],1
	cmp	al,'E'
	je	cdr17
	mov	byte ptr [sorttype],2
	cmp	al,'D'
	je	cdr17
	mov	byte ptr [sorttype],3
	cmp	al,'S'
	je	cdr17
	jmp	badparm2
cdr17:
	mov	byte ptr [si-3],20h
	mov	word ptr [si-2],2020h	; blank out the option in parmbuf
	jmp	cdr46			; to simplify later parsing
cdr18:
	lea	si,[parmbuf]
	xor	ah,ah
	mov	al,'W'
	call	getoption
	jne	cdr27
	setflg	[dwopt]
cdr27:
	mov	al,'P'
	call	getoption
	jne	cdr45
	setflg	[dpopt]
cdr45:
	mov	al,'D'
	call	getoption
	jne	cdr29
	setflg	[ddopt]
cdr29:
	mov	al,'A'
	call	getoption
	jne	cdr1
	setflg	[daopt]
cdr1:
	mov	ah,1
	call	getoption
	lje	badparm2
	true?	[dsopt]			; sorting? if yes, get a memory block
	ljne	cdr47
	mov	bx,4096			; paragraph count for 64 kbytes
cdr31:
	mos	getmem
	call	memcheck
	jnc	cdr48
	or	bx,bx
	ljz	badparm7		; insufficient memory
	jmp	cdr31			; try again with the returned size
cdr48:
	mov	[copyseg],ax		; store pointer to block
	setflg	[copyfix2]		; flag for error handler cleanup
	mov	cl,4
	shl	bx,cl
	dec	bx
	mov	[copysize],bx		; calc block size in bytes and store
	mov	di,bx
	sub	di,33			; init pointer for data table
	mov	ax,bx
	mov	bx,34			; calc number of entries which can be handled
	xor	dx,dx
	div	bx
	mov	[maxfiles],ax		; store max number of entries
cdr47:
	lea	si,[parmbuf]		; test for a null parmbuf after options
	call	passdelims		; have been removed
	or	al,al
	jnz	cdr51
cdr30:
	mos	getdrv			; when a null parameter line, get default
	inc	al			; drive
	mov	[drvnum],al		; save the drive number
	lea	si,[workbuf]
	call	writedrvpth		; put current path in workbuf
	lea	si,[workbuf]		; prepare for code at cdr23
	call	findend
	mov	byte ptr [si],bslash
	inc	si
	mov	di,si
	cld
	jmp	cdr23
cdr51:
	call	oneparmchk		; should only be one parameter at most
	ljc	badparm2
	lea	si,[parmbuf]
	call	passdelims
	call	parse			; check for a valid drive specification
	cmp	al,0ffh
	lje	badparm4
	mov	al,byte ptr [prsfcb]
	or	al,al
	jnz	cdr21
	mos	getdrv			; if no drive spec'ed, read the default
	inc	al
cdr21:
	mov	[drvnum],al		; save the drive number
	lea	si,[parmbuf]
	call	passdelims
	push	si
	call	finddelim
	mov	byte ptr [si],0		; trim off any trailing delims
	pop	si
	lea	di,[workbuf]
	xor	cx,cx			; copy the parameter into workbuf
	call	copystr			; so it can be freely modified
cdr22:
	lea	si,[workbuf]
	call	genpthstr		; see if the parameter is a subdir
	jc	cdr7
	call	findfname
	cmp	byte ptr [si],0		; just a \ ?
	je	cdskip
	cmp	word ptr [si],2e2eh	; a .. ?
	je	cdskip
	lea	dx,[workbuf]		; since the parm is a subdir, make sure it
	mov	cx,10h			; is one which should be recognized based
	mos	fndfrst			; on the current security level
	ljc	badparm5
;bwr 8/30/90 --------------------------------------------------------------
;
;  if the pathname ends with a wildcarded name, then don'T append the
;  \*.* to it!
;
	call	findfname		; find filename portion of path.
	call	parse
	cmp	al, 1			; any wildcards detected?
	ljz	cdr11
;
;bwr 8/30/90 --------------------------------------------------------------
cdskip:
	lea	si,[workbuf]
	call	findend
	cld
	mov	di,si			; put a \ on the end if not one already
	cmp	byte ptr [si-1],bslash
	je	cdr23
	mov	al,bslash
	stosb
cdr23:
	mov	al,'*'			; if the parm was simply a subdir, need
	stosb				; to put '\*.*'0 on the end
cdr8:
	mov	al,'.'
	stosb
	mov	al,'*'
	stosb
	xor	al,al
	stosb
	jmp	cdr11
cdr7:
	lea	si,[workbuf]		; when the entered parm is not a subdir
	push	si
	call	findfname
	cmp	word ptr [si],2e2eh	; a .. ?
	pop	si
	lje	badparm5
	mov	di,si			; trim it back and try to chdir again
	dec	di
	call	findend
	std
	dec	si
cdr24:
	lodsb
	cmp	al,bslash		; scan back from end, stopping for a \ or
	je	cdr12			; the beginning of workbuf
	cmp	si,di
	jne	cdr24
	mov	al,[drvnum]		; if stop at beginning of workbuf, the parm
	lea	si,[workbuf]		; can't be a subdir so read the current one
	call	writedrvpth
	call	findend
	cmp	byte ptr [si-1],bslash
	je	cdr13			; put a \ on the end if not one already
	mov	byte ptr [si],bslash
	inc	si
cdr13:
	mov	di,si
	lea	si,[parmbuf]		; locate starting point of parm in parmbuf
	call	passdelims		; for copying into workbuf
	cmp	byte ptr [si+1],':'
	jne	cdr16
	add	si,2
cdr16:
	xor	cx,cx
	cld				; di points to workbuf where parmbuf goes
	call	passdelims
	mov	al,[si]			; si points to parmbuf where data begins
	or	al,al
	ljz	cdr23
	cmp	al,'.'			; check for 'dir .com' format, if find, add a *
	je	cdr10
	mov	bp,si
	call	copystr			; copy remainder of parmbuf into workbuf
	mov	si,bp
	mov	al,'.'
	xor	cx,cx
	call	scanstr			; check for a period in the name
	jz	cdr11			; if none, put one on the end
	dec	di			; (ie 'dir test' -> 'dir test.*')
	jmp	cdr8
cdr10:
	mov	al,'*'			; add a leading star for 'dir .com' format
	stosb
	call	copystr			; copy the remainder of the parm
	jmp	cdr11
cdr12:
	cmp	si,offset [workbuf-1]	; when find a \ while scanning back
	je	cdr15			; must check for '\kdfj' or 'c:\dkjf'
	cmp	byte ptr [si],':'	; cases before trimming
	je	cdr15
	mov	byte ptr [si+1],0	; trim off at the \
	jmp	cdr25
cdr15:
	mov	byte ptr [si+2],0	; trim off just after the \
cdr25:
	lea	si,[workbuf]
	call	genpthstr		; second attempt to find the subdir
	ljc	badparm5
	call	findfname
	cmp	byte ptr [si],0		; just a \ ?
	je	cdskip2
	cmp	word ptr [si],2e2eh	; a .. ?
	je	cdskip2
	lea	dx,[workbuf]		; since the parm is a subdir, make sure it
	mov	cx,10h			; is one which should be recognized based
	mos	fndfrst			; on the current security level
	ljc	badparm5
cdskip2:
	lea	si,[workbuf]
	call	findend
	mov	di,si
	cmp	byte ptr [di-1],bslash	; add a \ on the end if not one already
	je	cdr53
	mov	byte ptr [di],bslash
	inc	di
cdr53:
	lea	si,[parmbuf]		; scan back from the end of parmbuf to
	call	findend			; find the \.  just to the right of the \
	std				; is where the portion of the parm which
	dec	si			; should be copied into workbuf
cdr26:
	lodsb
	cmp	al,bslash
	jne	cdr26
	add	si,2
	jmp	cdr16
cdr11:					; initialize the fcb for directory search
	lea	si,[workbuf]
	call	findfname
	push	si
	call	parse
	lea	di,[prsfcb-7]
	cld
	mov	al,0ffh			; init the fcb's extension
	stosb
	xor	al,al
	mov	cx,5
	rep	stosb
	mov	al,10h			; normal search attribute
	true?	[daopt]
	jne	cdr4
	mov	al,16h			; attribute for hidden and system files
cdr4:
	stosb
	mov	al,[drvnum]		; set the drive number
	stosb
	add	di,11			; skip past the file name and extension fields
	xor	al,al
	mov	cx,25
	rep	stosb			; init remiander to 0
	pop	si			; truncate the file name out of workbuf
	cmp	byte ptr [si-2],':'
	je	cdr5
	dec	si
cdr5:
	mov	byte ptr [si],0		; workbuf now holds just the drive and path
	lea	si,[attmpt1]		; save the current dir of the spec'ed drive
	mov	al,[drvnum]
	call	writedrvpth
	lea	dx,[workbuf]		; make the spec'ed subdir the current one
	mos	chdir			; to accomodate the old fcb calls
	lea	dx,[prsfcb-7]
	mos	srchfrs			; search for first
	push	ax
	lea	dx,[attmpt1]		; restore original current dir for the drive
	mos	chdir
	pop	ax
	or	al,al
	ljnz	cdr50			; no files found
	true?	[dwopt]
	lje	cdr6b
	true?	[ddopt]			; only want subdirectories?
	je	skiphead
	call	putheading
	jmp	skiphead

putheading proc
	true?	[didhead]
	je	phd1
	setflg	[didhead]
	push	dx
	lea	dx,[colhead]
	call	csdispstr
	call	dispeol
	pop	dx
phd1:
	ret
putheading endp

colhead db	cr,lf,'FILENAME.EXT       SIZE  ----UPDATED---- ATTRB CLS USER'  ;@@xlat
	db	'  ----CREATED----',cr,lf,0  ;@@xlat

cdr6b:
	call	dispeol
	call	dispeol
skiphead:
	lea	dx,[attmpt1]		; set up attmpt1 with country data
	xor	al,al
	mos	getcoun
	true?	[dsopt]			; is sorting in effect?
	ljne	cdr19

; read the directory data into the ram block at copyseg and sort.
; 32 block directory records will be read into the ram block from the
; top down, with a table of offset pointers to each block growing from
; the base of the block upwards. when bubble sorting, only need to swap
; the offset word instead of the 32 byte block.

	xor	bp,bp			; init files read counter
	xor	bx,bx			; init pointer for offset table
	mov	di,[copysize]
	sub	di,33			; init pointer for data table
	mov	ax,[copyseg]
	mov	es,ax			; make es point to the ram block
cdr57:
	true?	[ddopt]			; only want subdirectories?
	jne	cdr66
	mov	si,dtaaddr+19		; offset of attribute code
	test	byte ptr [si],10h	; is the attr a subdir's?
	jz	cdr67			; skip if not
	true?	[dwopt]
;	lje	cdr14		; mjs 11/30/87 corrects bug
	je	cdr66			; with 'dir /sn /d /w'
	call	putheading
cdr66:

; $$$$$$$$ add dcopt filter here

	inc	bp			; increment file counter
	cmp	bp,[maxfiles]		; check for overflow
	lja	cdr3
	mov	es:[bx],di		; write data pointer in offset table
	mov	si,dtaaddr+8
	mov	cx,32			; copy the directory block from the dta to
	cld				; the ram block
	rep	movsb
	sub	di,64			; update pointers
	add	bx,2
cdr67:
	lea	dx,[prsfcb-7]
	mos	srchnxt			; old search for next call
	or	al,al
	jz	cdr57

; all the files are in the ram block, now sort them

	or	bp,bp			; test for no files
	ljz	cdr50
	dec	bp			; decrement file counter to use as limit check
	ljz	cdr20
	mov	al,[sorttype]
	push	ax			; save sort type on stack (al on stack)
	push	es
	pop	ds			; make both ds and es point to the data area
cdr58:
	pop	ax			; init swap flag (ah on stack)
	xor	ah,ah
	push	ax
	xor	cx,cx			; init comparison counter
	xor	bx,bx			; init first pointer
	mov	di,2			; init second pointer
cdr59:
	inc	cx
	pop	ax
	push	ax			; get sort type off of stack
	or	al,al
	ljz	cdr62			; sort by fname.ext
	cmp	al,1
	lje	cdr60			; sort by extension
	cmp	al,2
	lje	cdr61			; sort by date/time
					; sorttype must be 3, sort by size
	mov	ax,1ch			; offset of file size
	call	cdr65
	ja	cdr63
	jne	cdr64
	cmp	ax,dx
	ja	cdr63
	jmp	cdr64
cdr60:					; sorttype=1, sort by file extension
	push	cx
	push	di
	mov	cx,3			; length of a file extension
	mov	si,bx
	mov	si,[si]
	add	si,8
	mov	di,[di]
	add	di,8
	repe	cmpsb			; compare the two data blocks
	pop	di
	pop	cx
	jna	cdr64			; swap the pointers if 1st > 2nd
	jmp	cdr63
cdr61:					; sorttype=2, sort by date/time
	mov	ax,16h			; offset of file time
	call	cdr65
	ja	cdr63
	jne	cdr64
	cmp	ax,dx
	ja	cdr63
	jmp	cdr64
cdr62:					; sorttype=0, sort by fname.ext
	push	cx
	push	di
	mov	cx,11			; length of a file name and ext
	mov	si,bx
	mov	si,[si]
	mov	di,[di]
	repe	cmpsb			; compare the two data blocks
	pop	di
	pop	cx
	jna	cdr64			; swap the pointers if 1st > 2nd
cdr63:
	pop	ax			; set swap flag
	mov	ah,1
	push	ax
	mov	ax,[bx]			; swap the pointers in the offset table
	xchg	ax,[di]
	mov	[bx],ax
cdr64:
	add	bx,2			; update the comparison pointers
	add	di,2
	cmp	cx,bp			; done with this pass?
	ljne	cdr59
	pop	ax			; make a full pass with no swaps?
	push	ax			; get swap flag off of stack
	or	ah,ah
	ljnz	cdr58
	pop	ax			; balance stack
cdr20:
	push	es
	pop	ds			; when enter becuase only one file, ds needs
	mos	getpsp			; init to = es.
	mov	es,bx			; restore segment reg es, leave ds pointing
	xor	bx,bx			; to the ram block
	mov	si,[bx]			; get offset of 1st data block from table
	mov	di,dtaaddr+8		; init destination pointer into dta
	mov	cx,32
	cld
	rep	movsb			; put the first data block back into the dta
	push	es
	pop	ds
	mov	word ptr [nextblk],2	; init pointer for next block
	inc	bp
	mov	[totfiles],bp		; store file count (orig count)
	jmp	cdr14
cdr19:					; jump to here to skip sorting

; $$$$$$$$$$ if dcopt true, filter for date spec here
; $$$$$$$$$$ if fail, jump to cdr68

	true?	[ddopt]			; if /d option, skip if not a subdirectory
	jne	cdr14
	mov	bx,dtaaddr+19		; address of attribute
	test	byte ptr [bx],10h
	jz	cdr49			; skip display call if not a subdir
	true?	[dwopt]
	lje	cdr14
	call	putheading
cdr14:

					; mjs 1/29/88
	mov	bx,dtaaddr+19
	test	byte ptr [bx],10h	; for novell - only read/tally file
	jne	cdr14a			; size if not a subdir
	mov	bx,dtaaddr+36		; (this mod added to $$shell1.pat)
	mov	ax,[bx]
	mov	dx,[bx+2]		; get file size in dx:ax
	add	word ptr [dtotbytes],ax
	adc	word ptr [dtotbytes+2],dx  ; update total bytes
cdr14a:
					; end mjs 1/29/88

	call	cdr33			; display file name and data
	inc	word ptr [dfilecnt]	; count number of files
cdr49:
	true?	[dsopt]			; is sorting in effect?
	jne	cdr68
	dec	[totfiles]
	jz	cdr69			; done
	mov	bx,[nextblk]
	mov	ax,[copyseg]
	mov	ds,ax
	mov	si,[bx]			; get offset of 1st data block from table
	mov	di,dtaaddr+8		; init destination pointer into dta
	mov	cx,32
	cld
	rep	movsb			; put the data block back into the dta
	push	es
	pop	ds
	add	bx,2
	mov	word ptr [nextblk],bx	; init pointer for next block
	jmp	cdr14
cdr68:					; skip to here if not sorting
	lea	dx,[prsfcb-7]
	mos	srchnxt
	or	al,al
	jz	cdr19
cdr69:					; done with directory listing
					; display summary lines at bottom
	true?	[ddopt]			; just doing directories?
	jne	cdr69a
	cmp	word ptr [dfilecnt],0
	ljz	cdr50			; if yes, but didn't find any, skip lower line
cdr69a:
	true?	[dwopt]
	jne	cdr52
	mov	ax,[dfilecnt]
	mov	bl,10			; if using /w option, insure proper placement
	div	bl			; of totals line
	or	ah,ah			; check for remainder after div by 10
	jz	cdr52
	call	dispeol
	call	cdr28			; manage line counting for /p option
cdr52:
	mov	dl,[drvnum]
	mov	bx,dtaaddr
	call	getvollbl
	mov	cx,1
	call	dispblanks
	mov	byte ptr [workbuf+11],0
	mov	word ptr [workbuf],2020h
	lea	bx,[workbuf+10]		; convert and display total byte count
	mov	cx,9
	mov	ax,word ptr [dtotbytes]
	mov	dx,word ptr [dtotbytes+2]
	call	bin2dec
	call	cdr43x
	lea	dx,[workbuf]
	call	dispstr
	lea	dx,cmd:[dtotmsg]	; display 'Bytes'
	call	csdispstr
	lea	bx,[workbuf+4]		; convert and display file count
	mov	cx,5
	xor	dx,dx
	mov	ax,[dfilecnt]
	call	bin2dec
	mov	byte ptr [workbuf+5],0
	lea	dx,[workbuf]
	call	dispstr
	lea	dx,cmd:[dfilmsg]	; display 'File(s)'
	call	csdispstr
	mov	dl,[drvnum]
	mos	freespc			; calc and display free space on disk
	mul	cx
	mul	bx
	lea	bx,[workbuf+10]		; convert and display free byte count
	mov	cx,9
	call	hibin2dec		;for 1.4 gig drive
	call	cdr43x			; put in commas
	lea	dx,[workbuf]
	call	dispstr
	lea	dx,cmd:[dbytmsg]	; display 'bytes free'
	call	csdispstr
	jmp	cdr9
cdr50:
	push	ds
	pop	es
	call	dispeol
	mov	al,2			; file not found error
	call	reporterror
	jmp	cdr9
cdr3:					; not enough memory for sort
	push	ds
	pop	es
	mov	al,2
	call	reporterror
	jmp	cdr9
cdr9:
	true?	[copyfix2]		; free up the memory block
	ljne	cmfl
	resflg	[copyfix2]
	mov	ax,[copyseg]
	mov	es,ax
	mos	freemem
	call	memcheck
	push	ds
	pop	es
	jmp	cmfl

;=========================== erase ========================

	assume	ds:cerases

evermsg1 db	cr,lf,'Erase All Files $    '  ;@@xlat
everyn	db	' (Y/N)? ',0		;@@xlat
evermsg2 db	cr,lf,'Erase  ',0	;@@xlat

cer5 proc				; read a key from standard input
	mov	al,8
	mov	dl,0ffh
	mos	getkey			; use this call to clear the buffer
	or	al,al			; extended key code?
	jnz	cer9
	mos	8			; get the extended code out of the buffer
	jmp	cer5			; don't want any key with extended code
cer9:
	cmp	al,32
	jb	cer29			; skip displaying control chars
	mov	dl,al
	call	dispchar
cer29:
	ret
cer5 endp

cer18 proc				; if get y,cr or n,cr then return the letter
	call	cer5			; (y or n) else return 0 in al
	call	low2upper
	cmp	al,[yesmsg]
	je	cer19
	cmp	al,[nomsg]
	je	cer19
	xor	al,al
	jmp	cer22
cer19:
	mov	bl,al
	call	cer5
	cmp	al,cr
	mov	al,bl
	je	cer22
	xor	al,al
cer22:
	ret
cer18 endp

;--------------------------- main code for erase  -------------------------

cerase:
	true?	[nullparm]
	lje	badparm1		; invalid number of parameters
	resflg	[evopt]
	lea	si,[parmbuf]		; scan parmbuf for options (/v)
	mov	al,'V'
	xor	ah,ah
	call	getoption
	jne	cer2
	setflg	[evopt]
cer2:
	resflg	[eyopt]
	lea	si,[parmbuf]		; scan parmbuf for options (/v)
	mov	al,'Y'
	xor	ah,ah
	call	getoption
	jne	cer2y
	setflg	[eyopt]
cer2y:
	mov	ah,1
	call	getoption
	lje	badparm2		; invalid option
cer1:
	lea	si,[parmbuf]		; test for a null parmbuf after options
	call	passdelims		; have been removed
	or	al,al
	ljz	badparm1		; invalid # of parms
	call	oneparmchk		; should only be one parameter at most
	ljc	badparm2
	call	setdtaaddr
	lea	si,[parmbuf]
	call	passdelims
	lea	di,[workbuf]
	xor	cx,cx
	call	copystr
	lea	si,[workbuf]

					; mjs 10/21/87
	push	si
	call	finddelim
	mov	byte ptr [si],0
	pop	si
					; end mjs 10/21/87

	call	fullform
	jnc	cer3
	or	al,al
	ljz	badparm5
	jmp	badparm4
cer3:
	or	bl,bl
	ljnz	badparm3
	lea	si,[workbuf]		; check for a full global spec and prompt
	call	findfname		; for verification
	mov	bp,si			; save start of file name for later
	call	parse
	lea	di,[prsfcb+1]
	cld
	mov	cx,11
	mov	al,'?'
	repe	scasb
	jne	cer4
cer6:
	true?	[evopt]
	je	cer10
	true?	[eyopt]			; if /y was used, skip the prompt
	je	cer10
	lea	dx,cmd:[evermsg1]	; disp msg 'Erase all '
	call	csdispmsg
	lea	dx,cmd:[everyn]		; disp msg '(Y/N)'
	call	csdispstr
	call	cer18			; get answer
	cmp	al,[yesmsg]
	je	cer10
	cmp	al,[nomsg]
	lje	cmfl
	jmp	cer6
cer10:
	call	dispeol
cer4:
	lea	dx,[workbuf]
	xor	cx,cx
	mos	fndfrst
	ljc	badparm3		; file not found
cer14:
	mov	si,[dtaaddr+30]
	mov	di,bp
	xor	cx,cx
	call	copystr			; put the file name found in workbuf
	true?	[evopt]			; was the /v (verify before erase) option used?
	jne	cer17
cer27:
	lea	dx,cmd:[evermsg2]	; disp msg 'Erase  '
	call	csdispstr
	mov	dx,bp
	call	dispstr			; display the file name
	lea	dx,cmd:[everyn]
	call	csdispstr
	call	cer5			; get answer
	or	al,al
	jz	cer27
	call	low2upper
	call	dispeol
	cmp	al,[nomsg]
	lje	cer28
	cmp	al,[yesmsg]
	jne	cer27
cer17:					; delete the file in workbuf
	lea	dx,[workbuf]
	mos	delfil
;;sah	jc	ceraccden
;;sah	jmp	cer28
cer28:
	mos	fndnext
	jnc	cer14
	jmp	cmfl
ceraccden:
;;sah	mov	al,5		; access denied
;;sah	jmp	badparm

;=========================== exit ========================

	assume	ds:dataseg,es:dataseg

cexit:
	true?	[popt]
	lje	cmfl			; ignore if /p option was used
	true?	[copt]
	lje	cext1			; if /c option, don't restore PSP data
	mov	si,10			; restore psp data before quitting
	mov	ax,word ptr [pspterm]
	mov	[si],ax
	add	si,2
	mov	ax,word ptr [pspterm+2]
	mov	[si],ax
	mov	si,22
	mov	ax,[pspparnt]
	mov	[si],ax
cext1:
	mos	quit

;=========================== mkdir ========================

	assume	ds:dataseg,es:dataseg

cmkdir:
	true?	[nullparm]
	lje	badparm1
	lea	si,[parmbuf]
	call	parse
	cmp	al,0ffh
	lje	badparm4
	call	oneparmchk
	ljc	badparm1
	lea	si,[parmbuf]
	call	passdelims
	mov	dx,si
	mos	mkdir
	ljnc	cmfl
	mov	al,207			; unable to create directory
	call	reporterror
	jmp	cmfl

;=========================== path ========================

	assume	ds:dataseg,es:dataseg

pathmsg db	'Path not set      ',cr,lf,0  ;@@xlat

cpath:

; make sure the reported path is current if do a path command right
; after running novell's login.exe

	push	ax
	push	bx
	push	cx
	push	si
	push	di
	call	initprmpth
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	true?	[nullparm]
	lje	cpa1			; if a null buffer, could still be 'path ;'
	lea	si,[parmbuf]
	cld
cpa2:
	lodsb
	call	testdelims
	je	cpa3
	mov	bp,si
	dec	bp
	jmp	cpa4
cpa3:
	cmp	al,';'
	jne	cpa2
	jmp	cpa5
cpa4:
	lodsb
	cmp	al,';'
	je	cpa4
	cmp	al,0
	je	cpa6
	call	testdelims
	jne	cpa4
cpa6:
	mov	byte ptr [si-1],0
	mov	si,bp
	xor	cx,cx
	lea	di,[workbuf]
	call	copystr
	xor	cx,cx
	lea	si,[workbuf]
	call	str2upper
	lea	di,[parmbuf]		; copy in 'PATH='
	push	ds
	push	cs
	pop	ds
	lea	si,[pthstrg]
	mov	cx,5
	call	copystr
	pop	ds
	lea	si,[workbuf]
	xor	cx,cx
	call	copystr
	resflg	[nullparm]
	jmp	cset			; use the logic for the set command
cpa1:
	lea	si,[parmbuf]
	mov	al,';'
	xor	cx,cx
	call	scanstr
	lje	cpa5
	cmp	byte ptr [pathstr],0
	je	cpa7
	lea	dx,cmd:[pthstrg]
	call	csdispstr
	lea	dx,[pathstr]
	call	dispstr
	call	dispeol
	jmp	cmfl
cpa7:
	lea	dx,cmd:[pathmsg]
	call	csdispstr
	jmp	cmfl
cpa5:
	lea	di,[parmbuf]		; copy in 'PATH='
	push	ds
	push	cs
	pop	ds
	lea	si,[pthstrg]
	xor	cx,cx
	call	copystr
	pop	ds
	resflg	[nullparm]
	jmp	cset			; use the logic for the set command

;=========================== prompt ========================

	assume	ds:dataseg,es:dataseg

cprompt:
	lea	si,[parmbuf]
	call	passdelims
	lea	di,[workbuf]
	xor	cx,cx
	call	copystr
	lea	di,[parmbuf]		; copy in 'PROMPT='
	push	ds
	push	cs
	pop	ds
	lea	si,[prmstrg]
	mov	cx,7
	call	copystr
	pop	ds
	lea	si,[workbuf]
	xor	cx,cx
	call	copystr
	resflg	[nullparm]
	jmp	cset			; use the logic for the set command

;=========================== rename ========================

	assume	ds:crenames

cdcheck:				; if the string at ds:si is a directory, return zr
	push	si			; uses [rspecdrv]
	lea	si,[attmpt1]
	mov	al,[rspecdrv]		; save current dir in attmpt1
	call	writedrv
	mov	dl,al
	mos	getdir
	mov	al,[rspecdrv]
	or	al,al
	jnz	cdc1
	mos	getdrv
	inc	al
cdc1:
	add	al,64
	mov	[attmpt2],al		; init attmpt2 with a the drive letter
	mov	[attmpt2+1],':'
	lea	di,[attmpt2+2]
	pop	si			; does the source contain a drive?
	cmp	byte ptr [si+1],':'	; skip past it if it does
	jne	cdc2
	add	si,2
cdc2:
	xor	cx,cx
	call	copystr			; now, tack on the 2nd parm
	lea	dx,[attmpt2]
	mos	chdir			; attempt the cd the path
	jc	cdc3
	lea	si,[attmpt2]
	mov	byte ptr [si],'\'
	inc	si
	mov	dl,[rspecdrv]		; save now current dir in attmpt2
	mos	getdir
	lea	dx,[attmpt1]		; restore original dir
	mos	chdir
	or	ax,ax
	ret
cdc3:
	mov	ax,1
	cmp	al,ah
	ret


fnd2nd	equ	1			; found an explicit second parm
bslash1 equ	2			; found \'s in the 1st parm
bslash2 equ	4			; found \'s in the 2nd parm
asis1	equ	8			; 1st parm is a dir
asis2	equ	10h			; 2nd parm is a dir
fndslm	equ	20h			; found a /m
p1eqp2 equ	40h			; 1st path = 2nd path


crename:
	true?	[nullparm]
	lje	badparm1

;========== develop parmeter profile ==========

	resflg	[renflgs]
	lea	si,[parmbuf]
	mov	al,'M'
	xor	ah,ah			; check for /m option
	call	getoption
	jne	crn1
	or	[renflgs],fndslm
crn1:
	call	oneparmchk		; count parameters
	ljnc	badparm1		; bwr 8/31/90 - invalid # of parms.
	or	[renflgs],fnd2nd	; there is a 2nd, now is there more?
	lea	si,[parmbuf]
	call	passdelims		; find start of 1st parm
	call	finddelim
	call	passdelims		; find start of 2nd parm
	call	finddelim
	call	passdelims
	or	al,al
	ljnz	badparm1		; should be 0 if only two parms
crn2:
	lea	si,[parmbuf]
	call	passdelims
	mov	[prm1strt],si		; record pointer to start of 1st parm
	call	parse
	cmp	al,0ffh
	lje	badparm4		; invalid drive spec
	mov	al,byte ptr [prsfcb]
	mov	[rspecdrv],al		; record drive
	mov	si,[prm1strt]
	call	finddelim
	mov	byte ptr [si],0		; isolate the first parm
	test	[renflgs],fnd2nd
	jz	crn4			; if an explicit 2nd parm was given, flow thru
	inc	si
	call	passdelims		; find start of 2nd parm
	push	si
	call	finddelim
	mov	byte ptr [si],0
	pop	si			; copy the 2nd parm to workbuf
	lea	di,[workbuf]
	xor	cx,cx
	call	copystr
	cmp	byte ptr [workbuf+1],':'; can't have a drive spec
	lje	badparm2
	lea	si,[workbuf]
	mov	al,bslash
	xor	cx,cx			; check the 2nd parm for a path spec
	call	scanstr
	jne	crn3
	or	[renflgs],bslash2
crn3:
	lea	si,[workbuf]
	call	cdcheck
	jne	crn4			; is the 2nd parm a subdir as is?
	or	[renflgs],asis2
crn4:
	mov	si,[prm1strt]
	mov	al,bslash
	xor	cx,cx			; check the 1st parm for a path spec
	call	scanstr
	jne	crn5
	or	[renflgs],bslash1
crn5:
	mov	si,[prm1strt]
	call	cdcheck			; is the 1st parm a subdir as is?
	jne	crn6
	or	[renflgs],asis1

;==================== subdir renaming and parameter analysis ===============

crn6:
	test	[renflgs],asis1
	ljz	crn7			; if 1st parm is a subdir "as is"
	test	[renflgs],fnd2nd	; then presume user wants to rename
	ljz	badparm1		; the directory
	test	[renflgs],fndslm
	jnz	crn6a			; if "ren x1 x2\x1" require /m
	test	[renflgs],bslash2	; for consistency
	jz	crn6c
	mov	al,221			; must use /m to move across directories
	jmp	badparm
crn6c:
	test	[renflgs],bslash1
	jz	crn6a
	lea	si,[workbuf]
	lea	di,[renbuf]		; if no /m, but \'s in 1st parm then need
	xor	cx,cx			; to force 2nd parm to be in same dir as first)
	call	copystr
	lea	si,[attmpt2]
	lea	di,[workbuf]
	xor	cx,cx
	call	copystr
	lea	si,[workbuf]
	call	findfname
	mov	di,si
	xor	cx,cx
	lea	si,[renbuf]
	call	copystr
crn6a:
	mov	dx,[prm1strt]
	lea	di,[workbuf]
	mos	rename
	ljnc	cmfl
	cmp	al,4
	ljb	badparm
	cmp	al,5
	jne	crn6d
	mov	al,223			; wildcards not allowed or new directory exists
	jmp	badparm
crn6d:
	mov	al,224			; cannot rename across drives
	jmp	badparm
crn7:
	test	[renflgs],fnd2nd
	ljz	crn11
	test	[renflgs],bslash2 or asis2
	jz	crn8
	test	[renflgs],fndslm
	jnz	crn7a
	mov	al,221			; must use /m message
	jmp	badparm
crn7a:
	test	[renflgs],asis2		; if 2nd parm just a subdir, must add
	ljz	crn12			; a '\' and the file name from
	lea	si,[workbuf]		; the 1st dir
	call	findend
	mov	al,'\'
	cld
	mov	di,si
	stosb
	mov	si,[prm1strt]
	call	findfname
	xor	cx,cx
	call	copystr
	jmp	crn12
crn8:
	test	[renflgs],bslash1
	jz	crn10
	test	[renflgs],fndslm
	ljnz	crn12
					; extract path from 1st parm and concat in front of 2nd parm
					; (don't copy drive spec) 2nd parm should only be a fname
	lea	si,[workbuf]
	lea	di,[attmpt1]		; copy 2nd parm to attmpt1 temporarily
	xor	cx,cx
	call	copystr
	mov	si,[prm1strt]
;
;  strip off the path portion of the first parameter and prepend
; it to the target filename, if present.
;
	mov	ax,si
	call	findfname
	sub	si,ax			; calculate length of path portion.
	mov	cx,si
	mov	si,ax			; put the 1st parm's path into workbuf
	lea	di,[workbuf]
	call	copystr
	lea	si,[attmpt1]		; then put the fname back on the end
	xor	cx,cx
	call	copystr
	or	[renflgs],p1eqp2	; mark 1st and 2nd paths as same
	jmp	crn15
crn10:
	test	[renflgs],fndslm
	jz	crn10a
	mov	al,221			; must use /m message
	jmp	badparm
crn10a:
	or	[renflgs],p1eqp2
	jmp	crn15
crn11:
	test	[renflgs],fndslm
	jnz	crn11a
	mov	al,221			; must use /m message
	call	reporterror
	mov	dl,'O'
	mos	2			; 'OR '
	mov	dl,'R'
	mos	2
	mov	dl,' '
	mos	2
	jmp	badparm1		; invalid number of parameters
crn11a:
	mov	byte ptr [workbuf],'\'
	mov	dl,[rspecdrv]
	lea	si,[workbuf+1]		; use current dir and addstar as 2nd parm
	mos	getdir
	call	findend
	mov	di,si
	call	addstars

;============ parameter test match ==============

crn12:
	test	[renflgs],bslash1
	jz	crn13
	mov	si,[prm1strt]		; if 1st parm has explicit path in it then
	lea	di,[attmpt1]		; use the 1st parm directly for the
	xor	cx,cx			; comparison
	call	copystr
	lea	si,[attmpt1]
	call	fullform		; derive the complete path
	ljc	badparm2
	jmp	crn14
crn13:
	mov	dl,[rspecdrv]
	lea	si,[attmpt1]		; otherwise use the current directory
	mos	getdir			; for the specified drive
crn14:
	lea	si,[attmpt1]
	call	findfname
	mov	byte ptr [si],0		; only concerned with the path portion here
	lea	si,[workbuf]
	lea	di,[attmpt2]
	xor	cx,cx			; put the 2nd parm in attmpt2 and derive
	call	copystr			; the complete path
	lea	si,[attmpt2]
	call	fullform
	ljc	badparm2
	lea	si,[attmpt2]
	call	findfname
	mov	byte ptr [si],0		; only concerned with the path portion here
	lea	si,[attmpt1]
	call	findlen			; find the lengths of each and compare
	mov	ax,cx
	lea	si,[attmpt2]
	call	findlen
	cmp	ax,cx			; can't match if different lengths
	jne	crn15
	xor	dx,dx
	lea	di,[attmpt1]
	call	strcompare		; check for a match
	jnz	crn15
	or	[renflgs],p1eqp2
crn15:
	lea	si,[workbuf]
	call	findfname		; find start of file name for second parm
	mov	[name2],si		; and record in name2
	call	parse
	lea	si,[prsfcb+1]
	lea	di,[cpttrn]		; save the fcb fname.ext as the template.
	mov	cx,11			; (this will convert *.* to ????????.???)
	call	copystr
	mov	si,[prm1strt]		; find start of file name for 1st parameter
	call	findfname
	mov	[name1],si
	mov	dx,dtaaddr
	mos	setdta
	xor	bp,bp

;================ work loop ==============

	mov	dx,[prm1strt]
	xor	cx,cx
	mos	fndfrst
crn16:
	jnc	crn18
	cmp	ax,18			; handle errors
	ljne	crn17
	mov	ax,2
	or	bp,bp
	ljnz	cmfl
crn17:
	jmp	badparm
crn18:
	mov	si,dtaaddr+30		; get offset of file name in dta
	mov	di,[name1]
	xor	cx,cx
	call	copystr			; copy the found name to parmbuf
	mov	si,[name1]		; start of source filespec
	mov	di,[name2]		; start of destination filespec
	lea	bx,[cpttrn]		; wildcard pattern
	call	substwild		; derive the destination name from the source
					; name and the wildcard pattern
	test	[renflgs],p1eqp2
	jz	crn19
	mov	si,[name1]		; if the 1st path is the same as the 2nd
	call	findlen			; then must see if the file names are the same
	mov	ax,cx
	mov	si,[name2]
	call	findlen
	cmp	ax,cx
	jne	crn19
	mov	di,[name1]
	call	strcompare
	jne	crn19			; if 1st and 2nd are same then error
	mov	al,210			; new file exists or original file not found
	jmp	badparm
crn19:
	mov	dx,[prm1strt]
	lea	di,[workbuf]		; do the rename
	mos	rename
	jnc	crn21
	cmp	al,4
	ljb	badparm
	cmp	al,5
	jne	crn20
	mov	al,210			; new file already exists
	jmp	badparm
crn20:
	mov	al,224			; cannot rename across drives
	jmp	badparm
crn21:
	mov	bp,1
	mos	fndnext
	jmp	crn16

;=========================== rmdir ========================

	assume	ds:dataseg,es:dataseg

crmdir:
	true?	[nullparm]
	lje	badparm1
	lea	si,[parmbuf]
	call	parse
	cmp	al,0ffh
	lje	badparm4
	call	oneparmchk
	ljc	badparm1
	lea	si,[parmbuf]
	call	passdelims
	mov	dx,si
	mos	rmdir
	ljnc	cmfl
	mov	al,208			; unable to create directory
	call	reporterror
	jmp	cmfl

;=========================== envsize ========================

	assume	ds:dataseg,es:dataseg

cenvsiz:
	true?	[nullparm]
	lje	badparm1		; is there a parameter?
	lea	si,[parmbuf]
	call	passdelims
	call	str2numdw		; convert the parameter
	ljc	badparm2
	or	dx,dx			; too large?
	ljnz	badparm2
	call	bytes2para		; calc # of paras for envsize specification
	cmp	ax,[envpara]
	jne	cevb
	mov	[envsize],ax		; if new spec is same as the current allocation
	jmp	cmfl			; then nothing much to do

; if new value > current, try to grow else, store new maximum size and
; check to see if the environment's allocation can be shrunk back to
; match the new envsize specification

cevb:
	ja	ceva
	mov	[envsize],ax
	push	ds
	mov	ds,[envaddr]
	assume	ds:nothing
	call	getenvsize		; get actual paragraphs in ax
	pop	ds
	assume	ds:dataseg
	cmp	ax,[envpara]		; if same as envpara, can't do anything
	lje	cmfl
	call	adjustenv
	ljc	badparm7		; not enough memory
	jmp	cmfl

; attempt to increase the allocation for the master envronment

ceva:
	mov	bx,ax
	push	es
	mov	es,[envaddr]
	mos	modmem
	pop	es
	call	memcheck
	ljc	badparm7		; not enough memory
	mov	[envpara],bx
	mov	[envsize],bx
	jmp	cmfl

;=========================== set ========================

	assume	ds:dataseg
cset:
	true?	[nullparm]
	lje	cst2			; dump
	lea	si,[parmbuf]
	call	passdelims
	mov	bp,si			; save si at start of name
	mov	al,'='
	xor	cx,cx
	call	scanstr
	ljnz	badparm6		; syntax error if don't find one
	mov	al,'='
	inc	si
	xor	cx,cx			; check for a 2nd equals sign
	call	scanstr
	ljz	badparm6		; syntax error if find a second one
	mov	si,bp
	cld				; si will point to the start of the name
	lea	di,[workbuf]		; in parmbuf
cst14:
	lodsb
	call	low2upper		; copy name into workbuf for search call
	stosb
	cmp	al,'='
	jne	cst14
	mov	byte ptr [di-1],0
	call	envsearch		; check for name in environment
	push	ds
	mov	ds,[envaddr]
	assume	ds:nothing
	jc	cst15

; if the string currently exists in the master environment, delete it by
; copying any strings which follow on top of it.

	mov	di,cx
	mov	si,cx
	call	findend
	inc	si			; now di points to start of string to delete
	xor	cx,cx			; and si points to the string after it
	push	es
	push	ds
	pop	es
	assume	es:nothing
cst9:
	cmp	byte ptr [si],0
	je	cst10
	call	copystr
	jmp	cst9
cst10:
	pop	es
	assume	es:dataseg
	mov	byte ptr ds:[di],0
	cmp	byte ptr ds:[0],0	; manage null environment
	jne	cst15
	mov	byte ptr ds:[1],0

; calculate number of bytes in environment (including double 0 terminator)

cst15:
	xor	si,si
	call	findenvtail
	pop	ds
	assume	ds:dataseg
	xchg	bp,si
	push	si
	call	findend
	cmp	byte ptr [si-1],'='	; check for delete string format
	pop	si

; si points to new string, bp holds bytes currently in environment

	jne	cst8

; when the 'set=' command format is used, shrink back as much as possible

	mov	ax,bp
	call	bytes2para
	call	adjustenv
	ljc	cst12
	jmp	cst5

; need to increase the env's block size before adding the new string

cst8:
	call	findlen			; calc total length of new string
	inc	cx			; include the terminating 0
	add	cx,bp
	mov	ax,cx
	call	bytes2para		; calc new allocation
	call	adjustenv		; and attempt to increase the block size
	ljc	cst12

; allocation increase successful, now copy in the new string

	push	si
	push	ds
	mov	ds,[envaddr]
	assume	ds:nothing
	xor	si,si			; find tail and copy new string
	cmp	byte ptr [si],0		; check for null environment
	je	cst13
	call	findenvtail
	dec	si
cst13:
	pop	ds
	assume	ds:dataseg
	mov	di,si
	pop	si
	push	es
	mov	es,[envaddr]
	assume	es:nothing
	cld
cst6:
	lodsb
	call	low2upper		; name on left side of = goes to uppercase
	stosb
	cmp	al,'='
	jne	cst6
	xor	cx,cx
	call	copystr
	xor	al,al
	stosb
	pop	es
	assume	es:dataseg
	jmp	cst5

; just a simple set command with no parameters - dump the environment to stdout

cst2:
	mov	ds,[envaddr]
	xor	si,si			; to the console
cst1:
	mov	dx,si
	call	dispstr
	call	dispeol
	call	findend
	inc	si
	cmp	byte ptr [si],0
	jne	cst1
	push	es
	pop	ds
	jmp	cmfl
cst12:
	mov	al,209			; out of environment space
	call	reporterror
cst5:
	call	initprmpth		; refresh internal copies of prompt and path
	jmp	cmfl

;=========================== time ========================

	assume	ds:dataseg,es:dataseg

timemsg1 db	' is the current time  ',0  ;@@xlat
timemsg2 db	'New time is: $  ',0	;@@xlat
timemsg3 db	cr,lf,'Time not valid   ',0  ;@@xlat
timeset1 db	':.',0
timeset2 db	',.',0

tim5 proc
	mov	al,byte ptr [si-1]	; check for a proper separator on input
	push	si
	lea	si,[timeset1]
	call	testset
	pop	si
	ret
tim5 endp

tim3 proc
	mov	al,byte ptr [si-1]	; check for a proper separator on input
	push	si
	lea	si,[timeset2]
	call	testset
	pop	si
	ret
tim3 endp
tim9 proc
	true?	[nullparm]
	je	tim12
	lea	si,[parmbuf]
	jmp	tim13
tim12:
	call	disptime
	lea	dx,cmd:[timemsg1]	; show the current time
	call	csdispstr
tim7:
	call	dispeol			; prompt for new time
	lea	dx,cmd:[timemsg2]
	call	csdispmsg
	mov	bx,stdin
	mov	cx,128
	lea	dx,[workbuf]
	mos	readfil			; get an input line from the console
	mov	cx,128
	mov	al,cr
	lea	si,[workbuf]
	call	scanstr
	mov	byte ptr [si],0		; convert workbuf to an asciiz string
	lea	si,[workbuf]
tim13:
	call	passdelims
	cmp	byte ptr [si],0
	lje	tim10			; null line
	xor	dx,dx
	xor	cx,cx
	call	str2num			; convert hours
	ljc	tim4
	or	ah,ah
	jnz	tim4
	mov	ch,al
	call	tim5			; test separator
	jne	tim8
	call	str2num			; convert minutes
	jc	tim4
	or	ah,ah
	jnz	tim4
	mov	cl,al
	call	tim5			; test separator
	jne	tim8
	call	str2num			; convert seconds
	jc	tim4
	or	ah,ah
	jnz	tim4
	mov	dh,al
	call	tim3			; test separator
	jne	tim8
	call	str2num			; hundreths of seconds
	jc	tim4
	or	ah,ah
	jnz	tim4
	mov	dl,al
tim11:
	mos	settime			; set the new time
	or	al,al
	ljz	tim10
tim4:
	lea	dx,cmd:[timemsg3]	; report invalid time
	call	csdispstr
	jmp	tim7
tim8:
	cmp	byte ptr [si-1],0
	jne	tim4			; allow for just hours, or just hours:mins
	jmp	tim11
tim10:
	ret
tim9 endp

ctime:
	call	tim9
	jmp	cmfl

;=========================== type ========================

	assume	ds:ctypes

zcheck proc
	push	es			; cx must be set to buffer size
	mov	es,[copyseg]
	xor	di,di
	mov	al,1ah
	cld
	repne	scasb
	pop	es
	ret
zcheck endp

ctype:
	resflg	[hopt]
	true?	[nullparm]
	lje	badparm1
	lea	si,[parmbuf]
	call	parsefn
	ljc	badparm4
	mov	bp,si			; save end of file point
	lea	si,[parmbuf]
	xor	ah,ah
	mov	al,'H'
	call	getoption
	jne	ctp4
	setflg	[hopt]
ctp4:
	call	oneparmchk		; check for only one parm
	ljc	badparm2
	mov	byte ptr [bp],0		; mark end of file name
	lea	si,[parmbuf]
	call	passdelims
	mov	dx,si
	mov	al,01000000b		; inherit, deny none, read access
	mos	openfil			; open file and record handle
	ljc	ctp5
	mov	[typehndl],ax		; save copy of handle

;bwr 11/20/90 ---------------------------------------------------------------
;
;   in the case where the user has tried to double the file by doing
;   a type file >> file to the same file, the type command will keep
;   reading the file after it writes to it.  before beginning the type
;   operation, find out where the eof is and use it as a limiting point
;   along with the dos eof character.
;
	mov	ax, 4202h		; get eof of file.
	mov	bx, [typehndl]
	xor	cx, cx
	xor	dx, dx
	int	21h
	mov	word ptr type_eof, ax
	mov	word ptr type_eof[2], dx
	mov	ax, 4200h		; put file pointer to begin.
	mov	bx, [typehndl]
	xor	cx, cx
	xor	dx, dx
	int	21h
	mov	bx, 3072		; paragraph count for 48 kb.

;bwr 11/20/90 ---------------------------------------------------------------
ctp10:
	mos	getmem
	call	memcheck
	jnc	ctp11
	or	bx,bx
	ljz	badparm7		; insufficient memory
	and	bx,0fff8h		; trunc down to nearest 128 byte multiple
	jmp	ctp10
ctp11:
	mov	[copyseg],ax		; store pointer to block
	mov	cl,4
	shl	bx,cl
	dec	bx
	mov	[copysize],bx		; calc block size in bytes and store
	setflg	[copyfix2]		; flag for error handler cleanup
ctp6:
	mov	bx,[typehndl]		; get handle
;bwr 11/20/90 ---------------------------------------------------------------
	mov	ax, word ptr type_eof	;get amount of file left.
	mov	dx, word ptr type_eof[2]
	mov	cx, [copysize]		;subtract copy chunk.
	sub	ax, cx
	jnc	@f			;if enough, continue.
	sbb	dx, 0			;borrow another 64k.
	test	dx, 8000h		;used up?
	jz	@f			;if not, full copy ok.
	mov	cx, word ptr type_eof	;only copy what's left.
	mov	[copysize], cx		;save for later check.
@@:
;bwr 11/20/90 ---------------------------------------------------------------
	mov	ax,[copyseg]
	mov	ds,ax
	xor	dx,dx
	mos	readfil			; read from the file into the memory block
	push	es
	pop	ds
	ljc	ctp5			; decode error
	mov	cx,ax
	ljcxz	ctp7			; done with file
	true?	[hopt]
	lje	ctp13			; do in hex dump format
ctp8:
	mov	bx,stdout
	mov	ax,[copyseg]
	mov	ds,ax
	push	es
	mov	es,ax
	xor	di,di
	mov	al,1ah
	cld
	repne	scasb
	mov	cx,di
	jne	ctp8a
	dec	di
ctp8a:
	pop	es
	xor	dx,dx
	push	cx
	mos	writfil
	pop	cx
	push	es
	pop	ds
	ljc	ctp5

;bwr 11/20/90 ---------------------------------------------------------------
;
;  have we run into the eof pointer of the file?
;
	mov	ax, [copysize]
	sub	word ptr type_eof, ax
	sbb	word ptr type_eof[2], 0
	test	word ptr type_eof[2], 8000h  ;has it gone negative?
	jnz	ctp7
	cmp	word ptr type_eof[2], 0	;file exhausted?
	jne	@f
	cmp	word ptr type_eof, 0
	jne	@f
	jmp	ctp7
@@:
;bwr 11/20/90 ---------------------------------------------------------------

	call	zcheck
	je	ctp7			; found a ^z in the input buffer
	jmp	ctp6
ctp7:					; normal end of typing process
	mov	bx,[typehndl]		; get handle
	mos	closfil
	ljnc	ctp12
ctp5:
	call	reporterror
ctp12:
	true?	[copyfix2]		; free up the memory block
	ljne	cmfl
	resflg	[copyfix2]
	mov	ax,[copyseg]
	mov	es,ax
	mos	freemem
	call	memcheck
	push	ds
	pop	es
	jmp	cmfl

;------------------------------- hex dump ------------------------------

ctp13:					; /h option, do a hex dump
	mov	bp,cx			; store byte count in bp (for limit check)
	call	dispeol
	lea	di,[workbuf]
	mov	ax,2020h
	mov	cx,40
	rep	stosw			; init workbuf to blanks
	mov	word ptr [datacnt],0
	mov	word ptr [datacnt+2],0
	xor	si,si			; use si as a pointer to the data block
	cld
ctp14:
	mov	ds,[copyseg]
	lodsb				; read a charactor from the data block
	push	es
	pop	ds
	cmp	si,bp
	lja	ctp22			; jump when done with block

	mov	cx,word ptr [datacnt]
	and	cx,0fh
	jnz	ctp23
	push	ax
	lea	di,[workbuf]		; convert the line number
	mov	al,byte ptr [datacnt+3]
	call	byte2hex
	mov	al,byte ptr [datacnt+2]
	call	byte2hex
	mov	al,byte ptr [datacnt+1]
	call	byte2hex
	mov	al,byte ptr [datacnt]
	call	byte2hex
	pop	ax
ctp23:
	mov	bx,cx
	add	cx,bx
	add	cx,bx			; multiply index by 3
	lea	di,[workbuf+10]
	add	di,cx
	call	byte2hex		; store the hex conversion in the buffer
	cmp	bx,8
	jne	cpt19
	mov	byte ptr [workbuf+33],'-'
cpt19:
	lea	di,[workbuf+59]		; store the char in the text portion of
	add	di,bx			; the buffer
	mov	ah,'.'
	cmp	al,' '
	jb	ctp20			; check the range of the code, if not
	cmp	al,126			; displayable, write a period in textbuf
	ja	ctp20
	mov	ah,al
ctp20:
	mov	[di],ah
	mov	ax,word ptr [datacnt]
	add	ax,1			; update the data counter
	adc	word ptr [datacnt+2],0
	mov	word ptr [datacnt],ax
	and	ax,0fh
	ljnz	ctp14
	call	ctp15
	jmp	ctp14			; recycle
ctp15 proc
	lea	dx,[workbuf]
	mov	cx,75
	mov	bx,stdout		; display the line
	mos	writfil
	cmp	ax,75
	ljne	ecl1
	call	dispeol
	lea	di,[workbuf]
	mov	ax,2020h
	mov	cx,40
	rep	stosw			; init workbuf to blanks
	ret
ctp15 endp

ctp22:
	mov	ax,word ptr [datacnt]	; when done with a block, must
	and	ax,0fh			; check for a remainder (will never
	ljz	ctp22a			; happen when can get another block)
	call	ctp15
ctp22a:
	mov	cx,bp

;bwr 11/20/90 ---------------------------------------------------------------
;
;  have we run into the eof pointer of the file?
;
	mov	ax, [copysize]
	sub	word ptr type_eof, ax
	sbb	word ptr type_eof[2], 0
	test	word ptr type_eof[2], 8000h  ;has it gone negative?
	ljnz	ctp7
	cmp	word ptr type_eof[2], 0	;file exhausted?
	jne	@f
	cmp	word ptr type_eof, 0
	jne	@f
	jmp	ctp7
@@:
;bwr 11/20/90 ---------------------------------------------------------------

	call	zcheck
	ljz	ctp7
	jmp	ctp6

;=========================== error handlers ========================

badparm1:
	mov	al,206			; invalid number of parameters
	jmp	badparm

badparm2:
	mov	al,205			; invalid parameter
	jmp	badparm

badparm3:
	mov	al,2			; file not found
	jmp	badparm

badparm4:
	mov	al,15			; invalid drive specification
	jmp	badparm

badparm5:
	mov	al,3			; invalid directory
	jmp	badparm

badparm6:
	mov	al,201			; syntax error
	jmp	badparm

badparm7:
	mov	al,8			; insufficient memory
	jmp	badparm

badparm:
	call	reporterror
	true?	[copyfix1]		; do we need to reset verify
	jne	bp10			; skip if no
	resflg	[copyfix1]		; make sure we don't try again
	xor	al, al			; no further verification requir
	mos	setverf			; tell mos to turn it off

bp10:
	true?	[copyfix2]		; do we need to release memory
	jne	bp20			; skip if no
	resflg	[copyfix2]		; make sure we don't try again
	mov	ax, [copyseg]		; get the memory block location
	mov	es, ax			; set es to the memory block
	mos	freemem			; tell mos he can have it back
	call	memcheck		; call the allocation checker
	push	ds			; must restore es
	pop	es			;  to its proper value
bp20:
	lea	si,[stacktop]
	jmp	cmfl
codeseg ends
	    end intstart
