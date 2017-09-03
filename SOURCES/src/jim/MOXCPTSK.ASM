	title	moxcptsk  -  mos command processor entry stub
	include	page.inc

comment ^===============================================================
	     development specification

program name:	command.com		assigned to: martin stitt
module name:	moxcptsk		assign date: 08/07/86
entry points:	moxcptsk		completed:
entry from:	exec
entry method:
purpose:	entry to $$shell.sys
refer to:
last update:	05/01/91

=======================================================================

mjs 7/22/87	changed entry method from int 0ffh to use a segment
		pointer from SCBCPSEG

sah 11/04/87	Notice that I could reduce COMMAND.COM size a little
		bit while investigating problem with PACK EXE's

sah 05/12/88	Made sure that we did not do an INT 38 because some
		applications that are compiled with MS-C and load
		command.com as overlay INT 38 will not be pointing
		to original vector.   This was the case in DataFlex

mjs 05/01/91	gave this module its own local stack to insure that
		an exec of command.com done when only a little tpa
		is left will not result in a stack conflict.

=======================================================================^

scbs	segment at 0
	assume	cs:scbs
	include	mosscbdf.inc
scbs	ends

codeseg	segment	
	org	0100h
	assume	cs:codeseg,es:codeseg,ds:codeseg,ss:codeseg
taskstart:
	mov	sp,offset stacktop
	push	es

; use int21fun34 to gain scb addressability

	mov	ah,34h
	int	21h
	sub	bx,offset scbinmos
	assume  es:scbs
	mov	ax,es:[bx+scbcpseg]
	pop	es
	assume	es:codeseg

; enter $$shell.sys at segment scbcpseg, offset 0

	xor	bx,bx
	push	ax
	push	bx	
	retf

	even
	db	100 dup('stack')
stacktop label byte

codeseg	ends
	end	taskstart

