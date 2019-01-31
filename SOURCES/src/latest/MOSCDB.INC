CDB	SEGMENT AT 2345H

;-------------------------- CDB PREFIX ------------------------------;

	 DB    ?	; RESERVED 
CDBTYPE  DB    ?	; 'C' TO INDICATE CDB
	 DB    6 DUP(?) ; RESERVED
CDBNEXT  DW    ?	; ADDRESS OF NEXT CDB FOR THIS TCB
CDBPREV  DW    ?	; ADDRESS OF PREVIOUS CDB FOR THIS TCB
CDBTCB	 DW    ?	; ADDRESS OF OWNER TCB
	 DB    2 DUP(?) ; RESERVED 

;------------------------ END OF PREFIX -----------------------------;

CDBDRIVE DB    ?	      ; DRIVE (0=A, 1=B,...)
CDBLVL	 DB    ?	      ; UNUSED
CDBPATH  DB    64 DUP(?)      ; DIRECTORY NAME
CDBCLUS  DW    ?	      ; FIRST CLUSTER OF DIRECTORY (0 IF ROOT)

CDBLEN	 EQU   $-CDB
CDB	 ENDS
