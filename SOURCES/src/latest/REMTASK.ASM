	include page.inc
	title MOXREMTA.ASM - Remove running MOS task
;
;******************************************************************************
;*                                                                            *
;*                        MOS Development Specification                       *
;*                                                                            *
;* Command type: External		Assigned to: Jeffrey S. Mayo	      *
;* Command name: REMTASK.COM		Date assigned: 12/11/86		      *
;*					Date completed:			      *
;* Command format: REMTASK taskid					      *
;* Purpose: Remove running task from system				      *
;* Refer to: ADDTASK.ASM, MOSITASK.ASM, MOSRTASK.ASM, MOXUTIL.ASM	      *
;* Last Update:	3/21/90			By: SAH				      *
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
;-------------------------------------------------------------------------;
;	07/12/87	SAH 	Converted fun 80+ to int 38h 00+	  ;
;				Remove sub-version checking		  ;
;-------------------------------------------------------------------------;
;       10/27/87        SAH	Removed memory if memory management is not;
;				on system.				  ;
;-------------------------------------------------------------------------;
;   06/28/89	SAH	Made sure that you can not remove task which is   ;
;			is console and being viewed.			  ;
;-------------------------------------------------------------------------;
;   11/30/89	BWR	Marked messages for foreign language translation. ;
;-------------------------------------------------------------------------;
;   03/21/90    SAH	Added Remtask all command			  ;
;-------------------------------------------------------------------------;

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


TCB SEGMENT AT 0		; use this data segment to reference the
				; labels in the TCB
include mostcb.pub		; So we have the labels with periscope
include mostcb.inc

TCB ENDS

SCBseg segment at 0		; data segment for labels in scb
	assume	cs:SCBseg
include	mosscbdf.inc
	assume	cs:grp
SCBseg ends

	subttl	macros & equates
	page

	include moxutl.inc
	include	remtask.pub

SELFID	equ	-1		; ID for currently running process
GETSCB	equ	002h		; Get pointer to system SCB
GETTCB	equ	004h		; MOS call to get TCB from a task ID
REMTSK	equ	005h		; MOS call to remove a running task

	subttl	data
	page

gdata	segment
;--------------------------- VARIABLES -------------------------;
version	label	byte
	include	version.inc

	even

SCBPtr	dd	?		; pointer to SCB

WorkBuf	db	128 dup(?)	; general purpose buffer
	db	?		; used for alignment

PrsFCB	db	?		; FCB for the Parse procedure
FCBname db	36 dup(?)	

MemSize	dw	0		; convert memsize string into here
TaskID	dw	0		; task ID value
TaskTCB	dw	0		; TCB for task to delete
TClass	db	' '		; class charactor (blank or A-Z)

ErrRTask db	'Error Removing Task     ',0	;@@XLAT
RTask	db	' task(s) removed.     ',0  ;@@XLAT
StopMsg	db	"Removed task number   ",0 ;@@XLAT
SelfMsg	db	"Removing current task, number   ",0 ;@@XLAT
PercMsg	db	"00 percent of System Memory Pool now in use.                   ",0 ;@@XLAT

extMM	db	'00000k of  ',0 ;@@XLAT
extMM2	db	'00000k memory now in use.          ',13,10,0 ;@@XLAT


SavePCT dw	0
NextTCB dw	0
tasks	dw	0

gdata	ends

moss	segment
	org	100h

;	public entry points

	public	ErrorW			; handler for error in console I/O
	public	begin
	public	EndOfProg


;--------------------------- START OF CODE -------------------------;

begin:
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

	mov	si,80h			; check  length of the parameter line
	mov	bl,[si]
	or	bl,bl
	Ljz	Error1
	inc	si
	xor	bh,bh
	mov	BYTE PTR [si+bx],0	; make sure there is a 0 end marker

	call	PassSpace		; must not skip the task ID spec
	cmp	al,','
	Lje	Error1

;
;	check for REMTASK ALL	
;	
	push	ax
	push	si
	and	al,0dfh
	cmp	al,'A' 			; check for (A)ll
	jne	NotPAll
	mov	ax,word ptr ds:[si+1]
	and	ax,0dfdfh
	cmp	ax,'LL'			; check for a(LL)
NotPAll:
	pop	si
	pop	ax
	je	IsTask0
	jmp	NotAll
IsTask0:
;
;	is this command run from task 0
;
	mov	bx,-1
	MOS38	GETTCB
	assume  es:tcb
	cmp	[tcbid],0 		; is current task task 0
	je	DoRemAll
	jmp	ErrorT0			; no do error message
DoRemAll:
;
;	check to make sure nobody is watching task 0
;
	xor	bx,bx
	MOS38	GETTCB
	mov	cx,[tcbscrdd]	; first task looking at TASK 0
	or	cx,cx
	Lje	ErrorTW		; if no task looking at TASK 0, error
	mov	ax,es		; is it itself?
	cmp	ax,cx
	Ljne	ErrorTW		; if another task looking at a background
	mov	cx,[tcbnxtdd]	; other tasks looking at TASK 0
	or	cx,cx		; no other tasks may look if delete succeeds
	Ljne	ErrorTW		; if other task watching
;
;	setup for task delete loop
;
	push	cs
	pop	es
	call	DispEOL
	MOS38	GETSCB
	mov	word ptr [SCBPtr],bx
	mov	word ptr [SCBPtr+2],es
	assume  es:SCBseg
	mov	ax,word ptr es:[bx]
	mov	[Tasks],0
RemLoop:
	mov	es,ax
	assume  es:tcb
	mov	ax,[tcbtcbpn]
	mov	[NextTCB],ax
	mov	ax,[tcbid]
	or	ax,ax		; is it task 0
	jz	SkipRem
	push	es
	push	ax
	MOS38	REMTSK
	push	cs
	pop	ds
	mov	[SavePCT],ax
	pop	ax
	jnc	NoRemErr
	push	cs
	pop	es
	push	ax
	lea	dx,ErrRTask
	call	DispStr
	pop	ax	
	lea	bx,[WorkBuf]	; display task ID number
	mov	cx,4		; 4 chars long
	call	WriteWord
	call	DispEOL
NoRemErr:
	inc	[Tasks]
	pop	es
SkipRem:
	mov	ax,[NextTCB]	; get next tcb
	or	ax,ax
	jnz	RemLoop
	mov	ax,cs
	mov	es,ax
	mov	ax,[tasks]
	lea	bx,[WorkBuf]	; display task ID number
	mov	cx,4		; 4 chars long
	call	WriteWord
	lea	dx,RTask
	call	DispStr
	call	DispEOL
	cmp	[tasks],0	; no tasks removed
	je	NoTasks
	mov	ax,[SavePCT]	; return Percent SMP (Last One)
	mov	[workbuf+40],0
	mov	word ptr [PercMsg],ax	; store % of heap used
	jmp	RemTout			
NoTasks:
	jmp	RemTDone     	
	

NotAll:	
	


;	Check for lone * as parameter.  If found, delete current task.

	cmp	al,'*'			; remove current task?
	jne	remt10			; if task to remove is not current task

	inc	si			; skip over the *
	call	PassSpace
	or	al,al			; is this the end?
	Ljnz	Error3			; if not end, syntax error, too many
					; parameters

	mov	ax,SELFID		; Report task #

;	Delete current task.
;	Convert task ID to TCB address

	mov	bx,ax
	MOS38	GETTCB			; get real TCB address
	Ljc	Error5			; if ID not in use
	mov	[TaskTCB],es

	assume	es:tcb

	mov	ax,[tcbid]		; get task's real ID
	mov	[TaskID],ax		; record task ID
	
	or	ax,ax			; is this task zero?
	Ljz	ErrorW			; if zero, we can't remove it
	
remt1:
;	Make sure no other tasks have their terminals pointed
;	at this task

	call	chkwatch
	cmp	word ptr [tcbcondd],0	 ; sorry can't do this
	Ljnz	Errorw
	lea	dx,[SelfMsg]	; display 'Killing current task'
	call	DispStr
	push	es
	push	ds
	pop	es
	mov	ax,[TaskID]
	lea	bx,[WorkBuf]	; display task ID number
	mov	cx,4		; 4 chars long
	call	WriteWord
	call	DispEOL
	pop	es
	jmp	short remt20	; continue processing

remt10:
	lea	di,[PrsFCB]
	call	Parse		; parse out task ID
	cmp	BYTE PTR [FCBname],0
	Lje	Error1		; must have a task ID parameter
	call	PassSpace
	or	al,al		; is this the end?
	Ljnz	Error3		; if not end, too many parameters
	push	si
	lea	si,[FCBname]
	call	Str2NumDW	; convert ASCII ID string to binary integer
	pop	si
	Ljc	Error2		; syntax error, parameter not a number
	or	dx,dx		; if dx <> 0, value too large
	Ljnz	Error4
	cmp	ax,0FFFFh	; if ax == -1, too large
	Lje	Error4
	or	ax,ax
	Ljz	ErrorW		; if id == 0, report error
	mov	[TaskID],ax	; record task ID

;	Convert task ID to TCB address

	mov	bx,ax
	MOS38	GETTCB		; get real TCB address
	Ljc	Error5		; if ID not in use
	mov	[TaskTCB],es
	
;	See if the task wants to remove itself

	push	es
	MOS38	GETSCB
	mov	word ptr [SCBPtr],bx
	mov	word ptr [SCBPtr+2],es
	mov	ax,es:[bx+scbtcbpc]
	pop	es

	assume	es:tcb

	cmp	[TaskTCB],ax
	Lje	remt1		; if task wants to remove itself

;	Make sure no other tasks have their terminals pointed
;	at this task

	call	chkwatch

;	Kill the task denoted by TCB in cell TaskTCB
remt20:

	mov	es,[TaskTCB]	; get TCB in es again
	MOS38	REMTSK		; blow the task away
	Ljc	ErrorW		; if we didn't have access

	push	cs
	pop	ds
	assume	ds:grp

	mov	[workbuf+40],0
	mov	word ptr [PercMsg],ax	; store % of heap used

	call	DispEOL
	lea	dx,[StopMsg]	; display 'Killed task number '
	call	DispStr
	mov	ax,[TaskID]	; Report task #
	lea	bx,[WorkBuf]	; buffer for conversion
	mov	cx,8		; length of buffer
	call	WriteWord
	call	DispEOL

;
;	The following location is enter by Remtask ALL to complete operation	
;

RemTout:

	les	bx,[SCBPtr]	; Get SCB address

	assume	es:SCBseg

	cmp	[bx+scbmmfg],'N'		; SAH memory management?
	je	remtskip			; no...skip the message

	push	ds
	lds	bx,dword ptr [bx+scbmmptr]	; Get pointer to used memory
	assume	ds:nothing
	mov	ax,[bx+14]			; available 4k blocks
	mov	bx,[bx+10]			; Total 4k blocks
	pop	ds

;	Format string for available memory & print.

	push	bx
	lea	bx,extMM+4
	mov	cx,5
	xor	dx,dx
	shl	ax,1
	shl	ax,1		; get K from 4K
	call	Bin2Dec
	lea	bx,extMM
remt30:
	cmp	byte ptr [bx],' '	; skip leading spaces
	jne	remt40		; if no more spaces
	inc	bx
	jmp	remt30		; next one
remt40:
	mov	dx,bx		; string less leading spaces
	call	DispStr
	
;	Format string for total memory & print.

	pop	ax
	lea	bx,extMM2+4
	mov	cx,5
	xor	dx,dx
	shl	ax,1
	shl	ax,1
	call	Bin2Dec
	lea	bx,extMM2
remt50:
	cmp	byte ptr [bx],' '	; skip leading spaces
	jne	remt60		; if no more spaces
	inc	bx
	jmp	remt50		; next one
remt60:
	mov	dx,bx		; string less leading spaces
	call	DispStr


remtskip:
	lea	dx,[PercMsg]	; display the percent of heap used
	call	DispStr

remtdone:
	xor	al,al		; set error level 0
	jmp	Done

;--------------------------- ERROR HANDLERS -------------------------;

Ermsg1	db	2, "Correct form: REMTASK TaskID        ", 13,10	;@@XLAT
	db	   '          or  REMTASK ALL     ',0			;@@XLAT

Error1:
	lea	dx,[Ermsg1]
	jmp	ShowError

Ermsg2	db	2, "Task ID must be number or *, no task removed                ",0 ;@@XLAT

Error2:
	lea	dx,[Ermsg2]
	jmp	ShowError

Ermsg3	db	2, "Can only remove one task at a time, no task removed               ",0 ;@@XLAT

Error3:
	lea	dx,[Ermsg3]
	jmp	ShowError

Ermsg4	db	1, "Task ID too large          ",0 ;@@XLAT

Error4:
	lea	dx,[Ermsg4]
	jmp	ShowError

Ermsg5 db	1, "Task ID not in use                 ",0 ;@@XLAT

Error5:
	lea	dx,[Ermsg5]
	jmp	ShowError

Ermsg6 db	1, "Another task is watching, task can't be removed                       ",0 ;@@XLAT

Error6:
	lea	dx,[Ermsg6]
	jmp	ShowError

Ermsg7	db	13,10,'Improper MOS Version',0 ;@@XLAT

Error7:
	lea	dx,[Ermsg7]
	jmp	ShowError

ErmsgW db	1, "Access denied, no task removed                    ",0 ;@@XLAT

ErrorW:
	lea	dx,[ErmsgW]
	jmp	ShowError


ErrorT0:
	lea	dx,[ErmsgT0]
	jmp	ShowError

ErmsgT0	db	1, 'Remtask All must be run from Task 0      ',0 ;@@XLAT

ErrorTW:
	lea	dx,[ErmsgTW]
	jmp	ShowError

ErmsgTW	db	1, 'Another task is watching Task 0          ',0 ;@@XLAT


ShowError:
	inc	dx		; skip error level
	call	DispErr
	dec	dx
	mov	bx,dx
	mov	al,[bx]		; get error level in al

;	$$$$$$$$ error handler

Done:
	call	DispEOL
	MOS	Quit

;----------------------------- Subroutines -----------------------------;

;-----------------------------------------------------------------------;
; chkwatch								;
;									;
; Make sure no other tasks have their terminals pointed at this task.	;
;									;
;  On Entry:								;
;	es->TCB of task to delete					;
;  On Exit:								;
;	If no error, returns to caller.  If other tasks are watching	;
;	this task, jumps into the error handler and never returns.	;
;  Global data affected:						;
;	none								;
;  Global procedures called:						;
;	none								;
;  Registers changed:
;	ax, cx
;-----------------------------------------------------------------------;
	assume cs:grp,ds:grp,es:tcb

chkwatch proc near
	mov	cx,[tcbscrdd]	; first task looking at this task
	jcxz	chk10		; if no task looking at this one
	mov	ax,es		; is it itself?
	cmp	ax,cx
	Ljne	Error6		; if another task looking at a background
	mov	cx,[tcbnxtdd]	; other tasks looking at this task
	or	cx,cx		; no other tasks may look if delete succeeds
	Ljne	Error6		; if other task watching
chk10:
	ret
chkwatch endp

	subttl	name -- function
	page
;-----------------------------------------------------------------------;
; WriteWord								;
;									;
; Display binary word as decimal ASCII on STDOUT.			;
;									;
;  On Entry:								;
;	ax contains word to display					;
;	bx -> buffer for conversion					;
;	cx contains length of buffer (less one for NULL terminator)	;
;  On Exit:								;
;	word displayed on terminal					;
;									;
;  Global data affected: none						;
;  Global procedures called: none					;
;  ax, bx, cx, dx, si changed						;
;-----------------------------------------------------------------------;
WriteWord proc	near
	xor	dx,dx			; it's only a word
	push	bx			; save buffer pointer
	add	bx,cx			; one past end of buffer
	mov	BYTE PTR [bx],0		; write end marker
	dec	bx			; now point to last pos
	call	Bin2Dec			; convert to decimal
	pop	si			; buffer to display
	call	PassSpace		; skip trailing spaces
	mov	dx,si
	call	DispStr			; write it out
	ret
WriteWord endp

moss	ENDS
	END	begin
