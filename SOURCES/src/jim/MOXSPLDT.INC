;
;****************************************************************************
;
;	Module name:	MOXSPLDT.INC
;
;	Creation date:	???
;
;	Revision date:	17-Apr-90
;
;	Author: 	B. W. Roeser
;
;	Description:	Common stuff for spooler
;
;
;		(C) Copyright 1990, The Software Link Inc.
;			All Rights Reserved
;
;****************************************************************************
;			>> Revision Log <<
;
; Date		Prog		Description of Revision
; ----		----		-----------------------
; 4/17/90	BWR		Fixed for Extended keyboard use of spooler
;				menu.
;
;****************************************************************************
;
; Following variables are common to all spool streams

fileseq	dw	0	; sequence number for filename
hotkey	dw	7700h	; Hot-key sequence for spooler window. (CTL-HOME)

	align	16	; data structures must be on paragraph boundrary

SPLDOFF	equ	1	; paragraphs to spool data segments


; Following structure exists for each spool stream
; Array of structures is terminated by a zero byte (no printers)

SPOOLDAT struc
printer	db	0		; bits define which printers use this stream
				; 1 => LPT1, 2 => LPT2, 4 => LPT3

		; while each buffer includes a full pathname
		; all printers should be spooled to the same directory

pathlen	dw	9		; length of spool directory path
filpath db	55 dup(' ')	; leave room for full size path
	db	'C:\SPOOL\'	; default drive/path
filname db	'SPL00???.D2A',0; default filename

timeout	dw	328		; ticks to timeout close of stream 18*18.2
timebeg	dw	0		; last printer access tick

seclass	db	0		; spool file security class

iopsp	dw	0		; PSP for spooler I/O
handle	dw	-1		; handle if open, else -1
buffpnt dw	0		; pointer into buffer
buffer	db	4*512 dup(0)	; buffer for printer data
SPOOLDAT ends

SPLDPARS equ	(SIZE SPOOLDAT + 15) SHR 4

SPLNAME	equ	 2	; offset to spool system name
SPLTASK	equ	 3	; task number in spool name
SPLSEQ	equ	 5	; spool sequence number
SPLDISP	equ	 9	; spooling disposition in filename
SPLPRIO	equ	10	; spool file priority
SPLCLAS	equ	11	; spool class

;spldata SPOOLDAT <>	; define 3 spool segments
	.xlist
spldata	SPOOLDAT <>	; spool data structures
	align	16
	SPOOLDAT <>
	align	16
	SPOOLDAT <>
	align	16
	SPOOLDAT <>
	align	16
	.list
	dw	0	; end of spool buffers
