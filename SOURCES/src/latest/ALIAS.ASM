	include page.inc
	title ALIAS.ASM - Create a logical drive name
;
;******************************************************************************
;*                                                                            *
;*                        MOS Development Specification                       *
;*                                                                            *
;* Command type: External		Assigned to: Jeffrey S. Mayo	      *
;* Command name: ALIAS.COM		Date assigned: 02/15/87		      *
;*					Date completed:			      *
;* Command format: ALIAS[/d] [d: [path]]				      *
;* Purpose: create an alias for a directory				      *
;* Refer to: MOSFUTIL.ASM, MOSBDB.INC, MOSFUN80.ASM, MOXUTIL.ASM	      * 
;* Last Update:	3/31/87			By: JSM				      *
;*                                                                            *
;*	External		Values			Values		      *
;*	routines		passed			returned	      *
;* -------------------------------------------------------------------------- *
;*	DispChar		dl is char to display	none
;*	DispStr			ds:dx->string		none		      *
;*	DispErr			ds:dx->string		none		      *
;*	DispEol			none			none		      *
;*	Parse			ds:si->string		al!=0, NZ, not OK     *
;*				es:di->FCB		al==0, ZR, parse OK   *
;*	Str2NumDW		ds:si->string		dx:ax DD binary int   *
;*							CY if error, NC not   *
;*	Bin2Dec			dx:ax dword to convert	BX string changed     *
;*				bx->output string			      *
;*				cx max string length			      *
;*	Bytes2Para		ax is bytes		ax is paragraphs      *
;*	PassSpace		ds:si->input string	ds:si past spaces     *
;*							al first non-space    *
;*	Word2Hex		ax word to convert			      *
;*				es:di->output string	es:di advanced	      *
;* -------------------------------------------------------------------------- *
;*                                                                            *
;******************************************************************************
;----------------------------------------------------------------------------;
; SAH 07/12/87  Converted functions 80+ to int 38h 00+                       ;
;----------------------------------------------------------------------------;
; JSM 01/04/88  Added /d switch to delete an alias and fixed path logic      ;
;		work properly with alias specs which include drive letters   ;
;		but no path specs.  Change id [1].                           ;
;----------------------------------------------------------------------------;
; RKG 11/02/88  Changed message for translation.                             ;
;----------------------------------------------------------------------------;
; BWR 07/11/89	Corrections so that user can't delete alias if it is         ;
;	      	current drive.                                               ;
;----------------------------------------------------------------------------;
; BWR 11/17/89  Messages marked for foreign language translation.            ;
; BWR 12/04/89	" " "                                                        ;
; BWR 3/28/90	Message delimeters changed from " to ' to conform to         ;
;		foreign language translation convention.		     ;
;----------------------------------------------------------------------------;
	subttl	group segments for code, data and extra segments
	page

;******************************************************************************
;*                                                                            *
;* The next statement tells the assembler and linker to keep all the segments *
;* together when assembled and linked.					      *
;*                                                                            *
;******************************************************************************
;

grp	group	moss,gdata,endseg	; use gdata to define any global data.

moss	segment	word public 'code'
	assume cs:grp,ds:grp,es:grp
moss	ends

gdata	segment word public 'code'
gdata	ends

endseg	segment word public 'code'
EndOfProg	label byte
endseg	ends


	subttl	macros & equates
	page

	include moxutl.inc
	include	alias.pub

GETCURRDSK equ	019h		; get current disk drive
GETCURRDIR equ	047h		; get current directory
DOALIAS	equ	00Dh		;[1] get, make, or delete an alias for a drive
GTALIAS	equ	0		;[1] get an alias definition
MKALIAS	equ	1		;[1] make an alias definition
DELALIAS equ	2		;[1] delete an alias definition



;	Bit flags for Reqmts.

CURDRV	equ	1		; set if we must add current drive
CURDIR	equ	2		; set if we must prepend current directory
NOPATH	equ	4		; set if no path on command line

	subttl	data
	page

gdata	segment
;--------------------------- VARIABLES -------------------------;
version	label	byte
	include	version.inc

	even

WorkBuf	db	128 dup(0)	; general purpose buffer

PrsFCB	db	?		; FCB for the Parse procedure
FCBname db	36 dup(0)	

ismsg	db	'X: is   ', 0   ; message between disk names & aliases ;@@XLAT
nomsg	db	'No aliases have been defined  ',0 ;@@XLAT
nodmsg	db	'No aliases could be found to delete    ',0 ;@@XLAT
delmsg	db	'Alias for  ' ;@@XLAT
deldrv	db	'A: has been deleted    ',0 ;@@XLAT
suremsg db	'Are you sure you want to delete all aliases? ',0 ;@@XLAT
nonedelmsg db	'No    ',13,10 ;@@XLAT
	   db	'No aliases were deleted     ',13,10,0 ;@@XLAT
ystr	db	'Yes   ',13,10,0 ;@@XLAT
pathbuf	db	80 dup (0)	; buffer for path from command line
Reqmts	db	0		; things to add to path
CurDrive db	0		; Current Drive
Drive	db	?		; drive number for alias
Tdrive	db	0		; target drive id
				;
	even			;
				;
DrivePtr dw	?		; pointer to beginning of drive name
DriveLen dw	?		; length of drive name in bytes
AliasPtr dw	?		; pointer to beginning of alias for drive
AliasLen dw	?		; length of alias string


gdata	ends

moss	segment
	org	100h

;	public entry points

	public	ErrorW			; handler for error in console I/O
	public	begin
	public	EndOfProg


;--------------------------- START OF CODE -------------------------;

begin	proc

	cld			; we do lots of string ops, all forwards

	mov	ah,30h
	mov	bx,ax		; read the MOS version number
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax,word ptr [version]
	Ljne	Error7

	mov	ax,OFFSET grp:EndOfProg	; calc size for this program
	add	ax,512			; add space for stack
	mov	sp,ax
	call	Bytes2Para
	mov	bx,ax
	MOS	ModMem			; shrink back to just what's needed

	MOS	GETCURRDSK		; get current drive
	inc	al
	mov	[CurDrive],al		; save for later

	mov	si,80h			; check  length of the parameter line
	mov	bl,[si]
	or	bl,bl
	jnz	ali10			; if parameters, continue
	call	PrintAliases		; if no parameters, print aliases
	jmp	Exit
ali10:
	inc	si
	xor	bh,bh
	mov	BYTE PTR [si+bx],0	; make sure there is a 0 end marker

	call	CheckDel		;[1] do they want to remove a drive?
	jne	ali19			;[1] no, do normal stuff
	call	GetDrive		;[1] get drive number
	Ljc	Error1			;[1]
	cmp	[Drive],0		;[1]
	jne	ali13			;[1] if drive number, delete one alias
	call	DeleteAliases		;[1] Kill all aliases (maybe)
	Ljc	ali30			;[1]
	jmp	Exit			;[1]
ali13:					;[1]
	mov	dl,[Drive]		;[1] alias to delete
	cmp	dl,[CurDrive]		; is this current drive
	Lje	Error8			; if so error out
	call	DeleteOne		;[1]
	Ljc	ali25			;[1]
	jmp	Exit			;[1] leave the program
ali19:					;[1]
	call	GetDrive		; get drive number
	Ljc	Error1
	cmp	[Drive],0		; no drive spec?
	jne	ali20			; if no spec, just print aliases
	call	PrintAliases
	jmp	Exit
ali20:
	mov	di,offset grp:PathBuf	; where the path will go
	call	GetAlias		; determine what to add to alias
	mov	[Reqmts],dl		; requirements to build alias
	call	MakeAlias		; build the alias string
	Ljc	Error4			; if too many parameters
	mov	al,MKALIAS		;[1] set an alias
	mov	dl,[Drive]
	mov	si,offset grp:pathbuf
	MOS38	DOALIAS			;[1] declare the alias to MOS
	jc	ali30			; if error making alias
	mov	dl,[Drive]
	call	PrintOne		; print alias we just made to screen
Exit:
	xor	al,al			; no error
	MOS	Quit
ali25:					;[1]
	cmp	al,15			;[1]
	Lje	Error6			;[1] Alias could not be found message
ali30:
	cmp	al,15
	Lje	Error2			; if drive can't be used for alias
	cmp	al,3
	Lje	Error3			; if bad path for alias
	cmp	al,8
	Lje	Error5			; if not enough memory for alias
	jmp	ErrorW			; if unsuspected error
begin	endp
	

;[1] changes start

	subttl	CheckDel -- check for a delete switch
	page
;-----------------------------------------------------------------------;
; CheckDel								;
;									;
; Checks for /d switch on the command line.  Returns ZF set if switch	;
; found, ZF clear if no switch found.					;
;									;
;  On Entry:								;
;	no conditions							;
;  On Exit:								;
;	ZF set if switch found						;
;	ZF clear if no switch found					;
;	no other registers changed					;
;									;
;-----------------------------------------------------------------------;

CheckDel proc
	push	ax
	push	cx
	push	di
	push	es
	mov	al,'/'
	mov	di,81h
	push	ds
	pop	es
	mov	cl,ds:[di-1]
	xor	ch,ch
chkd10:
repne	scasb			; look for a slash
	jne	chkdx		; if none found
	cmp	byte ptr ds:[di],'d'
	je	chkd20		; if /d
	cmp	byte ptr ds:[di],'D'
	je	chkd20		; if a /D
	or	cx,cx
	jne	chkd10		; if more bytes to search
	cmp	cl,al		; clear ZF, no /d or /D found
	jmp	short chkdx
chkd20:
	mov	word ptr ds:[di-1],'  '	; blank out /d
chkdx:
	pop	es
	pop	di
	pop	cx
	pop	ax
	ret
CheckDel endp

;[1] changes end

	subttl	GetDrive -- get alias drive
	page
;-----------------------------------------------------------------------;
; GetDrive								;
;									;
; Gets drive spec to use as an alias.  Leaves drive number in [Drive].	;
; Advances si beyond drive spec on command line.			;
;									;
;  On Entry:								;
;	ds:si -> command line.						;
;  On Exit:								;
;	CY set if error, clear if no error				;
;	ds:si -> one past end of drive spec				;
;									;
;  Global data affected:						;
;	[Drive] set to drive number --> 1 for A, 2 for B, etc.		;
;	[DrivePtr] -> beginning of drive spec on command line.		;
;	[DriveLen] contains length of drive spec.			;
;  Global procedures called: PassSpace, Parse				;
;  al, si, di changed							;
;-----------------------------------------------------------------------;

GetDrive proc
	call	PassSpace		; must not skip the task ID spec
	or	al,al			; test for null terminator byte
	jz	GetD15			;[1] if no parameters, just spaces

;	At least one parameter, make a drive letter.

	mov	[DrivePtr],si
	mov	di,offset grp:PrsFCB	; parse out whole name
	call	Parse
	mov	ax,si			; find length of drive name
	sub	ax,[DrivePtr]
	mov	[DriveLen],ax
	mov	si,[DrivePtr]		; back to beginning of drive

;	Check drive name out.
	
	lodsb
	cmp	al,'A'			; upper case alphabetic?
	jb	GetD20
	cmp	al,'Z'
	jbe	GetD10
	cmp	al,'a'			; lower case alphabetic?
	jb	GetD20			; if char bad	
	cmp	al,'z'
	ja	GetD20			; if char bad 
	sub	al,'a' - 'A'		; convert to upper case

;	Save drive number.
GetD10:
	sub	al,'A' - 1		; 'A' -> 1, 'B' -> 2, etc.
	mov	[Drive],al		; drive number to use for alias

;	Make sure there's a colon.

	lodsb
	cmp	al,':'
	jne	Getd20			; if no colon
	cmp	[DriveLen],2		; length had better be 2
	jne	Getd20			; if bad length
	clc
	jmp	short GetD30
GetD15:					;[1]
	xor	al,al			;[1]
	mov	[Drive],al		;[1]
	jmp	short GetD30		;[1]
GetD20:
	xor	al,al
	stc
	mov	[Drive],al
GetD30:
	ret
GetDrive endp

	subttl	GetAlias -- get alias string
	page
;-----------------------------------------------------------------------;
; GetAlias								;
;									;
; Determines where path string for alias is on command line.  Returns	;
; requirements for pieces of the path which must be synthesized.  Sets	;
; carry if more than two parameters on command line.			;
;									;
;  On Entry:								;
;	si -> command line right after alias drive spec			;
;  On Exit:								;
;	CY set if too many parameters (3 or more)			;
;	CY clear if right number of parameters (1 or 2)			;
;	si advanced to end of command line				;
;	dl contains bit flags for path pieces which must be synthesized	;
;									;
;  Global data affected:						;
;	[AliasPtr] -> beginning of alias path on command line		;
;	[Tdrive] contains target drive letter				;
;  Calls Passspace							;
;  Changes al, di, si							;
;-----------------------------------------------------------------------;

GetAlias proc
	call	PassSpace		; find next parameter
	xor	dl,dl			; clear requirements
	or	al,al			; any alias at all?
	jnz	GetA10			; if something there
	or	dl,CURDRV or CURDIR or NOPATH
	jmp	GetA70			; set requirements properly
GetA10:
;	Check for drive letter.

	lodsb
	cmp	al,'a'
	jb	GetA20
	cmp	al,'z'
	ja	GetA20
	sub	al,'a' - 'A'		; convert lower to upper case
GetA20:
	cmp	al,'A'
	jb	GetA35			; if no drive letter
	cmp	al,'Z'
	ja	GetA35			; if no drive letter
	mov	ah,al			;[1] save drive letter
	lodsb				; check for colon
	cmp	al,':'
	jne	GetA30
	mov	[Tdrive],ah		;[1] remember target drive
	jmp	short GetA50
GetA30:
	dec	si
GetA35:
	dec	si
	or	dl,CURDRV		; get current drive

;	Determine if path is rooted.

GetA50:
	mov	[AliasPtr],si
	lodsb
	cmp	al,'\'			; rooted paths start with '\'
	je	GetA60			; if path rooted
	or	dl,CURDIR		; say we need current directory
GetA60:
	dec	si			; back si to beginning of path
	or	al,al			; more path?
	jnz	GetA70
	or	dl,NOPATH		; if no path, just drive letter
GetA70:					; skip to next white space
	lodsb
	or	al,al
	jz	GetA80			; end of command line, all OK
	cmp	al,' '
	ja	GetA70			; continue if not whitespace

	call	PassSpace
	or	al,al			; more stuff on line?
	jz	GetA80			; if no more, it's OK
	stc				; more stuff, return error
	jmp	short GetAx
GetA80:
	clc
GetAx:
	ret
GetAlias endp

	subttl	MakeAlias -- construct missing parts of alias string
	page
;-----------------------------------------------------------------------;
; MakeAlias								;
;									;
; If drive spec missing from alias string, gets current drive & copies	;
; into new alias buffer.  If path is not present or path is not rooted,	;
; gets current directory and copies into new alias buffer.  If path is	;
; present on command line, appends path to alias buffer.		;
;									;
; The requirements for constructing the path are assumed to be in the	;
; Reqmts variable.							;
;									;
;  On Entry:								;
;	di -> buffer for alias						;
;  On Exit:								;
;	CY set if problem getting path or drive				;
;	CY clear otherwise						;
;	di -> end of buffer						;
;									;
;  Global data affected: none						;
;  Global procedures called: none					;
;  Changes al, dl, di							;
;-----------------------------------------------------------------------;
	
MakeAlias proc
	mov	al,[Tdrive]		;[1] might be the target drive letter
	sub	al,'A'			;[1] convert to 0-based number
	test	[Reqmts],CURDRV		;[1] use current drive?
	jz	Mka05			;[1] no, we already have a drive
	MOS	GETCURRDSK		;[1] get current drive number
	jc	Mka60			;[1] if unexpected error
Mka05:					;[1]
	mov	dl,al			; save drive number for later
	inc	dl			; use 1 for A, 2 for B, etc.
	add	al,'A'			; convert number to letter
	stosb
	mov	al,':'
	stosb				; store drive name in pathbuf
Mka10:
	test	[Reqmts],CURDIR		; add current path?
	jz	Mka30
	mov	al,'\'			; make path rooted
	stosb
	push	si			; save path pointer
	push	di			; save output pointer
	mov	si,di			; point si where we want the path
					; dl contains the drive in question
	MOS	GETCURRDIR		; get the current path
	pop	di			; get output pointer back
	pop	si
	jc	Mka60			; if unexpected error
	mov	cx,80
	xor	al,al			; look for terminator
repne	scasb
	dec	di			; back di to null byte
	cmp	byte ptr es:[di-1],'\'	; trailing \ ?
	je	Mka30			; if we already have a \
	mov	al,'\'			; make curpath \ userpath
	stosb
Mka30:
	test	[Reqmts],NOPATH		; is there a path to copy?
	jnz	Mka50			; if no path to copy
	mov	si,[AliasPtr]
	call	copyaz			; copy path into pathbuf
Mka50:
	cmp	byte ptr [di-1],'\'	; path end with '\'?
	jne	Mka55			; if no \ on end
	cmp	byte ptr [di-2],':'	; "d:\" is OK
	je	Mka55
	dec	di
	mov	byte ptr [di],0		; terminate path with null
Mka55:
	clc				; no error found
Mka60:
	ret
MakeAlias endp

	subttl	Printone -- print the alias for a drive
	page
;-----------------------------------------------------------------------;
; PrintOne								;
;									;
; Gets the alias for the given drive in Workbuf.  If drive is aliased,	;
; prints "X: is alias" on STDOUT.  If drive is not aliased, prints	;
; nothing.								;
;									;
;  On Entry:								;
;	dl contains disk number -- 1 -> A:, 2 -> B:, etc.		;
;  On Exit:								;
;	ax zero if drive is not aliased					;
;	ax 1 if drive is aliased.					;
;									;
;  Global data affected: none						;
;  Global procedures called: none					;
;  ax changed.								;
;-----------------------------------------------------------------------;

PrintOne proc
	push	dx
	push	si
	push	di
	mov	di,offset grp:ismsg
	mov	al,dl
	add	al,'A' - 1		; make drive number into letter
	mov	[di],al
	mov	al,GTALIAS		;[1] get alias for drive in dl
	mov	si,offset grp:workbuf
	MOS38	DOALIAS			;[1]
	mov	ax,0			; assume drive not aliased
	jc	Pronx			; if no alias for that drive
	mov	ax,1			; drive is aliased
	mov	dx,offset grp:ismsg
	call	DispStr			; say "X: is   "
	mov	dx,offset grp:workbuf
	call	DispStr			; "d:path"
	call	DispEOL
Pronx:	
	pop	di
	pop	si
	pop	dx
	ret
PrintOne endp

	subttl	PrintAliases -- prints aliases for all aliased drives
	page
;-----------------------------------------------------------------------;
; PrintAliases								;
;									;
; Prints aliases for all aliased drives on system.  Calls PrintOne	;
; to print out aliases for all disks on system, 1 (A) through 26 (Z).	;
; If no aliases defined, prints "no aliases" message.			;
;									;
;  On Entry:								;
;	Nothing.							;
;  On Exit:								;
;	dl changed.							;
;									;
;  Global data affected: none						;
;  Global procedures called: PrintOne					;
;  No registers are changed						;
;-----------------------------------------------------------------------;

PrintAliases proc
	mov	bl,0		; flag no aliases printed yet
	mov	dl,1
Pral10:
	call	PrintOne
	or	bl,al		; if something printed, set flag
	inc	dl
	cmp	dl,26
	jbe	Pral10		; can only have 26 drives
	or	bl,bl
	jnz	Pral20		; if no aliases printed
	mov	dx,offset grp:nomsg
	call	DispErr
	call	DispEOL		; print "no aliases" message
Pral20:
	ret
PrintAliases endp

;[1] changes start

	subttl	DeleteOne -- delete an existing aliases
	page
;-----------------------------------------------------------------------;
; DeleteOne								;
;									;
; Delete the alias for the drive in the dl register.			;
;									;
;  On Entry:								;
;	dl contains 1-based drive number (0=A, 1=B, etc.)		;
;  On Exit:								;
;	CY flag set if error to report outside routine			;
;	al contains error code if CY set				;
;	CY flag clear if all went OK					;
;	ax changed							;
;									;
;  Global data affected: none						;
;  Global procedures called: none					;
;-----------------------------------------------------------------------;

DeleteOne proc
	push	dx
	push	dx			; save drive number
	mov	al,DELALIAS		; delete one alias
	MOS38	DOALIAS
	pop	dx
	jc	delox			; if error deleting the alias
	add	dl,'A' - 1		; convert to letter
	mov	[deldrv],dl
	mov	dx,offset grp:delmsg
	call	DispStr			; print successful deletion message
	call	DispEol
	clc
delox:
	pop	dx
	ret
DeleteOne endp

	subttl	DeleteAliases -- delete all aliases in system
	page
;-----------------------------------------------------------------------;
; DeleteAliases								;
;									;
; Deletes all aliases on the system (if the user wants to).		;
;									;
;  On Entry:								;
;	no conditions							;
;  On Exit:								;
;	CY flag set if error to report outside routine			;
;	CY flag clear if all went OK					;
;	al contains error code if CY set				;
;	ax changed always						;
;									;
;  Global data affected: none						;
;  Global procedures called: none					;
;-----------------------------------------------------------------------;

DeleteAliases proc
	push	bx
	push	dx
	push	si
	mov	bl,0		; flag no aliases found
	mov	dl,1		; first drive to check is A
Dela05:
	mov	al,GTALIAS	; get alias for drive in dl
	mov	si,offset grp:workbuf
	MOS38	DOALIAS
	jc	Dela07
	or	bl,1		; if something found, set flag
Dela07:
	inc	dl
	cmp	dl,26
	jbe	Dela05		; can only have 26 drives

	or	bl,bl
	jnz	Dela09		; if an alias found
	mov	dx,offset grp:nodmsg
	call	DispErr
	call	DispEOL		; print "no aliases to delete" message
	jmp	short Dela70
Dela09:
	mov	dx,offset grp:suremsg
	call	DispStr		; are you sure you want to delete them?
Dela10:
	mov	ah,0
	int	16h		; wait for a key
	cmp	al,'a'
	jb	Dela20
	cmp	al,'z'
	ja	Dela20
	sub	al,'a' - 'A'	; convert to upper case
Dela20:
	cmp	al,[ystr]	; test Yes answer
	je	Dela30
	cmp	al,[nonedelmsg]	; test No answer
	jne	Dela10
	mov	dx,offset grp:nonedelmsg	; say none were deleted
	call	DispStr
	jmp	short Dela70	; quit routine & print message if 'N'
Dela30:
	mov	dx,offset grp:ystr
	call	DispStr		; print out "Y" & go to new line
	mov	dl,1		; first drive to check is A
Dela40:
	cmp	dl,[CurDrive]	; if on current drive skip deleting it
	je	Dela50
	mov	al,GTALIAS	; get alias for drive in dl
	mov	si,offset grp:workbuf
	MOS38	DOALIAS
	jc	Dela50
	call	DeleteOne
Dela50:
	inc	dl
	cmp	dl,26
	jbe	Dela40		; can only have 26 drives
Dela70:
	pop	si
	pop	dx
	pop	bx
	ret
DeleteAliases endp

;[1] changes end

	subttl	copyaz -- copy ASCIIZ string
	page
;-----------------------------------------------------------------------;
; copyaz								;
;									;
; Copies an ASCIIZ string, including zero byte, from source to		;
; destination.								;
;									;
;  On Entry:								;
;	si -> source buffer						;
;	di -> destination buffer					;
;  On Exit:								;
;	si -> 1 byte past zero terminator byte in source buffer		;
;	di -> 1 byte past zero terminator byte in destination buffer	;
;	al is last byte copied (NULL)					;
;									;
;  Global data affected: none						;
;  Global procedures called: none					;
;  al, si, di changed							;
;-----------------------------------------------------------------------;

copyaz	proc
	lodsb
	stosb
	or	al,al			; quit if moved a zero byte
	jnz	copyaz
	ret
copyaz	endp

;--------------------------- ERROR HANDLERS -------------------------;

Ermsg1	db	2, ' is bad syntax for an alias drive         ', 0 ;@@XLAT

Error1:
	mov	di,[DrivePtr]
	add	di,[DriveLen]
	mov	byte ptr [di],0	; terminate drive name with null byte
	mov	dx,[DrivePtr]
	call	DispErr		; display drive name
	lea	dx,[Ermsg1]
	jmp	ShowError

Ermsg2	db	1, ' may not be used as an alias        ',0 ;@@XLAT

Error2:
	mov	di,[DrivePtr]
	add	di,[DriveLen]
	mov	byte ptr [di],0	; terminate drive name with null byte
	mov	dx,[DrivePtr]
	call	DispErr		; display drive letter
	lea	dx,[Ermsg2]
	jmp	ShowError

Er3pre	db	'Cannot find directory        ',0 ;@@XLAT
Ermsg3	db	1, ' ',0

Error3:
	lea	dx,[Er3pre]
	call	DispErr		; prefix to directory name
	lea	dx,[pathbuf]
	call	DispErr		; display directory name
	lea	dx,[Ermsg3]
	jmp	ShowError

Ermsg4	db	1,'Format is ',13,10 ;@@XLAT
	db	'ALIAS[/d] x: [path]',0 ;@@XLAT
Error4:
	lea	dx,[Ermsg4]
	jmp	ShowError

Ermsg5	db	2,'Not enough memory to create alias          ',0 ;@@XLAT

Error5:
	lea	dx,[Ermsg5]
	jmp	ShowError

Ermsg6	db	2,'No alias to delete    ',0 ;@@XLAT
								;[1]
Error6:								;[1]
	lea	dx,[Ermsg6]					;[1]
	jmp	ShowError					;[1]
								;[1]
Ermsg7	db	2,'Improper MOS Version',0 ;@@XLAT

Error7:
	lea	dx,[Ermsg7]
	jmp	ShowError

ErmsgW db	1, 'Unexpected error occurred          ',0 ;@@XLAT

ErrorW:
	lea	dx,[ErmsgW]
	jmp	ShowError

Ermsg8	db	2,'Can''t delete Alias on Current Drive       ',0 ;@@XLAT

Error8:
	lea	dx,[Ermsg8]
	jmp	ShowError


ShowError:
	inc	dx		; skip error level
	call	DispErr
	call	DispEOL		; skip a line
	dec	dx
	mov	bx,dx
	mov	al,[bx]		; get error level in al
	MOS	QUIT
	

;	$$$$$$$$ error handler


moss	ENDS

	end	begin
