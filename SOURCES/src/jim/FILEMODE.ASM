	include page.inc
	title FILEMODE.ASM - Attribute command for MOS
;
;******************************************************************************
;*                                                                            *
;*                        MOS Development Specification                       *
;*                                                                            *
;* Command type: External		Assigned to: Jeffrey S. Weyrich	      *
;* Command name: FILEMODE.COM		Date assigned: 2/17/86		      *
;*					Date completed:	2/25/86		      *
;* Command format:FILEMODE [+r,-r,+a,-a] [path\]filename		      *
;* Purpose: Set/clear read-only attribute for a file			      *
;* Refer to: DOS 3.2 reference manuel, "ATTRIB" command			      *
;*									      *
;* Last Update:	11/26/86,1/14/87	By: JSW				      *
;*                                                                            *
;* 2/09/87 DAM renamed to FILEMODE.COM					      *
;* 3/31/87 JSM ripped out guts, fixed wild card operations, used procs	      *
;* 5/12/87 RBR Messages cleaned up     					      *
;* 12/17/87 JSW fixed < 3 chars in filename error.			      *
;*                                                                            *
;*	External		Values			Values		      *
;*	routines		passed			returned	      *
;* -------------------------------------------------------------------------- *
;*	findparm		AX=byte(s) to find	DI points to 1st byte *
;*				AL=byte to find		past found string.    *
;*				AH=0			Carry set - not found *
;*				CX=# of chars in parms			      *
;*				DI=addrs of command line		      *
;*									      *
;*	findfile		CX=# of chars to scan	DI points to 1st non- *
;*				DI=addrs of line to scan  blank char.         *
;*							Carry set - error.    *
;* -------------------------------------------------------------------------- *
;*                                                                            *
;* Errors: 1) Invalid path or filename (cannot set attribute for directoy or  *
;* volume label. 2) Syntax error or 3) Access denied. (Network Access)	      *
;* FILEMODE exits with error codes for ERRORLEVEL testing in batch files. The *
;* codes are: 0 - successful completion of command. 1 - syntax error. 2,3 -   *
;* invalid path or filename. 5 - Access denied! (network access).	      *
;*									      *
;* MOS commands will use the same segment grouping as the MOS kernel. This    *
;* file is a template as is MOSSHELL.ASM. Except that its designed for use in *
;* commands, both internal and external, for MOS. See MOSSHELL.ASM for de-    *
;* tails. The commands should not need to go into as much detail as the kernel*
;* does in keeping track of end of segment pointers in the INC files and such.*
;* Our desire is to maintain the same coding standards thruout MOS and to use *
;* code modularity as much as possible. So, use the same group labels in any  *
;* routine to keep the code and data segments in the same segment.	      *
;*                                                                            *
;******************************************************************************
;
;                    This space intentionally left blank.
;
;******************************************************************************
;*                                                                            *
;* The next statement tells the assembler and linker to keep all the segments *
;* together when assembled and linked.					      *
;*                                                                            *
;******************************************************************************

;----------------------------------------------------------------------------;
;  SAH  08/05/87  Removed sub MOS version check				     ;
;----------------------------------------------------------------------------;
;  BWR	11/27/89  Marked messages for foreign language translation.          ;
;----------------------------------------------------------------------------;
;  RSR  08/10/91  Modified to include system and hidden files per DOS 5      ;
;----------------------------------------------------------------------------;

grp	group	moss,zdata	; use zdata to define any global data.

zdata	segment word public 'code'
zdata	ends

	page

SPACE		equ	20h		; ascii space char
TWENTY_ONE	equ	21h
OPS		equ	80h

;	attribute bit values.

ARCHIVE		equ	020h		; archive attribute
RDONLY		equ	01h		; read-only attribute
HIDDEN          equ     02h             ; hidden
SYSTEM          equ     04h             ; system

moss	segment	word public 'code'
	assume cs:grp,ds:grp,es:grp

	include filemode.pub	; debugging for periscope

	org	100h

mosattr:

	jmp	begin

;******************************************************************************

NO		equ	00h
YES		equ	01h
wrd_flag	db	NO	; indicates whether or not ax has 2 bytes.
				; will cause routine to locate a second byte.
findparm proc	near

start:
	push	es		; save es register.
	push	cs
	pop	es		; set es=cs.
	cmp	ah,NO		; see if 1 byte scan.
	jnz	do_2		; must scan for 2 bytes.
	or	al,al		; sets the zero flag for following scan
scan:	repne	scasb
	jne	not_found	; if didn't find byte, set carry & return
	cmp	byte ptr [di-1],05ch	; check to see if its a `\`. if so, don't
	jz	chk_2			; blank it out.
	mov	byte ptr cs:[di-1],20h	; blank out delimeter

chk_2:
	cmp	grp:[wrd_flag],YES	; see if we must check a second byte
	jnz	ncy		; no - clear carry and return
	cmp	[di],ah		; see if next byte = ah. as it should
	jnz	not_found	; not there
	inc	di		; adjust di & return
	mov	[wrd_flag],NO	; reset word flag
ncy:
	clc			; clear the carry flag
dun:
	pop	es
	ret

do_2:	mov	[wrd_flag],YES
	or	al,al		; clear zero flag
	jmp	scan

not_found:
	stc			; set the carry & return
	jmp	dun

findparm	endp

;******************************************************************************
findfile:

	mov	ah,byte ptr [di]
	cmp	ah,' '		; allow for whitespace
	ja	no_err
	cmp	ah,0dh		;jsw see if we've found the end of the line
	je	err		;jsw this will indicate an error
bump_di:
	inc	di
	loop	findfile
err:
	stc
	jmp	dood
no_err:
	clc			; clear the carry, we found a non-blank

dood:
	ret

;******************************************************************************
;*                           	Data Area & Messages                          *
;******************************************************************************
;

parms	db	'+','-','\'
parmsl	db	$-parms		; length of parameter table. just in case

	even

savecx	dw	0		; used to save the length of the command line

;

fnptr	dw	?		; pointer to real file name
pathptr	dw	0		; pointer to beginning of path
pathlen	dw	?		; length of path
pathbuf	db	80 dup (?)	; buffer for path on file names
namebuf	db	94 dup (?)	; buffer for printint file name with path
msgbuf	db	134 dup (20h)	; buffer for user message

attrib	dw	ARCHIVE		; new attribute for files
attrmsk	dw	0
err1	db	'Invalid path or file not found!           ',13,10,0 ;@@XLAT
err2	db	'Syntax error! ',13,10 ;@@XLAT
	db	'Correct syntax: FILEMODE [-r,+r,+a,-a,+h,-h,+s,-s] [path\]filename     ',13,10,0 ;@@XLAT
err3	db	'Access denied!   ',0dh,0ah,0 ;@@XLAT

setmsg	  db	09h,'set attribute, ',0 ;@@XLAT
nochgmsg  db	09h,'no change,',0 ;@@XLAT
rdonlymsg db	'read-only,' ,0 ;9h,0 ;@@XLAT
rdwrmsg	  db	'read/write, ',0 ;,9h,0 ;@@XLAT
archmsg	  db	'archive on, ',0 ;@@XLAT
noarchmsg db	'archive off ',0 ;@@XLAT
sysmsg    db    'system on, ',0;@@XLAT
nosysmsg  db    'system off, ',0;@@XLAT
hidmsg    db    'hidden on. ',0;@@XLAT
nohidmsg  db    'hidden off. ',0;@@XLAT

endline	db	0dh, 0ah, 0

	even

dta	label	byte
	db	21 dup(0)	; used by mos for scratch area
fattri	db	0		; files attribute
ftime	db	2 dup(0)	;   "   time
fdate	db	2 dup(0)	;   "   date
flenl	db	2 dup(0)	;   "   length - low word
flenh	db	2 dup(0)	;   "      "   - high word
fname	db	13 dup(0)	; filename
left	db	85 dup(0)	; left overs

;******************************************************************************
version	label	byte
	include	version.inc

vermsg	db	13,10,'Improper MOS Version.',13,10,'$' ;@@XLAT

begin	proc
	mov	ah,30h
	mov	bx,ax		; read the MOS version number
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax,word ptr [version]
	je	Vrchk3
;;SAH	cmp	bx,word ptr [version+2]
;;SAH	je	Vrchk3
Vrchk2:
	lea	dx,[vermsg]	; report mismatch
	push	cs
	pop	ds
	mov	ah,9
	int	21h
	mov	ax,4c01h	; and terminate
	int	21h
Vrchk3:

	mov	bx,OPS		; check for parameters
	mov	cl,byte ptr [bx]; load # of chars into cx
	xor	ch,ch
	or	cx,cx		; see if they entered any parms
	jnz	parms_there
	call	syntax_err	; no, syntax error
	jmp	exit

parms_there:

	push	bx
	mov	ah,1ah		; set the dta
	lea	dx,dta
	int	21h
	pop	bx
	mov	di,bx
	inc	di		; di=81h. 1st byte of parms	
	lea	bx,parms	; address parm table
	mov	[savecx],cx	; save area for repeated checks
	call	findfile	; see if only blanks entered on command line.
	jnc	chars_there	; if no carry, command line non-blank
	call	syntax_err
	jmp	exit

;	Search for + on command line.
chars_there:
	mov	cx,[savecx]
	mov	di,OPS
	inc	di
	mov	al,byte ptr [bx]; scan for 2 bytes
	xor	ah,ah
	call	findparm	; check for '+'
	jc	noplus		; if didn't find a '+'
	call	set_plus	; set an attribute
	jc	pluserr		; if error
	inc	bx		; found +, next param is \
	jmp	short procfil	
pluserr:
	call	syntax_err	; if syntax error in set_plus processing
	jmp	exit		; find the files & set attributes
noplus:

;	Search for - on command line.

	inc	bx		; bx points to next parm in table '-'.
	mov	al,byte ptr [bx]
	xor	ah,ah
	mov	cx,[savecx]	; reload cx
	mov	di,OPS		; reset di
	inc	di
	call	findparm	; look for '-' on command line
	jc	nominus		; didn't find a minus sign either
	call	set_minus	; clear an attribute
	jnc	procfil		; if no error
	call	syntax_err	; if syntax error in set_minus processing
	jmp	exit
nominus:
	mov	di,OPS + 1	; set pointer to file name
	mov	cx,[savecx]	; savecx has right thing in it already
procfil:
	mov	[fnptr],di	; remember where file name is
	mov	[savecx],cx	; and how many chars left
	call	get_name	; process file name
	jnc	name_ok		; if file name processed OK
	call	syntax_err	; if can't find the file, error message
	jmp	exit
name_ok:
	xor	cx,cx		; clear attribute
	mov	dx,[pathptr]	; is there a path?
	cmp	dx,cx
	jnz	nameready
	mov	dx,[fnptr]	; no path, use file name
nameready:
	call	get1st		; find first file
	jc	proc_err	; if no file
	call	set_attr
	jc	proc_err	; if problem setting attribute
procnxt:
	call	getnext
	jc	ok_exit
	call	set_attr
	jc	proc_err	; if problem setting attribute
	jmp	procnxt

;	leave program.
proc_err:
	call	file_err	; tell user about problem
	jmp	short exit
ok_exit:
	xor	al,al		; no error
exit:
	mov	ah,4ch
	int	21h
begin	endp

set_plus proc
	cmp	byte ptr [di],'r'	; see if we found the '+r' option 
	je	set_ro		; found it. look for file name.
	cmp	byte ptr [di],'R'	; see if we have the '+R' option
	je	set_ro		; set file read_only
	cmp	byte ptr [di],'a'
	je	setArcOn
	cmp	byte ptr [di],'A'
	je	setArcOn
        cmp     byte ptr [di],'s'
        je      setSysOn
        cmp     byte ptr [di],'S'
        je      setSyson
        cmp     byte ptr [di],'h'
        je      setHidOn
        cmp     byte ptr [di],'H'
        je      setHidOn


l_err0:
	stc			; if no match, return carry set for error
	jmp	short set_px
set_ro:
	or	[attrib],RDONLY	; turn on read-only attribute
	or	[attrmsk],RDONLY
	jmp	set_pok

setArcOn:
	or	[attrib],ARCHIVE ; turn on archive attribute
	or	[attrmsk],ARCHIVE
        jmp     set_pok
setSyson:
	or	[attrib],SYSTEM	; turn on System attribute
	or	[attrmsk],SYSTEM
        jmp     set_pok
setHidOn:
	or	[attrib],HIDDEN	; turn on Hidden attribute
	or	[attrmsk],HIDDEN
        jmp     set_pok
set_pok:
	clc			; no error
	inc	di
	dec	cx		; advance command line pointer
set_px:
	ret
set_plus endp

set_minus proc
	cmp	byte ptr [di],'r'	; see if lower case
	je	set_rw		; yes. set file read/write
	cmp	byte ptr [di],'R'	; check for upper case
	je	set_rw
	cmp	byte ptr [di],'a'
	je	setArcOff
	cmp	byte ptr [di],'A'
	je	setArcOff
        cmp     byte ptr [di],'s'
        je      setSysOff
        cmp     byte ptr [di],'S'
        je      setSysOff
        cmp     byte ptr [di],'h'
        je      setHidOff
        cmp     byte ptr [di],'H'
        je      setHidOff

l_err1:
	stc			; signal error if no match found
	jmp	short set_mx
set_rw:
	and	[attrib],not RDONLY
	or	[attrmsk],RDONLY
	jmp	set_mok

setArcOff:
	and	[attrib],not ARCHIVE
	or	[attrmsk],ARCHIVE
        jmp     set_mok
setSysOff:
       	and	[attrib],not SYSTEM
	or	[attrmsk],SYSTEM
	jmp	set_mok
setHidOff:
      	and	[attrib],not HIDDEN
	or	[attrmsk],HIDDEN
	jmp	set_mok

set_mok:
	clc			; no error
	inc	di
	dec	cx		; advance command line pointer
set_mx:
	ret
set_minus endp


get_name proc			; process the file name
	mov	cx,[savecx]	; check to see if invalid chars are on the line
	mov	di,[fnptr]
	call	findfile	; findfile will locate 1st non-blank.
	mov	dx,di
	sub	dx,[fnptr]	; how far we've moved
	sub	[savecx],dx	; update path length
	mov	[fnptr],di	; and path location
	mov	dx,di
	inc	bx		; scan for '\'
	mov	al,byte ptr [bx]
	xor	ah,ah
	mov	cx,[savecx]
	mov	di,[fnptr]
	call	findparm
	jnc	copy_path	; no carry. found '\'. assume path found
	jmp	short findEnd

copy_path:
	mov	ax,[fnptr]	; beginning of path
	mov	[pathptr],ax
next_bs:
	mov	[pathlen],cx	; store possible path length
	mov	al,'\'
	call	findparm	; look for next '\'
	jnc	next_bs		; if found another, do it again

;	set path length & copy to path buffer.

	mov	cx,[savecx]	; number of chars in file name + path
	sub	cx,[pathlen]	; number of chars in file name alone
	mov	[pathlen],cx	; length of path
	neg	cx
	add	[savecx],cx	; reduce name length by path length
	neg	cx
	add	[fnptr],cx	; update file name pointer
	mov	si,[pathptr]	; beginning of path
	lea	di,[pathbuf]
	cld
	push	cs
	pop	es
rep	movsb			; copy the path
	mov	byte ptr [di],0	; terminate it with a null byte

findEnd:

	mov	di,[fnptr]	; beginning of file name
	mov	cx,[savecx]	; savecx has # of chars in file name
	
	push	ax
	push	di
	xor	ah,ah
	mov	al,SPACE	; use a space to check to see if there are
	call	findparm	; any more chars on the line. if so error!
	mov	byte ptr [di],0	; terminate name with null byte
	pop	di
	pop	ax
	jc	get_ok
	stc			; return error to caller
	jmp	short get_nx
get_ok:
	clc
get_nx:
	ret
get_name endp


fmt_name proc
	mov	si,[pathptr]
	or	si,si
	jz	fmt30		; if no path to process
fmt10:
	cmp	si,[fnptr]	; to file name yet?
	jae	fmt20		; if finished copying path
	lodsb
	stosb
	jmp	fmt10		; next char
fmt20:
fmt30:
	lea	si,[fname]	; copy file name
	call	copyaz		; copy ASCIIZ string
	ret
fmt_name endp

copyaz	proc
	lodsb			; next byte of file
	stosb			; store in output area
	or	al,al
	jnz	copyaz		; if not end of string, next char
	dec	di		; point di at null byte
copyax:
	ret
copyaz	endp

make_msg proc
	lea	di,[msgbuf]	; where rest of message goes
	mov	dx,[attrmsk]
	test	dx,RDONLY or ARCHIVE or SYSTEM or HIDDEN
	jnz	cset		; if we will look at some bits
	xor	cx,cx
	mov	cl,[fattri]	; file's attribute
	mov	dx,RDONLY or ARCHIVE or SYSTEM or HIDDEN	; attributes we care about
	lea	si,[nochgmsg]	; say no change, display states
	call	copyaz
	jmp	short rtst	; display messages
cset:
	lea	si,[setmsg]	; " set " message
	call	copyaz
	mov	cx,[attrib]	; attribute to set
rtst:
	test	dx,RDONLY	; do we care about read only bit?
	jz	atst		; if we don't care
	lea	si,[rdonlymsg]
	test	cx,RDONLY	; see if set r/o
	jnz	rmsg		; if is read only
	lea	si,[rdwrmsg]
rmsg:
	call	copyaz		; read only or read/write message
atst:
	test	dx,ARCHIVE	; do we care about archive bit?
;	jz	endmsg		; if we don't care
        jz      sytst
	lea	si,[archmsg]
	test	cx,ARCHIVE
	jnz	armsg		; if archive bit set
	lea	si,[noarchmsg]
armsg:
	call	copyaz		; archive or no archive message
sytst:
       	test	dx,SYSTEM	; do we care about archive bit?
        jz      hidtst
	lea	si,[sysmsg]
	test	cx,SYSTEM
	jnz	psysmsg		; if archive bit set
	lea	si,[nosysmsg]
psysmsg:
        call    copyaz
hidtst:
       	test	dx,HIDDEN	; do we care about archive bit?
        jz      endmsg
	lea	si,[hidmsg]
	test	cx,HIDDEN
	jnz	phidmsg		; if archive bit set
	lea	si,[nohidmsg]            
phidmsg:
        call    copyaz

endmsg:
	lea	si,[endline]
	call	copyaz		; end of line message
make_mx:
	ret
make_msg endp

addterm	proc
	mov	cx,size namebuf
	xor	al,al		; search for 0 byte
repne	scasb
	mov	byte ptr [di],'$'	; put in $ terminator
	ret
addterm	endp

set_attr proc
	lea	di,[namebuf]
	call	fmt_name
	xor	ch,ch
	mov	cl,[fattri]	; get the file's attribute
	mov	ax,[attrmsk]	; attributes to change
	not	ax
	and	cx,ax		; clear bits of interest
	not	ax
	and	ax,[attrib]	; only set bits which are on in mask
	or	cx,ax		; set desired attributes
	lea	dx,[namebuf]	; pointer to filename
	mov	ax,4301h	; set attribute function code
	test	[attrmsk],RDONLY or ARCHIVE or HIDDEN or SYSTEM
	jnz	set10		; if we will set some attribute
	xor	al,al		; if we will only get attributes
set10:
	int	TWENTY_ONE
	jc	setax
	lea	di,[namebuf]
	call	addterm		; add $ terminator
	lea	dx,[namebuf]
	call	print_msg	; print out file name
	call	make_msg
	lea	dx,[msgbuf]
	call	print_msg	; print message about this file
setax:
	ret
set_attr endp

file_err proc
	mov	ah,59h		; get extended error
	mov	bx,00h		; for dos 3.10
	int	TWENTY_ONE
	cmp	al,02h
	jz	set_err1
	cmp	al,03h
	jz	set_err1
	cmp	al,05h
	jz	set_err3

set_err1:
	lea	dx,err1
	jmp	short to_prt

set_err3:
	lea	dx,err3
	jmp	short to_prt

to_prt:
	call	print_msg
	mov	al,01h		; error level
	ret
file_err endp

syntax_err proc
	lea	dx,err2
	call	print_msg
	mov	al,02h		; syntax error code for terminate
	ret
syntax_err endp

print_msg proc
	push	si
	mov	si,dx		; pointer to string
	cld
prim10:
	lodsb
	or	al,al
	jz	primx
	mov	dl,al
	mov	ah,2
	int	TWENTY_ONE	; print char in dl to STDOUT, allow ^C check
	jmp	prim10		; next char
primx:
	pop	si
	ret
print_msg endp

getnext	proc
	mov	ax,4f00h	; find next file
	int	21h
	ret
getnext endp

get1st	proc
	mov	ax,4e00h	; find first file
        mov     cx,0000000000100111b ;set for hidden, system, r/o and archive
	int	21h
	ret
get1st	endp

moss	ends
	end	mosattr
