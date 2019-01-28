page 90, 132
comment ^==============================================================

 module name:		moscnf.inc
 creation date:		03/26/91
 revision date:		
 author: 		mjs
 description:		def of config.sys buffer

		(c) copyright 1991, the software link inc.
			all rights reserved

======================================================================^


cnfbuf	segment at 1234h
cnfpre	db	16 dup(?)		; heap prefix

; starting at offset ddnum, through ddinitcnt bytes, memory
; allocated for this structure is initialized to 0s.
; this is done within readcnf (mosinit2.asm)

ddnum	dw	0			; offset counter
mmdev1	dw	0			; pointer to memdev filename
mmdev2	db	0,0			; length of memdev filename and parms
ddrecsiz equ	6
ddrecs	equ	80
ddtable db	ddrecs*ddrecsiz dup(0)	; room for 80 drivers (6 bytes each)
ddtlen	equ	($-cnfpre+15)/16	; # segs needed for ddtable
ddinitcnt equ	$-ddnum
cnffile db	?			; actual config.sys file starts here
cnfbuf	ends

