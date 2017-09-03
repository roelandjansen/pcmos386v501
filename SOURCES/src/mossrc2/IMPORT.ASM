        include page.inc
        title	IMPORT - MOS decompression and restore utility
;******************************************************************************
;*
;*			  MOS Development Specification
;*
;* Command type: EXTERNAL		Assigned to:
;* Command name: IMPORT 		Date assigned:
;*					Date completed:
;* Command format: IMPORT d:filename d:\path\ [/y]
;* Purpose:
;* Refer to:
;* Last Update:    4/30/90 - BWR
;*
;******************************************************************************
;
;------------------------------------------------------------------------;
; 02/11/87	SAH - Multi-directory, Archive Bit, Path in header
; 03/02/87	SAH - Security Information Tranfer Processing
; 05/05/87	SAH - Bug fixes and misc cleanup
; 05/12/87	RBR - Clean up messages
; 06/02/87	SAH - Fix Security Problem
; 07/12/87	SAH - change int 21h 80+ calls to Int 38h 00+
; 11/05/87	JSM - Use disk labels to know when to quit
; 11/11/87	JSM - /n switch for no directory tree searches
; 11/19/87	JSM - /O:count switch for importing old-style export
;		      disk sets, & update version number to 1.02
; 11/30/87	JSM - Fixed problem with files being left open, and
;		      handling files which cross disks when user has
;		      specified a subdirectory for the source file spec
;		      Set verison number to 1.03.  Revision mark [1].
; 11/03/88	RKG - Changes for easier foreign language translation
; 02/20/89	SAH - Converted INT 38h calls into INT SERVICES
; 09/07/89	SAH - Correction for import a:*.* e: creating dir e
; 09/20/89	SAH - Corrections for Translations.
; 11/27/89	BWR - Marked messages for foreign language
;		      translations.
; 4/30/90	BWR - Corrected problem with inability to IMPORT from
;		      a floppy other than drive A:.  IMPORT was originally
;		      obtaining the drive ID's from the default FCB's in the
;		      PSP.  A deficiency in MOS's handling of drive ID's
;		      on the command-tail (with respect to DOS) was causing
;		      it to misinterpret the source-drive specification.
;		      IMPORT requires input of the drive specifier anyway,
;		      so the code dealing with the FCB has been removed.
;
;------------------------------------------------------------------------
MOS	equ	01

tcb     segment at 7777h
        .xlist

if	MOS
	include options.inc
        include mostcb.inc
endif

        .list
tcb     ends

include import.pub

_text	segment 	word	public	'code'
	assume		CS:_text, DS:_text

	org	0100h
entry:
	jmp	start

stkrec  equ     21+22+1                 ; stack record size (even)
buflen  equ     32*1024                 ; input buffer size
outlen  equ     16*1024                 ; output buffer size

msgtsl	db	13,10,'PC-MOS File Import Utility (Version 4.10)' ;@@XLAT
	db	13,10,'(C) Copyright 1987-1990 The Software Link, Incorporated' ;@@XLAT
	db	13,10,'All Rights Reserved, Worldwide.          ' ;@@XLAT
        db      13,10,'$'

        even
version label   near
        include version.inc

badmos  db      13,10, 'Incorrect MOS Version.',13,10,'$' ;@@XLAT

        even
inhandle dw     0                       ; handle for input
ouhandle dw     1                       ; handle for output
bytsleft dw     2 dup(0)                ; bytes left in file
savecx   dw     0                       ; temp value

inbufadr dw     inbuffer                ; input buffer address
inbuflen dw     buflen                  ; input buffer length
inbufnb  dw     0                       ; input buffer number bytes contained
inbufix  dw     0                       ; input buffer index
nubflr   dw     0                       ; number unread bytes from last read

oubufadr dw     inbuffer+buflen         ; output buffer address
oubuflen dw     outlen                  ; output buffer length
oubufix  dw     0                       ; output buffer index

dstkadr  dw     inbuffer+buflen+outlen+20 ; directory stack address
dstkptr  dw     0                       ; directory stack pointer
dstksav  dw     0                       ; directory stack pointer saved

flopinfo label  byte                    ; DTA starts here
        db      21 dup(0)               ; reserved for DOS
flattr  db      0                       ; file attribute
        dw      0                       ; file time
        dw      0                       ; file date
flsize  dw      2 dup(0)                ; file size in bytes
flname  db      13 dup(0)               ; ASCIIZ filename

fileinfo label  byte
fiattr  db      0                       ; file attribute
fitime  dw      0                       ; file time
fidate  dw      0                       ; file date
fisize  dw      2 dup(0)                ; file size in bytes
finame  db      13 dup(0)               ; ASCIIZ filename
fidpath db      80 dup(0)		; ASCIIZ Sub-Directory Pathname
baseplen dw	0			;[1] ASCIIZ base path name length

;	Label stuff.

RDOATTR equ	01h			; read only attribute
SYSATTR equ	02h			; system attribute
HIDATTR	equ	04h			; hidden attribute
LBLATTR	equ	08h			; attribute for label files
DIRATTR	equ	10h			; directory attribute
ARCATTR	equ	20h			; archive attribute

lblinfo	struc
lblprf	db	'EX-'			; prefix for label
lbleflg	db	?			; end flag -- I is intermediate disk
					;	      L is last disk
lblsn	db	'0001'			; sequence number for label
lblinfo	ends

firstlbl db	1			; first label read in

chklbl	lblinfo	<"EX-","I","0000">
chkle	db	0			; NUL terminator

lblpath	db	"A:\"			; path plus name
lbldta	db	30 dup (?)		; dta for finding labels
ldnm	lblinfo	<?,?,?>			; name of found label
	db	(13 - size lblinfo) dup (?)	; fill out to 13 bytes
	db	0

; JSM 11/19/87 start changes

oldset	db	'N'			; dealing with old-style EXPORT set?
	even
diskct	dw	0			; number of disks in old-style set

; JSM 11/19/87 end changes

newpath  db     82 dup (0)
workpath db     'A:',80 dup (0)              
workdir  db     'A:',80 dup (0)         ; temporary storage for dir creation
buff03   db     10 dup (0)              ; security information buffer
buff03d  db     10 dup (0)              ; security information buffer (dir)
defclass db     0

olddir   db     'C:\'
curdir   db     64 dup (0)
curdrive db     0
 
        even
fidplen dw      0                       ; subdirectory len
fioff   dw      0                       ; finame offset
fiend   dw      0
woffset dw      offset ffwname
TCBSEG  dw      7777h                   ; tcb segment

ptrfn	dw	0			; pointer to start of file name
srcid	db	"A:",0,0		; source disk drive name

newflag	 db     'N'			
multidir db     'Y'                     ; Multi-directory
autoyes  db     'N'                     ; auto responce
wildcard db     '*.*', 0                ; wild card for directory searchs
sgnature db     'Xf'                    ; signature for eXported File
synerror db      0                      ; syntax error

dirchg	db	1			; non-zero if we must make a new 
					; directory

msgcrlf db      13,10,'$'

msgnotxf db     ' bypassed - not an exported file!$     ' ;@@XLAT

msgfile	db	"Now importing $   " ;@@XLAT
msgstart db	13,10,"     Import begins with disk " ;@@XLAT
startid	db	"   1",13,10,"$"

msgswap db      13,10
        db      13,10,'Please insert archive disk number   ' ;@@XLAT
msgsnbr db      '   1.   in drive  ' ;@@XLAT
msglbldrv db	"A: and press any key $       " ;@@XLAT
msgkey  db      'Press a key when ready... $           ' ;@@XLAT

msgabort db     13,10,'IMPORT is interrupted by user.        ' ;@@XLAT
         db     13,10,'The IMPORT process is incomplete.   ',13,10,'$' ;@@XLAT

msgdone db      13,10,'IMPORT is complete.    ',13,10,'$' ;@@XLAT

msgsyn  db      13,10,'Syntax error! ',13,10 ;@@XLAT
        db      'Correct Syntax: IMPORT  X:[Src. path]filename [Dst. path]' ;@@XLAT
        db      ' [/Y][/N][/O:nn]      ',13,10,'$' ;@@XLAT
msgdisk db      13,10,'Unexpected disk data!    ',13,10,'$' ;@@XLAT
msgopeni db     13,10,'Error opening input file!           ',13,10,'$' ;@@XLAT
msgopeno db     13,10,"Error opening output file!          ",13,10,'$' ;@@XLAT
msgclosi db     13,10,'Error closing input file!              ',13,10,'$' ;@@XLAT
msgcloso db     13,10,'Error closing output file!             ',13,10,'$' ;@@XLAT
msgread  db     13,10,'Error reading input!         ',13,10,'$' ;@@XLAT
msgwrite db     13,10,'Error writing output!        ',13,10,'$' ;@@XLAT
msgget03 db     13,10,'Error processing input file!             ',13,10,'$' ;@@XLAT
msgset03 db     13,10,'Error processing output file!            ',13,10,'$' ;@@XLAT

msgnpath db     13,10,'Destination Path not found!         ',13,10,'$' ;@@XLAT

msgronly db     13,10,'Read-only file - overwrite (Y/N) ?   $  ' ;@@XLAT
rubout   db     8,' ',8,'$'     
yesmsg	db	'Yes   ' ;@@XLAT
nomsg	db	'No    ' ;@@XLAT


ffname	db	'A:filename.ext',0      ; filename field for floppy opens ;@@XLAT
        db      66 dup (0)
ffwname db      'A:filename.ext',0      ; filename field for dir scan ;@@XLAT
ftname  db      11 dup ('?')            ; test file name mask
        even
pathlen dw      (?)                     ; pathlen
pathfn  dw      offset dstpath          ; address of filename portion of path
dstbpptr dw	offset dstpath+2	; pointer to place for file names
dstpath db      "A:",78 dup(0)          ; saves pathname from operands

compff  db      0ffh,0                  ; compression control info
compdata db     0,0
        db      0                       ; trash byte must follow compdata
        page
;------------------------- startup logic ----------------------------;

start   proc   near

	call	chkver
	call	setup
;-------------------- display response message ----------------------;

        push     ax
        push     dx
	call	newdisk			; new label for each disk
        cmp      [autoyes], 'Y'
        je       respdone
IFDEF	OLDSTUFF
	lea      dx, [msgswap]
	call     display
        lea      dx, [msgkey]
        call     display
        mov      ah, 1
        int      21h
        lea      dx, [msgcrlf]
        call     display

respdone:
        inc     byte ptr [msgsnbr+1]
ENDIF
        pop     dx
        pop     ax
diskloop:
	call	nxtlbl
respdone:
	call	getlbl
        call    domain                  ; do main loop
	call	lastdisk
	jne	moredisk

        lea     dx,[msgcrlf]            ; new line
        call    display
        lea     dx,[msgdone]
        call    display
        xor     al, al
        call    doquit
moredisk:
	call	newdisk			; new label for each disk
	jmp	short diskloop

start	endp


;----------------------- end of directory ---------------------------;

doquit	proc

        push    ax      

;       reset current drive and directory

        mov     dl, [curdrive]
        mov     ah, 0eh
        int     21h
        lea     dx, [olddir]
        mov     ah, 3bh
        int     21h

if      MOS
        mov     es,[TCBSEG]
        assume  es:tcb                  ; reset to original default
        mov     al, [defclass]
        mov     es:[TCBCDFT], al
endif
        pop     ax
        mov     ah, 4ch
        int     21h
doquit	endp

;------------------------ check MOS version number -----------------------;

chkver	proc
if      MOS
;
;       Routine to check mos version
;
        mov     ah, 30h
        mov     bx, ax
        mov     cx, ax
        mov     dx, ax
        int     21h
        cmp     ax, word ptr [version]
        je      mosok
        lea     dx, badmos
        mov     ah, 9
        int     21h
        mov     ax, 4c01h
        int     21h
endif
mosok:
	ret
;
;       all ok continue with bussiness
;

chkver	endp

;---------------------- setup for importing -------------------------;

setup	proc
	lea	dx, uabort		;Set CTRL-C handler address.
        mov     ax, 2523h
        int     21h

	lea	dx, msgtsl		;Display copyright.
        call    display
;
;	Get current drive and directory
;
	mov	ah, 19h 		;Get current drive. (0 = A)
        int     21h
	mov	curdrive, al
	mov	dl, al			;1 = A for Get current directory.
        inc     dl
        add     al, 'A'
	mov	olddir, al
	mov	dstpath[0], al
;
;   Get the current directory on the current drive.
;
        lea     si, curdir
        mov     ah, 47h
        int     21h

if  MOS        
        mov     ah, 04h                 ; save default output class
        mov     bx, -1                  ; from current TCB
	int	SERVICES
        assume  es:tcb
        mov     [TCBSEG], es
        mov     al, es:[TCBCDFT]
        mov     [defclass], al
	mov	ax, cs
	mov	es, ax
        assume  es:nothing
endif
;
;  Move the DTA away from the default location (command tail) so we
; will be able to parse the command line.
;
	mov	ah, 1Ah 		 ; set DTA
	lea	dx, flopinfo
        int     21h

;----------------------check for options --------------------;

        cld
        mov     al, byte ptr ds:[80h]   ; get length
        xor     ah, ah
        mov     si, 81h
        add     si, ax                  ; point to tail
	inc	si

mdcloop:
        dec     si                      ; scan backwards for a /
        cmp     si, 81h
        jb      mdcskip
        cmp     byte ptr ds:[si], '/'
        jne     mdcloop

        mov     al, ds:[si+1]

; JSM 11/19/87 start changes

	cmp	al,'z'
	ja	nolower
	cmp	al,'a'
	jb	nolower
	sub	al,'a' - 'A'		; convert lower case to upper case
nolower:
	cmp	al,'N'			; ignore subdirectories?
	jne	mdcychk
	mov	[multidir],'N'		; no multiple directory stuff
	jmp	mdcnext
mdcychk:
        cmp     al, YesMsg             ; auto response?
        jne     mdcochk
        mov     [autoyes], 'Y'         ; indicate auto responced
	jmp	mdcnext
mdcochk:
	cmp	al,'O'
	jne	mdcnext			; if another option
	mov	[oldset],'Y'		; old export set to import
	cmp	byte ptr [si+2],':'	; option must be form /o:nn
	jne	mdsynerr		; if not, report error
	push	si
	add	si,3			; where the number should be
	call	str2numdw		; convert number to binary
	mov	di,si			; end of number
	dec	di			; points to last byte
	dec	di			; - 1
	pop	si
	jc	mdsynerr		; if unsuccessful conversion
	or	dx,dx
	jnz	mdsynerr		; must be 1 - 32767 disks in set
	or	ax,ax
	jle	mdsynerr		; must be 1 - 32767 disks in set
	mov	[diskct],ax		; number of disks in set
	mov	al,' '
mdoblk:					; blank out entire switch
	cmp	si,di
	jae	mdcnext			; if done
	mov	[si],al			; blank out the next byte
	inc	si
	jmp	mdoblk
mdcnext:
	mov	word ptr [si],'  '	; blank out option
	jmp	mdcloop
mdsynerr:
	jmp	errsyn

; JSM 11/19/87 end changes

mdcskip:

;-------------------- look for filename operand ---------------------;

        cld
        mov     si,0080h
lffolp1:
        inc     si
	cmp	byte ptr ds:[si], ' '   ; scan for nonblank
        jbe	lffolp1

        cmp     byte ptr ds:[si+1],':'  ; check syntax
        je      noerr
        jmp     errsyn
noerr:
;
;   Get the source drive into all workspaces.
;
	mov	al, [si]	;Get the drive specifier.
	and	al, 0DFh	;Convert to upper case.
	mov	ffname, al
	mov	ffwname, al
	mov	workpath, al
	mov	workdir, al
	inc	si

lffolp2:
        inc     si
	cmp	byte ptr ds:[si], ' '   ; scan for nonblank
        jbe     lffolp2

	mov   dx, si		       ; save start address in dx
sfoloop:
        lodsb                           ; find end and terminate it with 0
        cmp     al,20h
        ja      sfoloop
        mov     [fiend], si
        dec     si
        mov     byte ptr ds:[si],0

	call	edp			; extract directory path name
	call	gdp			; get destination path
	call	mfm			; make file mask
	ret

setup	endp

; JSM 11/19/87 start changes

;-----------------------------------------------------------------------;
;		               Str2NumDW				;
;    converts the numeric string at ds:si to a value in dx:ax, the 	;
;    CY flag will be set for errors or overflow out of dx:ax		;
;-----------------------------------------------------------------------;

Str2NumDW PROC
	push	bx
	push	cx
	push	di
	push	bp
	xor	ah,ah
	xor	dx,dx
	cld
	lodsb		; get the first digit
	cmp	al,'0'
	jb	Sn2
	cmp	al,'9'
	ja	Sn2
	sub	al,'0'	; convert from ascii to numeric
	mov	bp,ax	; save intermeadiate value in bp:di
	xor	di,di
Sn1:
	lodsb		; get next digit
	cmp	al,'0'
	jb	Sn3
	cmp	al,'9'
	ja	Sn3
	sub	al,'0'	; if 0-9, convert and mul the previous
	xchg	ax,bp	; value in bp:di by 10
	xchg	dx,di

	sal	ax,1	; multiply by 10 by the equation
	rcl	dx,1	; 10X = 8X + 2X
	jc	Sn4
	mov	bx,ax
	mov	cx,dx
	sal	ax,1
	rcl	dx,1
	jc	Sn4
	sal	ax,1
	rcl	dx,1
	jc	Sn4
	add	ax,bx
	adc	dx,cx
	jc	Sn4

	xchg	ax,bp
	xchg	dx,di
	add	bp,ax	; add the new digit to the tally
	adc	di,dx
	jc	Sn4
	jmp	Sn1
Sn3:
	mov	ax,bp
	mov	dx,di
	clc
Sn4:
	pop	bp
	pop	di
	pop	cx
	pop	bx
	ret
Sn2:
	stc
	jmp	Sn4
Str2NumDW ENDP

; JSM 11/19/87 end changes

;--------------------- Extract directory path name -----------------------;

edp	proc

	std
edp10:
        cmp     si,dx
        jb      edp30
	lodsb	                        ; scan backwards for a \ or :
	cmp	al,':'
	je	edp20
        cmp     al,'\'
        jne     edp10
edp20:
	inc	si
edp30:
	inc	si
	cld
	mov	[ptrfn],si		; beginning of file name
	mov	[fioff],si		; beginning of source spec
	mov	si,dx
	mov	al,[si-2]		; source drive spec
edp40:
	mov	byte ptr [srcid],al	; source disk drive
	mov	di,offset fidpath	; where the path goes
edp100:
	cmp	si,[ptrfn]		; is there some path stuff?
	je	edp110			; if path copied
	lodsb
	stosb
	jmp	edp100
edp110:
	xor	al,al
	stosb				; terminate path with NUL
	dec	di			; point di at terminator byte
	sub	di,offset fidpath	; determine length of path
	mov	[fidplen],di
	mov	[baseplen],di		;[1] remember starting path length
	ret
edp	endp

;------------------------ make file mask ------------------------;

mfm	proc
	mov	si,[fioff]		; pointer to file name
	mov	di,offset ftname	; where the mask goes
	mov	cx,8

;	Process 8 character file name.

mfm10:
	lodsb
	cmp	al,'*'
	je	mfm30			; special processing for *
	cmp	al,'.'			; end of extension?
	je	mfm25			; leave loop if .
	or	al,al			; check for end
	jz	mfm20
	cmp	al,'a'
	jb	mfm13			; if not lower case character
	cmp	al,'z'
	ja	mfm13			; if not lower case character
	sub	al,'a' - 'A'		; convert to upper case
mfm13:
	stosb				; if normal character, copy it
	loop	mfm10
mfm15:
	lodsb
	cmp	al,'.'
	je	mfm40			; if finished with file name
	or	al,al
	jnz	mfm15			; if more file name stuff
mfm20:
	add	cx,3			; including extension
	mov	al,' '			; fill rest of name with spaces
rep	stosb
	jmp	short mfmx		; fill extension, too
mfm25:
	mov	al,' '			; fill only file name with spaces
rep	stosb
	jmp	short mfm40		; process extension
mfm30:
	mov	al,'?'			; fill rest of name with ?
rep	stosb
	jmp	mfm15			; read stuff up to period

;	Process 3 character extension.

mfm40:
	mov	cx,3			; number of chars in extension
	mov	ah,' '			; default fill char
mfm50:
	lodsb
	cmp	al,'*'			; special stuff for wild card
	je	mfm60
	or	al,al			; check for end
	jz	mfm70
	cmp	al,'a'
	jb	mfm55			; if not lower case character
	cmp	al,'z'
	ja	mfm55			; if not lower case character
	sub	al,'a' - 'A'		; convert to upper case
mfm55:
	stosb				; copy the char
	loop	mfm50
mfm60:
	mov	ah,'?'			; fill char for wild card
mfm70:
	mov	al,ah
rep	stosb				; fill extension with fill character

mfmx:
	ret
mfm	endp

;--------------------- get destination pathname -------------------;

gdp	proc
	mov	di,si			; where to start looking
	mov	cl,ds:[80h]		; length of command line
	xor	ch,ch
	sub	si,81h			; bytes checked so far
	sub	cx,si			; bytes to check
	mov	al,':'
gdp5:
	jcxz	gdpx			; if finished looking
repne	scasb
	jnz	gdpx			; if no : found
	cmp	word ptr [di-3],'o/'	; parameter instead of disk?
	je	gdp5			; if parameter, keep looking
	cmp	word ptr [di-3],'O/'	;[1]
	je	gdp5			;[1]
	lea	si,[di-2]		; start copy with disk id
	mov	di,offset dstpath	; where the path goes (if any)
gdp10:
	lodsb
	cmp	al,' '			; quit on white space
	jbe	gdp20			; if we found white space
	cmp	al,'/'			; quit on slash, too
	je	gdp20
;BWR 4/30/90
	cmp	al, 0Dh 		; Quit at end-of-line.
	je	gdp20
	cmp	al, 0
	je	gdp20
;BWR 4/30/90
	stosb				; Write next character.
	jmp short gdp10

gdp20:
	mov	dx,offset dstpath
	mov	si,dx
	cmp	byte ptr ds:[si+1],':'
	jne	gdp25
	cmp	byte ptr ds:[si+2],00h
	je	gdp30
gdp25:
	mov	ah,39h			; Create specified subdirectory.
	int	21h
	mov	ah,3Bh			; Make it the current directory.
	int	21h

gdp30:
	xor	al,al
	stosb				; terminate path with nul
	dec	di
	mov	[dstbpptr],di		; where all destination paths start
gdpx:
	ret
gdp	endp

;------------------------- main loop --------------------------------;


domain	proc
        lea     di, workpath+2
        lea     si, fidpath             ; transfer current directory
        mov     cx, [fidplen]
        rep     movsb
	cmp	byte ptr [di-1],':'	; if no path
	je	sdirskip
	cmp	byte ptr [di-1],'\'	; if path ends with \
	je	sdirskip
        mov     al, '\'
        stosb
        
sdirskip:
        lea     si, wildcard
        mov     cx, 4
        rep     movsb

	call	setpath			; set output path

        lea     dx, workpath            ; set to wild card match
	mov	ah,4Eh			; find first matching file
        mov     cx,16h                  ; include hidden and system files
        jmp     short dlentry           ; enter directory scan loop

;----------------- process next input directory entry ---------------;

dirloop label   near
        mov     ah,4fh                  ; find next matching file
dlentry:
        int     21h
        jc	dlend                   ; error check
        test    byte ptr [flattr], 10h          ; directory??
        jnz     dldent
 	call	dlfile
	jmp	dirloop
dldent:
	call	dldir
dleloop:
	jmp	dirloop
dlend:
        ret
domain	endp


;------------- test and scan for directory recursively ----------------;

dldir	proc
        cmp     byte ptr [flname], '.'          ; . or ..
        je      dldjix                          ; next dir
        cmp     byte ptr [MultiDir], 'Y'        ; Multi-Directory
        je      dlscdir
dldjix:
	jmp	dldix				; leave routine

;----------------------  set current directory ----------------------;
dlscdir:        
        lea     di, [fidpath]           ; point at end of current dir
        add     di, [fidplen]           ; and path len
        cmp     di, offset [fidpath]
        je      scdskip
	cmp	byte ptr [di-1],'\'	; if \ already there
	je	scdskip
	cmp	byte ptr [di-1],':'	; if \ not needed
	je	scdskip
        mov     al, '\'
        stosb
        inc     [fidplen]

scdskip:
        xor     cx, cx
        lea     si, [flname]            ; get directory name

scdloop:
        lodsb
        or      al, al
        jz      scddone
        stosb
        inc     cx
        cmp     cx, 13
        jb      scdloop

scddone:
        xor     al, al
        stosb
        add     [fidplen], cx

;-------------------- save dta  on internal stack -------------------;

        mov     di, [dstkadr]           ; save dta on internal stack
        add     di, [dstkptr]
        lea     si, flopinfo
        mov     cx, STKREC/2
	cld
        rep     movsw
        add     [dstkptr], STKREC       ; increment stack ptr by len

	mov	[dirchg],1		; signal we're in a new directory
        call    domain

;---------------------- get dta from internal stack -----------------;

        sub     [dstkptr], STKREC       ; decrement int stack ptr
        mov     si, [dstkadr]           ; get dta from int stack
        add     si, [dstkptr]
        lea     di, flopinfo
        mov     cx, STKREC/2
	cld
        rep     movsw


;---------------------- reset current directory ---------------------;
        
        mov     si, [fidplen]
        
rscdir:
        mov     al, [si+fidpath]                ; get byte
        cmp     al, '\'                         ; backslash
        je      rsdone
	cmp	al,':'
	jne	rsechk				; continue backing unless :
	inc	si				; don't kill : character
	jmp	short rsdone
rsechk:
	cmp	si,[baseplen]			;[1] end-of-line
        je      rsdone
        dec     si
        jmp     short   rscdir

rsdone:
        mov     byte ptr [si+fidpath], 0        ; clear byte

rsdone2:
        mov     [fidplen], si           ; save length
        
;----------------- process next input directory entry ---------------;
dldix:
        ret
dldir	endp


;------------------ setup path for directory search -----------------;

setpath	proc
        lea     si, fidpath             ; transfer current directory
        lea     di, dstpath + 2
        mov     cx, [fidplen]
rep     movsb
	cmp	byte ptr [di-1],'\'
	je	setp10
	cmp	byte ptr [di-1],':'
	je	setp10
        mov     al, '\'
        stosb
setp10:
        mov     [pathfn], di
        mov     si, [fioff]             ; add file name
        mov     cx, 13
rep     movsb
	ret
setpath	endp

dlfile	proc

;       test file match since we use wild cards to get directories

        lea     si, flname
        lea     di, ftname
        xor     cx, cx

dtestlp:
        lodsb
        or      al, al
        jz      dirok
        cmp     al, 0dh
        je      dirok
        cmp     al, '.'         ; test for extension
        je      dtestnt
        mov     ah, byte ptr [di]
        cmp     ah, '?'         ; wildcard specification
        je      dtestok
        cmp     al, ah          ; check it out
        je      dtestok

dtestbd:
        jmp     dlfix           ; failed

dtestnt:
        cmp     cl, 7
        jae     dtestsk
        mov     ch, 7
        sub     ch, cl
        xchg    cl, ch
        xor     ch, ch

dtestvr:
        mov     al, byte ptr [di]
        cmp     al, '?'
        je      dtestvo
        cmp     al, ' '
        jne     dtestbd

dtestvo:
        inc     di
        loop    dtestvr

dtestsk:
        lea     di, ftname+7    ; setup for extension

dtestok:			; next character
        inc     di
        inc     cl
        jmp     short dtestlp

;       pass directory test

dirok:
        call    makenm                  ; create name

        call    showname                ; entertain the operator

if      MOS
        push    es
        push    cs
        pop     es
        lea     dx,[ffname]
        lea     bx,[buff03]
        mov     ax,0300h                ; get security information
	int	SERVICES
        jnc     $+5
        jmp     errget03

        mov     es, [TCBSEG]            ; set default class as class read
        assume  es:tcb
        mov     al, byte ptr [buff03+1]
        mov     byte ptr es:[TCBCDFT], al
        pop     es
        assume  es:nothing
endif

        call    openin                  ; open input file
	jnc	filenotmt		;JSM 11/19/87 if file not 0-length
	cmp	[oldset],'Y'		;JSM 11/19/87
	jne	filenotmt		;JSM 11/19/87 if not an old-style set
	mov	bx,[inhandle]		;[1] close the file
	mov	ah,3eh			;[1]
	int	21h			;[1]
	jmp	dlfix			;JSM 11/19/87 old, ignore empty files
	
filenotmt:
        mov     cx,2                    ; read signature
        lea     dx,[fiattr]
        call    rdfloppy
        mov     ax,word ptr [fiattr]    ; check for valid signature
        cmp     ax,word ptr [sgnature]
        je      sigisok
        lea     dx,[msgnotxf]           ; tell them file is not exported
        call    display
        jmp     rlbypass                ; and skip this file
sigisok:
        mov     cx,22                   ; read file directory info
        lea     dx,[fiattr]
        call    rdfloppy

        mov     di,[pathfn]             
        lea     si,[flname]             ; create asciiz string for output open
        mov     cx,13                   
        cld
        rep     movsb

        lea     dx,[dstpath]               ; get attribute
        mov     ax, 4300h
        int     21h
        jc      attrok
        test    cx, 1                   ; read-only
        jz      attrok
        lea     dx, msgronly            
        mov     ah, 9
        int     21h

roloop:
        mov     ah, 01
        int     21h
        and     al, 0DFH
        cmp     al, [yesmsg]
        je      attrovr
        cmp     al, [nomsg]
        je      roabort
        lea     dx, rubout
        mov     ah, 9
        int     21h
        jmp     short roloop

roabort:
        lea     dx, msgcrlf
        mov     ah, 9
        int     21h
        jmp     dlfix

attrovr:
        lea     dx,msgcrlf
        mov     ah, 9
        int     21h

attrok:
        lea     dx,[dstpath]               ; reset attribute
        xor     cx, cx
        mov     ax, 4301h
        int     21h

        lea     dx,[dstpath]               ; delete entry
        mov     ah,41h
        int     21h

        mov     ah,3ch                  ; create output file
        lea     dx,[dstpath]
        xor     cx, cx                  ; no out attribute
        int     21h
        jnc     $+5
        jmp     erropeno
        mov     [ouhandle],ax

        mov     ax,[fisize]             ; set starting byte count
        mov     [bytsleft],ax
        mov     ax,[fisize+2]
        mov     [bytsleft+2],ax

        mov     byte ptr [compff+1],0   ; init compression byte value
	call	readloop
dlfix:
	ret
dlfile	endp

readloop proc
        cmp     [bytsleft+2],-1         ; check for end
        je      jrlend
        cmp     [bytsleft+2],0 
        jne     rlcont
        cmp     [bytsleft],0 
        jne     rlcont
jrlend:
        jmp     rlend
rlcont:
        mov     cx,2                    ; read 2 bytes
        lea     dx,[compdata]
        call    rdfloppy

        mov     cx,word ptr [compdata]  ; uncompressed byte count in cl
        cmp     cl,0ffh                 ; setting a new compression byte? 
        jne     rlnocb
        mov     byte ptr [compff+1],ch  ; yes, set it
        jmp     readloop
rlnocb:
        mov     ch,0                    ; read uncompressed data
        push    cx                      ; save its length 
        mov     dx,[oubufadr]           ; set read data address
        add     dx,[oubufix]
        call    rdfloppy
        pop     di

        mov     cl,byte ptr [compdata+1] ; now zap in compressed bytes
        mov     ch,0
        mov     dx,di                   ; compute total length in dx
        add     dx,cx
        add     di,[oubufadr]           ; compute target address
        add     di,[oubufix]
        mov     al,byte ptr [compff+1]
        cld
        rep     stosb

        sub     [bytsleft],dx           ; compute remaining length
        sbb     [bytsleft+2],0

        add     dx,[oubufix]            ; new buffer length
        mov     [oubufix],dx
        cmp     dx,[oubuflen]           ; is it full?
        jb      readloop                ; no, jump
        call    flushout                ; yes, flush it
        jmp     readloop

;------------------ end of file - close and do next -----------------;

rlend:
        call    flushout                ; flush output buffer

        mov     ax,5701h                ; set date/time of output file
        mov     bx,[ouhandle]
        mov     cx,[fitime]
        mov     dx,[fidate]
        int     21h

        mov     ah,3eh                  ; close output file
        mov     bx,[ouhandle]
        int     21h
        jnc     $+5
        jmp     errcloso

        lea     dx,[dstpath]               ; set file attribute of file
        mov     ax, 4301h
        xor     cx, cx
        mov     cl,[fiattr]
        int     21h

if      MOS
        push    es
        push    cs
        pop     es
        lea     dx,[dstpath]
        lea     bx,[buff03]
        mov     ax, 0301h               ; set security information
	int	SERVICES
        jnc     $+5
        jmp     errset03
        pop     es
endif

rlbypass label	near
        mov     ah,3eh                  ; close input file
        mov     bx,[inhandle]
        int     21h
        jnc     $+5
        jmp     errclosi
        ret		                ; go do next file
readloop endp

flushout proc   near
        mov     cx,[oubufix]            ; length to write
        jcxz    floexit                 ; skip if zero
        mov     ah,40h
        mov     bx,[ouhandle]
        mov     dx,[oubufadr]
        int     21h
        jnc     $+5
        jmp     errwrite
        mov     [oubufix],0
floexit:
        ret
flushout endp
        page

        page
;----------------------- get input disk label ----------------------------;

getlbl	proc   near
get10:
	call	flbl			; find an old label & deal with it
	je	glblx			; if it was the label we expected
	call	nxtlbl			; say we want right disk
	jmp	get10
glblx:
	mov	[firstlbl],0		; found a good label
	ret
getlbl	endp

;---------------------- display ASCIIZ string ----------------------;

strdsp	proc
	cld
strd10:
        lodsb
        or      al, al
        jz      strd20
        mov     dl, al
        mov     ah, 2
        int     21h
        jmp     strd10
strd20:
	ret
strdsp	endp

;---------------------- find a disk label ---------------------------;

flbl	proc   near
	cmp	[oldset],'Y'		; JSM 11/19/87 old disk set?
	jne	flbl5			; JSM 11/19/87 if not old, continue
	jmp	flblx2			; JSM 11/19/87 if old, exit w/OK status
flbl5:					; JSM 11/19/87
	mov	ah,2fh			; get current DTA
	int	21h
	push	bx			; save offset (we know segment)
	mov	dx,offset lbldta
	mov	ah,1ah
	int	21h			; switch to different dta

	mov	di,offset lblpath	; put label path here
	mov	ax,word ptr [ffname]
	stosw				; disk drive for label
	mov	al,'\'
	stosb				; path for label
	mov	si,offset wildcard	; file name for search
	call	strcpy
	mov	ah,4eh			; find a label
	mov	cx,LBLATTR
	mov	dx,offset lblpath
	int	21h			; find a label
	jnc	flbl10			; if a label found
	mov	ah,1
	or	ah,ah			; clear Z flag
	jmp	short flblx

;	Is it the label we expect?

flbl10:
	mov	di,offset chklbl.lblprf	; compare the old label's name
	mov	si,offset ldnm		; with new label's name
	mov	cx,lbleflg - lblprf
repe	cmpsb				; check prefix
	jne	flbl15			; if different
	lodsb
	inc	di
	cmp	al,'I'
	je	flbl12
	cmp	al,'L'
	jne	flbl15
flbl12:
	mov	cx,chkle - chklbl.lblsn
repe	cmpsb				; check number
	je	flblx
flbl15:
	cmp	[firstlbl],1
	jne	flblx

;	If first time, see if it's a label made by EXPORT & in different order

	mov	di,offset chklbl.lblprf
	mov	si,offset ldnm
	mov	cx,lbleflg - lblprf
repe	cmpsb				; prefix same as ours?
	jne	flblx			; if different, ignore it
	lodsb				; end flag byte
	cmp	al,'I'			; end flag must be I or L
	je	flbl20
	cmp	al,'L'
	jne	flblx			; neither I nor L, ignore it
flbl20:
	mov	cx,chkle - chklbl.lblsn	; four bytes of serial number
flbl30:
	lodsb				; make sure serial number is OK
	cmp	al,'0'
	jb	flblx			; if not a numeral
	cmp	al,'9'
	ja	flblx			; if not a numeral
	loop	flbl30			; next one

;	It's ours, copy label into our label.

	mov	si,offset ldnm
	mov	di,offset chklbl
	call	strcpy
	mov	si,offset chklbl.lblsn
	mov	di,offset startid
	mov	cx,chkle - chklbl.lblsn
	call	copydn			; tell user starting disk number
	mov	dx,offset msgstart
	call	display
	cmp	si,si			; set Z flag
	jmp	short flblx

;	Compare label with ours

flblx:
	pop	dx			; restore original dta
	mov	ah,1ah
	int	21h
flblx2:					; JSM 11/19/87
	ret
flbl	endp

;----------------------- request new disk ----------------------------;

nxtlbl	proc
	mov	si,offset chklbl.lblsn
	mov	di,offset msgsnbr
	mov	cx,chkle - chklbl.lblsn
	call	copydn			; copy disk number into message

	mov	al,byte ptr [ffname]
	mov	byte ptr [msglbldrv],al
	mov	dx,offset msgswap	; please put archive disk #
	call	display			; in drive x: and press any key
	mov	ax,0c01h
	int	21h
	mov	dx,offset msgcrlf	; end line
	call	display
	ret
nxtlbl	endp

;----------------------- copy disk number -------------------------;

copydn	proc
	cld
cpdn10:
	lodsb
	cmp	al,'0'
	jne	cpdn20
	mov	al,' '
	stosb
	loop	cpdn10
	jmp	short cpdn30
cpdn20:
	stosb
rep	movsb

cpdn30:
	ret
copydn	endp

;----------------------- signal new disk ----------------------------;

newdisk	proc	near
	mov	si,offset chkle - 1
					; last byte of serial num
	mov	cx,chkle - chklbl.lblsn	; do length of lblsn digits
	call	incstr			; increment next expected disk ID
	cmp	[oldset],'Y'		; JSM 11/19/87
	jne	newdx			; JSM 11/19/87 if new set, exit
	dec	[diskct]		; JSM 11/19/87 if old, 1 less disk
newdx:					; JSM 11/19/87
	ret
newdisk	endp

;------------------- increment decimal ASCII string -----------------;

incstr	proc	near
	std				; back up on lodsb
	mov	ah,1			; always increment the first one
	jmp	short incs30
incs10:
	cmp	al,'9'
	jbe	incs20
	inc	ah
	mov	al,'0'
incs20:
	mov	[si+1],al		; save incremented number
incs30:
	lodsb
	or	ah,ah			; increment this one?
	jz	incs40
	inc	al
	xor	ah,ah
	loop	incs10
incs40:
	cld
	ret
incstr	endp

;--------------------- check for last disk ------------------------;

lastdisk proc
	cmp	[oldset],'Y'		; JSM 11/19/87
	jne	lstd10			; JSM 11/19/87 if new set
	cmp	[diskct],0		; JSM 11/19/87 to end of set?
	jg	lstdx			; JSM 11/19/87 some left
	cmp	al,al			; JSM 11/19/87 if < 0, return last one
	jmp	short lstdx		; JSM 11/19/87 set Z flag if last
lstd10:					; JSM 11/19/87
	cmp	[ldnm.lbleflg],'L'	; end disk of set?
lstdx:					; JSM 11/19/87
	ret
lastdisk endp

;---------------------- copy ASCIIZ string ----------------------;

strcpy	proc    near
	cld
strc10:
	lodsb
	stosb
	or	al,al
	jnz	strc10
        ret
strcpy	endp

        page
;------------------------ floppy input ------------------------------;

rdfloppy proc   near
        jcxz    rdfret                  ; exit if count is zero
        mov     ax,[inbufnb]            ; compute bytes left in buffer
        sub     ax,[inbufix]
        jbe     rdfmore                 ; if none, go get some
        cmp     cx,ax                   ; enough to satisfy the request?
        jbe     rdfskip1                ; yes, jump
        xchg    cx,ax                   ; no, get what's there
        sub     ax,cx                   ; save number of unread bytes
        jmp     short rdfskip2
rdfskip1:
        xor     ax,ax                   ; indicate no unread bytes
rdfskip2:
        mov     si,[inbufadr]
        add     si,[inbufix]            ; source address
        mov     di,dx
        add     dx,cx                   ; dx saves next target address
        add     [inbufix],cx            ; update input buffer index
        inc     cx
        shr     cx,1                    ; length in words
        cld
        rep     movsw
        mov     cx,ax
        or      cx,cx
        jnz     rdfloppy                ; do more if partial read
rdfret:
        ret
rdfmore:
        push    dx
        push    cx

        cmp     [nubflr],0              ; any unread bytes from last read?
        jne     rdfswap                 ; yes, time to swap diskettes
rdfsback:
        mov     ah,3fh                  ; read
        mov     bx,[inhandle]
        mov     cx,[inbuflen]
        mov     dx,[inbufadr]
        int     21h
        jnc     $+5
        jmp     errread

        mov     [inbufnb],ax            ; save number of bytes actually read
        mov     [inbufix],0             ; reset index

        sub     cx,ax                   ; compute number unread bytes
        mov     [nubflr],cx             ; nonzero here means end of file

        pop     cx
        pop     dx
        jmp     rdfloppy

rdfswap:
        mov     ah,3eh                  ; close input file
        mov     bx,[inhandle]
        int     21h
        jnc     $+5
        jmp     errclosi

	call	newdisk			; prepare for new disk
	call	nxtlbl			; ask for new diskette
	call	getlbl			; get new disk's label

rdfsdnok:
        xor     ax, ax                  ; zap! dta internal stack
        xchg    ax, [dstkptr]
        mov     [dstksav], ax
        mov     cx,[baseplen]		;[1] start copying this much
        mov     ax, word ptr [workpath]
        mov     word ptr [newpath], ax
	mov	[newflag], 'N'
 
newloop:
        lea     si, fidpath             ; generate immed. path for dta's
        add     si, cx                  ; assumes to end 0
	cmp     [newflag], 'Y'
	je      newloop1
	mov	[newflag], 'Y'
	inc     cx
	jmp     newdone

newloop1:
        inc     cx                      ; increment counter
        lodsb
        or      al, al
        jz      newdone
        cmp     al, '\'                 ; switch time
        jne     newloop1

newdone:
        mov     [savecx], cx            ; save counter
        dec     cx	
        lea     si, fidpath
        lea     di, newpath+2
	cld
        rep     movsb
	cmp	byte ptr [di-1],'\'	;[1] path already end with \?
	jne	news10			;[1] no, do as normal
	dec	di			;[1] rewrite the \
news10:					;[1]
        mov     ax, '*\'
        stosw
        mov     al, '.'
        stosw
        xor     al, al
        stosb

;-------------------- find next directory entry ---------------------;

newnext:
        mov     ah,4eh                  ; find first matching file
        mov     cx,16h                  ; include hidden and system files
        lea     dx,newpath

newloop2:
        int     21h
        jnc     $+5                     ; error check
        jmp     errdisk

;---------------------------------------------------------------;

newcont:
        test    byte ptr [flattr], 10h  ; test for subdirect .
        jz      newfile
        cmp     byte ptr [flname], '.'
        jne     newfile	
        mov     ah, 4fh                 ; next..
        jmp     short newloop2

newfile:

;-------------------------------------------------------------------;

        cmp     byte ptr [multidir], 'Y'
        jne     rdfshow
        mov     cx, [dstkptr]
        cmp     cx, [dstksav]           ; are we there
        jae     rdfshow

;----------------- save dta on internal stack ----------------------;

	mov	di, [dstkadr]
	add     di, [dstkptr]
	lea     si, flopinfo
	mov	cx, STKREC/2
	cld
	rep	movsw
	add     [dstkptr], STKREC

;-------------------------------------------------------------------;

        mov     cx, [savecx]
        jmp     newloop

rdfshow:
        call    showname                ; list filename to screen
        call    openin                  ; open new input file

        jmp     rdfsback                ; return from diskette swap
rdfloppy endp
        page
;------------------------ open floppy input file --------------------;

openin  proc    near
        mov     ax,3d00h                ; open input file
        lea     dx,[ffname]
        int     21h
        jnc     $+5 
        jmp     erropeni
        mov     [inhandle],ax
        xor     dx,dx
        mov     [inbufnb],dx
        mov     [inbufix],dx
        mov     [nubflr],dx

; JSM 11/19/87 changes start

	cmp	[oldset],'Y'
	jnz	openx			; if new style set, clear CY & exit
	mov	bx,ax
	mov	ax,4202h		; seek to end of file
	mov	cx,dx			; offset 0 from end
	int	21h
	push	dx			; save file size
	push	ax
	mov	ax,4200h		; seek back to beginning
	xor	dx,dx
	mov	cx,dx			; offset for beginning
	int	21h			; back to beginning of file
	pop	ax
	pop	dx
	or	ax,ax
	jnz	openx			; if file not empty
	or	dx,dx
	jnz	openx			; if file not empty
	stc				; file empty, set carry
openx:

; JSM 11/19/87 changes end

        ret
openin  endp

;----------------- create output directory & output file name --------------;

makenm  proc    near

        lea     di, [workdir+2]
        lea     si, [fidpath]

	cmp	[dirchg],1
	je	chdir				; if directory changed
	jmp	makecp				; if directory didn't change
chdir:
	mov	[dirchg],0			; accounted for new dir
	
;       make new directory if not already made

mitlp:
        cmp     byte ptr [si], 0
        je      makecp
	cmp	word ptr [si],'\'		; ignore final \
	je	makecp
        cmp     byte ptr [si], '\'
        jne     mit1
        movsb

mit1:
        lodsb   
        or      al, al          ; end-of-path
        jz      mit2
        cmp     al, '\'         ; end-of-directory 
        je      mit2
        stosb
        jmp     short mit1

mit2:
        mov     byte ptr [di], 0        ; set terminator
        dec     si                      ; decrement point for next one

;       get     security information from directory

        push    bx
        push    es
        push    cs
        pop     es

if      MOS        
	mov	al, [ffname]		; disk id for floppy
	mov	[workdir],al
        lea     dx, [workdir]
        lea     bx, [buff03d]
        mov     ax, 0300h               ; get security
	int	SERVICES
        jnc     $+5
        jmp     errget03
endif

	mov	al, [dstpath]
	mov	[workdir],al			; create dirs on dest. disk
        lea     dx, [workdir]
        mov     ah, 39h
        int     21h

;       set security information

if      MOS
        lea     dx, [workdir]
        lea     bx, [buff03d]
        mov     ax, 0301h               ; set security
	int	SERVICES
        jnc     $+5
        jmp     errset03
endif

        pop     es
        pop     bx
        jmp     short mitlp
         
makecp:
        cld
        lea     di,[ffname+2]
        mov     cx,[fidplen]
        lea     si,[fidpath]
rep     movsb
	cmp	byte ptr [di-1],'\'
	je	nodir			; if already have \ separator
	cmp	byte ptr [di-1],':'
	je	nodir			; if we don't need \
        mov     al, '\'
        stosb

nodir:  
        lea     si,[flname]             ; create asciiz string for input open
        mov     cx,13
        cld
        rep     movsb
        ret
makenm  endp

;---------------------- list filename to screen ---------------------;


showname proc   near
        lea     dx, msgcrlf
        call    display
	mov	dx,offset msgfile
	call	display			; display initial message
        lea     si,[ffname]
	call	strdsp			; display source file name
        ret
showname endp

;---------------------- display data to screen ----------------------;

display proc    near
        mov     ah,9
        int     21h
        ret
display endp

        page
;----------------------- abnormal termination -----------------------;

errsyn:
        lea     dx,[msgsyn]
        mov     [synerror], 1
        jmp     short badmsg
erropeni:
        lea     dx,[msgopeni]
        jmp     short badmsg
erropeno:
        lea     dx,[msgopeno]
        jmp     short badmsg
errread:
        lea     dx,[msgread]
        jmp     short badmsg
errwrite:
        lea     dx,[msgwrite]
        jmp     short badmsg
errclosi:
        lea     dx,[msgclosi]
        jmp     short badmsg
errcloso:
        lea     dx,[msgcloso]
        jmp     short badmsg
errdisk:
        lea     dx,[msgdisk]
        jmp     short badmsg
errget03:
        lea     dx,[msgget03]
        jmp     short badmsg
errset03:
        lea     dx,[msgset03]
        jmp     short badmsg
errpath:
        lea     dx,[msgnpath]
        jmp     short badmsg

badmsg:
        call    display

uabort:
        cmp     [synerror], 1
        je      ucont
        lea     dx,[msgabort]
        call    display

ucont:
        mov     al, 2
	jmp	doquit

        even
inbuffer label  byte

_text	ends
        end     entry
