	page	95,132

;--------------------------------------------------------------------;
;	CD-Link INSTALL Utility					     ;
;--------------------------------------------------------------------;

jmpa	macro	target
	local	nojump
	jna	nojump
	jmp	target
nojump:
	endm

jmpc	macro	target
	local	nojump
	jnc	nojump
	jmp	target
nojump:
	endm

;====================================================================;
;                         Code Segment                               ;
;====================================================================;

codeseg	segment	para
	assume	cs:codeseg,ds:dataseg,ss:stakseg

;------ Entry Logic -------------------------------------------------;

begin	label	near

	mov	ax,offset codeend	; point ds to data segment
	mov	cl,4
	shr	ax,cl
	mov	dx,cs
	add	ax,dx
	mov	ds,ax
	assume	ds:dataseg

;------ Determine video type and adjust accordingly -----------------;

	int	11h			; get equipment flags
	and	al,00110000b
	mov	ah,byte ptr es:[005dh]	; command-line parameter
	cmp	ah,'B'			; B&W forced from command line?
	je	BandW			; yes, skip
	cmp	ah,'C'			; color forced from command line?
	je	Color			; yes, skip
	cmp	al,00110000b		; 11 indicates monochrome
	je	BandW
Color:
	mov	[wpVideoRAM],0b800h
	cmp	ah,'M'			; mono monitor indicated?
	je	BandW			; yes, skip
	mov	[bColorBar],30h		; black on cyan
	mov	[bColorText],0ah	; light green on black
	mov	[bColorNoSel],07h	; grey on black
	mov	[bColorSel],4fh		; white on red
BandW:

;------ Allocate Document Buffer ------------------------------------;

	mov	bx,sp			; compute new size to shrink to
	add	bx,15
	shr	bx,cl
	mov	ax,ss
	add	bx,ax
	mov	ax,es
	sub	bx,ax
	mov	ah,4ah			; do the shrink
	int	21h

	mov	ah,48h			; now allocate 64K for document buffer
	mov	bx,1000h
	int	21h
	jmpc	termn8			; abort if insufficient memory
	mov	[wpDocumentBuffer],ax

;------ Initialize the screen ---------------------------------------;

	call	cursoff			; turn off the cursor
	call	clrscrn			; clear the screen

;------ Determine if they really want to run this program -----------;

proc1a:
	call	clrtext
	mov	bx,offset txt01a	; write introductory text
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scr1		; continue 
	call	doscrn
	jc	proc1a			; ESC key hit
proc1b:
	call	clrtext
	mov	bx,offset txt01b	; write more text
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scr1		; continue
	call	doscrn
	jc	proc1a

;------ Present Main Menu -------------------------------------------;

proc2	label	near

	call	clrtext
	mov	bx,offset scrMain
	call	doscrn
	jc	proc1b
	cbw
	shl	ax,1
	mov	bx,ax
	jmp	cs:[MenuTable-6+bx]

	even
MenuTable label word
	dw	DisplayLicense
	dw	PrintLicense
	dw	DisplayManual
	dw	PrintManual
	dw	Configure
	dw	Order
	dw	TechSupport
	dw	termn8

;------ Display License Agreement -----------------------------------;

DisplayLicense label near

	call	clrscrn			; clear the screen
	mov	bx,offset scrLicense	; display screen header
	call	doscrn
	lea	dx,[sLicenseName]
	jmp	DisplayDocument

;------ Display Manual ----------------------------------------------;

DisplayManual label near

	call	clrscrn			; clear the screen
	mov	bx,offset scrManual	; display screen header
	call	doscrn
	lea	dx,[sManualName]
	jmp	DisplayDocument

;------ Print License Agreement -------------------------------------;

PrintLicense label near
	lea	dx,[sLicenseName]
	jmp	PrintDocument

;------ Print Manual ------------------------------------------------;

PrintManual label near
	lea	dx,[sManualName]
	jmp	PrintDocument

;------ Configure CD-Link -------------------------------------------;

Configure label near
	call	clrscrn			; clear the screen
	mov	bx,offset scrConfig	; display screen header
	call	doscrn

;	Ask if they accept the license agreement

	call	clrtext
	mov	bx,offset txtAgree	; ask if they agree to LULA
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrYesNo	; yes or no
	call	doscrn
	jmpc	proc2			; ESC key hit
	cmp	al,1			; did they select Yes?
	je	ConfigAgreed

;	They rejected the license agreement

	call	clrtext
	mov	bx,offset txtNoAgree	; tell them no dice
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrCancel
	call	doscrn
	jc	Configure		; ESC key hit, go ask again
	jmp	proc2			; otherwise to main menu

;	Introductory screen for configuration

ConfigAgreed:
	call	clrtext
	mov	bx,offset txtConfigIntro ; write introductory text
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrCont	; continue 
	call	doscrn
	jc	Configure		; ESC key hit

;	Get hardware driver device name

ConfigDevName:
	call	clrtext
	mov	bx,offset txtDevName	; explain request for device name
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrDevName
	call	doscrn
	jc	ConfigAgreed

;	Get cache file name

ConfigCFName:
	call	clrtext
	mov	bx,offset txtCFName	; explain request for cache file name
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrCFName
	call	doscrn
	jc	ConfigDevName

;	Get cache file size

ConfigCFSize:
	call	clrtext
	mov	bx,offset txtCFSize	; explain request for cache file size
	mov	dh,2			; starting line number
	call	wtext
ConfigCFSizeRetry:
	mov	bx,offset scrCFSize
	call	doscrn
	jc	ConfigCFName
	lea	bx,[datCFSize+2]	; convert size to binary
	call	DecToBin
	cmp	dl,20h			; following character should be blank
	jne	ConfigCFSizeError
	cmp	ax,42			; enforce maximum value
	jae	ConfigCFSizeOK
ConfigCFSizeError:
	mov	bx,offset txtNumericError ; tell them garbage was input
	mov	dh,22			; starting line number
	call	wtext
	jmp	ConfigCFSizeRetry
ConfigCFSizeOK:

;	Get number of drives

ConfigDrives:
	call	clrtext
	mov	bx,offset txtDrives	; explain request for number of drives
	mov	dh,2			; starting line number
	call	wtext
ConfigDrivesRetry:
	mov	bx,offset scrDrives
	call	doscrn
	jc	ConfigCFSize
	lea	bx,[datDrives+2]	; convert to binary
	call	DecToBin
	cmp	dl,20h			; following character should be blank
	jne	ConfigDrivesError
	cmp	ax,1			; enforce minimum value
	jb	ConfigDrivesError
	cmp	ax,24			; enforce maximum value
	jbe	ConfigDrivesOK
ConfigDrivesError:
	mov	bx,offset txtNumericError ; tell them garbage was input
	mov	dh,22			; starting line number
	call	wtext
	jmp	ConfigDrivesRetry
ConfigDrivesOK:

;	Build the DEVICE command line

	mov	ah,19h			; get current drive
	int	21h
	add	al,'A'
	mov	[sOutput+7],al

	mov	ah,47h			; get current directory
	mov	dl,0			; of current drive
	lea	si,[sOutput+10]
	int	21h

	cld
	push	ds
	pop	es
	lea	di,[sOutput]
FindEnd:
	inc	di
	cmp	byte ptr ds:[di],20h
	ja	FindEnd

	mov	al,'\'
	stosb
	lea	si,[sDriverName]
	call	CopyString

	mov	al,' '
	stosb
	mov	ax,'=D'
	stosw
	lea	si,[datDevName+2]
	call	CopyString

	mov	al,' '
	stosb
	mov	ax,'=C'
	stosw
	lea	si,[datCFName+2]
	call	CopyString

	mov	al,' '
	stosb
	mov	ax,'=K'
	stosw
	lea	si,[datCFSize+2]
	call	CopyString

	mov	al,' '
	stosb
	mov	ax,'=N'
	stosw
	lea	si,[datDrives+2]
	call	CopyString

	mov	ax,di
	sub	ax,offset sOutput
	mov	[wOutputLength],ax
	mov	al,'@'
	mov	ah,0
	stosw

;	Show them the command line

	call	clrtext
	mov	bx,offset txtConfigResult ; write explanation
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset sOutput	; display command that we built
	mov	dh,6			; starting line number
	call	wtext
	mov	bx,offset scrCont	; continue 
	call	doscrn
	jmpc	ConfigDrives		; ESC key hit

	jmp	proc2

CopyString proc near
	lodsb
	cmp	al,20h
	jbe	CSExit
	stosb
	jmp	CopyString
CSExit:
	ret
CopyString endp

;------ Order the Real Thing ----------------------------------------;

Order	label	near
	call	clrscrn			; clear the screen
	mov	bx,offset scrOrder	; display screen header
	call	doscrn

;	Ask if they accept the license agreement

	call	clrtext
	mov	bx,offset txtAgree	; ask if they agree to LULA
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrYesNo	; yes or no
	call	doscrn
	jmpc	proc2			; ESC key hit
	cmp	al,1			; did they select Yes?
	je	OrderAgreed

;	They rejected the license agreement

	call	clrtext
	mov	bx,offset txtNoAgree	; tell them no dice
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrCancel
	call	doscrn
	jc	Order			; ESC key hit, go ask again
	jmp	proc2			; otherwise to main menu

;	Introductory screen for serialization

OrderAgreed:
	call	clrtext
	mov	bx,offset txtOrderIntro ; write introductory text
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrCont	; continue 
	call	doscrn
	jc	Order			; ESC key hit
	
	lea	dx,[sDriverName]	; load the file into memory
	call	LoadFile
	jmpc	proc2			; if error, return to main menu

;	Get the serial number

OrderSerNo:
	call	clrtext
	mov	bx,offset txtSerNo	; explain request for serial number
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrSerNo
	call	doscrn
	jc	OrderAgreed

;------ Scan to get serial number location --------------------------;

	mov	es,[wpDocumentBuffer]
	xor	di,di
	cld
ScanResume:
	cmp	di,[wDocumentSize]
	jae	ScanError
	lea	si,[sScanData]
	inc	di
	mov	bx,di
ScanNext:
	lodsb
	cmp	al,'@'
	je	ScanDone
	cmp	al,es:[bx]
	jne	ScanResume
	inc	bx
	jmp	ScanNext
ScanError:
	mov	bx,offset txtIOError	; unexpected error occurred
	mov	dh,2
	call	wtext
	mov	bx,offset scrCancel	; must cancel this request
	call	doscrn
	jmp	proc2
ScanDone:
	sub	di,17			; point di to serial number location

;------ Insert serial number ----------------------------------------;

	lea	si,[datSerNo+2]
	mov	cx,15
	rep	movsb

;------ Write the modified driver back to disk ----------------------;

	lea	dx,[sDriverName]	; load the file into memory
	mov	ax,3d02h		; open for i/o
	int	21h
	jc	ScanError
	mov	bx,ax
	mov	ah,40h			; write it
	mov	cx,[wDocumentSize]	; the whole thing
	xor	dx,dx
	push	ds
	mov	ds,[wpDocumentBuffer]
	int	21h
	pop	ds
	jc	ScanError
	mov	ah,3eh			; close the handle
	int	21h
	jc	ScanError

;	Tell them it worked

	call	clrtext
	mov	bx,offset txtOrderDone	; write introductory text
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrCont	; continue 
	call	doscrn
	jmp	proc2			; back to main menu

;------ Technical Support -------------------------------------------;

TechSupport label near
	call	clrtext
	mov	bx,offset scrSupport	; display screen header
	call	doscrn
	mov	bx,offset txtSupportIntro ; write introductory text
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrCont	; continue 
	call	doscrn
	jmp	proc2			; return to main menu

;------ Logic to display a document ---------------------------------;

DisplayDocument label near

	call	LoadFile		; load the file to memory
	jmpc	proc2			; if error, return to main menu

	mov	[wDocumentIndex],0
DDocLoop:
	call	DocDisplay		; write a screenful
	mov	ah,0			; get a key
	int	16h
	cmp	al,1bh			; Esc
	je	ClearToMain
	cmp	ax,5000h		; cursor down
	je	DDocCurDown
	cmp	ax,4800h		; cursor up
	je	DDocCurUp
	cmp	ax,5100h		; page down
	je	DDocPageDown
	cmp	ax,4900h		; page up
	je	DDocPageUp
	jmp	DDocLoop
ClearToMain:
	jmp	proc2

DDocCurDown:
	call	NextDocLine
	jmp	DDocLoop

DDocCurUp:
	call	PrevDocLine
	jmp	DDocLoop

DDocPageDown:
	mov	cx,23
DDPDLoop:
	push	cx
	call	NextDocLine
	pop	cx
	loop	DDPDLoop
	jmp	DDocLoop

DDocPageUp:
	mov	cx,23
DDPULoop:
	push	cx
	call	PrevDocLine
	pop	cx
	loop	DDPULoop
	jmp	DDocLoop

;------ Subroutine to load a file into memory -----------------------;

LoadFile proc	near
	mov	ax,3d00h		; open for input
	int	21h
	jc	LFOpenError
	mov	bx,ax
	mov	ah,3fh			; read it
	mov	cx,-1			; the whole thing (65535 bytes max)
	xor	dx,dx
	push	ds
	mov	ds,[wpDocumentBuffer]
	int	21h
	pop	ds
	jc	LFReadError
	mov	[wDocumentSize],ax
	mov	ah,3eh			; close the handle
	int	21h
	clc				; normal completion
	ret
LFOpenError:
	call	clrtext
	mov	bx,offset txtNoDocument	; write error explanation
	mov	dh,2			; starting line number
	call	wtext
	jmp	LFCancel
LFReadError:
	mov	bx,offset txtIOError	; write error explanation
	mov	dh,2			; starting line number
	call	wtext
LFCancel:
	mov	bx,offset scrCancel	; must cancel this request
	call	doscrn
	stc				; error completion
	ret
LoadFile endp

;------ Subroutine to display a screenful of document text ----------;

DocDisplay proc near

	mov	cx,0100h
	mov	dx,174fh
	mov	ax,0600h		; clear lines 2-24
	mov	bh,[bColorText]
	int	10h

	mov	dx,0100h		; starting line/column number
	mov	es,[wpDocumentBuffer]
	mov	di,[wDocumentIndex]
	cld
DDLoop:
	cmp	di,[wDocumentSize]
	jae	DDSkip2
	mov	bx,di			; start address of next line
	mov	al,0dh			; scan for c/r
	mov	cx,255
	repne	scasb
	lea	cx,[di-1]		; length in cx
	sub	cx,bx
	jz	DDSkip1
	mov	bp,bx			; display string at es:bp
	mov	bl,[bColorText]		; attribute
	call	DisplayLine
DDSkip1:
	cmp	byte ptr es:[di],0ah
	jne	DDSkip2
	inc	di
DDSkip2:
	inc	dh			; bump line number
	cmp	dh,23
	jbe	DDLoop
	ret

DocDisplay endp

NextDocLine proc near
	mov	es,[wpDocumentBuffer]
	mov	di,[wDocumentIndex]
	cld
NDLLoop:
	cmp	di,[wDocumentSize]
	jae	NDLRet
	mov	al,0dh			; scan for c/r
	mov	cx,255
	repne	scasb
	cmp	byte ptr es:[di],0ah
	jne	NDLRet
	inc	di
NDLRet:
	mov	[wDocumentIndex],di
	ret
NextDocLine endp

PrevDocLine proc near
	mov	es,[wpDocumentBuffer]
	mov	di,[wDocumentIndex]
	sub	di,3
	jc	PDLRet
	std
PDLLoop:
	mov	al,0dh			; scan for c/r
	mov	cx,di
	jcxz	PDLExit
	repne	scasb
	jne	PDLExit
	add	di,3
PDLExit:
	mov	[wDocumentIndex],di
PDLRet:
	cld
	ret
PrevDocLine endp

;------ Logic to print a document -----------------------------------;

PrintDocument label near

	push	dx
	call	clrscrn			; clear the screen
	mov	bx,offset scrPrint	; display screen header
	call	doscrn
	pop	dx

	call	LoadFile		; load the document into memory
	jmpc	proc2			; if error, return to main menu

	mov	es,[wpDocumentBuffer]	; append a form feed
	mov	di,[wDocumentSize]
	mov	byte ptr es:[di],0ch
	inc	[wDocumentSize]

	mov	[wDocumentIndex],0

	mov	bx,offset txtPrint	; display instructions
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrLPT	; choose a print device
	call	doscrn
	jmpc	ClearToMain		; ESC key hit

	or	al,'0'			; make the digit
	mov	[sPrintName+3],al

	mov	ax,3d01h		; open for output
	lea	dx,[sPrintName]
	int	21h
	jc	PrintError
	mov	bx,ax

	mov	ah,40h			; print the thing
	mov	cx,[wDocumentSize]
	xor	dx,dx
	push	ds
	mov	ds,[wpDocumentBuffer]
	int	21h
	pop	ds

	mov	ah,3eh			; close the printer
	int	21h
	jmp	proc2

PrintError label near
	mov	bx,offset txtNoPrinter	; write error explanation
	mov	dh,2			; starting line number
	call	wtext
	mov	bx,offset scrCancel	; must cancel this request
	call	doscrn
	jmp	proc2

;--------------------------------------------------------------------;

abort:
termn8:
	call	clrscrn			; erase the display
	call	curson			; restore cursor type
	mov	ax,4c00h		; terminate to MOS
	int	21h

clrstr	proc	near
	push	ds
	pop	es
	mov	al,' '
	cld
	rep	stosb
	ret
clrstr	endp

;--------------------------------------------------------------------;
;                     Clear-Screen Subroutine                        ;
;--------------------------------------------------------------------;

clrscrn	proc	near
	mov	cx,0000h
	mov	dx,184fh
	mov	bh,07h
	jmp	short clrsgo
clrtext:
	mov	cx,0100h		; upper left corner
	mov	dx,174fh		; lower right corner
	mov	bh,[bColorText]
clrsgo:
	mov	ax,0600h		; clear the window
	int	10h
	ret
clrscrn	endp

;--------------------------------------------------------------------;
;                       Cursor Off Subroutine                        ;
;--------------------------------------------------------------------;

cursoff	proc	near
	cmp	word ptr [origct],-1	; skip if already off
	jne	cursofx
	push	es
	push	cx
	push	ax
	xor	ax,ax
	mov	es,ax
	mov	ax,es:[460h]		; save cursor type
	mov	[origct],ax
	mov	ah,01h			; set new cursor type
	mov	cx,0f00h
	int	10h
	pop	ax
	pop	cx
	pop	es
cursofx:
	ret
cursoff	endp

;--------------------------------------------------------------------;
;                       Cursor On Subroutine                         ;
;--------------------------------------------------------------------;

curson	proc	near
	cmp	word ptr [origct],-1	; skip if already on
	je	cursonx
	push	cx
	push	ax
	mov	ah,01h			; set cursor type to original
	mov	cx,[origct]
	mov	word ptr [origct],-1
	int	10h
	pop	ax
	pop	cx
cursonx:
	ret
curson	endp

;--------------------------------------------------------------------;
;                      Write Text Subroutine                         ;
;--------------------------------------------------------------------;

wtext	proc	near
	cld
	push	ds
	pop	es
	mov	dl,4			; starting column number
	mov	di,bx
wtloop:
	mov	bx,di			; start address of next line
	mov	al,'@'			; scan for "at" sign
	mov	cx,73
	repne	scasb
	lea	cx,[di-1]		; length in cx
	sub	cx,bx
	jz	wtskip
	mov	bp,bx			; es:bp points to it
	mov	bl,[bColorText]		; attribute
	call	DisplayLine
wtskip:
	inc	dh			; bump line number
	cmp	byte ptr [di],0		; check for end of data
	jne	wtloop
	ret
wtext	endp

;--------------------------------------------------------------------;
;                        Process a Screen                            ;
;--------------------------------------------------------------------;
;  Input:  BX = pointer to the desired screen table                  ;
;  Output: AL = 0 (and Carry set) if Esc key was pressed, otherwise  ;
;               is field number of selected field (Enter pressed)    ;
;          SI = address of selected field                            ;
;--------------------------------------------------------------------;

doscrn	proc	near
	mov	si,bx			; bx->screen, si->field

;	Display all fields for this screen

	add	si,2
dosnxf:
	mov	al,ds:[si+1]		; al is the attribute
	call	dispfld			; display the field
	add	si,8			; address next field
	cmp	si,ds:[bx]		; end of screen?
	jb	dosnxf			; no, do next field

;	Locate first selectable or input field

	lea	si,[bx+2]		; address first field
doslf:
	cmp	byte ptr [si],01h
	ja	dosdsf
	add	si,8
	cmp	si,word ptr [bx]
	jb	doslf
	clc
	jmp	dosexit

;	Display "selected" field

dosdsf:
	mov	al,3			; attribute = bColorSel
	call	dispfld			; write it
	cmp	byte ptr [si],03h	; input field?
	jne	dosgkey			; no, jump

;	Input field - set cursor position

	push	bx
	mov	bx,[si+4]		; address the field
	mov	di,[bx]			; di is offset
doslclp:
	cmp	byte ptr [bx+di+1],20h	; is preceding char a blank?
	jne	doslcd			; no, we're done
	dec	di
	jnz	doslclp
doslcd:
	mov	[curoff],di		; save offset
	mov	dx,di			; compute location for cursor
	mov	dh,byte ptr [si+2]
	add	dl,byte ptr [si+3]
	sub	dx,0101h
	mov	ah,2
	mov	bh,0
	int	10h
	call	curson
	pop	bx

;	Get a keystroke

dosgkey:
	mov	ah,0			; get a key
	int	16h
	cmp	al,'a'			; convert it to upper case
	jb	dosgotk
	cmp	al,'z'
	ja	dosgotk
	sub	al,'a'-'A'
dosgotk:

;	Handle Esc key

	cmp	al,1bh			; Esc hit?
	jne	dosgnes
	xor	ax,ax			; yes, return al=0
	stc				; and carry set
	jmp	dosexit
dosgnes:

;	Handle Cursor Down key

	cmp	ax,5000h		; cursor down?
	jne	dosgncd
	mov	al,2			; attribute = bColorNoSel
	call	dispfld
dosglcd:
	add	si,8			; find next selectable field
	cmp	si,word ptr [bx]
	jb	dosgsk1
	lea	si,[bx+2]
dosgsk1:
	cmp	byte ptr [si],01h
	jbe	dosglcd
	jmp	dosdsf			; redisplay new field
dosgncd:

;	Handle Cursor Up key

	cmp	ax,4800h		; cursor up?
	jne	dosgncu
	mov	al,2			; attribute = bColorNoSel
	call	dispfld
dosglcu:
	sub	si,8			; find previous selectable field
	cmp	si,bx
	ja	dosgsk2
	mov	si,word ptr [bx]
	sub	si,8
dosgsk2:
	cmp	byte ptr [si],01h	; loop if not selectable
	jbe	dosglcu
	jmp	dosdsf			; redisplay new field
dosgncu:

;	Handle Enter key

	cmp	al,0dh			; Enter key?
	jne	dosgnen			; no, jump
	lea	ax,[si+8-2]		; yes, compute field number in al
	sub	ax,bx
	mov	cl,3
	shr	ax,cl
	clc
	jmp	dosexit
dosgnen:

;	Begin processing for an input field

	cmp	byte ptr [si],03h	; input field?
	jne	jdosgkey		; no, ignore the key

;	Handle Backspace key

	cmp	ax,4b00h		; treat left arrow same as backspace
	je	dosgbs
	cmp	al,08h			; check if backspace
	jne	dosgnbs			; no, skip
dosgbs:
	mov	dx,[curoff]		; get cursor displacement in field
	or	dx,dx			; cursor already at start?
	jz	dosgkey			; yes, ignore the key
	mov	di,[si+4]
	add	di,dx
	mov	byte ptr [di+1]," "	; erase byte preceding cursor
	dec	word ptr [curoff]
	mov	ax,0e08h		; write a backspace
	int	10h
	mov	ax,0e20h		; write a space
	int	10h
	mov	ax,0e08h		; write a backspace
	jmp	doswcts
dosgnbs:

;	Handle other characters

	cmp	al,20h			; ignore if not printable
	jb	jdosgkey
	mov	dx,[curoff]
	mov	di,[si+4]
	cmp	dx,[di]			; ignore if already full
	jae	jdosgkey
	add	di,dx
	mov	byte ptr [di+2],al	; save the character
	inc	word ptr [curoff]
doswcts:
	mov	ah,0eh			; write TTY
	int	10h
jdosgkey:
	jmp	dosgkey
dosexit:
	pushf
	call	cursoff
	popf
	ret
doscrn	endp

;--------------------------------------------------------------------;
;                        Display a Field                             ;
;--------------------------------------------------------------------;
;  Input:  SI = pointer to the desired screen table field entry      ;
;          AL = desired display attribute                            ;
;--------------------------------------------------------------------;

dispfld	proc	near
	push	bx
	mov	bl,al			; get real attribute in bl
	mov	bh,0
	mov	bl,[bColorTable+bx]
	push	si			; save field pointer
	mov	si,ds:[si+4]
	mov	cx,ds:[si]		; cx is string length
	lea	bp,[si+2]
	pop	si
	push	ds			; es:bp points to string
	pop	es
	mov	dx,ds:[si+2]		; specify screen position
	xchg	dl,dh
	sub	dx,0101h
	call	DisplayLine
	pop	bx
	ret
dispfld	endp

;------ Emulate BIOS Int 10h function 13h (write string) ------------;
;
;       This is not a robust emulation, but it's fast and does
;	what we need.

DisplayLine proc near
	jcxz	DLineRet

	push	es
	push	ds
	push	di
	push	si
	push	dx
	push	cx

	push	es
	mov	es,[wpVideoRAM]
	pop	ds

	mov	al,80			; compute target address to es:di
	mul	dh
	mov	dh,0
	add	ax,dx
	add	ax,ax
	mov	di,ax

	mov	si,bp			; source address
	mov	ah,bl			; attribute
	cld
DLineLoop:
	lodsb
	cmp	al,0ah
	jbe	DLineControl
	stosw
DLineCont:
	loop	DLineLoop

	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	ds
	pop	es
DLineRet:
	ret
DLineControl:
	jne	DLineBackspace
	add	di,160
	jmp	DLineCont
DLineBackspace:
	sub	di,2
	jmp	DLineCont
DisplayLine endp

;--------------------- Decimal-to-Binary Routine --------------------;

dectobin proc	near
	xor	ax,ax			; AX will contain the result
	dec	bx			; BX is source address
dtbloop1:
	inc	bx			; skip any leading spaces
	cmp	byte ptr [bx],20h
	je	dtbloop1
dtbloop2:
 	mov	dl,[bx]
	cmp	dl,'0'
	jb	dtbwrap
	cmp	dl,'9'
	ja	dtbwrap
	push	dx
	mul	word ptr [wordten]
	pop	dx
	and	dx,000fh
	add	ax,dx
	inc	bx
	jmp	dtbloop2
dtbwrap:
	ret
dectobin endp

;--------------------- Binary-to-Decimal Routine --------------------;

bintodec proc	near			; AX is the binary number
	mov	ch,0			; CL is length of output field
	add	bx,cx			; BX is address of output field
btdloop:
	dec	bx
	xor	dx,dx
	div	[wordten]
	add	dl,'0'
	mov	[bx],dl
	loop	btdloop
	ret
bintodec endp

;--------------------------------------------------------------------;

	org	($+15-codeseg)/16*16
codeend	label	byte
codeseg	ends

	page

;====================================================================;
;                         Data Segment                               ;
;====================================================================;

dataseg	segment	para

;--------------------------------------------------------------------;
;              Variables specific to this application                ;
;--------------------------------------------------------------------;

wpDocumentBuffer dw	0
wDocumentSize	dw	0
wDocumentIndex	dw	0
wOutputLength	dw	0			; length of sOutput
sLicenseName	db	'LICENSE.DOC',0
sManualName	db	'CDLINK.DOC',0
sDriverName	db	'CDLINK.SYS',0
sPrintName	db	'LPT1',0
sOutput		db	'DEVICE=C:\',150 DUP(' ')
sScanData	db	'Copyright@'

;--------------------------------------------------------------------;
;               Miscellaneous variables and constants                ;
;--------------------------------------------------------------------;

wpVideoRAM dw	0b000h			; segment address of video RAM
wordten	dw	10
origct	dw	-1			; original cursor type
curoff	dw	0			; offset of cursor within input field

bColorTable	label	byte
bColorBar	db	70h		; menu bar
bColorText	db	07h		; normal text
bColorNoSel	db	07h		; unselected selectable field
bColorSel	db	70h		; selected selectable field

;--------------------------------------------------------------------;
;                     Screen Generation Data                         ;
;--------------------------------------------------------------------;

txt01a	label	byte
 db 'Welcome to the CD-Link Administrator!  This serves as your User''s Guide,@'
 db '"Getting Started" booklet, License Agreement, etc., that would otherwise@'
 db 'have to be on paper.  From the main menu, you will be able to do any of@'
 db 'the following:@'
 db '@'
 db '  > View or print the CD-Link Limited Use License Agreement@'
 db '  > View or print the CD-Link User''s Guide@'
 db '  > Configure CD-Link for use on this computer@'
 db '  > Serialize CD-Link for unrestricted use@'
 db '  > Get information about technical support@'
 db '@'
 db 'To make a selection, you will use the up or down arrow key to select the@'
 db 'desired item, and then press Enter to confirm.  If you decide that you@'
 db 'need to go back to a previous screen, use the Esc key.@'
 db '@'
 db 'Press Enter to continue.@'
 db 0

txt01b	label	byte
 db 'Your use of CD-Link is subject to a Limited Use License Agreement, which@'
 db 'you can view from this program; be sure to read it before you configure@'
 db 'CD-Link.  If you do not agree to its terms, then do not proceed further.@'
 db '@'
 db 'As initially provided to you, CD-Link runs in "demo" mode.  This means@'
 db 'that after 30 minutes from bootup, the product will time out and any@'
 db 'further attempt to access the CD-ROM will result in a "Not Ready" error.@'
 db 'You can then re-boot and use the CD-ROM for another 30 minutes, as many@'
 db 'times as you wish.@'
 db '@'
 db 'To get the "real thing", select "Create Fully Functional CD-Link" from@'
 db 'the next screen, and follow the instructions presented.@'
 db '@'
 db 'Press Enter to continue to the main menu.@'
 db 0

scr1	label	word
	dw	scr1end			; end of fields for this screen
	db	1,00h,1,1		; title bar, top line
	dw	dat0101,0
	db	1,00h,25,1		; title bar, bottom line
	dw	datNoCh,0
	db	2,02h,23,36		; field type, attr, row, column
	dw	datCont,0
scr1end	label	word

dat0101	dw	80
	db	' CD-LINK ADMINISTRATOR         Copyright'
	db	' 1993 Rod Roark                         '

datNoCh	DW	80
	db	'                             Valid keys:'
	db	' Enter Esc                              '

datMenu	DW	80
	db	'                           Valid keys: ',18h
	db	' ',19h,' Enter Esc                            '

datDDoc	DW	80
	db	'                         Valid keys: ',18h,' ',19h
	db	' PgUp PgDn Esc                          '

datInput dw	80
	db	'                   Valid keys: Enter Esc'
	db	' Backspace Characters                   '

datCont	dw	8
	db	'Continue'

scrMain	label	word
	dw	scrMainEnd
	db	1,00h,1,1		; title bar, top line
	dw	dat0201,0
	db	1,00h,25,1		; title bar, bottom line
	dw	datMenu,0
	db	2,02h,10,25
	dw	dat0203,0
	db	2,02h,11,25
	dw	dat0204,0
	db	2,02h,12,25
	dw	dat0205,0
	db	2,02h,13,25
	dw	dat0206,0
	db	2,02h,14,25
	dw	dat0207,0
	db	2,02h,15,25
	dw	dat0208,0
	db	2,02h,16,25
	dw	dat0209,0
	db	2,02h,17,25
	dw	dat0210,0
scrMainEnd label word

dat0201	dw	80
	db	' CD-LINK ADMINISTRATOR version 1.04     '
	db	'                              MAIN MENU '
dat0203	dw	22
	db	'View License Agreement'
dat0204	dw	23
	db	'Print License Agreement'
dat0205	dw	17
	db	'View User''s Guide'
dat0206	dw	18
	db	'Print User''s Guide'
dat0207	dw	17
	db	'Configure CD-Link'
dat0208	dw	31
	db	'Create Fully Functional CD-Link'
dat0209	dw	23
	db	'About Technical Support'
dat0210	dw	9
	db	'Terminate'

scrLicense label word			; LULA screen header
	dw	scr3end
	db	1,00h,1,1		; top line
	dw	dat0301,0
	db	1,00h,25,1		; bottom line
	dw	datDDoc,0
scr3end	label	word

dat0301	dw	80
	db	' CD-LINK ADMINISTRATOR                  '
	db	'        LICENSE AGREEMENT (LICENSE.DOC) '

scrManual label word			; manual screen header
	dw	scr5end
	db	1,00h,1,1		; top line
	dw	dat0501,0
	db	1,00h,25,1		; bottom line
	dw	datDDoc,0
scr5end	label	word

dat0501	dw	80
	db	' CD-LINK ADMINISTRATOR                  '
	db	'              USER''S GUIDE (CDLINK.DOC) '

scrPrint label	word			; print screen header
	dw	scr6end
	db	1,00h,1,1		; top line
	dw	dat0601,0
scr6end	label	word

dat0601	dw	80
	db	' CD-LINK ADMINISTRATOR                  '
	db	'                         PRINT DOCUMENT '

txtPrint label byte
 db 'Please ready your printer, choose the proper device name, and press@'
 db 'Enter to begin printing.@'
 db 0

scrLPT	label	word
	dw	scr7end			; end of fields for this screen
	db	2,02h,14,39		; field type, attr, row, column
	dw	dat0701,0
	db	2,02h,15,39		; field type, attr, row, column
	dw	dat0702,0
	db	2,02h,16,39		; field type, attr, row, column
	dw	dat0703,0
	db	1,00h,25,1		; bottom line
	dw	datMenu,0
scr7end	label	word

dat0701	dw	4
	db	'LPT1'
dat0702	dw	4
	db	'LPT2'
dat0703	dw	4
	db	'LPT3'

txtNoPrinter label byte
 db 'Uh-oh!  I could not open the printer device that you selected!@'
 db '@'
 db 'You might need to select a different printer.@'
 db '@'
 db 'Press Enter to return to the main menu.@'
 db 0

txtNoDocument label byte
 db 'Uh-oh!  I could not find the requested file in the current directory!@'
 db '@'
 db 'When you run the Administrator, you must have the current directory set@'
 db 'to the directory that contains all of your CD-Link files.  For example,@'
 db 'if the directory named "CDLINK" is the one in which you have installed@'
 db 'CD-Link, then enter the command@'
 db '@'
 db '                           CD \CDLINK@'
 db '@'
 db 'before running this program.@'
 db '@'
 db 'Press Enter to return to the main menu.@'
 db 0

txtIOError label byte
 db 'An unexpected error occurred when trying to process this request!@'
 db '@'
 db 'This is quite unusual.  You may want to request technical support from@'
 db 'your dealer, or from IPC.@'
 db '@'
 db 'Press Enter to return to the main menu.@'
 db 0

scrCancel Label word
	dw	scrCancelEnd		; end of fields for this screen
	db	1,00h,25,1		; title bar, bottom line
	dw	datNoCh,0
	db	2,02h,23,36		; field type, attr, row, column
	dw	datCancel,0
scrCancelEnd label word

datCancel dw	6
	db	'Cancel'

scrConfig label	word			; config screen header
	dw	scr8end
	db	1,00h,1,1		; top line
	dw	dat0801,0
scr8end	label	word

dat0801	dw	80
	db	' CD-LINK ADMINISTRATOR                  '
	db	'                          CONFIGURATION '

scrOrder label	word			; screen header
	dw	scrOrderEnd
	db	1,00h,1,1		; top line
	dw	datOrder,0
scrOrderEnd label word

datOrder dw	80
	db	' CD-LINK ADMINISTRATOR                  '
	db	'                   SERIALIZE CDLINK.SYS '

scrSupport label word			; screen header
	dw	scrSupportEnd
	db	1,00h,1,1		; top line
	dw	datSupport,0
scrSupportEnd label word

datSupport dw	80
	db	' CD-LINK ADMINISTRATOR                  '
	db	'                      TECHNICAL SUPPORT '

txtAgree label byte
 db 'Do you understand and agree to the terms and conditions of the Limited@'
 db 'Use License Agreement?@'
 db 0

scrYesNo label	word
	dw	scr9end			; end of fields for this screen
	db	2,02h,15,39		; field type, attr, row, column
	dw	dat0901,0
	db	2,02h,16,39		; field type, attr, row, column
	dw	dat0902,0
	db	1,00h,25,1		; bottom line
	dw	datMenu,0
scr9end	label	word

dat0901	dw	3
	db	'Yes'
dat0902	dw	2
	db	'No'

txtNoAgree label byte
 db 'Using CD-Link requires that you read and agree to the terms and@'
 db 'conditions of the Limited Use License Agreement that is provided with@'
 db 'the product.  To see this Agreement, select "View License Agreement" or@'
 db '"Print License Agreement" from the main menu.@'
 db '@'
 db 'Press Enter to return to the main menu.@'
 db 0

scrCont	label	word
	dw	scrContEnd		; end of fields for this screen
	db	1,00h,25,1		; title bar, bottom line
	dw	datNoCh,0
	db	2,02h,23,36		; field type, attr, row, column
	dw	datCont,0
scrContEnd label word

txtConfigIntro label byte
 db 'In order for CD-Link to work, your CONFIG.SYS must load two device@'
 db 'drivers (via DEVICE= statements).  The first of these is the "hardware"@'
 db 'driver provided by your CD-ROM manufacturer, which provides the low-@'
 db 'level interface to the controller and drive(s).@'
 db '@'
 db 'Unfortunately we cannot help you install the hardware driver; its name@'
 db 'and parameters are determined by the hardware manufacturer.  However, if@'
 db 'you had previously installed MSCDEX, then your CONFIG.SYS will already@'
 db 'contain the required command.@'
 db '@'
 db 'The second required driver is CDLINK.SYS.  This configuration procedure@'
 db 'will build the command line needed for the CD-Link driver.@'
 db '@'
 db 'Press Enter to continue.@'
 db 0

txtDevName label byte
 db 'First, I need to know the "device name" of your CD-ROM hardware driver.@'
 db '@'
 db 'This name must be correct, or CD-Link will have no idea how to find it.@'
 db 'It is generally NOT the same as the disk filename of that driver.  Your@'
 db 'CD-ROM hardware manual will tell you what its device name is, or how to@'
 db 'specify the name on the "DEVICE=" command line that is used to load the@'
 db 'hardware driver.@'
 db '@'
 db 'For some hardware drivers the default name is MSCD001.@'
 db '@'
 db 'To change the name from the default shown here, backspace over it and@'
 db 'type in the new name.@'
 db 0

scrDevName label word
	dw	scrDevNameEnd		; end of fields for this screen
	db	3,02h,23,36		; field type, attr, row, column
	dw	datDevName,0
	db	1,00h,25,1		; bottom line
	dw	datInput,0
scrDevNameEnd	label	word

datDevName dw	7
	db	'MSCD001 '

txtCFName label byte
 db 'Now, I need to know the fully qualified filename that you want for your@'
 db 'cache file.  This will be the scratch file that CD-Link uses to store@'
 db 'recently-accessed CD-ROM data, in order to improve performance.@'
 db '@'
 db '"Fully qualified" means that the name must include the drive letter and@'
 db 'complete path.@'
 db '@'
 db 'Please accept or modify the following:@'
 db 0

scrCFName label word
	dw	scrCFNameEnd		; end of fields for this screen
	db	3,02h,23,9		; field type, attr, row, column
	dw	datCFName,0
	db	1,00h,25,1		; bottom line
	dw	datInput,0
scrCFNameEnd	label	word

datCFName dw	64
 db 'C:\CDLINKCA.CHE                                                  '

txtCFSize label byte
 db 'Next, please indicate the amount of disk space, in kilobytes, that you@'
 db 'want to assign for the cache file.  Any size from 128 kilobytes to@'
 db 'several megabytes is reasonable (one megabyte is 1024 kilobytes).  The@'
 db 'minimum size is 42 kilobytes.@'
 db '@'
 db 'As a general rule, a larger cache file means better performance; however@'
 db 'there will most likely be some maximum size, beyond which you will not@'
 db 'notice any significant performance improvement.  This can only be@'
 db 'determined by experimentation (the CDSTAT utility, described in the@'
 db 'User''s Guide, is useful in this regard).@'
 db '@'
 db 'Please accept or modify the following:@'
 db 0

scrCFSize label word
	dw	scrCFSizeEnd		; end of fields for this screen
	db	3,02h,23,37		; field type, attr, row, column
	dw	datCFSize,0
	db	1,00h,25,1		; bottom line
	dw	datInput,0
scrCFSizeEnd	label	word

datCFSize dw	5
	db	'1024  '

txtNumericError label byte
 db 'Invalid number!  Try again:@'
 db 0

txtDrives label byte
 db 'Very good!  One more question.@'
 db '@'
 db 'How many CD-ROM drives will be attached to this system?@'
 db 0

scrDrives label word
	dw	scrDrivesEnd		; end of fields for this screen
	db	3,02h,23,39		; field type, attr, row, column
	dw	datDrives,0
	db	1,00h,25,1		; bottom line
	dw	datInput,0
scrDrivesEnd	label	word

datDrives dw	2
	db	'1  '

txtConfigResult label byte
 db 'Based on the information you have provided, the following command line@'
 db 'should be added to your CONFIG.SYS file:@'
 db '@'
 db '@'
 db '@'
 db '@'
 db '@'
 db 'Remember that prior to this command line, a DEVICE= statement must also@'
 db 'appear for the CD-ROM hardware driver.@'
 db '@'
 db 'We suggest that you now print this screen (Shift-PrtSc), exit the@'
 db 'Administrator, edit your CONFIG.SYS file, and re-boot to activate@'
 db 'CD-Link.  Be sure to take some time to study the User''s Guide for notes@'
 db 'on fine-tuning your installation, and for information about special@'
 db 'cases that could apply to you.@'
 db '@'
 db 'Press Enter to return to the main menu.@'
 db 0

txtOrderIntro label byte
 db 'Converting to a fully functioning CD-Link consists of applying a valid@'
 db 'serial number to CDLINK.SYS.  To get this serial number, you must pur-@'
 db 'chase a license from your dealer, or from IPC.  This license is subject@'
 db 'to the Limited Use License Agreement that you have already accepted.@'
 db 'Remember that you are not permitted to disclose your serial number, or@'
 db 'to use it on more than one computer.@'
 db '@'
 db 'If you already have a unique CD-Link serial number for this computer,@'
 db 'press Enter to proceed.  If not, you will need to contact IPC at@'
 db '(404)992-5327, or your dealer, to place your order.@'
 db '@'
 db 'The serialization procedure will still work if this copy of CDLINK.SYS@'
 db 'has previously been serialized.@'
 db '@'
 db 'Press Enter to continue.@'
 db 0

txtSerNo label byte
 db 'Please enter the unique CD-Link serial number for this computer.@'
 db '@'
 db 'This number is always nine digits.  Do NOT include any dashes, commas,@'
 db 'or other punctuation.  Do include any leading zeros.@'
 db '@'
 db 'When you press Enter, the copy of CDLINK.SYS in the current directory@'
 db 'will be rewritten with this serial number embedded in it.  Do NOT dis-@'
 db 'tribute this copy to any other person.  Do feel free to give copies of@'
 db 'the unserialized "demo" version to others, as long as you include all of@'
 db 'the original files in the form originally provided by IPC.@'
 db 0

scrSerNo label word
	dw	scrSerNoEnd		; end of fields for this screen
	db	3,02h,23,35		; field type, attr, row, column
	dw	datSerNo,0
	db	1,00h,25,1		; bottom line
	dw	datInput,0
scrSerNoEnd	label	word

datSerNo dw	9
	db	15 dup (' ')		; need some extra spaces for move

txtOrderDone label byte
 db 'The driver has been successfully rewritten.@'
 db '@'
 db 'Press Enter to return to the main menu.@'
 db 0

txtSupportIntro label byte
 db 'If CD-Link is just not working, the first thing to do is make sure that@'
 db 'your CD-ROM drive, as installed, will work with Microsoft''s Extensions@'
 db '(MSCDEX) under DOS.  Chances are that MSCDEX came with your drive.  If@'
 db 'the drive doesn''t work with MSCDEX, then either your CD-ROM drive or@'
 db 'its controller is defective, or improperly installed, or the hardware@'
 db 'device driver is not properly installed.@'
 db '@'
 db 'If CD-Link appears to be the culprit and your dealer cannot help, then@'
 db 'IPC''s support staff will need your CD-Link serial number and listings of@'
 db 'your CONFIG.SYS and AUTOEXEC.BAT files.@'
 db '@'
 db 'The fastest and most accurate way to get support is via modem or FAX.@'
 db 'IPC''s bulletin board number is (404)640-5017, or you may send your@'
 db 'question to Compuserve ID 73747,66.  For FAX instructions, call us@'
 db '(voice) at (404)992-5327.@'
 db '@'
 db 'Press Enter to return to the main menu.@'
 db 0

dataseg	ends

;====================================================================;
;                         Stack Segment                              ;
;====================================================================;

stakseg	segment	stack
	db	256 dup("S")
stakseg	ends

	end	begin
