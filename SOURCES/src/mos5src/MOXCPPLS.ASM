	include	page.inc
	title	MOXCPPLS  -  MOS Command Processor Additional Internal Commands
comment ^==============================================================

SAH 07/11/87	Converted 80+ int 21 to int 38 00+

SAH 07/22/87	Fix bugs with TEXT and EXCEPT/ONLY

SAH 07/27/87	Signon fix - simple and fast

JSM 08/03/87	Signon fix - close $$USER.SYS on all paths
		out of the signon routine.

SAH 08/06/87	Function 87 in signon change to INT 38

SAH 08/18/87	Corrected bug with key by not-allowing Ctrl-C
		Ctrl-Break out the KEY command.  Simply use
		use function 7 instead of function 8

SAH 08/27/87	Provide support for SP (space) and CR
		(carriage return) keys in the KEY command

SAH 10/19/87	added SWITCH command

SAH 11/24/87	Did not allow switch command if PAM switching is off

SAH 05/12/88	Change INT 38 calls to simulate calls

SAH 08/31/88	Corrected switching to same task. Cleanup

RDG 10/21/88	Modified the signon command to require a
		carriage return before asking for user id and
	        password.  Also set SonPuser so that entry of
		a carriage return only was not treated as an
		an invalid entry.
		Removed the INCLUDE MOSTCB.INC so as to decrease
		the symbol table requirements for MASM 2.0 and
		replaced it with explicit TCB definitions.

mjs 06/21/89	Added code to manage the $compat$ environment variable.

SAH 06/28/89	Corrections for SIGNON USER and clearing screen

SAH 08/15/89	Corrections for signon which make it turn on ansi
		support temporary. Must be modified if ansi support is
		ever going to me move to a seperated driver.

BWR 11/29/89	Marked messages for foreign language translation.

SAH 12/20/89	Made so user could not break out of signon, made sure
		that we restore ansi mode propertly.

SAH 05/01/90	Corrections so that Signon does not lockup if class is
		set in addtask line.  Also revampe signoff for better
		security.

BWR 2/19/91	Prepared command tables for foreign language
		translation. (Russian)

mjs 04/24/91	made signon save and restore tcbclass.  made signoff
		test tcbclass and automatically invoke signon when
		a lockout would otherwise occur.

================ 5.01 kernel ends here ====================================

mjs 08/12/92	modifed getsetclass to use the new id4f31 function 
		to read and set tcbcdft.  this is so llpro can hook 
		the function and manage copy/c across the network.
		set version 5.04 in moxcpcor.
		patched into release 5.01 by updat501.sys version 1.08.

======================================================================^

INCLUDE MOXCPDAT.INC		;data declarations

CMD	GROUP	CODESEG

if      0 eq 0			;       fake public.com out
NEWSCB	SEGMENT AT 0
	assume	cs:newscb
.xlist
INCLUDE MOSSCBDF.INC
.list
	assume	cs:nothing
NEWSCB	ENDS

TCB SEGMENT AT 0
                                                                       	
	org	00008h                                                  
TCBTCBPN DW	?	 ;* POINTER TO NEXT TCB                         
                                                                        
	org	00010h                                                  
TCBID	 DW	?	;* TASK ID (Task0 = 0, Task1 = 1, ETC.)         
                                                                        
	org	00035h                                                  
TCBPAGE  DB	?	; Current video page                            
TCBCOLS  DB	?	; Number of text columns per screen             
                                                                        
	org	0003eh                                                  
TCBCPOS  DW	8 DUP(?) ; Cursor positions for the 4 screen pages      
                                                                        
	org	0007ah                                                  
TCBCLASS DB	?		    ; CLASS FOR THIS TASK               
TCBUSER  DB	4 DUP(?)	    ; 4-BYTE USER ID FOR THIS TASK      
TCBCDFT  DB	?		    ; DEFAULT FILE CREATE CLASS FOR THIS
TCBCMAP  DB    (26*2+7)/8 DUP(?)    ; CLASS PERMISSION MAP FOR THIS TASK
                                                                        
; TWO BITS PER CLASS ('A'-'Z')                                          
; VALUE 		PARTITION		DIR/FILE                
; 0 - ACCESS DENIED	NO ACCESS		NO ACCESS               
; 1 - EXECUTE ONLY	VIEW ONLY		EXECUTE ONLY            
; 2 - READ		ABOVE			ABOVE+READ              
; 3 - WRITE		ABOVE+SUPPLY KEYS	ABOVE+WRITE+CREATE+DEL+R

	org	2d4h
TCBOCLASS	db	?		; original class
                                                                        
	org	00590h                                                  
TCB%RS0A dw	?		; root size for 0a                      
                                                                        
	org	00596h                                                  
TCB%RS3F dw	?		; root size for 3f                      
                                                                        
	org	005b4h                                                  
TCB%INSF db	?		; insert flag 0ffh = insert mode active 
                                                                        
	org	007e2h                                                  
TCBPAM	  DB	?  		; flag to indicate if paming is ok or no
                                                                        
	org	007e7h                                                  
TCBSWFLG  DB	?  		; Switch flag for getkeys               
TCBSWITCH DB	?  		; Switch value for GetKeys              
									
	org	00801h
TCBANSI db	?		; ansi.sys emulation flag non-zero = on

TCB     ENDS                                                            

endif

CODESEG SEGMENT

	ASSUME	CS:CMD,DS:DATASEG,ES:DATASEG


INCLUDE MOXCPPLS.PUB		;	public defs

INCLUDE MOXCPSXT.INC		;	external declarations for MOXCPSUB

extrn cmfl:near, cmf1:near, issueprompt:near, baterr:near, 
extrn bateof:near, batresume:near, echostr:byte, processlbuf:near, 
extrn bater1:near, closebat:near, openbat:near, batresume:near, 
extrn brkstr:byte, onstr:byte, offstr:byte, pthstrg:byte, 
extrn prmstrg:byte, verstr:byte, dotstr:byte, ecl1:near, 
extrn ecl2:near, ecl3:near, badparm1:near, badparm2:near, 
extrn badparm3:near, badparm4:near, badparm5:near, badparm6:near, 
extrn badparm7:near, badparm:near, gtplus1:near

;--------------------------- START OF CODE -------------------------;

PlsStart:


PlusTbl:
	db	'STOP    '              ;@@XLAT
	dw	OFFSET cmd:Cstop
	db	0			; don't set/clear errlvl

	db	'ABORT   '              ;@@XLAT
	dw	OFFSET cmd:CAbort
	db	0			; don't set/clear errlvl

	db	'CALL    '              ;@@XLAT
	dw	OFFSET cmd:CCall
	db	0			; don't set/clear errlvl

	db	'RETURN  '              ;@@XLAT
	dw	OFFSET cmd:CReturn
	db	0			; don't set/clear errlvl

	db	'TEXT    '              ;@@XLAT
	dw	OFFSET cmd:CText
	db	0			; don't set/clear errlvl

	db	'BATECHO '              ;@@XLAT
	dw	OFFSET cmd:CBatEcho
	db	0			; don't set/clear errlvl

	db	'EXCEPT  '              ;@@XLAT
	dw	OFFSET cmd:CExcept
	db	0			; don't set/clear errlvl

	db	'ONLY    '              ;@@XLAT
	dw	OFFSET cmd:COnly
	db	0			; don't set/clear errlvl

	db	'KEY     '              ;@@XLAT
	dw	OFFSET cmd:CKey
	db	0			; don't set/clear errlvl

	db	'AUTOCD  '              ;@@XLAT
	dw	OFFSET cmd:CAutocd
	db	0			; don't set/clear errlvl

	db	'REL     '              ;@@XLAT
	dw	OFFSET cmd:Crel
	db	0			; don't set/clear errlvl

      	db	'VER     '              ;
	dw	OFFSET cmd:Crel
	db	0			; don't set/clear errlvl

	db	'NEXT    '              ;@@XLAT
	dw	OFFSET cmd:Cnext
	db	0			; don't set/clear errlvl

	db	'INSERT  '              ;@@XLAT
	dw	OFFSET cmd:Cinsert
	db	0			; don't set/clear errlvl

	db	'FLUSH   '              ;@@XLAT
	dw	OFFSET cmd:Cflush
	db	0			; don't set/clear errlvl

	db	'WVER    '              ;@@XLAT
	dw	OFFSET cmd:Cverify	
	db	0			; don't set/clear errlvl

	db	'BREAK   '              ;@@XLAT
	dw	OFFSET cmd:Cbreak
	db	0			; don't set/clear errlvl

	db	'DOT     '              ;@@XLAT
	dw	OFFSET cmd:Cdot
	db	0			; don't set/clear errlvl

	db	'SIGNOFF '              ;@@XLAT
	dw	OFFSET cmd:Csignoff
	db	0			; don't set/clear errlvl

	db	'SIGNON  '              ;@@XLAT
	dw	OFFSET cmd:Csignon
	db	0			; don't set/clear errlvl

	db	'SWITCH  '              ;@@XLAT
	dw	OFFSET cmd:Cswitch
	db	0			; don't set/clear errlvl

	dw	0		; end of table marker

;-----------------------------------------------------------------------;
;				NEXT					;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG
Cnext:
	True?	[Batch] 	; ignore if not in a batch file
	Ljne	CMFL
	call	FixBatParms	; restore the	BatParms string to asciiz
	lea	si,[BatParms]
	call	PassDelims
	mov	dx,si		; save start of first parm
	call	FindDelim
	sub	si,dx		; calc the length of the first parm
	mov	cx,si
	mov	al,' '
	cld
	mov	di,dx
	rep	stosb		; blank out	the	first parm
	call	UpdBatTbl	; update the BatTabl on the new string
	jmp CMFL

;-----------------------------------------------------------------------;
;				REL					;
;-----------------------------------------------------------------------;
	
	ASSUME	DS:DATASEG,ES:DATASEG

Crel: 
	call	DispEOL
	call	DispVer
	call	DispEOL
	jmp CMFL

;-----------------------------------------------------------------------;
;				 STOP					;
;-----------------------------------------------------------------------;

Cstop:
	jmp	BatEof

;-----------------------------------------------------------------------;
;				 ABORT					;
;-----------------------------------------------------------------------;

CAbort: 
	jmp	BatErr

;-----------------------------------------------------------------------;
;				 CALL					;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

CCall:
	True?	[Batch]
	Ljne	CMFL		; ignore if	not	in a batch file
	True?	[NullParm]
	Lje	Cll1
	mov	bx,1		; block size
	MOS	GetMem
	call	MemCheck
	jc	Cll2
	mov	es,ax
	mov	ax,ds:[BatEnd]
	mov	bx,0
	mov	es:[bx],ax	; save BatEnd as the back link
	mov	ax,es
	mov	ds:[BatEnd],ax	; update BatEnd
	add	bx,2
	mov	BYTE PTR es:[bx],1	  ; save descriptor for .call command
	inc	bx
	mov	ax,WORD PTR ds:[BatLine]  ; save BatLine
	mov	WORD PTR es:[bx],ax
	mov	ax,WORD PTR ds:[BatLine+2]
	add	bx,2
	mov	WORD PTR es:[bx],ax
	push	ds
	pop	es
	jmp	GtPlus1 	;	in the GOTO command's logic
Cll1:
	mov	al,213		; label not found
	call	ReportError
	jmp	BatErr
Cll2:
	mov	al,8		; insufficient memory
	call	ReportError
	jmp	BatErr

;-----------------------------------------------------------------------;
;				 RETURN 				;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

CReturn:
	True?	[Batch]
	Ljne	CMFL		; ignore if	not	in a batch file
	cmp	BYTE PTR [ForScnt],0  ; ignore if in a FOR	command
	Ljne	CMF1
	mov	ax,[ForStkE]	; ignore if the FOR stack is not empty
	cmp	ax,[BatForSe]
	Ljne	CMF1
	mov	ax,[BatEnd]
	or	ax,ax
	jz	Crtn1
	mov	es,ax
	mov	bx,2		; offset of descriptor
	mov	al,es:[bx]
	cmp	al,1
	jne	Crtn1
	xor	bx,bx
	mov	ax,es:[bx]	; get BatEnd
	mov	ds:[BatEnd],ax
	add	bx,3
	mov	ax,es:[bx]	; get BatLine
	mov	WORD PTR ds:[BatLine],ax
	add	bx,2
	mov	ax,es:[bx]
	mov	WORD PTR ds:[BatLine+2],ax
	MOS	FreeMem
	call	MemCheck
	push	ds
	pop	es
	ResFlg	[BatEFlg]
	jmp	BatResume
Crtn1:
	mov	al,219		; Return without Call
	call	ReportError
	push	ds
	pop	es
	jmp	BatErr

;-----------------------------------------------------------------------;
;				 TEXT					;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

Ctx4	proc
	cmp	al,'0'		; return binary number in al's lower nibble
	jb	Ctx4a		; for '0'-'9' and 'A'-'F'
	cmp	al,'9'
	jna	Ctx4b
	call	Low2Upper
	cmp	al,'A'
	jb	Ctx4a
	cmp	al,'F'
	ja	Ctx4a
	sub	al,55
	ret
Ctx4b:
	sub	al,'0'
	ret
Ctx4a:
	xor	al,al
	ret
Ctx4	endp

Ctx27	proc		; blank out the option and get the next two chars
	mov	WORD PTR [si-2],2020h  ; blank out the option 
	lodsb
	or	al,al		; get background digit
	Ljz	BADPARM2
	mov	ah,al
	mov	byte ptr [si-1],20h
	lodsb			; get foreground digit
	or	al,al
	Ljz	BADPARM2	
	mov	byte ptr [si-1],20h
	xchg	ah,al		; 1st in al, 2nd in ah
	ret
Ctx27	endp

Ctx28	proc
	cmp	al,'0'
	Ljb	BADPARM2
	cmp	al,'9'
	jna	Ctx20
	call	Low2Upper
	cmp	al,'A'
	Ljb	BADPARM2
	cmp	al,'F'
	Lja	BADPARM2
	sub	al,55
	jmp	Ctx21
Ctx20:
	sub	al,'0'
Ctx21:
	ret
Ctx28	endp

Ctx23	proc		
	call	Ctx27		; get the letter pair in ax
	call	Ctx28		; convert al to binary
	mov	cl,4
	shl	al,cl
	xchg	ah,al
	call	Ctx28
	or	al,ah
	ret
Ctx23	endp

Ctx29	proc			; mul al by 10, but preserve ah
	push	cx	
	mov	cl,10
	mov	ch,ah
	mul	cl
	mov	ah,ch
	pop	cx
	ret
Ctx29	endp
	
	
EndTxtSt db	'.ENDTEXT'

CText:
	True?	[Batch]
	Ljne	CMFL		; ignore if	not	in a batch file
	mov	[tabcnt],0
	mov	ah,0fh
	int	10h
	mov	bl,[bkattr]
	mov	bp,bx		; set page and default attr
	True?	[NullParm]
	Lje	Ctx16a
	lea	si,[ParmBuf]
Ctx24:
	xor	cx,cx		; check for /s, /c and /p options	
	mov	al,Fslash
	call	ScanStr
	Ljne	Ctx16a		; no options found, final pass
	inc	si
	cld
	lodsb
	call	Low2Upper
	cmp	al,'S'		; is it a /s ?
	lje	Ctx25
	cmp	al,'C'
	Lje	Ctx26
	cmp	al,'K'
	Lje	Ctx30
	cmp	al,'P'
	Ljne	Ctxbad2

	; deal with the /p case

	call	Ctx27		; get the first two chars after the /p
	mov	bx,ax
	lodsb
	or	al,al		; get third digit
	Ljz	Ctxbad2
	mov	ah,al
	mov	byte ptr [si-1],20h
	lodsb			; get fourth digit
	or	al,al
	Ljz	Ctxbad2	
	mov	byte ptr [si-1],20h

	sub	bl,'0'
	cmp	bl,8
	Lja	Ctxbad2
	sub	bh,'0'
	cmp	bl,9
	Lja	Ctxbad2
	sub	ah,'0'
	cmp	ah,2
	Lja	Ctxbad2
	sub	al,'0'
	cmp	al,9
	Lja	Ctxbad2
	mov	dh,al
	mov	al,ah		;	digits in bl bh ah al
	call	Ctx29		;	set dh = ah*10 + al
	add	dh,al		;	set dl = bl*10 + bh  
	mov	dl,bh		
	mov	al,bl
	call	Ctx29
	add	dl,al
	dec	dh
	dec	dl
	cmp	dh,24
	Lja	Ctxbad2
	cmp	dl,79
	Lja	Ctxbad2
	mov	bx,bp
	mov	ah,2
	int	10h		; set the cursor position
	jmp	Ctx24
Ctx25:
	call	Ctx23		; get the letter pair in ax and convert
	mov	[bkattr],al	; store as the current defualt
	mov	bx,bp
	mov	bl,al
	mov	bp,bx
	mov	ah,3		; for /s, update the entire screen
	int	10h
	mov	di,dx		; save original cursor position
	xor	dx,dx
	mov	es,[tcbseg]
	assume	es:tcb
Ctx18:
	mov	ah,2
	int	10h		; read each char and rewrite with
	mov	ah,8		; new attribute
	int	10h
	mov	ah,9
	mov	cx,1
	int	10h
	mov	cl,[tcbcols]
	dec	cl
	cmp	dl,cl
	je	Ctx19
	inc	dl
	jmp	Ctx18
Ctx19:
	xor	dl,dl
	cmp	dh,24
	je	Ctx16
	inc	dh
	jmp	Ctx18
Ctx16:
	mov	dx,di
	mov	ah,2
	int	10h		; restore cursor to original location
	push	ds
	pop	es
	assume	es:dataseg
	jmp	Ctx24
Ctx26:
	call	Ctx23		; convert two digits after /c
	mov	bx,bp		; use as value for current attribute
	mov	bl,al
	mov	bp,bx
	jmp	Ctx24

Ctx30:				; /K option
	call	Ctx23		; get the letter pair in ax and convert
	mov	[bkattr],al	; store as the current defualt
	mov	bx,bp
	mov	bl,al
	mov	bp,bx
	mov	ah,3		; for /k, update the entire screen
	int	10h
	mov	di,dx		; save original cursor position
	xor	dx,dx
	mov	es,[tcbseg]
	assume	es:tcb
	mov	ax,0600h	; use scroll to clear the window
	mov	bh,[bkattr]
	xor	cx,cx
	mov	dh,24
	mov	dl,[tcbcols]
	dec	dl
	int	10h		
	mov	bx,bp
	mov	dx,di
	mov	ah,2
	int	10h		; restore cursor to original location
	push	ds
	pop	es
	assume	es:dataseg
	jmp	Ctx24
Ctx16a:
	call	Openbat		; open the batch file
	mov	bx,[BatHandl]
	mov	dx,WORD PTR [BatLine]
	mov	cx,WORD PTR [BatLine+2]
	xor	al,al
	MOS	Lseek		; get BatLine and seek the next line to be read
	Ljc	BatEr1
	mov	bx,bp
Ctx1:
	push	ds
	pop	es
	True?	[BatEFlg]
	Lje	Ctx3
	call	ReadBatLine	; read a line from the batch file into LineBuf
	Ljnz	Ctx3		; if end of file found before any data,	jmp
	lea	si,[LineBuf]
	push	cs
	pop	es
	lea	di,es:[EndTxtSt]	; try to match with a dot
	mov	dx,1
	mov	cx,8
	call	StrCompare
	Ljz	Ctx2
	lea	di,es:[EndTxtSt+1]	; try to match without a dot
	mov	dx,1
	mov	cx,7
	call	StrCompare
	Ljz	Ctx2
	push	ds
	pop	es
	lea	si,[LineBuf]
	cld
	mov	es,[tcbseg]
	assume	es:tcb
Ctx5:	
	cmp	[tabcnt],0
	Ljne	Ctx13
	lodsb
	or	al,al
	Ljz	Ctx6
	cmp	al,9		; tab char ?
	je	Ctx12
	cmp	al,'|'
	jne	Ctx7
	lodsb
	or	al,al
	Ljz	Ctx6
	cmp	al,'|'
	jne	Ctx8
Ctx7:
	mov	cx,1
	mov	ah,9
	int	10h
	call	Ctx14		; get cursor position in dx
	cmp	dl,[tcbcols]
	je	Ctx9
	inc	dl
Ctx11:
	mov	ah,2
	int	10h		; set cursor position
	jmp	Ctx5
Ctx9:
	cmp	dh,24
	je	Ctx10
	inc	dh		; increment row
	xor	dl,dl		; left column
	jmp	Ctx11

Ctx14	proc
	push	bx
	mov	bl,[tcbpage]
	xor	bh,bh
	shl	bx,1
	mov	dx,[tcbcpos+bx]
	pop	bx
	ret
Ctx14	endp

Ctx10:
	call	Ctx15
	jmp	Ctx11

Ctx15	proc
	mov	ax,0601h
	push	bx
	mov	bh,[bkattr]
	xor	cx,cx
	mov	dh,24
	mov	dl,[tcbcols]
	dec	dl
	int	10h		
	pop	bx
	mov	dx,1800h
	ret
Ctx15	endp

Ctx12:
	call	Ctx14		; get cursor position in dx
	mov	cl,dl
	add	cl,8
	and	cl,0f8h 	; calc next tab stop
	sub	cl,dl
	mov	[tabcnt],cl
Ctx13:
	dec	[tabcnt]
	mov	al,' '
	jmp	Ctx7
Ctx8:
	call	Ctx4
	mov	ah,al
	shl	ah,1
	shl	ah,1
	shl	ah,1
	shl	ah,1
	lodsb
	or	al,al
	je	Ctx6
	call	Ctx4
	or	al,ah
	mov	bl,al
	jmp	Ctx5
Ctx6:
	call	Ctx14		; get cursor position in dx
	cmp	dh,24
	je	Ctx6a
	mov	ax,0e0dh
	int	10h
	mov	ax,0e0ah
	int	10h
	jmp	Ctx1
Ctx6a:
	call	Ctx15
	mov	ah,2
	int	10h		; set cursor position
	jmp	Ctx1
Ctx2:
	push	ds
	pop	es
	call	Closebat		; close the	batch file
	jmp	BatResume
Ctx3:
	push	ds
	pop	es
	call	Closebat
	jmp	BATEOF

Ctxbad2:
	push    ds
	pop	es
	call	Closebat		; close batch file
	mov	al,205		; BAD parameter error
	call	ReportError
	jmp     BATEOF


;-----------------------------------------------------------------------;
;	 Messages for Signon and Signoff  (for security reasons)	;
;-----------------------------------------------------------------------;

clrmsg	db	01bh,'[1;1H',01bh,'[2J',0
entrmsg db	'Press Enter(CR) to begin Signon                         ',0 ;@@XLAT
signmsg db	01bh,'[4;1H','Please Signon      ',13,10,0 ;@@XLAT
usermsg db	01bh,'[6;1H',01bh,'[K','  User ID   : ',0 ;@@XLAT
passmsg db	13,10,'  Password  : ',01bh,'[0J',0 ;@@XLAT
sonok	db	13,10,'  User   ', 0 ;@@XLAT
sonver	db	'  has Signed on.     ',13,10,13,10,0 ;@@XLAT
taskcls db	'    Partition Class      =     ', 0 ;@@XLAT
dopcls	db	'    Default Output Class =     ', 0 ;@@XLAT
nouser	db	13,10,'Error: Invalid    ', 0 ;@@XLAT
nouser2 db	'USER.SYS File! ',13,10,0 ;@@XLAT
baduser db	13,10,'   Access denied, Please ',0 ;@@XLAT
badtry	db	'try again.        ',13,10,0 ;@@XLAT
badwait db	'wait.    ',13,10,0 ;@@XLAT
rubout	db	8,' ',8,0

soff	db	13,10,'  User   ',0 ;@@XLAT
susing	db	' Signed off.         ',13,10,0 ;@@XLAT
snobody db	13,10,'Nobody is Currently Signed On.  ',13,10,0 ;@@XLAT


;-----------------------------------------------------------------------;
;				BATECHO 				;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

BatEcStr db	'BATECHO',0

CBatEcho:
	True?	[NullParm]
	je	Cbe1
	lea	si,[ParmBuf]
	call	PassDelims
	call	Low2Upper
	cmp	al,'O'		; if first non-delim = 'O', could be ON	or OFF
	je	Cbe2
Cbe5:
	mov	al,214		; Must specify ON or OFF
	call	ReportError
	jmp CMFL
Cbe1:
	mov	al,[BatEcDf]
	lea	dx,cmd:[BatEcStr]
	call	ReportStat
	jmp	CMFL
Cbe2:				; check for 'ON' or 'OFF'
	push	es
	push	cs
	pop	es
	lea	di,[ONStr]
	mov	dx,1		; mod si string to Ucase
	mov	cx,2
	call	StrCompare
	je	Cbe3
	lea	di,[OFFStr]
	mov	cx,3
	call	StrCompare
	je	Cbe4
	pop	es
	jmp	Cbe5
Cbe3:				; found 'on'
	pop	es
	add	si,2
	call	PassDelims
	cmp	BYTE PTR [si],0
	jne	Cbe5
	SetFlg	[BatEcDf]
	SetFlg	[BatEcho]
	jmp CMFL
Cbe4:				; found 'off'
	pop	es
	add	si,3
	call	PassDelims
	cmp	BYTE PTR [si],0
	jne	Cbe5
	ResFlg	[BatEcDf]
	ResFlg	[BatEcho]
	jmp CMFL

;-----------------------------------------------------------------------;
;				 EXCEPT 				;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

CExcept:
	xor	bp,bp		; reset type flag
	jmp	Ceo1

;-----------------------------------------------------------------------;
;				 ONLY					;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

Cancel	db	'CANCEL'

COnly:
	mov	bp,2		; set type flag
Ceo1:
	call	ChainClr
	True?	[NullParm]
	Lje	BADPARM1
	lea	si,[ParmBuf]
	call	CheckSet
	Ljnc	Ceo9		
	
	call	PassDelims	; not '(set) do' format so check for cancel
	push	cs
	pop	es
	lea	di,[Cancel]
	mov	dx,1		; mod si string to Ucase
	mov	cx,6
	call	StrCompare
	push	ds
	pop	es	
	Ljnz	BADPARM6	; not cancel so error
	xor	al,al		
	call	GetSetAct
	or	si,si
	Ljz	CMFL		; if	tcbactseg=0, no lists exist
				; if a list does exist, flush all the blocks
				; of the type as specified by bp
	xor	cx,cx		; init flag	for pointer update control
	push	es
	assume	es:nothing
Ceo11:
	mov	bx,es		; save old pointer in bx
	mov	es,si
	xor	di,di
	mov	si,es:[di+1]		; get next pointer of current block
	or	bp,bp
	jz	Ceo15
	test	byte ptr es:[di],2	; test	for only case
	jz	Ceo12
	jmp	Ceo16
Ceo15:
	test byte ptr es:[di],2 	; test for except case
	jnz	Ceo12
Ceo16:
	MOS	FreeMem
	call	MemCheck
	or	cx,cx
	jz	Ceo13
	push	es
	mov	es,bx		; point to previous	block
	mov	es:[di+1],si	; put	next pointer value of block just killed
	pop	es		; in next pointer of previous block
	jmp	Ceo12
Ceo13:
	mov	ax,1		; as	long as keep killing blocks from the start
	call	GetSetPre	; update the root pointers
	call	GetSetAct
	or	si,si
	jz	Ceo14		; done
	jmp	Ceo11
Ceo12:
	or	si,si
	jz	Ceo14		; done
	mov	cx,1		; keeping a block, set cx so	its next link
	jmp	Ceo11		; is updated instead of the	root pointers
Ceo14:
	pop	es
	jmp	CMFL
Ceo9:
	mov	dl,dh
	xor	dh,dh
	push	si		; save pointer to start of command
	mov	si,bx
	push	si		; save pointer to start of name list
	mov	bx,dx
	mov	byte ptr [si+bx],0	; mark end of file list with a 0
	mov	al,':'
	xor	cx,cx
	call	ScanStr
	Lje	BADPARM6
	pop	si
	push	si
	mov	al,Bslash
	call	ScanStr
	Lje	BADPARM6
	
	mov	bx,4096 	;	paragraph count for 64 Kbytes
Ceo2:
	MOS	GetMem
	call	MemCheck
	jnc	Ceo3
	or	bx,bx
	Ljz	BADPARM7	;	insufficient memory
	and	bx,0fff8h	; trunc down to nearest 128 byte multiple
	jmp	Ceo2
Ceo3:
	mov	es,ax		; store pointer to block
	assume	es:nothing
	mov	cl,4
	shl	bx,cl
	dec	bx		; block size (bytes) in bx
	mov	di,5		; offset of file name area in the list
	pop	si		; pointer to start of file name list
	push	si
Ceo4:
	pop	si
	push	di
	push	es
	push	ds
	pop	es
	call	Parse
	lea	di,[PrsFCB+1]
	mov	cx,8		; convert 8 ?'s into a *
	mov	al,'?'
	cld
	repe	scasb
	or	cx,cx
	jnz	Ceo7
	mov	byte ptr [PrsFCB+1],'*'
Ceo7:
	lea	di,[PrsFCB+9]	; convert 3 ' ' into
	cmp     byte ptr [PrsFCB+1],00
	je      Ceo7ok		; well if nothing skip (why????)
	cmp     byte ptr [di],0
	jne     Ceo7ok
	mov     byte ptr [di],' '	; convert to space to fix bug
Ceo7ok:
	cmp	byte ptr [di],' '
	jne	Ceo7a
	push	si
	std
Ceo7b:
	lodsb			; if no extension, check for a period on
	call	TestDelims	; the end of the filename.  If none,
	je	Ceo7b		; put a * on the end
	add	si,2
	pop	si
	cmp	byte ptr [si],'.'
	jne	Ceo7c	
Ceo7a:
	mov	cx,3
	mov	al,'?'
	repe	scasb
	or	cx,cx
	jnz	Ceo8
Ceo7c:
	mov	byte ptr [PrsFCB+9],'*'
Ceo8:
	pop	es
	pop	di
	cmp	byte ptr [PrsFCB+1],0
	je	Ceo5		; done with list
	mov	ax,12		; 11 for fname.ext and 1 for the ending 0
	xor	dx,dx
	add	ax,di
	adc	dx,0
	or	dx,dx
	jnz	Ceo6
	cmp	di,bx
	ja	Ceo6		; out	of room in block
		
	mov	cx,11
	push	si
	lea	si,[PrsFCB+1]
	cld
	rep	movsb		; copy the file name into the block
	jmp	Ceo4		
Ceo6:
	MOS	FreeMem 	; es should still be pointing to the block
	call	MemCheck
	push	ds
	pop	es
	jmp	BADPARM7	
Ceo5:
	xor	al,al
	stosb			; write the end of list marker
	mov	ax,di
	add	ax,15
	call	Bytes2Para
	mov	bx,ax
	MOS	ModMem		; shrink the block back to just what's needed
	call	MemCheck
	xor	di,di
	xor	ax,ax
	or	ax,bp		; set type bit
	stosb			; init	block header flags
	xor	al,al
	call	GetSetPre
	mov	ax,si
	stosw			; record the value of tcbpreseg in the	block
	mov	si,es
	mov	al,1
	call	GetSetPre	; make tcbpreseg point to the new block	
	pop	si		; recover pointer to start of command
	push	ds
	pop	es
	lea	di,[LineBuf]	; put	command in LineBuf
	xor	cx,cx
	call	CopyStr
	lea	si,[LineBuf]
	mov	[MlStrt],si
	jmp	ProcessLBuf

;-----------------------------------------------------------------------;
;				 KEY					;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

Key15 proc		; supply test char in al, ZR if ok,	else NZ 
	push	si
	lea	si,[NumSet]
	call	TestSet
	je	Key16
	lea	si,[AlphSet]
	call	TestSet
Key16:
	pop	si
	ret
Key15 endp

Key17 proc			; enter with si pointing to buffer
	mov	di,si		; converts the buffer to single byte format
	cmp	byte ptr [si],0
	je	Key18	
	cld
Key6:
	lodsb
	or	al,al
	je	Key18
	cmp	al,'-'
	je	Key6
	call	TestDelims
	je	Key6
	cmp	al,'S'		; test for 'S' for SPace
	jne     Key6a
	lodsb
	cmp	al,'P'		; test for 'P' for SPace
	jne	Key6c		; SAH handle the case of just 'S'
	mov	al,' '		; translate to a SPace
	stosb
	jmp	Key6
Key6a:
	cmp	al,'C'		; test for 'C' for Carriage Return
	jne     Key6b
	lodsb
	cmp	al,'R'		; test for 'R' for Carriage Return
	jne	Key6c		; SAH handle the case of just 'C'
	mov	al,13		; translate to a Carriage Return
	stosb
	jmp	Key6
Key6b:
	cmp	al,'F'
	je	Key7
	stosb
	jmp	Key6

;	SAH	11/25/87 fix for SP and CR

Key6c:
	dec	si		; adjust source pointer back to initial char
	dec	si
	movsb			; transfer the byte
	jmp	Key6	

;	SAH     11/25/87 

Key7:
	lodsb			; found an 'F', check for function key
	or	al,al
	je	Key8
	cmp	al,'-'
	je	Key8
	call	TestDelims
	je	Key8
	mov	cl,al
	sub	cl,'0'
	lodsb
	or	al,al
	je	Key9
	cmp	al,'-'
	je	Key9
	call	TestDelims
	je	Key9
	mov	ah,al
	mov	al,210		; code for	F10
	jmp	Key10
Key9:
	mov	ah,al	
	mov	al,cl
	add	al,200		; convert to function key code
Key10:
	stosb		
	or	ah,ah
	jnz	Key6
	jmp	Key18
Key8:
	mov	ah,al
	mov	al,'F'
	stosb
	or	ah,ah
	jnz	Key6
Key18:
	xor	al,al
	stosb
	ret
Key17 endp

NumSet	db	'0123456789',0
AlphSet db	'ABCDEFGHIJKLMNOPQRSTUVWXYZ',0

;------------------------ START OF CODE FOR  KEY -------------------------;

Ckey:
	call	ChainClr
	True?	[NullParm]
	Lje	BADPARM6
	lea	si,[ParmBuf]
	cld
	call	PassDelims
	cmp	al,'%'
	Ljne	BADPARM6
	inc	si
	lodsb
	call	TestDelims
	Lje	BADPARM6
	or	al,al
	Ljz	BADPARM6
	call	Low2Upper
	mov	cl,al		; save the char after the % for replacement
	lodsb
	call	TestDelims
	Ljne	BADPARM6
	call	PassDelims
	call	Low2Upper
	cmp	al,'I'
	Ljne	BADPARM6
	inc	si
	lodsb
	call	Low2Upper
	cmp	al,'N'
	Ljne	BADPARM6
	lodsb
	call	TestDelims
	Ljne	BADPARM6
	call	CheckSet	; check for (set) DO spec
	Ljc	BADPARM6	;	returns data in si, bx, dx
	mov	dl,dh
	xor	dh,dh
	push	si		; save pointer to start of command
	mov	si,bx
	mov	bx,dx
	mov	byte ptr [si+bx],0	; put an end of string marker after
					; the name	list
	push	cx
	xor	cx,cx
	call	Str2Upper		
	cld
	mov	bp,si
Key19:
	lodsb			; should only be leading spaces, if anything
	cmp	al,' '
	je	Key19
	call	TestDelims
	Lje	BADPARM2
	dec	si
Key20:
	call	PassDelims
	lodsb
	or	al,al
	jz	Key21
	call	Key15
	Ljnz	BADPARM2
	cmp	al,'S'		; test for 'S' for SPace
	jne     Key20a
	lodsb
	cmp	al,'P'		; test for 'P' for SPace
	je      Key20		; passed
	dec	si		; SAH point back to the char after 'S'	
	jmp	Key20		; SAH allow for just 'S'
Key20a:
	cmp	al,'C'		; test for 'C' for Carriage Return
	jne     Key20b
	lodsb
	cmp	al,'R'		; test for 'R' for Carriage Return
	je      Key20		; passed
	dec	si		; SAH point back to the char after 'C'
	jmp	Key20		; SAH allow for just 'C'
Key20b:
	cmp	al,'F'
	je	Key23
	lodsb
	or	al,al
	je	Key21	
	call	TestDelims
	je	Key20
	cmp	al,'-'
	je	Key20
	jmp	BADPARM2
Key23:
	lodsb
	or	al,al
	jz	Key21
	call	TestDelims
	je	Key20
	cmp	al,'-'
	je	Key20
	push	si
	lea	si,[NumSet]
	call	TestSet 
	pop	si
	Ljne	BADPARM2
	cmp	al,'0'
	Lje	BADPARM2
	mov	ah,al
	lodsb
	or	al,al
	jz	Key21
	call	TestDelims
	je	Key20
	cmp	al,'-'
	je	Key20
	cmp	al,'0'
	Ljne	BADPARM2
	cmp	ah,'1'
	Ljne	BADPARM2
	jmp	Key20
Key21:
	lea	di,[WorkBuf]
	xor	ax,ax
	mov	cx,64
	cld
	rep	stosw
	
	mov	si,bp		; recover pointer to start of char set
	push	si
	call	PassDelims
	mov	dx,si
	lea	bp,[WorkBuf]
Key5:
	mov	di,si
	call	FindLen
	mov	al,'-'		; scan for	a dash
	repne	scasb
	jne	Key22
	mov	si,di
	sub	si,3
	std
Key2:
	lodsb
	call	TestDelims
	je	Key1
	cmp	dx,si
	jna	Key2
Key1:
	add	si,2
	cmp     byte ptr [si-1], 'F'		; check for function keys
	jne     Key1nf
	dec     si
Key1nf:
	push	si		; save start of substring pointer
	mov	si,di
	cld
	inc	si
Key4:
	lodsb
	or	al,al
	jz	Key3
	call	TestDelims
	jne	Key4
Key3:
	mov	cx,si
	pop	si
	push	si
	sub	cx,si
	dec	cx
	mov	di,bp
	push	si
	push	cx
	rep	movsb		; copy the substring to WorkBuf
	pop	cx
	pop	si
	mov	al,','
	stosb
	mov	bp,di
	mov	al,' '
	mov	di,si
	push	cx
	rep	stosb		; blank out	the substring in ParmBuf
	pop	cx
	pop	si
	add	si,cx
	cmp	byte ptr [si],0
	jne	Key5
Key22:	
	pop	si
	push	si
	call	Key17
	lea	si,[WorkBuf]
	call	Key17
	lea	si,[WorkBuf]		; if	anything in WorkBuf, validate
	cld				; the ranges
Key11:
	lodsb
	mov	ah,al
	lodsb
	or	ah,ah
	jz	Key24
	push	si
	lea	si,[NumSet]
	call	TestSet
	pop	si
	jne	Key12
	push	si
	xchg	ah,al
	lea	si,[NumSet]
	call	TestSet
	pop	si
	Ljne	BADPARM2
	cmp	al,ah
	Ljnb	BADPARM2
	jmp	Key11
Key12:
	push	si
	lea	si,[AlphSet]
	call	TestSet
	pop	si
	jne	Key13
	push	si
	xchg	ah,al
	lea	si,[AlphSet]
	call	TestSet
	pop	si
	Ljne	BADPARM2
	cmp	al,ah
	Ljnb	BADPARM2
	jmp	Key11
Key13:				; must be function key
	cmp	ah,al
	Ljnb	BADPARM2
	jmp	Key11
Key24:
	MOS	7		; SAH 08/18/87 get a key 
	or	al,al
	jz	Key25
	call	Low2Upper
	jmp	Key26	
Key25:
	MOS	7		; SAH 08/18/87 was function 8
	add	al,142		; convert F1 to 201, etc
Key26:	
	pop	si
	push	si
	dec	si
	mov	bl,al
Key34:
	inc	si
	cmp	BYTE PTR [si],0
	je	Key35
	cmp	al,BYTE PTR [si]
	je	Key27
	jmp	Key34
Key35:
	lea	si,[WorkBuf]
	cld
Key14:
	lodsb
	mov	ah,al
	lodsb
	or	ah,ah
	jz	Key24		; ignore and	get another key
	cmp	bl,ah
	jb	Key14
	cmp	bl,al
	ja	Key14
Key27:				; replacement	char is in bl
	pop	si		; get si off of stack
	pop	cx		; % char is in	cl
	mov	dl,cl
	pop	si		; get pointer to start	of command
	lea	di,[LineBuf]	; put	command in LineBuf, convert any parm
	xor	cx,cx		; and execute the command
	call	CopyStr
Key30:
	mov	ah,dl		; get the %	char 
Key29:
	lea	si,[LineBuf]
	mov	al,'%'
	xor	cx,cx
	call	ScanStr
	Ljne	Key28		; done with parameter replacement
	inc	si
	mov	al,[si]
	call	Low2Upper
	cmp	ah,al
	jne	Key29
	mov	bp,si		; save point where substitution is to start
	dec	bp
	inc	si
	lea	di,[WorkBuf]	; save remainder of LineBuf in WorkBuf
	xor	cx,cx
	call	CopyStr
	mov	di,bp
	mov	al,bl
	cmp	al,' '		; test for SPace
	jne     Key29a
	mov	al,'S'		; store 'S' for SPace
	stosb
	mov	al,'P'		; store 'P' for SPace
	jmp	Key31
Key29a:
	cmp     al,13		; test for Carriage Return
	jne	Key29b
	mov	al,'C'		; store 'C' for Carriage Return
	stosb
	mov	al,'R'		; store 'R' for Carriage Return
	jmp	Key31
Key29b:
	cmp	al,201
	jb	Key31
	mov	ah,al
	mov	al,'F'
	stosb
	sub	ah,152
	cmp	ah,58
	je	Key33
	mov	al,ah
	stosb
	jmp	Key32
Key33:
	mov	al,'1'
	stosb
	mov	al,'0'
	stosb
	jmp	Key32
Key31:
	stosb
Key32:
	lea	si,[WorkBuf]
	xor	cx,cx
	call	CopyStr
	mov	si,bp		; recover next search point
	jmp	Key30		; continue scanning	for	% parms
Key28:
	lea	si,[LineBuf]
	mov	[MlStrt],si
	jmp	ProcessLBuf

;-----------------------------------------------------------------------;
;				 AUTOCD 				;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

CAutocd:
	True?	[NullParm]
	Lje	BADPARM1
	lea	si,[ParmBuf]
	call	PassDelims
	mov	dx,si
	xor	al,al
	call	GetSetAct	; temporarily suspend any EXCEPT/ONLY 
	mov	[TempSeg],si	; list(s) which may be active
	xor	si,si
	mov	al,1
	call	GetSetAct
	mov	al,00100000b	; deny write, read only access
	MOS	OpenFil
	pushf
	push	ax
	mov	si,[TempSeg]	; restore original tcbactseg
	mov	word ptr [TempSeg],0
	mov	al,1
	call	GetSetAct
	pop	ax
	popf
	Ljc	BADPARM
	mov	cx,80
	lea	dx,[WorkBuf]
	mov	bx,ax
	MOS	ReadFil
	push	ax
	Ljc	BADPARM
	MOS	ClosFil
	Ljc	BADPARM
	pop	bx
	lea	si,[WorkBuf+bx-1]
	std
Cau1:
	lodsb
	cmp	al,20h
	jbe	Cau1
	add	si,2
	mov	byte ptr [si],0
	lea	dx,[WorkBuf]
	MOS	ChDir
	Ljc	BADPARM5
	lea	si,[WorkBuf]
	mov	dl,[si]
	sub	dl,'A'
	MOS	SetDrv
	jmp	CMFL

;-----------------------------------------------------------------------;
;				 INSERT 				;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

Cinsert:

	mov	es,[TcbSeg]
	assume	es:tcb
	mov	byte ptr [tcb%insf],0ffh
	push	ds
	pop	es
	jmp	CMFL

;-----------------------------------------------------------------------;
;				 FLUSH					;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

Cflush:
	mov	es,[TcbSeg]
	assume	es:tcb
	mov	word ptr [tcb%rs0a],0
	mov	word ptr [tcb%rs3f],0
	push	ds
	pop	es
	jmp	CMFL


;-----------------------------------------------------------------------;
;				    BREAK				;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

Cbreak:
	True?	[NullParm]
	je	Cbk1
	lea	si,[ParmBuf]
	call	PassDelims
	call	Low2Upper
	cmp	al,'O'		; if first non-delim = 'O', could be ON or OFF
	je	Cbk2
Cbk5:
	mov	al,214		; Must specify ON or OFF
	jmp	BADPARM
Cbk1:
	xor	al,al
	MOS	GSBrk		; read and display break status
	mov	al,dl
	lea	dx,cmd:[BrkStr]
	call	ReportStat
	jmp	CMFL
Cbk2:				; check for 'ON' or 'OFF'
	push	es
	push	cs
	pop	es
	lea	di,[ONStr]
	mov	dx,1		; mod si string to Ucase
	mov	cx,2
	call	StrCompare
	je	Cbk3
	lea	di,[OFFStr]
	mov	cx,3
	call	StrCompare
	je	Cbk4
	pop	es
	jmp	Cbk5
Cbk3:				; found 'on'
	pop	es
	add	si,2
	call	PassDelims
	cmp	BYTE PTR [si],0
	jne	Cbk5
	mov	al,1
	mov	dl,1
	MOS	GSBrk
	jmp CMFL
Cbk4:				; found 'off'
	pop	es
	add	si,3
	call	PassDelims
	cmp	BYTE PTR [si],0
	jne	Cbk5
	mov	al,1
	xor	dl,dl
	MOS	GSBrk
	jmp CMFL

;-----------------------------------------------------------------------;
;				    DOT 				;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

Cdot:
	True?	[NullParm]
	je	Cdt1
	lea	si,[ParmBuf]
	call	PassDelims
	call	Low2Upper
	cmp	al,'O'		; if first non-delim = 'O', could be ON or OFF
	je	Cdt2
Cdt5:
	mov	al,214		; Must specify ON or OFF
	jmp	BADPARM
Cdt1:
	mov	al,[NoDot]
	and	al,1
	xor	al,1		; invert the low bit
	lea	dx,cmd:[DotStr]
	call	ReportStat
	jmp	CMFL
Cdt2:				; check for 'ON' or 'OFF'
	push	es
	push	cs
	pop	es
	lea	di,[ONStr]
	mov	dx,1		; mod si string to Ucase
	mov	cx,2
	call	StrCompare
	je	Cdt3
	lea	di,[OFFStr]
	mov	cx,3
	call	StrCompare
	je	Cdt4
	pop	es
	jmp	Cdt5
Cdt3:				; found 'on'
	pop	es
	add	si,2
	call	PassDelims
	cmp	BYTE PTR [si],0
	jne	Cdt5
	ResFlg	[NoDot]
	jmp CMFL
Cdt4:				; found 'off'
	pop	es
	add	si,3
	call	PassDelims
	cmp	BYTE PTR [si],0
	jne	Cdt5
	SetFlg	[NoDot]
	jmp CMFL

;-----------------------------------------------------------------------;
;				     WVER				;
;-----------------------------------------------------------------------;

	ASSUME	DS:DATASEG,ES:DATASEG

Cverify: 
	True?	[NullParm]
	je	Cvr1
	lea	si,[ParmBuf]
	call	PassDelims
	call	Low2Upper
	cmp	al,'O'		; if first non-delim = 'O', could be ON or OFF
	je	Cvr2
Cvr5:
	mov	al,214		; Must specify ON or OFF
	call	ReportError
	jmp CMFL
Cvr1:
	MOS	GetVerf 	; read and display break status
	lea	dx,cmd:[VerStr]
	call	ReportStat
	jmp	CMFL
Cvr2:				; check for 'ON' or 'OFF'
	push	es
	push	cs
	pop	es
	lea	di,[ONStr]
	mov	dx,1		; mod si string to Ucase
	mov	cx,2
	call	StrCompare
	je	Cvr3
	lea	di,[OFFStr]
	mov	cx,3
	call	StrCompare
	je	Cvr4
	pop	es
	jmp	Cvr5
Cvr3:				; found 'on'
	pop	es
	add	si,2
	call	PassDelims
	cmp	BYTE PTR [si],0
	jne	Cvr5
	mov	al,1
	MOS	SetVerf
	jmp CMFL
Cvr4:				; found 'off'
	pop	es
	add	si,3
	call	PassDelims
	cmp	BYTE PTR [si],0
	jne	Cvr5
	xor	al,al
	MOS	SetVerf
	jmp CMFL

;-----------------------------------------------------------------------
;			      signoff
;-----------------------------------------------------------------------
	assume	ds:dataseg,es:dataseg
csignoff:
	push	es
	mov	es,[tcbseg]
	assume	es:tcb
	xor	ax,ax
	cmp	word ptr [tcbuser],ax
	jne	soff1
	cmp	word ptr [tcbuser+2],ax
	lea	dx,snobody		; nobody is on system
	call	csdispstr
	jmp	short soff2
soff1:

; if signing off would result in a lockout, channel into signon instead.

	cmp	[tcbclass],0
	je	soff3
	cmp	[tcbclass],20h
	je	soff3
	pop	es
	assume	es:dataseg
	jmp	csignon
soff3:

; display signoff message

	assume	es:tcb
	lea	dx,soff
	call	csdispstr
	call	dispuser
	lea	dx,susing
	call	csdispstr

; change user information in tcb

	xor	ax,ax
	mov	word ptr [tcbuser],ax
	mov	word ptr [tcbuser+2],ax
	mov	[tcbcdft],al
	lea	di,[tcbcmap]		; clear tcb bit map
	mov	cx,7
	rep	stosb
soff2:

; clear command buffers

	mov	word ptr [tcb%rs0a],0
	mov	word ptr [tcb%rs3f],0
	pop	es
	jmp	cmfl

;-----------------------------------------------------------------------
;			      signon
;-----------------------------------------------------------------------
	assume ds:dataseg,es:dataseg
csignon:
	push	ds
	mov	ds,[tcbseg]
	assume	ds:tcb,es:csignons
	mov	bl,[tcbansi]		; get current ansi emulation
	mov	[organsi],bl		; save value into data segment
	mov	[tcbansi],0ffh		; put system in ansi emulation
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr ds:[23h*4]
	mov	[sign23o],ax
	mov	ax,word ptr ds:[23h*4+2]
	mov	[sign23s],ax
	cli
	mov	word ptr ds:[23h*4],offset cmd:signint23
	mov	word ptr ds:[23h*4+2],cs
	sti
	pop	ds
	assume	ds:dataseg,es:dataseg
	push	ds			; save ds for return
	push	es			; and es
	call	setdtaaddr		; set dta to our dtaaddr
	mov	bx,4096			; we want 4096 paragraphs (64k)
son0a:
	mov	[copysize],bx		; save number of paragraphs requ
	mos	getmem			; tell mos we want 64k right now
	jnc	son0b			; press on if no errors
	call	memcheck		; go check out the error
	or	bx,bx			; any memory available
	jnz	son0a			; ask for what he's got
	jmp	badparm7		; no place to go if not enuf mem
son0b:
	mov	[copyseg],ax		; save the segment of our 64k
	mov	bx,[copysize]		; get the number of paragraphs s
	mov	cl,4			; convert paragraphs to bytes
	shl	bx,cl			; convert buffer size to bytes
	dec	bx			; minus one for full 64k
	mov	[copysize],bx		; save the size of the buffer-1
	setflg	[copyfix2]		; set to clear and release the b

; once any change of error exit has been passed, reset tcbclass
; to insure that keystroke entry will be allowed 

	push	ds
	mov	ds,[tcbseg]
	assume	ds:tcb
	mov	al,[tcbclass]		; save entry value for later
	mov	[tcbclass],0		; restoration
	mov	[tcbcdft],0

; clear command buffers

	mov	word ptr [tcb%rs0a],0
	mov	word ptr [tcb%rs3f],0
	pop	ds
	assume	ds:dataseg
	push	ax			; put orig tcbclass on stack
	lea	dx,cmd:clrmsg
	call	csdispstr		; clear the screen
	true?	[nullparm]		; did we get a command line user
	jne	son0d			; skip enter request if yes
	lea	dx,cmd:entrmsg		; point to enter message
	call	csdispstr		; display the enter message
son0c:
	mov	ah,0			; function 0
	int	016h			; get a keyboard character
	cmp	al,00dh			; is it an enter (carriage retur
	jne	son0c			; loop until one found
son0d:
	lea	dx,cmd:signmsg		; point to the signon message #1
	call	csdispstr		; display the signon message
	xor	al,al			; clear all security request
	call	clrsetsall		; clear user name, security map
	assume	ds:csignons		; csignons redefines dataseg
	mov	byte ptr [trys],0	; reset the try counter
	mov	word ptr [soncls],'. '	; initialize class display area
	mov	byte ptr [soncls+2],0	; and string terminator
	lea	dx,cmd:usermsg		; point to the user id prompt
	call	csdispstr		; display it
	true?	[nullparm]		; was there a command line optio
	je	sonpuser		; get the user id if not on comm
	lea	si ,[parmbuf]		; point to the command line user
	call	passdelims		; point si to the user id
	xor	cx,cx			; clear cx
	call	str2upper		; convert the entry to upper cas
	push	si			; save the start of the entry
	xor	cx,cx			; clear cx
sonchk1:
	lodsb				; get a character
	cmp	al,'0'			; is it less than 0
	jb	sonchk3			; jump if no (invalid data)
	cmp	al,'9'			; is it a number
	jbe	sonchk2			; jump if yes (0 - 9 is ok)
	cmp	al,'A'			; is it between 9 and a
	jb	sonchk3			; jump if yes (invalid data)
	cmp	al,'Z'			; is it between a and z
	ja	sonchk3			; jump if not (invalid data)
sonchk2:
	inc	cx			; bump the count of valid charac
	mov	dl,al			; character to dl for display
	mos	02h			; ask mos to display the charact
	jmp	sonchk1			; go check the next character
sonchk3:
	pop	si			; restore the pointer to the dat
	or	cl,cl			; did we get any valid character
	je	sonpuser		; go ask for user id if no
	cmp	cl,5			; did we get more than 4
	jb	sonchk4			; jump if no
	mov	cl,4			; only look at the first 4
sonchk4:
	mov	[len1],cl		; store the user id length
	lea	di,[parm1]		; store the user id in parm1
	call	copystr			; go copy it (rep movsb)
	jmp	sonppass		; go get the password
sonparse:				; errors come back here
	lea	dx,cmd:usermsg		; point to the user id prompt
	call	csdispstr		; go display it
sonpuser:
	mov	ax,2020h		; set user id to spaces
	mov	word ptr [parm1],ax	; initialize the user id storage
	mov	word ptr [parm1+2],ax	; all four bytes of it
	xor	ax,ax			; set to display input
	mov	cl,4			; ask for no more than 4 charact
	lea	di,[parm1]		; and put them in parm1
	call	getinp			; go get the keyboard data
	mov	[len1],cl		; save length of data received
	xor	ch,ch			; clear ch
	jcxz	sonparse		; go ask again if nothing entere
sonppass:
	call	dispeol			; do a new line
	lea	dx,cmd:passmsg		; point to the password prompt
	call	csdispstr		; go display it
	mov	al,1			; set for non display of respons
	mov	cl,6			; no more than 6 characters
	lea	di,[parm2]		; put the response in parm2
	call	getinp			; go get the keyboard data
	mov	[len2],cl		; save number of characters rece
	call	dispeol			; do a new line

; set tcb bit map to highest piroritys

check:
	setflg	[signfix1]		; set sign flag
	mov	al,1
	call	clrsetsall		; set to highest level
	assume	ds:dataseg
	call	chkuser			; check user file
	or	ah,ah
	ljz	ok

; reset	tcb bitmap to spaces

	push	ax
	xor	al,al
	call	clrsetsall		; clear it
	pop	ax
	cmp	ah,3			; test for invalid password
	jb	soninv
	lea	dx,cmd:nouser		; invalid user file - error out
	call	csdispstr
	mov	dl,'$'
	mos	02h
	mov	dl,'$'
	mos	02h
	lea	dx,cmd:nouser2
	call	csdispstr
	pop	ax			; get orig tcbclass off stack
	jmp	sonexit
soninv:

; invalid access - try again

	assume	ds:csignons
	lea	dx,cmd:baduser
	call	csdispstr
	inc	[trys]
	xor	ax,ax
	int	1ah
	and	dh,1
	and	dl,3
	add	dl,dh
	add	dl,5
	cmp	[trys],dl
	ljb	sontok
	lea	dx,cmd:badwait
	call	csdispstr

; wait a while

	xor	ax,ax			; randomize wait
	int	1ah
	and	dh,3
	and	dl,7
	add	dl,dh
	add	dl,5
	mov	bh,dl
	shl	bh,1
	mov	ax,0702h		; wait for timer ticks
	call	sim38			; sah simulate int 38
	mov	byte ptr [trys],0	; wait is over - ask again
	jmp	sonparse
sontok:
	lea	dx,cmd:badtry
	call	csdispstr
	jmp	sonparse		; try again
ok:
	pop	dx			; get orig tcbclass from stack
	push	ds
	mov	ds,[tcbseg]
	assume	ds:tcb
	mov	[tcbclass],dl		; restore entry value
	pop	ds
	assume	ds:csignons
	mov	[soncls],al		; save default class for message
	lea	dx,cmd:sonok
	call	csdispstr
	mov	bl,[len1]
	xor	bh,bh
	mov	byte ptr [bx+parm1],0
ok1:
	lea	dx,parm1
	call	dispstr
	lea	dx,cmd:sonver
	call	csdispstr
	assume	ds:dataseg
	mov	es,[tcbseg]
	assume	ds:csignons,es:tcb
	mov	al,byte ptr es:[tcbclass]  ; tcb class
	or	al,al
	jnz	ok2
	mov	al,' '
ok2:
	xchg	[soncls],al		; exchange it with defoutcls
	lea	dx,cmd:taskcls
	call	csdispstr
	lea	dx,soncls
	call	dispstr
	call	dispeol
	or	al,al
	jnz	ok3
	mov	al,' '
ok3:
	mov	[soncls],al		; default output class
	lea	dx,cmd:dopcls
	call	csdispstr
	lea	dx,soncls
	call	dispstr
	call	dispeol
sonexit:
	assume	ds:dataseg
	call	cleansign		; cleanup security & memory
	pop	es
	pop	ds
	assume	ds:dataseg,es:dataseg
	assume	ds:dataseg
	jmp	cmfl

; the following is stubb interupt for int 23h control-c vector during
; the process of doing a signon. simple set to  iret

	public signint23
signint23 proc	near
	iret
signint23 endp

;-----------------------------------------------------------------------
;	routines use internally by signon
;-----------------------------------------------------------------------
	page
;-----------------------------------------------------------------------
;	function:   getinp
;		    gets input from user ethier user id or non
;		    displayable password
;	input:
;		al = type    (0 = userid, 1 = password)
;		cl = buffer limit
;		di = buffer offset position
;	output:
;		cl = buffer size
;		di = buffer offset position
;-----------------------------------------------------------------------
	assume	ds:csignons,es:dataseg
getinp	proc	near
	push	dx
	push	bp
	push	si
	push	di
	push	es
	mov	es,[tcbseg]
	assume	es:tcb
	mov	ch,' '			; make it space class
	xchg	ch,byte ptr es:[tcbclass]
	push	ds
	pop	es
	assume	ds:csignons,es:dataseg
	mov	[savecls],ch
	xor	ch,ch
	mov	si,cx			; save lenght in a register
	xor	ah,ah
	mov	bp,ax			; save type in a register
	xor	cx,cx
gi1:
	xor	ax,ax
	int	16h			; get key
	cmp	al,8
	jne	gi2
	or	cx,cx
	jz	gi1
	dec	cx
	dec	di
	or	bp,bp			; test for non-display
	jnz	gi1
	lea	dx,cmd:rubout
	call	csdispstr
	jmp	short gi1
gi2:
	cmp	al,0dh
	je	gidone
	cmp	al,0ah
	je	gidone
gi2a:
	cmp	cx,si
	jae	gi1
	cmp	al,'0'			; test for 0 - 9
	jb	gi1
	cmp	al,'9'
	jbe	giset
	call	low2upper
	cmp	al,'A'			; test for a - z
	jb	gi1
	cmp	al,'Z'
	jbe	giset
giset:
	stosb
	or	bp,bp			; test for non-display
	jnz	gi3
	mov	ah,14
	int	10h
gi3:
	inc	cx
	jmp	gi1
gidone:
	mov	es,es:[tcbseg]
	mov	ch,[savecls]
	assume	es:tcb
	mov	byte ptr es:[tcbclass],ch
	pop	es
	assume	es:dataseg
	pop	di
	pop	si
	pop	bp
	pop	dx
	ret
getinp	endp

	page
;-----------------------------------------------------------------------
;	function:   getuser
;		    gets next user from userfile skiping over comment
;		    lines and reading new disk records in memory
;	input:
;		bx = handle
;		di = buffer offset position    (0 = begin)
;	output:
;		di = buffer offset position    (0 = error)
;		al = user id lenght
;-----------------------------------------------------------------------
	assume	ds:csignons,es:dataseg
getuser proc	near
	push	bx
	push	cx
	push	dx
	push	es
	xchg	si,di
	or	si,si			; skip read
	jz	guread
	assume	ds:dataseg
	mov	es,[copyseg]
	assume	ds:csignons,es:nothing
	jmp	gunext
guread:
	xor	si,si
	mov	cx,[hfoff]		; get high file offset
	mov	dx,[lfoff]		; get low file offset
	mov	ah,42h			; move handle  (42h)
	xor	al,al			; from start
	int	21h
	push	ds
	assume	ds:dataseg
	mov	cx,[copysize]
	push	es
	push	di
	mov	es,[copyseg]
	xor	di,di
	xor	al,al
	cld
	rep	stosb			; zap memory memory before reading
	pop	di
	pop	es
	mov	cx,[copysize]
	mov	ah,3fh			; read handle  (3fh)
	xor	dx,dx			; start of buffer
	mov	ds,[copyseg]
	int	21h
	pop	ds
	jnc	guset
gubend:
	xor	si,si
	mov	al,1			; indicate bad user
	jmp	gudone
guset:
	push	cx
	push	si
	push	di
	push	ds
	push	es
	xor	si,si
	xor	di,di
	mov	cx,[copysize]
	mov	ax,[copyseg]
	mov	ds,ax
	mov	es,ax
gulp1:
	lodsb
	cmp	al,'a'
	jb	gulp2
	cmp	al,'z'
	ja	gulp2
	sub	al,'a'
	add	al,'A'
gulp2:
	stosb
	loop	gulp1
	pop	es
	pop	ds
	assume ds:dataseg,es:dataseg
	pop	di
	pop	si
	pop	cx

; check buffer for user information

guchk:
	push	si
	mov	es,[copyseg]
	assume	es:nothing
gu1:
	cmp	si,[copysize]
	jae	gu2
	cmp	word ptr es:[si],0
	jne	gu1a
	pop	si
	xor	si,si			; end-of-buffer
	mov	al,1			; indicate bad user
	jmp	gudone
gu1a:
	cmp	word ptr es:[si],0a0dh
	je	gu2
	inc	si
	jmp	short gu1
gu2:
	mov	ax,si			; save endpoint
	pop	si
	cmp	ax,[copysize]
	jb	gu3			; below buffer size
	mov	ax,si
	assume	ds:csignons
	add	[lfoff],ax		; update file pointer
	adc	[hfoff],0000h
	jmp	guread
gu3:
	mov	al,byte ptr es:[si]
	inc	si
	cmp	al,' '			; just incase of leading spaces
	je	gu3
	dec	si
	cmp	al,'*'			; comment!
	jne	gufound

;****** jump to end of line ******

gunext:
	cmp	word ptr es:[si],0a0dh
	je	gu4
	inc	si
	jmp	short gunext
gu4:
	inc	si
	inc	si
	jmp	guchk			; next....

; we got it

gufound:
	mov	al,byte ptr es:[si]
	inc	si
	cmp	al,' '
	je	gufound
	dec	si
	push	si
	xor	cx,cx
gu5:
	mov	al,byte ptr es:[si]
	inc	si
	cmp	al,' '
	je	gu5
	cmp	al,','
	je	gu6
	inc	cx
	jmp	short gu5
gu6:
	pop	si
	mov	al,cl
gudone:
	xchg	si,di
	pop	es
	assume	es:dataseg
	pop	dx
	pop	cx
	pop	bx
	ret
getuser endp

	page
;-----------------------------------------------------------------------
;	function:   chkuser
;		    check user file with user & passord from parm1&2
;		    and error code in ah
;	input:
;	output:
;		al = default class
;		ah = error code
;			0 -  no errors
;			1 -  invalid password
;			2 -  invalid user id
;			3 -  user file not found
;-----------------------------------------------------------------------
	assume	ds:dataseg,es:dataseg
chkuser proc	near
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	es
	push	ds
	mov	bp,ds			; save a copy of ds in bp
	assume	ds:csignons
	xor	ax,ax
	mov	[hfoff],ax
	mov	[lfoff],ax
	push	ds
	push	es
	mov	ah,02h
	call	sim38			; sah simulate int 38 call
	assume	es:newscb
	mov	dx,bx
	add	dx,offset [scbusrf]
	push	es
	pop	ds
	assume	ds:newscb
	mov	ax,3da0h		; open handle	3da0h
cuopen:
	int	21h
	pop	es
	pop	ds
	assume	ds:csignons,es:dataseg
	jnc	cu1
cuabort:
	mov	ah,3
	jmp	cudone
cu1:
	mov	bx,ax			; save handle
	xor	cx,cx
	mov	cl,[len1]
	lea	si,[parm1]		; set to user enter userid
	xor	di,di
cu2:
	call	getuser
	or	di,di
	jnz	cu3
	mov	ah,2			; no more users - invalid user id
	jmp	cuclose
cu3:
	cmp	cl,al			; same user lenght
	jne	cu2			; no ... next
	push	cx
	push	si
	assume	ds:dataseg
	mov	es,[copyseg]
	assume	es:nothing
	rep	cmpsb			; test for user
	pop	si
	pop	cx
	jnz	cu2
cu4:
	mov	al,byte ptr es:[di]
	cmp	al,','			; comma???
	je	cu5
	cmp	al,' '			; space
	jne	cu6
cu5:
	inc	di
	jmp	short cu4
cu6:
	xor	cx,cx
	mov	si,di
cu7:
	mov	al,byte ptr es:[si]
	inc	si
	cmp	al,','			; comma???
	je	cu8
	cmp	al,' '			; space
	je	cu8
	inc	cx
	cmp	cx,6
	jb	cu7
cu8:
	mov	dx,di			; save password position for later
	assume	ds:csignons
	lea	si,[parm2]
	or	cl,cl			; sah signon bug fix
	ljz	cu9			; sah
	cmp	cl,[len2]		; sah
	ljnz	cu9			; sah
	rep	cmpsb
	jz	goodpw
	jmp	cu9

; good password

goodpw:
	assume	ds:dataseg
	resflg	[signfix1]
	push	es
	mov	ax,[tcbseg]
	mov	es,ax
	assume	ds:csignons,es:tcb
	lea	di,tcbuser
	mov	ax,2020h
	stosw
	stosw
	lea	di,tcbuser
	lea	si,parm1
	mov	cl,[len1]
	xor	ch,ch
	rep	movsb			; save user
	push	bx
	mov	si,dx
	assume	ds:dataseg
	mov	ds,[copyseg]
	assume	ds:nothing
gploopa:
	lodsb
	cmp	al,','
	jne	gploopa
	mov	cx,26
gploop:
	push	cx
	mov	bx,26
	sub	bx,cx
	mov	cx,bx
	shr	bx,1
	shr	bx,1			; divide by 4 since 4 class per byte
	and	cl,3			; 0, 1, 2, 3
	shl	cl,1			; 0, 2, 4, 6
gploop1:
	lodsb
	cmp	al,' '			; skip spaces
	je	gploop1
	cmp	al,'0'			; below '0' means bad file...
	jb	gpbad
	cmp	al,'3'			; above '3' means bad file...
	ja	gpbad
	sub	al,'0'
	mov	ah,11111100b		; set and mask
	rol	ah,cl			; rotate mask into position
	shl	al,cl			; shift value into position
	and	byte ptr es:[bx+tcbcmap],ah
	or	byte ptr es:[bx+tcbcmap],al
	pop	cx
	loop	gploop
gploop2:
	lodsb
	cmp	al,' '			; skip over spaces
	je	gploop2
	cmp	al,','			; skip over commas
	je	gploop2
	mov	byte ptr es:[tcbcdft],' '
	cmp	al,0dh
	je	gpspace
	cmp	al,0ah
	je	gpspace
	or	al,al
	jz	gpspace
	cmp	al,26
	je	gpspace
	cmp	al,'A'
	jb	gpbad2			; bad
	cmp	al,'Z'
	ja	gpbad2
	jmp	short gpother
gpspace:
	mov	al,' '
gpother:
	mov	es:[tcbcdft],al
	pop	bx
	pop	es
	assume	es:dataseg
	xor	ah,ah
	jmp	short cuclose
gpbad:
	pop	cx
gpbad2:
	pop	bx
	pop	es
	assume	es:dataseg
	mov	ah,3			;jsm 8/3/87
	jmp	short cuclose		;jsm 8/3/87
cu9:
	mov	ah,1			; invalid password???
cuclose:
	push	ax
	mov	ah,3eh			;jsm 8/3/87 close handle	 3eh
	int	21h
	pop	ax
cudone:
	pop	es
	pop	ds
	assume	es:dataseg,ds:dataseg
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	ret
chkuser endp



;-----------------------------------------------------------------------;
; 			SWITCH						;
;-----------------------------------------------------------------------;

	assume	ds:DATASEG,es:DATASEG

Cswitch:
	push 	es
	True?	[NullParm]
	je	csw2
	lea	si,[ParmBuf]
	call 	PassDelims	; like it says	
	mov	bx,si	
	call	DECTOBIN	; convert it to binary
	xor	ah,ah
	
csw1:
	push	ax
	mov	bx,ax
	mov	ah,04h		; verified that task exists
	call	sim38		; SAH simulate INT 38 call
	pop	ax
	jnc	csw3
	call	DispEOL
	mov	al,37		; bad task error
	call	ReportError
	jmp	csw4

csw2:
	mov	es,[TcbSeg]
	assume  es:tcb
csw2a:
	mov	ax,[TCBTCBPN]	; get next TCB available
	or	ax,ax
	jnz	csw2b
	mov 	ah,2		; SAH get SCB
	call	sim38		; SAH simulate int 38 call
	assume  es:NEWSCB
	mov	ax,[BX+SCBTCBPF]	; SAH get first TCB
csw2b:		
	mov	es,ax
	assume  es:tcb
	mov	ax,[TCBID]
	push	es
	mov	es,[TcbSeg]
	cmp	ax,[TCBID]
	pop	es
	je	csw4
	cmp	[TCBPAM],'N'
	je	csw2a
csw3:
	push	ax
	mov	ax,es		; SAH check to see if trying to switch
	cmp	ax,[TcbSeg]	; SAH to same task
	pop	ax
	je	csw4		; SAH if so skip the following...not needed
	mov	es,[TcbSeg]
	assume  es:tcb
	cmp	[TCBPAM],'N'	; SAH check to see if PAM switching is on
	je	csw4		; SAH no...so skip
	mov	[TCBSWITCH],AL	; set switch value
	mov	[TCBSWFLG],'Y'	; set switch flag

csw4:
	pop	es
	jmp	CMFL

CODESEG ENDS
	    END PlsStart

