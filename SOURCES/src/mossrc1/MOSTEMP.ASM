	include PAGE.INC
	title	MOStemp.ASM - temp MOS module
	extrn bugerror:near

;-----------------------------------------------------------------------;
;									;
;		Development Specification				;
;									;
;									;
; Program Name: MOS.COM 		Assigned to: n/a		;
; Module Name:	MOStemp 		Assign date: n/a		;
; Entry Points: n/a			Completed:   n/a		;
; Entry From:	n/a							;
; Entry Method: n/a							;
; Calls:	n/a							;
; Purpose:	provide mosfunxx labelx and whatever else might be	;
;		needed to temp some MOS module				;
; Refer to:	n/a							;
; Last Update:	06/22/90						;
;									;
;	11/25/86	M Stitt  inserted code at terminate label	;
;			(supplied in cterm from DAM			;
;									;
;	07/07/87	S Hyde   added limited function 5e and 5f 	;
;			support MS Network Not Installed (AX=1) 7-15	;
;									;
;	08/13/87	S Hyde   added undocoment function 55 which     ;
;			appears to do the same thing as function 26     ;
;			Must be a more efficent way or special cond.    ;
;			under dos.  Information about this call was     ;
;			provide in PD doc about undocomented calls      ;
;									;
;	08/18/87        S Hyde   added undocment function 60 which      ;
;			from PD doc about undocmented call seams to     ;
;			return the current drive and directory in       ;
;			ASCIIZ format into address specify by ES:DI	;
;									;
;	08/25/87        S Hyde    Enhanced function 5e and 5f to set    ;
;			extended error.  Require for RM-COBOL/85	;
;			Corrected function in which PD doc was incorect ;
;			After investigating function 60 seems to return ;
;			last open file by task.				;
;									;
;	09/12/87	S Hyde   Enhanced function 55 from information  ;
;	09/16/87	supplied from Computer Associates. Function 55  ;
;			creates a PSP (similar to function 26) but also ;
;			allows the file to inherit the files from the   ;
;			parent whose inherit bit is on.  The new PSP is ;
;			also the active PSP.				;
;									;
;	11/06/87	S Hyde	Slightly Improved space and speed of    ;
;			function 52 while investigating problems with	;
;			MCB and Initialization of device drivers	;
;									;
;	11/12/87	S Hyde  Implement function 63			;
;			Information from Adv MS-DOS pg 385 and invest-	;
;			igation.  Found out that al is clear, dl is     ;
;			unless al is 1 and dl is 1 (which then dl is 1) ;
;			This function is use by MS-C 5.00 and MASM 5.0  ;
;			Linker.						;
;									;
;	11/15/87	S Hyde function 34 now points correct to our	;
;			INMOS flag (SCBINMOS) similar to TCBNEST but	;
;			global to all tasks				;
;									;
;	01/20/88	S Hyde change SCBSEG and ZERO seg access to	;
;			use MGetXXXX macros. Optimize INT 00 and INT 2E ;
;			for smaller code since previous code is very    ;
;			similar.					;
;-----------------------------------------------------------------------;
; sah\rdr 02/20/88 Move DDT Segment to MO2 Group			;
;-----------------------------------------------------------------------;
; SAH 10/05/88	Move function 34 into MOSINT28 so that all TSR related  ;
;		code is in one module.					;
;-----------------------------------------------------------------------;
; RKG 10/06/88	Public MOSFUNxx for assembly without .PUBs		;
;-----------------------------------------------------------------------;
; SAH 10/13/88  Added function 5d06h to point to critical flag SCBCRIT  ;
;-----------------------------------------------------------------------;
; SAH 12/0/88	Move mosint2f handler to this module since it is in	;
;		this is better place for it. Also enhance it for MOS	;
;		SHARE OFF command which is necessary because of DBASE	;
;		IV's Installation program.                              ;
;-----------------------------------------------------------------------;
; SAH 07/07/89	Added INT 2E support which is back door to command	;
;		processor, which Novell's menu interface uses.          ;
;-----------------------------------------------------------------------;
; BWR 11/29/89	Marked messages for foreign language translation	;
;-----------------------------------------------------------------------;
; BWR 01/22/90	  Added support for DOS 3.30 (Network) functions 5E00	;
;		and 5E01.  (5E01 is an undocumented call that PLACES	;
;		the network machine name and ID into local space.	;
;		Novell calles 5E01 to furnish this ID.			;
;		  The other functions on 5E and 5F are handled directly ;
;		by the Novell shell itself and need not be intercepted	;
;		by the O/S.  Presumably this is how the network		;
;		drivers handle it anyway - DOS (or MOS in this case)	;
;		doesn't know, or care, what network is installed.	;
;		DOS does have some mystery code down under 5E02, 5E03	;
;		5F02, 5F03 and 5F04, but at this point exploring that	;
;		code is unnecessary.  (It's probably specific to the	;
;		Microsoft Network.)					;
;-----------------------------------------------------------------------;
; SAH 02/20/90  Added INT 29h support					;
; SAH 02/23/90  Use maxdays from mosfun00 (duplicate data)		;
; SAH 02/26/90  Corrections for Novell's INT 2eh use in menus		;
;-----------------------------------------------------------------------;
; SAH 03/07/90  Corrections for function 55h, so it inherits files	;
;		Also corrected unused DOS functions, so that AL is 	;
;		return as 00 (as in DOS) instead of given a nasty 	;
;		Error.							;
;-----------------------------------------------------------------------;
; SAH 06/22/90	Corrections for MSetPSP macro and LanLink		;
;-----------------------------------------------------------------------;

	include GROUP.INC

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
	include mospsp.inc


gdata	segment para public 'data'
	include MOSSCBEX.INC	; specify all SCB items as external
gdata	ends
.list

irq	segment byte public 'data'
	extrn	irqstart:byte, irqend:byte

	dw	00h*4		; offset for this interrupt
	dd	?		; save prior value
	dw	0		; we don't save changes, we leave them alone
	dw	mos:mosint00	; initial value is here
	dw	0		; don't change back if application changes it

	dw	2eh*4		; offset for this interrupt
	dd	?		; save prior value
	dw	0		; we don't save changes, we leave them alone
	dw	mos:mosint2e	; initial value is here
	dw	0		; don't change back if application changes it

	dw	24h*4
	dd	?
	dw	0
	dw	mos:MOSTMP24
	dw	0

	dw	29h*4		; offset for this interrupt
	dd	?		; save prior value
	dw	0		; we don't save changes, we leave them alone
	dw	mosint29	; offset of handler
	dw	0		; don't change back if application changes it

	dw	2fh*4		; offset for this interrupt
	dd	?		; save prior value
	dw	0		; we don't save changes, we leave them alone
	dw	mosint2f	; offset of handler
	dw	0		; don't change back if application changes it
irq	ends


poll	segment byte public 'data'
poll	ends

ddt     segment word public 'code2'
	extrn   findtfb:near
ddt     ends

	page
mosseg	segment para public 'code1'
	assume	cs:mos,ds:grp,es:nothing,ss:tcb

	extrn	mosend:byte, sbios:word, maxdays:byte
	extrn	moserror:near, fun00a:near
	extrn	todriver:near, mosfun26:near

int0msg	db	13,10,'Divide by zero error      ',13,10,13,10,'$' ;@@XLAT

mosint00:		
	assume	ds:nothing,es:nothing,ss:nothing
	mov	dx,offset [int0msg]
	assume	ds:nothing,es:nothing,ss:nothing
	MGetSCB ds
	assume	ds:grp
	mov	ss,[scbtcbpc]		; gain addressability to MOS data
	assume	ss:tcb
	lea	sp,[tcbstack]
	mov	ax,cs
	mov	ds,ax			; access constant data in MOS 
	assume	ds:mos
	mov	ah,9
	int	21h

; Please note That MOSINT00 will simply flow into to code 
; terminate instead of jumping to it, this makes the code
; smalller

;-----------------------------------------------------------------------;
	public	terminate
terminate:
	assume	ds:nothing,es:nothing,ss:nothing

	MGetSCB	ds
	assume	ds:grp
	cli
	mov	ss,[scbtcbpc]
	mov	sp,offset tcbstack
	sti
	assume	ss:tcb
	mov	es,[tcbpsp]		; Used in normal termination procedures
	mov	[tcbretc],ax	
	mov	ax,offset tcbstack	; Reset stack
	mov	[tcbstkp],ax
	jmp	fun00a



;-------------------------------------------------------------------;
; Temporary INT 23h and INT 24 handler until command processor is   ;
; loaded and initialized.					    ;
;-------------------------------------------------------------------;

mostmp24:
	mov	al,3
mostmp23:
	iret

;-------------------------------------------------------------------;
; MOSINT2E - Undocment Back door to command processor.		    ;
; DS:SI -> #,'String',0dh  which is passed to command processor     ;
;-------------------------------------------------------------------;
MOSINT2E:
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	ds
	push	es
;
;	We are going to sorta cheat on this but basically we will
;	exec our command.com.  This should make the INT 2E function
;	correctly and my understanding of why DOS has this is for
;	a quick and dirty way or getting to Command processor with out
;	reloading it.  Since our command processor is only 20 bytes and
;	all of the main code is resident anyway.  This technique should work
;
;	The following is use to set up Parameters to be passed to function
;	4bH (EXEC)
;
	mov	dx,ds		    ; save current ds
	MGetSCB ds
	assume	ds:grp
	mov	es,[scbtcbpc]
	assume	es:tcb
	mov	di,offset [tcbparm2e]
	cld
	xor	ax,ax		    ; store 00h into offset 00 of parm block
	stosw			    ; This means copy enviroment
	mov	ax,offset [tcbtext2e]
	stosw			    ; use si for offset of command to pass
	mov	ax,es		    ; use ds (save in dx above) for segment
	stosw
	mov	ax,5ch		    ; we are going to use Current PSP for
	stosw			    ; fcbs
	mov	ax,[tcbpsp]
	stosw
	mov	ax,6ch		    ; we are going to use Current PSP for
	stosw			    ; fcbs
	mov	ax,[tcbpsp]
	stosw
;
;	Now we must append /c in front of the command pass in ds:si
;
;
	mov	di,offset [tcbtext2e]
	push	ds
	mov	ds,dx
	lodsb
	mov	cl,al		    ; save count
	add	al,3
	stosb
	mov	al,'/'
	stosb
	mov	ax,' C'
	stosw
	xor	ch,ch
	rep	movsb
	pop	ds

;	Now is the time to do actual EXEC
;
	mov	dx,offset [scbshell]	    ; point ds:dx -> scbshell
	mov	bx,offset [tcbparm2e]	    ; point es:bx -> tcbparm2e
	mov	ax,4b00h
	int	21h
 ;
	pop	es
	pop	ds
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret


;-------------------------------------------------------------------;
; MOSINT2F - Multiplex interupt - currently support function 10     ;
; which checks to see if share is installed. If MOS SHARE OFF is    ;
; use then INT 2f function 10 will return that share is not install ;
;-------------------------------------------------------------------;

mosint2f proc	far
	cmp	ax,1000h	; only respond to the id for share
	jne	i2f2
	pushf			; save flags
	push	ds
	MGetSCB ds
	assume	ds:grp
	mov	ds,[scbtcbpc]	; get current TCB
	cmp	[tcbshare],'N'	; share installed or not (MOS SHARE)
	jne	i2f1
	pop	ds
	popf			; get old flags
	ret	2		; return back with current flags
i2f1:
	pop	ds
	popf
	mov	al,0ffh 	; indicate share is installed
i2f2:
	iret
mosint2f endp

;------------------------------------------------------------------;
; MOSINT29 - Undocument DOS interupt for faster access to master   ;
; console.  Some Information can be found in the MS-Papers book	   ;
;------------------------------------------------------------------;				

mosint29 proc	near
 	 push	ax
	 push	si
	 push	di
	 push	bp
	 mov	bx,7
	 mov	ah,0eh
	 int	10h
	 pop	bp
	 pop	di
	 pop	si
	 pop	ax
         iret
mosint29 endp

;-----------------------------------------------------------------------;
; return invalid function for all the others
pubfn	macro	fn
	public	mosfun&fn
mosfun&fn:
	endm

	irp	fn,<18,1d,1e>
	pubfn	fn
	endm
	irp	fn,<20>
	pubfn	fn
	endm
	irp	fn,<53>
	pubfn	fn
	endm
	irp	fn,<61>
	pubfn	fn
	endm

	; Print message that unsupported function used

unkfun  label	near	
	mov	[TAL],0		; do as DOS and return 00 in al
	ret			; don't lock entired system

	subttl	mosfun52 - Get 1st MBP pointer
	page
;-----------------------------------------------------------------------;
; This is provided for compatibility with Periscope.			;
;									;
;  On Entry:								;
;	Nothing.							;
;  On Exit:								;
;	TES:TBX-2 -> TCBMBPF						;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,ss:tcb,es:nothing
	public	mosfun52
mosfun52 proc	near
	mov	bx,ss		; SAH 
	mov	es,bx		; SAH ES -> TCB	
	lea	bx,[tcbmbpf+2]	; Pointer to 1st memory block prefix
	xor	ax,ax		; tell them it worked
	mov	[TES],es
	mov	[TBX],bx
	mov	[TAX],ax
	ret
mosfun52 endp

	subttl	mosfun55 - Undocomented Create New PSP call
	page
;-----------------------------------------------------------------------;
;       This appears to be silimilar to Create PSP 			;
;	but also allows the PSP to inherit the files of the parent whos ;
;	inherit bit is on.  Also this PSP becomes the active PSP	;
;									;
;	On Entry:							;
;		SI = Segment for end of allocation			;
;		DX = Segment for PSP to create				;
;									;
;	On Exit:							;
;		New PSP created						;
;-----------------------------------------------------------------------;

	assume	ds:grp,ss:tcb,es:nothing
	public	mosfun55
mosfun55 label	near
;
;	call function 26 to initialize PSP
;
	 call	mosfun26

;        set this PSP as active PSP

	 mov	bx,[tcbpsp]		; SAH get parent PSP
	 mov	ax,[TDX]		; SAH set active PSP to this
	 MSetPSP ax			; SAH psp
	 mov	es,ax			; SAH point to PSP
	 assume es:PSPseg
	 mov	ax,[TSI]		; SAH get end segment
	 mov	es:[PSPmem],ax
	 mov	es:[PSPprnt],bx		; SAH save parent PSP
	 assume es:nothing
	 mov	byte ptr [TAL],0
;
;	 now for the fun part, if handles are mark inherit, set handle 
;	 to ffh.
;

	 push	es
	 push	ds
	 mov	ax,es
	 mov	ds,ax
	 mov	cx,15
	 mov	si,offset [PSPhtbl]
	 mov	bx,5
HandLoop:
	 callmos2 findtfb
	 jc	HandZap
	 assume es:tfb
	 test	[tfbalow],08h		; is it inherited
	 jz	HandNext
HandZap:	
	 mov	byte ptr ds:[si+bx],0ffh
HandNext:
	 inc	bx
	 loop	HandLoop
	  	 
	 pop	ds
	 pop	es

	 and	[TFLAG],NOT CARRY
	 ret

	subttl	mosfun5D - Error setup functions
	page
;-----------------------------------------------------------------------;
; This is provided for compatibility with some TSRs to reset the	;
; extended error information for an application that they may have	;
; interrupted.								;
;									;
;  On Entry:								;
;	TAL = function code						;
;	    = 06h - Return critical flag				;
;	    = 0AH - reset extended error				;
;	TDS:TDX -> 3	words of data (error, class, locus)		;
;									;
;  On Exit:								;
;	Nothing								;
;									;
;-----------------------------------------------------------------------;
	assume	ds:grp,ss:tcb,es:nothing
	public	mosfun5d
mosfun5d proc	near
	mov	al,[TAL]
	cmp	al,06h		; is this for critical flag
	jne	mf5dn6
	mov	[TDS],DS	; make sure you return ds --> GRP
	mov	[TSI], OFFSET SCBCRIT
	ret
mf5dn6:
	cmp	al,0aH		; Is this set extended error?
	jne	mf5dx		; No, could be anything

	mov	es,[TDS]	; Get pointer to error info
	mov	bx,[TDX]
	mov	al,es:[bx]	; Get error number only (don't care about rest)
	mov	[tcberrcod],al	; Set it
mf5dx:
	ret

mosfun5d endp

	 subttl	mosfun5e - printer Setup & mosfun5f Get Assign list entry
	 page
;----------------------------------------------------------------------------
;	Function 5E00 - Get Machine Name
;	--------------------------------
;
;	Input:	
;		AX 	= 	5E00h
;		DS:DX	=	Pointer to buffer to receive string.
;	Output:
;		CH	=	Validity. (1 = Valid Network Station)
;		CL	=	Local station ID.
;		
;		Machine name placed at location supplied on input.
;
;	Function 5E01 - Set Machine Name
;	--------------------------------
;
;	  This function is undocumented by DOS, but found to be used by
;	Novell LOGIN.EXE in assigning the Machine name and Network ID.
;
;	Input:
;		AX	=	5E01h
;		CX	=	Station ID assigned.
;		DS:DX	=	Pointer to buffer with Machine Name
;				string in it.
;	Output:
;		None.
;
;----------------------------------------------------------------------------
	assume	ds:nothing, es:nothing, ss:tcb
	public	mosfun5E, mosfun5F

mosfun5e 	proc	near
	mov	ax, [TAX]
	cmp	al, 1
	jb	m5E_0
	je	m5E_1
;
;	Bad function.
;
	mov	ax, 1
	callmos2  moserror
	ret

m5E_0:
	mov	ax, ss			;Build DS:SI at Machine name.
	mov	ds, ax
	mov	si, offset TCB_machine_name
	mov	es, [TDS]		;ES:DI => Buffer @ DS:DX
	mov	di, [TDX]
	mov	cx, 15			;Move 15 bytes.
;
;	If the machine name was never initialized in our TCB, stuff
;	the name with blanks.
;
	cmp	byte ptr [si], 0	;Zero in Machine name?
	jne	m5E_0_COPY		;If not, copy it to dest.
	mov	al, ' '			;If so, return string of blanks.
	rep	stosb
	jmp short m5E_0_TERMINATE
m5E_0_COPY:
	rep	movsb
m5E_0_TERMINATE:
	mov	byte ptr es:[di], 0	;Zero terminate the string.
	mov	cx, [TCB_machine_ID]
	mov	[TCX], cx		;Return machine ID.
	ret

m5E_1:
	mov	ds, [TDS]		;Build DS:SI at buffer.
	mov	si, [TDX]
	mov	ax, ss			;Build ES:DI in the TCB.
	mov	es, ax
	mov	di, offset TCB_machine_name
	mov	cx, 15			;Move 15 bytes.
	rep	movsb
	mov	cx, [TCX]		;Get machine ID.
	mov	[TCB_machine_ID], cx
	ret
mosfun5e	endp

mosfun5f	proc	near
	mov	[TAX], 1	; Indicate that MS Network not installed.
	or	[TFLAG], carry
	mov	byte ptr [tcberrcod], 1
	ret
mosfun5f	endp

	 subttl  mosfun60 - get last open file name (undocumented) 
	 page
;-----------------------------------------------------------------------;
;        the following is currently knowned implementation of 		;
;	 undocmomented function 60 which from information from PD doc   ;
;	 about undocumented call returns the current drive and          ;
;	 and directory into address specify by ES:DI.  RM-COBOL 85 uses ;
;        this function.							;
;        After investigation function 60 seems to return the last open  ;
;	 file by system: Here is what I observed:			;
;		Task open file with function 3d	and later (the task)    ;
;	converted the filename at ds:dx of open function to full path   ;
;	When function 60 is called, it seems to return the same info    ;
;	stored at ds:dx of the prevous open file.  Possiablity trans-   ;
;	lated under PC-Networks but I am not sure about it.		;
;-----------------------------------------------------------------------;
	 assume ds:grp,es:nothing,ss:tcb
	 public	mosfun60
mosfun60 proc	near
	 mov	di,[TDI]
	 mov	ax,[TES]
	 mov	es,ax
	 lds    si,[tcbopen60]
mf60loop:
	 lodsb			; get character
	 or     al,al
	 jz     mf60done
	 stosb			; store it in user space
	 jmp	short mf60loop
mf60done:
	 stosb			; store trailing zero
	 mov	[TAX],004ch	; seems to be right (who knows)
	 ret
mosfun60 endp

	subttl	mosfun63 - get dos interim flag 
;---------------------------------------------------------------------;
;	ADV MS-DOS Page 384 for more information 		      ;
;	use by MS-C 5.00 and MASM 5.00 Linker			      ;	 
;---------------------------------------------------------------------;
	assume  ds:grp,es:nothing,ss:tcb
	public	mosfun63
mosfun63 proc	near
	 mov	al,[TDL]
	 mov	byte ptr [TDL], 00h
	 cmp	byte ptr [TAL], 01h
	 jne	mf63skip
	 mov	[TDL],al
mf63skip:
	 mov	byte ptr [TAL], 00h
	 ret
mosfun63 endp
	

;--------------------------------------------------------------------------;

capstbl db	80H,9AH,90H,83H,8EH,85H,8FH,80H,88H,89H,8AH,8BH,8CH,8DH,8EH,8FH
	db	90H,92H,92H,93H,99H,95H,96H,97H,98H,99H,9AH,9BH,9CH,9DH,9EH,9FH
	db	0A0H,0A1H,0A2H,0A3H,0A4H

public	caps
caps:	cmp	al,'a'
	jb	caps1
	cmp	al,'z'
	jbe	caps2
	cmp	al,80h
	jb	caps1
	cmp	al,0e5h
	je	caps3
	cmp	al,165
	jae	caps1
	push	bx
	lea	bx,capstbl-80H
	xlat	capstbl
	pop	bx
caps1:
	ret
caps2:
	sub	al,'a'-'A'
	ret
caps3:
	mov	al,05h
	ret


;-----------------------------------------------------------------------;
public	getdate
lproc 	getdate

lstring reqhead,26
lstring datebuffer,6
lbyte 	wkday
lword 	year
lbyte 	month
	
	assume	ds:nothing
	push	bx
	push	si
	push	di	
	push	es
	
	mov	byte ptr [reqhead],26		; set rh length
	mov	byte ptr [reqhead+2],4		; input read from mosddclk
	lea	bx,[datebuffer]
	mov 	word ptr [reqhead+14],bx	; set transfer address
	mov 	ax,ss
	mov	word ptr [reqhead+16],ax

	push	ds
	MGetSCB ds
	assume	ds:grp
	lds	si,[scbstdclk]
	assume	ds:nothing
	mov	bx,ss
	mov	es,bx
	lea	bx,[reqhead]
	mov	ah,80h
	xor	cx,cx
	callmos2 todriver		; call the clock driver
	mov 	cx,word ptr [datebuffer]	
	pop	ds
	
	mov	ax,cx		; day count now in cx
	xor	dx,dx
	mov	bx,7
	div	bx
	mov	ax,dx
	sub	ax,5
	mov	[wkday],al
	cmp	dx,4
	ja	Dc1
	add	dx,2
	mov	[wkday],dl
Dc1:
	mov	ax,cx
	xor	dx,dx
	mov	bx,1461		; number of days in a four year period
	div	bx
	or	ax,ax
	jz	Dc2
	shl	ax,1
	shl	ax,1		; ax * 4
Dc2:
	mov	[year],ax
	xor	di,di
	cmp	dx,366
	jae	Dc7
	mov	di,1		; set di=1 for leap year
	jmp	Dc3
Dc7:
	inc	[year]
	sub	dx,366
	mov	ax,dx
	xor	dx,dx
	mov	bx,365
	div	bx
	add	[year],ax
Dc3:				; dx now holds number of days into the year
	add	WORD PTR [year],1980
	mov	BYTE PTR [month],1
Dc4:
	mov	al,[month]
	xor	ah,ah
	mov	si,ax
	dec	si
	mov	bx,offset [maxdays]
	mov	bl,mos:[bx+si]	; get max number of days for month
	xor	bh,bh
	cmp	al,2		; is it february?
	jne	Dc5
	add	bx,di		; if feb, add the leap year factor (0 or 1)
Dc5:
	cmp	dx,bx
	jnae	Dc6
	sub	dx,bx
	inc	BYTE PTR [month]
	cmp	BYTE PTR [month],12
	jne	Dc4
Dc6:
	inc	dl
	mov	al,[wkday]
	mov	cx,[year]
	mov	dh,[month]

	pop	es
	pop	di
	pop	si
	pop	bx

lundef 	reqhead,26

lundef 	datebuffer,6
	
lundef 	wkday
lundef 	year
lundef 	month

lendp 	getdate

;-----------------------------------------------------------------------;
public	gettime
lproc 	gettime

lstring reqhead,26

lstring datebuffer,6

	assume	ds:nothing
	push	ax
	push	bx
	push	si
	push	di
	push	es
	
	mov	byte ptr [reqhead],26		; set rh length
	mov	byte ptr [reqhead+2],4		; input read from mosddclk
	lea	bx,[datebuffer]
	mov 	word ptr [reqhead+14],bx	; set transfer address
	mov 	ax,ss
	mov	word ptr [reqhead+16],ax

	push	ds
	MGetSCB ds
	assume	ds:grp
	lds	si,[scbstdclk]
	assume	ds:nothing
	push	ss
	pop	es
	lea	bx,[reqhead]
	mov	ah,80h
	xor	cx,cx
	callmos2 todriver		; call the clock driver
	pop	ds

	mov	cl,byte ptr [datebuffer+2]	; minutes
	mov	ch,byte ptr [datebuffer+3]	; hour
	mov	dl,byte ptr [datebuffer+4]	; hundreth secs
	mov	dh,byte ptr [datebuffer+5]	; seconds

	pop	es
	pop	di
	pop	si
	pop	bx
	pop	ax

lundef 	reqhead,26

lundef 	datebuffer,6

lendp 	gettime

;-----------------------------------------------------------------------;
mosseg	ends
	end
