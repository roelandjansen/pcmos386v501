
;	Device driver request packet.

devreqh	struc

rqhsize	db	?		; length of entire request
rqhunit	db	?		; unit number for request
rqhcmd	db	?		; command for request
rqhstat	dw	?		; status from call
rqhres	db	8 dup (?)	; DOS reserved

;	common fields for I/O

rqhspar db	?		; filler
rqhbuff	dd	?		; seg:off to user buffer
rqhlen	dw	?		; length of buffer 

devreqh	ends


devinit	struc

dizsize	db	?		; length of entire request
dizunit	db	?		; unit number for request
dizcmd	db	?		; command for request
dizstat	dw	?		; status from call
dizres	db	8 dup (?)	; DOS reserved

;	extra fields for init

dizunits db	?		; initialized units
diztail	dd	?		; end of driver code
dizline dd	?		; pointer to command line 
dizdnum	db	?		; starting device number

devinit	ends

;	Status contains the following fields

RQSDONE	equ	0100h	; set when operation completed
RQSBUSY	equ	0200h	; set only by status calls and media check
RQSERR	equ	8000h	; if set error code in bits 0-7

RQSPROT	 equ	0	; write protected
RQSUNIT	 equ	1	; unknown unit
RQSRDY	 equ	2	; not ready
RQSCMD	 equ	3	; unknown command
RQSCRC	 equ	4	; CRC error
RQSLEN	 equ	5	; bad request structure length
RQSSEEK	 equ	6	; seek error
RQSMEDIA equ	7	; unknown media
RQSSECT	 equ	8	; sector not found
RQSPAPER equ	9	; out of paper
RQSWRITE equ	10	; write fault
RQSREAD	 equ	11	; read fault
RQSGEN	 equ	12	; general failure
RQSCHANG equ	13	; invalid disk change

