	include PAGE.INC
	title	MOSBACK.ASM - the last MOS module to link

;-----------------------------------------------------------------------;
;									;
;		Development Specification				;
;									;
;									;
; Program Name: MOS		Assigned to: Jim Bean, David Morrow	;
; Module Name:	MOSBACK		Assign date: 01/01/86			;
; Entry Points: n/a		Completed:   02/06/86			;
; Entry From:	n/a							;
; Entry Method:	n/a							;
; Calls:	n/a							;
; Purpose:	Establish end pointers in each of the MOS segments, as	;
;		well as specifying the last entries of the irq and poll	;
;		segment tables						;
; Refer to:	n/a							;
; Last Update:	02/24/86						;
;									;
;-----------------------------------------------------------------------;
; jrb 02/24/86 								;
; changed grouping of segments for romability				;
;-----------------------------------------------------------------------;
; sah\rdr 02/21/88 Move DDT Segment to MO2 Group			;
;-----------------------------------------------------------------------;
; SAH 	08/01/88	Added INIT Segment for INIT Code which is	;
;			discarded.					;
;-----------------------------------------------------------------------;

	include GROUP.INC

	.xlist
tcb	segment	at 1234h
	include	MOSTCB.INC	; TCB definition
tcb	ends

gdata	segment	word public 'data'
	include	MOSSCBEX.INC	; specify all SCB items as external
gdata	ends

	.list
;-----------------------------------------------------------------------;
;									;
; the irq segment is used (if needed) within a MOS module for defining 	;
; a mos interrupt handler						;
; 									;
; this is the last irq table entry (flagged with 0ffffh) as well as	;
; specifying the ending address in the segment				;
;-----------------------------------------------------------------------;

irq	segment	byte public 'data'
	extrn	irqstart:byte

	public	irqend
	
	dw	0ffffh	; this would be offset into interrupt table
			;   (0ffffh means the end of the table)
	dw	?	; boot vector value for interrupt would be here
	dw	0	; this would be the offset in the TCB (0 for n/a)
	dw	0	; this is the first level handler
	dw	0	; this is the second level handler

irqend	label	byte	; specify the last offset into this segment, and thus
			; the end of the irq table
irq	ends


poll	segment	byte public 'data'
	extrn	pollstart:byte

	public	pollend

	dw	-1	; this would be the address of the subroutine
			;   (0ffffh means the end of the table)
	dw	0	; this would be nxttmr (0 means it's inactive)
	dw	0	; this would be the offset in the TCB for timer value
			;   (0 means look at nxttmr)

pollend	label	byte	; specify the last offset into this segment, and thus
			; the end of the poll table
poll	ends

	subttl	gend segment - END of data segments
	page

;-----------------------------------------------------------------------;
; define the last byte in the data segment grp				;
;-----------------------------------------------------------------------;

gback	segment	word public 'data'
	public	gend
gend	equ	this byte
gback	ends


ddt     segment word public 'code2'
	assume cs:mo2
	public mo2end
mo2end	label	byte		; specifiying end of MO2 Segment
ddt     ends
				
mosseg	segment	word public 'code1'
	assume	cs:mos,ds:grp,es:nothing,ss:tcb
	public	mosend
mosend	label	byte		; specifying the end of the mos kernel code
				; in case we need it for something
mosseg	ends

init	group	initseg
initseg	segment	word public 'code3'
	public initend
initend label	byte
initseg	ends

	end
