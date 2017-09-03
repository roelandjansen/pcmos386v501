;******************************************************************************
;*				   MBR Definition			      *
;*									      *
;* 	MBRPTAB - this is the offset into the MBR of the partition table      *
;* Since each of the four possible entries into the partition table is 16     *
;* bytes. The offsets will define the entry.				      *
;*	MBRBI	- offset of boot indicator byte				      *
;*	MBRBH	-   "    "  logical disk beginning head number		      *
;*	MBRBS	-   "    "     "     "       "     sector number	      *
;*	MBRBC	-   "    "     "     "       "     cylinder number	      *
;*	MBRSI	-   "    "  system indicator byte			      *
;*	MBREH	-   "    "  logical disk ending head number		      *
;*	MBRES	-   "    "     "     "     "    sector number		      *
;*	MBREC	-   "    "     "     "     "    cylinder number		      *
;*	MBRRSL	-   "    "     "     "   beginning relative sector - low word *
;*	MBRRSH	-   "    "     "     "       "        "       "    - hi  word *
;*	MBRRSCL	-   "    "     "     "   sector count - low word	      *
;*	MBRRSCH	-   "    "     "     "     "      "   - high word	      *
;*	MBRPLEN	- length of each entry					      *
;*									      *
;******************************************************************************

MBRPTAB	equ	01beh		; offset into MBR of the partition table

MBRBI	equ	0
MBRBH	equ	1
MBRBS	equ	2
MBRBC	equ	3
MBRSI	equ	4
MBREH	equ	5
MBRES	equ	6
MBREC	equ	7
MBRRSL	equ	8
MBRRSH	equ	10
MBRRSCL	equ	12
MBRRSCH	equ	14

MBRPLEN	equ	16
MBRSIG	equ	01feh		; offset into mbr of signature
