comment ^===============================================================
		     development specification

 program name:	patch???.sys		   assigned to: martin stitt
 module name:	patchmac.inc		   assign date: 03/31/92
 entry points:	n/a			   completed:
 entry from:	n/a
 entry method:	n/a
 purpose:	patch driver support macros
 refer to:	n/a
 last update:	04/17/92

=======================================================================

mjs 03/31/92	develop initial version

mjs 04/17/92	Corrections for handling multiable plist macros
SAH
======================================================================^

; operation codes for LSEG1

LCODE_EOL	equ	0		; end of list marker
LCODE_SETSEG	equ	1		; init a segment operand
LCODE_SETFJM	equ	2		; write a far jump in mos
LCODE_SETFCM	equ	3		; write a far call in mos
LCODE_INITCALL	equ	4		; call an init function
LCODE_PLIST	equ	5		; call process_plist
LCODE_CSHELL	equ	6		; write a far/near calling shell

; segment codes

MOS		equ	0
MO2		equ	1
MOSINIT		equ	2

; opcode codes

FAR_CALL_OPCODE		equ	09ah
FAR_JMP_OPCODE		equ	0eah
NEAR_CALL_OPCODE	equ	0e8h
FAR_RET_OPCODE		equ	0cbh

; macros

;======================================================================
;.fs
; fj_p2m - macro to generate a far jump within this driver
;
; generate code for a far jump from this patch driver to mos
;
; in:	seg_code = MOS, MO2 or INIT
;	ofs1 = the offset within mos to be jumped to
;
; out:	
;
;.fe
;=====================================================================^
fj_p2m	macro	seg_code, ofs1
local	x1
	db	FAR_JMP_OPCODE
	dw	ofs1
x1	dw	?

LSEG1	segment
	db	LCODE_SETSEG
	dw	patch_version
	db	seg_code
	dw	dgroup:x1
LSEG1	ends

	endm

;======================================================================
;.fs
; fj_m2p - macro to generate a far jump within mos, jumping to patch driver
;
; generate code for a far jump from mos to this patch driver
;
; in:	seg_code = MOS, MO2 or INIT
;	ofs1 = the offset within mos to write the far jump
;	ofs2 = the offset within this driver to jump to
;
; out:	
;
;.fe
;=====================================================================^
fj_m2p	macro	seg_code, ofs1, ofs2

LSEG1	segment
	db	LCODE_SETFJM
	dw	patch_version
	db	seg_code
	dw	dgroup:ofs1
	dw	dgroup:ofs2
LSEG1	ends

	endm

;======================================================================
;.fs
; fc_p2m - macro to generate a far call within this driver
;
; generate code for a far call from this patch driver to mos
;
; in:	seg_code = MOS, MO2 or INIT
;	ofs1 = the offset within mos to be called
;
; out:	
;
;.fe
;=====================================================================^
fc_p2m	macro	seg_code, ofs1
local	x1
	db	FAR_CALL_OPCODE
	dw	ofs1
x1	dw	?

LSEG1	segment
	db	LCODE_SETSEG
	dw	patch_version
	db	seg_code
	dw	dgroup:x1
LSEG1	ends

	endm

;======================================================================
;.fs
; fc_m2p - macro to generate a far call within mos
;
; generate code for a far call from mos to this patch driver
;
; in:	seg_code = MOS, MO2 or INIT
;	ofs1 = the offset within mos to write the far call
;	ofs2 = the offset within this driver to call
;
; out:	
;
;.fe
;=====================================================================^
fc_m2p	macro	seg_code, ofs1, ofs2

LSEG1	segment
	db	LCODE_SETFCM
	dw	patch_version
	db	seg_code
	dw	dgroup:ofs1
	dw	dgroup:ofs2
LSEG1	ends

	endm

;======================================================================
;.fs
; fcs_m - macro to generate a far/near calling shell within mos
;
; in:	seg_code = MOS, MO2 or INIT
;	ofs1 = the offset within mos to write the calling shell
;	ofs2 = the offset within mos for the near call
;
; out:	
;
;.fe
;=====================================================================^
fcs_m	macro	seg_code, ofs1, ofs2

LSEG1	segment
	db	LCODE_CSHELL
	dw	patch_version
	db	seg_code
	dw	dgroup:ofs1
	dw	dgroup:ofs2
LSEG1	ends

	endm


pl_help1 macro p1, p2
	dw	dgroup:plist_&p1&_&p2
	endm

pl_help2 macro p1, p2
plist_&p1&_&p2 label byte
	endm

plist_start macro seg_code

LSEG1	segment
	db	LCODE_PLIST
	dw	patch_version
	db	seg_code
	pl_help1 %patch_version, %pl_seq
LSEG1	ends

INITSEG	segment
pl_help2 %patch_version, %pl_seq

	endm

plist_end macro
pl_seq = pl_seq + 1
INITSEG	ends
	endm

;------------ helper macros for the sectioning template

patch_ver macro p1
patch_version = p1
pl_seq = 0

LSEG2	segment
	dw	patch_version
LSEG2	ends

LSEG3	segment
	db	1
LSEG3	ends
	endm

;------------

gen_ilbl macro p1
	dw	dgroup:install_&p1
	endm

;------------

ifc1	macro	p1
install_&p1 proc near
	endm

;------------

ifunc_start macro

LSEG1	segment
	db	LCODE_INITCALL
	dw	patch_version
	gen_ilbl %patch_version
LSEG1	ends

INITSEG	segment
	assume	ds:dgroup,es:nothing,ss:nothing
	ifc1	%patch_version
	endm

;------------

ifc2	macro	p1
install_&p1 endp
	endm

;------------

ifunc_end macro
	ret
	ifc2	%patch_version
INITSEG	ends
	endm

