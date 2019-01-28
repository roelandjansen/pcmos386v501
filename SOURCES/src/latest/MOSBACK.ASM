	include page.inc
	title	mosback.asm - the last mos module to link
comment ^===============================================================
		    development specification

 program name:	$$mos.com		assigned to: jim bean, david morrow
 module name:	mosback			assign date: 01/01/86
 entry points:	n/a			completed:   02/06/86
 entry from:	n/a
 entry method:	n/a
 calls:		n/a
 purpose:	establish end pointers in each of the mos segments, as
		well as specifying the last entries of the irq and poll
		segment tables
 refer to:	n/a
 last update:	08/18/1992
========================================================================

jrb 02/24/86	changed grouping of segments for romability

sah\rdr 02/21/88 move ddt segment to mo2 group

sah 08/01/88	added init segment for init code which is discarded.

================ 5.01 Kernel Ends Here ====================================

mjs 08/18/92	clean up segment declarations

======================================================================^

.xlist
;	include mosback.pub
	include group.inc
.list

irq	segment
	extrn	irqstart:byte

	public	irqend

	dw	0ffffh			; this would be offset into interrupt table
					;   (0ffffh means the end of the table)
	dw	?			; boot vector value for interrupt would be here
	dw	0			; this would be the offset in the tcb (0 for n/a)
	dw	0			; this is the first level handler
	dw	0			; this is the second level handler

irqend	label	byte			; specify the last offset into this segment, and thus
					; the end of the irq table
irq	ends

poll	segment
	extrn	pollstart:byte

	public	pollend

	dw	-1			; this would be the address of the subroutine
					;   (0ffffh means the end of the table)
	dw	0			; this would be nxttmr (0 means it's inactive)
	dw	0			; this would be the offset in the tcb for timer value
					;   (0 means look at nxttmr)

pollend label	byte			; specify the last offset into this segment, and thus
					; the end of the poll table
poll	ends

	subttl	gend segment - end of data segments
	page

;-----------------------------------------------------------------------
; define the last byte in the data segment grp
;-----------------------------------------------------------------------

gback	segment byte public 'data'
	public	gend
gend	equ	this byte
gback	ends


;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume cs:mo2
	public mo2end
mo2end	label	byte			; specifiying end of mo2 segment
ddt	ends

;======================================================== mos segment
if 0 eq 0
segment_num = 1
endif
mosseg	segment
	assume	cs:mos,ds:grp,es:nothing,ss:nothing
	public	mosend
mosend	label	byte			; specifying the end of the mos kernel code
					; in case we need it for something
mosseg	ends

;======================================================== init segment
if 0 eq 0
segment_num = 3
endif
init	group	initseg
initseg segment
	public initend
initend label	byte
initseg ends

fcseg	segment
	db	0			; end of list marker
fcseg	ends

	end

