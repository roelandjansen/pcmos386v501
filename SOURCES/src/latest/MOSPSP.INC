;-----------------------------------------------------------------------;
; PSP definition							;
;-----------------------------------------------------------------------;
PSPseg	segment at 2222H

PSPterm dw	?		;0H   MOS terminate, INT 20H
PSPmem	dw	?		;2H   Segment address for end of allocation
res1	db	?		;4H   RESERVED
PSPcall db	?		;5H   Long CALL to MOS
	dd	?		;	 (address of call)
PSPtrmv dd	?		;AH   Terminate vector (INT 22H)
PSPctrv dd	?		;EH   Ctrl-Break vector (INT 23H)
PSPcrtv dd	?		;12H  Critical Error vector (INT 24H)
PSPprnt dw	?		;16H  PSP segment of parent (Novell uses this)
PSPhtbl db	20 dup(?)	;18H  PSP handle table
PSPenv	dw	?		;2CH  Segment address of environment
PSPsp   dw      ?               ;2EH  SP of EXEC's Caller (see mosfun00)
PSPss   dw      ?               ;30H  SS of EXEC's Caller (EXEC & Terminate)
PSPhdls dw	?		;32H  # of handles
PSPpntr dd	?		;34H  Pointer to PSP handle table (PSPhtbl)
res4	db	24 dup(?)	;38H  RESERVED (38/39 used - EXE part of EXEC)
PSPfarc	db	3  dup(?)	;50H  Far call to function dispatcher
	db	9  dup(?)	;53H  RESERVED
PSPfcb1 db	16 dup(?)	;5CH  Default FCB #1
PSPfcb2 db	20 dup(?)	;6CH  Default FCB #2
PSPcnt	db	?		;80H  Command line length
PSPcmd	db	127 dup(?)	;81H  Command line passed to application

PSPseg	ends
