	include page.inc
        TITLE   MOXEMS - Virtual Expanded Memory Specification Driver
;
;******************************************************************************
;*                                                                            *
;*                        MOS Development Specification                       *
;*                                                                            *
;* Command type: Device Driver          Assigned to:      Stewart Hyde        *
;* Command name: MOXEMS.SYS             Date assigned:    Feb 02, 1987        *
;*                                      Date completed:                       *
;* Command format: DEVICE=MOXEMS.SYS [SIZE]                                   *
;* Purpose: Provide EMS support for PC-MOS/386                                *
;* Refer to:                                                                  *
;* Last Update:                         By:                                   *
;*                                                                            *
;*      External                Values                  Values                *
;*      routines                passed                  returned              *
;* -------------------------------------------------------------------------- *
;* (add as many lines as you need here and above to complete the form.)       *
;* -------------------------------------------------------------------------- *
;* MOS commands will use the same segment grouping as the MOS kernel. This    *
;* file is a template as is MOSSHELL.ASM. Except that its designed for use in *
;* commands, both internal and external, for MOS. See MOSSHELL.ASM for de-    *
;* tails. The commands should not need to go into as much detail as the kernel*
;* does in keeping track of end of segment pointers in the INC files and such.*
;* Our desire is to maintain the same coding standards thruout MOS and to use *
;* code modularity as much as possible. So, use the same group labels in any  *
;* routine to keep the code and data segments in the same segment.            *
;*                                                                            *
;******************************************************************************
;

;------------------------------------------------------------------------;
;  	SAH	08/08/87	Minor changes plus changes so non-memory ;
;				management case will not crash context   ;
;				switching				 ;
;------------------------------------------------------------------------;
;	SAH	04/10/89	Corrections for copyright		 ;
;------------------------------------------------------------------------;

         page
	 if	0 eq 0
         comment  |

                  AUTHOR:  Stewart A. Hyde
                  Updated: 02/16/87

                  Modified for PC-MOS/386 Operating System
                  This program emulates the hardware and provides the LIM/EMS
                  Interupt 67H for EMS support on computers that do not have
                  EMS boards on them.  This version supports version 3.2 of
                  the LIM/EMS only.  Direct I/O (in and out) to page registers
                  not available with this device.


                  FUNCTION       AH       DESCRIPTION
                      1          40       GET STATUS                  06/06/86
                      2          41       GET PAGE FRAME ADDRESS      06/06/86
                      3          42       GET UNALLOCATED PAGE COUNT  06/05/86
                      4          43       ALLOCATE PAGES              06/06/86
                      5          44       MAP HANDLE PAGES            06/09/86
                      6          45       DEALLOCATE PAGES            06/06/86
                      7          46       GET EMM VERSION             06/04/86
                      8          47       SAVE PAGE MAP               06/09/86
                      9          48       RESTORE PAGE MAP            06/09/86
                      10         49       RESERVED                    06/09/86
                      11         4A       RESERVED                    06/09/86
                      12         4B       GET EMM HANDLE COUNT        06/04/86
                      13         4C       GET EMM HANDLE PAGES        06/05/86
                      14         4D       GET ALL EMM HANDLE PAGES    06/05/86
                      15         4E       GET/SET PAGE MAP            06/09/86
                  |
         endif

         PAGE

         if1
		%out	Pass 1	Started.
         else
                %out    Pass 2  Started.
         endif  


;	 include _ems.pub

	 if    0 eq 0		; fake out public.com
TRUE           EQU   1
FALSE          EQU   0

DEBUG          EQU   FALSE

MAX_HANDLE     EQU   255
MAX_PAGE       EQU   512
EMS_VERSION    EQU   32H
MAP_SIZE       EQU   4

SOFT_ERROR     EQU   80H
NO_HARD        EQU   81H
BAD_HANDLE     EQU   83H
ALL_USED       EQU   85H
NOT_ENOUGH     EQU   87H
NOT_ZERO       EQU   89H
LOGIC_RANGE    EQU   8AH
PHYS_RANGE     EQU   8BH
INVALID_PARM   EQU   8FH


BMAP     STRUC
INUSE    DB    FALSE                ; INDICATES IF INUSE
ASSIGN   DB    0                    ; INDICATES WHICH HANDLE OWNS IT
LINKPTR  DW    0                    ; NEXT LINK POINTER
BMAP     ENDS

BMAP_LEN EQU   4

HAND     STRUC
ALLOC    DB    FALSE                ; INDICATES IF HANDLE IS ALLOCATED
PAGES    DW    0                    ; NO PAGES ALLOCATE (1-512) IF ALLOCATED
LINK     DW    0                    ; PAGE LINK POINTER
HAND     ENDS

HAND_LEN EQU   5

	endif

MAINSEG  SEGMENT PARA
         ASSUME CS:MAINSEG,DS:MAINSEG
BEGIN    LABEL NEAR

         PAGE
;------------------------- DEVICE HEADER ----------------------------;

DEVHEADR LABEL BYTE
         DD    -1                    ; POINTER TO NEXT DRIVER
         DW    8000H                 ; ATTRIBUTE: INDICATE CHARACTER DEVICE
         DW    STRATEGY              ; PTR TO STRATEGY ROUTINE
         DW    INTERUPT              ; PTR TO INTERRUPT ROUTINE
         DB    'EMMXXXX0'            ; DEVICE NAME

         EVEN
ADDRESS  DB    0E0H                  ; SEGMENT ADDRESS
; PORTTAB  DB    16 DUP (0)            ; PORT TABLE

COMMENT  |

;;PORTADDR DW    0238H                 ; PORT ADDRESS
         DW    0239H
         DW    023AH
         DW    023BH
         DW    023CH
         DW    023DH
         DW    023EH
         DW    023FH
         DW    0240H
         DW    0241H
         DW    0242H
         DW    0243H
         DW    0244H
         DW    0245H
         DW    0246H
         DW    0247H

         |

BASEADDR DW    0                     ; START OF EXTENDED MEMORY ALLOCATION
MROUTINE DW    2 DUP (?)             ; MEMORY MANAGEMENT ADDRESS
OLDINT67 DD    0                     ; SAVES OLD VECTOR
ZERO     DW    0
BOARDS   DB    0                     ; BOARDS ON SYSTEM
HANDLES  DW    0                     ; EMM HANDLE COUNT
PGSAVAIL DW    0                     ; INDICATES TOTAL PAGES AVAILABLE ON BOARD
PGSLEFT  DW    0                     ; INDICATES PAGES UNALLOCATED
SYSERROR DB    0                     ; BYTE INDICATES LATEST SYSERROR
SYSAVAIL DB    0                     ; INDICATES IF SYSTEM IS AVAILABLE
CUR_HAND DB    0                     ; CURRENT HANDLE USING DATABASE
PHY_PAGE DB    0                     ; PHYSICAL PAGE STORAGE
EMS_PAGE DW    0                     ; EMS PAGE STORAGE

WINDMAP  DW    4  DUP (MAX_PAGE)     ; MAP OF PAGES IN WINDOW

PGMAP    DW    1024 DUP (MAX_PAGE)   ; PAGE MAP STORAGE AREA
HDMAP    DB    256 DUP (0)           ; HANDLE IN MAP

DATABASE HAND  256 DUP (<>)          ; STORAGE FOR HANDLE IMFORMATION

BITMAP   BMAP  512 DUP (<>)          ; STORAGE FOR PAGE BITMAP

FUNTAB   LABEL WORD
         DW    INIT
         DW    MEDIACHK
         DW    BUILDBPB
         DW    IOCTLIN
         DW    INPUT
         DW    NDINPUT
         DW    INSTATUS
         DW    INFLUSH
         DW    OUTPUT
         DW    OUTPUTV
         DW    OUSTATUS
         DW    OUFLUSH
         DW    IOCTLOUT

RHOFF    DW    0                     ; REQUEST HEADER POINTER
RHSEG    DW    0
         PAGE
STRATEGY LABEL NEAR
         MOV   CS:[RHSEG],ES
         MOV   CS:[RHOFF],BX
FARRET1  PROC  FAR
         RET
FARRET1  ENDP  

INTERUPT LABEL NEAR
         PUSH  ES
         PUSH  DS
	 PUSH  BP
         PUSH  DI
         PUSH  SI
         PUSH  DX
         PUSH  CX
         PUSH  BX
         PUSH  AX

         PUSH  CS                    ; INIT DS REGISTER
         POP   DS
         LES   BX,DWORD PTR [RHOFF]  ; LOAD RH POINTER
         MOV   AL,ES:[BX+2]          ; GET COMMAND CODE BYTE
         MOV   AH,0
         SHL   AX,1
         MOV   DI,AX
         JMP   [DI+FUNTAB]
  
DONESTAT LABEL NEAR
         LES   BX,DWORD PTR [RHOFF]
         OR    WORD PTR ES:[BX+03],0100H   ; "DONE" STATUS

EXIT     LABEL NEAR
         CLC
         POP   AX
         POP   BX
         POP   CX
         POP   DX
         POP   SI
         POP   DI
	 POP   BP
         POP   DS
         POP   ES
FARRET2  PROC  FAR
         RET
FARRET2  ENDP
         PAGE
INPUT    LABEL NEAR
OUTPUT   LABEL NEAR
OUTPUTV  LABEL NEAR
IOCTLIN  LABEL NEAR
IOCTLOUT LABEL NEAR
         MOV   WORD PTR ES:[BX+18],0     ; NO DATA TRANSFERRED
NDINPUT  LABEL NEAR
INFLUSH  LABEL NEAR
OUFLUSH  LABEL NEAR
MEDIACHK LABEL NEAR
BUILDBPB LABEL NEAR
         OR    WORD PTR ES:[BX+03],8102H ; INDICATE DEVICE NOT READY
         JMP   DONESTAT


INSTATUS LABEL NEAR
OUSTATUS LABEL NEAR
         AND   WORD PTR ES:[BX+03],0000H ; INDICATE DEVICE READY
         JMP   DONESTAT


         PAGE
;--------------------------------------------------------------------;
;                         INT 67H HANDLER                            ;
;--------------------------------------------------------------------;

ENTINT67 LABEL NEAR
         STI

IF       DEBUG
         CMP   AH, 4EH
;        JE    DBCONT
;        INT   2
ENDIF

DBCONT   LABEL NEAR
         PUSH  DS
         PUSH  BX
         CMP   AH,40H
         JB    XFERBIOS
         SUB   AH,40H
         CMP   AH,0FH
         JA    XFERBIOS
         XOR   BH,BH
         MOV   BL,AH
         SHL   BX,1
         JMP   CS:[FUNTABLE+BX]
XFERBIOS: 
         POP   BX
         POP   DS
         JMP   CS:[OLDINT67]

         EVEN
FUNTABLE LABEL WORD
         DW    STATUS                ; 1  - GET STATUS
         DW    PAGEADDR              ; 2  - GET PAGE FRAME ADDRESS
         DW    PCOUNT                ; 3  - GET UNALLOCATED PAGE COUNT
         DW    ALPAGES               ; 4  - ALLOCATE PAGES
         DW    MAPHAND               ; 5  - MAP HANDLE PAGES
         DW    FREE                  ; 6  - DEALLOCATE PAGES
         DW    VERSION               ; 7  - GET EMM VERSION
         DW    SAVEPMAP              ; 8  - SAVE PAGE MAP
         DW    RESTPMAP              ; 9  - RESTORE PAGE MAP
         DW    RSV10                 ; 10 - RESERVED
         DW    RSV11                 ; 11 - RESERVED
         DW    HCOUNT                ; 12 - GET EMM HANDLE COUNT
         DW    HPAGES                ; 13 - GET EMM HANDLE PAGES
         DW    AHPAGES               ; 14 - GET ALL EMM HANDLE PAGES
         DW    GETSET                ; 15 - GET/SET PAGE MAP


         PAGE
;---------------------------------------------------------------------------
; FUNCTION: 1 - GET STATUS
;---------------------------------------------------------------------------

STATUS   LABEL NEAR
         MOV   AH, CS:[SYSAVAIL]     ; GET SYSTEM AVAIL TEST
         OR    AH, AH                ; AVAILABLE?????
         JNE   OK1                   ; YES...SKIP
         MOV   AH, NO_HARD           ; NO HARDWARE
         MOV   CS:[SYSERROR], AH     ; SAVE ERROR...

OK1:
         MOV   AH, CS:[SYSERROR]     ; GET LATEST ERROR CODE
         POP   BX                    ; GET BX
         POP   DS
         IRET


;---------------------------------------------------------------------------
; FUNCTION: 2 - GET PAGE ADDRESS
;---------------------------------------------------------------------------

PAGEADDR LABEL NEAR
         POP   BX                    ; GET BX
         MOV   BH, CS:[ADDRESS]      ; GET STORED SEGMENT ADDRESS
         XOR   BL, BL                ; ZERO OUT LOWER BYTE
         XOR   AH, AH                ; INDICATE OK....
         MOV   CS:[SYSERROR], AH     ; SAVE SYSTEM ERROR CODE
         POP   DS
         IRET


;---------------------------------------------------------------------------
; FUNCTION: 3 - GET UNALLOCATED PAGES COUNT
;---------------------------------------------------------------------------

PCOUNT   LABEL NEAR
         PUSH  CS
         POP   DS
         XOR   AH, AH                ; INDICATE OK....
         POP   BX                    ; GET BX
         MOV   BX, [PGSLEFT]         ; GET # OF UNALLOCATED PAGES
         MOV   DX, [PGSAVAIL]        ; GET MAX # OF PAGES
         CMP   BX, DX                ; COMPARE THEM....
         JBE   PDONE                 ; SHOULD ALWAYS HAPPEN...
         MOV   AH, SOFT_ERROR        ; INDICATE ERROR IN SOFTWARE

PDONE:
         MOV   [SYSERROR], AH        ; SAVE SYSTEM ERROR CODE
         POP   DS
         IRET

;---------------------------------------------------------------------------
; FUNCTION: 4 - ALLOCATED PAGES
;---------------------------------------------------------------------------

ALPAGES  LABEL NEAR
         PUSH  CS
         POP   DS
         MOV   AH, NOT_ENOUGH        ; INDICATE NOT ENOUGHT PAGES IN MEMORY
         POP   BX                    ; GET BX
         PUSH  BX                    ; PUSH IT BACK
         CMP   BX, [PGSLEFT]         ; CMP TO # OF UNALLOCATED PAGES
         JBE   ALP1                  ; CONTINUE
         JMP   ALPDONE2              ; NOT ENOUGH PAGES

ALP1:
         MOV   AH, ALL_USED          ; INDICATE ALL HANDLES USED UP...
         CMP   [HANDLES], MAX_HANDLE      ; COMPARE HANDLES COUNT  TO MAX
         JNE   ALP2                  ; CONTINUE
         JMP   ALPDONE2              ; ALL EMM HANDLES USE

ALP2:
         MOV   AH, NOT_ZERO          ; CAN'T ALLOCATED ZERO PAGES
         OR    BX, BX                ; ZERO PAGES????
         JNE   ALP3                  ; CONTINUE
         JMP   ALPDONE2              ; YES...ABORT....

ALP3:
         PUSH  BP
         PUSH  SI                    ; SAVE SI
         PUSH  CX                    ; SAVE CX

         ; UPDATE COUNTERS

         SUB   [PGSLEFT], BX         ; UPDATE PAGE COUNTER

         ; FIND UNUSED HANDLE AND UPDATE IT

         XOR   SI, SI                ; ZERO OUT SOURCE POINTER
         XOR   DX, DX                ; ZERO OUT DX
         MOV   AH, SOFT_ERROR        ; SHOULD NEVER HAPPEN
ALPHAND:
         CMP   BYTE PTR DATABASE[SI].ALLOC, FALSE ; LOOK FOR UNUSED HANDLE
         JE    ALPFIN                ; FIN DOING HANDLES
         INC   DX                    ; INCREMENT DX
         ADD   SI, HAND_LEN          ; ADD LENGHT OF HANDLE RECORD
         CMP   DX, MAX_HANDLE        ; OVER THE HILL BUD!!!
         JBE   ALPHAND               ; NO...REPEAT
         POP   CX
         JMP   ALPDONE               ; GET OUT OF HERE
ALPFIN:
         MOV   BP, DX                ; SAVE HANDLE
         MOV   CX, BX                ; PLACE BX IN CX
         INC   [HANDLES]             ; UP COUNTER
         MOV   BYTE PTR DATABASE[SI].ALLOC, TRUE  ; UNUSED HANDLE FOUND
         MOV   WORD PTR DATABASE[SI].PAGES, CX    ; SAVE PAGES
         MOV   BX, SI                ; SAVE HANDLE POINTER
         XOR   SI, SI                ; ZERO OUT SOURCE POINTER
         MOV   DX, MAX_PAGE          ; INDICATES TOP OF LIST
         CALL  GETPAGE               ; GET PAGE
         CMP   DX, MAX_PAGE          ; THIS INDICATES SYSTEM ERROR
         JB    ALP4                  ; CONTINUE
         MOV   AH, SOFT_ERROR        ; IDICATE SOFTWARE ERROR
         POP   CX                    ; GET CX
         JMP   ALPDONE               ; ABORT......

ALP4:
         MOV   WORD PTR DATABASE[BX].LINK, DX     ; PLACE LINK INTO DATABASE
         MOV   BX, SI                ; SAVE POINTER
         DEC   CX                    ; DECREMENT CX
         OR    CX, CX                ; DONE
         JZ    SKIPLOOP              ; ONLY ONE PAGE WANTED
         ADD   SI, BMAP_LEN          ; POINT TO NEXT ITEM

ALPLOOP:

         ; ALLOCATE AND STORE PAGES IN LINK LIST HERE - BX POINTS TO START
         ;   SI POINTS TO THE NEXT AVAIABLE PAGE

         CALL  GETPAGE               ; GET PAGE
         CMP   DX, MAX_PAGE          ; THIS INDICATES SYSTEM ERROR
         JB    ALP5                  ; CONTINUE
         MOV   AH, SOFT_ERROR        ; IDICATE SOFTWARE ERROR
         POP   CX                    ; GET CX
         JMP   ALPDONE               ; ABORT......

ALP5:
;        OR    CX, CX                ; LAST ONE???
;        JNE   ALP6                  ; NO..SKIP
;        XOR   DX, DX                ; INDICATE END OF LIST

ALP6:
         MOV   WORD PTR BITMAP[BX].LINKPTR, DX  ; SETUP LINK...
         MOV   BX, SI                ; SAVE POINTER
         ADD   SI, BMAP_LEN          ; POINT TO NEXT ITEM
         LOOP  ALPLOOP               ; LOOP UNTIL DONE
;        POP   CX                    ; GET CX
;        JMP   ALPDONE1              ; SKIP THE FOLLOWING

SKIPLOOP:
         MOV   WORD PTR BITMAP[BX].LINKPTR, 0  ; SETUP LINK...
         POP   CX                    ; GET CX

ALPDONE1:
         MOV   DX, BP                ; GET HANDLE
         XOR   AH, AH                ; INDICATE OK

ALPDONE:
         POP   SI
         POP   BP

ALPDONE2:
         MOV   [SYSERROR], AH        ; SAVE SYSTEM ERROR CODE
         POP   BX
         POP   DS
         IRET

;---------------------------------------------------------------------------
; FUNCTION: 5 - MAP HANDLE PAGES
;---------------------------------------------------------------------------

MAPHAND  LABEL NEAR
         PUSH  CS
         POP   DS
         POP   BX                    ; GET OLD BX
         PUSH  SI                    ; SAVE SI
         PUSH  DX
         PUSH  AX
         PUSH  BX
	 XOR   DH, DH		     ; BETTER-BASIC FIX 4-9-87
         MOV   [PHY_PAGE], AL        ; SAVE PHYSICAL PAGE
         MOV   [EMS_PAGE], BX        ; SAVE EMS PAGE
         MOV   AH, PHYS_RANGE        ; INDICATE PHYSICAL RANGE ERROR
         CMP   AL, 3                 ; OUT OF RANGE
         JA    MHDONE                ; YES....ABORT...
         MOV   AH, SOFT_ERROR        ; INDICATE ERROR IN SOFTWARE
         CMP   DX, MAX_HANDLE        ; COMPARE TO MAX # OF HANDLES
         JA    MHDONE                ; BAD HANDLE #
         MOV   BX, DX                ; PUT DX IN BX
         MOV   SI, DX                ; IN SI TOO!!!
         SHL   SI, 1                 ; MULT SI BY 2
         SHL   SI, 1                 ; MULT SI BY 2
         ADD   SI, BX                ; NOW IT IS MULT BY 5
         MOV   AH, BAD_HANDLE        ; INDICATED BAD HANDLE
         CMP   BYTE PTR DATABASE[SI].ALLOC, TRUE   ; ALLOCATED BLOCK???
         JNE   MHDONE                ; NO...ERROR
         MOV   AH, LOGIC_RANGE       ; INDICATE ERROR IN SOFTWARE
         MOV   BX, [EMS_PAGE]          ; GET EMS PAGE (BX)
         CMP   BX, WORD PTR DATABASE[SI].PAGES  ; COMPARE TO LOG RANGE
         JAE   MHDONE                ; OUT OF RANGE
         MOV   DX, WORD PTR DATABASE[SI].LINK   ; GET LINK
         MOV   AH, SOFT_ERROR        ; INDICATE ERROR IN SOFTWARE
         MOV   BX, [EMS_PAGE]        ; GET EMS PAGE (BX)
         INC   BX
         PUSH  DX

MAPLOOP:
         OR    BX, BX                ; DONE????
         JE    MAPDONE               ; YES..OK
         DEC   BX                    ; DECREMENT COUNTER
         POP   SI                    ; GET OLD COPY (REMOVE FROM STACK)
         MOV   SI, DX                ; GET PAGE #
         SHL   SI, 1                 ;
         SHL   SI, 1                 ; ONLY IF BMAP_LEN = 4
         PUSH  DX
         MOV   DX, WORD PTR BITMAP[SI].LINKPTR   ; GET NEXT PAGE LINK
         CMP   DX, [PGSAVAIL]        ; IN PHYSICAL RANGE????
         JAE   MHDONE1               ; NO...ABORT
         JMP   MAPLOOP               ; YES...CONTINUE...

MAPDONE:
         POP   DX
         PUSH  DX
         MOV   AL, [PHY_PAGE]          ; GET PHYSICAL PAGE (AL)
         CALL  GETMEM                  ; GET IT!!!!
         XOR   BX, BX                  ; ZERO OUT BASE REGISTER
         MOV   BL, AL                  ; GET PAGE FRAME
         SHL   BX, 1                   ; TIMES 2
         MOV   WINDMAP[BX], DX         ; SAVE NEW WINDOW MAP
         XOR   AH, AH                  ; NO ERRORS!!!!

MHDONE1:
         POP   DX

MHDONE:
         MOV   [SYSERROR], AH          ; SAVE SYSTEM ERROR CODE
         POP   BX
         POP   AX
         MOV   AH, [SYSERROR]          ; SAVE SYSTEM ERROR CODE
         POP   DX
         POP   SI
         POP   DS
         IRET

;---------------------------------------------------------------------------
; FUNCTION: 6  -  DEALLOCATE PAGES
;---------------------------------------------------------------------------

FREE     LABEL NEAR
	 PUSH  DX
         PUSH  SI                    ; SAVE SI
         PUSH  CS
         POP   DS
	 XOR   DH, DH		     ; BETTER BASIC FIX 4-9-87	
         MOV   AH, SOFT_ERROR        ; INDICATE ERROR IN SOFTWARE
         CMP   DX, MAX_HANDLE        ; COMPARE TO MAX # OF HANDLES
         JA    FDONE                 ; BAD HANDLE #
         MOV   BX, DX                ; PUT DX IN BX
         MOV   SI, DX                ; PLACE IN SI
         SHL   SI, 1                 ; MULT SI BY 2
         SHL   SI, 1                 ; MULT SI BY 2
         ADD   SI, BX                ; NOW IT IS MULT BY 5
         MOV   AH, BAD_HANDLE        ; INDICATED BAD HANDLE
         CMP   BYTE PTR DATABASE[SI].ALLOC, TRUE   ; ALLOCATED BLOCK???
         JNE   FDONE                 ; NO...ERROR
         MOV   AH, SOFT_ERROR        ; INDICATE ERROR IN SOFTWARE
         MOV   BX, [PGSLEFT]         ; GET MAX PAGES
         ADD   BX, WORD PTR DATABASE[SI].PAGES      ; ADD PAGES IN HANDLE
         CMP   BX, [PGSAVAIL]        ; COMPARE TO MAX PAGES AVAILABLE
         JA    FDONE                 ; ERROR IN SOFTWARE {NOT ME}

         ; AT THIS POINT WE CAN DEALLOCATE THE SPACE

         MOV   [PGSLEFT], BX         ; SET NEW PAGES LEFT
         DEC   [HANDLES]
         MOV   BYTE PTR DATABASE[SI].ALLOC, FALSE   ; REMOVE HANDLE
         MOV   WORD PTR DATABASE[SI].PAGES, 0       ; SET PAGES TO ZERO
         MOV   BX, WORD PTR DATABASE[SI].LINK       ; GET START OF LINK LIST
         MOV   WORD PTR DATABASE[SI].LINK, MAX_PAGE    ; ZERO OUT LINK LIST
         CMP   BX, MAX_PAGE          ; THIS WILL INDICATED ERROR
         JE    FDONE                 ; ERROR...

FLOOP:
         MOV   SI, BX                ; PLACE BX IN SI
         SHL   SI, 1                 ;
         SHL   SI, 1                 ; MULTIPLY BY FOR - (ONLY IF BMAP_LEN=4)
         CMP   BYTE PTR BITMAP[SI].INUSE, FALSE   ; TEST TO SEE IF ALLOCATED
         JE    FDONE
         MOV   BYTE PTR BITMAP[SI].INUSE, FALSE   ; DEALLOCATE PAGE
         CMP   DL, BYTE PTR BITMAP[SI].ASSIGN     ; SAME HANDLE
         JNE   FDONE
         MOV   BX, WORD PTR BITMAP[SI].LINKPTR    ; GET LINK POINTER
         MOV   WORD PTR BITMAP[SI].LINKPTR, MAX_PAGE  ; RESET LINK PTR
         CMP   BX, 0                 ; END OF LIST???
         JNE   FLOOP                 ; REPEAT UNTIL DONE

         XOR   AH, AH                ; INDICATE ALL OK AND DANDY...

FDONE:
         MOV   [SYSERROR], AH        ; SAVE SYSTEM ERROR CODE
         POP   SI
	 POP   DX
         POP   BX
         POP   DS
         IRET

;---------------------------------------------------------------------------
; FUNCTION: 7  -  GET EMS VERSION
;---------------------------------------------------------------------------

VERSION  LABEL NEAR
         XOR   AH,AH                 ; INDICATED OK...
         MOV   AL,EMS_VERSION        ; INDICATE VERSION 3.2

FUNEND:
         MOV   CS:[SYSERROR], AH     ; SAVE SYSTEM ERROR CODE
         POP   BX
         POP   DS
         IRET

;---------------------------------------------------------------------------
; FUNCTION: 8  -  SAVE PAGE MAP
;---------------------------------------------------------------------------

SAVEPMAP LABEL NEAR
         PUSH  CX
         PUSH  DX
         PUSH  SI
         PUSH  DI

         PUSH  CS
         POP   DS
	 XOR   DH, DH		     ; BETTER BASIC FIX 4-9-87	
         MOV   AH, BAD_HANDLE        ; INDICATE BAD HANDLE
         CMP   DX, MAX_HANDLE        ; BAD HANDLE???
         JA    SPDONE                ; ABORT....
         MOV   DI, DX                ; GET HANDLE
         SHL   DI, 1                 ;
         SHL   DI, 1                 ; MULTIPLY BY 8 - FOUR WORDS
         SHL   DI, 1                 ;
         XOR   SI, SI                ; ZERO OUT SOURCE
         MOV   AL, 4                 ; DITTO
         MOV   CL, [CUR_HAND]        ; GET CURRENT HANDLE
         MOV   [CUR_HAND], DL        ; MARK GIVEN HANDLE AS CURRENT
         MOV   BX, DX                ; PLACE HANDLE IN BASE REGISTER
         MOV   BYTE PTR HDMAP[BX], CL      ; SAVE OLD HANDLE IN HANDLE MAP
         XOR   AH, AH                ; INDICATE OK....
         XOR   AL, AL

SPLOOP:
         CMP   AL, 4                 ; ALL DONE???
         JE    SPDONE                ; YES
         MOV   DX,  WORD PTR WINDMAP[SI] ; GET PAGE FOR PAGE MAP
         MOV   WORD PTR PGMAP[DI], DX    ; GET PAGE FROM PAGE MAP
         INC   SI                    ;
         INC   SI                    ; BY 2 ....
         INC   DI                    ;
         INC   DI                    ; BY 2 ....
         INC   AL                    ; INCREMENT AL
         JMP   SPLOOP                ; LOOP UNTIL DONE

SPDONE:
         MOV   [SYSERROR], AH        ; SAVE SYSTEM ERROR CODE
         POP   DI
         POP   SI
         POP   DX
         POP   CX
         POP   BX
         POP   DS
         IRET

;---------------------------------------------------------------------------
; FUNCTION: 9  -  RESTORE PAGE MAP
;---------------------------------------------------------------------------

RESTPMAP LABEL NEAR
         PUSH  CX
         PUSH  DX
         PUSH  SI
         PUSH  DI

         PUSH  CS
         POP   DS
	 XOR   DH, DH		     ; BETTER BASIC FIX 4-9-87 (SAH)
         MOV   AH, BAD_HANDLE        ; INDICATE BAD HANDLE
         CMP   DX, MAX_HANDLE        ; BAD HANDLE???
         JA    RPDONE                ; ABORT....
         MOV   SI, DX                ; GET HANDLE
         SHL   SI, 1                 ;
         SHL   SI, 1                 ; MULTIPLY BY 8 - FOUR WORDS
         SHL   SI, 1                 ;
         XOR   DI, DI                ; ZERO OUT DESTINATION
         MOV   AL, 4                 ; DITTO
         MOV   BX, DX                ; PLACE HANDLE IN BASE REGISTER
         MOV   CL, BYTE PTR HDMAP[BX]      ; GET OLD HANDLE IN HANDLE MAP
         MOV   [CUR_HAND], CL        ; MAKE OLD HANDLE CURRENT HANDLE
         XOR   AH, AH                ; INDICATE OK....
         XOR   AL, AL

RPLOOP:
         CMP   AL, 4                 ; ALL DONE???
         JE    RPDONE                ; YES
         MOV   DX, WORD PTR PGMAP[SI]    ; GET PAGE FROM PAGE MAP
         MOV   WORD PTR WINDMAP[DI], DX  ; GET PAGE FOR PAGE MAP
         INC   SI                    ;
         INC   SI                    ; BY 2 ....
         INC   DI                    ;
         INC   DI                    ; BY 2 ....
         CALL  GETMEM                ; GET MEMORY AREA
         INC   AL                    ; INCREMENT AL
         JMP   RPLOOP                ; LOOP UNTIL DONE

RPDONE:
         MOV   [SYSERROR], AH        ; SAVE SYSTEM ERROR CODE
         POP   DI
         POP   SI
         POP   DX
         POP   CX
         POP   BX
         POP   DS
         IRET

;---------------------------------------------------------------------------
; FUNCTION: 10 - RESERVED # 10
;---------------------------------------------------------------------------

RSV10    LABEL NEAR

COMMENT  |

         FOLLOWING CODE WAS FOR DIRECT I/O

         PUSH  SI
         PUSH  DI
         PUSH  DX
         PUSH  CX

         PUSH  CS
         POP   DS
         MOV   CX, MAP_SIZE          ; THERE ARE FOUR PAGES REGISTERS
         LEA   SI, PORTADDR
         REP   MOVSW                 ; MOVE ADDRESS

         |

         XOR   AX, AX                ; INDICATE 0 BOARDS AND OK

R10DONE:
         MOV   [SYSERROR], AH        ; SAVE SYSTEM ERROR CODE
;        POP   CX
;        POP   DX
;        POP   DI
;        POP   SI
         POP   BX
         POP   DS
         IRET

;---------------------------------------------------------------------------
; FUNCTION: 11 - RESERVED # 11
;---------------------------------------------------------------------------

RSV11    LABEL NEAR
         PUSH  CS
         POP   DS
         PUSH  CX
	 PUSH  DX
         PUSH  SI                    ; SAVE SI
         PUSH  DI                    ;
	 XOR   DH, DH		     ; BETTER BASIC FIX 4-9-87 (SAH)	     
         MOV   AH, BAD_HANDLE        ; INDICATED BAD HANDLE
         CMP   DX, MAX_HANDLE        ; COMPARE TO MAX # OF HANDLES
         JA    R11DONE                 ; BAD HANDLE #
         MOV   BX, DX                ; PUT DX IN BX
         SHL   SI, 1                 ; MULT SI BY 2
         SHL   SI, 1                 ; MULT SI BY 2
         ADD   SI, BX                ; NOW IT IS MULT BY 5
         CMP   BYTE PTR DATABASE[SI].ALLOC, TRUE   ; ALLOCATED BLOCK???
         JNE   R11DONE               ; NO...ERROR

         ; AT THIS POINT WE SCAN AND COLLECT PAGES FOR LIM/EMS TRANSLATION

         MOV   AH, SOFT_ERROR                       ;
         MOV   BX, WORD PTR DATABASE[SI].LINK       ; GET START OF LINK LIST
         CMP   BX, MAX_PAGE
         JAE   R11DONE                              ; ERROR...

R11LOOP:
         MOV   SI, BX                ; PLACE BX IN SI
         SHL   SI, 1                 ;
         SHL   SI, 1                 ; MULTIPLY BY FOR - (ONLY IF BMAP_LEN=4)
         CMP   BYTE PTR BITMAP[SI].INUSE, FALSE   ; TEST TO SEE IF ALLOCATED
         JE    R11DONE
         CMP   DL, BYTE PTR BITMAP[SI].ASSIGN     ; SAME HANDLE
         JNE   R11DONE
         MOV   BX, WORD PTR BITMAP[SI].LINKPTR    ; GET LINK POINTER
         CMP   BX, MAX_PAGE          ; END OF LIST???
         JAE   R11OK
         MOV   CX, BX

         ; WE NOW TO THE ACTUAL TRANSLATION

         SHL   CX, 1                 ; SHIFT HIGH BIT OF CL INT CH
         SHR   CL, 1                 ;
         OR    CL, 80H               ; SET ENABLE BIT
         MOV   WORD PTR ES:[DI], CX  ; SAVE BYTE IN TABLE
         INC   DI
         INC   DI
         JMP   R11LOOP               ; REPEAT UNTIL DONE

R11OK:
         XOR   AH, AH                ; INDICATE ALL OK AND DANDY...

R11DONE:
         MOV   [SYSERROR], AH        ; SAVE SYSTEM ERROR CODE
         POP   DI
         POP   SI
	 POP   DX
         POP   CX
         POP   BX
         POP   DS
         IRET

;---------------------------------------------------------------------------
; FUNCTION: 12 - GET EMM HANDLE COUNT
;---------------------------------------------------------------------------

HCOUNT   LABEL NEAR
         MOV   AH, SOFT_ERROR        ; INDICATE ERROR IN SOFTWARE
         POP   BX                    ; GET BX
         MOV   BX, CS:[HANDLES]      ; GET HANDLE COUNT
         CMP   BX, MAX_HANDLE        ; COMPARE TO MAX # OF HANDLES
         JA    HDONE                 ; SHOULD NOT HAPPEN...
         XOR   AH, AH                ; INDICATE OK....

HDONE:
         MOV   CS:[SYSERROR], AH     ; SAVE SYSTEM ERROR CODE
         POP   DS
         IRET

;---------------------------------------------------------------------------
; FUNCTION: 13 - GET EMM HANDLE PAGES
;---------------------------------------------------------------------------

HPAGES   LABEL NEAR
         PUSH  CS
         POP   DS
         POP   BX                    ; GET BX
         PUSH  DX                    ; SAVE DX
         PUSH  SI                    ; SAVE SI
	 XOR   DH, DH		     ; BETTER BASIC FIX 4-9-87 (SAH)	
         MOV   AH, SOFT_ERROR        ; INDICATE ERROR IN SOFTWARE
         CMP   DX, MAX_HANDLE        ; COMPARE TO MAX # OF HANDLES
         JA    HPDONE                ; BAD HANDLE #
         MOV   BX, DX                ; PUT DX IN BX
         MOV   SI, DX                ; PUT DX IN DX
         SHL   SI, 1                 ; MULT SI BY 2
         SHL   SI, 1                 ; MULT SI BY 2
         ADD   SI, BX                ; NOW IT IS MULT BY 5
         MOV   BL, BYTE PTR DATABASE[SI].ALLOC   ; GET ALLOCATED BLOCK
         MOV   AH, BAD_HANDLE        ; INDICATED BAD HANDLE
         CMP   BL, TRUE              ; ALLOCATED???
         JNE   HPDONE                ; NO...ERROR
         MOV   AH, SOFT_ERROR        ; INDICATE ERROR IN SOFTWARE
         MOV   BX, WORD PTR DATABASE[SI].PAGES   ; GET NUMBER OF ALLOCATED PAGES
         CMP   BX, [PGSAVAIL]        ; CAN'T BE MORE THAN AVAILABLE
         JA    HPDONE                ; IF SO REPORT ERROR....
         XOR   AH, AH                ; INDICATE OK....

HPDONE:
         MOV   [SYSERROR], AH        ; SAVE SYSTEM ERROR CODE
         POP   SI
         POP   DX
         POP   DS
         IRET

;---------------------------------------------------------------------------
; FUNCTION: 14 - GET ALL EMM HANDLE PAGES
;---------------------------------------------------------------------------

AHPAGES  LABEL NEAR
         PUSH  CS
         POP   DS
         POP   BX
         PUSH  CX
         PUSH  SI                    ; SAVE SI
         PUSH  DI                    ; SAVE DI
         XOR   SI, SI                ; CLEAR SI
         XOR   CX, CX                ; CLEAR COUNTER

AHLOOP:
         MOV   BL, BYTE PTR DATABASE[SI].ALLOC   ; GET ALLOCATED BLOCK
         CMP   BL, TRUE              ; ALLOCATED????
         JNE   AHSKIP                ; NO..SKIP
         MOV   WORD PTR ES:[DI], CX  ; SEND HANDLE #
         MOV   BX, WORD PTR DATABASE[SI].PAGES   ; GET NUMBER OF ALLOCATED PAGES
         INC   DI                    ; INCREMENT DI
         INC   DI                    ; INCREMENT DI
         MOV   WORD PTR ES:[DI], BX  ; SEND PAGE COUNT
         INC   DI                    ; INCREMENT DI
         INC   DI                    ; INCREMENT DI
         INC   CX                    ; INCREMENT COUNTER
AHSKIP:
         ADD   SI, HAND_LEN          ; ADD LENGHT OF HAND RECORD
         CMP   SI, MAX_HANDLE * HAND_LEN    ; COMPARE TO MAX
         JBE   AHLOOP                ; LOOP UNTIL DONE
         XOR   AH, AH                ; INDICATE OK....
         MOV   [SYSERROR], AH        ; SAVE SYSTEM ERROR CODE
         MOV   BX, CX                ; GET COUNTER
         POP   DI
         POP   SI
         POP   CX
         POP   DS
         IRET


;---------------------------------------------------------------------------
; FUNCTION: 15 - GET / SET PAGE MAP
;---------------------------------------------------------------------------

GETSET   LABEL NEAR
         MOV   AH, INVALID_PARM      ; INVALID PARAMETER???
         CMP   AL, 3                 ; SUB-FUNCTION 0 -- 3????
         JA    GSDONE                ; ABORT.....
         XOR   AH, AH                ; INDICATE OK....
         OR    AL, AL                ; SUBFUNCTION 0....
         JNE   GS1                   ; NO...SKIP
         CALL  GETARRAY              ; GET PAGE ARRAY
         JMP   GSDONE                ; EXIT OK

GS1:
         CMP   AL, 1                 ; SUBFUNCTION 1....
         JNE   GS2                   ; NO...SKIP
         CALL  SAVARRAY              ; SAVE PAGE ARRAY
         CALL  SETPORT               ; SETUP GIZMO ALLOCATION
         JMP   GSDONE                ; EXIT OK...

GS2:
         CMP   AL, 2                 ; SUBFUNCTION 2....
         JNE   GS3                   ; NO...SKIP
         CALL  GETARRAY              ; GET PAGE ARRAY
         CALL  SAVARRAY              ; SAVE PAGE ARRAY
         CALL  SETPORT               ; SETUP GIZMO ALLOCATION
         JMP   GSDONE                ; EXIT OK...

GS3:
         MOV   AL, MAP_SIZE*2        ; RETURN MAP SIZE

GSDONE:
         MOV   CS:[SYSERROR], AH     ; SAVE SYSTEM ERROR CODE
         POP   BX
         POP   DS
         IRET


         PAGE
;---------------------------------------------------------------------
;  GETPAGE - GET THE NEXT PAGE AVAILABLE FOR SYSTEM
;        DS MUST POINT CODE SEGMENT
;---------------------------------------------------------------------

GETPAGE  PROC  NEAR

GPLOOP:
         CMP   BYTE PTR BITMAP[SI].INUSE, FALSE  ; UNALLOCATED
         JE    GPFOUND                ; OK..WE GOT IT
         ADD   SI, BMAP_LEN           ; UPDATE POINTER
         CMP   SI, BMAP_LEN * MAX_PAGE    ; AT END OF LIST?? NEVER...
         JB    GPLOOP                 ; NO....REPEAT
         MOV   DX, MAX_PAGE           ; INDICATES ABORT
         RET

GPFOUND:
         MOV   BYTE PTR BITMAP[SI].INUSE, TRUE  ; ALLOCATED IT
         MOV   WORD PTR BITMAP[SI].ASSIGN, BP   ; SET HANDLE ASSIGMENT
         MOV   DX, SI                 ; GET LOOP POSITION
         SHR   DX, 1                  ;
         SHR   DX, 1                  ; DIVIDE BY FOUR (ONLY FOR BMAP_LEN=4)
         RET

GETPAGE  ENDP

;---------------------------------------------------------------------
; SETPORT -  SET GIZDRIVE MEMORY ALLOCATION FOR A PORT
;---------------------------------------------------------------------

SETPORT  PROC  NEAR
         PUSH  AX
         PUSH  CX
         PUSH  DX
         PUSH  SI
         PUSH  DI
         XOR   SI, SI
         MOV   CX, 4
         XOR   AL, AL

SETLOOP:
         MOV   DX, WORD PTR CS:WINDMAP[SI]  ; GET PAGE FOR PAGE MAP
         INC   SI                    ;
         INC   SI                    ; BY 2 ....
         CALL  GETMEM                ; GET MEMORY AREA
         INC   AL
         LOOP  SETLOOP               ; LOOP UNTIL DONE

         POP   DI
         POP   SI
         POP   DX
         POP   CX
         POP   AX
         RET
SETPORT  ENDP


;---------------------------------------------------------------------
; GETARRAY - GET CURRENT PAGE ARRAY
;            ARRAY WILL BE STORED AT ES:DI
;---------------------------------------------------------------------

GETARRAY PROC  NEAR
         PUSH  DI
         PUSH  SI
         PUSH  CX
         PUSH  DS
         PUSH  CS
         POP   DS

         MOV   CX, MAP_SIZE  ; THERE ARE FOUR PAGES REGISTERS
         LEA   SI, WINDMAP

         CLD
         REP   MOVSW         ; MOVE BYTES

         POP   DS
         POP   CX
         POP   SI
         POP   DI
         RET
GETARRAY ENDP

;---------------------------------------------------------------------
; SAVARRAY - SAVE CURRENT PAGE ARRAY
;            ARRAY COME FROM DS:SI
;---------------------------------------------------------------------

SAVARRAY PROC  NEAR
         PUSH  DI
         PUSH  SI
         PUSH  CX
         PUSH  ES
         PUSH  CS
         POP   ES


         MOV   CX, MAP_SIZE  ; THERE ARE FOUR PAGES REGISTERS
         LEA   DI, WINDMAP

         CLD
         REP   MOVSW         ; MOVE BYTES

         POP   ES
         POP   CX
         POP   SI
         POP   DI
         RET
SAVARRAY ENDP


;---------------------------------------------------------------------
;  GETMEM  - TRANSFER 16K OF EMS PAGE  P   TO WINDOW PAGE  W
;            AL = WINDOW PAGE  W
;            DX = EMS PAGE     P
;---------------------------------------------------------------------

GETMEM   PROC  NEAR
         PUSH  AX
         PUSH  BX
         PUSH  CX
         PUSH  ES

         XOR   AH, AH
         SHL   AL, 1                   ; MULTI BY 4 (16K OFFSETS)
         SHL   AL, 1
         ADD   AL, BYTE PTR CS:[ADDRESS]        ; GET WINDOW SEGMENT
         XCHG  AH, AL
         MOV   ES, AX
         MOV   BX, DX                  ; GET PAGE
         SHL   BX, 1                   ;
         SHL   BX, 1                   ; MULTI BY 4 TO GET
         ADD   BX, CS:[BASEADDR]       ; ADD BASE ADDRESS OF EXTENDED MEMORY
         MOV   CX, 4                   ; MAP 4 4K PAGES 16K
         MOV   AH, 3
         CALL  DWORD PTR CS:[MROUTINE] ; CALL MEMORY MANAGEMENT

         POP   ES
         POP   CX
         POP   BX
         POP   AX
         RET
GETMEM   ENDP



PROGEND  LABEL BYTE                  ; END OF RETAINED CODE
         PAGE
MESSAGE  LABEL BYTE
         DB    'MOS Expanded Memory Specification driver v1.00'
         DB    ' with Work Area at      '

WORK     DB    'E0000H'
         DB    13,10,'$'

PAGESINS LABEL BYTE
         DB    '0   K bytes of expanded memory installed         ',13,10,'$'

GIZDRIVE LABEL BYTE
         DB    'Memory management required for MOS EMS driver!       ',13,10,'$'

BADADDR  DB    'Invalid work area specified!        ',13,10,'$'

MEMDEV   DB    '$$MEMDEV', 0

TEMP     DB    '    '

TEN      DW    10                    ; CONSTANT
MEMPTR   DD    0

         PAGE
;--------------------------------------------------------------------;
;             INITIALIZATION CODE - DISCARDED LATER                  ;
;--------------------------------------------------------------------;

INIT     LABEL NEAR

         MOV   WORD PTR ES:[BX+14],OFFSET PROGEND 
         MOV   WORD PTR ES:[BX+16],CS

;---------------------- REPLACE INT 67H VECTOR ----------------------;

         MOV   ES,[ZERO]
         MOV   AX,ES:[019CH]         ; SAVE ORIGINAL VECTOR
         MOV   WORD PTR [OLDINT67],AX
         MOV   AX,ES:[019EH]
         MOV   WORD PTR [OLDINT67+2],AX
 
         MOV   WORD PTR ES:[019CH],OFFSET ENTINT67
         MOV   ES:[019EH],CS

;-------------------- LOCATE MEMORY DEVICE DRIVER ------------------;

         LEA   DX, MEMDEV
         MOV   AX,3D02H
         INT   21H
         JNC   LMEM1
         MOV   BP, 0
         JMP   FINISH

LMEM1:
         MOV   BX,AX
         MOV   AX, 4400H
         INT   21H
         XOR   DH, DH
         OR    DL, 20H             ; BINARY MODE
         MOV   AX, 4401H
         INT   21H
         MOV   AX, 3F00H
         MOV   CX, 4
         LEA   DX,MEMPTR
         INT   21H
         MOV   AH, 3EH
         INT   21H
         PUSH  ES
         LES   BX,MEMPTR
         MOV   AX, ES:[BX+2] 
         MOV   WORD PTR [MROUTINE+2], AX
         MOV   AX, ES:[BX]
         MOV   WORD PTR [MROUTINE], AX
         POP   ES
         MOV   BP, 1                   ; mem-man found

MEMFOUND:

;-------------------- GET COMMAND PARAMETER ------------------------;

         LES   BX,DWORD PTR [RHOFF]
         LES   BX,DWORD PTR ES:[BX + 18]  ; GET PARAMETER POINTER

SCAN1:
         INC   BX
         MOV   AL,ES:[BX]            ; SCAN FOR BLANK
         CMP   AL, 0DH
         JNE   SCAN1A
         JMP   SCANDONE              ; RETURN TERMINATES

SCAN1A:
         CMP   AL, 20H               ;
         JNE   SCAN1                 ; REPEAT UNTIL BLANK

SCAN2:
         INC   BX                    ;
         CMP   BYTE PTR ES:[BX],20H  ; SCAN FOR NON-BLANK
         JE    SCAN2
         PUSH  BX                    ; SAVE POSITION
         XOR   CX, CX                ; ZERO OUT CX
         XOR   AX, AX                ; ZERO OUT VALUE
         XOR   DI, DI                ; ZERO OUT DI

SCAN3:
         CMP    DI, 4                ; DONE YET!!!
         JE     SCAN4                ; YES...SKIP
         MOV    CL,ES:[BX]           ; GET CHARACTER
         CMP    CL, '0'              ; 0???
         JB     SCAN4                ; DONE!!!
         CMP    CL, '9'              ; 9???
         JA     SCAN4                ; DONE!!!
         INC    DI                   ; INCREMENT DESTINATION COUNTER
         SUB    CL, '0'              ; ASCII ADJUST
         MUL    [TEN]                ; MULTIPLY BY 10
         ADD    AX, CX               ; ADD VALUE
         INC    BX                   ; INCREMENT POINTER
         JMP    SCAN3                ; REPEAT

SCAN4:
         OR     AX, AX               ; ZERO PAGES
         JNZ    SCAN5                ;
         POP    BX
         JMP    FINISH               ; SORRY CHARLIE

SCAN5:
         ADD    AX, 3                ; ADD 3
         SHR    AX, 1                ; DIVIDE
         SHR    AX, 1                ; BY 16
         SHR    AX, 1                ;
         SHR    AX, 1                ;
         CMP    AX, MAX_PAGE         ; OVER THE HILL BUD???
         JBE    SCANALLOC            ; ALLOC SPACE
         POP    BX
         JMP    FINISH               ; TIME TO REBOOT!!!

SCANALLOC:
         MOV    CX, AX               ; PLACE PAGE IN BX
         SHL    CX, 1                ; MULTIPLY BY 4
         SHL    CX, 1                ;

;        CODE FOR JRAM & EEMS HERE

         MOV    AH, 1                ; ALLOCATE
         CALL   DWORD PTR [MROUTINE] ; ALLOCATE SPACE
         MOV    CS:[BASEADDR], BX    ; STORE STARTING PAGE
         SHR    CX, 1                ; DIVIDE BY 4
         SHR    CX, 1                ;
         MOV    WORD PTR CS:[PGSAVAIL], CX    ; SAVE PAGES AVAILABLE
         MOV    WORD PTR CS:[PGSLEFT], CX     ; SAVE PAGES LEFT AS ALL

         POP    BX

DDSLOOP3:
         INC   BX                    ; SCAN FOR FIRST BLANK AFTER SIZE PARAM
         MOV   AL, BYTE PTR ES:[BX]  ; ALSO WILL STOP ON ',' 
         CMP   AL, 0DH
         JNE   DDSLOOP3A
         JMP   SCANDONE

DDSLOOP3A:
         CMP   AL, ','
         JE    DDSLOOP4
         CMP   AL, ' '
         JNE   DDSLOOP3  

DDSLOOP4:
         INC   BX                   ; SCAN FOR NON-BLANK
         CMP   BYTE PTR ES:[BX], ' '    
         JE    DDSLOOP4
         XOR   DX, DX               ; ZERO WORK ADDRESS
         XOR   CX, CX
         XOR   AH, AH
         LEA   DI, WORK

DDSLOOP5:
         MOV   AL, BYTE PTR ES:[BX]  ; GET HEX VALUE
         INC   BX
         CMP   AL, '0'
         JB    DDSCHK
         CMP   AL, '9'
         JA    DDSHEX
         SUB   AL,'0'
         JMP   SHORT DDSNEXT

DDSHEX:
         CMP   AL,'a'
         JB    DDSHEX2
         CMP   AL,'f'
         JA    DDSCHK
         SUB   AL,'a'-10
         JMP   SHORT DDSNEXT
         
DDSHEX2:
         CMP   AL,'A'
         JB    DDSCHK
         CMP   AL,'F'
         JA    DDSCHK
         SUB   AL,'A'-10

DDSNEXT:                                ; ADJUST VALUE
         SHL   DX, 1
         SHL   DX, 1
         SHL   DX, 1
         SHL   DX, 1
         ADD   DX, AX
         CMP   AL, 10
         JB    DDSLOW
         ADD   AL, 'A'-10
         JMP   SHORT DDSOUT

DDSLOW:
         ADD   AL, '0'   

DDSOUT:
         MOV   [DI], AL
         INC   DI
         INC   CX
         CMP   CX, 4
         JB    DDSLOOP5

DDSCHK:
         CMP   CX, 4                    ; FOR BYTES
         JNE   DDSBAD
         MOV   AX, DX                   ; CHECK FOR 4K BONDARY
         AND   AX, 0FC00H
         CMP   AX, DX
         JE    DDSGOOD
         MOV   AH, 9                    ; DISPLAY ERROR MESSAGE
         LEA   DX, [MESSAGE]
         INT   21H
         LEA   DX, [BADADDR]
         INT   21H
         JMP   DONESTAT

DDSGOOD:
         MOV   [ADDRESS], DH            ; SAVE VALUE    
         JMP   SHORT SCANDONE

DDSBAD:
         MOV   WORD PTR [WORK], '0E'
         MOV   WORD PTR [WORK+2], '00'

SCANDONE:
         CMP   CS:[PGSAVAIL], 0      ; ZERO PAGES???
         JE    FINISH                ; SYSTEM NOT AVAILABLE
         MOV   CS:[SYSAVAIL], 1      ; SYSTEM IS AVAILABLE
         MOV   CX, 3                 ; STORE MESSAGE
         MOV   BX, CS:[PGSAVAIL]     ; GET # OF PAGES
         SHL   BX, 1                 ; SHIFT 1 BIT LEFT
         INC   BH                    ; INCREMENT BOARD COUNT
         MOV   CS:[BOARDS], BH       ; SAVE # OF BOARDS
         XOR   BX, BX                ; ZERO OUT BASE REGISTER

SCANMSG:
         MOV   DX, CS:[PGSAVAIL]     ; GET # OF PAGES
         SHL   DX, 1                 ;
         SHL   DX, 1                 ; MULTI BY 16
         SHL   DX, 1                 ;
         SHL   DX, 1                 ;
         LEA   DI, CS:[TEMP]         ; POINT TO BEGINING OF MESSAGE
         XOR   CX, CX                ; ZERO COUNTER

DEC16:
         MOV   AX, DX                ; NUMERATOR
         XOR   DX, DX                ; CLEAR UPPER HALF
         DIV   CS:[TEN]              ; DIVIDE
         XCHG  AX, DX                ; GET QUOTIENT
         ADD   AL, 30H               ; ASCII ADJUST
         MOV   CS:[DI], AL           ; STORE IN BUFFER
         INC   DI                    ; BUMP POINTER
         INC   CX                    ; INCREMENT COUNTER
         CMP   DX, 0                 ; DONE
         JNZ   DEC16                 ; NO...REPEAT
         LEA   DI, CS:[PAGESINS]     ; GET DESTINATION
         ADD   DI, CX                ; ADD COUNT
         DEC   DI                    ; DECREMENT - SET AT END
         LEA   SI, CS:[TEMP]         ; GET ADDRESS OF TEMPORARY BUFFER

CONV:
         MOV   AL, BYTE PTR CS:[SI]  ; GET SOURCE
         MOV   BYTE PTR CS:[DI], AL  ; STORE DESTINATION
         INC   SI                    ; INCREMENT SOURCE PTR
         DEC   DI                    ; DECREMENT DEST PTR
         LOOP  CONV                  ; DO CX TIMES


comment  |

         ; Clear out page registers

         MOV   CX, MAP_SIZE          ; GET MAX SIZE
         XOR   SI, SI
         XOR   AL, AL

;;CLPORT:
         MOV   DX, WORD PTR CS:[SI]
         INC   SI
         INC   SI
         OUT   DX, AL
         INC   DX
         LOOP  CLPORT                ; REPEAT


	 |

         PAGE
;------------------------ WRITE COPYRIGHT NOTICE --------------------;

FINISH:
         MOV   AH,9
         LEA   DX,[MESSAGE]
         INT   21H
         OR    BP,BP                 ; MEMMANAGEMENT ERROR
         JNZ   MEMMANOK
	 MOV   ES,[ZERO]
	 MOV   AX,WORD PTR [OLDINT67]	  ; REPLACE VECTORS SO CONTEXT DOESN'T
	 MOV   ES:[19CH],AX	          ; CRASH	
	 MOV   AX,WORD PTR [OLDINT67+2]
	 MOV   ES:[19EH],AX
	 MOV   AH,9
         LEA   DX,[GIZDRIVE]
         INT   21H

MEMMANOK:
         LEA   DX,[PAGESINS]
         INT   21H

         JMP   DONESTAT


         if1
                %out    Pass 1  Completed.
         else
                %out    Pass 2  Completed.
         endif  


MAINSEG  ENDS
         END   BEGIN
