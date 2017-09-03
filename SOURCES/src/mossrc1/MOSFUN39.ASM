	include	page.inc
	title	MOSFUN39 - MOS functions 39 - 5C

	subttl	MOSFUN39 Development Specification
	.sall

;-----------------------------------------------------------------------;
;									;
;		      Development Specification 			;
;									;
;									;
; Program Name: $$MOS.COM		 Assigned to: Jim Bean		;
; Module Name:	MOSFUN39		 Assign date: 01/30/86		;
; Entry Points: MOSFUN39-MOSFUN5C	 Completed: 09/03/86		;
; Entry From:	MOSINT21, MOSFUN0F					;
; Entry Method: CALL							;
; Calls:	MOSFUTIL, MOSLIMAN, gettime, caps			;
; Purpose:	File handle functions					;
; Last Update:	07/18/90						;
;									;
; This module handles function calls 39 through 5c.			;
;									;
;-----------------------------------------------------------------------;
;-----------------------------------------------------------------------;
;	COOKING MODS 2/24/87 MJS					;
;									;
;	Moved readguts, writeguts, truncguts and creatguts to the	;
;	MOSMIMAN module.						;
;-----------------------------------------------------------------------;
;	JSM	03/18/87	Large volume support			;
;-----------------------------------------------------------------------;
;	JSM	04/01/87	ALIAS support				;
;-----------------------------------------------------------------------;
;	JSM	04/27/87	make 5c (LOCK) initialize RLB properly	;
;-----------------------------------------------------------------------;
;	JSM	05/02/87	make 4e (find first) deal properly with	;
;				volume labels & alias drives		;
;-----------------------------------------------------------------------;
;       SAH	05/02/87	example dos return codes for sucessfull ;
;				functions in 39+ range which do not     ;
;				return any values in ax and made mos to ;
;				to simulate their returns (set table)   ;
;-----------------------------------------------------------------------;
;       RBR	05/03/87	code optimization                       ;
;-----------------------------------------------------------------------;
;       JRB     05/17/87        create check attribute low byte only    ;
;-----------------------------------------------------------------------;
;       SAH     06/10/87	BBx requires AX to be 00 on fun 4E	;
;                                   requires AX to be 00 on fun 4F	; 
;-----------------------------------------------------------------------;
;	SAH     06/24/87	44 Sub function 2 returns count in AX   ;
;-----------------------------------------------------------------------;
;	JSM	07/21/87	Temporarily enable access to all classes;
;				in 3C (create file) if file does not	;
;				already exist.				;
;-----------------------------------------------------------------------;
;       SAH     08/13/87        Fix bugs with function 44 Sub function  ;
;				6 return status codes back to the caller;
;				Also check out similar sub functions for;
;				silimilar problems.			;
;-----------------------------------------------------------------------;
;        SAH    08/25/87        Fix function 44 sub function 8 which did;
;				termination condition correctly		;
;				Store ds:dx into TCBOPEN60 for use in   ;
;				return information in function 60h      ;
;-----------------------------------------------------------------------;
;	SJC	10/26/87	Optimization.				;
;				Modify OKSWT to check for improper use.	;
;-----------------------------------------------------------------------;
;	SJC	11/10/87	Fixed bug - Execute only files did not	;
;				execute properly.			;
;				MOSFUN3D used current code segment when	;
;				referencing external seg SCBMOSADR.	;
;-----------------------------------------------------------------------;
;	SAH	12/07/87	Fixed bug with function 44 sub-function ;
;				02 in not returning correct value back  ;
;				in AX, because BP is not correct when   ;
;				AX is set.				;
;				This fix also fix problems with sub-	;
;				functions 03,04, and 05			;
;-----------------------------------------------------------------------;
;	SJC	12/13/87	Function 4f clears byte 20 of the DTA.	;
;				This causes problems with LANLink.	;
;				DOS does not clear this byte!		;
;				Set al reg to function number to make	;
;				certain this byte is not cleared in 4f.	;
;-----------------------------------------------------------------------;
;	jrby	12/17/87	allow device find in function 4e	;
;-----------------------------------------------------------------------;
;	SAH	01/21/88	Change SCBSEG and ZERO seg access to	;
;				MGetXXXX macros				;
;-----------------------------------------------------------------------;
; 02/04/88 jrb	don't release one handle's locks on a close on another	;
; jrba		handle							;
;-----------------------------------------------------------------------;
; MJS 2/9/88	Add logic to fun56 (rename) to return access denied if	;
;		the second parm contains any *'s or ?'s.  Also added	;
;		logic to support renaming and relocating of 		;
;		subdirectories.						;
;-----------------------------------------------------------------------;
;  rbr/sah 02/20/88  Move DDT code to MO2 group.			;
;-----------------------------------------------------------------------;
; SAH 04/13/88  Change fun 3d so if openfile got an extended error that ;
;		it will return ACCESS DENIED instead of Path not found  ;
;-----------------------------------------------------------------------;
; jrb 05/02/88  correct ioctl fn 0e and 0f (get/set logical drive)	;
;		change get current dir to do a media check (which also	;
;		returns cdb ptr) because dos does and it's needed on	;
;		floppies						;
;		split mosfun44 into new mosfun44.asm cause mosfun39	;
;		ran out of room						;
;-----------------------------------------------------------------------;
; mjs 7/2/88	Added a call to noswt in mosfun47.  This function had an;
;		okswt call but no call to noswt.			;
;-----------------------------------------------------------------------;
; SAH 07/14/88  Correct function 3f if invalid handle would always try  ;
;		read because flags were not save around and xor cx,cx   ;
;-----------------------------------------------------------------------;
; SAH 08/15/88	Corrected mosfun47 by making sure that the directory 	;
;		path is actually there. Some body could have change 	;
;		disks on us. Clean up source and correct lundefs for	;
;		OPTASM.							;
;-----------------------------------------------------------------------;
; SAH 09/04/88  Corrected function 47h return of ax to 0100h not 100d   ;
;		This solve conflict with Windows write.			;
;-----------------------------------------------------------------------;
; SAH 11/04/88  Remove dependency on mosscbex.inc			;
;-----------------------------------------------------------------------;
; SAH 01/26/89	Change LOCK equate to NLOCK (MASM 5.10 Compatibility)	;
;-----------------------------------------------------------------------;
; mjs 06/06/89	mosfun39 was not checking the entry string for globals	;
;		so it was possible to do a "md a?b" and create a dir	;
;		that could not be removed and which would screw up 	;
;		verify.  I excised code from fun56 and made the 	;
;		procedure chk_glbl.  both fun39 and fun56 call this now.;
;-----------------------------------------------------------------------;
; SAH 12/14/89  Remove mosregs2.inc					;
;-----------------------------------------------------------------------;
; mjs 04/30/90	add setup of al register to pathfind calls.		;
;		add test in mosfun3c and mosfun5b to skip files of the	;
;		same name when creating a label				;
;-----------------------------------------------------------------------;
; SAH 07/18/90	Corrected function 3c for handling creating read-only   ;
;		files.	Also fix fun 5a and 5b for similar condition 	;
;-----------------------------------------------------------------------;

	subttl	description of MOSFUN39 as implemented
	page

;-----------------------------------------------------------------------;
;									;
; jrb 08/19/86 MOSFUN39 implementation comments 			;
;									;
; functions implemented:						;
;   39, 3a, 3b, 3c, 3d, 3e, 3f, 40, 41, 42, 43, 44, 45, 46, 47, 4e, 4f, ;
;   56, 57, 5a, 5b, 5c							;
;									;
; each of the MOSFUN?? functions considers all registers except DS, BP, ;
;   SS, SP, CS and IP as fair game so if you call near instead of doing ;
;   an INT 21H, be warned - also note that the parameters are expected	;
;   in the task register set TAX, TBX, .. - kids don't try this at home ;
;									;
; sector size (BDBSSIZ) must be an integral multiple of 32 (directory	;
;   entry size) 							;
;									;
; RMDIR not allowed if directory is the current directory for any task	;
;									;
; pathdir relies on the .. entry in the subdirectory if .. is specified ;
;   in the path (note that DOS doesn't depend upon the .. entry or even ;
;   seem to use the .. entry)						;
;									;
; timestamp (to get date and time for directory entries) uses gettime	;
;   and getdate extrn functions - gettime and getdate should be 	;
;   provided with the implementation of functions 2AH and 2CH		;
;									;
; little attention is paid to multi-user stuff within a function since	;
;   task switches are locked out for the duration of the dos functions	;
;									;
; reports too many files open if it runs out of heap space trying to	;
;   open a file (allocating a GFB or TFB), or if handle 65535 is the	;
;   only available handle						;
;									;
; reports error 128 (attempt to duplicate a system handle) if FDUP	;
;   or DUP used on a handle which isn't a psp handle                    ;
;									;
; when exec is implemented, it must duplicate access to open files of	;
;   the parent process - it must create a copy of the parent's psp      ;
;   handle table and set each entry to 0ffh whose inheritance bit is 1	;
;   note to deal with special cases like, 20 bytes fits in child psp,	;
;   else space has to be allocated somewhere else and pointed to by	;
;   child psp handle table pointers					;
;									;
; close flushes dir entry info (date, time, size) and written sectors	;
;   each time, the tfb is deleted only when the open count goes to 0,	;
;   the gfb is deleted only if that was the last tfb			;
;									;
; change file mode (43H) sets the new attribute in the gfb (if any) as	;
;   well as in the dir entry						;
;									;
; requires the ability to acquire exclusive access to file to create,	;
;   delete or rename the file (calls exlcude which closes the		;
;   respective file if open)						;
;									;
; chkacc and iolock (checking open access and read/write locks) 	;   
;   suspend the task between retries.					;
;									;
; chkacc, iolock, devread, devwrite all currently pass a null poll	;
;   subroutine pointer to suspend - the null poll always tells MOS	;
;   the task is ready to run						;
;-----------------------------------------------------------------------;
;	Compatibility Table for higher level function AX returns        ;
;									;
;	Function          AX Return	   Updated			;
;	  39		    0005	   SAH  5/02/87			;
;	  3a		    0005	   SAH  5/02/87			;
;	  3b		    0000	   SAH  5/02/87			;
;	  3e		    0006	   SAH	5/02/87 (twin)		;
;	  47		    0100	   MJS				;
;	  4e                0000	   MJS 	(SAH ax) (first choice) ;
;         4f                0000           SAH  6/10/87 (BBx)           ;
;-----------------------------------------------------------------------;

 	include GROUP.INC

	subttl	group segments and include block definitions
	page

;-----------------------------------------------------------------------;
; access to partition saved registers					;
;-----------------------------------------------------------------------;

.xlist
	include MOSREGS.INC

tcb	segment at 1234h
	include MOSTCB.INC	; TCB definition
tcb	ends

	include MOSCDB.INC	; etc., etc., etc.
	include MOSGFB.INC
	include MOSTFB.INC
	include MOSRLB.INC
	include MOSBDB.INC

	include	MACROS.INC

gdata	segment word public 'data'
extrn	scbnoswt:byte, scbtcbpf:word	
gdata	ends

.list

irq	segment byte public 'data'
irq	ends

poll	segment byte public 'data'
poll	ends
	subttl	mos segment - local code and data

mosseg	segment word public 'code1'
mosseg	ends

	page
ddt	segment word public 'code2'
	assume	cs:mo2,ds:grp,es:nothing,ss:tcb

	extrn	mosend:byte, sbios2:word
	extrn	mosliman:near, caps:near
	extrn	gettime:near, execopen:near
	extrn	mo1seg:word			;rs1

	; extrn's from MOSFUTIL.ASM
	extrn	alloclust:near, blkread:near, blkwrite:near
	extrn	chklock:near, closefile:near, clrclust:near, create:near
	extrn	dealloc:near, delete:near, devchk:near, todriver:near
	extrn	emptydir:near, findbdb:near, findgfb:near, findlbl:near
	extrn	findnm:near, findrlb:near, findtfb:near, flushdir:near
	extrn	getfat:near, getphdl:near, makelbl:near
	extrn	moserror:near, nextnm:near, openfile:near
	extrn	pathfind:near, putfat:near, rddir:near, slash:near
	extrn	timestamp:near, wrsector:near, setphdl:near, iolock:near
	extrn	devread:near, devwrite:near, finddrv:near, exclude:near
	extrn	okchar:near, encrypt:near, decrypt:near, classlvl:near
	extrn	cpycmap:near, eblcmap:near, capscmps:near

	; extrn's from MOSMIMAN.ASM
	extrn	readguts:near, writeguts:near, truncguts:near
	extrn	creatguts:near, checkexon:near
	extrn	buffinp:near, cdevinp:near

	public	okswt, noswt, sttax0
	public		  mosfun39, mosfun3a, mosfun3b
	public	mosfun3c, mosfun3d, mosfun3e, mosfun3f
	public	mosfun40, mosfun41, mosfun42, mosfun43
	public	mosfun45, mosfun46, mosfun47
	public			    mosfun4e, mosfun4f
	public			    mosfun56, mosfun57
	public			    mosfun5a, mosfun5b
	public	mosfun5c

if 0 eq 0		; trick PUBLIC.COM

;-----------------------------------------------------------------------;
; error codes defined							;
;-----------------------------------------------------------------------;

INVFN	EQU	1		; invalid function (or sub-function)
FILENF	EQU	2		; file not found (or invalid name)
PATHNF	EQU	3		; path not found (or invalid path)
MANYFIL EQU	4		; too many files open
ACCDENY EQU	5		; access denied
INVHDL	EQU	6		; invalid handle (file not open)
INVACC	EQU	12		; invalid access code specified
DRIVENF EQU	15		; drive not found (or invalid drive)
DELCURD EQU	16		; attempt to delete current directory
DIFFDEV EQU	17		; not the same device
NOMORE	EQU	18		; no more files found
SHARE	EQU	32		; sharing violation
NLOCK	EQU	33		; lock violation
SHAREOV EQU	36		; share buffer overflow (couldn't alloc RLB)
FILEXST EQU	80		; file already exists
FAIL24H EQU	83		; fail chosen from INT 24H (as defined by DOS)
SYSHDL	EQU	127 OR 8000H	; attempt to DUP or FDUP a non-psp handle
XSHARE	EQU	SHARE OR 8000H	; fail from INT 24H sharing
XLOCK	EQU	NLOCK OR 8000H	; fail from INT 24H locking
ERR24H	EQU	FAIL24H OR 8000H; fail error from INT 24H (signal for MOSERROR)
INTERN	EQU	80FFH		; internal error

;-----------------------------------------------------------------------;
; directory entry fields						;
;-----------------------------------------------------------------------;

DATR	EQU	11		; offset of attribute byte
DCLASS0 EQU	13		; offset of class byte
DTIME	EQU	22		; offset of time word
DDATE	EQU	24		; offset of date word
DSIZE	EQU	28		; offset of size dword
DCLUST	EQU	26		; offset of bof cluster word

;-----------------------------------------------------------------------;
; directory entry file attribute bits defined				;
;-----------------------------------------------------------------------;

OVERRIDE EQU	80H		; dir search class level override
ARCH	EQU	20H		; archive
DIR	EQU	10H		; directory
LBL	EQU	08H		; label
SYS	EQU	04H		; system
HID	EQU	02H		; hidden
RO	EQU	01H		; read-only

;-----------------------------------------------------------------------;
; critical error coding 						;
;-----------------------------------------------------------------------;

RDX	EQU	00H		; read operation
WRX	EQU	01H		; write operation

FAILX	EQU	08H		; fail not allowed
RETRYX	EQU	10H		; retry not allowed
IGNOREX EQU	20H		; ignore not allowed
ALLX	EQU	FAILX OR RETRYX OR IGNOREX
SYSX	EQU	FAILX OR RETRYX ; ignore not allowed in system areas

DOSX	EQU	00H OR ALLX	; dos area of disk?
FATX	EQU	02H OR SYSX	; fat area
DIRX	EQU	04H OR SYSX	; dir area
DATAX	EQU	06H OR ALLX	; data area

endif

	assume	cs:mo2,ds:nothing,es:nothing,ss:nothing
noswt	proc	near
	push	ds
	MGetSCB2 ds
	assume  ds:grp
	inc	[scbnoswt]
	pop	ds
	assume  ds:nothing
	ret
noswt	endp

;-----------------------------------------------------------------------;

okswt	proc	near
	push	ds
	MGetSCB2 ds
	assume  ds:grp

	cmp	[scbnoswt],0	;SJC guard against improper use of NOSWT/OKSWT
	jz	endok		; if already zero, don't decrement
	dec	[scbnoswt]

	; Check for pending task switch here!

	assume  ds:nothing
endok:
	pop	ds
	ret

okswt	endp

;- CHK_GLBL ------------------------------------------------------------;
; entry parms:	es:di -> string to check				;
; exit parms:	ax = 0 if no globals, ACCDENY if any found		;
;									;
; NOTES: 								;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:nothing
chk_glbl:
	push	bx
	push	cx
	push	si
	push	di
	mov	si,di
	mov	cx,0ffffh
	cld
	xor	al,al		; find length of string
	repne	scasb
	mov	cx,di
	sub	cx,si
	mov	di,si
	mov	al,'?'
	push	cx
	repne	scasb
	pop	cx
	je	chkglbl1
	mov	di,si
	mov	al,'*'
	xor	bx,bx
	repne	scasb
	je	chkglbl1
	xor	ax,ax
	jmp	chkglbl2
chkglbl1:
	mov	ax,ACCDENY
chkglbl2:
	pop	di
	pop	si
	pop	cx
	pop	bx
	ret


	subttl	mosfun39 - create dir (MKDIR)
	page
;-----------------------------------------------------------------------;
;									;
; MOS function 39H - Create a dir (MKDIR)				;
;									;
; entry:								;
;   TDS:TDX -> ASCIIZ string specifying path and dir to create		;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	PATHNF	- invalid drive specified				;
;		  invalid path specified				;
;		  path not found					;
;		  subdir name is invalid				;
;	ACCDENY - a file or dir with the same drive, path and name (or	;
;		    a device with the same name) already exists 	;
;		  the root dir is full					;
;		  the parent dir is full and the disk is full so the	;
;		    parent dir can't be extended                        ;
;	& critical error codes						;
;   CARRY bit of TFLAG clear if no error				;
;									;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun39

lword	pcluster		; first cluster of parent dir (0 if root)
lword	ccluster		; first cluster of new subdir
lword	pofs			; offset in sector of parent dir entry
ldword	psect			; sector of parent dir entry
lstring fnm,11			; dir entry formatted name of new subdir
lstring	secbuf,<size sectorblk>	; buffer for sector number

	call	usts0		; use task regs
	call	chk_glbl
	or	ax,ax
	jnz	jmosf39y

;-----------------------------------------------------------------------;
; validate drive, path and subdir name					;
;-----------------------------------------------------------------------;

	mov	[fnm],' '	; to detect drive only path
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1		; skip labels
	call	pathfind

	assume	ds:bdb,es:nothing

	jc	mosf39a
	mov	ax,ACCDENY	; name already exists in subdir
jmosf39y:
	jmp	mosf39y
mosf39a:
	cmp	ax,FILENF
	jne	jmosf39y 	; ne includes PATHNF
	mov	ax,PATHNF
	cmp	[fnm],' '
	je	jmosf39y 	; invalid if only drive supplied in path
	mov	ax,ACCDENY	; must have read/write access to parent dir
	cmp	cl,3
	jb	jmosf39y
	mov	[pcluster],dx
;-----------------------------------------------------------------------;
; create dir entry in parent dir for subdir				;
;-----------------------------------------------------------------------;
	push	ss
	pop	es
	lea	di,fnm
	mov	al,DIR
	call	create		; make a dir entry (fails if duplicate)
	jc	jmosf39y 	; (error - nothing to undo)
	mov	[pofs],si
	mov	dx,[secbuf].seclow
	mov	word ptr [psect],dx
	mov	dx,[secbuf].sechigh
	mov	word ptr [psect+2],dx
;-----------------------------------------------------------------------;
; allocate and clear a cluster for the subdir				;
;-----------------------------------------------------------------------;
	mov	dx,0ffffh	; no clusters allocated so far
	call	alloclust	; allocate a cluster to the dir entry
	jc	mosf39x 	; (error - del dir entry, no cluster)
	mov	[ccluster],dx
	call	clrclust
	jc	mosf39w 	; (error - del dir entry, dealloc cluster)
;-----------------------------------------------------------------------;
; assign allocated cluster to new dir entry				;
;-----------------------------------------------------------------------;
	call	rddir		; ss:bx -> parent dir entry sector
	jc	mosf39w 	; (error - del dir entry, dealloc cluster)

	assume	es:dbb
				; si = parent dir entry offset
	mov	word ptr [si+dbbbuf+DCLUST],dx
	call	wrsector
	jc	mosf39x 	; (error - del dir entry with cluster)
;-----------------------------------------------------------------------;
; set up . (self-reference) and .. (parent) dir entries in subdir	;
;-----------------------------------------------------------------------;
	push	ss
	pop	es
	assume	es:tcb

	lea	di,fnm
	mov	al,'.'		; construct . name
	stosb
	mov	ax,'  '
	mov	cx,10/2
	rep stosw
	lea	di,fnm
	mov	al,DIR		; dx = subdir start cluster
	call	create		; . (self-reference) entry
	jc	mosf39x
	mov	[fnm+1],'.'	; (constructs .. name)
	mov	al,DIR		; dx = subdir start cluster, di -> fnm
	call	create		; .. (parent-reference) entry
	jc	mosf39x
;-----------------------------------------------------------------------;
; supply starting cluster to . and .. dir entries			;
;-----------------------------------------------------------------------;
	call	rddir
	jc	mosf39x

	assume	es:dbb
				; si -> .. entry (immediately follows . entry)
	mov	word ptr [dbbbuf+si-32+DCLUST],dx
	mov	ax,[pcluster]
	mov	word ptr [dbbbuf+si+DCLUST],ax
	call	wrsector
	jc	mosf39x
	call	flushdir	; flush any changed fat and dir sectors
	jc	mosf39x
	xor	ax,ax		; no error
	jmp	short mosf39y
;-----------------------------------------------------------------------;
; error before new dir entry owns cluster, so explicitly dealloc it	;
;-----------------------------------------------------------------------;
mosf39w:
	push	ax
	mov	dx,[ccluster]
	call	dealloc
	pop	ax
mosf39x:
;-----------------------------------------------------------------------;
; error after creating dir entry, so del it				;
;-----------------------------------------------------------------------;
	push	ax
	mov	ax,word ptr [psect]
	mov	[secbuf].seclow,ax
	mov	ax,word ptr [psect+2]
	mov	[secbuf].sechigh,ax
	lea	bx,[secbuf]
	mov	si,[pofs]
	call	delete		; delete the dir entry, dealloc cluster if any
	call	flushdir	; flush changed fat and dir sectors
	pop	ax

	assume	ds:nothing,es:nothing,ss:tcb
mosf39y:
	mov	dx,5		; SJC optimize, set return code of 5 per SAH
	mov	cx,PATHNF
	call	repo0		; report error and return codes for task

lundef	pcluster
lundef	ccluster
lundef	pofs
lundef	psect
lundef	fnm
lundef	secbuf

lendp	mosfun39

	subttl	mosfun3a - remove dir (RMDIR)
	page
;-----------------------------------------------------------------------;
;									;
; MOS function 3AH - Remove a dir (RMDIR)				;
;									;
; entry:								;
;   TDS:TDX -> ASCIIZ string specifying path and dir to remove		;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	PATHNF	- invalid path specified				;
;		  path not found					;
;		  subdir not found					;
;		  the subdir is not valid				;
;	ACCDENY - the subdir is the current dir for another task	;
;		  the subdir is not empty				;
;	DELCURD - the subdir is the current dir for this task		;
;	& critical error codes						;
;   CARRY bit of TFLAG clear if no error				;
;									;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun3a

ldword	psect
lword	pofs
lword	pclust
lword	xtcb
lstring fnm,11
lstring	secbuf,<size sectorblk>

	call	usts0		; use task regs, no switch

;-----------------------------------------------------------------------;
; validate drive, path and dir name					;
;-----------------------------------------------------------------------;
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1		; skip labels
	call	pathfind

	assume	ds:bdb,es:nothing

	jc	jmosf3ax
	cmp	al,'?'
	mov	ax,PATHNF
	je	jmosf3ax 	; no wild-cards allowed
	or	bx,bx
	jz	jmosf3ax 	; device isn't a directory
	mov	ax,ACCDENY
	cmp	dx,-1
	je	jmosf3ax 	; can't remove root dir
	cmp	cl,3		; must have read/write access to parent dir
	jb	jmosf3ax
	mov	[pclust],dx	; dx = cluster for parent dir

	assume	es:dbb

	test	[dbbbuf+si+DATR],DIR
	jmpz	mosf3ax 	; not a directory
	mov	dx,word ptr [dbbbuf+si+DCLUST]
;-----------------------------------------------------------------------;
; verify that subdir is a valid, empty subdir:				;
; 1.  first entry is a dir named . which owns the subdir cluster	;
; 2.  second entry is a dir named .. which owns the parent cluster	;
; 3.  there are no other entries					;
;-----------------------------------------------------------------------;

;-----------------------------------------------------------------------;
; read the first sector of the subdir					;
;-----------------------------------------------------------------------;
	mov	[pofs],si
	mov	si,[secbuf].seclow
	mov	word ptr [psect],si
	mov	si,[secbuf].sechigh
	mov	word ptr [psect+2],si
	mov	bx,dx		; dx = cluster for subdir
	cmp	bx,[bdbcnum]	; validate subdir cluster number
	jnc	jmosf3ax
	sub	bx,2
	jc	jmosf3ax
	xor	cx,cx
	mov	[secbuf].sechigh,cx
	mov	cl,[bdbcshl]
	jcxz	mosf3a1
mosf3a0:
	shl	bx,1
	rcl	[secbuf].sechigh,1
	loop	mosf3a0
mosf3a1:
	add	bx,[bdbclus]	; bx = sector for subdir
	adc	[secbuf].sechigh,cx	; cx is 0
	mov	[secbuf].seclow,bx
	lea	bx,[secbuf]
	call	rddir
	jnc	$+5
jmosf3ax:
	jmp	mosf3ax

	assume	es:dbb

;-----------------------------------------------------------------------;
; first entry must be a dir named . owning the subdir cluster		;
;-----------------------------------------------------------------------;
	lea	di,dbbbuf
	mov	al,'.'
	scasb
	jne	mosf3ab
	mov	ax,'  '
	mov	cx,10/2
	repe scasw
	jne	mosf3ab
	test	[dbbbuf+DATR],DIR
	jz	mosf3ab
	cmp	word ptr [dbbbuf+DCLUST],dx
	jne	mosf3ab
;-----------------------------------------------------------------------;
; second entry must be a dir named .. owning the parent dir cluster	;
;-----------------------------------------------------------------------;
	lea	di,dbbbuf+32
	mov	ax,'..'
	scasw
	jne	mosf3ab
	mov	al,' '
	mov	cx,11-2
	repe scasb
	jne	mosf3ab
	test	byte ptr [dbbbuf+32+DATR],DIR
	jz	mosf3ab
	mov	ax,[pclust]
	cmp	word ptr [dbbbuf+32+DCLUST],ax
	je	mosf3ac
mosf3ab:
	mov	ax,PATHNF	; DOS returns PATHNF for invalid subdir
	jmp	short jmosf3ax
;-----------------------------------------------------------------------;
; there can be no other entries 					;
;-----------------------------------------------------------------------;
mosf3ac:
	push	ss
	pop	es
	assume	es:tcb

	lea	di,fnm		; construct fnm *.* to match any other entry
	mov	cx,11		;   in subdir
	mov	al,'?'
	rep stosb
	lea	di,fnm
	mov	si,32*2 	; point at third dir entry to start
	call	nextnm		; dx = cluster for subdir
	mov	cx,ax
	mov	ax,ACCDENY
	jnc	mosf3ax 	; nc if dir not empty
	mov	ax,cx
	cmp	ax,FILENF
	jne	mosf3ax 	; ne if error other than name not in directory
;-----------------------------------------------------------------------;
; subdir can't be any task's current dir				;
;-----------------------------------------------------------------------;
	
	MGetSCB2 es
	assume	es:grp

	mov	bx,[scbtcbpf]	; first tcb

	assume	ss:nothing	; (make sure ss not used to address tcb's)
;-----------------------------------------------------------------------;
; for every task							;
;-----------------------------------------------------------------------;
mosf3ad:
	or	bx,bx
	jz	mosf3af
	mov	es,bx

	assume	es:tcb

	mov	[xtcb],bx	; remember which tcb we're looking at
	mov	bx,[tcbtcbpn]
	mov	cx,[tcbcdbpf]
;-----------------------------------------------------------------------;
; look through cdb's for task to find cdb for subdir drive              ;
;-----------------------------------------------------------------------;
mosf3ae:
	mov	ax,INTERN	; internal error - every task has a cdb for
	jcxz	mosf3ax 	;   every drive 			    
	mov	es,cx

	assume	es:cdb

	mov	cx,[cdbnext]
	mov	al,[bdbid]
	cmp	al,[cdbdrive]
	jne	mosf3ae 	; e when we've found the correct drive
;-----------------------------------------------------------------------;
; and make sure it's not the same as the subdir                         ;
;-----------------------------------------------------------------------;
	cmp	dx,[cdbclus]
	jne	mosf3ad
	mov	ax,ss
	cmp	ax,[xtcb]
	mov	ax,DELCURD	; tried to delete own task's current dir
	je	mosf3ax 	;   if e
	mov	ax,ACCDENY	; else tried to delete another task's current
	jmp	short mosf3ax 	;   dir
;-----------------------------------------------------------------------;
; delete subdir and flush changed sectors				;
;-----------------------------------------------------------------------;
	assume	es:nothing,ss:tcb
mosf3af:
	mov	bx,word ptr [psect]
	mov	[secbuf].seclow,bx
	mov	bx,word ptr [psect+2]
	mov	[secbuf].sechigh,bx
	lea	bx,[secbuf]	
	mov	si,[pofs]
	call	delete		; delete subdir and dealloc any clusters
	jc	mosf3ax
	call	flushdir	; flush everything out to disk
	jc	mosf3ax
	xor	ax,ax

	assume	ds:nothing,es:nothing,ss:tcb
mosf3ax:
	cmp	ax,FILENF
	jne	mosf3ay
	mov	ax,PATHNF
mosf3ay:
	mov	dx,5		; per SAH  success code
	mov	cx,PATHNF
	call	repo0

lundef	psect
lundef	pofs
lundef	pclust
lundef	xtcb
lundef	fnm
lundef	secbuf

lendp	mosfun3a

	subttl	mosfun3b - change the current directory (CHDIR)
	page
;-----------------------------------------------------------------------;
;									;
; MOS function 3BH - Change the current directory (CHDIR)		;
;									;
; entry:								;
;   TDS:TDX -> ASCIIZ string with subdirectory to change to		;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	PATHNF	- invalid path specified				;
;		  path not found					;
;		  subdirectory not found				;
;		  subdirectory not a valid subdirectory 		;
;	& critical error codes						;
;   CARRY bit of TFLAG clear if no error				;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun3b

lbyte	clvl
lword	cdbptr
lword	rootclust
ldword	pathptr
lstring fnm,64
lstring	secbuf,<size sectorblk>

	call	usts0		; task regs, no switch

;-----------------------------------------------------------------------;
; validate drive, path and dir name					;
;-----------------------------------------------------------------------;
	mov	word ptr [pathptr],di
	mov	word ptr [pathptr+2],es
	lea	si,fnm		; pathfind serves to validate path and access
	lea	bx,secbuf
	mov	al,1		; skip labels
	call	pathfind	;   level

	assume	ds:bdb,es:nothing

	mov	[clvl],cl
	jc	jmosf3bx
	cmp	al,'?'
	mov	ax,PATHNF
	je	jmosf3bx 	; no wild-cards allowed
	or	bx,bx
	jz	jmosf3bx 	; can't set dir to device name
	inc	dx
	jnz	mosf3ba2	; if not a root of a physical disk
	mov	dx,[bdbroot]	; get root directory for the disk
	jmp	short mosf3ba3

	assume	es:dbb
mosf3ba2:
	test	[dbbbuf+si+DATR],DIR
	jz	jmosf3bx 	; not a directory
	mov	dx,word ptr [dbbbuf+si+DCLUST]
	mov	ax,PATHNF
	jne	mosf3ba3
jmosf3bx:
	jmp	mosf3bx
;-----------------------------------------------------------------------;
; find current directory block for this task for this drive		;
; set new subdir data in cdb						;
; but remember old data in case of error				;
;-----------------------------------------------------------------------;
mosf3ba3:
	mov	cx,[bdbroot]	; root directory cluster for the real drive
	mov	[rootclust],cx
	mov	bl,[bdbid]
	mov	cx,[tcbcdbpf]
	mov	ax,INTERN
	or	dx,dx
	jnz	mosf3ba4	; make sure root access is read/write
	mov	[clvl],3
mosf3ba4:
	or	cx,cx		; internal error if drive not represented among
	jz	jmosf3bx 	;   cdb's
	mov	ds,cx

	assume	ds:cdb

	mov	cx,[cdbnext]
	cmp	bl,[cdbdrive]
	jne	mosf3ba4
	lea	si,cdbpath
	push	ss
	pop	es
	lea	di,fnm
	mov	cx,64/2
	rep movsw		; remember old current dir string
	xchg	[cdbclus],dx	; remember old current dir cluster
	mov	al,[clvl]
	xchg	[cdblvl],al
	mov	[clvl],al
	push	ds
	pop	es
	assume	es:cdb

	lds	si,[pathptr]

	assume	ds:nothing

	cmp	byte ptr ds:[si+1],':'
	jne	mosf3bb
	add	si,2		; past drive designator
mosf3bb:
	lea	di,cdbpath
	lodsb
	call	slash
	je	mosf3bc 	; e if starting path with root
;-----------------------------------------------------------------------;
; starting path with current dir (find end of current dir string)	;
;-----------------------------------------------------------------------;
	dec	si		; correcting for lodsb
	cmp	dx,[rootclust]	; (cluster of previous current dir)
	jz	mosf3bc 	; current dir is root
	mov	cx,64
	xor	al,al
	repne scasb
	mov	byte ptr es:[di-1],'\'
mosf3bc:
	lodsw
	cmp	al,'.'
	mov	al,ah
	mov	ah,0
	jne	mosf3bd
	dec	di		; backup onto last slash
	or	al,al
	jz	mosf3be1	; so zero is written on top of it if '.',00h
	inc	di
	call	slash
	je	mosf3bc 	; skip any .\ encountered
	cmp	al,'.'
	jne	mosf3bd 	; isn't ..
	mov	al,[si]
	or	al,al
	jz	mosf3bc1
	call	slash
	jne	mosf3bd
mosf3bc1:
;-----------------------------------------------------------------------;
; on ..\ scan backwards to preceding \	or beginning of dir string	;
;-----------------------------------------------------------------------;
	sub	di,2		; di preceding last \
	mov	cx,di
	sub	cx,offset cdbpath-1
	mov	al,'\'
	std
	repne scasb
	cld
	inc	di		; onto encountered \ (or to cdbpath)
	lodsb
	or	al,al
	jz	mosf3be1
	mov	al,'\'		; must be \ if not 0
	cmp	di,offset cdbpath
	jne	mosf3be1
	jmp	mosf3bc 	; don't need slash at start of cd string
;-----------------------------------------------------------------------;
; not .\ or ..\ so just copy it to dir string				;
;-----------------------------------------------------------------------;
mosf3bd:
	sub	si,2
mosf3be:
	lodsb
	callmos1 caps		;** Call in MOS segment
	cmp	al,'/'
	jne	mosf3be1
	mov	al,'\'
mosf3be1:
	cmp	di,offset cdbpath+64
	jae	mosf3bf 	; new current dir path is too long
	stosb
	or	al,al
	jz	mosf3be2
	cmp	al,'\'
	je	mosf3bc
	jmp	mosf3be
mosf3be2:
	dec	di		; remove any trailing spaces (who needs 'em)
	cmp	byte ptr es:[di],' '
	je	mosf3be2
	inc	di
	stosb
	jmp	mosf3bx
mosf3bf:
;-----------------------------------------------------------------------;
; if string too long or encountered ..\ at root,			;
; restore previous current dir information				;
;-----------------------------------------------------------------------;
	mov	[cdbclus],dx
	mov	al,[clvl]
	mov	[cdblvl],al
	lea	di,cdbpath
	push	ss
	pop	ds
	assume	ds:tcb

	lea	si,fnm
	mov	cx,64/2
	rep movsw
	mov	ax,PATHNF

	assume	ds:nothing,es:nothing,ss:tcb
mosf3bx:
	cmp	ax,FILENF
	jne	mosf3by
	mov	ax,PATHNF
mosf3by:
	xor	dx,dx		; per SAH-return code of zero
	mov	cx,PATHNF
	call	repo0		; report

lundef	clvl
lundef	cdbptr
lundef	rootclust
lundef	pathptr
lundef	fnm
lundef	secbuf

lendp	mosfun3b

	subttl	mosfun3c - create a file (CREAT)
	page
;-----------------------------------------------------------------------;
;									;
; MOS function 3CH - Create a file (CREAT)				;
;   file is opened in compatibility sharing mode with read/write access ;
;									;
; entry:								;
;   TDS:TDX -> ASCIIZ string with drive, path and file to create	;
;   TCX = attribute for created file					;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	PATHNF	- invalid path specified				;
;		  path not found					;
;		  invalid file name specified				;
;	ACCDENY - the root directory is full				;
;		  the disk is full					;
;		  see attribute discussion below			;
;	MANYFIL - too many files open					;
;	& critical error codes						;
;   CARRY bit of TFLAG clear if no error				;
;     TAX = file handle (if not label)					;
;									;
; access permission established as follows:				;
;									;
; bits 15-6 - invalid bits						;
;   if set in CREAT attribute						;
;     then access denied						;
;   else								;
;     bit 5 - 20H - archive bit 					;
;	ignored 							;
;     bit 3 - 08H - volume label bit					;
;	if set in CREAT attribute					;
;	  then								;
;	    if set in any root dir entry				;
;	      then access denied					;
;	else								;
;	  bit 4 - 10H - sub-directory bit				;
;	    if set in CREAT attribute or dir entry			;
;	      then access denied					;
;	    else							;
;	      bit 0 - 01H - read-only bit				;
;		if set in the dir entry 				;
;		  then access denied					;
;		else							;
;		  bit 2 - 04H - system bit				;
;		    if set in the dir entry				;
;		      if clear in the CREAT attribute			;
;			then access denied				;
;		  bit 1 - 02H - hidden bit				;
;		    if set in the dir entry				;
;		      if clear in the CREAT attribute			;
;			then access denied				;
;									;
; file creation as follows:						;
;									;
; bit 3 - 08H - volume label bit					;
;   if set in CREAT attribute						;
;     then								;
;	create the file in the root dir 				;
;	set bit 3 of attribute						;
;   else								;
;     create the file according to the path				;
;     bit 2 - 04H - system bit						;
;	if set then set bit 2 of attribute				;
;     bit 1 - 02H - hidden bit						;
;	if set then set bit 1 of attribute				;
;     bit 0 - 01H - read-only bit					;
;	if set then set bit 0 of attribute				;
; bit 5 - 20H - archive bit						;
;   set bit 5 of attribute						;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun3c

lword	bufptr			; pointer to sector buffer
lbyte	clvl			; cumulative access level into parent
lbyte	fattr			; file attribute
lstring	clsmap,<size tcbcmap>	;JSM copy of class map for task
lstring fnm,11			; dir entry formatted file name
lstring	secbuf,<size sectorblk>	; sector number buffer

	lea	si,[tcbcmap]	;JSM copy tcbcmap -> clsmap
	lea	di,[clsmap]	;JSM save original class access map
	call	cpycmap		;JSM

	mov	bx,bp
	mov	bp,[bp]
	mov	es,[TDS]
	mov	di,[TDX]
	mov	cx,[TCX]
	mov	bp,bx
	call	noswt		; no task switches allowed
;-----------------------------------------------------------------------;
; validate attribute							;
;-----------------------------------------------------------------------;
	mov	[fattr],cl	; save file attribute for later
	test	cl,not ( ARCH OR DIR OR LBL OR SYS OR HID OR RO )
	mov	ax,ACCDENY
	jnz	jmosf3cx 	; fail if any invalid attribute bit set
	mov	[fnm],' '	; to check for null path (drive only)
	lea	si,fnm
	lea	bx,secbuf
	push	cx
	mov	al,1		; skip labels
	test	cl,LBL
	jz	mosf3ce
	xor	al,al		; unless specified in entry cx
mosf3ce:
	call	pathfind
	mov	[bufptr],bx
	mov	[clvl],cl
	pop	cx

	assume	ds:bdb,es:dbb

	jc	mosf3ca 	; error or name not in directory
	cmp	al,'?'
	mov	ax,ACCDENY
	je	jmosf3cx 	; no wild-cards allowed
	or	bx,bx
	jz	mosf3cb 	; name refers to a device
	cmp	dx,-1
	je	jmosf3cx 	; root dir is invalid file to create


; if supposed to create a volume label, make sure pathfind doesn't
; find a file by the same name.

	test	cl,LBL
	jz	mosf3ch
mosf3cg:
	assume	es:dbb
	test	[dbbbuf+si+DATR],LBL
	jnz	mosf3ch			; fail if not a label
	mov	di,ss
	mov	es,di
	lea	di,fnm			; when find a file
	add	si,32			; must keep checking
	lea	bx,secbuf
	call	nextnm
	jc	mosf3ca			; exit loop when can't find more
	jmp	short mosf3cg
mosf3ch:

	mov	ah,[clvl]
	call	truncguts
	jnc	mosf3cb
jmosf3cx:
	jmp	short mosf3cx

;-----------------------------------------------------------------------;
; no dir entry with that name, create a new one with supplied attrib	;
;-----------------------------------------------------------------------;
mosf3ca:
	cmp	ax,FILENF
	jne	mosf3cx 	; some error other than not found
	mov	ax,PATHNF
	cmp	[fnm],' '						     
	je	mosf3cx 	; drive was only path item supplied
	push	ss
	pop	es
	assume	es:tcb

	mov	ah,[clvl]
	lea	di,[fnm]
	call	creatguts
	jc	mosf3cx
	call	eblcmap		;JSM enable access to all classes
mosf3cb:
;-----------------------------------------------------------------------;
; open file and return handle						;
;-----------------------------------------------------------------------;
	mov	al,02h		; set to read-write access
	test	[fattr],01h	; is this for Read-Only access
	jz	mosf3cbx
	dec	al
mosf3cbx:
	mov	ah,[clvl]
	mov	bx,[bufptr]
	call	openfile

	pushf			;JSM
	push	si		;JSM
	push	di		;JSM
	lea	si,[clsmap]	;JSM restore original class access map
	lea	di,[tcbcmap]	;JSM copy clsmap -> tcbcmap
	call	cpycmap		;JSM
	pop	di		;JSM
	pop	si		;JSM
	popf			;JSM

	jc	mosf3cx

	assume	es:tfb

	call	getphdl 	; get free handle from psp table
	mov	ax,[tfbhdl]
	xchg	ax,bx
	jc	mosf3cc 	; c if no room in psp table (no error)
	xchg	ax,bx
	call	setphdl 	; set system handle into psp table
	jnc	mosf3cc
	mov	bx,[tfbhdl]	; c if tfbhdl is a system handle (no error)
mosf3cc:
	mov	[tfbfnh],bx	;jrba
	mov	ds,[tfbgfb]

	assume	ds:gfb

	cmp	[gfbdev],0
	jne	mosf3cd
	mov	[gfbwrtn],'Y'
	or	[tfbioctl],40h	; signal file has been written (if not device)
mosf3cd:
	call	rethan		; return handle to task

;-----------------------------------------------------------------------;
; no error recovery - if new entry, we didn't succeed in adding it      ;
; if truncated, we lost the allocation chain anyway			;
;-----------------------------------------------------------------------;
	assume	ds:nothing,es:nothing,ss:tcb
mosf3cx:
	mov	cx,PATHNF
	call	repo1		; report


lundef	bufptr
lundef  clvl
lundef	fattr
lundef	clsmap
lundef	fnm
lundef	secbuf

lendp	mosfun3c

	subttl	mosfun3d - open a file
	page
;-----------------------------------------------------------------------;
;									;
; MOS function 3DH - open a file					;
;									;
; entry:								;
;   TDS:TDX -> ASCIIZ string with drive, path and file to open		;
;   TAL = open mode							;
;     bit 7 = 0 - inherited by child processes				;
;	      1 - or not						;
;     bits 6-4 = 000 - compatibility mode				;
;		 001 - deny read/write (nothing ok)			;
;		 010 - deny write (read ok)				;
;		 011 - deny read (write ok)				;
;		 100 - deny none (read, write, read/write all ok)	;
;     bit 3 = 0 (reserved)						;
;     bits 2-0 = 000 - read only access required			;
;		 001 - write only access required			;
;		 010 - read and write access required			;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	PATHNF	- invalid path specified				;
;		  path not found					;
;		  invalid file name specified				;
;	FILENF	- file not found					;
;	ACCDENY - can't grant requested access                          ;
;		  can't restrict access as requested                    ;
;	INVVACC - invalid access code					;
;	MANYFIL - too many files open					;
;	& critical errors						;
;   CARRY bit of TFLAG clear if no error				;
;     TBX = handle of opened file					;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun3d

lbyte	clvl			; cumulative access level into parent
lbyte	access			; attribute for created file
lword	pseg			; if device, seg for driver
lstring fnm,11			; dir entry formatted file name
lstring	secbuf,<size sectorblk>	; buffer for sector number

	mov	bx,bp
	mov	bp,[bp]
	mov	es,[TDS]
	mov     word ptr [TCBOPEN60+2],es
	mov	di,[TDX]
	mov	word ptr [TCBOPEN60],di
	mov	al,[TAL]
	mov	bp,bx
	call	noswt		; no task switches allowed
;-----------------------------------------------------------------------;
; validate access							;
;-----------------------------------------------------------------------;
	mov	[access],al
	mov	bl,al		; remember access
	mov	bh,al
	mov	ax,INVACC
	test	bl,8		; invalid bit
	jnz	jmosf3dx
	and	bl,07h
	cmp	bl,3
	jae	jmosf3dx 	; invalid access requested
	and	bh,70h
	cmp	bh,50h
	jae	jmosf3dx 	; invalid share mode requested
;-----------------------------------------------------------------------;
; validate drive, path and name and look up name in dir 		;
;-----------------------------------------------------------------------;
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1		; skip labels
	call	pathfind

	mov	[clvl],cl

	assume	ds:bdb,es:nothing

	jc	jmosf3dx

	call	ckexcl		; check for exclusion from except/only
	jnc	noex1
	mov	ax,ACCDENY
jmosf3dx:
	jmp	mosf3dx

noex1:
	cmp	al,'?'
	mov	ax,FILENF
	je	jmosf3dx 	; no wild-cards allowed
	mov	[pseg],es	; (if a device, then segment for driver)
	or	bx,bx
	jz	mosf3da 	; name refers to a device
;-----------------------------------------------------------------------;
; found a dir entry, check attribute					;
;-----------------------------------------------------------------------;
	mov	ax,ACCDENY
	cmp	dx,-1
	je	jmosf3dx

	assume	es:dbb

	mov	ax,ACCDENY
	test	[dbbbuf+si+DATR],LBL or DIR
	jnz	jmosf3dx 	; no good if it's a label or directory
	test	[access],07h
	jz	mosf3da 	; else ok if only need read access to the file
	test	[dbbbuf+si+DATR],RO
	jnz	jmosf3dx 	; else must not be a read-only file
mosf3da:
;-----------------------------------------------------------------------;
; open file and return handle						;
;-----------------------------------------------------------------------;

	mov	al,[access]	; compatibility sharing, read/write,
	mov	es,[pseg]

	assume	es:nothing

	mov	ah,[clvl]
	call	openfile
	jc	mosf3dx
	assume	es:tfb

	mov	cx,bp		; if open is from exec function 00h - allow
	mov	bp,[bp] 	;   one higher access to tcb

	mov	dx,[mo1seg]	;rs1  this is the MOS group segment address

	cmp	dx,[TCS]	; test if EXEC did it
	jne	mosf3da1
	cmp	[TIP],offset mos:execopen
	jne	mosf3da1
	test	[TFLAG],ZERO
	jz	mosf3da1	; nz if exec function 00h using open (zero set)
	inc	[tfblvl]
mosf3da1:
	mov	bp,cx
	call	getphdl 	; get free handle from psp table
	mov	ax,[tfbhdl]
	xchg	ax,bx
	jc	mosf3db 	; c if no room in psp table (no error)
	xchg	ax,bx
	call	setphdl 	; set system handle into psp table
	jnc	mosf3db
	mov	bx,[tfbhdl]	; c if tfbhdl is a system handle (no error)
mosf3db:
	mov	[tfbfnh],bx	;jrba
	call	rethan		; return handle
	
	assume	ds:nothing,es:nothing,ss:tcb
mosf3dx:
	mov	cx,ACCDENY	;SAH 04/13/88
	call	repo1

lundef	clvl
lundef	pseg
lundef	access
lundef	fnm
lundef	secbuf

lendp	mosfun3d

	subttl	mosfun3e - close a file handle
	page
;-----------------------------------------------------------------------;
;									;
; MOS function 3EH - close a file					;
;									;
; entry:								;
;   TBX = handle for file or device to close				;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle specified				;
;	& critical errors						;
;   CARRY bit of TFLAG clear if no error				;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun3e

	call	usts1
	jc	mosf3ex 	; (invalid handle if not found)
	
	assume	es:tfb

	mov	ax,0ffffh	; delete handle from tfb handle list
	call	setphdl 	; don't bother checking for error
	call	closefile	; all the hard stuff
mosf3ex:
	mov	dx,6		; per SAH, return code
	mov	cx,INVHDL
	call	repo0

lendp	mosfun3e

	subttl	mosfun3f - read from a file or device
	page
;-----------------------------------------------------------------------;
;									;
; MOS function 3FH - read from a file or device 			;
;									;
; entry:								;
;   TBX = handle for file or device to read				;
;   TDS:TDX -> buffer to read into					;
;   TCX = byte length to read						;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle specified				;
;	ACCDENY - file opened for write only				;
;	& critical errors						;
;   CARRY bit of TFLAG clear if no error				;
;     TAX = number of bytes read (0 implies EOF)			;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun3f

	call	rwdevs		; read/write device setup
	pushf			; SAH make sure you save the flags
	xor	cx,cx		; SAH	set # of bytes read if error
	popf			; SAH
	jc	mosf3fx 	; (invalid handle)
	
	assume	es:tfb

	mov	cx,di
	call	readguts
mosf3fx:
	call	stnbyt		; set number of bytes read into TAX

	assume	ds:nothing,es:nothing,ss:tcb

	mov	cx,ACCDENY
	call	repo1		; report

lendp	mosfun3f

	subttl	mosfun40 - write to a file or device
	page
;-----------------------------------------------------------------------;
;									;
; MOS function 40H - write from a file or device			;
;									;
; entry:								;
;   TBX = handle for file or device to write				;
;   TDS:TDX -> buffer to write from					;
;   TCX = byte length to write (0 to truncate at current position)	;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle specified				;
;	ACCDENY - file opened for read only				;
;	& critical errors						;
;   CARRY bit of TFLAG clear if no error				;
;     TAX = number of bytes written (TAX <> TCX implies disk full)	;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun40

	call	rwdevs
	jc	mosf40x 	; (invalid handle)
	
	assume	es:tfb

	mov	cx,di
	call	writeguts
;-----------------------------------------------------------------------;
; return number of bytes read in TAX					;
;-----------------------------------------------------------------------;
mosf40x:
	call	stnbyt		; set number of bytes written

	assume	ds:nothing,es:nothing,ss:tcb

	mov	cx,ACCDENY
	call	repo1		; report results to caller

lendp	mosfun40

	subttl	mosfun41 - delete a file from a specified directory (UNLINK)
	page
;-----------------------------------------------------------------------;
;									;
; MOS function 41H - delete a file from a specified directory (UNLINK)	;
;									;
; entry:								;
;   TDS:TDX -> ASCIIZ string with drive, path and file to delete	;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	PATHNF	- invalid path specified				;
;		  path not found					;
;		  invalid file name specified				;
;	FILENF	- file not found					;
;	ACCDENY - file is RO						;
;		  can't establish exclusive access                      ;
;	& critical errors						;
;   CARRY bit of TFLAG clear if no error				;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun41

lstring fnm,11			; dir entry formatted file name
lstring	secbuf,<size sectorblk>	; buffer for sector number

	call	usts0

;-----------------------------------------------------------------------;
; validate drive, path and name 					;
;-----------------------------------------------------------------------;
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1		; skip labels
	call	pathfind

	assume	ds:bdb,es:nothing

	jc	mosf41x
	cmp	al,'?'
	mov	ax,FILENF
	je	mosf41x 	; no wild-cards allowed
	xor	ax,ax		; no error if device (just don't do anything)
	or	bx,bx
	jz	mosf41x 	; name refers to a device
;-----------------------------------------------------------------------;
; found a dir entry with that name, check its attribute 		;
;-----------------------------------------------------------------------;
	mov	ax,ACCDENY
	cmp	cl,3		; must have read/write access to parent
	jb	mosf41x 	;   to delete dir entry
	cmp	dx,-1
	jz	mosf41x 	; can't unlink root dir

	assume	es:dbb

	test	[dbbbuf+si+DATR],RO or LBL or DIR
	jnz	mosf41x 	; must not be read-only or label or directory

	call	ckexcl		; check for exclusion from except/only
	jnc	noex2
	mov	ax,ACCDENY
	jmp	short mosf41x

noex2:
	mov	al,[dbbbuf+si+DCLASS0]
	call	classlvl	; must have read/write access to dir entry
	cmp	al,3		;   to delete it
	mov	ax,ACCDENY
	jb	mosf41x
;-----------------------------------------------------------------------;
; must be able to establish exclusive access to file			;
;-----------------------------------------------------------------------;
	call	exclude
	jc	mosf41x
;-----------------------------------------------------------------------;
; go ahead and delete it						;
;-----------------------------------------------------------------------;
mosf41a:
	call	delete
	jc	mosf41x
	call	flushdir
	jc	mosf41x
	xor	ax,ax

	assume	ds:nothing,es:nothing,ss:tcb
mosf41x:
	mov	cx,PATHNF
	call	repo1		; report

lundef	fnm
lundef	secbuf

lendp	mosfun41

	subttl	mosfun42 - move file read/write pointer (LSEEK)
	page
;-----------------------------------------------------------------------;
;									;
; MOS function 42H - move file read/write pointer (LSEEK)		;
;									;
; entry:								;
;   TBX = file handle							;
;   TCX:TDX = length to move pointer					;
;   TAL = method (0 from beginning of file, 1 from current position	;
;	  2 from end of file)						;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVFN  - invalid method specified				;
;	INVHDL - invalid handle specified				;
;   CARRY bit of TFLAG clear if no error				;
;     TDX:TAX = new file position					;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun42

lword	tfbseg
lbyte	method
ldword	distance

	mov	si,bp
	mov	bp,[bp]
	mov	cl,[TAL]
	mov	bx,[TBX]	; handle of file to seek
	mov	ax,[TDX]
	mov	dx,[TCX]
	mov	bp,si
	call	noswt		; no task switches allowed
	mov	[method],cl
	mov	word ptr [distance],ax
	mov	word ptr [distance+2],dx
	call	findtfb 	; locate TFB corresponding to file handle
	mov	ax,INVHDL
	jc	mosf42x 	; (invalid handle)
	
	assume	es:tfb

	mov	[tfbseg],es
;-----------------------------------------------------------------------;
; offset from beginning of file if method = 0				;
;-----------------------------------------------------------------------;
	xor	dx,dx
	mov	cx,dx
	mov	al,[method]
	or	al,al
	jz	mosf42a
;-----------------------------------------------------------------------;
; offset from current position if method = 1				;
;-----------------------------------------------------------------------;
	mov	dx,word ptr [tfbpos]
	mov	cx,word ptr [tfbpos+2]
	dec	al
	jz	mosf42a
;-----------------------------------------------------------------------;
; offset from end of file if method = 2 				;
;-----------------------------------------------------------------------;
	mov	es,[tfbgfb]

	assume	es:gfb

	mov	dx,word ptr [gfbsize]
	mov	cx,word ptr [gfbsize+2]
	dec	al
	mov	ax,INVFN
	jnz	mosf42x 	; error if method > 2
mosf42a:
;-----------------------------------------------------------------------;
; add distance to offset and record as new file position		;
;-----------------------------------------------------------------------;
	add	dx,word ptr [distance]
	adc	cx,word ptr [distance+2]
	mov	es,[tfbseg]

	assume	es:tfb

	mov	word ptr [tfbpos],dx	; new current position
	mov	word ptr [tfbpos+2],cx
	mov	bx,bp
	mov	bp,[bp]
	mov	[TAX],dx	; and return it
	mov	[TDX],cx
	mov	bp,bx
	xor	ax,ax

	assume	ds:nothing,es:nothing,ss:tcb
mosf42x:
	mov	cx,INVHDL
	call	repo1		; report code

lundef	tfbseg
lundef	method
lundef	distance

lendp	mosfun42

	subttl	mosfun43 - change file mode (CHMOD)
	page

;-----------------------------------------------------------------------;
;									;
; MOS function 43H - change file mode (CHMOD)				;
;									;
; entry:								;
;   TDS:TDX -> ASCIIZ string with drive, path and file to change mode	;
;   TCX = attribute to change to					;
;   TAL = 0 return attribute						;
;	= 1 set attribute						;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	PATHNF	- invalid path specified				;
;		  path not found					;
;		  invalid file name specified				;
;	FILENF	- file not found or name specifies a device		;
;	ACCDENY - attribute of found file is DIR or LBL or invalid	;
;	INVFN	- invalid function specified				;
;	& critical errors						;
;   CARRY bit of TFLAG clear if no error				;
;     TCX = current attribute						;
;									;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb

lproc	mosfun43

lbyte	function		; 0 = get attribute, 1 = set attribute
lbyte	fattrib			; current attribute of file
lword	attrib			; new attribute for file
lstring fnm,11			; dir entry formatted file name
lstring	secbuf,<size sectorblk>	; buffer for sector number

	mov	bx,bp
	mov	bp,[bp]
	mov	cx,[TCX]
	mov	es,[TDS]
	mov	di,[TDX]
	mov	al,[TAL]
	mov	bp,bx
	call	noswt		; no task switches allowed
;-----------------------------------------------------------------------;
; validate drive, path and name 					;
;-----------------------------------------------------------------------;
	mov	[function],al
	mov	[attrib],cx
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1		; skip labels
	call	pathfind

	assume	ds:bdb,es:nothing

	jc	jmosf43x
	cmp	al,'?'
	mov	ax,FILENF
	je	jmosf43x 	; no wild-cards allowed
	or	bx,bx
	jz	jmosf43x 	; name refers to a device
;-----------------------------------------------------------------------;
; found a dir entry with that name, check its attribute 		;
;-----------------------------------------------------------------------;
	mov	al,10h		; report a directory if root
	cmp	dx,-1
	je	mosf43c
	call	rddir
	jc	jmosf43x

	assume	es:dbb

	mov	al,[dbbbuf+si+DATR]
	mov	[fattrib],al	; save file's real attribute
mosf43c:
	cmp	[function],0
	je	mosf43b
	mov	ax,INVFN
	cmp	[function],1
	jne	jmosf43x
;-----------------------------------------------------------------------;
; setting attribute							;
;-----------------------------------------------------------------------;
	mov	ax,ACCDENY
	cmp	dx,-1
	je	jmosf43x 	; can't set attributes on root dir

	assume	es:dbb

	cmp	cl,3		; must have read/write access to parent
	jb	jmosf43x 	;   to change attributes of dir entry

	call	ckexcl		; check exclusion from except/only
	jnc	noex3
	mov	ax,ACCDENY
jmosf43x:
	jmp	short mosf43x

noex3:
	mov	al,[dbbbuf+si+DCLASS0]
	call	classlvl	; must have read/write access to dir/entry
	cmp	al,3		;   to change its attributes
	mov	ax,ACCDENY
	jb	mosf43x
	test	[attrib],NOT ( ARCH OR SYS OR HID OR RO )
	jnz	mosf43x 	; invalid or DIR or LBL attributes

;	Make new file attribute.

	mov	al,byte ptr [attrib]
	mov	ah,[fattrib]	; current file attribute
	and	ah,DIR or LBL	; toss all old bits but DIR & LBL bit
	or	al,ah		; put old DIR & LBL bits into new attribute
	mov	byte ptr [attrib],al
	mov	di,es 
	call	findgfb 	; set attribute in gfb

	assume	es:gfb

	mov	ax,[attrib]
	jc	mosf43a 	; no gfb found
	mov	[gfbattr],al
mosf43a:			; and in directory entry
	mov	es,di

	assume	es:dbb

	mov	[dbbbuf+si+DATR],al
	call	wrsector
	jc	mosf43x
	call	flushdir
	jc	mosf43x
	xor	ax,ax
	jmp	short mosf43x
;-----------------------------------------------------------------------;
; getting attribute (already in al)					;
;-----------------------------------------------------------------------;
mosf43b:
	xor	ah,ah
	mov	bx,bp
	mov	bp,[bp]
	mov	[TCX],ax
	mov	bp,bx
	xor	ax,ax

	assume	ds:nothing,es:nothing,ss:tcb
mosf43x:
	mov	cx,PATHNF
	call	repo1		; report code

lundef	function		; 0 = get attribute, 1 = set attribute
lundef	fattrib			; old file attribute
lundef	attrib			; new attribute for file
lundef	fnm			; dir entry formatted file name
lundef	secbuf

lendp	mosfun43

	subttl	 mosfun45 - duplicate a file handle (DUP)
	page

;-----------------------------------------------------------------------;
;									;
; MOS function 45H - duplicate a file handle (DUP)			;
;									;
; entry:								;
;   TBX = file handle to duplicate					;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle specified				;
;	MANYFIL - too many files open					;
;	SYSHDL - attempt to dup a non-psp handle			;
;	& critical errors						;
;   CARRY bit of TFLAG clear if no error				;
;     TAX = new handle							;
;									;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb

lproc	mosfun45

lword	tfbseg

	call	usts1
	jc	mosf45x 	; (invalid handle)
	
	assume	es:tfb

	call	getphdl 	; returns bx = free handle
	jc	mosf45x 	; no free psp handles available or SYS handle
	mov	ax,[tfbhdl]
	call	setphdl 	; set bx handle in psp to tfbhdl
	jc	mosf45x 	; trying to DUP a system handle
	inc	[tfbopen]	; else another instance now exists
	mov	ax,bp
	mov	bp,[bp]
	mov	[TAX],bx	; return new handle to application
	mov	bp,ax
	xor	ax,ax

	assume	ds:nothing,es:nothing,ss:tcb
mosf45x:
	mov	cx,INVHDL
	call	repo1

lundef	tfbseg

lendp	mosfun45

	subttl	mosfun46 - force a duplicate of a handle (FORCDUP)
	page

;-----------------------------------------------------------------------;
;									;
; MOS function 46H - duplicate a file handle (DUP)			;
;									;
; entry:								;
;   TBX = file handle to duplicate					;
;   TCX = file handle to force (if active file, it is closed first)	;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid handle specified				;
;	MANYFIL - too many files open					;
;	SYSHDL - attempt to dup from/to a non-psp handle		;
;	& critical errors						;
;   CARRY bit of TFLAG clear if no error				;
;									;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb

lproc	mosfun46

lword	tfbseg

	mov	ax,bp
	mov	bp,[bp]
	mov	cx,[TBX]	; handle of file to duplicate
	mov	bx,[TCX]	; handle to refer to file also
	mov	bp,ax
	call	noswt		; no task switches allowed
	mov	ax,INVHDL
	call	findtfb 	; find tfb for second handle
	jc	mosf46a 	; c if not in use
	mov	ax,0ffffh	; delete handle from tfb's handle list
	call	setphdl 	; don't bother checking for error
	call	closefile	; second handle in use, close the file first
	jc	mosf46x
mosf46a:
	push	bx
	mov	bx,cx
	call	findtfb 	; locate TFB corresponding to first file handle
	pop	bx
	mov	ax,INVHDL
	jc	mosf46x 	; (invalid handle)
	
	assume	es:tfb

	mov	ax,[tfbhdl]
	call	setphdl 	; set second file handle to it
	jc	mosf46x 	; tried to FDUP from or to a system handle
	inc	[tfbopen]	; else another instance now exists
	xor	ax,ax

	assume	ds:nothing,es:nothing,ss:tcb
mosf46x:
	mov	cx,INVHDL
	call	repo1

lundef	tfbseg

lendp	mosfun46

	subttl	mosfun47 - get current directory
	page

;-----------------------------------------------------------------------;
;									;
; MOS function 47H - Get the current directory				;
;									;
; entry:								;
;   TDS:TSI -> 64-byte buffer to return ASCIIZ current dir string	;
;   TDL = drive number of current dir (0=default drive) 		;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	DRIVENF - invalid drive specified				;
;   CARRY bit of TFLAG clear if no error				;
;									;
;	1/8/87 MJS  if no error, must return TAX = 0100 		;
;	This is required by the Lotus 123 v2.0 INSTALL.EXE program.	;
;									;
;	SAH	08/15/88						;
;	Check to see if current path is actually valid.  If it is a     ;
;	floppy, some could change it on us.  We should have already 	;
;	catch this problem.						;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb

lproc	mosfun47
lstring	fnm,11
lstring	secbuf,<size sectorblk>
lstring temp,64				; temporary space for path
lbyte	drv47				; temporary space for drive

	mov	bx,bp
	mov	bp,[bp]
	mov	dl,[TDL]	; drive for current dir (0=default)
	mov	es,[TDS]	; pointer to buffer for current dir string
	mov	di,[TSI]
	mov	bp,bx
	call	noswt
        mov     al,[tcbcdriv]
        or      dl,dl
        jz      mosf47a0
        mov     al,dl
        dec     al
mosf47a0:
	mov	[drv47],al
        call    finddrv
        jc      mosf47x
        mov     ds,cx
        assume  ds:cdb
mosf47b:
	lea	si,cdbpath
;
;	Check to see if path return is valid and make sure it exist on disk
;	This is done just in case somebody changes drives on US
;
	push	si
	push	di
	push	es
	push	ds
	push	ss
	pop	es
	mov	al,[drv47]		; get drive
	add	al,'A'
	lea	di,temp			; use temporary space on stack
	stosb
	mov	al,':'
	stosb
	mov	al,'\'
	stosb
	mov	cx,60/2			; 61 = 60+1
	rep	movsw			; transfer entry
	movsb
	lea	di,temp
	mov	[fnm],' '		; only path validation
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind
	pop	ds
	pop	es
	pop	di
	pop	si
	jnc	mosf47c			; path is ok so use it
	mov	byte ptr [si],0		; place it root
mosf47c:
	lodsb
	stosb
	or	al,al
	jnz	mosf47c
	xor	ax,ax		; no error

	assume	ds:nothing,es:nothing,ss:tcb
mosf47x:
	mov	cx,DRIVENF
	mov	dx,100H		; MJS return ax = 0100 if no error
	call	repo0

lundef	drv47
lundef  temp
lundef	fnm
lundef	secbuf
lendp	mosfun47

	subttl	mosfun4e - find first matching file (FIND FIRST)
	page

;-----------------------------------------------------------------------;
;									;
; MOS function 4EH - Find first matching file (FIND FIRST)		;
;									;
; entry:								;
;   TDS:TDX -> ASCIIZ string with drive/path/file to be found		;
;   TCX = attribute to use during search				;
;     if TCX = 8 find only volume label 				;
;     else								;
;	match all files without hidden, system or read-only attributes	;
;	additionaly match files with those attributes if the respective ;
;	bit is set in TCX						;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	PATHNF	- invalid path specified				;
;		  path not found					;
;		  invalid file name					;
;	NOMORE	- no matching files					;
;	& critical error codes						;
;   CARRY bit of TFLAG clear if no error				;
;     DTA filled in as follows: 					;
;     offset 00H 21 bytes reserved					;
;	     00H byte	  file drive (A=1)				;
;	     01H 11 bytes search name					;
;	     0CH byte	  search attribute				;
;	     0DH word	  offset in sector of dir entry of found file	;
;			    (note: dos is entry number within cluster)	;
;	     0FH word	  sector number of dir entry of found file	;
;			    (note: dos is cluster number)		;
;	     11H 4 bytes  0's (not used)                                ;
;	     15H byte	  found file's attribute                        ;
;	     16H word	  found file's time                             ;
;	     18H word	  found file's date                             ;
;	     1AH dword	  found file's length                           ;
;	     1EH 13 bytes foundfile's name and extension followed by 0  ;
;									;
; 3/10/87 MJS If successful operation then TAL should return 0.  This	;
;	  is needed by PFS First Choice					;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb

lproc	mosfun4e

lword	attrib			; attribute of matching files
lstring fnm,11			; dir entry formatted file name
lstring	secbuf,<size sectorblk>	; buffer for sector number

	mov	bx,bp
	mov	bp,[bp]
	mov	cx,[TCX]
	mov	es,[TDS]
	mov	di,[TDX]
	mov	bp,bx
	call	noswt		; no task switches allowed
	mov	[attrib],cx
;-----------------------------------------------------------------------;
; validate drive, path and name 					;
;-----------------------------------------------------------------------;
mosf4ea:
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	test	cx,LBL
	jz	mosf4ea0
	xor	al,al
mosf4ea0:
	call	pathfind

	assume	ds:bdb,es:nothing

	jc	jmosf4ex
	mov	ax,NOMORE
	cmp	dx,-1
	je	jmosf4ex 	; name refers to root dir
;-----------------------------------------------------------------------;
; see if it's a search for a label (and look in root if so)             ;
;-----------------------------------------------------------------------;
	mov	al,byte ptr [attrib]
	or	bx,bx		;jrby
	jz	mosf4ee		;jrby
	and	al,HID or DIR or LBL
	cmp	al,LBL
	jne	mosf4eb
	cmp	[bdbalias],0	; is this an alias device?
	je	mosf4ea1	; if not an alias drive, it can have a label
				; change jne to je	JSM 05/02/87
	mov	ax,FILENF	; make search fail if alias drive
jmosf4ex:
	jmp	mosf4ex
mosf4ea1:
	push	ss
	pop	es
	lea	di,[fnm]
	mov	dx,[bdbdir]
	mov	[secbuf].seclow,dx
	xor	dx,dx
	mov	[secbuf].sechigh,dx
	lea	bx,[secbuf]
	xor	si,si
	call	nextnm
	jc	jmosf4ex 	; none found
mosf4eb:
;-----------------------------------------------------------------------;
; found a dir entry with that name, check its attribute 		;
;-----------------------------------------------------------------------;

	assume	es:dbb

	mov	al,byte ptr [attrib]
	mov	cl,al
	and	cl,(HID or DIR or LBL)
	mov	ch,[dbbbuf+si+DATR]
	and	ch,(HID or DIR or LBL)
	cmp	cl,LBL
	jne	mosf4ec 	; not specifically looking for a label
	test	ch,LBL
	jnz	mosf4ee 	; nz if found the label
	jmp	mosf4ed 	; else not found if specifically looking
mosf4ec:
	and	cl,ch		; else found bits must be set in search
	cmp	cl,ch		;   attribute
	jne	mosf4ed 	; e if found the one we're looking for

	test	al,OVERRIDE
	jnz	mosf4ee 	; class override for dir search

	call	ckexcl		; check for exclusion
	jc	mosf4ed

	push	ax		; else make sure this tcb can look at dir
	mov	al,[dbbbuf+si+DCLASS0]
	call	classlvl	;   entries of this class
	or	al,al
	pop	ax
	jnz	mosf4ee 	; class access ok if not deny access
mosf4ed:
;-----------------------------------------------------------------------;
; if wrong attribute, get the next					;
;-----------------------------------------------------------------------;
	push	ss
	pop	es
	assume	es:tcb

	lea	di,fnm
	add	si,32
	lea	bx,[secbuf]
	call	nextnm
	jnc	mosf4eb
	jmp	short mosf4ex
;-----------------------------------------------------------------------;
; fill out dma area with found entry					;
; es = segment of dbb for dir sector					;
; ss:bx -> sector number						;
; si = sector offset							;
; al = attribute for search						;
;-----------------------------------------------------------------------;
mosf4ee:
	mov	ah,al
	mov	al,[bdbid]
	inc	al
	push	es
	pop	ds
	assume	ds:dbb

	les	di,dword ptr [tcbdta]
	assume	es:nothing

	stosb
	push	ds
	push	si
	push	ss
	pop	ds
	lea	si,fnm
	mov	cx,11
	rep movsb
	pop	si
	pop	ds
	mov	al,ah
	stosb
	mov	al,4eh		; Setup to clear function reserved bytes - SJC
	lea	bx,[secbuf]	;jrby
	call	dta4e		; fill out rest of dta with found file stuff
	xor	ax,ax

	call	sttax0		; return zero in task AX

	assume	ds:nothing,es:nothing,ss:tcb
mosf4ex:
	cmp	ax,FILENF
	jne	mosf4ey
	mov	ax,NOMORE
mosf4ey:
	mov	cx,NOMORE
	call	repo1

lundef	attrib
lundef	fnm
lundef	secbuf

lendp	mosfun4e

	subttl	dta4e - fill out dta with data from dir entry
	page

;-----------------------------------------------------------------------;
; fill out dta with data from found directory entry			;
;-----------------------------------------------------------------------;
	assume	ds:dbb,es:nothing,ss:tcb
dta4e:
	push	ax		; save reserved clear status - SJC
	mov	ax,si		; offset into sector of entry
	stosw
	mov	ax,ss:[bx].seclow	; sector address of entry
	stosw
	mov	ax,ss:[bx].sechigh	; high word of sector address
	stosw
	pop	ax		; retrieve reserved status - SJC
	cmp	al,4eh
	je	d4eclr
	inc	di		; bypass clear reserved bytes if not fun4e
	inc	di
	jmp	short d4enoc
d4eclr:
	xor	ax,ax
	stosw			; reserved
d4enoc:				; SJC
	mov	ax,ss:[bx].seclow	;jrby see if it's a device
	or	ax,ss:[bx].sechigh	;jrby
	jnz	dta4ej1			;jrby a device if 0
	mov	cx,9			;jrby clear out rsrvd area
	rep stosb			;jrby (note al already 0)
	add	si,10			;jrby   if so ds:si -> driver header
	mov	cx,8/2			;jrby   copy driver name
	rep movsw			;jrby
	mov	cx,8			;jrby
	mov	al,' '			;jrby
	jmp	dta4e3			;jrby   strip trailing spaces
dta4ej1:				;jrby else not a device
	mov	al,[dbbbuf+si+DATR]
	stosb
	mov	ax,word ptr [dbbbuf+si+DTIME]
	stosw
	mov	ax,word ptr [dbbbuf+si+DDATE]
	stosw
	mov	ax,word ptr [dbbbuf+si+DSIZE]
	stosw
	mov	ax,word ptr [dbbbuf+si+DSIZE+2]
	stosw
	lea	si,[dbbbuf+si]
	mov	cx,4
	rep movsw
	mov	cx,8
	mov	al,' '
dta4e1:
	dec	di
	cmp	al,es:[di]
	loope	dta4e1
	je	dta4e2
	inc	di
dta4e2:
	mov	al,'.'
	stosb
	movsw
	movsb
	mov	cx,3
	mov	al,' '
dta4e3:
	dec	di
	cmp	al,es:[di]
	loope	dta4e3
	jne	dta4e4
	dec	di
	cmp	byte ptr es:[di],'.'
	je	dta4e5
dta4e4:
	inc	di
dta4e5:
	xor	ax,ax
	stosb
	ret

	subttl	mosfun4f - find next matching file (FIND NEXT)
	page

;-----------------------------------------------------------------------;
;									;
; MOS function 4FH - Find next matching file (FIND NEXT)		;
;									;
; entry 								;
;   DTA filled in from function 4EH or 4FH				;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	NOMORE	- no matching files					;
;	& critical error codes						;
;   CARRY bit of TFLAG clear if no error				;
;     DTA filled in as in function 4EH					;
;									;
; 1/10/87 DAM If successful operation then TAL should return 0.  This	;
;	  is needed by the public domain program SD.COM v2.4		;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb

lproc	mosfun4f

lbyte	attrib
lstring	secbuf,<size sectorblk>

	call	noswt
	les	di,dword ptr [tcbdta]
	mov	al,es:[di]
	dec	al
	call	finddrv
	mov	ax,NOMORE
	jc	jmosf4fx

	assume	ds:bdb

	les	di,dword ptr [tcbdta]
	mov	al,es:[di+12]
	mov	[attrib],al
	mov	ax,NOMORE
	mov	si,es:[di+13]
	test	si,32-1
	jnz	jmosf4fx 	; offset must be a dir entry boundary
	mov	dx,es:[di+17]
	mov	[secbuf].sechigh,dx
	mov	bx,es:[di+15]
	mov	[secbuf].seclow,bx
	cmp	si,[bdbssiz]
	jae	jmosf4fx 	; and less than sector size
	or	dx,dx
	jnz	mosf410		; dir sector & data sector have high word 0
	cmp	bx,[bdbdir]
	jb	jmosf4fx 	; sector must be >= first root sector
	cmp	bx,[bdbclus]
	jb	mosf4fa 	; ok if in root directory ( < data clusters)
mosf410:
				; else make sure its a valid data cluster
	xor	cx,cx
	sub	bx,[bdbclus]
	sbb	dx,cx
	mov	cl,[bdbcshl]
	jcxz	mosf430
mosf420:
	shr	dx,1
	rcr	bx,1
	loop	mosf420
mosf430:
	add	bx,2
	cmp	bx,[bdbcnum]
	jae	jmosf4fx 	; and < max cluster
mosf4fa:
	les	di,dword ptr [tcbdta]
	inc	di		; -> name to find
	add	si,32
	lea	bx,[secbuf]	; point bx at sector buffer
	call	nextnm
	jnc	$+4
jmosf4fx:
	jmp	short mosf4fx
;-----------------------------------------------------------------------;
; found a dir entry with that name, check its attribute 		;
;-----------------------------------------------------------------------;

	assume	es:dbb

	mov	al,byte ptr [attrib]
	and	al,(HID or DIR or LBL)
	mov	ah,[dbbbuf+si+DATR]
	and	ah,(HID or DIR or LBL)
	cmp	al,LBL
	jne	mosf4fb 	; ne if not looking specifically for label
	test	ah,LBL
	jnz	mosf4fc 	; nz if found label
	jmp	mosf4fa 	; else next if looking specifically
mosf4fb:
	and	al,ah		; else found bits must be set in search
	cmp	al,ah		;   attribute
	jne	mosf4fa
	test	byte ptr [attrib],OVERRIDE
	jnz	mosf4fc 	; ok if level access overrride for dir search

	call	ckexcl		; check except/only list
	jc	mosf4fa

	mov	al,[dbbbuf+si+DCLASS0]
	call	classlvl
	or	al,al
	jz	mosf4fa 	; ignore dir entry at deny access level
mosf4fc:
;-----------------------------------------------------------------------;
; fill out dma area with found entry					;
; es = segment of dbb for dir sector					;
; ss:bx -> sector number						;
; si = sector offset							;
;-----------------------------------------------------------------------;
	push	es
	pop	ds
	assume	ds:dbb

	les	di,dword ptr [tcbdta]
	assume	es:nothing

	lea	di,[di+13]
	lea	bx,[secbuf]
	mov	al,4fh		; set no clear reserved bytes - SJC
	call	dta4e
	xor	ax,ax
	call	sttax0

	assume	ds:nothing,es:nothing,ss:tcb
mosf4fx:
	cmp	ax,FILENF
	jne	mosf4fy
	mov	ax,NOMORE
mosf4fy:
	mov	cx,NOMORE
	call	repo1

lundef	attrib
lundef	secbuf

lendp	mosfun4f

	subttl	mosfun56 - rename a file
	page

;-----------------------------------------------------------------------;
;									;
; MOS function 56H - rename a file					;
;									;
; entry:								;
;   TDS:TDX -> ASCIIZ drive, path, name to be renamed			;
;   TES:TDI -> ASCIIZ drive, path and new name				;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	PATHNF	- invalid path specified				;
;		  path not found					;
;		  invalid file name specified				;
;	FILENF	- file not found					;
;	ACCDENY - second file exists					;
;	DIFFDEV - not the same drive					;
;   CARRY bit of TFLAG clear if no error				;
;									;
;-----------------------------------------------------------------------;

;-----------------------------------------------------------------------;
;  search the list of cdb's to find match with drive in al		;
;  enter with  es -> 1st cdb in list, al = drive to search for		;
;  return with es->cdb for drive in al					;
;-----------------------------------------------------------------------;

find_cdb:		
	assume es:cdb	
	cmp	[cdbdrive],al
	je	fcdb1
	mov	es,[cdbnext]
	jmp	find_cdb
fcdb1:
	ret

;-----------------------------------------------------------------------;
;  before renaming a subdirectory, must make sure the target directory	;
;  is not the current dir, or parent dir of any task.			;
;  must also prohibit renaming a directory as a child of itself!	;
;  enter with ds->bdb, es->dbb, ss->tcb, bx = TDS, dx = TDX, 		;
;  si value from pathfind.  cx:di -> 2nd parm				;
;  return with ax = 0 if ok, != 0 if conflict				;
;-----------------------------------------------------------------------;

lproc chk_pths

lstring refbuf,64		; reference buffer for subdir comparisons
lbyte 	refdrv			; "    "    drive   "    "      "      "
lword	refptr			; pointer for 1st/2nd parm comparisons
lword	refcpth			; segment of cdb

	assume	ds:bdb, es:dbb, ss:tcb
	push	cx
	push	di
	mov	al,[bdbid]		; get drive of 1st parm
	mov	[refdrv],al
	mov	es,[tcbcdbpf]
	assume	es:cdb
	call	find_cdb
	mov	[refcpth],es	; find the current path for the drive
	mov	ds,bx
	assume	ds:nothing
	mov	si,dx
	cmp	byte ptr [si+1],':'
	jne	f56mjs3
	add	si,2
	add	dx,2
f56mjs3:
	push	ss
	pop	es
	assume	es:nothing
	lea	di,[refbuf]
	inc	si
	cmp	byte ptr [si-1],'\'
	je	f56mjs5
	mov	ds,[refcpth]
	push	ss
	pop	es
	assume	ds:cdb,es:nothing	; and stick it in refbuf first
	lea	si,[cdbpath]
	lea	di,[refbuf]
	cld
	cmp	byte ptr [si],0
	je	f56mjs4a
f56mjs4:
	lodsb
	stosb
	or	al,al
	jnz	f56mjs4
	mov	byte ptr es:[di-1],'\'
f56mjs4a:
	mov	ds,bx
	assume	ds:nothing
	mov	si,dx
f56mjs5:
	mov	[refptr],di
f56mjs5a:
	lodsb			; copy 1st parm into rebuf (after current
	callmos1 caps		; path, if there)
	stosb
	or	al,al
	jnz	f56mjs5a
	dec	di
	mov	cx,di
	lea	di,[refbuf]
	sub	cx,di		; calc length of string (not counting the 0)

;-----------------------------------------------------------------------;
; must make sure the 1st parm is not contained within the 2nd parm.	;
; when this situation is found, some idiot is trying to rename a dir	;
; as a child of itself.  if we don't crash the party, bye bye files!	;
;-----------------------------------------------------------------------;

	pop	si		; push'ed as entry di
	pop	ds		; push'ed as entry cx   ds:si->2nd parm
	push	cx
	cmp	byte ptr [si],'\'
	jne	f56mjs5b		; if 2nd parm starts with a \ then
	inc	si			; compare with full 1st parm
	lea	di,[refbuf]
	jmp	f56mjs5c
f56mjs5b:				; else compare with 1st parm after
	lea	ax,[refbuf]		; the point where the current dir
	mov	bx,[refptr]		; was added
	mov	di,bx
	sub	bx,ax
	sub	cx,bx		; calc new comparison length
	push	ss
	pop	es
f56mjs5c:
	call	capscmps
	pop	cx                 ; when find a substring match, if next  
	jne	f56mjs5d           ; char in 2nd parm is a "\" then 
	cmp	byte ptr [si],'\'  ; have a conflict.  Otherwise, have 
	je	f56mjs8		   ; a case of the type "ren abc abcd" and
f56mjs5d:                          ; must not indicate an error            
	mgetscb2 es                
	assume	es:grp		; pass on to here when no substring match
	mov	ds,[scbtcbpf]
	assume	ds:tcb
f56mjs7:
	mov	es,[tcbcdbpf]
	assume	es:cdb
	mov	al,[refdrv]		; for each task, find the cdbpath 
	call	find_cdb		; for the drive
	lea	di,[cdbpath]
	push	ds
	push	ss
	pop	ds
	lea	si,[refbuf]
	push	cx			; see if the 1st parm's path matches
	repe	cmpsb			; or is a substring of the current
	pop	cx			; path (for the drive) of any task
	pop	ds
	je	f56mjs8			; if find a match, error
	xor	ax,ax
	cmp	[tcbtcbpn],0
	je	f56mjs9			; all done, no matches
	mov	ds,[tcbtcbpn]
	jmp	f56mjs7
f56mjs8:
	mov	ax,ACCDENY	; return error if any task's current
f56mjs9:			; dir for the drive is the same as, or parent
				; of the 1st parm
	assume	ds:nothing,es:nothing

lundef	refbuf
lundef	refdrv
lundef	refptr
lundef	refcpth

lendp	chk_pths

;-----------------------------------------------------------------------;
; main line code for function 56					;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb

lproc	mosfun56

ldword	asciiz2 		; -> second name
lstring fnm1,11 		; dir entry formatted first name
lstring fnm2,32 		; dir entry formatted second name
				;   (later has entire new dir entry)
lbyte	clvl			; cumulative level to destination parent dir
lword	dofs1			; offset in dir sector of first name
ldword	dsct1			; dir sector of first name
lword	clust1			; cluster of parent directory for first name
lword	clust2			; cluster of parent directory for second name
lstring	secbuf,<size sectorblk>	; buffer for sector number

	mov	cx,bp
	mov	bp,[bp]
	mov	di,[TDX]
	mov	es,[TDS]
	mov	ax,[TDI]
	mov	dx,[TES]
	mov	bp,cx
	call	noswt
	mov	word ptr [asciiz2],ax
	mov	word ptr [asciiz2+2],dx
;-----------------------------------------------------------------------;
; validate drive, path, name of first file				;
;-----------------------------------------------------------------------;
	lea	si,fnm1
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind

	assume	ds:bdb,es:nothing

	jc	jmosf56x
	cmp	al,'?'
	mov	ax,FILENF
	je	jmosf56x 	; no wild-cards allowed
	or	bx,bx
	mov	ax,ACCDENY
	jz	jmosf56x 	; name refers to a device
	cmp	cl,3		; must have read/write access to source parent
	jb	jmosf56x
	cmp	dx,-1
	je	jmosf56x 	; can't rename root directory

	assume	es:dbb

	test	[dbbbuf+si+DATR],LBL
	jnz	jmosf56x 	; can't rename label
	mov	[clust1],dx
	push	ax
	mov	ax,[secbuf].seclow
	mov	word ptr [dsct1],ax
	mov	ax,[secbuf].sechigh
	mov	word ptr [dsct1+2],ax
	pop	ax
	mov	[dofs1],si

	call	ckexcl		; check exclusion
	jnc	noex5
	mov	ax,ACCDENY
jmosf56x:
	jmp	mosf56x

noex5:
	mov	al,[dbbbuf+si+DCLASS0]
	call	classlvl	; must have read/write access to source
	cmp	al,3		;   dir entry
	mov	ax,ACCDENY
	jb	jmosf56x
;-----------------------------------------------------------------------;
; must be able to establish exclusive access to first file		;
;-----------------------------------------------------------------------;
	call	exclude
	jc	jmosf56x
mosf56a:
	push	es
	les	di,[asciiz2]	; Must check for globals in 2nd parm this 
	call	chk_glbl        ; way.  Pathfind will return al == '?' when
	pop	es              ; a matching file is found for a global 
	or	ax,ax           ; filespec, but when no match is found, 
	jz	f56mjs2         ; then AX == FILENF
	jmp	mosf56x         
f56mjs2:			; the bdb for first name is now the 
	push	ds		; first thing on top of stack
	test	[dbbbuf+si+DATR],DIR
	jz	f56pthok
	mov	ax,bp
	mov	bp,[bp]
	mov	di,[TDI]	; cx:di -> second parm
	mov	cx,[TES]
	mov	dx,[TDX]
	mov	bx,[TDS]	; when the first path is a directory, must
	mov	bp,ax		; make sure there is no conflict with the 
	call	chk_pths	; current path of any other tasks before
	or	ax,ax		; allowing the rename
	jz	f56pthok
	pop	ds
	jmp	mosf56x
f56pthok:
	les	di,[asciiz2]
;-----------------------------------------------------------------------;
; validate drive, path, name of second file				;
;-----------------------------------------------------------------------;
	lea	si,fnm2
	lea	bx,[secbuf]
	mov	al,1			; skip labels
	call	pathfind

	assume	ds:bdb,es:nothing

	mov	[clvl],cl
	pop	cx
	jc	mosf56ab
	mov	ax,ACCDENY	; file already exists
xmosf56x:
	jmp	mosf56x
mosf56ab:
	cmp	ax,FILENF
	jne	xmosf56x 	; ne if some error other than file not found
	mov	ax,ds
	cmp	ax,cx
	mov	ax,DIFFDEV
	jne	xmosf56x 	; drives must be the same for first and second
	mov	ax,ACCDENY
	cmp	[clvl],3	; must have read/write access to dest parent
	jb	xmosf56x
	mov	[clust2],dx	; first cluster of parent of new dir
;-----------------------------------------------------------------------;
; first file exists, second file doesn't - go ahead with rename         ;
; save first dir entry							;
;-----------------------------------------------------------------------;
	mov	si,word ptr [dsct1]
	mov	[secbuf].seclow,si
	mov	si,word ptr [dsct1+2]
	mov	[secbuf].sechigh,si
	mov	si,[dofs1]
	lea	bx,[secbuf]
	call	rddir
	jc	x2f56x

	assume	es:dbb

	push	es
	push	ds
	push	es
	pop	ds
	push	ss
	pop	es
	assume	ds:dbb,es:tcb

	lea	si,[dbbbuf+si+11]	; past file name
	lea	di,fnm2+11	; past file name
	mov	cx,32-11
	rep movsb
	pop	ds
	pop	es

	assume	ds:bdb,es:dbb

	mov	si,[dofs1]
	mov	dx,[clust1]
	cmp	dx,[clust2]
	je	mosf56c 	; new name and old name in same dir
;-----------------------------------------------------------------------;
; if new and old names in different paths, delete old name		;
;-----------------------------------------------------------------------;
	mov	[dbbbuf+si],0e5h
	call	wrsector
	jnc	$+5
x2f56x:
	jmp	mosf56x
;-----------------------------------------------------------------------;
; find empty place for new name 					;
;-----------------------------------------------------------------------;
	mov	dx,[clust2]
	call	emptydir
	jc	x2f56x
;-----------------------------------------------------------------------;
; copy saved dir entry to new location (including new name)		;
;-----------------------------------------------------------------------;

	assume	es:dbb
mosf56c:
	push	si
	push	ds
	push	ss
	pop	ds
	assume	ds:tcb

	lea	di,[dbbbuf+si]
	lea	si,fnm2
	mov	cx,32/2
	rep movsw
	pop	ds
	pop	si

	assume	ds:bdb

	call	wrsector
	jc	mosf56x

;-----------------------------------------------------------------------;
; when a subdirectory is renamed into a different position, must 	;
; update the first cluster pointer in the .. directory entry. 		;
;-----------------------------------------------------------------------;

	test	[dbbbuf+si+DATR],DIR
	jnz	$+5	; if not working with a directory, skip all this
	jmp	f56mjs12
	mov	bx,word ptr [dbbbuf+si+DCLUST]
	cmp	bx,[bdbcnum]	; validate subdir cluster number
	jnc	mosf56x
	sub	bx,2
	jc	mosf56x
	xor	cx,cx
	mov	[secbuf].sechigh,cx
	mov	cl,[bdbcshl]
	jcxz	f56mjs11
f56mjs10:
	shl	bx,1
	rcl	[secbuf].sechigh,1
	loop	f56mjs10
f56mjs11:
	add	bx,[bdbclus]	; bx = sector for subdir
	adc	[secbuf].sechigh,cx	; cx is 0
	mov	[secbuf].seclow,bx
	lea	bx,[secbuf]
	call	rddir
	jc	mosf56x

	assume	es:dbb

;-----------------------------------------------------------------------;
; second entry must be a dir named .. owning the parent dir cluster	;
;-----------------------------------------------------------------------;
	lea	di,dbbbuf+32
	mov	ax,'..'
	scasw
	jne	mosf56x
	mov	al,' '
	mov	cx,11-2
	repe scasb
	jne	mosf56x
	test	byte ptr [dbbbuf+32+DATR],DIR
	jz	mosf56x
	mov	ax,[clust2]		; update the starting cluster number
	mov	word ptr [dbbbuf+32+DCLUST],ax
	call	wrsector
	jc	mosf56x
f56mjs12:
	call	flushdir
	jc	mosf56x
	xor	ax,ax

	assume	ds:nothing,es:nothing,ss:tcb
mosf56x:
	mov	cx,FILENF
	call	repo1

lundef	asciiz2 		; -> second name
lundef	fnm1	 		; dir entry formatted first name
lundef	fnm2	 		; dir entry formatted second name
				;   (later has entire new dir entry)
lundef	clvl
lundef	dofs1			; offset in dir sector of first name
lundef	dsct1			; dir sector of first name
lundef	clust1			; cluster of parent directory for first name
lundef	clust2			; cluster of parent directory for second name
lundef	secbuf

lendp	mosfun56

	subttl	mosfun57 - get/set a file's date and time
	page

;-----------------------------------------------------------------------;
;									;
; MOS function 57H - get/set a file's date and time                     ;
;									;
; entry:								;
;   TBX = file handle							;
;   TCX = time to set							;
;   TDX = date to set							;
;   TAL = 0 get date/time						;
;	= 1 set date/time						;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVHDL - invalid file handle specified				;
;	INVFN - invalid function specified				;
;	& critical error codes						;
;   CARRY bit of TFLAG clear if no error				;
;     TCX = file time							;
;     TDX = file date							;
;									;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb

lproc	mosfun57

lbyte	function

	mov	cx,bp
	mov	bp,[bp]
	mov	al,[TAL]
	mov	bx,[TBX]	; handle of file for date and time
	mov	bp,cx
	call	noswt		; no task switches allowed
	mov	[function],al
	call	findtfb 	; locate TFB corresponding to file handle
	mov	ax,INVHDL
	jc	mosf57x 	; (invalid handle)
	
	assume	es:tfb

	cmp	[function],0
	jne	mosf57a
;-----------------------------------------------------------------------;
; getting file date and time						;
;-----------------------------------------------------------------------;
	mov	es,[tfbgfb]

	assume	es:gfb

	mov	cx,[gfbtime]
	mov	dx,[gfbdate]
	mov	bx,bp
	mov	bp,[bp]
	mov	[TCX],cx
	mov	[TDX],dx
	mov	bp,bx
	xor	ax,ax
	jmp	short mosf57x
;-----------------------------------------------------------------------;
; setting file date and time						;
;-----------------------------------------------------------------------;
mosf57a:
	assume	es:tfb

	cmp	[function],01h
	mov	ax,INVFN
	jnz	mosf57x
	mov	ax,ACCDENY	; must have read/write access to file to
	cmp	[tfblvl],3	;   set the file date
	jb	mosf57x
	mov	es,[tfbgfb]

	assume	es:gfb

	mov	bx,bp
	mov	bp,[bp]
	mov	ax,[TCX]
	mov	[gfbtime],ax
	mov	ax,[TDX]
	mov	[gfbdate],ax
	mov	bp,bx
	mov	[gfbwrtn],'Y'	; signal file has been modified
	xor	ax,ax

	assume	ds:nothing,es:nothing,ss:tcb
mosf57x:
	mov	cx,INVHDL
	call	repo1

lundef	function

lendp	mosfun57

	subttl	mosfun5a - create unique file
	page

;-----------------------------------------------------------------------;
;									;
; MOS function 5AH - Create a unique file				;
;   file is opened in compatibility sharing mode with read/write access ;
;									;
; entry:								;
;   TDS:TDX -> ASCIIZ string with drive and path of directory in which	;
;	       to create the file					;
;   TCX = attribute for created file					;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	PATHNF	- invalid path specified				;
;		  path not found					;
;	ACCDENY - the root directory is full (can't add to root)        ;
;		  the disk is full (can't extend subdir)                ;
;		  label attribute					;
;		  see attribute discussion in function 3CH		;
;	MANYFIL - too many files open					;
;	& critical error codes						;
;   CARRY bit of TFLAG clear if no error				;
;     TAX = file handle 						;
;     TDS:DX -> ASCIIZ string filled in with file name			;
;									;
; access permission established as in function 3CH			;
;   (except LBL attribute always results in ACCDENY)			;
;									;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb

lproc	mosfun5a

lbyte	clvl			; cumulative access to parent dir
lbyte	attrib			; attribute for created file
lword	pcluster		; first cluster of parent dir (0 if root)
lstring fnm,11			; dir entry formatted file name
ldword	buffer			; pointer to user path
lstring	secbuf,<size sectorblk>	; buffer for sector number

	mov	bx,bp
	mov	bp,[bp]
	mov	es,[TDS]
	mov	di,[TDX]
	mov	cx,[TCX]
	mov	bp,bx
	call	noswt		; no task switches allowed
;-----------------------------------------------------------------------;
; validate drive and path and attribute 				;
;-----------------------------------------------------------------------;
	mov	[attrib],cl
	and	cl,not ( ARCH OR SYS OR HID OR RO )	; LBL and DIR invalid
	mov	ax,ACCDENY
	jnz	jmosf5ax 	; fail if any invalid attribute bit set
;-----------------------------------------------------------------------;
; validate drive and path (and get first cluster of dir)		;
;-----------------------------------------------------------------------;
	push	di
	mov	cx,67		; 64 byte path + C: + trailing \
	xor	al,al
	repne scasb
	pop	cx
	mov	ax,PATHNF
	jne	jmosf5ax
	mov	al,byte ptr es:[di-2]
	call	slash
	je	mosf5aa
	inc	di		; supply trailing \ if omitted
	mov	ax,'\'		; (note ah = 0)
	mov	es:[di-2],ax
mosf5aa:
	dec	di
	mov	word ptr [buffer],di
	mov	word ptr [buffer+2],es
	push	cx
	call	genname
	pop	di
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	call	pathfind
	mov	[pcluster],dx	; first cluster of parent dir
	mov	[clvl],cl
	jc	mosf5ac
	cmp	al,'?'
	mov	ax,PATHNF
	je	jmosf5ax 	; no wild-cards allowed
	mov	ax,ACCDENY
	or	bx,bx
	jz	jmosf5ax
	cmp	[clvl],3	; must have read/write access to parent dir
	jb	jmosf5ax
	cmp	dx,-1
	jne	mosf5ab
jmosf5ax:
	jmp	mosf5ax
;-----------------------------------------------------------------------;
; generate a name and see if it's unique                                ;
;-----------------------------------------------------------------------;
mosf5ab:
	les	di,[buffer]
	call	genname 	; generate a new name into buffer
	push	ds
	push	ss
	pop	es
	lea	di,fnm
	lds	si,[buffer]
	mov	cx,8/2
	rep movsw
	mov	ax,'  '
	stosw
	stosb
	pop	ds
	mov	dx,[pcluster]
	lea	di,fnm
	call	findnm		; see if file exists
	jnc	mosf5ab 	; (repeat if so)

	assume	es:nothing
mosf5ac:
	cmp	ax,FILENF
	jne	mosf5ax 	; make sure it's not some other error
;-----------------------------------------------------------------------;
; no dir entry with that name, create a new one with supplied attrib	;
;-----------------------------------------------------------------------;
	push	ss
	pop	es
	lea	di,fnm
	mov	dx,[pcluster]
	mov	al,byte ptr [attrib]
	call	create		; make a directory entry (fail if duplicate)
	jc	mosf5ax 	; (probably root full)
;-----------------------------------------------------------------------;
; flush out buffered sectors						;
;-----------------------------------------------------------------------;
	call	flushdir	; flush any changed fat and dir sectors
	jc	mosf5ax
	mov	al,02h		; compatibility sharing, read/write,
	test	[attrib],01h	; is this for Read-Only access
	jz	mosf5acx
	dec	al		; set for read-only
mosf5acx:
	mov	ah,[clvl]
	call	openfile	;   inherited by child processes
	jc	mosf5ax

	assume	es:tfb

	call	getphdl 	; get free handle from psp table
	mov	ax,[tfbhdl]
	xchg	ax,bx
	jc	mosf5ad 	; c if no room in psp table (no error)
	xchg	ax,bx
	call	setphdl 	; set system handle into psp table
	jnc	mosf5ad
	mov	bx,[tfbhdl]	; c if tfbhdl is a system handle (no error)
mosf5ad:
	mov	[tfbfnh],bx	;jrba
	mov	ds,[tfbgfb]

	assume	ds:gfb

	mov	[gfbwrtn],'Y'	; file has been written
	or	[tfbioctl],40h	; written by this process
	mov	ax,bp
	mov	bp,[bp]
	mov	[TAX],bx	; set up to return handle
	mov	bp,ax
	xor	ax,ax

	assume	ds:nothing,es:nothing,ss:tcb
mosf5ax:
	mov	cx,PATHNF
	call	repo1

lundef	clvl
lundef	attrib			; attribute for created file
lundef	pcluster		; first cluster of parent dir (0 if root)
lundef	fnm,11			; dir entry formatted file name
lundef	buffer			; pointer to user path
lundef	secbuf

lendp	mosfun5a

;-----------------------------------------------------------------------;
; generate a file name from the current time				;
; copy it to es:di terminated with 0					;
;-----------------------------------------------------------------------;
genname:
	callmos1 gettime	;** Call in MOS segment
	mov	ax,cx		; hour, minutes
	call	hexword
	mov	ax,dx		; seconds, hundredths
	call	hexword
	xor	al,al
	stosb
	ret

;-----------------------------------------------------------------------;
; translate ax to ASCII hex at ES:DI					;
;-----------------------------------------------------------------------;
hexword:
	xchg	al,ah
	call	hexbyte
	xchg	al,ah
hexbyte:
	push	ax
	shr	al,1
	shr	al,1
	shr	al,1
	shr	al,1
	call	hexdig
	pop	ax
hexdig:
	and	al,0fh
	add	al,'0'
	cmp	al,'0'+10
	jb	hexdg1
	add	al,7
hexdg1: stosb
	ret

	subttl	mosfun5b - create new file
	page

;-----------------------------------------------------------------------;
;									;
; MOS function 5BH - Create a new file					;
;   file is opened in compatibility sharing mode with read/write access ;
;									;
; entry 								;
;   TDS:TDX -> ASCIIZ string with drive, path and file to create	;
;   TCX = attribute for created file					;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	PATHNF	- invalid path specified				;
;		  path not found					;
;		  invalid file name specified				;
;	ACCDENY - the root directory is full				;
;		  the disk is full					;
;		  see attribute discussion in function 3CH		;
;	MANYFIL - too many files open					;
;	FILEXST - file exists (not new) 				;
;	& critical error codes						;
;   CARRY bit of TFLAG clear if no error				;
;     TAX = file handle (if not label)					;
;									;
; access permission established as in function 3CH			;
;									;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb

lproc	mosfun5b

lbyte	clvl			; cumulative access level to parent
lword	pseg			; if device, seg for driver
lbyte	attrib			; attribute for created file
lstring fnm,11			; dir entry formatted file name
lstring	secbuf,<size sectorblk>	; buffer for sector number

	mov	bx,bp
	mov	bp,[bp]
	mov	es,[TDS]
	mov	di,[TDX]
	mov	cx,[TCX]
	mov	bp,bx
	call	noswt		; no task switches allowed
;-----------------------------------------------------------------------;
; validate drive and path and attribute 				;
;-----------------------------------------------------------------------;
	mov	[attrib],cl
	and	cl,not (ARCH OR SYS OR HID OR RO OR LBL)	; DIR invalid
	mov	ax,ACCDENY
	jnz	jmosf5bx 	; fail if any invalid attribute bit set
	mov	[fnm],' '	; to detect null path (drive only)
	lea	si,fnm
	lea	bx,secbuf
	mov	al,1			; skip labels
	test	cl,LBL
	jz	mosf5bf
	xor	al,al		; unless specified in entry cx
mosf5bf:
	call	pathfind

	assume	ds:bdb,es:nothing

	mov	[clvl],cl
	jc	mosf5ba
	cmp	al,'?'
	mov	ax,ACCDENY
	je	jmosf5bx 	; no wild-cards allowed
	mov	[pseg],es	; (if a device, then segment for driver)
	or	bx,bx
	ljz	mosf5bd 	; name refers to a device is ok
	cmp	dx,-1
	jz	jmosf5bx




; if supposed to create a volume label, make sure pathfind doesn't
; find a file by the same name.

	mov	di,bp
	mov	bp,[bp]
	mov	cx,[TCX]
	mov	bp,di
	test	cl,LBL
	jz	mosf5bh
mosf5bg:
	assume	es:dbb
	test	[dbbbuf+si+DATR],LBL
	jnz	mosf5bh			; fail if not a label
	mov	di,ss
	mov	es,di
	lea	di,fnm			; when find a file
	add	si,32			; must keep checking
	lea	bx,secbuf
	call	nextnm
	jc	mosf5ba			; exit loop when can't find more
	jmp	short mosf5bg
mosf5bh:




	mov	ax,FILEXST
jmosf5bx:
	jmp	mosf5bx 	; name refers to a file which exists already
;-----------------------------------------------------------------------;
; no dir entry with that name, create a new one with supplied attrib	;
;-----------------------------------------------------------------------;
mosf5ba:
	cmp	ax,FILENF
	jne	jmosf5bx
	mov	ax,PATHNF
	cmp	[fnm],' '
	je	jmosf5bx 	; e if null path
	push	ss
	pop	es
	assume	es:tcb

	lea	di,fnm
	mov	al,'?'
	mov	cx,11
	repne scasb
	mov	ax,ACCDENY
	je	jmosf5bx 	; wild-cards aren't allowed
	sub	di,11
	test	[attrib],LBL
	jz	mosf5bb
;-----------------------------------------------------------------------;
; create a label dir entry in root if none already there		;
;-----------------------------------------------------------------------;
	call	makelbl
	jnc	mosf5bc
	jmp	short mosf5bx
;-----------------------------------------------------------------------;
; else not a label, create a new file in path dir			;
;-----------------------------------------------------------------------;
mosf5bb:
	mov	ax,ACCDENY
	test	[attrib],DIR
	jnz	mosf5bx 	; fail if dir entry attribute bit set (ACCDENY)
	cmp	[clvl],3	; must have read/write access to parent dir
	jb	mosf5bx
	mov	al,[attrib]
	call	create		; make a directory entry (fail if duplicate)
	jc	mosf5bx 	; (probably root full)
;-----------------------------------------------------------------------;
; flush out buffered sectors						;
;-----------------------------------------------------------------------;
mosf5bc:
	call	flushdir	; flush any changed fat and dir sectors
	jc	mosf5bx
mosf5bd:
	mov	al,02h		; compatibility sharing, read/write,
	test	[attrib],01h	; test for read-only
	jz	mosf5bdx
	dec	al
mosf5bdx:
	mov	es,[pseg]	;   and inherited by child processes
	mov	ah,[clvl]
	call	openfile
	jc	mosf5bx

	assume	es:tfb

	call	getphdl 	; get free handle from psp table
	mov	ax,[tfbhdl]
	xchg	ax,bx
	jc	mosf5be 	; c if no room in psp table (no error)
	xchg	ax,bx
	call	setphdl 	; set system handle into psp table
	jnc	mosf5be
	mov	bx,[tfbhdl]	; c if tfbhdl is a system handle (no error)
mosf5be:
	mov	[tfbfnh],bx	;jrba
	mov	ds,[tfbgfb]

	assume	ds:gfb

	mov	[gfbwrtn],'Y'	; file has been written
	or	[tfbioctl],40h	; written in this process
	mov	ax,bp
	mov	bp,[bp]
	mov	[TAX],bx	; set up to return handle
	mov	bp,ax
	xor	ax,ax

	assume	ds:nothing,es:nothing,ss:tcb
mosf5bx:
	mov	cx,PATHNF
	call	repo1

lundef	clvl
lundef	pseg			; if device, seg for driver
lundef	attrib			; attribute for created file
lundef	fnm			; dir entry formatted file name
lundef	secbuf

lendp	mosfun5b

	subttl	mosfun5c - lock/unlock file access
	page

;-----------------------------------------------------------------------;
;									;
; MOS function 5CH - lock/unlock file access				;
;									;
; entry 								;
;   TAL = function (0=lock, 1=unlock)					;
;   TBX = file handle							;
;   TCX:TDX = offset of lock region					;
;   TSI:TDI = length of lock region					;
;									;
; returns:								;
;   CARRY bit of TFLAG set if error					;
;     TAX = error code							;
;	INVFN  - invalid function specified				;
;	INVHDL - invalid handle specifed				;
;	LOCK   - lock violation 					;
;	& critical error codes						;
;   CARRY bit of TFLAG clear if no error				;
;									;
;-----------------------------------------------------------------------;

	assume	ds:grp,es:nothing,ss:tcb

lproc	mosfun5c

lbyte	function
ldword	locklen
ldword	lockofs

	mov	bx,bp
	mov	bp,[bp]
	mov	al,[TAL]
	mov	dx,[TDX]
	mov	cx,[TCX]
	mov	di,[TDI]
	mov	si,[TSI]
	push	[TBX]		; handle of file containing region
	mov	bp,bx
	pop	bx
	call	noswt		; no task switches allowed
	mov	[function],al
	mov	word ptr [lockofs],dx
	mov	word ptr [lockofs+2],cx
	mov	word ptr [locklen],di
	mov	word ptr [locklen+2],si
	call	findtfb 	; locate TFB corresponding to file handle
	mov	ax,INVHDL
	jc	jmosf5cx 	; (invalid handle)
	push	es
	pop	ds
	assume	ds:tfb,es:tfb

	cmp	[function],0
	jne	mosf5ca
;-----------------------------------------------------------------------;
; lock sub-function							;
;-----------------------------------------------------------------------;
	mov	dx,word ptr [lockofs]
	mov	cx,word ptr [lockofs+2]
	mov	di,word ptr [locklen]
	mov	si,word ptr [locklen+2]
	mov	ds,[tfbgfb]
	call	chklock
	mov	ax,NLOCK
	jc	jmosf5cx 	; error if locked by others
	jz	jmosf5cx 	; error if locked by this process
;-----------------------------------------------------------------------;
; allocate and fill out a new rlb					;
;-----------------------------------------------------------------------;
	push	es
	push	ds
	pop	es
	xor	ax,ax
	mov	al,'R'
	callmos1 mosliman	;** Call in MOS segment
	pop	ds

	assume	ds:tfb,es:rlb

	or	al,al
	mov	ax,SHAREOV	; no room for more locks
	jnz	jmosf5cx
	mov	[rlbtfb],ds	; tfb of owner process and psp and handle
	mov	ax,[tfbfnh]	;jrba
	mov	[rlbhdl],ax	;jrba
	mov	dx,word ptr [lockofs]
	mov	cx,word ptr [lockofs+2]
	mov	di,word ptr [locklen]
	mov	si,word ptr [locklen+2]
	mov	ax,[tcbpsp]		; current psp -- JSM 04/27/87
	mov	word ptr [rlbpsp],ax	; psp for owner of locked region
	mov	word ptr [rlbbgn],dx	; start of locked region
	mov	word ptr [rlbbgn+2],cx
	add	di,dx
	adc	si,cx
	mov	word ptr [rlbend],di	; end+1 of locked region
	mov	word ptr [rlbend+2],si
	xor	ax,ax
jmosf5cx:
	jmp	short mosf5cx

	assume	ds:tfb,es:tfb
mosf5ca:
	cmp	[function],1
	mov	ax,INVFN
	jne	mosf5cx
;-----------------------------------------------------------------------;
; unlock sub-function							;
;-----------------------------------------------------------------------;
	mov	dx,word ptr [lockofs]
	mov	cx,word ptr [lockofs+2]
	mov	di,word ptr [locklen]
	mov	si,word ptr [locklen+2]
	push	[tfbfnh]	;jrba
	mov	ds,[tfbgfb]
	push	es
	call	findrlb
	pop	bx
	pop	cx		;jrba

	assume	ds:gfb,es:rlb

	mov	ax,NLOCK
	jc	mosf5cx 	; error if not found
	jnz	mosf5cx 	; error if not exact match
	cmp	bx,[rlbtfb]	;jrba
	jne	mosf5cx 	; error if current process not the owner
	mov	ax,[tcbpsp]	;jrba
	cmp	ax,[rlbpsp]	;jrba
	jne	mosf5cx		;jrba
	cmp	cx,[rlbhdl]	;jrba
	jne	mosf5cx		;jrba
;-----------------------------------------------------------------------;
; deallocate rlb							;
;-----------------------------------------------------------------------;
	mov	ah,01h
	mov	al,'R'
	callmos1 mosliman	;** Call in MOS segment
	xor	ah,ah
	or	al,al
	jz	mosf5cx
	mov	ax,INTERN	; internal error if can't de-allocate RLB

	assume	ds:nothing,es:nothing,ss:tcb
mosf5cx:
	mov	cx,INVHDL
	call	repo1

lundef	function
lundef	locklen
lundef	lockofs
lendp	mosfun5c

	subttl	mosfun39 - common sdubroutines from optimization
	page

;
; Written 10/26/87  SJC
;

;
; Use task registers, do not modify bp reg. - Called from start of most procs
;
usts0	proc	near
	mov	bx,bp
	mov	bp,[bp]
	mov	es,[TDS]
	mov	di,[TDX]
	mov	bp,bx
	call	noswt		; no task switches allowed
	ret
usts0	endp

usts1	proc	near
	mov	ax,bp
	mov	bp,[bp]
	mov	bx,[TBX]	; handle of file to duplicate
	mov	bp,ax
	call	noswt		; no task switches allowed
	call	findtfb 	; locate TFB corresponding to file handle
	mov	ax,INVHDL
	ret
usts1	endp

;
; Report error in tasks space - version 0
; Success code in dx reg.
; Return code in cx (for moserror)
;
repo0	proc	near
	call	okswt		; safe to allow a task switch
	mov	bx,bp
	mov	bp,[bp] 	; address task registers for TAX = error code
	mov	[TAX],dx	; dx holds success code
	call	moserror
	mov	bp,bx
	ret
repo0	endp

;
; Report code/error, version 1
; Error code in cx.
;
repo1	proc	near
	call	okswt
	mov	bx,bp
	mov	bp,[bp] 	; address task registers to report TAX error
	call	moserror
	mov	bp,bx
	ret
repo1	endp

;
; Return handle in task AX reg.
;
rethan	proc	near
	mov	ax,bp
	mov	bp,[bp]
	mov	[TAX],bx	; return handle
	mov	bp,ax
	xor	ax,ax		; no error
	ret
rethan	endp

;
; Check for exclusion
;
ckexcl	proc	near
	push	ds
	push	si
	push	es
	pop	ds
	lea	si,[dbbbuf+si]
	call	checkexon	; check for an exclusion from +except/+only
	pop	si
	pop	ds
	ret
ckexcl	endp

;
; Read/write device setup routine
;
rwdevs	proc	near
	mov	si,bp
	mov	bp,[bp]
	mov	bx,[TBX]	; handle of file to read
	mov	dx,[TDX]
	mov	ax,[TDS]
	mov	di,[TCX]
	mov	bp,si
	call	noswt		; no task switches allowed

	push	ax		; normalized segment
	call	findtfb 	; locate TFB corresponding to file handle
	pop	ds
	mov	ax,INVHDL
	ret
rwdevs	endp

;
; Set number of bytes read/written in task AX reg.
;
stnbyt	proc	near
	mov	di,bp
	mov	bp,[bp]
	mov	[TAX],cx	; number of bytes read returned in AX
	mov	bp,di
	ret
stnbyt	endp

;
; Set TAX reg with processor ax reg
;
sttax0	proc	near
	mov	bx,bp
	mov	bp,[bp]
	mov	[TAX],ax
	mov	bp,bx
	xor	ax,ax
	ret
sttax0	endp

ddt	ends
	end
