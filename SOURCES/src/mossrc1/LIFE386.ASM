	page	60,132

;--------------------------------------------------------------------;
;         "LIFE" Pattern Generator for 80386 Native Mode             ;
;--------------------------------------------------------------------;
;								     ;
;  This program is designed to be assembled and linked using 386ASM  ;
;  and 386LINK from Phar Lap Software, Inc.  Use the following       ;
;  syntax:							     ;
;								     ;
;	386asm  life386						     ;
;	386link life386 -8086 -map con				     ;
;								     ;
;--------------------------------------------------------------------;

;------------------------- Revision Log --------------------------------;
;									;
; BWR	10/27/89	Marked messages for foreign language 		;
;			translation.					;
;									;
;-----------------------------------------------------------------------;
.386

;------------------------ Equates for Sizes -------------------------;

BPR	equ	320/8		; Bytes Per Row 
RPS	equ	200		; Rows Per Screen

dataseg segment para public use32 'data'

	db	'**DATA SEGMENT**'

;----------------------- Generation Variables -----------------------;

xcount	dd	0		; number of cells left in current row
ycount	dd	0		; current row number
ltindex	dd	0		; indexes into lifetables
fromseg dw	0		; source lifetable segment address
toseg	dw	0		; target lifetable segment address

;----------------- Video Hardware-related Variables -----------------;

	even
vidoff	dd	0		; current video offset and segment
vidseg	dw	0
cgaseg	dw	0

msgmem	db	13,10,'Insufficient extended memory is available!',13,10 ;@@XLAT
msgmeml	equ	$-msgmem

	page
;------------------------- Starting Array ---------------------------;

	even
ltable1 label	byte
	db	BPR dup(0)			; dummy line at front

        db	(RPS/2-6)*BPR dup(0)
 	db	25 dup(0),1,(BPR-26) dup(0)
 	db	25 dup(0),1,(BPR-26) dup(0)
 	db	25 dup(0),1,(BPR-26) dup(0)
 	db	25 dup(0),1,(BPR-26) dup(0)
 	db	25 dup(0),1,(BPR-26) dup(0)
 	db	18 dup(0),9 dup(-1),(BPR-27) dup(0)
        db	(RPS/2)*BPR dup(0)

	db	BPR dup(0)			; dummy line at end

;----------------- Video Translation Table for Pixels ---------------;

	even
vttable label 	word
.xlist
	dw	0000000000000000b 
	dw	0100000000000000b
	dw	0001000000000000b 
	dw	0101000000000000b
	dw	0000010000000000b 
	dw	0100010000000000b
	dw	0001010000000000b 
	dw	0101010000000000b
	dw	0000000100000000b 
	dw	0100000100000000b
	dw	0001000100000000b 
	dw	0101000100000000b
	dw	0000010100000000b 
	dw	0100010100000000b
	dw	0001010100000000b 
	dw	0101010100000000b
	dw	0000000001000000b 
	dw	0100000001000000b
	dw	0001000001000000b 
	dw	0101000001000000b
	dw	0000010001000000b 
	dw	0100010001000000b
	dw	0001010001000000b 
	dw	0101010001000000b
	dw	0000000101000000b 
	dw	0100000101000000b
	dw	0001000101000000b 
	dw	0101000101000000b
	dw	0000010101000000b 
	dw	0100010101000000b
	dw	0001010101000000b 
	dw	0101010101000000b
	dw	0000000000010000b 
	dw	0100000000010000b
	dw	0001000000010000b 
	dw	0101000000010000b
	dw	0000010000010000b 
	dw	0100010000010000b
	dw	0001010000010000b 
	dw	0101010000010000b
	dw	0000000100010000b 
	dw	0100000100010000b
	dw	0001000100010000b 
	dw	0101000100010000b
	dw	0000010100010000b 
	dw	0100010100010000b
	dw	0001010100010000b 
	dw	0101010100010000b
	dw	0000000001010000b 
	dw	0100000001010000b
	dw	0001000001010000b 
	dw	0101000001010000b
	dw	0000010001010000b 
	dw	0100010001010000b
	dw	0001010001010000b 
	dw	0101010001010000b
	dw	0000000101010000b 
	dw	0100000101010000b
	dw	0001000101010000b 
	dw	0101000101010000b
	dw	0000010101010000b 
	dw	0100010101010000b
	dw	0001010101010000b 
	dw	0101010101010000b
	dw	0000000000000100b 
	dw	0100000000000100b
	dw	0001000000000100b 
	dw	0101000000000100b
	dw	0000010000000100b 
	dw	0100010000000100b
	dw	0001010000000100b 
	dw	0101010000000100b
	dw	0000000100000100b 
	dw	0100000100000100b
	dw	0001000100000100b 
	dw	0101000100000100b
	dw	0000010100000100b 
	dw	0100010100000100b
	dw	0001010100000100b 
	dw	0101010100000100b
	dw	0000000001000100b 
	dw	0100000001000100b
	dw	0001000001000100b 
	dw	0101000001000100b
	dw	0000010001000100b 
	dw	0100010001000100b
	dw	0001010001000100b 
	dw	0101010001000100b
	dw	0000000101000100b 
	dw	0100000101000100b
	dw	0001000101000100b 
	dw	0101000101000100b
	dw	0000010101000100b 
	dw	0100010101000100b
	dw	0001010101000100b 
	dw	0101010101000100b
	dw	0000000000010100b 
	dw	0100000000010100b
	dw	0001000000010100b 
	dw	0101000000010100b
	dw	0000010000010100b 
	dw	0100010000010100b
	dw	0001010000010100b 
	dw	0101010000010100b
	dw	0000000100010100b 
	dw	0100000100010100b
	dw	0001000100010100b 
	dw	0101000100010100b
	dw	0000010100010100b 
	dw	0100010100010100b
	dw	0001010100010100b 
	dw	0101010100010100b
	dw	0000000001010100b 
	dw	0100000001010100b
	dw	0001000001010100b 
	dw	0101000001010100b
	dw	0000010001010100b 
	dw	0100010001010100b
	dw	0001010001010100b 
	dw	0101010001010100b
	dw	0000000101010100b 
	dw	0100000101010100b
	dw	0001000101010100b 
	dw	0101000101010100b
	dw	0000010101010100b 
	dw	0100010101010100b
	dw	0001010101010100b 
	dw	0101010101010100b
	dw	0000000000000001b 
	dw	0100000000000001b
	dw	0001000000000001b 
	dw	0101000000000001b
	dw	0000010000000001b 
	dw	0100010000000001b
	dw	0001010000000001b 
	dw	0101010000000001b
	dw	0000000100000001b 
	dw	0100000100000001b
	dw	0001000100000001b 
	dw	0101000100000001b
	dw	0000010100000001b 
	dw	0100010100000001b
	dw	0001010100000001b 
	dw	0101010100000001b
	dw	0000000001000001b 
	dw	0100000001000001b
	dw	0001000001000001b 
	dw	0101000001000001b
	dw	0000010001000001b 
	dw	0100010001000001b
	dw	0001010001000001b 
	dw	0101010001000001b
	dw	0000000101000001b 
	dw	0100000101000001b
	dw	0001000101000001b 
	dw	0101000101000001b
	dw	0000010101000001b 
	dw	0100010101000001b
	dw	0001010101000001b 
	dw	0101010101000001b
	dw	0000000000010001b 
	dw	0100000000010001b
	dw	0001000000010001b 
	dw	0101000000010001b
	dw	0000010000010001b 
	dw	0100010000010001b
	dw	0001010000010001b 
	dw	0101010000010001b
	dw	0000000100010001b 
	dw	0100000100010001b
	dw	0001000100010001b 
	dw	0101000100010001b
	dw	0000010100010001b 
	dw	0100010100010001b
	dw	0001010100010001b 
	dw	0101010100010001b
	dw	0000000001010001b 
	dw	0100000001010001b
	dw	0001000001010001b 
	dw	0101000001010001b
	dw	0000010001010001b 
	dw	0100010001010001b
	dw	0001010001010001b 
	dw	0101010001010001b
	dw	0000000101010001b 
	dw	0100000101010001b
	dw	0001000101010001b 
	dw	0101000101010001b
	dw	0000010101010001b 
	dw	0100010101010001b
	dw	0001010101010001b 
	dw	0101010101010001b
	dw	0000000000000101b 
	dw	0100000000000101b
	dw	0001000000000101b 
	dw	0101000000000101b
	dw	0000010000000101b 
	dw	0100010000000101b
	dw	0001010000000101b 
	dw	0101010000000101b
	dw	0000000100000101b 
	dw	0100000100000101b
	dw	0001000100000101b 
	dw	0101000100000101b
	dw	0000010100000101b 
	dw	0100010100000101b
	dw	0001010100000101b 
	dw	0101010100000101b
	dw	0000000001000101b 
	dw	0100000001000101b
	dw	0001000001000101b 
	dw	0101000001000101b
	dw	0000010001000101b 
	dw	0100010001000101b
	dw	0001010001000101b 
	dw	0101010001000101b
	dw	0000000101000101b 
	dw	0100000101000101b
	dw	0001000101000101b 
	dw	0101000101000101b
	dw	0000010101000101b 
	dw	0100010101000101b
	dw	0001010101000101b 
	dw	0101010101000101b
	dw	0000000000010101b 
	dw	0100000000010101b
	dw	0001000000010101b 
	dw	0101000000010101b
	dw	0000010000010101b 
	dw	0100010000010101b
	dw	0001010000010101b 
	dw	0101010000010101b
	dw	0000000100010101b 
	dw	0100000100010101b
	dw	0001000100010101b 
	dw	0101000100010101b
	dw	0000010100010101b 
	dw	0100010100010101b
	dw	0001010100010101b 
	dw	0101010100010101b
	dw	0000000001010101b 
	dw	0100000001010101b
	dw	0001000001010101b 
	dw	0101000001010101b
	dw	0000010001010101b 
	dw	0100010001010101b
	dw	0001010001010101b 
	dw	0101010001010101b
	dw	0000000101010101b 
	dw	0100000101010101b
	dw	0001000101010101b 
	dw	0101000101010101b
	dw	0000010101010101b 
	dw	0100010101010101b
	dw	0001010101010101b 
	dw	0101010101010101b
.list
dataseg ends

stakseg segment para stack use32 'stack'
	db	128 dup('Stak')
stakseg ends

	page
;--------------------------------------------------------------------;
;                              Begin                                 ;
;--------------------------------------------------------------------;

mainseg segment	para public use32 'code'
	assume  cs:mainseg,ds:dataseg,ss:stakseg

;------------ The following section runs in Virtual Mode ------------;

entry	label	near
	mov	ax,ds		; fix DS register
	mov	bh,0
	mov	bl,10h
	add	eax,ebx
	mov	ds,ax
	mov	ah,0b8h		; point es to video RAM
	mov	al,0
	mov	es,ax
	mov	ah,10h		; go to native mode
	mov	dx,cs		; compute NCA segment address
	mov	ch,1024/256	; tell MOS the NCA's length
	mov	cl,0 
	jmp	start+2		; +2 compensates for the fact that the
				;   assembler doesn't know that this 
				;   instruction executes in 16-bit mode

	org	entry+1024 	; make room for the NCA

start	label	near
	int	38h		; execute switch to native mode

	page
;--------------------------------------------------------------------;
;                    We are now in Native Mode                       ;
;--------------------------------------------------------------------;

	mov	[cgaseg],es		; save video RAM selector
 	call	setgr			; set graphics mode
	jc	memerror		; abort if error

	mov	ah,11h			; allocate a memory block
	mov	ebx,BPR*(RPS+2)+16	; tell the length
	int	38h
	jc	memerror		; jump if allocation error
	mov	[fromseg],es		; save the new selector

	mov	ah,11h			; allocate another memory block
	mov	ebx,BPR*(RPS+2)+16	; tell the length
	int	38h
	jc	memerror		; jump if allocation error
	mov	[toseg],es		; save the new selector

	mov	edi,16			; zap in starting array
	mov	esi,offset ltable1
	mov	ecx,BPR*(RPS+2)/4
	cld
	rep	movsd

	page
;--------------------------------------------------------------------;
;                      Process Next Generation                       ;
;--------------------------------------------------------------------;

prgen	label	near
	mov	ax,[fromseg]		; swap source with target segment
	xchg	ax,[toseg]
	mov	[fromseg],ax

	call	vidswap			; swap video buffers 

	cld
	xor	eax,eax
	mov	es,[toseg]		; clear new target lifetable
	mov	edi,16
	mov	ecx,BPR*(RPS+2)/4
	rep	stosd

	push	ds
	mov	es,[fromseg]		; zap in dummy rows at begin and end
	mov	ds,[fromseg]
	mov	edi,16
	mov	esi,BPR*RPS+16
	mov	ecx,BPR/4
	rep	movsd
	mov	edi,BPR*(RPS+1)+16
	mov	esi,BPR+16
	mov	ecx,BPR/4
	rep	movsd
	pop	ds

	mov	[ycount],0		; set starting row number
	mov	[ltindex],BPR+16	; and starting lifetable index

	mov	ah,1
	int	16h
	jz	prloop			; jump if no key is buffered
	jmp	termin8

	page
;--------------------------------------------------------------------;
;                         Process Next Row                           ;
;--------------------------------------------------------------------;

prloop	label	near
	mov	ebx,[ycount]
	call	rowconv			; compute video offset in ax
	mov	[vidoff],eax
	mov	[xcount],BPR/2-1	; words per row - 1

	mov	ebx,[ltindex]
	mov	edx,[xcount]
	mov	ebp,[vidoff]

;-------------------------- Process a Word --------------------------;

pbloop1 label	near
	push	ds
	mov	ds,[fromseg]		; address source cells
pbloop2:
	mov	ecx,[ebx]
	mov	esi,[ebx-BPR]		; get bits
	mov	edi,[ebx+BPR]
	mov	eax,esi			; skip it if nothing is there
	or	eax,ecx
	or	eax,edi
	jnz	short pbcalc
pbcalbak:
	add	ebx,2			; bump lifetable index
	add	ebp,4			; bump video workarea pointer
	dec	edx			; decrement word count
	jnz	pbloop2

	pop	ds
pbnxrow:
	call	wraprow			; process first and last byte
	mov	[ltindex],ebx
	mov	[vidoff],ebp
	inc	[ycount]		; count rows
	cmp	[ycount],RPS 
	jb	prloop
	jmp	prgen			; process next generation
pbcalc:
	test	eax,0003ffffh		; performance enhancement here
	jz	pbcalbak

	pop	ds
	mov	[ltindex],ebx
	mov	[vidoff],ebp
	mov	[xcount],edx

	call	calcgen			; compute next-generation cells
	mov	es,[toseg]
	mov	esi,[ltindex]
	or	es:[esi],ebx

	xor	ecx,ecx			; get vttable indexes in ebx,ecx
	shr	ebx,1
	xchg	cl,bh
	shl	ebx,1
	shl	ecx,1

	mov	es,[vidseg]
	mov	edi,[vidoff]		; current video position
	cld
	mov	ax,[ebx+vttable]	; translate the bits for display
	xchg	al,ah
	stosw
	mov	ax,[ecx+vttable]	; translate the bits for display
	xchg	al,ah
	stosw

	mov	ebx,esi			; ltindex
	mov	ebp,edi			; vidpos
	mov	edx,[xcount]

	add	ebx,2
	dec	edx
	jnz	pbloop1
	jmp	pbnxrow

	page
;------------------- Handle Horizontal Wraparound -------------------;

wraprow proc	near
	push	ds
	mov	ds,[fromseg]
	mov	ecx,[ebx-BPR]
	mov	cx,[ebx]
	mov	eax,[ebx-BPR-BPR]
	mov	ax,[ebx-BPR]
	mov	esi,eax
	mov	eax,[ebx]
	mov	ax,[ebx+BPR]
	mov	edi,eax
	pop	ds
	mov	[ltindex],ebx
	mov	[vidoff],ebp
	mov	[xcount],edx
	call	calcgen			; compute next-generation cells
	mov	es,[toseg]
	mov	esi,[ltindex]
	or	es:[esi],bx
	mov	ecx,ebx
	xor	bx,bx
	or	es:[esi-BPR],ebx

	xor	ebx,ebx			; get vttable indexes in ebx,ecx
	shr	ecx,1
	xchg	bl,ch
	shl	ecx,1
	shl	ebx,1

	mov	es,[vidseg]
	mov	edi,[vidoff]		; current video position
	cld
	mov	ax,[ecx+vttable]	; translate the bits for display
	xchg	al,ah
	stosw
	mov	ax,[ebx+vttable]	; translate the bits for display
	xchg	al,ah
	stosw

	mov	ebx,esi			; ltindex
	mov	ebp,edi			; vidoff
	mov	edx,[xcount]
	add	ebx,2
	dec	edx
	ret
wraprow endp

	page
;--------------------------------------------------------------------;
;               Compute 16 cells for next generation                 ;
;--------------------------------------------------------------------;
; input:							     ;
;	esi,ecx,edi bits 0-17 are from previous, current, next rows  ;
; output:							     ;
;	ebx bits 1-16 are next-generation bits for the current row   ;
;	ebx bits 0 and 17-31 are always returned as zero	     ;
;	eax,ecx,edx,esi,edi are trashed				     ;
;--------------------------------------------------------------------;

calcgen	proc	near

	mov	ebx,00008000h	; when the 1 bit is shifted out we are done

	xor	eax,eax
	mov	edx,eax

	ror	esi,1		; al,dl,dh is the order
	adc	al,ah
	ror	ecx,1
	adc	al,ah
	ror	edi,1
	adc	al,-1

	ror	esi,1
	adc	dl,ah
	ror	ecx,1
	adc	dl,ah
	ror	edi,1
	adc	dl,-1

	ror	esi,1
	adc	dh,ah
	ror	ecx,1
	adc	dh,ah
	ror	edi,1
	adc	dh,-1

	add	al,dl
	add	al,dh
	jz	short live1	; vacant + 3 neighbors, or occupied + 2
	dec	al
	jz	short maybe1
back1:
	shr	ebx,1
bitloop:
	mov	al,ah		; dl,dh,al is the new order

	ror	esi,1
	adc	al,ah
	ror	ecx,1
	adc	al,ah
	ror	edi,1
	adc	al,-1

	add	dl,dh
	add	dl,al
	jz	short live2
	dec	dl
	jz	short maybe2
back2:
	shr	ebx,1

	mov	dl,ah		; dh,al,dl is the new order

	ror	esi,1
	adc	dl,ah
	ror	ecx,1
	adc	dl,ah
	ror	edi,1
	adc	dl,-1

	add	dh,al
	add	dh,dl
	jz	short live3
	dec	dh
	jz	short maybe3
back3:
	shr	ebx,1

	mov	dh,ah		; al,dl,dh is the new order

	ror	esi,1
	adc	dh,ah
	ror	ecx,1
	adc	dh,ah
	ror	edi,1
	adc	dh,-1

	add	al,dl
	add	al,dh
	jz	short live4
	dec	al
	jz	short maybe4
back4:
	shr	ebx,1
	jnc	bitloop
	ret

maybe1:
	test	ecx,40000000h 
	jz	back1 
live1:
	or	ebx,00020000h
	jmp	back1
maybe2:
	test	ecx,40000000h 
	jz	back2 
live2:
	or	ebx,00020000h
	jmp	back2
maybe3:
	test	ecx,40000000h 
	jz	back3 
live3:
	or	ebx,00020000h
	jmp	back3
maybe4:
	test	ecx,40000000h 
	jz	back4 
live4:
	or	ebx,00020000h
	jmp	back4

calcgen	endp

	page
;--------------------------------------------------------------------;
;                           Termination                              ;
;--------------------------------------------------------------------;

termin8 label	near
	call	settx 
release:
	mov	ah,12h			; release all acquired memory
	mov	es,[vidseg]
	int	38h
	mov	ah,12h 
	mov	es,[fromseg]
	int	38h
	mov	ah,12h 
	mov	es,[toseg]
	int	38h

	mov	ax,4c00h		; exit back to MOS
	int	21h

;------------------------ Error Termination -------------------------;

memerror label	near			; enter here if memory error
	call	settx			; back to text mode
	mov	ah,40h			; write error message
	mov	bx,1			; to standard output
	mov	ecx,msgmeml
	lea	edx,[msgmem]
	int	21h
	jmp	short release

	page
;--------------------------------------------------------------------;
;                     Graphics Hardware Support                      ;
;--------------------------------------------------------------------;

;------------------------ Set Graphics Mode -------------------------;

setgr	proc	near
	mov	ax,0004h		; 320x200 color mode
	int	10h
	mov	ah,11			; set color
	mov	bx,0000h		; black for background (color 0)
	int	10h
	mov	ah,11			; set color
	mov	bx,0101h		; cyan/magenta/white for colors 1/2/3
	int	10h

	mov	ah,11h			; allocate another memory block
	mov	ebx,4000h		; tell the length
	int	38h
	jc	setgret			; jump if allocation error
	mov	[vidseg],es		; save the new selector

	xor	edi,edi			; zap in starting array
	mov	ecx,4000h/4
	xor	eax,eax
	cld
	rep	stosd
	clc
setgret:
	ret
setgr	endp

;-------------------------- Set Text Mode ---------------------------;

settx	proc	near
	mov	ax,0003h		; 80x25 color mode
	int	10h
	ret
settx	endp

	page
;----- display newly-created video buffer and clear the old one -----;

vidswap proc	near
	push	ds
	mov	es,[cgaseg]		; move work buffer to video RAM
	mov	ds,[vidseg]
	xor	edi,edi
	xor	esi,esi
	mov	ecx,4000h/4
	cld
	rep	movsd
	pop	ds

	xor	eax,eax			; clear work buffer
	mov	es,[vidseg]
	xor	edi,edi
	mov	ecx,4000h/4
	rep	stosd
	ret
vidswap endp

;------------- Convert Row Number to CGA Buffer Offset --------------;

rowconv proc	near
	ror	bx,1
	shr	bh,1
	shr	bh,1
	xor	eax,eax
	mov	al,80
	mul	bl
	add	ah,bh
	ret
rowconv endp

mainseg ends
	end	entry
