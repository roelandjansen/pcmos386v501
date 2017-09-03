	include page.inc
	title	NETBIOS - NETBIOS emulation for PC-MOS v1.0
	subttl	data structure definitions
	.sall
;-----------------------------------------------------------------------;
;									;
; !!!!!!!! NOTE: when making modifications and fixes to this module,	;
;	consider that LANLink's NETBIOS code roughly parallels this one.;
;									;
;-----------------------------------------------------------------------;
; 1.01									;
; B0 - allow up to 17 adapters for MultiLink Advanced 4.00's 17         ;
;      partitions							;
; B1 - change NBIOS references in messages to MLNETBIO			;
; 07/22/86								;
; PC-MOS version 1.0							;
;	Converted program to device driver format			;
;	Changed calls to get ML task ID, suspend the task, transfer	;
;	data between tasks, and call an arbitrary routine in a task.	;
; JSM	03/03/87							;
; JSM	04/20/87 upped maximum tasks to 25				;
; SAH	07/12/87 Converted function 80+ to INT 38h 00+			;
; SAH	08/25/87 Limited 5f02 support --> no more files on system	;
; jrb	08/27/87 changed allocation so exactly as many tasks as adapters;
;	are allocated, so unlink can be changed to remove a task and	;
;	adapter for remtask						;
; jrb	08/27/87 changeed unlink to remove task and adapter for remtask ;
; jrb	08/27/87 fixed senddg so name is copied to receiver and so	;
;	it doesn't trash cx, si, di                                     ;
; jrb	08/27/87 fixed call so name is copied to listener		;
; jsm	11/20/87 fixed command line parsing so tasks=nn works again	;
; jsm	11/23/87 id [3] fixed infinite loop in findnm routine by	;
;		 1) reloading di before calling localnm in the second	;
;		    loop						;
;		 2) making sure the search loops will work with ladapt	;
;		    being larger than nextadp				;
; jrb	11/25/87 id [4] findm needs to check all the adapters		; 
; SAH	01/28/88 converted INT 38 calls to call MOSINT38 directly to	;
;		 avoid conflicts with apps which take INT 38		; 
; jsw	03/21/88 fixed installed check call to return flag in ah.	;
; sjc	05/06/88 fixed 5f02h fun in int21h emu to return carry flag set!;
; sjc	05/13/88 fixed do10 sub to correctly copy callers name		;
; sjc	09/27/88 fixed retrieval of int 38h vector in init (net)	;
; sjc	11/08/88 made send (fn14,17) wait for time out until timing out ;
; sjc	12/5/88  fixed hangup to delete name if de-registered after hup ;
; sjc	12/7/88  fixed hangup rcvany any to set lsn into ncb (local/far);
; sjc	2/9/89	fix call (fn10) to wait some time before returning err	;
; sjc	2/13/89 fix int2ah retry operation, fix typo in int21h. 	;
; SAH	02/20/89 Converted INT 38 to INT SERVICES. MASM 5.10 fixes	;
; sjc	3/5/89	GETADP incorrectly sensing end of adapter storage (fix).;
; sjc	3/9/89	FINDNM searches for conflict incorrectly, set straight. ;
;		Place MOSSusp call w/in fn10,14,17 (wait for recv cond).;
; sjc	3/13/89 Need to disallow task switching in MOSmove to allow	;
;		 LANLink NETBIOS to function correctly under MOS. This	;
;		 code is NOT assembled in the current vers (commented). ;
;-----------------------------------------------------------------------;
; mjs 03/29/89	when the send command (fn14) was checking the command	;
;		queue for any pending receive's, it wasn't qualifying	;
;		any matches by the session number.  Progress was	;
;		crashing under MOS because when the second task logged	;
;		in, its first send command ended up using the last	;
;		receive command was issued by task 0 for task 1.	;
;		In addition, it seems that task switching must be	;
;		disabled when int38fun08 is called to do a task to task ;
;		data transfer.	Doing this fixed another problem which	;
;		was occuring sporadically with Progress.		;
;-----------------------------------------------------------------------;
; BWR 11/30/89	Marked messages for foreign language translation.	;
;-----------------------------------------------------------------------;
; BWR 12/21/89  Include of "netbios.pub" was fixed to "_netbios.pub".   ;
;		Routine was failing to assemble over that one!		;
;-----------------------------------------------------------------------;
; SAH 01/08/89  Must save and restore CX for function loclnm. This was	;
;		causing a bizzard problem if more than 2 task were 	;
;		recieving datagrams from single sender. This corrected  ;
;		a problem with OMNILINE (France) Netbios program.	;
;-----------------------------------------------------------------------;
; JRB 09/15/91  doMOSSusp wasn't waking up properly - took tick from    ;
;               llpro netbios and used it for wait command sleep as     ;
;               well as call and send/receive timeout sleep - mospeek   ;
;               and moscall weren't protected from task switching       ;
;               changes id'ed "jrb091591"                               ;
;-----------------------------------------------------------------------;
; SAH 04/21/92  Corrections for Netbios locking up with foxpro (actually;
; 		any INT 2fh call will do. Bad assume duriing int2f. Also;
;		up version to 5.01 and copyright notice.		;
;-----------------------------------------------------------------------;

	.xlist
	include OPTIONS.INC
	include _NETBIOS.PUB
	.list

; rep movsb from ds:si in current task memory to
; es:di in task dx for length cx

doMOSmove macro
	mov	bx,curtsk
	mos38	tskmove
	endm

; interrupt call to address in dword at ds:si in local memory
;   address is in task dx

doMOScall macro
	mov	bp,sp
	lds	si,dword ptr ds:[si]
	mos38	tskcall
	endm

; suspend processing of this task for awhile
;   (switch to a new task)

doMOSsusp macro
	xor	al,al		; wait indefinitely (until post)
	mos38	tskwait
	endm

SCALL	equ	10h
SLISTEN equ	11h
SHANGUP equ	12h
SSND	equ	14h
SRCV	equ	15h
SRCVANY equ	16h
SCHAIN	equ	17h
SNDDG	equ	20h
SRCVDG	equ	21h
SSNDBDG equ	22h
SRCVBDG equ	23h
SADDNAM equ	30h
SDELNAM equ	31h
SRESET	equ	32h
SASTAT	equ	33h
SSSTAT	equ	34h
SCANCEL equ	35h
SADDGRP equ	36h
SUNLINK equ	70h

mos	macro	fn
	mov	ah,fn
	int	21h
	endm

mos38	macro	fn
	mov	ah,fn
	pushf	
        cli                     ;;jrb091591
	call	dword ptr cs:[far38]
	endm

jmpnz	macro	adr
	local	notjmp
	jz	notjmp
	jmp	adr
notjmp:
	endm

jmpz	macro	adr
	local	notjmp
	jnz	notjmp
	jmp	adr
notjmp:
	endm

jmpa	macro	adr
	local	notjmp
	jna	notjmp
	jmp	adr
notjmp:
	endm

dspstr	equ	09h
getver	equ	30h
stay	equ	31h
alloc	equ	48h
free	equ	49h
exit	equ	4ch
getscb	equ	02h
tskwait equ	07h
tskmove equ	08h
tskcall equ	09h
timloc	equ	046ch	; BIOS timer data loc
cto	equ	10	; 5 seconds (500 ms count)

.xlist
SCBseg	segment at 9999 	; to make references to SCB data easier
	assume	cs:SCBseg
	include mosscbdf.inc
	assume	cs:nothing
SCBseg	ends

tcb	segment at 8888 	; to make references to TCB data easier
	include mostcb.inc
tcb	ends
.list

nseg	segment para public 'code'
	assume	cs:nseg,ds:nseg,es:nseg,ss:nseg

; Device driver header

nethdr	label	near
	dd	-1		; next driver
	dw	08000h		; "character" device driver
	dw	offset netstrat ; strategy entry point
	dw	offset netint	; interrupt entry point
	db	"$$$$NETB"	; device name

netmsg	label	near
	db	'MOS NETBIOS Version v5.01',0dh,0ah ;@@XLAT
	db	'(c) Copyright 1987 - 1992  The Software Link, Incorporated' ;@@XLAT

	db	0dh,0ah,'$'
	db	'ADAPTERS='
nadapt	db	'09',0dh,0ah,1ah	;debuggable for number of adapters
permnm	db	10 dup(0)
unitid	db	'SeRiAl'	;debuggable for permanent name
				;  serialized in distribution
reqhdr	dd	?		; pointer to device driver request header

; Network Command Block (NCB - PC Net Tech Ref pgs 2-15, 16)

NCB	struc
ncbcmd	db	?		;NCB_COMMAND
ncbret	db	?		;NCB_RETCODE
ncblsn	db	?		;NCB_LSN
ncbnum	db	?		;NCB_NUM
ncbbuf	dd	?		;NCB_BUFFER@
ncblen	dw	?		;NCB_LENGTH
ncbcnam db	16 dup(?)	;NCB_CALLNAME
ncbnam	db	16 dup(?)	;NCB_NAME
ncbrto	db	?		;NCB_RTO
ncbsto	db	?		;NCB_STO
ncbpost dd	?		;NCB_POST@
ncblana db	?		;NCB_LANA_NUM
ncbcplt db	?		;NCB_CMD_CPLT
ncb_rsv db	14 dup(?)	;NCB_RESERVE
NCB	ends

; each MOS task has a task structure, allocated when that task calls
; int 5ch for the first time
; at the same time, an adapter card emulation is allocated to that task
; adapters are allocated in round robin fashion, so they are shared by as
; few tasks as possible

task	struc
tTCB	dw	?		;TCB pointer from MOS
tadaptr dw	?		;adapter structure for this task (0-inactive)
tpost	dd	?		;current post address
task	ends

; each adapter has a name table with space for 17 names - one is filled in and
; is the permanent name

names	struc
nlnn	db	?		;local name number (0-inactive >0-lnn)
nstate	db	?		;PC Network Tech Ref pg 2-33
nnums	db	?		;number of sessions using name
nhash	dw	?		;hash code for name
nstr	db	16 dup(?)	;name string (all char values allowed)
names	ends

; each adapter has a session table with space for 32 sessions

session struc
slsn	db	?		;local session number (0-inactive >0-lsn)
sstate	db	?		;PC Network Tech Ref pg 2-68
spartnr dw	?		;pointer to partner session record
slnptr	dw	?		;pointer to local name record
spnptr	dw	?		;pointer to partner name record
ssndto	db	?		;send time out
srcvto	db	?		;receive time out
session ends

; each adapter has a command table with space for 32 commands
;   commands are LISTEN, RECEIVE, RECEIVE ANY, RECEIVE DATAGRAM
;   RECEIVE BROADCAST DATAGRAM
; LISTEN stores

command struc
ccode	db	?		;NCB command code (0-inactive >0-NCB cmd)
ctask	dw	?		;owner task
cncb	dd	?		;pointer to NCB
cpost	dd	?		;pointer to post address (NCB_POST@)
clsn	db	?		;NCB_LSN for LISTEN and RECEIVE, else NCB_NUM
cbuffer dd	?		;pointer to buffer (NCB_BUFFER@)
clength dw	?		;length of buffer (NCB_LENGTH)
cmsc	db	cbuffer+16-cmsc dup(?)	;make up difference to store
command ends			;  NCB_CALLNAME for LISTEN
cname	equ	byte ptr cbuffer
cnum	equ	byte ptr clsn

; each adapter structure represents one adapter card emulation
; the command-line determines the number of adapters allocated up to 1 per task

adapter struc
acurn	db	?		;next local name number (0 if adapter inactive)
anames	db	17*type names dup(?)	;17 names for this adapter
anums	db	?		;number of sessions allowed (per last reset)
acurs	db	?		;next local session number
assns	db	32*type session dup(?)	;32 sessions max for each adapter
anumc	db	?		;number of commands allowed (per last reset)
acmds	db	32*type command dup(?)	;32 commands max for each adapter
adapter ends

; Device driver request packet.

devrq	struc
drqlen	db	?		; length of entire request
drquni	db	?		; unit number for request
drqcom	db	?		; command for request
drqsta	dw	?		; status from call
drqres	db	8 dup (?)	; DOS reserved
;	extra fields for init
drqunits db	?		; initialized units
drqendres dd	?		; end of driver code
; drqbpba	dd	?		; BPB pointer array
drqcmdln dd	?		; pointer to command line (same as drqbpba)
drqbdn	db	?		; starting device number
devrq	ends

	subttl	netbios emulation data
	page
nxttsk	dw	?		;ptr to first unallocated task
endtsk	equ	this word	;jrb ptr past task structures
adapts	dw	?		;jrb ptr to start of adapter structures
nxtadp	dw	?		;ptr to first unallocated adapter
endadp	dw	?		;ptr past adapter structures
old5ch	dd	?		;save old value of int 5ch vector
scbptr	dd	0		; MOS SCB pointer
far38	dw	2 dup (0)	; MOSINT38 pointer
ticksps dw	18		; timer ticks per second var - sjc
callto	dw	cto		; call time out time
retrys	dw	8		; standard number of retries
curpri	db	?		; current task priority storage while t.s. off
mosbusy db	0		; debugging!!! flag to tell if in MOSmove

if 1 eq 1	;so PUBLIC.COM doesn't generate the following
ncbptr	equ	(dword ptr [bp-4])	;ncb ptr now
curtsk	equ	(word ptr [bp-06])	;MOS current task id now
ladapt	equ	(word ptr [bp-08])	;local adapter pointer for curtsk
radapt	equ	(word ptr [bp-10])	;pointer to a found remote adapter
lname	equ	(word ptr [bp-12])	;pointer to a found local name
rname	equ	(word ptr [bp-14])	;pointer to a found remote name
lssn	equ	(word ptr [bp-16])	;pointer to a found local session
rssn	equ	(word ptr [bp-18])	;pointer to a found remote session
cmdloc	equ	(word ptr [bp-20])	;pointer to a found free command
ssnloc	equ	(word ptr [bp-22])	;pointer to a found free session
nmloc	equ	(word ptr [bp-24])	;pointer to a found free name
nmhash	equ	(word ptr [bp-26])	;hash code for last hashed name
srchst	equ	(word ptr [bp-28])	;[3] offset of string to search for
hup	equ	(byte ptr [bp-30])	;locally used by hangup procedure
time0	equ	(word ptr [bp-32])	; contains starting send timer value
totloc	equ	(word ptr [bp-34])	; contains time out ticks for send-sjc
locallength equ 34			;[3] - was 30 - SJC

; NOTE: totloc and nmloc are the same, remember never to be used together. sjc
;	time0 and ssnloc also the same, same applies.
; SJC - caused problems when implemented FN10 time out
endif

; vectors to each of the netbios functions

fntbl	dw	fn10,	fn11,	fn12,	0,	fn14,	fn15,	fn16,	fn17
	dw	fn20,	fn21,	fn22,	fn23,	0,	0,	0,	0
	dw	fn30,	fn31,	fn32,	fn33,	fn34,	fn35,	fn36
fnlen	equ	$-fntbl

	subttl	netbios emulation code
	page

; idstr must immediately precede int5ch handler

idstr	db	'NETBIOS'
idlen	equ	$-idstr
	assume	ds:nothing,es:nothing,ss:nothing
int5ch	proc	far
	sti
	push	bp
	mov	bp,sp
	sub	sp,locallength
	push	bp
	push	ds
	push	di
	push	si
	push	dx
	push	cx
	mov	word ptr ncbptr,bx
	mov	word ptr ncbptr+2,es
	mov	es:[bx].ncbcplt,0ffh
	mov	es:[bx].ncbret,0ffh
	mov	cl,es:[bx].ncbcmd ;jrb
	mov	ch,cl		;jrb
	and	cl,7fh		;jrb clear no wait bit and ch
	cmp	cl,70h		;jrb unlink is a special case
	jne	int5c1		;jrb
	xor	al,al		;jrb post no error
	or	ch,ch		;jrb
	jns	int5c2		;jrb wait version is just posted as noerror
	call	fn70		;jrb nowait version releases task and adapter
	xor	al,al		;jrb
	jmp	int5c2		;jrb
int5c1: 			;jrb
	mov	al,23h		;invalid number in NCB_LANA_NUM field
	cmp	es:[bx].ncblana,0
	jne	int5c2
	call	gettsk		;return ds:si pointing to adapter
	jnz	int5c2		;  and ah = task record number
	assume	ds:nseg
	mov	ladapt,si	;pointer to adapter
	mov	cl,es:[bx].ncbcmd
	and	cx,7fh		;clear no wait bit and ch
	sub	cx,10h
	mov	al,03h		;invalid command
	test	cx,08h		;none of the valid commands are x8 - xf
	jnz	int5c2
	mov	di,cx
	and	di,not 0fh
	and	cx,0fh
	shl	cx,1
	or	di,cx
	cmp	di,fnlen	;past end of table ?
	jnb	int5c2		;(note equal for unlink is valid)
	cmp	fntbl[di],0	;valid function ?
	je	int5c2
	call	fntbl[di]	;else execute function
	jmp	int5c3
int5c2:
	call	post
int5c3:
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	ds
	pop	bp
	mov	sp,bp
	pop	bp
	iret
int5ch	endp

	subttl	gettsk - find (or allocate) task structure for this caller
	page

; return ds:si pointing at the adapter structure for this
; return ah = task record number
; MOS task (allocate a task structure and adapter if needed)
; set curtsk to MOS task

	assume	ds:nothing
gettsk	proc	near
	push	es
	les	si,[scbptr]	; Where MOS's SCB lives
	assume	es:SCBseg
	mov	ax,es:[si+scbtcbpc]	; get current task pointer
	assume	es:nothing		; we no longer care what's in es
	push	cs
	pop	ds
	assume	ds:nseg
	mov	curtsk,ax
	mov	cx,ax
	mov	si,offset tasks
	xor	ah,ah		;keep track of task record number as we look
getts1:
	cmp	si,nxttsk
	jnb	getts1a 	;jrb
	cmp	cx,[si].tTCB
	je	getts4		;e if already allocated
	inc	ah
	add	si,type task
	jmp	getts1

; task not currently allocated - allocate next task

getts1a:			;jrb look for released tasks
	mov	si,offset tasks ;jrb
	xor	ah,ah		;jrb
getts1b:			;jrb
	cmp	si,[nxttsk]	;jrb
	jnb	getts2		;jrb nb if no released tasks
	cmp	[si].tTCB,-1	;jrb
	je	getts2a 	;jrb e if a released task
	inc	ah		;jrb
	add	si,type task	;jrb
	jmp	getts1b 	;jrb
getts2:
	mov	si,nxttsk
	cmp	si,[endtsk]	;jrb
	mov	al,7eh		;adapter malfunction error
	jz	getts5		;no more tasks to be allocated
	add	nxttsk,type task
getts2a:			;jrb
	mov	[si].tTCB,cx
	mov	word ptr [si].tpost,offset nullpost
	mov	word ptr [si].tpost+2,cs
	push	si
	push	ax
	call	getadp
	pop	ax
	pop	si
getts4:
	mov	si,[si].tadaptr ;return si -> adapter
	xor	al,al
getts5:
	or	al,al
	pop	es
	ret
gettsk	endp

	subttl	getadp - allocate an adapter structure
	page

; allocate and initialize newly allocated adapter structure as necessary
; ax -> adapter structure
; si -> task structure for new owner (also current end of task list)

getadp	proc	near
	mov	di,[adapts]	;jrb look for a released adapter
getad1a:			;jrb
	cmp	di,[nxtadp]	;jrb
	jnb	getad1b 	;jrb nb if no released adapter
	mov	ax,di		;jrb
	cmp	[di].acurn,0	;jrb
	je	getad1		;jrb e for released adapter
	add	di,type adapter ;jrb
	jmp	getad1a 	;jrb
getad1b:
	mov	ax,nxtadp	;allocate an adapter to the task
	add	nxtadp,type adapter
	mov	di,endadp
	cmp	nxtadp,di
	jbe	getad1		; if reach PAST the last one, its an error
	mov	di,[adapts]	;jrb (note this is now an unsignalled
	mov	[nxtadp],di	;jrb internal error)
getad1:
	mov	[si].tadaptr,ax
	mov	di,offset tasks ;see if it's already initialized for another
getad2:
	cmp	di,[nxttsk]	;jrb
	jnb	getad3		;jrb
	cmp	di,si		;  task
	je	getad2a 	;jrb
	cmp	[di].tTCB,-1	;jrb
	je	getad2a 	;jrb
	cmp	ax,[di].tadaptr
	je	getad5		;has already been initialized
getad2a:			;jrb
	add	di,type task
	jmp	getad2
getad3:
	mov	di,ax
	mov	ah,32		;default number of sessions and commands
	mov	al,32		;  (differs from the PC power-on default)
	call	ainit

; initialize permanent node name

	push	es
	push	cs
	pop	es
	push	di
	mov	di,offset permnm
	call	hashnm
	pop	di
	lea	di,[di].anames
	mov	[di].nlnn,1
	mov	[di].nstate,04h
	mov	[di].nnums,0
	mov	[di].nhash,ax
	lea	di,[di].nstr
	mov	cx,16/2 	;set permanent name
	mov	si,offset permnm
	rep movsw
	mov	si,offset unitid
	mov	di,si		;increment permanent name for next adapter
	mov	cx,6
getad4:
	lodsb
	inc	al
	stosb
	or	al,al
	loopz	getad4		;finished if nz
	pop	es
getad5:
	ret
getadp	endp

	subttl	ainit - initialize an adapter structure
	page

; initialize di -> adapter structure (except for permanent name)
; ah = max number of sessions
; al = max number of commands

ainit	proc	near		;validate number of sessions and number of
	mov	dh,6		;  commands
	or	ah,ah
	jz	ainit1
	mov	dh,32
	cmp	ah,32
	ja	ainit1
	mov	dh,ah
ainit1:
	mov	dl,12
	or	al,al
	jz	ainit2
	mov	dl,32
	cmp	al,32
	ja	ainit2
	mov	dl,al
ainit2:
	mov	[di].acurn,2	;first name will be number 2
	mov	[di].anums,dh	;number of sessions
	mov	[di].acurs,1	;first session will be number 1
	mov	[di].anumc,dl	;number of commands
	push	di		;clear name table
	lea	di,[di+type names].anames
	mov	cx,16
ainit3:
	mov	[di].nlnn,0	;inactive name
	add	di,type names
	loop	ainit3
	pop	di
	push	di		;clear all sessions
	lea	di,[di].assns
	mov	cx,32
ainit5:
	mov	[di].slsn,0
	add	di,type session
	loop	ainit5
	pop	di
	push	di
	lea	di,[di].acmds	;clear all commands
	mov	cx,32
ainit6:
	mov	[di].ccode,0
	add	di,type command
	loop	ainit6
	pop	di
	ret
ainit	endp

	subttl	function 10h emulation - call for a session
	page

; CALL for a session
; open a session with NCB_CALLNAME using the unique local name NCB_NAME
; NCB_CALLNAME must have a LISTEN command outstanding
;   first check for a LISTEN command for a CALL from NCB_NAME
;   then check for a LISTEN command for a CALL from any name
; NCB_CALLNAME may be a local or a remote name
; multiple sessions can be established between the same pair of names
; input fields:
;   NCB_CALLNAME
;   NCB_NAME
;   NCB_RTO
;   NCB_STO
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
;   NCB_LSN
; error codes include:
;   00H - good return
;   11H - local session table is full
;   12H - session open rejected (no LISTEN)
;   14H - can't find NCB_CALLNAME or NCB_CALLNAME is invalid
;   15H - can't find NCB_NAME or NCB_NAME is invalid
;   19H - name conflict detected
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM

	assume	ds:nseg,es:nothing,ss:nothing
fn10	proc	near
	call	freecmd
	jmpnz	fn10x		;22h
	call	freessn
	jmpnz	fn10x		;11h
	lea	di,es:[bx].ncbnam	;NCB_NAME
	call	hashnm
	call	loclnm		;look for name on local adapter
	mov	al,15h
	jmpnz	fn10x		;15H - name not found
	test	[di].nstate,01h
	jmpnz	fn10x		;15h - name is de-registered
	mov	al,19h
	test	[di].nstate,02h
	jmpnz	fn10x		;19h - name conflict detected
	mov	lname,di		; store ptr to local name
	lea	di,es:[bx].ncbcnam	;NCB_CALLNAME
	call	hashnm
	call	findnm		;look for called name on all adapters
	mov	al,14h
	jmpnz	fn10x		;14h - name not found

; set starting time for time out testing

	push	es
	xor	ax,ax
	mov	es,ax
	mov	ax,es:[timloc]
	pop	es
	mov	time0,ax	; save starting time in usable var
	mov	dx,[ticksps]	; time out cnt = time out var * ticksps/2
	shr	dx,1
	mov	ax,[callto]	; get call time out time (in 500ms cnt)
	mul	dx		; time out cnt in ax.
	mov	totloc,ax	; save time out ticks in usable stack var
	mov	rname,di	; store ptr to remote task name
	mov	radapt,si	;save location of remote adapter
fn10lp:
	mov	cl,[si].anumc	; get # of cmds
	xor	ch,ch
	lea	si,[si].acmds	; get ptr to remote cmd struc
	xor	dx,dx		;NULL pointer to found LISTEN for any

; find the session record and command record for the LISTEN

fn10a:
	mov	al,[si].ccode
	and	al,7fh
	cmp	al,SLISTEN
	jne	fn10c
	push	si
	mov	al,[si].clsn
	mov	si,radapt
	call	findssn
	mov	ax,[di].slnptr
	cmp	ax,rname
	pop	si
	jne	fn10c		;listen isn't for name we're calling
	cmp	[si].cname,'*'
	jne	fn10b
	mov	dx,si		;save session pointer in case LISTEN for any
	jmp	short fn10c	;  is only one found
fn10b:
	push	di
	push	si
	push	cx
	lea	si,[si].cname
	lea	di,es:[bx].ncbnam
	mov	cx,16/2
	repe	cmpsw
	pop	cx
	pop	si
	pop	di
	je	fn10d		;found the LISTEN session and command
fn10c:
	add	si,type command
	loop	fn10a

; no LISTEN for name command found

	or	dx,dx		;NZ if LISTEN for any was found
	jnz	fn10e		; establish session

; no listens of any variety were found
;  keep looking for remote listens until internal time out time has expired.
;  This means to allow a task switch now, test current time against time out,
;   then loop to look for more lstns if time not expired.

	xor	ax,ax
	cmp	ax,totloc	; if timer ticks to wait = 0, no send tot,
	je	fn10wa		; wait always if ssndto=0
	push	es
	mov	es,ax
	mov	ax,es:[timloc]	; get current timer value
	pop	es
	sub	ax,time0	; subtract starting time from this time
	cmp	ax,totloc	; and see if past time out ticks
	mov	al,12h		; set possible error code to ses_opn_rej
	jae	fn10x		; past time out time - do error processing
fn10wa:
	call	tick            ;jrb091591
;jrb091591	push	bx
;jrb091591	mov	bx,1
;jrb091591	mov	al,2	; wait for 1 timer tick
;jrb091591	mos38	tskwait ; use MOS to do it
;jrb091591	pop	bx
;jrb091591	mov	ah,1		; wait until past time out time to return error
;jrb091591	int	16h	; o/w just allow task switching until get lstn or error
	mov	si,radapt
	mov	di,rname	; reset remote structure ptrs
	jmp	fn10lp		; loop looking for remote listens
fn10e:
	mov	si,dx
fn10d:
	call	do10		;establish the session
	xor	al,al
fn10x:
	les	bx,ncbptr
	call	post
	ret
fn10	endp

	subttl	do10 - establish a session
	page

; establish a session
; ds:di -> LISTEN session
; ds:si -> LISTEN command
; es:bx -> CALL ncb
; fill out remote session table entry
;   (set sstate=03h, spartnr, spnptr)
; put this local name into remote's LISTEN ncb, delete remote's LISTEN
;   command table entry, post 00h to remote's LISTEN
; fill out this session table entry
; incrememt local name session count

do10	proc	near
	push	si
	mov	si,ladapt
	call	ssnnum
	mov	si,ssnloc
	mov	[si].slsn,al
	mov	es:[bx].ncblsn,al
	mov	al,es:[bx].ncbsto
	mov	[si].ssndto,al
	mov	al,es:[bx].ncbrto
	mov	[si].srcvto,al
	mov	ax,lname
	mov	[si].slnptr,ax
	mov	[di].spnptr,ax
	mov	[di].spartnr,si
	mov	[di].sstate,03h
	mov	ax,[di].slnptr
	mov	[si].spnptr,ax
	mov	[si].spartnr,di
	mov	[si].sstate,03h
	mov	di,[si].slnptr
	inc	[di].nnums
	mov	di,[si].spnptr
	inc	[di].nnums
	pop	si			;jrb

;jrb copy caller's name into listener's ncb

	push	si			;jrb
	mov	dx,[si].ctask		;jrb
	les	bx,[si].cncb
	lea	di,[bx].ncbcnam 	;jrb
	mov	si,[lname]		;jrb
	lea	si,[si].nstr		;jrb
	mov	cx,16			;jrb
	call	MOSmove 		;jrb debugging!!!
	pop	si			;jrb
	mov	al,0
	call	postfar
	ret
do10	endp

	subttl	function 11h emulation - listen for a call
	page

; listen for a call
; listens for a CALL from NCB_CALLNAME or '*' for a CALL from anyone
;   using the unique local name NCB_NAME
; NCB_CALLNAME can be a local or a remote name
; multiple sessions can be established between the same pair of names
; a listen occupies a session table entry
; the local session number (1-254 allocated in round robin manner starting
;   with next available number) returned in NCB_LSN
; if a '*' is used, the name that made the CALL will be returned in
;   NCB_CALLNAME
; input fields:
;   NCB_CALLNAME (including '*')	    
;   NCB_NAME
;   NCB_RTO
;   NCB_STO
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
;   NCB_LSN
;   NCB_CALLNAME (if '*' specifed on input)
; error codes include:
;   00H - good return
; * 0BH - command canceled
;   11H - local session table full
;   15H - can't find NCB_NAME or NCB_NAME is invalid
; * 17H - name was deleted
;(*)19H - name conflict detected
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM
;
; * posted remotely

	assume	ds:nseg,es:nothing,ss:nothing
fn11	proc	near
	call	freecmd
	jnz	fn11x		;22h
	call	freessn
	jnz	fn11x		;11h
	lea	di,es:[bx].ncbnam
	call	hashnm
	call	loclnm		;look for name on local adapter
	mov	al,15h
	jnz	fn11x		;15h - name not found
	test	[di].nstate,01h
	jnz	fn11x		;15h - de-registered
	mov	al,19h
	test	[di].nstate,02h
	jnz	fn11x		;19h - name conflict detected
	mov	lname,di
	call	do11
	call	waitfun 	;wait if no-wait option not chosen
	ret
fn11x:
	les	bx,ncbptr
	call	post
	ret
fn11	endp

; fill out session record (slsn, sstate=01h, spartnr=0, slnptr, spnptr=0,
;   ssndto, srcvto)
; fill out command table entry

do11	proc	near
	call	ssnnum
	mov	di,cmdloc
	mov	si,ssnloc
	mov	[si].slsn,al
	mov	es:[bx].ncblsn,al
	mov	[si].sstate,01h
	mov	[si].spartnr,0
	mov	ax,lname
	mov	[si].slnptr,ax
	lea	ax,[di].cname-nstr	; so spnptr points to a name
	mov	[si].spnptr,ax
	mov	al,es:[bx].ncbsto
	mov	[si].ssndto,al
	mov	al,es:[bx].ncbrto
	mov	[si].srcvto,al
	mov	al,es:[bx].ncbcmd
	mov	[di].ccode,al
	mov	ax,curtsk
	mov	[di].ctask,ax
	mov	word ptr [di].cncb,bx
	mov	word ptr [di].cncb+2,es
	mov	ax,word ptr es:[bx].ncbpost
	mov	word ptr [di].cpost,ax
	mov	ax,word ptr es:[bx].ncbpost+2
	mov	word ptr [di].cpost+2,ax
	mov	al,[si].slsn
	mov	[di].clsn,al
	lea	di,[di].cname
	lea	si,[bx].ncbcnam
	push	ds
	push	es
	pop	ds
	pop	es
	mov	cx,16/2
	rep	movsw
	push	cs
	pop	ds
	mov	es,word ptr ncbptr+2
	ret
do11	endp

	subttl	function 12h emulation - hang up from a session
	page

; hang up from a session
; all pending local and remote RECEIVE commands are terminated (session closed)
; at most one RECEIVE ANY on local name is returned session closed (even if
;   many are pending)
; input fields:
;   NCB_LSN
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
; error codes include:
;   00H - good return (session closed normally)
;   08H - illegal local session number (not found, closed or ended abnormally)
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM

	assume	ds:nseg,es:nothing,ss:nothing
fn12	proc	near
	call	freecmd
	jnz	fn12x		;22h
	mov	al,es:[bx].ncblsn
	call	findssn
	jnz	fn12x		;08h
	mov	al,08h
	cmp	[di].sstate,02h ;mjs
	jz	fn12x		;08h
	push	[di].spartnr
	mov	al,0ah		;session closed
	call	hangup		;hang up our end
	pop	di
	mov	al,0ah		;session closed
	call	hangup		;hang up partner's end
	xor	al,al		;good return
fn12x:
	les	bx,ncbptr
	call	post
	ret
fn12	endp

	subttl	function 14h emulation - send a message within a session
	page

; send a session message
; an unsuccessful send terminates the session
; if a session abnormally terminates, all outstanding session commands for that
;   session are terminated with that status
; if STO = 0 then no timeout occurs (#### what do we do with this one)
; sends data taken from NCB_BUFFER@ for NCB_LENGTH bytes to partner of
;   NCB_LSN
; input fields:
;   NCB_LSN
;   NCB_BUFFER@
;   NCB_LENGTH
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
; error codes include:
;   00H - good return
;   05H - command timed out (no RECEIVE and STO <> 0) 
;   08H - illegal local session number
;   18H - session ended abnormally (no RECEIVE and STO = 0)
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM

	assume	ds:nseg,es:nothing,ss:nothing
fn14	proc	near
	call	freecmd
	jmpnz	fn14x		;22h
	mov	al,es:[bx].ncblsn
	call	findssn
	jmpnz	fn14x		;08h
	mov	al,08h
	cmp	[di].sstate,02h ;mjs
	jmpz	fn14x

; look for any RECEIVEs for this session
; set starting time for time out testing

	push	es
	xor	ax,ax
	mov	es,ax
	mov	ax,es:[timloc]
	pop	es
	mov	time0,ax	; save starting time in usable var
	mov	dx,[ticksps]	; time out cnt = time out var * ticksps/2
	shr	dx,1
	xor	ax,ax		; clr that
	mov	al,[di].ssndto
	mul	dx		; time out cnt in ax.
	mov	totloc,ax	; save time out ticks in usable stack var
	mov	lssn,di 	; save local session ptr
fn14lp:
	mov	di,[di].spartnr
	mov	ah,[di].slsn	;mjs
	mov	rssn,di
	call	adpptr		;compute adapter pointer from session pointer
	mov	cl,[di].anumc
	xor	ch,ch
	lea	di,[di].acmds
	xor	si,si		;save RCVANY for our name if found
	xor	dx,dx		;save RCVANY for any name if found
fn14a:
	mov	al,[di].ccode
	and	al,7fh
	cmp	al,SRCV
	jz	fn14aa		;mjs
	cmp	al,SRCVANY
	jne	fn14c
	cmp	[di].cnum,0ffh
	jne	fn14b
	mov	dx,di
	jmp	fn14c
fn14aa: 			;mjs
	cmp	ah,[di].clsn	;mjs
	jne	fn14c		;mjs
	jmp	fn14f		;mjs
fn14b:
	push	di
	mov	di,rssn
	mov	di,[di].slnptr
	mov	al,[di].nlnn
	pop	di
	cmp	[di].cnum,al
	jne	fn14c
	mov	si,di
fn14c:
	add	di,type command
	loop	fn14a

; no RECEIVE found, see if any RECEIVE ANY's were found

	mov	di,si
	or	di,di		;check for RECEIVE ANY for our name
	jnz	fn14e
	mov	di,dx
	or	di,di		;or RECEIVE ANY for any name
	jnz	fn14d

; no receives of any variety were found
;   hang up session as abnormally terminated
;   if send time-out is 0 then post code is 18h - abnormally terminated
;   else post code is 05h - no receive
;sjc 11/08/88
; if this is the case (no rcvs of any variety found),
;  keep looking for remote rcvs until the time out time has expired.
;  This means to allow a task switch now, test current time against time out,
;   then loop to look for more rcvs if time not expired.
;  Do same for chain send (fn17).

	mov	di,lssn 	; reset local session ptr
	xor	ax,ax
	cmp	ax,totloc	; if timer ticks to wait = 0, no send tot,
	je	fn14wa		; wait always if ssndto=0
	push	es
	mov	es,ax
	mov	ax,es:[timloc]	; get current timer value
	pop	es
	sub	ax,time0	; subtract starting time from this time
	cmp	ax,totloc	; and see if past time out ticks
	jae	fn14pt
fn14wa:
	call	tick            ;jrb091591
;jrb091591	push	bx
;jrb091591	mov	bx,1
;jrb091591	mov	al,2	; wait for 1 timer tick
;jrb091591	mos38	tskwait ; use MOS to do it
;jrb091591	pop	bx
;jrb091591	mov	ah,1		; wait until past time out time to return error
;jrb091591	int	16h		; o/w just allow task switching until get rcv
	jmp	fn14lp		; or error
fn14pt: 			; past time out time - do error processing
	mov	al,[di].ssndto
	push	ax
	push	[di].spartnr
	mov	al,18h		;18h - session abnormally terminated
	call	hangup
	pop	di
	mov	al,18h
	call	hangup
	pop	ax
	or	al,al
	mov	al,05h		;05h - command timed out if send to <> 0
	jnz	fn14x
	mov	al,18h		;18h - abnormally terminated if send to = 0
	jmp	fn14x

; RCV ANY, di -> command
;   fill in remote's ncb with its name number

fn14d:
	push	di
	mov	si,rssn
	mov	si,[si].slnptr
	mov	al,[si].nlnn
	les	bx,[di].cncb
	mov	dx,[di].ctask
	lea	di,[bx].ncbnum
	call	MOSpoke 	; debugging!!!
	pop	di

;   fill in remote's ncb with its session number

fn14e:
	push	di
	mov	si,rssn
	mov	al,[si].slsn
	les	bx,[di].cncb
	mov	dx,[di].ctask
	lea	di,[bx].ncblsn
	call	MOSpoke 	; debugging!!!
	pop	di
fn14f:
	les	bx,ncbptr
	call	do14		; post to remote
	xor	al,al
fn14x:
	les	bx,ncbptr
	call	post
	ret
fn14	endp

; a receive was found, di -> receive command
;   send the message
;   post far 00h or 06h to remote according to receive buffer size
;   post code is 00h - good return

do14	proc	near
	lds	si,es:[bx].ncbbuf
	assume	ds:nothing
	mov	cx,es:[bx].ncblen
	push	cs
	pop	es
	call	sendfar
	push	cs
	pop	ds
	assume	ds:nseg
	mov	si,di
	mov	ax,cx
	les	di,[si].cncb
	lea	di,[di].ncblen
	mov	dx,[si].ctask
	call	MOSpokw 	; debugging!!!
	les	bx,ncbptr
	mov	al,00h		;good return
	cmp	cx,es:[bx].ncblen
	je	do14a
	mov	al,06h		;receive buffer too small
do14a:
	call	postfar
	ret
do14	endp

	subttl	function 15h emulation - receive a message within a session
	page

; receive a session message
; receives posted in order
;   RECEIVE, RECEIVE ANY for specified name, RECEIVE ANY for any name
;   FIFO within category
; input fields:
;   NCB_LSN
;   NCB_BUFFER@
;   NCB_LENGTH
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
;   NCB_LENGTH
; error codes include:
;   00H - good return
; * 06H - message incomplete (buffer length too small)
;	  note: doc states the rest can be received by re-issuing the receive
;	  command before a time-out occurs in our emulation, the time-out has
;	  always occurred and the rest is lost
;   08H - illegal local session number
; * 0AH - session closed
; * 0BH - command cancelled
; * 18H - session ended abnormally
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM
;
; * posted remotely

	assume	ds:nseg,es:nothing,ss:nothing
fn15	proc	near
	call	freecmd
	jnz	fn15x		;22h
	mov	al,es:[bx].ncblsn
	call	findssn
	jnz	fn15x		;08h
	mov	al,08h
	cmp	[di].sstate,02h ;mjs
	jz	fn15x
	mov	di,cmdloc
	mov	al,es:[bx].ncbcmd
	mov	[di].ccode,al
	mov	ax,curtsk
	mov	[di].ctask,ax
	mov	word ptr [di].cncb,bx
	mov	word ptr [di].cncb+2,es
	mov	al,es:[bx].ncblsn
	mov	[di].clsn,al
	mov	ax,word ptr es:[bx].ncbbuf
	mov	word ptr [di].cbuffer,ax
	mov	ax,word ptr es:[bx].ncbbuf+2
	mov	word ptr [di].cbuffer+2,ax
	mov	ax,es:[bx].ncblen
	mov	[di].clength,ax
	mov	ax,word ptr es:[bx].ncbpost
	mov	word ptr [di].cpost,ax
	mov	ax,word ptr es:[bx].ncbpost+2
	mov	word ptr [di].cpost+2,ax
	call	waitfun 	;wait if no-wait option not chosen
	ret
fn15x:
	les	bx,ncbptr
	call	post
	ret
fn15	endp

	subttl	function 16h emulation - receive a message within any session
	page

; receive any session message
; receives posted in order
;   RECEIVE, RECEIVE ANY for specified name, RECEIVE ANY for any name
;   FIFO within category
; NCB_NUM has local name number to receive or 0ffh for any local name with
;   a session
; if session closed or session ended abnormally, and a RECEIVE ANY is posted,
;   the LSN ended is put in NCB_LSN - at most one RECEIVE ANY is posted,
;   first for specified name if any for ended session, then RECEIVE ANY for
;   any name if any active
; input fields:
;   NCB_BUFFER@
;   NCB_LENGTH
;   NCB_NUM	(0ffh for RECEIVE ANY for any name)
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_LSN
;   NCB_RETCODE
;   NCB_NUM	(if 0ffh specifed on input)
;   NCB_LENGTH
; error codes include:
;   00H - good return
; * 06H - message incomplete (buffer length too small)
;	  note: doc states the rest can be received by re-issuing the receive
;	  command before a time-out occurs in our emulation, the time-out has
;	  always occurred and the rest is lost
; * 0AH - session closed
; * 0BH - command cancelled
;   13H - illegal name number (or not found)
; * 17H - name was deleted
; * 18H - session ended abnormally
;(*)19H - name conflict detected
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM
;
; * remotely posted

	assume	ds:nseg,es:nothing,ss:nothing
fn16	proc	near
	call	freecmd
	jnz	fn16x		;22h
	mov	al,es:[bx].ncbnum
	cmp	al,0ffh
	je	fn16a
	call	findnum
	jnz	fn16x		;13h
	mov	al,13h
	test	[di].nstate,01h
	jnz	fn16x		;13h - name de-registered
	mov	al,19h
	test	[di].nstate,02h
	jnz	fn16x		;19h - name conflict detected
fn16a:
	mov	di,cmdloc
	mov	al,es:[bx].ncbcmd
	mov	[di].ccode,al
	mov	ax,curtsk
	mov	[di].ctask,ax
	mov	word ptr [di].cncb,bx
	mov	word ptr [di].cncb+2,es
	mov	al,es:[bx].ncbnum
	mov	[di].cnum,al
	mov	ax,word ptr es:[bx].ncbbuf
	mov	word ptr [di].cbuffer,ax
	mov	ax,word ptr es:[bx].ncbbuf+2
	mov	word ptr [di].cbuffer+2,ax
	mov	ax,es:[bx].ncblen
	mov	[di].clength,ax
	mov	ax,word ptr es:[bx].ncbpost
	mov	word ptr [di].cpost,ax
	mov	ax,word ptr es:[bx].ncbpost+2
	mov	word ptr [di].cpost+2,ax
	call	waitfun 	;wait if no-wait option not chosen
	ret
fn16x:
	les	bx,ncbptr
	call	post
	ret
fn16	endp

	subttl	function 17h emulation - chain send within a session
	page

; chain send a session message
; an unsuccessful send terminates the session
; if a session abnormally terminates, all outstanding session commands for that
;   session are terminated with that status
; if STO = 0 then no timeout occurs (#### what do we do with this one)
; sends data taken from NCB_BUFFER@ for NCB_LENGTH bytes to partner of
;   NCB_LSN
; then sends data taken from dword ptr NCB_CALLNAME+2 for word NCB_CALLNAME 
;   bytes to partner
; input fields:
;   NCB_LSN
;   NCB_BUFFER@
;   NCB_LENGTH
;   NCB_CALLNAME	(word length of second buffer)
;   NCB_CALLNAME+2	(dword ptr to second buffer)
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
; error codes include:
;   00H - good return
;   08H - illegal local session number
;   05H - command timed out (no RECEIVE and STO <> 0) 
;   18H - session ended abnormally (no RECEIVE and STO = 0)
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM

	assume	ds:nseg,es:nothing,ss:nothing
fn17	proc	near
	call	freecmd
	jmpnz	fn17x		;22h
	mov	al,es:[bx].ncblsn
	call	findssn
	jmpnz	fn17x		;08h
	mov	al,08h
	cmp	[di].sstate,02h ;mjs
	jmpz	fn17x

; look for any RECEIVEs for this session
; set starting time for time out testing

	push	es
	xor	ax,ax
	mov	es,ax
	mov	ax,es:[timloc]
	pop	es
	mov	time0,ax	; save starting time in usable var
	mov	dx,[ticksps]	; time out cnt = time out var * ticksps/2
	shr	dx,1
	xor	ax,ax		; clr it
	mov	al,[di].ssndto
	mul	dx		; time out cnt in ax.
	mov	totloc,ax	; save time out ticks in usable stack var
	mov	lssn,di 	; save local session ptr
fn17lp:
	mov	di,[di].spartnr
	mov	rssn,di
	call	adpptr		;compute adapter pointer from session pointer
	mov	cl,[di].anumc
	xor	ch,ch
	lea	di,[di].acmds
	xor	si,si		;save RCVANY for our name if found
	xor	dx,dx		;save RCVANY for any name if found
fn17a:
	mov	al,[di].ccode
	and	al,7fh
	cmp	al,SRCV
	jmpz	fn17f
	cmp	al,SRCVANY
	jne	fn17c
	cmp	[di].cnum,0ffh
	jne	fn17b
	mov	dx,di
	jmp	fn17c
fn17b:
	push	di
	mov	di,rssn
	mov	di,[di].slnptr
	mov	al,[di].nlnn
	pop	di
	cmp	[di].cnum,al
	jne	fn17c
	mov	si,di
fn17c:
	add	di,type command
	loop	fn17a

; no RECEIVE found, see if any RECEIVE ANY's were found

	mov	di,si
	or	di,di		;check for RECEIVE ANY for our name
	jnz	fn17e
	mov	di,dx
	or	di,di		;or RECEIVE ANY for any name
	jnz	fn17d

; no receives of any variety were found
;   hang up session as abnormally terminated
;   if send time-out is 0 then post code is 18h - abnormally terminated
;   else post code is 05h - no receive
;sjc 11/08/88
; if this is the case (no rcvs of any variety found),
;  keep looking for remote rcvs until the time out time has expired.
;  This means to allow a task switch now, test current time against time out,
;   then loop to look for more rcvs if time not expired.

	mov	di,lssn 	; reset local session ptr
	xor	ax,ax
	cmp	ax,totloc	; if timer ticks to wait = 0, no send tot,
	je	fn17wa		; wait always if ssndto=0
	push	es
	mov	es,ax
	mov	ax,es:[timloc]	; get current timer value
	pop	es
	sub	ax,time0	; subtract starting time from this time
	cmp	ax,totloc	; and see if past time out ticks
	jae	fn17pt
fn17wa:
	call	tick            ;jrb091591
;jrb091591	push	bx
;jrb091591	mov	bx,1
;jrb091591	mov	al,2	; wait for 1 timer tick
;jrb091591	mos38	tskwait ; use MOS to do it
;jrb091591	pop	bx
;jrb091591	mov	ah,1		; wait until past time out time to return error
;jrb091591	int	16h		; o/w just allow task switching until get rcv
	jmp	fn17lp		; or error
fn17pt: 			; past time out time - do error processing
	mov	di,lssn
	mov	al,[di].ssndto
	push	ax
	push	[di].spartnr
	mov	al,18h		;18h - session abnormally terminated
	call	hangup
	pop	di
	mov	al,18h
	call	hangup
	pop	ax
	or	al,al
	mov	al,05h		;05h - command timed out if send to <> 0
	jnz	fn17x
	mov	al,18h		;18h - abnormally terminated if send to = 0
	jmp	fn17x

; RCV ANY, di -> command
;   fill in remote's ncb with its name number

fn17d:
	push	di
	mov	si,rssn
	mov	si,[si].slnptr
	mov	al,[si].nlnn
	les	bx,[di].cncb
	mov	dx,[di].ctask
	lea	di,[bx].ncbnum
	call	MOSpoke
	pop	di

; fill in remote's ncb with its session number

fn17e:
	push	di
	mov	si,rssn
	mov	al,[si].slsn
	les	bx,[di].cncb
	mov	dx,[di].ctask
	lea	di,[bx].ncblsn
	call	MOSpoke
	pop	di
fn17f:
	les	bx,ncbptr
	call	do17
	xor	al,al
fn17x:
	les	bx,ncbptr
	call	post
	ret
fn17	endp

; a receive was found, di -> receive command
;   send the message
;   post far 00h or 06h to remote according to receive buffer size
;   post code is 00h - good return

do17	proc	near
	lds	si,es:[bx].ncbbuf
	assume	ds:nothing
	mov	cx,es:[bx].ncblen
	push	cs
	pop	es
	call	sendfar
	push	cs
	pop	ds
	assume	ds:nseg
	les	bx,ncbptr
	mov	al,06h		;receive buffer too small
	cmp	cx,es:[bx].ncblen
	jne	do17a
	sub	[di].clength,cx
	add	word ptr [di].cbuffer,cx
	push	cx
	lds	si,dword ptr es:[bx].ncbcnam+2
	assume	ds:nothing
	mov	cx,word ptr es:[bx].ncbcnam
	push	cs
	pop	es
	call	sendfar
	push	cs
	pop	ds
	assume	ds:nseg
	pop	ax
	add	cx,ax
do17a:
	mov	si,di
	mov	ax,cx
	mov	dx,[si].ctask
	les	di,[si].cncb
	lea	di,[di].ncblen
	call	MOSpokw
	les	bx,ncbptr
	mov	dx,es:[bx].ncblen
	add	dx,word ptr es:[bx].ncbcnam
	mov	al,06h
	cmp	cx,dx
	jne	do17x
	mov	al,00h		;receive buffer too small
do17x:
	call	postfar
	ret
do17	endp

	subttl	function 20h emulation - send datagram
	page

; send datagram message
; send to unique name or group name of local or remote adapter
; messages can be from 0 to 512 bytes
; input fields:
;   NCB_BUFFER@
;   NCB_LENGTH
;   NCB_NUM
;   NCB_CALLNAME
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
; errors include:
;   00H - good return (including no receives)
;   01H - illegal buffer length (> 512)
;   13H - illegal local name number or not found
;   19H - name conflict detected
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM

	assume	ds:nseg,es:nothing,ss:nothing
fn20	proc	near
	call	freecmd
	jmpnz	fn20x		;22h
	mov	al,01h
	cmp	es:[bx].ncblen,512
	jmpa	fn20x		;01h - illegal buffer length
	mov	al,es:[bx].ncbnum
	call	findnum
	jmpnz	fn20x		;13h
	mov	al,13h
	test	[di].nstate,01h
	jmpnz	fn20x		;13h - name is de-registered
	mov	al,19h
	test	[di].nstate,02h
	jmpnz	fn20x		;19h - name conflict detected
	lea	di,es:[bx].ncbcnam
	call	hashnm
fn20a:
	cmp	[si].acurn,0	;jrb adapter not allocated
	je	fn20f		;jrb
	mov	cl,[si].anumc
	xor	ch,ch
	lea	di,[si].acmds
fn20b:
	mov	al,[di].ccode
	and	al,7fh
	cmp	al,SRCVDG
	jne	fn20e
	cmp	[di].cnum,0ffh
	jne	fn20c
	push	di
	mov	ax,nmhash
	lea	di,es:[bx].ncbcnam
	call	loclnm
	mov	al,[di].nlnn
	pop	di
	jnz	fn20e
	mov	[di].cnum,al
	jmp	fn20d
fn20c:
	push	di
	push	si
	push	cx
	mov	al,[di].cnum
	call	findnum
	lea	si,[di].nstr
	lea	di,[bx].ncbcnam
	mov	cx,16/2
	repe cmpsw
	pop	cx
	pop	si
	pop	di
	jne	fn20e
fn20d:
	call	senddg
fn20e:
	add	di,type command
	loop	fn20b
fn20f:				;jrb
	add	si,type adapter
	cmp	si,nxtadp	;jrb
	jb	fn20g		;jrb
	mov	si,[adapts]	;jrb
fn20g:
	cmp	si,ladapt
	jne	fn20a
	xor	al,al
fn20x:
	les	bx,ncbptr
	call	post
	ret
fn20	endp

	subttl	function 21h emulation - receive datagram
	page

; receive datagram message
; receive from any name directed at local name (can be a group name)
; input fields:
;   NCB_BUFFER@
;   NCB_LENGTH
;   NCB_NUM	(0ffh to receive for any local name)
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
;   NCB_LENGTH
;   NCB_CALLNAME	(send datagram name)
;   NCB_NUM	(not specified in doc - if 0ffh above)
; error codes:
;   00H - good return
;   01H - illegal buffer length
; * 06H - message incomplete (buffer too short)
; * 0BH - command cancelled
;   13H - illegal local name number
; * 17H - name was deleted
;(*)19H - name conflict detected
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM
;
; * remotely posted

	assume	ds:nseg,es:nothing,ss:nothing
fn21	proc	near
	call	freecmd
	jnz	fn21x		;22h
	mov	al,01h
	cmp	es:[bx].ncblen,512
	ja	fn21x		;01h - buffer length illegal
	mov	al,es:[bx].ncbnum
	cmp	al,0ffh
	je	fn21a
	call	findnum
	jnz	fn21x		;13h
	mov	al,13h
	test	[di].nstate,01h
	jnz	fn21x		;13h - name is de-registered
	mov	al,19h
	test	[di].nstate,02h
	jnz	fn21x		;19h - name conflict detected
fn21a:
	mov	di,cmdloc
	mov	al,es:[bx].ncbcmd
	mov	[di].ccode,al
	mov	ax,curtsk
	mov	[di].ctask,ax
	mov	word ptr [di].cncb,bx
	mov	word ptr [di].cncb+2,es
	mov	al,es:[bx].ncbnum
	mov	[di].cnum,al
	mov	ax,word ptr es:[bx].ncbbuf
	mov	word ptr [di].cbuffer,ax
	mov	ax,word ptr es:[bx].ncbbuf+2
	mov	word ptr [di].cbuffer+2,ax
	mov	ax,es:[bx].ncblen
	mov	[di].clength,ax
	mov	ax,word ptr es:[bx].ncbpost
	mov	word ptr [di].cpost,ax
	mov	ax,word ptr es:[bx].ncbpost+2
	mov	word ptr [di].cpost+2,ax
	call	waitfun 	;wait if no-wait option not chosen
	ret
fn21x:
	les	bx,ncbptr
	call	post
	ret
fn21	endp

	subttl	function 22h emulation - send broadcast datagram
	page

; send broadcast datagram message
; send to anyone with a receive broadcast datagram command
; messages can be from 0 to 512 bytes
; a send broadcast datagram message satisfies all outstanding receive
;   broadcast datagram commands
; input fields:
;   NCB_BUFFER@
;   NCB_LENGTH
;   NCB_NUM
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
; errors include:
;   00H - good return (including no receives)
;   01H - illegal buffer length (> 512)
;   13H - illegal local name number or not found
;   19H - name conflict detected
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM

	assume	ds:nseg,es:nothing,ss:nothing
fn22	proc	near
	call	freecmd
	jnz	fn22x		;22h
	mov	al,01h
	cmp	es:[bx].ncblen,512
	ja	fn22x		;01h - illegal buffer length
	mov	al,es:[bx].ncbnum
	call	findnum
	jnz	fn22x		;13h
	mov	al,13h
	test	[di].nstate,01h
	jnz	fn22x		;13h - name is de-registered
	mov	al,19h
	test	[di].nstate,02h
	jnz	fn22x		;19h - name conflict detected
fn22a:
	cmp	[si].acurn,0	;jrb
	je	fn22d		;jrb
	mov	cl,[si].anumc
	xor	ch,ch
	lea	di,[si].acmds
fn22b:
	mov	al,[di].ccode
	and	al,7fh
	cmp	al,SRCVBDG
	jne	fn22c
	call	senddg
fn22c:
	add	di,type command
	loop	fn22b
fn22d:				;jrb
	add	si,type adapter
	cmp	si,[nxtadp]	;jrb
	jb	fn22e		;jrb
	mov	si,[adapts]	;jrb
fn22e:
	cmp	si,ladapt
	jne	fn22a
	xor	al,al
fn22x:
	les	bx,ncbptr
	call	post
	ret
fn22	endp

	subttl	function 23h emulation - receive broadcast datagram
	page

; receive broadcast datagram message
; receive from any send broadcast datagram
; input fields:
;   NCB_BUFFER@
;   NCB_LENGTH
;   NCB_NUM
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
;   NCB_LENGTH
;   NCB_CALLNAME	(send datagram name)
;   NCB_NUM
; error codes:
;   00H - good return
; * 06H - message incomplete (buffer too short)
; * 0BH - command cancelled
;   13H - illegal local name number
; * 17H - name was deleted
;   19H - name conflict detected
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM
;
; * remotely posted

	assume	ds:nseg,es:nothing,ss:nothing
fn23	proc	near
	call	freecmd
	jnz	fn23x		;22h
	mov	al,es:[bx].ncbnum
	call	findnum
	jnz	fn23x		;13h
	mov	al,13h
	test	[di].nstate,01h
	jnz	fn23x		;13h - name is de-registered
	mov	al,19h
	test	[di].nstate,02h
	jnz	fn23x		;19h - name conflict detected
	mov	di,cmdloc
	mov	al,es:[bx].ncbcmd
	mov	[di].ccode,al
	mov	ax,curtsk
	mov	[di].ctask,ax
	mov	word ptr [di].cncb,bx
	mov	word ptr [di].cncb+2,es
	mov	al,es:[bx].ncbnum
	mov	[di].cnum,al
	mov	ax,word ptr es:[bx].ncbbuf
	mov	word ptr [di].cbuffer,ax
	mov	ax,word ptr es:[bx].ncbbuf+2
	mov	word ptr [di].cbuffer+2,ax
	mov	ax,es:[bx].ncblen
	mov	[di].clength,ax
	mov	ax,word ptr es:[bx].ncbpost
	mov	word ptr [di].cpost,ax
	mov	ax,word ptr es:[bx].ncbpost+2
	mov	word ptr [di].cpost+2,ax
	call	waitfun 	;wait if no-wait option not chosen
	ret
fn23x:
	les	bx,ncbptr
	call	post
	ret
fn23	endp

	subttl	function 30h emulation - add unique name
	page

; add unique name
; returns number of name in NCB_NUM for datagram and RECEIVE ANY
; input fields:
;   NCB_NAME
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
;   NCB_NUM
; errors include:
;   00H - good return
;   0DH - duplicate name in local table
;   0EH - name table is full
;   15H - name is invalid
;   16H - name in use on remote adapter
;   19H - name conflict detected
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM

	assume	ds:nseg,es:nothing,ss:nothing
fn30	proc	near
	call	freecmd 	;is there room for this command
	jnz	fn30x		;22h
	call	freenm		;is there room for a name
	jnz	fn30x		;0eh
	mov	al,15h
	mov	ah,es:[bx].ncbnam
	or	ah,ah
	jz	fn30x		;15h - illegal name
	cmp	ah,'*'
	je	fn30x		;15h - illegal name
	lea	di,es:[bx].ncbnam	;es:di -> name to hash
	call	hashnm		;validate and hash name
	call	loclnm		;in the local table?
	jnz	fn30a
	mov	al,[di].nlnn
	mov	es:[bx].ncbnum,al	;return local name number if any
	test	[di].nstate,02h
	mov	al,0dh
	jz	fn30x		;0dh - duplicate name in local name table
	mov	al,19h
	jmp	fn30x		;19h - name conflict detected
fn30a:
	lea	di,es:[bx].ncbnam
	mov	ax,nmhash
	call	findnm		;in any table?
	mov	al,16h
	jz	fn30x		;16h - name in use on remote adapter
fn30b:
	mov	si,ladapt
	mov	di,nmloc

; ds:di -> free slot in name table
; es:bx -> ncb
; ds:si -> adapter

	mov	[di].nnums,0
	mov	ax,nmhash
	mov	[di].nhash,ax	;hash code for name
	mov	[di].nstate,04h ;name is unique and registered
	call	namenm		;get next name number
	mov	[di].nlnn,al	;local name number for this name
	mov	es:[bx].ncbnum,al ;and return name number
	push	es
	push	es		;xchg ds,es
	push	ds
	pop	es
	pop	ds
	lea	di,[di].nstr
	lea	si,es:[bx].ncbnam
	mov	cx,16/2
	rep movsw
	push	cs
	pop	ds
	pop	es
	xor	al,al
fn30x:
	les	bx,ncbptr
	call	post
	ret
fn30	endp

	subttl	function 31h emulation - delete name
	page

; delete name
; if the name has active sessions, it's flagged as de-registered until
;   the sessions are closed
; a de-registered name continues to occupy a name table entry until the
;   sessions are closed
; non-active session commands for name (LISTEN, RECEIVE ANY,
;   RECEIVE DATAGRAM, RECEIVE BROADCAST DATAGRAM) are terminated with
;   "name was deleted" status	       
; input fields:
;   NCB_NAME
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
; errors include:
;   00H - good return
;   0FH - name de-registered, has active sessions
;   15H - name not found or invalid
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM

	assume	ds:nseg,es:nothing,ss:nothing
fn31	proc	near
	call	freecmd 	;is there room for this command
	jmpnz	fn31x		;22h
	lea	di,es:[bx].ncbnam	;es:di -> name to hash
	call	hashnm		;validate and hash name
	call	loclnm		;in the local table?
	mov	al,15h
	jmpnz	fn31x		;15h - name not found

; ds:di -> name to be deleted
; es:bx -> ncb
; ds:si -> adapter
; terminate non-active session commands posting 17h - name was deleted status

	mov	lname,di
	mov	si,ladapt
	mov	cl,[si].anumc
	xor	ch,ch
	lea	si,[si].acmds
fn31c:
	mov	al,[si].ccode
	and	al,7fh
	cmp	al,SRCVANY
	je	fn31d
	cmp	al,SRCVDG
	je	fn31d
	cmp	al,SRCVBDG
	je	fn31d
	cmp	al,SLISTEN
	jne	fn31f
	push	di
	push	si
	mov	di,si
	call	adpptr
	mov	al,[si].clsn
	mov	si,di
	call	findssn
	mov	bx,di
	pop	si
	pop	di
	cmp	di,[bx].slnptr
	jne	fn31f		;ne if this session with a different name
	mov	[bx].slsn,0	;delete session record
	jmp	fn31e
fn31d:
	mov	al,[di].nlnn
	cmp	al,[si].cnum
	jne	fn31f
fn31e:
	mov	al,17h		;delete command record
	call	postfar
fn31f:
	add	si,type command
	loop	fn31c
	mov	al,00h		;00h - good return
	mov	di,lname
	mov	ah,[di].nlnn
	mov	[di].nlnn,0	;delete it
	cmp	[di].nnums,0
	je	fn31x
	mov	[di].nlnn,ah	;un-delete it
	or	[di].nstate,01h ;de-register it instead
	mov	al,0fh		;0fh - name de-registered, has active sessions
fn31x:
	les	bx,ncbptr
	call	post
	ret
fn31	endp

	subttl	function 32h emulation - reset adapter card
	page

; reset adapter card
; note: since we evaluate all commands to completion at time of call except:
;   listen
;   receive
;   receive any
;   receive datagram
;   receive broadcast datagram
; we don't have to worry about waiting for any commands
; the reset command aborts all sessions
; adapter is initialized as specified in ncb
; clear name and session tables
; set number of sessions and number of NCB's supported on adapter
; note: effect on active commands is unspecified - we post them all
;   as "unusual network condition"
; input fields:
;   NCB_LSN - number of sessions to support (0 => 6,  max is 32)
;   NCB_NUM - number of commands to support (0 => 12, max is 32)
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
; error codes:
; 00H - good return
; 03H - invalid command (no-wait option is invalid)
; 23H - invalid NCB_LANA_NUM

	assume	ds:nseg,es:nothing,ss:nothing
fn32	proc	near
	mov	al,03h		;03h - invalid command
	test	es:[bx].ncbcmd,80h
	jnz	fn32x		;no-wait option is invalid
	mov	cl,[si].anums
	xor	ch,ch
	lea	si,[si].assns
fn32a:
	cmp	[si].slsn,0
	je	fn32b		;session not active
	mov	di,si
	push	[di].spartnr
	mov	al,18h		;session ended abnormally
	call	hangup		;hang up locally
	pop	di
	mov	al,18h		;session ended abnormally
	call	hangup		;hang up on partner
fn32b:
	add	si,type session
	loop	fn32a
	mov	si,ladapt
	mov	cl,[si].anumc
	xor	ch,ch
	lea	si,[si].acmds
fn32c:
	cmp	[si].ccode,0	;complete any active commands
	je	fn32d
	mov	al,40h		;unusual network condition
	call	postfar
fn32d:
	add	si,type command
	loop	fn32c
	les	bx,ncbptr
	mov	ah,es:[bx].ncblsn	;max number of local sessions now
	mov	al,es:[bx].ncbnum	;max number of commands now
	mov	di,ladapt
	call	ainit
	xor	al,al		;good return
fn32x:
	les	bx,ncbptr
	call	post
	ret
fn32	endp

	subttl	function 33h emulation - adapter status
	page

; return status of adapter
; '*' in NCB_CALLNAME for local adapter status
; else remote adapter status
; input fields:
;   NCB_BUFFER@
;   NCB_LENGTH
;   NCB_CALLNAME	('*' local adapter, else remote)
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
;   NCB_LENGTH		(not in doc - but we put it in anyway)
; errors include:
;   00H - good return
;   06H - message incomplete (receive buffer too small)
;   14H - name not found (not in doc - put it in)
;   19H - name conflict detected
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM
; first approximation is to assume nobody looks at any of this stuff
;   otherwise we'll have to look at emulating them more closely in terms
;   of what a real adapter returns

statbf	label	byte
sunit	db	6 dup(?);unit identification number (#### storage order)
	db	0C0H	;external jumper status (W2 and W1)
			;  (#### W2 value)
			;  bit set => jumper on adapter
			;  W1 on adapter => no RPL
	db	0	;results of last power on self test
	db	0	;software major version number
	db	0	;software minor version number

; traffic and error statistics

	dw	0	;duration of reporting period in minutes
	dw	0	;quantity of crc errors received
	dw	0	;quantity of alignment errors received
	dw	0	;quantity of collisions encountered
	dw	0	;quantity of aborted transmissions
	dd	0	;number of successfully transmitted packets
	dd	0	;number of successfully received packets
	dw	0	;number of retransmissions
	dw	0	;number of times receiver exhausted its resources

; adapter resource statistics

	db	8 dup(0)	;reserved for internal use
scmdf	dw	?	;free command blocks
scmdmx	dw	?	;configured maximum command blocks
	dw	32	;maximum possible configured command blocks
	db	4 dup(0)	;reserved for internal use
sssna	dw	?	;pending sessions
sssnmx	dw	?	;configured maximum pending sessions
	dw	32	;total maximum of possible sessions
sdatap	dw	512	;maximum session data packet size
snnum	dw	0	;number of names in local name table

; local name table

snames	db	16*18 dup(?)

	assume	ds:nseg,es:nothing,ss:nothing
fn33	proc	near
	call	freecmd 	;is there at least one empty command slot?
	jnz	fn33x		;22h
	cmp	byte ptr es:[bx].ncbcnam,'*'
	je	fn33a		;local adapter requested ?
	lea	di,es:[bx].ncbcnam	;es:di -> name to hash
	call	hashnm		;note: name must be valid (no leading '*')
	call	findnm		;find adapter for name (ds:si->adapter)
	mov	al,14h
	jnz	fn33x		;14h - name not found
fn33a:
	call	astat		;construct adapter status buffer
	mov	si,offset statbf
	sub	di,si
	mov	cx,di
	call	send		;send status results to requester
	mov	es:[bx].ncblen,cx
fn33x:
	les	bx,ncbptr
	call	post
	ret
fn33	endp

	subttl	astat - construct adapter status for fn33
	page

; construct adapter status buffer
; si -> adapter

astat	proc	near
				;#### (what is the real byte ordering for name)
				;permanent name
	mov	ax,word ptr [si+anames].nstr+10
	mov	word ptr sunit,ax
	mov	ax,word ptr [si+anames].nstr+12
	mov	word ptr sunit+2,ax
	mov	ax,word ptr [si+anames].nstr+14
	mov	word ptr sunit+4,ax

; count free command blocks

	push	si
	mov	cl,[si].anumc
	xor	ch,ch
	mov	scmdmx,cx	;configured maximum command blocks
	lea	si,[si].acmds
	xor	ax,ax
astat1:
	cmp	[si].ccode,0
	jne	astat2
	inc	ax
astat2:
	add	si,type command
	loop	astat1
	mov	scmdf,ax
	pop	si

; count current sessions active (or pending)

	push	si
	mov	cl,[si].anums
	xor	ch,ch
	mov	sssnmx,cx	;configured maximum sessions
	lea	si,[si].assns
	xor	ax,ax
astat3:
	cmp	[si].slsn,0
	je	astat4
	inc	ax
astat4:
	add	si,type session
	loop	astat3
	mov	sssna,ax	;current active sessions
	pop	si
	push	es		;save es (segment of ncb)
	push	ds
	pop	es
	assume	es:nseg
	mov	di,offset snames
	lea	si,[si+type names].anames
	mov	cx,16
	xor	ah,ah
astat5:
	cmp	[si].nlnn,0
	je	astat6
	push	si
	push	cx
	lea	si,[si].nstr
	mov	cx,16
	rep movsb
	pop	cx
	pop	si
	mov	al,[si].nlnn
	stosb
	mov	al,[si].nstate
	stosb
	inc	ah
astat6:
	add	si,type names
	loop	astat5
	mov	al,ah
	cbw
	mov	snnum,ax
	pop	es
	assume	es:nothing
	ret
astat	endp

	subttl	function 34h emulation - return session status
	page

; session status
; '*' in NCB_NAME for all sessions for all names in local table
; else all sessions for a name
; input fields:
;   NCB_BUFFER@
;   NCB_LENGTH
;   NCB_NAME		('*' local adapter, else remote)
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
;   NCB_LENGTH
; errors include:
;   00H - good return
;   06H - message incomplete (receive buffer too small)
;   15H - name not found or invalid
;   19H - name conflict detected
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM

ssnstat label	byte
sslnn	db	?		;local name number for this name
ssnum	db	?		;number of sessions for this name
ssrdg	db	?		;number of rcv datagram and rcv broadcast
ssrany	db	?		;number of rcv any
sslist	db	32*36 dup(?)	;session status buffer

	assume	ds:nseg,es:nothing,ss:nothing 
fn34	proc	near
	mov	sslnn,0ffh	;#### this needs to be check out against
				;####	the actual result for '*'
	mov	ssrdg,0
	mov	ssrany,0
	mov	ssnum,0
	call	freecmd
	jmpnz	fn34x		;22h
	cmp	es:[bx].ncbnam,'*'
	je	fn34a
	lea	di,es:[bx].ncbnam
	call	hashnm
	call	loclnm
	mov	al,15h
	jnz	fn34x		;15h - name not found
	mov	al,19h
	test	[di].nstate,02h
	jnz	fn34x		;19h - name conflict detected
	mov	lname,di
	mov	al,[di].nlnn
	mov	sslnn,al
fn34a:
	lea	di,[si].acmds
	mov	cl,[si].anumc
	xor	ch,ch
fn34b:
	mov	al,[di].ccode
	and	al,7fh
	cmp	al,SRCVANY
	jne	fn34c
	inc	ssrany
	jmp	fn34e
fn34c:
	cmp	al,SRCVDG
	je	fn34d
	cmp	al,SRCVBDG
	jne	fn34e
fn34d:
	inc	ssrdg
fn34e:
	add	di,type command
	loop	fn34b
	mov	dx,si
	mov	cl,[si].anums
	xor	ch,ch
	lea	si,[si].assns
	mov	di,offset sslist
fn34f:
	cmp	[si].slsn,0
	je	fn34h
	mov	al,sslnn
	cmp	al,0ffh
	je	fn34g
	mov	ax,lname
	cmp	ax,[si].slnptr
	jne	fn34h
fn34g:
	inc	ssnum
	call	sstat
fn34h:
	add	si,type session
	loop	fn34f
	mov	si,offset ssnstat
	sub	di,si
	mov	cx,di
	call	send
	mov	es:[bx].ncblen,cx
fn34x:
	les	bx,ncbptr
	call	post
	ret
fn34	endp

	subttl	sstat - fill out session status buffer for fn34
	page

; fill out session status information in buffer
; si -> session record
; di -> buffer to put status
; dx -> adapter record

sstat	proc	near
	push	es
	push	cx
	push	ds
	pop	es
	assume	es:nseg
	mov	al,[si].slsn
	mov	ah,al
	stosb
	mov	al,[si].sstate
	stosb
	push	si
	mov	si,[si].slnptr
	lea	si,[si].nstr
	mov	cx,16/2
	rep movsw
	pop	si
	push	si
	mov	si,[si].spnptr
	lea	si,[si].nstr
	mov	cx,16/2
	rep movsw
	mov	si,dx
	mov	cl,[si].anumc
	xor	ch,ch
	lea	si,[si].acmds
	xor	al,al
sstat1:
	cmp	[si].ccode,SRCV
	je	sstat2
	cmp	[si].ccode,SRCV OR 80H
	jne	sstat3
sstat2:
	cmp	ah,[si].clsn
	jne	sstat3
	inc	al
sstat3:
	add	si,type command
	loop	sstat1
	pop	si
	stosb
	xor	al,al		;never any sends outstanding
	stosb
	pop	cx
	pop	es
	assume	es:nothing
	ret
sstat	endp

	subttl	function 35h emulation - cancel command
	page

; cancel command
; cancels command at NCB_BUFFER@ ptr
; ADD NAME, ADD GROUP NAME, DELETE NAME, SEND DATAGRAM, SEND BROADCAST
;   DATAGRAM, SESSION STATUS, RESET, and CANCEL can't be canceled
; canceling a SEND or CHAIN send terminates the session
; input fields:
;   NCB_BUFFER@
;   NCB_LANA_NUM
; output_fields:
;   NCB_RETCODE
; errors include:
;   00H - good return
;   03H - invalid command (no-wait option is invalid)
;   23H - invalid NCB_LANA_NUM
;   24H - command completed while cancel occurring (NCB not found)
;   26H - command not valid to cancel

	assume	ds:nseg,es:nothing,ss:nothing
fn35	proc	near
	mov	al,03h
	test	es:[bx].ncbcmd,80h
	jnz	fn35x		;no-wait option isn't allowed
	mov	ax,word ptr es:[bx].ncbbuf
	mov	dx,word ptr es:[bx].ncbbuf+2
	mov	cl,[si].anumc
	xor	ch,ch
	lea	si,[si].acmds
	jcxz	fn35c
fn35a:
	cmp	[si].ccode,0
	je	fn35b
	cmp	ax,word ptr [si].cncb
	jne	fn35b
	cmp	dx,word ptr [si].cncb+2
	je	fn35d		;found command for the ncb to cancel
fn35b:
	add	si,type command
	loop	fn35a

; couldn't find command for ncb to cancel

fn35c:
	mov	al,24h		;command completed while cancel occurring
	jmp	fn35x
fn35d:
	mov	cl,[si].ccode	;command not valid to cancel
	and	cx,7fh
	cmp	cx,SLISTEN
	jne	fn35e
	push	si
	mov	di,si
	call	adpptr
	mov	al,[si].clsn
	mov	si,di
	call	findssn
	mov	[di].slsn,0
	pop	si
fn35e:
	mov	al,0bh
	call	postfar
	xor	al,al
fn35x:
	les	bx,ncbptr
	call	post
	ret
fn35	endp

	subttl	function 36h emulation - add group name (not unique)
	page

; add group (non-unique) name
; returns number of name in NCB_NUM for datagram and RECEIVE ANY
; input fields:
;   NCB_NAME
;   NCB_POST@
;   NCB_LANA_NUM
; output fields:
;   NCB_RETCODE
;   NCB_NUM
; errors include:
;   00H - good return
;   0DH - duplicate name in local table
;   0EH - name table is full
;   15H - name is invalid
;   16H - name in use on remote adapter
;   22H - too many commands outstanding
;   23H - invalid NCB_LANA_NUM

	assume	ds:nseg,es:nothing,ss:nothing
fn36	proc	near
	call	freecmd 	;is there room for this command
	jnz	fn36x		;22h
	call	freenm		;is there room for a name
	jnz	fn36x		;0eh
	mov	al,15h
	mov	ah,es:[bx].ncbnam
	or	ah,ah
	jz	fn36x		;15h - illegal name
	cmp	ah,'*'
	je	fn36x		;15h - illegal name
	lea	di,es:[bx].ncbnam	;es:di -> name to hash
	call	hashnm		;validate and hash name
	call	loclnm		;in the local table?
	jnz	fn36a
	mov	al,[di].nlnn	;return found name number
	mov	es:[bx].ncbnum,al
	mov	al,19h
	test	[di].nstate,02h
	jnz	fn36x		;19h - name conflict detected
	mov	al,0dh
	jmp	short fn36x	;0dh - duplicate name in local table
fn36a:
	mov	ax,nmhash
	lea	di,es:[bx].ncbnam
	call	findnm		;in any table?
	jnz	fn36b
	mov	al,16h
	test	[di].nstate,80h ;z if unique name on remote adapter
	jz	fn36x		;16h - name in use on remote adapter
fn36b:
	mov	di,nmloc
	mov	si,ladapt

; ds:di -> free slot in name table
; es:bx -> ncb
; ds:si -> adapter

	mov	[di].nnums,0
	mov	ax,nmhash
	mov	[di].nhash,ax
	mov	[di].nstate,84h ;group name and registered
	call	namenm
	mov	[di].nlnn,al	;local name number for this name
	mov	es:[bx].ncbnum,al ;and return number for this name
	push	es
	push	es		;xchg ds,es
	push	ds
	pop	es
	pop	ds
	lea	di,[di].nstr
	lea	si,es:[bx].ncbnam
	mov	cx,16/2
	rep movsw
	push	cs
	pop	ds
	pop	es
	xor	al,al
fn36x:
	les	bx,ncbptr
	call	post
	ret
fn36	endp

	subttl	function 70h emulation - unlink from remote boot
	page

; unlink
; at this point there's no reason to emulate this (so we simply allow it)
; see manual pages 2-35, 2-36
;jrb use bit 7 of command (no wait) to signal release of task and adapter
;jrb for remtask

	assume	ds:nseg,es:nothing,ss:nothing
fn70	proc	near
	mov	ax,es:[bx].ncblen ; tcb address to release
	mov	si,offset tasks
fn70b:
	cmp	si,nxttsk
	jnb	fn70x		;nb if task not found
	cmp	ax,[si].tTCB
	je	fn70c
	add	si,type task
	jmp	fn70b
fn70c:
	mov	[si].tTCB,-1	;releasing this task
	mov	si,[si].tadaptr
	mov	[si].acurn,0	;releasing this adapter
	mov	cl,[si].anums	;hang up any active sessions with other tasks
	xor	ch,ch
	lea	si,[si].assns
fn70d:
	cmp	[si].slsn,0
	je	fn70e		;session not active
	mov	di,[si].spartnr
	cmp	di,si
	je	fn70e		;no need to hangup on ourselves
	mov	al,18h		;session ended abnormally
	call	hangup		;hang up on partner
fn70e:
	add	si,type session
	loop	fn70d
fn70x:
	ret	
fn70	endp

	subttl	hangup - hang up on a session
	page

; terminate a session
; al = error code (session closed or session ended abnormally)
; ds:di -> session record
; delete commands relative to terminated session

hangup: push	di
	push	si
	push	cx
	push	bx
	mov	hup,al		;save hangup code
	push	di
	call	adpptr
	mov	si,di
	pop	di
	push	si
	mov	cl,[si].anumc	;first cancel all RECEIVE commands
	xor	ch,ch
	lea	si,[si].acmds
hup1:
	mov	al,[si].ccode
	and	al,7fh
	cmp	al,SRCV
	jne	hup3
	mov	al,[si].clsn
	cmp	al,[di].slsn
	jne	hup3
	mov	al,hup
	call	postfar 	;post and cancel the RECEIVE
hup3:
	add	si,type command
	loop	hup1
	pop	si
	mov	cl,[si].anumc	;cancel at most one receive any command
	xor	ch,ch
	xor	dx,dx		;save RECEIVE ANY for any name if found
	lea	si,[si].acmds
hup4:
	mov	al,[si].ccode
	and	al,7fh
	cmp	al,SRCVANY
	jne	hup6
	cmp	[si].cnum,0ffh
	jne	hup5
	mov	dx,si
	jmp	short hup6
hup5:
	mov	bx,[di].slnptr	;RECEIVE ANY for this session's name found
	mov	al,[si].cnum
	cmp	al,[bx].nlnn
	je	hup7
hup6:
	add	si,type command
	loop	hup4
	mov	si,dx
	or	si,si
	jz	hup8

; fix handling of rcvany any command complete on hangup
; MUST return LSN that was hungup to application

	mov	al,[di].slsn	; get lsn from session struc
	push	di		; save session ptr
	les	bx,[si].cncb	; get ptr to this cmds ncb
	mov	dx,[si].ctask	; get this ncb's task id
	cmp	dx,curtsk	; is it the same as ours?
	je	hup6a		; if so, not a far poke
	lea	di,[bx].ncblsn	; else far poke, use MOS to set ncblsn field
	call	MOSpoke
	jmp	short hup6b
hup6a:
	mov	es:[bx].ncblsn,al	; set local ncb with cancelled LSN
hup6b:
	pop	di		; restore session ptr
hup7:
	mov	al,hup		;post and cancel the single RECEIVE any
	call	postfar
hup8:
	mov	[di].slsn,0	;session is now deleted
	mov	si,[di].slnptr	;if local name is de-registered, see if it
	dec	[si].nnums	;  can now be deleted
	jnz	hup11

; Test to see if name IS de-registered and correctly delete it if so.

	test	[si].nstate,1	; if lo-bit set, name is de-registered
	jz	hup11		; if not de-registered, don't delete name
	mov	[si].nlnn,0	; no more sessions for name so delete it
hup11:
	pop	bx
	pop	cx
	pop	si
	pop	di
	ret

	subttl	freecmd - is there a slot for a command
	page

; ds:si -> adapter
; return z and di -> cmd slot if there is a free slot for a command
; else nz and al = 22h (too many commands outstanding)

freecmd proc	near
	push	cx
	lea	di,[si].acmds
	mov	cl,[si].anumc
	xor	ch,ch
	mov	al,ch
freec1:
	cmp	[di].ccode,0
	je	freec2
	add	di,type command
	loop	freec1
	mov	al,22h
freec2:
	mov	cmdloc,di
	or	al,al
	pop	cx
	ret
freecmd endp

	subttl	fresssn - is there a slot for a session
	page

; ds:si -> adapter
; return z and di -> session slot if a session is available
; else return nz and al = 11h (local session table full)

freessn proc	near
	push	cx
	lea	di,[si].assns
	mov	cl,[si].anums
	xor	ch,ch
	mov	al,ch
frees1:
	cmp	[di].slsn,0
	je	frees2
	add	di,type session
	loop	frees1
	mov	al,11h
frees2:
	mov	ssnloc,di
	or	al,al
	pop	cx
	ret
freessn endp

	subttl	findssn - find session record for session number
	page

; ds:si -> adapter
; al = session number
; return Z and ds:di -> session if found and active
; NZ and al = 08h (illegal session number)

findssn proc	near
	push	cx
	lea	di,[si].assns
	mov	cl,[si].anums
	xor	ch,ch
	mov	ah,08h
	or	al,al
	jz	finds2
	mov	ah,ch
finds1:
	cmp	[di].slsn,al
	je	finds2
	add	di,type session
	loop	finds1
	mov	ah,08h
finds2:
	mov	al,ah
	or	al,al
	pop	cx
	ret
findssn endp

	subttl	ssnnum - return next available session number
	page

; ds:si -> adapter
; return al = next available session number

ssnnum	proc	near
	push	di
	mov	al,[si].acurs
ssnnm1:
	push	ax
	call	findssn
	pop	ax
	jnz	ssnnm2		;session number not in use
	inc	al
	jmp	ssnnm1
ssnnm2:
	mov	ah,al
	inc	ah
	mov	[si].acurs,ah
	inc	ah
	jnz	ssnnm3
	mov	[si].acurs,1
ssnnm3:
	pop	di
	ret
ssnnum	endp

	subttl	adpptr - compute adapter pointer from name, session or cmd
	page

; di -> name, session or cmd pointer
; return di -> adpater

adpptr	proc	near
	push	dx
	push	cx
	push	ax
	mov	ax,di		;compute location of adapter from location of
	sub	ax,[adapts]	;jrb
	xor	dx,dx
	mov	cx,type adapter
	div	cx
	mul	cx
	add	ax,[adapts]	;jrb
	mov	di,ax
	pop	ax
	pop	cx
	pop	dx
	ret
adpptr	endp

	subttl	freenm - is there a slot for a name
	page

; ds:si -> adapter
; return z and di -> name slot if there is a free slot for a name
; else nz and al = 0eh (name table is full)

freenm	proc	near
	push	cx
	lea	di,[si].anames
	mov	cx,17
	mov	al,ch
freen1:
	cmp	[di].nlnn,0
	je	freen2
	add	di,type names
	loop	freen1
	mov	al,0eh
freen2:
	mov	nmloc,di
	or	al,al
	pop	cx
	ret
freenm	endp

	subttl	findnum - find name record for name number
	page

; ds:si -> adapter
; al = name number
; return Z and ds:di->name record if found
; else NZ and al = 13h illegal name number

findnum proc	near
	push	cx
	lea	di,[si].anames
	mov	cx,17
	mov	ah,13h
	or	al,al
	jz	fnum2
	mov	ah,0
fnum1:
	cmp	[di].nlnn,al
	je	fnum2
	add	di,type names
	loop	fnum1
	mov	ah,13h
fnum2:
	mov	al,ah
	or	al,al
	pop	cx
	ret
findnum endp
	subttl	namenm - return next available name number
	page
; ds:si -> adapter
; return al = next available name number
namenm	proc	near
	push	di
	mov	al,[si].acurn
namen1:
	push	ax
	call	findnum
	pop	ax
	jnz	namen2		;session number not in use
	inc	al
	jmp	namen1
namen2:
	mov	ah,al
	inc	ah
	mov	[si].acurn,ah
	inc	ah
	jnz	ssnnm3
	mov	[si].acurn,2
namen3:
	pop	di
	ret
namenm	endp

	subttl	hashnm - hash the name for use by loclnm and findnm
	page

; es:di -> name to hash
; return ax = hash code for name
; no other registers changed

hashnm	proc	near
	push	si
	push	cx
	push	bx
	mov	bx,-1
	mov	si,di
	mov	cx,16
hashn1:
	lods	byte ptr es:[si]
	rol	bx,1
	xor	bl,al
	loop	hashn1
	mov	ax,bx
	mov	nmhash,ax
	pop	bx
	pop	cx
	pop	si
	ret
hashnm	endp

	subttl	loclnm - is the name defined on the local card
	page

; ds:si -> adapter to search for name
; es:di -> name to look for
; ax = hash code for name
; return z and ds:di -> name
;   if found in ds:si adapter even if de-registered
; else nz

loclnm	proc	near
	push	cx  		; SAH must save and restore CX
	push	si
	lea	si,[si].anames
	mov	cx,17
locln1:
	cmp	[si].nlnn,0
	je	locln2
	cmp	[si].nhash,ax
	jne	locln2
	push	di
	push	si
	push	cx
	lea	si,[si].nstr
	mov	cx,16/2
	repe cmpsw
	pop	cx
	pop	si
	pop	di
	jne	locln2
	mov	di,si
	jmp	locln3
locln2:
	add	si,type names	;note is NZ
	loop	locln1
locln3:
	pop	si
	pop	cx		; SAH must restore CX
	ret
loclnm	endp

	subttl	findnm - find adapter card corresponding to a name
	page

; es:di -> name to look for
; ds:si & ladapt -> adapter to start with
; ax = hash code for name
; return z and ds:di -> name and ds:si -> adapter if found on any adapter
; else nz
; if found on more than one adapter, report names as "name conflict detected"
;   on all the adapters except the one returned here

findnm	proc	near
	mov	si,[adapts]	;[3] search table and only table
	mov	[srchst],di	;[3] remember search string
findn1:
	cmp	[si].acurn,0	;jrb
	je	findn2		;jrb
	call	loclnm
	jnz	findn2
	test	[di].nstate,03h
	jz	findn5		;z if it is not de-registered or in conflict
findn2:
	add	si,type adapter
	cmp	si,[nxtadp]	;jrb
	jb	findn1		;[4]
	or	si,si		;set NZ - none found on any adapter
	ret

; found at least one

findn5:
	push	di
	push	si		;remember where it was found
	mov	di,[srchst]	;[3] use proper search string
findn6:
	add	si,type adapter
	cmp	si,[nxtadp]	;jrb
	ja	findn9		;[3]
	cmp	[si].acurn,0	;jrb
	je	findn6		;jrb
	call	loclnm
	jnz	findn6
	test	[di].nstate,03h
	jnz	findn6		;de-registered or already in conflict
	call	conflct 	;report conflict
	jmp	findn6
findn9:
	pop	si		;restore first one found
	pop	di
	cmp	si,si		;set Z - found on at least one adapter
	ret
findnm	endp

	subttl	conflict - report and post name in conflict remotely
	page

; ds:di -> name in conflict
; ds:si -> adpater with name

conflct proc	near
	or	[di].nstate,02h
	push	si
	mov	cl,[si].anumc
	xor	ch,ch
	lea	si,[si].acmds
confl1:
	cmp	[si].ccode,0
	je	confl4
	mov	al,[si].ccode
	and	al,7fh
	cmp	al,SLISTEN
	jne	confl2

; listen command active

	mov	al,[si].clsn
	call	findssn
	mov	[di].slsn,0
	jmp	confl3
confl2:
	cmp	al,SRCVANY
	je	confl3
	cmp	al,SRCVDG
	je	confl3
	cmp	al,SRCVBDG
	jne	confl4

; receive broadcast datagram active

	mov	al,[di].nlnn
	cmp	al,[si].cnum
	jne	confl4
confl3:
	mov	al,19h		;19h - name conflict detected
	call	postfar
confl4:
	add	si,type command
	loop	confl1
	pop	si
	ret
conflct endp

	subttl	post/wait - post result to calling partition
	page

; post al = command result to ncb at es:bx for curtsk
; this is a post of the result of an immediate command, i.e. a command which
;   can be fully evaluated at the time the application calls

post	proc	near
	push	cx
	mov	es:[bx].ncbcplt,al
	mov	es:[bx].ncbret,al
	test	es:[bx].ncbcmd,80h
	jz	post1		;wait implies no post
	mov	cx,word ptr es:[bx].ncbpost
	or	cx,word ptr es:[bx].ncbpost+2
	jz	post1		;= 0 implies no post
	push	ds
	push	ax
	pushf
	call	es:[bx].ncbpost
	pop	ax
	pop	ds
post1:
	pop	cx
	ret
post	endp

; same as post, except it hangs up here until the command is complete
; if the no-wait command option was not chosen

waitfun proc	near
	les	bx,ncbptr
	xor	al,al
	test	es:[bx].ncbcmd,80h
	jnz	wait2		;no-wait just returns 0
wait1:
;jrb091591	call	MOSsusp 	;request MOS task switch
        call    tick            ;jrb091591
	cmp	es:[bx].ncbcplt,0ffh
	je	wait1		;until command complete field is set
	mov	al,es:[bx].ncbcplt
	call	post
wait2:
	ret
waitfun endp

	subttl	postfar - post a result to some other partition
	page

; ds:si -> command record to post

postfar proc	near
	push	es
	push	bx
	push	di
	push	si
	push	dx
	mov	dx,[si].ctask
	les	bx,[si].cncb
	cmp	dx,curtsk	; debugging!!!
	jne	pfar1
	call	post
	jmp	pfar3

; must actually go far

pfar1:
	lea	di,[bx].ncbcplt
	call	MOSpoke
	lea	di,[bx].ncbret
	call	MOSpoke
	test	[si].ccode,80h
	jz	pfar2		;wait implies no post
	mov	bx,word ptr [si].cpost
	or	bx,word ptr [si].cpost+2
;jrb121891	jz	pfar2		;= 0 implies no post
        jz      pfar3           ;jrb121891 no post, but not waiting either
	les	bx,[si].cncb
	lea	si,[si].cpost
	call	MOScall
	jmp	short pfar3
pfar2:
;jrb121891	mov	es,dx
;jrb121891	assume	es:tcb
;jrb121891	or	[tcbwait],2	; set wait resoved bit for waiting task
;jrb121891	assume	es:nothing
pfar3:
	pop	dx
	pop	si
	mov	[si].ccode,0
	pop	di
	pop	bx
	pop	es
	ret
postfar endp

	subttl	send - copy information to partition
	page

; send buffer at ds:si in curtsk of length cx bytes to
;   buffer specified by es:bx -> ncb in curtsk
; return al = 06h and cx = number sent, if receive buffer too small

send	proc	near
	push	dx
	xor	al,al
	cmp	cx,es:[bx].ncblen
	jbe	send1
	mov	al,06h
	mov	cx,es:[bx].ncblen
send1:
	mov	dx,cx
	push	es
	push	di
	les	di,es:[bx].ncbbuf
	rep movsb
	pop	di
	pop	es
	mov	cx,dx
	pop	dx
	ret
send	endp

	subttl	sendfar - copy information to remote partition
	page

; send buffer at ds:si in curtsk of length cx bytes to
;   buffer specified by es:di -> command record
; return al = 06h and cx = number sent, if receive buffer too small

	assume	ds:nothing,es:nseg
sendfar proc	near
	push	dx
	mov	dx,es:[di].ctask
	cmp	dx,curtsk
	jne	sendf1		; debugging!!!
	push	es
	push	bx
	les	bx,es:[di].cncb
	call	send
	pop	bx
	pop	es
	pop	dx
	ret
sendf1:
	xor	al,al
	cmp	cx,es:[di].clength
	jbe	sendf2
	mov	al,06h
	mov	cx,es:[di].clength
sendf2:
	push	es
	push	di
	les	di,es:[di].cbuffer
	call	MOSmove
	pop	di
	pop	es
	pop	dx
	ret
sendfar endp

	subttl	senddg - send a datagram message
	page

; send datagram
; di -> command record for receiver

	assume	ds:nseg,es:nothing
senddg	proc	near
	push	di		;jrb
	push	si		;jrb
	push	cx		;jrb
	les	bx,ncbptr
	lds	si,es:[bx].ncbbuf
	assume	ds:nothing
	mov	cx,es:[bx].ncblen
	push	cs
	pop	es
	call	sendfar
	push	cx
	push	cs
	pop	ds
	assume	ds:nseg

; set length received

	mov	si,di
	mov	ax,cx
	les	di,[si].cncb
	lea	di,[di].ncblen
	mov	dx,[si].ctask
	call	MOSpokw
	push	si

; set receiver's name number

	mov	al,[si].cnum
	les	di,[si].cncb
	lea	di,[di].ncbnum
	mov	dx,[si].ctask
	call	MOSpoke

; set sender's name

	les	bx,ncbptr
	mov	al,es:[bx].ncbnum	;jrb
	push	si			;jrb
	mov	si,[ladapt]		;jrb
	call	findnum
	pop	si			;jrb
	mov	dx,[si].ctask
	les	bx,[si].cncb
	lea	bx,[bx].ncbcnam
	lea	si,[di].nstr
	mov	di,bx
	mov	cx,16
	call	MOSmove
	pop	si
	les	bx,ncbptr
	pop	cx
	mov	al,00h		;good return
	cmp	cx,es:[bx].ncblen
	je	snddg1
	mov	al,06h		;receive buffer too small
snddg1:
	call	postfar
	pop	cx		;jrb
	pop	si		;jrb
	pop	di		;jrb
	ret
senddg	endp

	subttl	MOS?? - interface to MOS
	page

;jrb091591; request a task switch from MOS (current task is waiting for
;jrb091591; command completion)
;jrb091591
;jrb091591	assume	ds:nothing,es:nothing,ss:nothing
;jrb091591MOSsusp:
;jrb091591	push	es
;jrb091591	push	ds
;jrb091591	push	bp
;jrb091591	push	di
;jrb091591	push	si
;jrb091591	push	dx
;jrb091591	push	cx
;jrb091591	push	bx
;jrb091591	push	ax
;jrb091591	doMOSsusp
;jrb091591	pop	ax
;jrb091591	pop	bx
;jrb091591	pop	cx
;jrb091591	pop	dx
;jrb091591	pop	si
;jrb091591	pop	di
;jrb091591	pop	bp
;jrb091591	pop	ds
;jrb091591	pop	es
;jrb091591MOSs1:
;jrb091591	ret




;jrb091591 >>>>
; tick - MOS subroutine which allows task switch.
;        Saves all registers excluding flags.
;

; always return ready status to MOS
mospoll proc    far
        xor     ax,ax
        ret
mospoll endp


public tick
tick    proc    near
	push	es
	push	ds
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
        push    cs
        pop     es
        mov     bx,offset mospoll       ; use MOS poll routine
        mov     al,80h
	mos38	tskwait
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
	pop	es
        ret
tick    endp

;jrb091591<<<<


; call a subroutine in task DX at address dword ptr DS:[SI] (locally)
; ES:BX and AL must be transferred to subroutine as is
; subroutine will return via an IRET

MOScall:
	push	es
	push	ds
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	call	tswoff		;jrb091591 turn off t.s.
	doMOScall
	call	tswon		;jrb091591 turn off t.s.
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
	pop	es
	ret

; move a string of CX bytes from DS:SI (in current task)
;   to ES:DI in task DX

MOSmove:
	push	es
	push	ds
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	call	tswoff		; turn off t.s.
	doMOSmove		; transfer the data
	call	tswon		; turn on t.s.
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
	pop	es
	ret

; set the byte at ES:DI in task DX to AL

MOSpoke:
	push	ds
	push	si
	push	cx
	push	ax
	mov	si,sp
	push	ss
	pop	ds
	mov	cx,1
	call	tswoff		;jrb091591 turn off t.s.
	call	MOSmove
	call	tswon		;jrb091591 turn off t.s.
	pop	ax
	pop	cx
	pop	si
	pop	ds
	ret

; set the word at ES:DI in task DX to AX

MOSpokw: push	ds
	push	si
	push	cx
	push	ax
	mov	si,sp
	push	ss
	pop	ds
	mov	cx,2
	call	tswoff		;jrb091591 turn off t.s.
	call	MOSmove
	call	tswon		;jrb091591 turn off t.s.
	pop	ax
	pop	cx
	pop	si
	pop	ds
	ret
tswoff:
	push	es
	push	si
        push    ax
	les	si,cs:[scbptr]          ;jrb121891 cs override
	inc	es:[si+scbnoswt]	; now turn off task switching
        cli
        in      al,21h
        jmp short $+2
        jmp short $+2
        jmp short $+2
        or      al,01h          ; disable irq 0
        out     21h,al
        sti
        pop     ax
	pop	si
	pop	es
	ret
tswon:
	push	es
	push	si
        push    ax
	les	si,cs:[scbptr]          ;jrb121891 cs override
	dec	es:[si+scbnoswt]	; now turn on task switching
        cli
        in      al,21h
        jmp short $+2
        jmp short $+2
        jmp short $+2
        and     al,not 01h      ; re-enable irq 0
        out     21h,al
        sti
        pop     ax
	pop	si
	pop	es
	ret

	subttl	int 2fh - pc network program interrupt
	page

	assume  ds:nothing,es:nothing,ss:nothing

old2fh	dd	?

int2fh:
	sti
	cld
	cmp	ax,0b700h
	je	int2fa
	cmp	ax,0b800h
	je	int2fb
	cmp	ax,0b803h
	je	int2fc
	cmp	ax,0b804h
	jne	int2fe

; set new post address (note it never gets called in the current emulation)

	push	ds
	push	si
	call	taskrec
	mov	word ptr [si].tpost,bx
	mov	word ptr [si].tpost+2,es
	pop	si
	pop	ds
	jmp	short int2fd

; append installation check

int2fa:
	xor	al,al		;append not installed
	jmp	short int2fd

; PC network program installation check

int2fb:
	mov	al,0ffh 	;PC network program installed
	mov	bx,00cch	;server, messenger, receiver and redirector
	jmp	short int2fd	;  are all installed

; return current post address

int2fc:
	push	ds
	push	si
	call	taskrec
	mov	bx,word ptr [si].tpost
	mov	es,word ptr [si].tpost+2
	pop	si
	pop	ds
int2fd:
	iret
int2fe:
	cli
	jmp	old2fh

nullpost equ	int2fd		;default post address

	subttl	int 2ah - pc network program interrupt
	page

old2ah	dd	?

int2ah:
	sti
	cld
	cmp	ah,00h
	je	int2aa
	cmp	ax,0300h
	je	int2ab
	cmp	ah,04h
	je	int2ac
	cmp	ax,0500h
	jne	int2ae

; get network resource information

	push	ax
	call	netrsr
	pop	ax
	jmp	short int2ad

; installation check

int2aa:
	mov	ah,0ffh 	;2ah is installed
	jmp	short int2ad

; check direct i/o

int2ab:
	push	bp		;clear carry - direct i/o is allowed
	mov	bp,sp
	and	byte ptr [bp+6],not 01h ;bp, ip, cs, flags
	pop	bp
	jmp	short int2ad

; execute NETBIOS

int2ac:
	or	al,al
	jz	i2aca		; zero means w/ error retry
	cmp	al,1		; one means w/o
	jne	int2ae

; execute with error retry - SJC - without!

	int	5ch
	mov	ah,0
	or	al,al
	jz	int2ad
	mov	ah,1
	iret

; execute with no error retry - SJC - with!

i2aca:
	mov	cx,[retrys]	; # of times to retry (internally set)
i2aclp:
	int	5ch
	mov	ah,0
	or	al,al
	jz	int2ad
	cmp	al,9		; only certain errors get retried (9,12h,21h)
	jz	i2acnxt
	cmp	al,12h
	jz	i2acnxt
	cmp	al,21h
	jnz	i2acerr
i2acnxt:
	loop	i2aclp
i2acerr:
	mov	ah,1
int2ad:
	iret
int2ae:
	cli
	jmp	old2ah

	subttl	int21h - int 21 netbios functions
	page

old21h	dd	?

int21h:
	sti
	pushf			; save original int21 call flags
	cld
	cmp	ax,5e00h	; handle machine name call
	je	int21a

; pass-on all other calls

	cmp	ah,5eh
	jb	i21noto
	cmp	ah,60h
	jbe	i21ours
i21noto:
	assume	ds:nothing
	popf			; retrieve original flags
	jmp	[old21h]	; passon the call to int 21h, no interception
i21ours:
	assume	ds:nothing
	call	[old21h]	; handle call by passing on, then ck if error
	jnc	int21ex 	; if so, ck for not loaded, chg to end of list

; setup stack to access and modify flags

	push	bp
	mov	bp,sp		; typo here, was mov sp,bp
	pushf
	pop	[bp+6]		; save full flags reg (save state of int 21h)
	pop	bp
	cmp	ax,1
	jne	i21prt		; if not loaded, chg to end of list
	mov	ax,18		; change error code to most desirable
i21prt:
	iret

; call is Get Machine Name
; ds:dx -> 16 byte buffer
; return first name encountered in local name table which is terminated by
;   00H and has no other characters = 00H and is padded with spaces
; ch = 0 => no name found
; else cl = name number

int21a: popf
	push	es
	push	ds
	push	di
	push	si
	push	ds
	pop	es
	cld
	call	taskrec 	;get -> to task record for this task
	mov	si,[si].tadaptr
	mov	cx,16
	lea	si,[si+type names].anames
	xor	al,al
int21b:
	mov	ah,cl		;(remember count)
	cmp	al,[si].nlnn	;name number = 0 => undefined
	je	int21e
	cmp	al,[si].nstr+15
	jne	int21e		;last byte of name <> 00H
	lea	di,[si].nstr	;else make sure all chars > ' ', then padded
	mov	cl,15		;  with ' '
int21c:
	mov	al,[di]
	cmp	al,' '
	jbe	int21d
	inc	di
	loop	int21c
	jmp	int21f
int21d:
	cmp	byte ptr [di],' '
	jne	int21e
	inc	di
	loop	int21d
	jmp	int21f
int21e:
	add	si,type names
	mov	cl,ah
	loop	int21b
	jmp	int21x		;no machine name defined
int21f:
	mov	al,[si].nlnn
	lea	si,[si].nstr
	mov	cx,16
	mov	di,dx
	rep	movsb
	mov	cl,al
	mov	ch,0ffh
int21x:
	pop	si
	pop	di
	pop	ds
	pop	es
int21ex:
	push	bp		;clear carry 'cause no error
	mov	bp,sp
	and	byte ptr [bp+6],not 01h ;bp, ip, cs, f
	pop	bp
	iret

	subttl	netrsr - int 2a function 0500
	page

; return bx = number of names available
;	 dx = number of sessions available
;	 cx = number of commands available

netrsr:
	push	ds
	push	si
	call	taskrec
	mov	si,[si].tadaptr
	push	si			;count number of names available
	mov	cx,16
	xor	ax,ax
	lea	si,[si+type names].anames
netr1:
	cmp	[si].nlnn,0
	jne	netr2
	inc	ax
netr2:
	add	si,type names
	loop	netr1
	mov	bx,ax
	pop	si
	push	si			;count number of sessions available
	mov	cl,[si].anums
	xor	ch,ch
	xor	ax,ax
	lea	si,[si].assns
netr3:
	cmp	[si].slsn,0
	jne	netr4
	inc	ax
netr4:
	add	si,type session
	loop	netr3
	mov	dx,ax
	pop	si			;count number of commands available
	mov	cl,[si].anumc
	xor	ch,ch
	xor	ax,ax
	lea	si,[si].acmds
netr5:
	cmp	[si].ccode,0
	jne	netr6
	inc	ax
netr6:
	add	si,type command
	loop	netr5
	mov	cx,ax
	pop	si
	pop	ds
	ret

	subttl	taskrec - return -> to task record for current task
	page

invncb	db	7fh,63 dup(0)		; an invalid command ncb

; return ds:si -> task record for current task
; send netbios an invalid ncb to make sure a task record gets allocated
; it returns ah = task record number

taskrec:push	es
	push	di
	push	cx
	push	bx
	push	ax
	push	bp

; Request NCB space from MOS

	mov	bp,sp		; save stack pointer
	mov	bx,128/16	; paragraphs we want
	mos	alloc
	jnc	tskr10		; if we got it OK
	sub	sp,128		; if we didn't get from MOS, get from stack
	push	ss
	pop	es
	mov	di,sp		; es:di points to NCB space
	jmp	short tskr20	; carry on
tskr10:
	mov	es,ax
	xor	di,di		; es:di points to NCB space
tskr20:
	mov	bx,di		; save pointer to NCB
	mov	cx,64/2
	xor	ax,ax
	rep stosw
	mov	byte ptr es:[bx].ncbcmd,7eh
	push	es
	push	bp
	int	5ch
	pop	bp
	pop	es
	mov	al,ah		;compute task record location from ah
	mov	ah,type task
	mul	ah
	add	ax,offset tasks
	mov	si,ax
	push	cs
	pop	ds
	cmp	bp,sp		; is sp same as bp?
	je	tskr30		; if same, return memory to MOS
	mov	sp,bp		; restore old stack pointer
	jmp	short tskr40	; exit
tskr30:
	mos	free		; return memory block (if allocated)
tskr40:
	pop	bp
	pop	ax
	pop	bx
	pop	cx
	pop	di
	pop	es
	ret

	subttl	initialization code and data
	page

;	Strategy and interrupt routines for device driver

netstrat proc far
	assume	cs:nseg,ds:nothing,es:nothing,ss:nothing
	mov	word ptr [reqhdr],bx	; pointer to request header
	mov	word ptr [reqhdr+2],es
	ret
netstrat endp

netint proc far
	push	es
	push	bx
	les	bx,[reqhdr]	; request header pointer from interrupt
	cmp	es:[bx].drqcom,0 ; an initialization request?
	jne	neti10		; if anything else, an error
	call	net		; call initialization routine
	jmp	short neti20	; leave
neti10:
	mov	es:[bx].drqsta,8103h	; return "error, done, bad command"
neti20:
	pop	bx
	pop	es
	ret
netint endp

tasks	equ	this byte	;jrb

	even
	dw	192 dup(0)
stk	label	word
llidstr db	'LLNETBIO'
llidlen equ	$-llidstr
okmsg	db	0dh,0ah,'NETBIOS installed for   ' ;@@XLAT
oknum	db	'00 partition' ;@@XLAT
okplurl db	's',0dh,0ah,'$'
MOSmsg	db	0dh,0ah,'NETBIOS may only be installed under PC-MOS      ' ;@@XLAT
	db	0dh,0ah,'$'
nmsg	db	0dh,0ah,'NETBIOS already installed  ',0dh,0ah,'$' ;@@XLAT

net	proc near
	push	ax
	push	cx
	push	dx
	push	si
	push	di
	push	ds
	push	cs
	pop	ds
	assume	ds:nseg, es:nothing

; make sure we're under MOS & get the SCB

	xor	bx,bx
	mov	es,bx		; set es and bx to 0 for later test
	mov	ah,getscb	; get the SCB segment
	INT	SERVICES	; call it directly here
	jc	net0		; if error return
	mov	ax,es
	or	ax,bx
	jnz	net1		; if SCB pointer returned is not 0
net0:
	mov	dx,offset MOSmsg ;'NETBIOS must be run under MOS'
	mos	dspstr
net0a:
	les	bx,[reqhdr]
	mov	es:[bx].drqsta,810Ch	; error, done, general failure
	xor	ax,ax
	mov	word ptr es:[bx].drqres,ax	; end of resident code is cs:0
	mov	word ptr es:[bx+2].drqres,cs
	mov	es:[bx].drqunits,al	; no units defined
	jmp	net11		; exit driver
net1:
	mov	word ptr [scbptr],bx
	mov	word ptr [scbptr+2],es	; store SCB pointer
	xor	ax,ax
	mov	es,ax		; get zero seg addressable
	mov	ax,word ptr es:[SERVICES*4]
	mov	[far38],ax
	mov	ax,word ptr es:[SERVICES*4+2]
	mov	[far38+2],ax			; save the vector properly!

; make sure NETBIOS isn't already installed

	xor	ax,ax
	mov	es,ax
	lds	si,dword ptr es:[2ah*4]
	assume	ds:nothing
	mov	word ptr [old2ah],si
	mov	word ptr [old2ah+2],ds
	lds	si,dword ptr es:[2fh*4]
	mov	word ptr [old2fh],si
	mov	word ptr [old2fh+2],ds
	lds	si,dword ptr es:[21h*4]
	mov	word ptr old21h,si
	mov	word ptr old21h+2,ds
	lds	si,dword ptr es:[5ch*4]
	mov	word ptr old5ch,si
	mov	word ptr old5ch+2,ds
	push	cs
	pop	es
	assume	es:nseg
	lea	si,[si-idlen]
	lea	di,idstr
	mov	cx,idlen
	repe cmpsb
	push	cs
	pop	ds
	assume	ds:nseg
	jne	net2
	mov	dx,offset nmsg	;'NETBIOS already installed  '
	mos	dspstr
	jmp	net0a		; exit driver
net2:
	lds	si,old5ch	;figure out whether to save old 5ch
	assume	ds:nothing
	lea	si,[si-llidlen]
	lea	di,llidstr
	mov	cx,llidlen
	repe cmpsb
	je	net3
	mov	word ptr old5ch,0	;forget it if not LanLink ID string
	mov	word ptr old5ch+2,0
net3:
	push	cs
	pop	ds
	assume	ds:nseg
	mov	nxttsk,offset tasks
	xor	ax,ax
	mov	es,ax
	assume	es:nothing
	cli
	mov	word ptr es:[5ch*4],offset int5ch
	mov	word ptr es:[5ch*4+2],cs
	mov	word ptr es:[2ah*4],offset int2ah
	mov	word ptr es:[2ah*4+2],cs
	mov	word ptr es:[2fh*4],offset int2fh
	mov	word ptr es:[2fh*4+2],cs
	mov	word ptr es:[21h*4],offset int21h
	mov	word ptr es:[21h*4+2],cs
	sti
	les	si,[reqhdr]	; get driver request header
	les	si,es:[si].drqcmdln	; get command line pointer

; Skip through command line to first equal sign.

net4:
	mov	al,es:[si]	;jsm next byte
	cmp	al,'='		;jsm look for first equal sign
	jne	net4a		;jsm
	inc	si		;jsm start conversion with byte after =
	jmp	short net5	;jsm
net4a:				;jsm
	cmp	al,0dh		;jsm or CR
	je	net5a		;jsm
	cmp	al,0ah		;jsm or LF
	je	net5a		;jsm
	inc	si		;jsm
	jmp	net4		;jsm next character

; es:si points to first equal sign or end of line.

net5:
	call	getnum		;b0
	jnc	net6		;b0
net5a:				;jrb
	lea	si,nadapt	;b0 - else use nadapt default
	push	cs
	pop	es
	call	getnum		;b0
	mov	ah,9		;b0
	jc	net7		;b0
net6:				;b0
	mov	ah,1		;b0 - must be from 1 to 17
	or	al,al		;b0
	jz	net7		;b0
	mov	ah,25		;b0
	cmp	al,25		;b0
	ja	net7		;b0
	mov	ah,al		;b0
net7:				;b0
	mov	al,ah		;b0
	cbw			;b0
	push	ax		;b0 - prepare it for display
	lea	di,oknum	;b0
	call	putnum		;b0
	pop	ax		;b0
	cmp	ax,1		;b0 - display 's' if more than 1
	jne	net8		;b0
	mov	okplurl,0dh	;b0	else redundant carriage-return
net8:
	mov	bx,ax
	mov	cx,type task	;jrb
	mul	cx		;jrb
	add	ax,offset tasks ;jrb
	mov	[adapts],ax	;jrb
	mov	[nxtadp],ax	;jrb
	mov	ax,bx		;jrb
	mov	cx,type adapter
	mul	cx
	mov	dx,[adapts]	;jrb
	mov	si,dx
	add	dx,ax
	mov	endadp,dx
	push	dx
	mov	dx,offset okmsg ;'NETBIOS installed'
	mos	dspstr
	mov	dx,offset netmsg	; Copyright and version number msg
	mos	dspstr
	pop	dx
	les	bx,[reqhdr]	; get driver request structure back

; Store size of code.

	mov	word ptr es:[bx].drqendres,dx
	mov	word ptr es:[bx+2].drqendres,cs
	mov	es:[bx].drqunits,1	; one unit (is this necessary?)
	mov	word ptr es:[bx].drqsta,0100h	; "OK, done"
net11:
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret
net	endp

; get number from 0-99 from es:si->ASCII buffer
; any number of spaces tabs preceding or following, one or two digits,
;   terminated by carriage-return

getnum:
	mov	al,es:[si]
	inc	si
	cmp	al,' '
	je	getnum
	cmp	al,09h
	je	getnum
	sub	al,'0'
	jb	getnm2
	cmp	al,9
	ja	getnm2
	mov	bl,al
	mov	al,es:[si]
	inc	si
	cmp	al,0dh
	je	getnm3
	cmp	al,0ah
	je	getnm3
	sub	al,'0'
	jb	getnm1
	cmp	al,9
	ja	getnm2
	mov	bh,bl
	add	bl,bl
	add	bl,bl
	add	bl,bh
	add	bl,bl
	add	bl,al
getnm1:
	mov	al,es:[si]
	inc	si
	cmp	al,0dh
	je	getnm3
	cmp	al,0ah
	je	getnm3
	cmp	al,' '
	je	getnm1
	cmp	al,09h
	je	getnm1
getnm2:
	stc
getnm3:
	mov	al,bl
	ret

; put number from 0 - 99 into ds:di->ASCII buffer

putnum:
	cbw
	mov	bl,10
	div	bl
	or	al,al
	jnz	putnm1
	mov	al,' '-'0'
putnm1:
	add	al,'0'
	add	ah,'0'
	mov	[di],ax
	ret
nseg	ends
	end	nethdr
