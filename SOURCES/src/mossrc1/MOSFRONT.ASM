	include page.inc
	title	MOSFRONT.ASM - the first MOS module to link

public	bugerror
bugreport equ	bugerror

;-----------------------------------------------------------------------;
;									;
;		Development Specification				;
;									;
;									;
; Program Name: MOS		Assigned to: Jim Bean, David Morrow	;
; Module Name:	MOSFRONT	Assign date: 01/01/86			;
; Entry Points: n/a		Completed:   02/06/86			;
; Entry From:	n/a							;
; Entry Method: n/a							;
; Calls:	n/a							;
; Purpose:	Establish start pointers in each of the MOS segments,	;
;		as well as specifying the last entries of the irq and	;
;		poll segment tables					;
;		Establish the segment ordering by using the MASM /S	;
;		option when assembling this module (only) to force	;
;		ordering as it is in this module			;
; Refer to:	n/a							;
; Last Update:	11/28/89						;
;									;
;-----------------------------------------------------------------------;
	subttl	discussion of MOSFRONT as implemented
	page

;-----------------------------------------------------------------------;
;									;
; jrb 02/14/86 10:20 MOSFRONT						;
;									;
; added a very simple error reporter for critical internal errors	;
; it is currently used as follows:					;
;									;
;	CALL	BUGERROR						;
;	DB	'99 '		; this is the internal error number	;
;	DB	'This is some variety of message',00H			;
;									;
; the string following the call is displayed, preceded by 'Internal     ;
; error #' (e.g. 'Internal error #99 This is some variety of message')  ;
; and then an enabled loop is entered to hang up the system		;
;									;
; error numbers are:							;
; 01 - Stack overflow during allocation of local variables for a	;
;      recursive procedure - the message consists of the procedure name ;
; 02 - Heap structure corruption, someone or something trashed a block	;
;      headers information.						;
;									;
; detection of the 01 error is enabled for a source file which makes	;
; use of the macros in MOSREGS.INC (also updated) if the statement	;
;									;
; extrn bugerror:near							;
;									;
; appears in the source file prior to the INCLUDE MOSREGS.INC statement ;
; I put it immediately following the title statement			;
;									;
; MOSTCB.INC changed slightly by the addition of TCBMINSTK which is a	;
; label in front of the stack area so overflow can be detected		;
;									;
;-----------------------------------------------------------------------;
;									;
; jrb 02/24/86								;
;									;
; took the mos segment out of the grp group of segments 		;
; added mos group of mosseg code segments				;
; added scbseg and scbfree in mosseg segment				;
;									;
;-----------------------------------------------------------------------;
;									;
; jrb 03/06/86								;
;									;
; added bootseg word in mosseg segment					;
;									;
; this is the segment address of 29 bytes formatted as follows: 	;
; 0-2	reserved							;
; 3-6	'TSL '		verification id 				;
; 11-27 		Bios Parameter Block of boot default disk	;
; 28			boot default disk id for BIOS INT 13H		;
;									;
; if we are ROMed, this is a segment in ROM with this information	;
; if we were loaded off a disk, this is the segment address of the	;
;   boot loader, whose first 29 bytes are formatted as above		;
; the standard block device driver should look at the verification id	;
;   and, if valid, should copy the BPB into its own space so it can	;
;   return a BPB pointer to MOS 					;
;									;
;-----------------------------------------------------------------------;
; DAM  1/2/87  Added DDT segment to GRP group for the DDTs to be put	;
;  into the GRP.  This will give us more code room in MOS.		;
;-----------------------------------------------------------------------;
; DAM  1/15/87 Added 'mainseg' to mos group.  This is the MEMMAN seg	;
;-----------------------------------------------------------------------;
; JRB  5/17/87 added code fragment to trick sidekick                	;
;-----------------------------------------------------------------------;
; SAH  7/14/87 added getkeys call to bugerror dead loop to Ctl-Alt-Del 	;
;-----------------------------------------------------------------------;
; SAH 09/18/87 added patch areas for both mosseg and mainseg. Current   ;
;	       size is 512 bytes each and the following is what to      ;
;	       search for:						;
;	       MOSSEG   -   "PATCH-MOS"   follow by 512 byte patch area ;
;              MAINSEG  -   "PATCH-MAIN"  follow by 512 byte patch area ;
;-----------------------------------------------------------------------;
; SAH 01/18/88 	Added initialization of 40:3fa and 40:03fc, conversion  ; 
;		of SCBSEG and zero access to MGetXXXX access.  Remove   ;
;		MAINSEG	patch area which is not needed.			;
;-----------------------------------------------------------------------;
; SAH 01/22/88  Change SCBSEG to MO2SEG for MOS 2nd segment		;
;-----------------------------------------------------------------------;
; SAH 02/12/88  Made changes necessary for MOS's new inter-segment calls;
;-----------------------------------------------------------------------;
; sah/rbr 02/21/88 Move DDT Segment to MO2 Group			;
;		remove mainseg which is not used			;
;		made patch size 128 bytes for MOS and MO2		;
;-----------------------------------------------------------------------;
; RBR 03/12/88  Created grpseg1 and grpseg2 to get addressability to    ;
;		grp in only one segment load, via the MGetSCB and 	;
;		MGetSCB2 macros.  This means that mosinit must write 	;
;		to code segments, but the performance improvement and 	;
;		space savings are significant.				;
;-----------------------------------------------------------------------;
; SAH 07/23/88  Change MOS segment so start of real MOS code is at 	;
;		origin of 1080h. Made Module compatible with OPTASM	;
;-----------------------------------------------------------------------;
; SAH 07/29/88	Added special call to SCBDUMP is available. This can be ;
;		useful for easly information debugging if buggerror	;
;		Passed with AH=1 to indicated that it happen here	;
;-----------------------------------------------------------------------;
; SAH 08/01/88	Added INIT segment for INIT code which will be 		;
;		discarded.						;
;-----------------------------------------------------------------------;
; BWR 11/28/89	Marked messages for foreign language translation.	;
;-----------------------------------------------------------------------;
; BWR 01/15/90	SCB aligned on 16-byte boundary.  This is done to	;
;		support the new GET_SCB_ADDRESS call that returns	;
;		a selector to the SCB.  (Before going to protected	;
;		mode, a segment address is returned).			;
;-----------------------------------------------------------------------;

	include	mosregs.inc

;-----------------------------------------------------------------------; 
; the following statement causes the assembler and linker to respect    ;
; our desire that the data in the gdata, mos, irq and poll segments be  ;
; addressable in the grp group                                          ;
;-----------------------------------------------------------------------;

grp     group   gdata,tcb,irq,poll
mos     group   mosseg
mo2	group	ddt
init	group	initseg

PATCHSIZE equ 512

gdata	segment page public 'data'
	assume	cs:grp,ds:nothing,es:nothing,ss:nothing
gstart	label	byte

	public	fgscboff

	extrn	gend:byte

	org	0100h

;-----------------------------------------------------------------------;
; from start to fgscboff is defined for purposes of non-rom'ed mos code ;
; the assumption is that the boot code loads mos into memory at some	;
; segment address and transfers to the start of the load image		;
; note: code below allows for starting at .COM file offset 0100H (so we ;
; can test it more easily) or at boot loader offset of 0000H (so we can ;
; boot it)								;
;									;
; if the code segment (mos) is rom'ed, then the assumption is that      ;
; execution somehow gets to the start of the mos segment (at mosstart)	;
;-----------------------------------------------------------------------;

start	proc	far
	jmp	grpx
	call	mosboot 	; xfr to remainder of bootstrap (must be @
				;   offset 3 into MOS file image)
grpx:
	call	grpofs
grpofs:
	pop	ax		; whether execution starts at 0100H or 0000H
	sub	ax,offset grp:grpofs 
	mov	cl,4
	sar	ax,cl
	mov	bx,cs
	add	bx,ax		; bx = true address of grp segment
	mov	ax,offset grp:gend+255	; defined in MOSBACK.ASM
	mov	al,0			;rs1
	mov	cl,4
	shr	ax,cl
	add	ax,bx

	mov	es,ax			;031288  init grp address in mo2
	assume	es:mo2			;031288
	mov	es:[grpseg2],bx		;031288

	push	ax			;rs1  save mo2 seg address
	mov	dx,offset mo2:mo2end+255 ;rs1  account for mo2 length
	mov	dl,0			;rs1
	shr	dx,cl			;rs1
	add	ax,dx			;rs1

	mov	es,ax		; es = true address of mos segment
	assume	es:mos

	pop	es:[mo2seg]	;rs1  init mo2 seg address in mo1
	mov	es:[grpseg1],bx	;031288  init grp address in mo1

        push    ax              ; crashes cx and dx which are assume to be
        push    ds              ; unimportant at this time of initialization

        mov     dx,00040h       ; NOTE this is a constant value
        mov     cx,ds           ; save current ds
        mov     ds,dx           ; make ds point to BIOS

        mov     ds:[03fah],bx
        xor     ax,ax           ; initialize value at 0040:03fc to 0000
        mov     ds:[03fch],ax   
        mov     ds,bx           ; access scb in ds
        assume  cs:nothing,ds:grp
        mov     [SCBBOOT],cx    ; save boot segment into SCB

        pop     ds
        assume  cs:grp,ds:nothing
        pop     ax

	mov	es:[bootseg],ds ; save segment location of boot sector
	mov	bx,es		; bx = mos segment address
	mov	ax,offset mos:mosend+15
	mov	cl,4
	shr	ax,cl
	add	ax,bx
	mov	es:[sinit],ax		;store start location of initseg
	mov	bx,offset init:initend+15
	shr	bx,cl
	add	ax,bx			; adjust for the lenght of INIT
	or	al,3
	mov	es:[scbfree],ax ; first free memory segment location for heap
	push	es		; far jmp to mosstart (below)
	mov	ax,offset mos:mosstart
	push	ax
	ret
start	endp

bootstrap segment at 0
	include	mboot.inc
bootstrap ends  
	assume	cs:grp,ds:bootstrap,es:nothing,ss:bootstrap

; es = segment address to start loading remainder of MOS
; bx = cluster address of first cluster of MOS
; ds, ss = bootstrap sector
; read through to end of file cluster
; must near return to MOS with ds -> boot sector

mosboot:
	mov	dx,bx
	call	nxtcls
	mov	bx,dx		; first cluster in remainder of read
	xor	cx,cx
; collect clusters while contiguous until eof
mboot1:
	inc	cx
	push	dx
	push	cx
	call	nxtcls
	pop	cx
	pop	di
	cmp	dx,0fff8h	; so di = 0fff7h doesn't compare contiguous
	jae	mboot2		;   to eof
	inc	di
	cmp	di,dx
	je	mboot1
; read all the contiguous ones then continue
	push	dx
	call	rdclust
	pop	dx
	mov	bx,dx
	xor	cx,cx
	jmp	mboot1
mboot2:
	call	rdclust
	ret			; ret to MOS startup
;
	subttl	get cluster number of next cluster in file
	page
;
; given dx = cluster number, return dx = next cluster in file
nxtcls:
	cmp	[bigfat],0
	jne	nxtcl2
; this one is a little (12-bit) fat
	mov	si,dx		;fat offset is cluster * 3 / 2
	add	dx,dx
	add	dx,si
	mov	si,dx		;si = fat offset * 2
; prepare for call to getcls
; si will be fat offset * 2 and will eventually be the offset within
;   the fat sector
; dx will be shifted right by cl to form the fat sector offset to be read
	mov	cl,[sctshft]	;cl prepared for / 2 for above + / sctsiz
	inc	cl		;  to find fat sector #
	call	getcls
	and	dx,0fffh	;and out any but meaningful 12 bit
	cmp	dx,0ff8h
	jb	nxtcl3
	or	dx,0f000h
	jmp	short nxtcl3
; this is for a big fat
nxtcl2:
	add	dx,dx
	mov	si,dx		;si & dx = fat offset
; prepare for call to getcls
; si will be fat offset * 2 and will eventually be the offset within
;   the fat sector
; dx will be shifted right by cl to form the fat sector offset to be read
	rcr	dx,1		;(c flag, if set by above, is significant)
	shl	si,1		;(as above we want fat offset * 2 )
	mov	cl,[sctshft]
	dec	cl		;already shifted right 1 above to get c flag
	call	getcls		
nxtcl3:
	ret

; this is here just because it was easy to transform the 16 bit logic in
; such a manner that all of this code could be shared to save space, and
; otherwise much of the code was duplicated, wasting space
; entry with ( si and (sctsiz*2-1) ) = byte offset of cluster within fat
;     sector * 2
;   dx shr cl = sector offset of cluster within fat
; exit with ( dx and (2 ^ fat entry size - 1) ) = next cluster

getcls:
	mov	ax,dx
	shr	ax,cl
	add	ax,[rsrvd]
	cmp	ax,[fatbuf]	;fat sector number currently in the buffer
	je	getcl1		;already in the buffer
	push	es
	mov	cx,ds
	add	cx,512/16	; pointing to fat buffers (bootbuf)
	mov	es,cx
	mov	cx,2		; 2 at a time in case entry is split across
	push	si
	xor	dx,dx
	push	ax
	call	read		;   2
	pop	ax
	pop	si
	pop	es
	mov	[fatbuf],ax	;else read it and remember it
getcl1:
	mov	cx,[sctsiz]
	shl	cx,1
	dec	cx
	and	si,cx		; si and (sctsiz*2)-1
	shr	si,1		;/2 for actual offset
	mov	dx,[si+512]
	jnc	getcl2
	mov	cl,4
	shr	dx,cl
getcl2:
	ret

	subttl	rdclust - read a bunch of clusters
	page

; read cx clusters starting at cluster bx into buffer at es
; adjust es past last read
; bx unchanged

rdclust:
	mov	al,[ausiz]
	xor	ah,ah
	xchg	ax,cx
	mul	cx
	xchg	ax,cx		; = total sectors to be read
	mov	dx,bx
	dec	dx
	dec	dx
	mul	dx
	add	ax,[cdata]
	adc	dx,0		; dx:ax = starting sector to read
	call	read
	ret

	align	16		; Ensure SCB on paragraph boundary.

fgscboff label	byte
	assume	cs:grp,ds:grp
	include MOSSCBDF.INC		; SCB definition include file
gdata	ends

	subttl	foreground TCB definition
	page

tcb	segment page 'data'
	public	fgtcboff
fgtcboff label	byte
	include MOSTCB.INC	; TCB definition
tcb	ends

irq	segment word public 'data'
	extrn	irqend:byte
	public	irqstart
irqstart label	byte	; specify the address of the first table entry by
			;   specifying the address of the start of irq segment
irq	ends

poll	segment word public 'data'
	extrn	pollend:byte
	public	pollstart
pollstart label byte	; specify the address of the first table entry by
			;   specifying the address of the start of poll segment
poll	ends

ddt     segment page public 'code2'
	assume  cs:mo2
	public  mo2start
mo2start label	byte
	
        extrn   callfun1:near,mo2end:byte
        public  sbios2
	public	grpseg2		;031288

sbios2  dw      0040h           ; !!SAH!! Temporary inside DDT seg
grpseg2	dw	0		;031288

	db	'PATCH-MO2'
mo2pat	db	PATCHSIZE dup (0)

ddt     ends

	page
mosseg	segment page public 'code1'
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

	public	mosstart, mo2seg, scbfree, bootseg, mo2fun, sbios
	public	grpseg1, sinit, sinitaddr, initcall

	extrn	mosend:byte
	extrn	mosinit:near, getkeys:near, MosCall:near
	
;-----------------------------------------------------------------------;
; mosstart is the first byte of the code segment - it also forces the	;
; cs register to be correct for the mos segment, regardless of how	;
; execution arrives here - so long as mos starts on a paragraph 	;
;-----------------------------------------------------------------------;

mosstart proc	far
	call	mosofs
mosofs: pop	ax		; what offset are we executing at
	sub	ax,offset mos:mosofs	; ax = byte correction to mos segment
	mov	cl,4
	sar	ax,cl		; ax = segment correction for mos execution
	mov	cx,cs
	add	ax,cx
	push	ax		; far transfer (with correct mos cs) to mosinit
	mov	ax,offset mos:mosinit
	push	ax
	ret
mosstart endp


; SAH	07/23/88 The following code starts at Origin 1080h and all code
;		 Before this in MOS segment is discarded when MOS finally
;		 Relocates it self during INITP5 during MOSINIT.
;
; Special Note:  For code size efficenciety part of MOS INIT code can be
;		 moved above this location which means that this code will
;		 not be include in final object image

	
	DB	1080h DUP (90h)	; start at 1080H
	ORG	1080h

; below locations are constant by the time we are executing in mosseg
; either they are built in to rom, or they are initialized by the startup
; code in grp
; The MOS2 label is used as a DWORD far call into the MOSFUTIL code area
; which resides in MO2

	even				;rs1
mo2fun	dw	offset mo2:callfun1	; Offset of MOS 2nd code fun depatcher
mo2seg	dw	?			; segment address of MOS 2nd code seg

; !!!SAH!!! the following 2 word will need to be remove later

scbfree dw	?		; segment address of first free memory
bootseg dw	?		; segment address of boot sector
				;   (startup default disk bpb starts at offset
				;   11 if ROMed with a 4 byte id at offset 3
				;   consisting of 'MOS '

;	following is a constant use for accessing the bios word at
;	40:03fa and 40:3fc for accessing scbseg (GRP) and ZERO segment

sbios	  dw	0040h
grpseg1	  dw	0		;031288
initcall  dw	offset INIT:InCall	; use for far calls to INIT segment
sinit	  dw	0			; Start address of INIT segment
sinitaddr dw	0			; address use in passing

	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

if1
	%out
	%out	* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	%out	*							*
endif

ifdef bugreport

if1
	%out	* debug option for internal error reporting is ON	*
endif

errmsg	db	0dh,0ah,'Internal error #',0 ;@@XLAT

; display string at return address from caller then hang

bugerror:
	cld
	sti
	MGetSCB	ds
	assume	ds:grp
	cmp 	word ptr [SCBDUMP+2],0
	je	nobugret
	mov	ah,1		
	call	dword ptr [SCBDUMP]	; call dumper
nobugret:	
	push	cs
	pop	ds
	lea	si,errmsg
	call	dspstr
	pop	si
	call	dspstr
	assume  ss:tcb
	cmp     [TCBTYPE], 'T'		; make sure we are at a TCB
	je      bugloop
	push    cs
	pop	ds
	MGetSCB	es
	assume  es:grp
	mov     ax, [SCBTCBPC]
	cli
	push	ax
	pop	ss
	sti	
bugloop:
	call	getkeys			; attempt to allow for Ctl-Alt-Del's
	jmp	short	bugloop

; display a null-terminated string at ds:si

dspstr:
	lodsb
	or	al,al
	jz	dspst1
	mov	ah,14
	mov	bx,7
	int	10h
	jmp	dspstr
dspst1:
	ret

else
if1
	%out	* debug option for internal error reporting is OFF	*
endif
endif

if1
	%out	*							*
	%out	* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
endif

;-----------------------------------------------------------------------;
;	This is a temporary home for the critical flag (SCBNOSWT)	;
;	routines.  Call NOSWITCH to tell you are in a critical section	;
;	of code and that no task switch is to take place, and call	;
;	OKSWITCH to tell MOS that it may now switch.			;
;	Note: There are duplicate routines in MOSFUN39 for use by code	;
;	that resides in the MO2 group.					;
;-----------------------------------------------------------------------;
	assume	cs:mos,ds:nothing,es:nothing,ss:nothing

public	noswitch, okswitch

noswitch proc	near
	push	ds
	MGetSCB	ds
	assume	ds:grp
	inc	[scbnoswt]
	pop	ds
	ret
noswitch endp

;-----------------------------------------------------------------------;
	assume	ds:nothing

okswitch proc	near
	push	ds
	MGetSCB ds
	assume	ds:grp
	dec	[scbnoswt]
	pop	ds
	ret
okswitch endp

	assume	ds:nothing

	 db	'PATCH-MOS'
mospat   db	PATCHSIZE dup(0)

mosseg ends

;	Following is use for defining the INIT segment

initseg	segment para public 'code3'
	extrn	InitEnd:byte
	extrn	InCall:near

	public imosaddr, mscall
	public InitStart, InitMos, InitMo2, InitGRP
InitStart label	byte
mscall   dw	offset MOS:MosCall ; Offset of routine to call in MOS segment
InitMos	 dw	0		   ; pointer to MOS segment for INIT segment
InitMo2  dw	0		   ; pointer to MO2 segment for INIT segment
InitGRP	 dw	0		   ; pointer to GRP segment for INIT segment
imosaddr dw	0		   ; address use in calling MOS from INIT
initseg	ends	
	end	start


