        include page.inc
        title	EXPORT - MOS compression and backup utility
;******************************************************************************
;*                                                                            *
;*                        MOS Development Specification                       *
;*                                                                            *
;* Command type: EXTERNAL               Assigned to:                          *
;* Command name: EXPORT                 Date assigned:                        *
;*                                      Date completed:                       *
;* Command format: EXPORT filename d: [/s][/i][/a][y]                         *
;* Purpose:  Archiving files to backup disks                                  *
;* Refer to:                                                                  *
;* Last Update:   June 28, 1989 	By: SAH 			      *
;*                                                                            *
;*      External                Values                  Values                *
;*      routines                passed                  returned              *
;*                                                                            *
;******************************************************************************
;
;-----------------------------------------------------------------------;
; Updated  02/09/87 SAH  Multi-Directory, Archive Bit, path in header   ;
; Updated  03/02/87 SAH  Security Information Transfer Supported        ;
; Updated  03/23/87 SAH  /A /Y and message changes                      ;
; Updated  03/26/87 SAH  /I for Incremental Backup                      ;
; Updated  05/02/87 SAH  Fix problem with last file feels up disk       ;
; Updated  05/12/87 RBR  Minor changes to messages			;
; Updated  07/12/87 SAH  Converted function 80+ calls to int 38H 00+    ;
; Updated  11/04/87 JSM  Fixed multidirectory features to work properly ;
;			 with disk drive specs, and to work properly	;
;			 on drives other than the default drive. Upped	;
;			 version to 1.01.
; Updated  11/16/87 JSM  Deal properly with source names which end with ;
;			 subdirectory names, and deal properly with	;
;			 blank destination names (with no disk drive)	;
; Updated  11/19/87 JSM  Add /O switch to prevent creation of labels,	;
;			 update version to 1.02.			;
; Updated  11/30/87 JSM  Fixed character display in getYN routine,	;
;			 fixed exporting to drives other than A:, upped	;
;			 version number to 1.03, change id [1]		;
; Updated  12/10/87 JSM  Fixed problems dealing with file names and	;
;			 paths on the destination drive spec.  Allow	;
;			 source file spec to be just a disk ID.	 Always	;
;			 write disk labels to target.  change id [2]	;
; Cleaned  09/08/88 RKG  Internal name change and misc cleanup		;
; Updated  11/02/88 RKG  Changed messages for easier translation	;
; Updated  02/20/89 SAH  Use OPTIONS.INC for MOS SERVICES		;
; Updated  06/28/89 SAH  Corrections for Signoff and default class	;
; Updated  09/19/89 SAH  Corrections for /Y for translations		;
; Updated  11/27/89 BWR  Marked messages for foreign language 		;
;			 translations.					;
; Updated  12/20/89 BWR	 Fixed problem with /Y option.  Also replaced   ;
;			 "jmp $+5" instructions with the long relative  ;
;			 jump macros.					;
;									;
;-----------------------------------------------------------------------;

include		jmpmacro.inc

MOS     equ     01

tcb     segment at 7777h
        .xlist

if      MOS
        include mostcb.inc
endif   
        .list
tcb     ends

	include options.inc
        include export.pub

mainseg segment para
        assume  cs:mainseg,ds:mainseg
        org     006ch
fcb2    label   byte                    ; target drive ID is here
        org     0100h

entry:
        jmp     start

stkrec  equ     21+22                   ; stack record size
                                        ; must be atleast 43 for dir removal
buflen  equ     16*1024                 ; I/O buffer size
outlen  equ     32*1024                 ; OutPut Buffer size

        db      3 dup(8),3 dup(' ')
msgtsl	db	13,10,'EXPORT v4.00',13,10
	db	'(c) Copyright 1987, 1988, 1989 The Software Link, Incorporated' ;@@XLAT
        db      13,10,'$'
        db      8,' ',1ah

        even
version label   near
        include version.inc

badmos  db      13,10, 'Incorrect MOS Version ',13,10,'$' ;@@XLAT

        even
inhandle dw     0                       ; handle for input
ouhandle dw     1                       ; handle for output
bibuffer dw     0                       ; bytes in buffer
bytsleft dw     2 dup(0)                ; bytes left in file

oubufadr dw     buffer+buflen           ; output buffer address
oubuflen dw     outlen                  ; output buffer length
oubufix  dw     0                       ; current index

dstkadr  dw     buffer+buflen+outlen+1  ; directory stack address (1/movsw)
dstkptr  dw     0                       ; enought for 390 21 byte entries
TCBSEG   dw     0
defclass db     0                       ; saved default class

        db      0                       ; start DTA at odd address
fileinfo label  byte                    ; DTA starts here
        db      21 dup(0)               ; reserved for DOS
fiattr  db      0                       ; file attribute
fitime  dw      0                       ; file time
fidate  dw      0                       ; file date
fisize  dw      2 dup(0)                ; file size in bytes
finame  db      13 dup(0)               ; ASCIIZ filename
fidpath db      80 dup(0)               ; ASCIIZ Sub-Directory Pathname


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

ndisk	db	1			; working on a new disk?
exlbl	lblinfo	<"EX-",'I',"0001">
exlend	equ	$

lblfcb  label   byte
lfat	db	0ffh,0,0,0,0,0,LBLATTR
lfid	db      1                       ; drive (default is A)
lfnm	db      11 dup ('?')		; filename
        dw      13 dup (0)

lbldta	db      30 dup (?)               ; DTA for label searches
ldnm	db	13 dup (?)

        even
fidplen dw      0                       ; length for current subdirectory
fioff   dw      0                       ; offset file
ficount dw      0                       ;


ptrfn	dw	0			; pointer to start of file name
srcfn	db	12 dup (0)		; source file name
srcid	db	"A:",0			; source disk ID
srcpth	db	64 dup (0)		; path for source files

buff03   db     10 dup (0)              ; for function 03
buff03d  db     10 dup (0)              ; for function 03 (directories) 
workpath db     80 dup (0)              ; work path
wilddel  db     'A:'
wildcard db     '*.*',0                 ; use for wildcard dir searches
chgdir   db     'A:', 13 dup (0)        ; change directory
parent   db     'A:..',0                ; parent
multidir db     'N'                     ; Multi-Directory searchs (no)
autoyes  db     'N'                     ; auto answer to prompts
appendmd db     'N'                     ; append mode
incback  db     'N'                     ; Incremental Backups (archive)
firstpss db     'Y'                     ; first pass  
uselbl	db	'Y'			; make labels on destination disk

sgnature db     'Xf'                    ; signature for eXported File

msgcrlf db      13,10,'$'

msgfile db      13,10,'Now exporting $   ' ;@@XLAT
msgstart db	13,10,"    Export begins with disk      " ;@@XLAT
startid	db	"   1",13,10,"$"

msgswap db      13,10
        db      13,10,'This archive disk is now full.             ' ;@@XLAT
        db      13,10,'Please replace it with archive disk                ' ;@@XLAT
msgsnbr db      '   2.'
msgcom  db      13,10,'      All files on Drive  ' ;@@XLAT
msgdrv  db      'A will be $      ' ;@@XLAT
msgera  db      'ERASED.$  ' ;@@XLAT
msgapp  db      'APPENDED.$ ' ;@@XLAT
msgsubd db      13,10,'Exporting directories...$   ' ;@@XLAT
msgincb db      13,10,'Incremental EXPORT in process...$' ;@@XLAT
msgrdy  db      13,10,'Ready to continue (Y/N) ? $  ' ;@@XLAT
yesrsp	db	'Yes   $' ;@@XLAT
norsp	db	'No    $' ;@@XLAT
msgabort db     13,10,'EXPORT is interrupted by user.' ;@@XLAT
         db     13,10,'The EXPORT process is incomplete.',13,10,'$' ;@@XLAT
msgdone  db     13,10,'EXPORT is complete.    ',13,10,'$'  ;@@XLAT
msgbadp  db     13,10,'Invalid option specified on command line.      ',13,10,'$' ;@@XLAT


msgopeni db     13,10,'Error opening input file!           ',13,10,'$' ;@@XLAT
msgopeno db     13,10,"Error opening output file!          ",13,10,'$' ;@@XLAT
msgopenl db     13,10,'Error making label on output disk!        ',13,10,'$' ;@@XLAT
msgclosi db     13,10,'Error closing input file!              ',13,10,'$' ;@@XLAT
msgcloso db     13,10,'Error closing output file!             ',13,10,'$' ;@@XLAT
msgread  db     13,10,'Error reading input! ',13,10,'$' ;@@XLAT
msgwrite db     13,10,'Error writing output! ',13,10,'$' ;@@XLAT
msgget03 db     13,10,'Error processing input file!             ',13,10,'$' ;@@XLAT
msgset03 db     13,10,'Error processing output file!            ',13,10,'$' ;@@XLAT

ffname  db      'A:filename.ext',0      ; filename field for floppy ;@@XLAT
        db      66 dup (0)              ; plus path....

defdisk	db	?			; default disk drive number
defpath	db	65 dup (?)		; default path

dirchg	db	1			; directory has changed

        even
dstfnptr dw	0			; pointer to location in ffname for
					; destination file names
dstbpptr dw	0			; where all destination paths should
					; start
pathspec dw     0
pathlen dw      (?)                     ; length of path
pathfn  dw      offset path             ; address of filename portion of path
path    db      80 dup(0)               ; saves pathname from operands

compff  db      0ffh,0                  ; compression control info
compdata db     0,0

delfcb  label   byte
        db      1                       ; drive (default is A)
        db      '???????????'           ; filename
        dw      13 dup(0)
        page
;------------------------- main routine ----------------------------;

start   proc
if      MOS
	call	chkver			; make sure we're MOS
	call	getdef			; save current disk drive & path
endif
	call	setup			; set up for exporting
	call	dscan			; scan and export files
eof:
        lea     dx,[msgdone]
        call    display
	call	lastdisk		; change disk label
        xor     al, al
        call     doquit
start	endp

doquit	proc
        push    ax
if	MOS
	mov	es,[tcbseg]		; SAH make sure we have TCB
        assume  es:tcb                  ; reset to original default
        mov     al, [defclass]
        mov     es:[TCBCDFT], al
endif
	mov	ah,0eh
	mov	dl,[defdisk]
	int	21h			; return to original disk drive
	mov	dx,offset defpath
	mov	ah,3bh
	int	21h			; return to original directory
	
        pop     ax
        mov     ah, 4ch
        int     21h
doquit	endp

if	MOS
chkver	proc
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
mosok:
	ret
chkver	endp
endif


;---------------- save current default disk & path ------------------;

getdef	proc
	mov	ah,19h
	int	21h
	mov	[defdisk],al

	inc	al			; drive number now 1 based
	mov	byte ptr [defpath],'\'
	mov	si,offset defpath+1	; where current path goes
	mov	dl,al
	mov	ah,47h
	int	21h			; get current path
	ret
getdef	endp


;---------------------- setup for exporting ------------------------;

setup	proc
        lea     dx, uabort
        mov     ax, 2523h
        int     21h

        lea     dx,[msgtsl]             ; write copyright notice
        call    display

if      MOS
        mov     ah, 04h                 ; save default output class
        mov     bx, -1                  ; from current TCB
	int	SERVICES
        assume  es:tcb
        mov     [TCBSEG], es
        mov     al, es:[TCBCDFT]
        mov     [defclass], al
        push    cs
        pop     es
        assume  es:nothing
endif

        mov     ah,1ah                  ; set DTA
        lea     dx,[fileinfo]
        int     21h

;----------------------- get floppy drive id ------------------------;

        mov     al,[fcb2]
        or      al,al
        jz      gfdiskip
        mov     [delfcb],al
        mov     [lfid],al
        add     al,'A'-1
        mov     [ffname],al
        mov     [wilddel], al
        mov     [chgdir], al
        mov     [parent], al
        mov     [msgdrv], al
gfdiskip:

;----------------------check for options ----------------------------;

	call	chkopt

;-------------------- look for filename operand ---------------------;

lookfile:
	cld
        mov     si,0080h
lffoloop:
        inc     si
        cmp     byte ptr ds:[si],20h    ; scan for nonblank
        je      lffoloop
        mov     dx,si                   ; save start address in dx
        mov     [fioff], dx             ; save default filename
sfoloop:
        lodsb                           ; find end and terminate it with 0
        cmp     al,20h
        ja      sfoloop
        dec     si
        mov     byte ptr ds:[si],0
        mov     [fioff], dx             ; save default filename
        
;--------------------- extract directory pathname -------------------;

	push	si
	call	edp
	pop	si
	inc	si			; si points to byte after source
	call	gdp

;---------------- prompt for user and display options ---------------;

	call	doprompt

	ret
setup	endp

;----------------------check for options ----------------------------;

chkopt	proc
        cld
        mov     al, byte ptr ds:[80h]   ; get length
        xor     ah, ah
        mov     si, 81h
        add     si, ax                  ; point to tail

mdcloop:
        dec     si                      ; scan backwards for a /
        cmp     si, 81h
        jb      mdcskip
        cmp     byte ptr ds:[si], '/'
        jne     mdcloop

        mov     al, ds:[si+1]
        cmp     al, 'a'
        jb      mdchead
        add     al, 'A'-'a'

mdchead:
        cmp     al, 'S'
        jne     mdcapp
        mov     [multidir], 'Y'         ; indicate multi-directory
        jmp     short mdcnext

mdcapp:
        cmp     al, 'A'
        jne     mdcauto
        mov     [appendmd], 'Y'         ; indicate append mode
        mov     [autoyes], 'Y'          ; indicate auto yes mode 
        jmp     short mdcnext

mdcauto:
	cmp	al, 'Y'
        jne     mdcinc
        mov     [autoyes], 'Y'          ; indicate auto responce mode
        jmp     short mdcnext

mdcnolb:
        cmp     al, 'O'
        jne     mdcinc
        mov     [uselbl], 'N'           ; don't write labels on target disks
        jmp     short mdcnext

mdcinc:
        cmp     al, 'I'
        jne     mdcbad
        mov     [incback], 'Y'          ; indicate incremental backup

mdcnext:
        mov     word ptr ds:[si], '  '  ; clear out option     
        jmp     short mdcloop

mdcbad:
        lea     dx, [msgbadp]
        call    display
        jmp     uabort

mdcskip:
	ret
chkopt	endp

;---------------- prompt for user and display options ---------------;

doprompt proc
        lea     dx, [msgcom]
        call    display
        lea     dx, [msgera]
        cmp     [appendmd], 'Y'
        jne     prompt1
        lea     dx, [msgapp]

prompt1:
        call    display
	cmp	[autoyes], 'Y'		;If /Y, then don't prompt.
	je	prompt2
        call    GetYN			;Pause and await the user.
        cmp     al,[yesrsp]		;Does he want to continue?
	je	prompt2			;If so, continue.
        jmp     uabort			;If not, then abort
prompt2:
        cmp     [appendmd],'Y'		;Append mode?
        je      prompt3
        call    deletall

prompt3:
        cmp     [multidir],'Y'
        jne     prompt4
        lea     dx, [msgsubd]
        call    display

prompt4:
        cmp     [incback], 'Y'
        jne     prompt5
        lea     dx, [msgincb]
        call    display

prompt5:
        lea     dx, [msgcrlf]
        call    display

	ret
doprompt endp

;--------------------- extract directory pathname -------------------;

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
	mov	si,[fioff]		; beginning of source spec
	cmp	byte ptr [si+1],':'	; is there a disk drive spec?
	jne	edp50			; if no disk drive spec
	mov	al,[si]			; get drive letter
	cmp	al,'a'
	jb	edp40
	cmp	al,'z'
	ja	edp40
	sub	al,'a' - 'A'		; convert drive letter to upper case
edp40:
	mov	byte ptr [srcid],al
	inc	si
	inc	si			; point si past disk drive spec
	jmp	short edp60
edp50:
	mov	ah,19h			; get current disk drive id
	int	21h
	add	al,'A'			; convert it to ASCII
	mov	byte ptr [srcid],al
edp60:
	mov	di,offset srcpth	; where the path goes
edp100:
	cmp	si,[ptrfn]		; is there some path stuff?
	je	edp110			; if path copied
	lodsb
	stosb
	jmp	edp100
edp110:
	xor	al,al
	stosb				; terminate path with NUL
	mov	di,offset srcfn		; source file name spec
	call	strcpy			; copy from command line
	cmp	byte ptr [srcfn],0	;[2] any source file spec?
	jne	edp120			;[2] yes, we can quit
	mov	si,offset wildcard	;[2] if no name, use *.*
	mov	di,offset srcfn		;[2]
	call	strcpy			;[2]
edp120:					;[2]
	ret
edp	endp

;--------------------- get destination pathname -------------------;

gdp	proc
	mov	di,si			; where to start looking
	mov	[dstbpptr],offset ffname + 2 ;JSM 11/16/87
					;JSM 11/16/87 in case no disk id found
	mov	cl,ds:[80h]		; length of command line
	xor	ch,ch
	sub	si,81h			; bytes checked so far
	sub	cx,si			; bytes to check
	jb	gdpx			;JSM 11/16/87 if there aren't any
	mov	al,':'
repne	scasb
	jnz	gdpx			;[1] if no :
	mov	al,[di-2]		;[1] target disk ID
	cmp	al,'a'			;[1] convert lower to upper
	jb	gdp2			;[1]
	cmp	al,'z'			;[1]
	ja	gdp2			;[1]
	sub	al,'a' - 'A'		;[1]
gdp2:					;[1]
	cmp	al,[ffname]		;[1] same as in second FCB in PSP?
	je	gdp4			;[1] if still the same
        mov     [ffname],al		;[1]
        mov     [wilddel], al		;[1]
        mov     [chgdir], al		;[1]
        mov     [parent], al		;[1]
        mov     [msgdrv], al		;[1]
        sub     al,'A'-1		;[1]
        mov     [delfcb],al		;[1]
	mov	[lfid],al		;[1]
gdp4:					;[1]
	jcxz	gdpx			;[1] if : on end
	mov	si,di
	mov	di,offset ffname+2	; where the path goes (if any)
	mov	dx,di			;[2] last backslash pointer
gdp10:
	lodsb
	cmp	al,' '			; quit on white space
	jbe	gdp20			; if we found white space
	stosb
	cmp	al,'\'			;[2]
	jne	gdp10			;[2]
	lea	dx,[di-1]		;[2] where last backslash was stored
	jmp	gdp10
gdp20:					;[2]
	cmp	dx,offset ffname+2	;[2] find any \ after first char?
	jne	gdp40			;[2] if found another backslash
	cmp	byte ptr [ffname+2],'\'	;[2] leading backslash?
	jne	gdp30			;[2] no, kill entire path
	inc	dx			;[2] path is just \
	jmp	short gdp40		;[2]
gdp30:					;[2]
	mov	di,dx			;[2] terminate the path at last \
	mov	byte ptr [di],0		;[2]
	jmp	short gdpx		;[2]
gdp40:					;[2]
	mov	di,dx			;[2] if not just \, kill last \
	mov	byte ptr [di],0		;[2] terminate path with nul
;[2]	xor	al,al
;[2]	stosb				; terminate path with nul
;[2]	dec	di
	mov	[dstbpptr],di		; where all destination paths start
	mov	ah,3bh
	mov	dx,offset ffname
	int	21h			; start on destination from
					; this drive
gdpx:
	ret
gdp	endp

;------------------------ start directory scan ----------------------;
dscan	proc
fscan:
        lea     di, fidpath		; current directory
	lea	si,srcid
	call	strcpy			; copy the disk drive
	dec	di
	lea	si,srcpth		; and the path
	call	strcpy

	lea	di,path
	lea	si,fidpath
	call	strcpy
	dec	di
	mov	[pathfn],di		; where file names should start
					; in path
	lea	si,srcfn		; also file name for (possibly)...
	call	strcpy			; fully qualified file name

	lea	dx,path
        call    dirscan                 ; scan main directory and subs
        cmp     [ficount], 0
        jne     dirend
        cmp     [firstpss], 'Y'
        jne     dirend
        mov     [firstpss], 'N'         ; nolonger first pass

;       append filename\*.* to path on assumption filename is a directory

	mov	di,offset srcpth
	mov	cx,80
	xor	al,al
repne	scasb
	dec	di			; at end of path
	mov	si,offset srcfn		; now append the file name
	call	strcpy
	cmp	byte ptr [di-1],'\'	;JSM 11/16/87 does it end with a \?
	je	direbs			;JSM 11/16/87
	mov	word ptr [di-1],'\'	;JSM 11/16/87 end path with \,NUL
direbs:					;JSM 11/16/87

;	Set file name to *.*

        mov     word ptr [srcfn], '.*'
        mov     word ptr [srcfn+2], 0 or '*'
	jmp	fscan

dirend:
        lea     dx,[msgcrlf]            ; new line
        call    display
	ret
dscan	endp


dirscan	proc
        mov     ah,4eh                  ; find first matching file
        mov     cx,02h                  ; include hidden but not system files
                                        ; include subdirectories in search
        call    short dlentry           ; call directory scan loop

;--------------------------------------------------------------------;
;       Search for the next directory and process it if found        ;
;--------------------------------------------------------------------;

        cmp     byte ptr [multidir], 'Y'        ; multi-directory
        jne	dscx
	call	dsearch
dscx:
        ret
dirscan	endp

;------------------ begin directory search --------------------------;

dsearch	proc
	mov	ah,4eh			; find first
remakdir:
        lea     di, workpath
	lea	si,fidpath
	call	strcpy			; copy the disk drive & path
	dec	di
	cmp	byte ptr [di-1],'\'	; if have \ already
	je	sdirskip
	cmp	byte ptr [di-1],':'	; if don't need a \
	je	sdirskip
        mov     al, '\'
        stosb
        
sdirskip:
        lea     si, wildcard
	movsw
        movsw
        lea     dx, workpath            ; set to wild card match
        mov     cx, 10h                 ; search for directories only
sdirnext:
        int     21h
        jnc	procdir
	jmp	dsearx

procdir:
	mov	ah,4fh				; do find next from now on
        test    byte ptr [fiattr], 10h          ; directory??
        jz      sdirnext
        cmp     byte ptr [finame], '.'          ; . or ..
        je      sdirnext                        ; next dir
	call	newdir

	mov	ah,4fh				; do find next from now on
        jmp     remakdir		; process next input directory entry
dsearx:
	ret
dsearch	endp


;------------------  process an entire new directory -----------------;

newdir	proc        
	mov	[dirchg],1		; notify makefn we're in a new
					; directory

        lea     di, [fidpath]           ; point at end of current dir
	xor	al,al			; look for zero byte
	mov	cx,80
repne	scasb
	dec	di			; back up to where NUL lives
	cmp	byte ptr [di-1],'\'
	je	scdskip			; if don't need another '\'
	cmp	byte ptr [di-1],':'
	je	scdskip			; ditto
        mov     al, '\'
        stosb
scdskip:
        mov	cx,12			; maximum file name length
        lea     si, [finame]            ; get directory name

scdloop:
        lodsb
        stosb
        or      al, al
	loopnz	scdloop
	jz	scddone			; if we already wrote a NUL
        xor     al, al
        stosb
scddone:

;-------------------- save dta  on internal stack -------------------;

        mov     di, [dstkadr]           ; save dta on internal stack
        add     di, [dstkptr]
        lea     si, fileinfo
        mov     cx, STKREC
        rep     movsb
        add     [dstkptr], STKREC       ; increment stack ptr by len

;------------------ setup path for directory search -----------------;

        lea     di, path
        lea     si, fidpath             ; transfer current directory
	call	strcpy
	dec	di
	cmp	byte ptr [di-1],'\'
	je	dirsav			; if we don't need another \
	cmp	byte ptr [di-1],':'
	je	dirsav			; ditto
        mov     al, '\'
        stosb
dirsav:
        mov     [pathfn], di
        lea     si, [srcfn]             ; add file name
	call	strcpy
        lea     dx, path                
        call    dirscan                 ; scan directory for files

;---------------------- get dta from internal stack -----------------;

        sub     [dstkptr], STKREC       ; decrement int stack ptr
        mov     si, [dstkadr]           ; get dta from int stack
        add     si, [dstkptr]
        lea     di, fileinfo
        mov     cx, STKREC
        rep     movsb

;---------------------- reset current directory ---------------------;
        
        lea     di, [fidpath]           ; point at beginning of current dir
	xor	al,al			; look for zero byte
	mov	cx,80
repne	scasb
	dec	di			; back up to where NUL lives
	mov	si,di
	std
rscdir:
        lodsb					; get byte before last one
        cmp     al, '\'
        je      rsdone				; stop backing for \
	cmp	al,':'
	jne	rsechk				; continue backing unless :
	inc	si				; don't kill : character
	jmp	short rsdone
rsechk:
        cmp	si,offset fidpath		; end-of-line
        jae     rscdir
rsdone:
	cld
	inc	si				; point to last OK char
        mov     byte ptr [si], 0		; terminate with nul
	ret
newdir	endp



dirloop proc
        mov     ah,4fh                  ; find next matching file
dlentry:
        int     21h
        jc	dirl10
	call    pentry                  ; error check
	jmp	dirloop
dirl10:
        ret
dirloop	endp

;------------------- process entry ----------------------------------;

pentry	proc
        cmp     [incback], 'Y'
        jne     pentry2
        test    byte ptr [fiattr], 20h  ; archive bit
        jnz	pentry2
	jmp	pentryx			; return to caller

pentry2:
        mov     ah,36h                  ; get disk free space
        mov     dl,[delfcb]
        int     21h
        or      bx,bx                   ; any free clusters?
	jnz	pentry3			; if clusters free
	call	doswap			; if disk full, request swap
pentry3:
	call	makelbl			; make label for this disk

        lea     si,[finame]             ; create asciiz string for input open
        mov     di,[pathfn]
        mov     cx,13
        cld
        rep     movsb

        call    showname                ; entertain the operator
        inc     [ficount]               ; increment file counter

if      MOS
        push    es
        push    cs
        pop     es
        lea     dx,[path]               ; get security information
        lea     bx,[buff03]
        mov     ax, 0300h               ; get
	int	SERVICES
	Ljc	errget03

        mov     es, [TCBSEG]            ; set default class as class read
        assume  es:tcb
        mov     al, byte ptr [buff03+1]
        mov     byte ptr es:[TCBCDFT], al
        pop     es
        assume  es:nothing
endif        

        call    makefn                  ; create floppy path name

        mov     ax,3d00h                ; open input file
        lea     dx,[path]
        int     21h
	Ljc	erropeni
        mov     [inhandle],ax

        lea     dx,[ffname]             ; change attribute to nothing
        xor     cx,cx
        mov     ax, 4301h
        int     21h
        lea     dx,[ffname]             ; delete file
        mov     ah, 41h
        int     21h

        mov     ah,3ch                  ; create output file
        lea     dx,[ffname]
        mov     cx,0
        int     21h
	Ljc	erropeno
        mov     [ouhandle],ax

        mov     ax,[fisize]             ; set starting byte count
        mov     [bytsleft],ax
        mov     ax,[fisize+2]
        mov     [bytsleft+2],ax

        mov     byte ptr [compff+1],0   ; init compression byte value

        mov     cx,2                    ; write signature to diskette
        lea     dx,[sgnature]
        call    wrfloppy

        mov     cx,22                   ; write header to diskette
        lea     dx,[fiattr]
        call    wrfloppy

readloop:
        mov     cx,buflen               ; compute length to read
        cmp     [bytsleft+2],0
        jne     rlgotlen

        cmp     [bytsleft],0            ; check for end at same time
	Lje	rlend
        cmp     cx,[bytsleft]
        jna     rlgotlen
        mov     cx,[bytsleft]
rlgotlen:
        mov     [bibuffer],cx           ; number of bytes in buffer

        sub     [bytsleft],cx           ; maintain remaining file length
        sbb     [bytsleft+2],0

        mov     ah,3fh                  ; read file data
        mov     bx,[inhandle]
        lea     dx,[buffer]
        int     21h
	Ljc	errread
        lea     si,[buffer]             ; si scans buffer

writloop:
        mov     ax,si                   ; compute remaining bytes in buffer
        sub     ax,offset buffer
        mov     cx,[bibuffer]
        sub     cx,ax
        jz      readloop                ; if none, get more

        push    si                      ; save buffer data pointer for write

        call    scan                    ; get compression info
        mov     word ptr [compdata],dx  ; data length, compressed length
        mov     cx,2                    ; write length bytes to diskette
        cmp     dh,0                    ; check compression length
        lea     dx,[compdata]

        je      wcdata                  ; skip if no compressed data
        cmp     byte ptr [compff+1],al  ; compression byte changed?
        je      wcdata                  ; no, skip
        mov     byte ptr [compff+1],al
        add     cx,2                    ; write compression byte info
        lea     dx,[compff]
wcdata:
        push    si
        call    wrfloppy                ; write 2 or 4 control bytes
        pop     si

        pop     dx                      ; now write raw data
        mov     cl,byte ptr [compdata]
        mov     ch,0
        push    si
        call    wrfloppy
        pop     si

        jmp     writloop

;------------------ end of file - close and do next -----------------;

rlend:
        call    wrflush                 ; flush output buffer

        mov     ah,3eh                  ; close input file
        mov     bx,[inhandle]
        int     21h
	Ljc	errclosi

        mov     ah,3eh                  ; close output file
        mov     bx,[ouhandle]
        int     21h
	Ljc	errcloso

if      MOS
        push    es
        push    cs
        pop     es
        lea     dx,[ffname]             ; set security information
        lea     bx,[buff03]
        mov     ax,0301h                ; set it
	int	SERVICES
	Ljc	errset03
        pop     es
endif
        
;------------------ set archive bit ---------------------------------;

archive:
        lea     dx, [path]
        mov     ax, 4301h               ; set attributes
        mov     cl, [fiattr]
        and     cx, 00DFh
        int     21h
        lea     dx, [ffname]
        mov     ax, 4301h               ; set attributes
        mov     cl, [fiattr]
        and     cx, 00DFh
        int     21h
pentryx:
	ret
pentry	endp

        page
;----------------------- make disk label ----------------------------;

makelbl	proc	near
	cmp	[ndisk],0		; is this a new disk?
	je	mklbx			; no, do nothing
	mov	[ndisk],0		; no longer a new disk
	cmp	[uselbl],'Y'		; make label on target?
	jne	mklbx			; no label on target disk

	cld
	call	flbl			; find an old label & deal with it
	mov	di,offset workpath	; put label path here
	mov	ax,word ptr [ffname]
	stosw				; disk drive for label
	mov	al,'\'
	stosb				; path for label
	mov	si,offset exlbl.lblprf
	call	strcpy			; file name for label
	mov	ah,3ch
	mov	cx,LBLATTR		; create a label
	mov	dx,offset workpath	; the label's name, disk & path
	int	21h			; create a new label for the disk
	jnc	mklb10
	jmp	erropenl		; error creating label
mklb10:
	mov	bx,ax
	mov	ah,3eh			; close the label
	int	21h
mklbx:
	ret
makelbl	endp

;---------------------- find a disk label ---------------------------;

flbl	proc    near
	mov	ah,2fh			; save current DTA
	int	21h
	push	bx
	mov	dx,offset lbldta	; change to label DTA
	mov	ah,1ah
	int	21h
	mov	di,offset lbldta
	xor	al,al
	mov	cx,43			; size of dta
rep	stosb				; clear out dta
	mov	di,offset workpath	; put label path here
	mov	ax,word ptr [ffname]
	stosw				; disk drive for label
	mov	al,'\'
	stosb				; path for label
	mov	si,offset wildcard	; file name for search
	call	strcpy
	mov	ah,4eh			; find a label
	mov	cx,LBLATTR
	mov	dx,offset workpath
	int	21h			; find a label
	jc	flbl30			; if no label to be found

;	If append mode, see if it's a label made by EXPORT.

	cmp	[appendmd],'Y'
	jne	flbl30			; if not in append mode, blow away
					; the label
	mov	si,offset exlbl.lblprf
	mov	di,offset ldnm
	mov	cx,lbleflg - lblprf
repe	cmpsb				; prefix same as ours?
	jne	flbl30			; if different, ignore it
	lodsb				; end flag byte
	cmp	al,'I'			; end flag must be I or L
	je	flbl10
	cmp	al,'L'
	jne	flbl30			; neither I nor L, ignore it
flbl10:
	mov	cx,exlend - exlbl.lblsn		; four bytes of serial number
flbl20:
	lodsb				; make sure serial number is OK
	cmp	al,'0'
	jb	flbl30			; if not a numeral
	cmp	al,'9'
	ja	flbl30			; if not a numeral
	loop	flbl20			; next one

;	It's ours, copy old serial number into our label.

	mov	si,offset ldnm + lbleflg - lblprf + 1	; copy serial #
	mov	di,offset exlbl.lblsn
	mov	cx,exlend - exlbl.lblsn
rep	movsb
	mov	si,offset exlbl.lblsn
	mov	di,offset startid
	mov	cx,exlend - exlbl.lblsn
	call	copydn			; tell user starting disk number
	mov	dx,offset msgstart
	call	display

;	Delete the old label.
flbl30:
	mov	al,'?'			; wild card file spec
	mov	cx,8 + 3		; name + extension
	mov	di,offset lfnm
rep	stosb				; just use wild cards 
	mov	ah,13h			; delete label with FCB
	mov	dx,offset lblfcb
	int	21h
flblx:
	pop	dx
	mov	ah,1ah			; back to normal DTA
	int	21h
	ret
flbl	endp

;----------------------- signal new disk ----------------------------;

newdisk	proc	near
	mov	[ndisk],1		; makelbl will make a new label
	mov	si,offset exlend - 1
					; last byte of serial num
	mov	cx,4			; do 4 digits
	call	incstr
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

;----------------------- finish last disk ---------------------------;

lastdisk proc
	mov	[exlbl.lbleflg],'L'	; end disk of set
	mov	[appendmd],'N'		; no more appending of things
	mov	[ndisk],1
	call	makelbl			; change the disk's label
	ret
lastdisk endp

        page
;------------------------ floppy output -----------------------------;

wrfloppy proc   near
        mov     di,[oubufix]            ; compute new index
        add     di,cx
        cmp     di,[oubuflen]           ; check if too big
        ja      wrfdump                 ; yes, go dump it
        xchg    di,[oubufix]            ; no, update buffer
        add     di,[oubufadr]
        mov     si,dx
        inc     cx
        shr     cx,1
        cld
        rep     movsw
        ret
wrfdump:
        push    dx
        push    cx
        call    wrflush                 ; flush output buffer
        pop     cx
        pop     dx
        jmp     wrfloppy
wrfloppy endp

wrflush proc    near
        mov     cx,[oubufix]
        jcxz    wrfexit                 ; skip if nothing to write
        mov     dx,[oubufadr]           ; set write address
wrfloop:
        mov     ah,40h                  ; write
        mov     bx,[ouhandle]
        int     21h
wrfcnub:
	Ljc	errwrite
        sub     cx,ax                   ; compute number unwritten bytes
        jnz     wrfswap                 ; if any, disk is full
wrfexit:
        mov     [oubufix],0             ; clear output buffer
        ret                             ; we are done
wrfswap:
        or      ax,ax                   ; anything at all written?
        jnz     wrfssome                ; yes, jump

        push    cx                      ; save original length
        push    dx                      ; save target address
        mov     ah,36h                  ; get disk free space
        mov     dl,[delfcb]
        int     21h
        or      bx,bx                   ; any free clusters?
        jz      wrfsoops                ; no, jump
        mul     cx                      ; compute bytes per cluster
        mul     bx                      ; compute free bytes
        mov     cx,ax
        pop     dx                      ; target address
        mov     ah,40h                  ; try the write again
        mov     bx,[ouhandle]
        int     21h
        pop     cx                      ; whew...
        jmp     wrfcnub                 ; ...now that we forced a full disk...
wrfsoops:
        pop     dx                      ; cleaning up from no free clusters
        pop     cx
        xor     ax,ax
wrfssome:
        add     dx,ax                   ; new source address
        push    dx                      ; save parameters
        push    cx

        mov     ah,3eh                  ; close output file
        mov     bx,[ouhandle]
        int     21h
	Ljc	errcloso

if      MOS 
        push    bx
        push    es
        push    cs
        pop     es
        lea     dx,[ffname]
        lea     bx,[buff03]
        mov     ax,0301h                ; set security information
	int	SERVICES
	Ljc	errset03
        pop     es
        pop     bx
endif

	call	doswap			; handle the swap

        call    makefn                  ; create file path & dir
        mov     ah,3ch                  ; create output file
        lea     dx,[ffname]
        mov     cx,0
        int     21h
	Ljc	erropeno
        mov     [ouhandle],ax

        pop     cx                      ; restore regs and try again
        pop     dx
        jmp     wrfloop
wrflush endp

doswap	proc
	call	newdisk			; say we have a new disk
	lea	di,[msgsnbr]		; copy disk number into message
	lea	si,exlbl.lblsn
	mov	cx,exlend - exlbl.lblsn
	call	copydn

        lea     dx,[msgswap]            ; ask for new diskette
        call    display
        lea     dx,[msgera]
        call    display
        call    GetYN
        cmp     al,[yesrsp]
	Ljne	uabort

	mov	[dirchg],1		; say we have to create directories
wrfsdnok:
	mov	[appendmd],'N'		; no longer in append mode
        call    deletall                ; delete all diskette files
        call    showname                ; list filename to screen

	call	makelbl			; make sure disk has label
	ret
doswap	endp

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

        page
;----------------- delete all files on floppy drive -----------------;
;                      including subdirectories                      ;
;--------------------------------------------------------------------;

deletall proc   near

;-------------------- save dta  on internal stack -------------------;

        mov     di, [dstkadr]           ; save dta on internal stack
        add     di, [dstkptr]
        lea     si, fileinfo
        mov     cx, STKREC
        rep     movsb
        add     [dstkptr], STKREC       ; increment stack ptr by len

        lea     dx, wilddel
        mov     cx, 10h
        mov     ah, 4eh
        jmp     deldo

delnext:
        mov     ah, 4fh


deldo:
        int     21h
        jnc     delproc


;---------------------- get dta from internal stack -----------------;

        sub     [dstkptr], STKREC       ; decrement int stack ptr
        mov     si, [dstkadr]           ; get dta from int stack
        add     si, [dstkptr]
        lea     di, fileinfo
        mov     cx, STKREC
        cld
        rep     movsb
        lea     dx,[delfcb]
        mov     ah,13h
        int     21h
        ret


delproc:
        test    byte ptr [fiattr], 10h
        jz      delnext
        cmp     byte ptr [finame], '.'
        je      delnext
        lea     di, chgdir+2            ; change to director
        lea     si, finame
        mov     cx, 13
        cld
        rep     movsb
        lea     dx, chgdir
        mov     ah, 3bh
        int     21h
        call    deletall                ; del directory again (recursive)
        lea     dx, parent              ; change to parent
        mov     ah, 3bh
        int     21h
        lea     di, chgdir+2            ; remove directory
        lea     si, finame
        mov     cx, 13
        cld
        rep     movsb
        lea     dx, chgdir
        mov     ah, 3ah
        int     21h
        jmp     delnext
        ret
deletall endp

;------------------ create floppy filepath & subdirectories ----------;

makefn  proc    near
	cmp	[dirchg],1
	jne	pathset				; if directory not changed
	mov	[dirchg],0			; accounted for new dir
	
        mov     di, [dstbpptr]			; leave base path alone
        lea     si, [fidpath+2]			; ditto with drive id

;       make new directory if not already made

mitlp:
        cmp     byte ptr [si], 0
        je      makecp
	cmp	word ptr [si],'\'		; path end with \?
	je	makecp				; if so, it's time to quit
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

;       do necessary security information for directory gathering

        push    bx
        
if      MOS
	push	si
	push	di			; do moves in here
	mov	ax,word ptr [fidpath]	; set drive spec to source drive
	mov	word ptr [workpath],ax
	mov	di,offset workpath+2
	mov	si,[dstbpptr]		; copy destination name beyond base
	call	strcpy
	pop	di
	pop	si

        lea     dx, [workpath]
        lea     bx, [buff03d]
        mov     ax, 0300h
	int	SERVICES
	Ljc	errget03
endif

        lea     dx, [ffname]
        mov     ah, 39h
        int     21h

;       do necessary security transfer to newly made directory

if      MOS
        lea     dx, [ffname]
        lea     bx, [buff03d]
        mov     ax, 0301h
	int	SERVICES
	Ljc	errset03
endif

mitend:
        pop     bx 
        jmp     short mitlp
         

makecp:
        
;       update check path with current path read in

	mov	[dstfnptr],di		; where destination file names go

pathset:
	mov	di,[dstfnptr]		; this is where the file name goes
	cmp	byte ptr [di-1],'\'	;[2] already a \ there?
	je	paths10			;[2] don't put 2
        mov     al, '\'
        stosb
paths10:				;[2]
        lea     si,[finame]             ; create asciiz string for diskette
        mov     cx,13
        cld
        rep     movsb
        xor     al, al
        stosb
        ret
makefn  endp

;----------------------- get Y/N ------------------------------------;


GetYN   proc    near
	push	bx
        lea     dx, [msgrdy]
        call    display

getynlp:
	mov	ax,0c08h
        int     21h
	and	al,5fh		; ensure upper case
	mov	bx,offset yesrsp
	cmp	al,[bx]
        je      getok
	mov	bx,offset norsp
        cmp     al,[bx]
        je      getok
        jmp     short getynlp

getok:
        push    ax		; save response get message in correct reg
	mov	dx,bx
	call	display		; display response message
        lea     dx, [msgcrlf]
        call    display
        pop     ax
	pop	bx
        ret
GetYN   endp


;---------------------- list filename to screen ---------------------;

showname proc   near
        lea     dx, msgfile
        call    display
        cld

	mov	si,offset path		; file name used to open the file
	call	strdsp
        ret
showname endp

;---------------------- display data to screen ----------------------;

display proc    near
        mov     ah,9
        int     21h
        ret
display endp

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

        page
;----------------------- abnormal termination -----------------------;

abnorm	proc

erropeni:
        lea     dx,[msgopeni]
        jmp     short badmsg
erropeno:
        lea     dx,[msgopeno]
        jmp     short badmsg
erropenl:
        lea     dx,[msgopenl]
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
errget03:
        lea     dx,[msgget03]
        jmp     short badmsg
errset03:
        lea     dx,[msgset03]
        jmp     short badmsg 
badmsg: 
        call    display

uabort:
        lea     dx,[msgabort]
        call    display
        mov     ah, 2
	call	doquit

abnorm	endp

        page
;------------------- Scan DS:SI for repeated bytes ------------------;
;                       CX contains data length                      ;
;--------------------------------------------------------------------;

scan    proc    near
        push    es
        push    di

        push    ds
        pop     es
        cld
        push    si                      ; save start address

        mov     al,ds:[si]              ; ensure no premature match
        inc     al 

        mov     bx,258                  ; compute stop-scan address
        cmp     bx,cx 
        jb      scansebx
        mov     bx,cx
scansebx:
        add     bx,si
scanloop:
        cmp     si,bx                   ; check for length limit
        je      scannope

        mov     dh,dl
        mov     dl,ah
        mov     ah,al
        lodsb                           ; post-increments si

        cmp     ah,al                   ; test if 4 repeated bytes
        jne     scanloop
        cmp     ax,dx 
        jne     scanloop 

;------------------ 4 repeated bytes were found ---------------------;

        sub     si,4
        mov     dx,si                   ; compute uncompressed length in dl
        pop     di
        sub     dx,di

        sub     cx,dx                   ; compute number of bytes left in cx
        cmp     cx,255                  ; ensure no greater than 255
        jna     scangbl
        mov     cx,255
scangbl:
        mov     dh,cl
        mov     di,si
        repz    scasb                   ; scan for end of repeats
        jz      scanzero                ; jump if entire length was equal
        dec     di                      ; otherwise we must adjust
        inc     cx
scanzero:
        sub     dh,cl                   ; compressed length in dh
        mov     si,di                   ; next-byte address in si
        jmp     short scanexit          ; compressed data byte in al

;-------------------- repeated bytes not found ----------------------;

scannope:
        pop     si                      ; starting point
        mov     dx,254                  ; compute length in dl, 0 in dh
        cmp     dx,cx
        jna     scannrbl
        mov     dx,cx
scannrbl:
        add     si,dx                   ; next-byte address in si
        xor     ax,ax                   ; dummy data in al

;---------------------------- exit ----------------------------------;

scanexit:
        pop     di
        pop     es
        ret
scan    endp

        even
buffer  label   byte                    ; 4096-byte buffer starts here

mainseg ends
        end     entry
