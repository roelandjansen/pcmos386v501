;-----------------------------------------------------------------------;
; MJS 1/5/87	removed Execcode and ExecLink variables 		;
;-----------------------------------------------------------------------;
; SAH 05/12/88	add farcall38 variable	($$shell.sys should never do an ;
;		int 38h directly.					;
;-----------------------------------------------------------------------;
; mjs 12/02/88	Removed extraneous vars for environment management and	;
;		console stack buffer.					;
;-----------------------------------------------------------------------;
; RKG 12/05/88	Expand size of critical window				;
;-----------------------------------------------------------------------;
; RDG 12/16/88	Added data items in the copy overlay area for (pathchek); RG8351
;-----------------------------------------------------------------------; RG8351
; mjs 06/21/89	Added code to manage the $compat$ environment variable.	;
;-----------------------------------------------------------------------;
; SAH 06/30/89	Add variable for critical error handling to correct	;
;		problem created with latest changes in critical handler ;
;-----------------------------------------------------------------------;
; SAH 07/06/89	Add special piece of code fragment which is used to	;
;		Jump to the $$shell.sys code segment for INT 23 vector	;
;-----------------------------------------------------------------------;
; BWR 11/20/90  Added new variable, "type_EOF" to manage the special    ;
;               case where the user does a TYPE command and specifies   ;
;               the append ">>" to the SAME file.                       ;
;-----------------------------------------------------------------------;
; BWR 12/17/90  Added two new variables to the CCOPY segment to deal    ;
;               with the new code written in MOXCPINT.ASM that performs ;
;               the COPY file++,, logic.                                ;
;               (SourcePtr & TargPtr)                                   ;
;-----------------------------------------------------------------------;

;================ EQUATES =======================

StdIn	equ	0000		; Standard handles
StdOut	equ	0001
StdErr	equ	0002

CretFil equ	3ch		; Dos calls
OpenFil equ	3dh
ClosFil equ	3eh
ReadFil equ	3fh
WritFil equ	40h
Lseek	equ	42h
UnqFil	equ	5ah
DelFil	equ	41h
ParsFil equ	29h
DupHndl equ	45h
ForcDup equ	46h
Quit	equ	4ch
GetDate equ	2ah
SetDate equ	2bh
GetTime equ	2ch
SetTime equ	2dh
GetDrv	equ	19h
SetDrv	equ	0eh
GetDir	equ	47h
ChDir	equ	3bh
MkDir	equ	39h
Rmdir	equ	3ah
GetVer	equ	30h
FreeMem equ	49h
ModMem	equ	4ah
GetMem	equ	48h
GetPSP	equ	62h
GetRet	equ	4dh
FndFrst equ	4eh
FndNext equ	4fh
GetDta	equ	2fh			; get dta function number      	; RG8351
SetDta	equ	1ah
GetKey	equ	0ch
FreeSpc equ	36h
Rename	equ	56h
IOCtrl	equ	44h
SetVct	equ	25h
GetCoun equ	38h
GSBrk	equ	33h
GetVerf equ	54h
SetVerf equ	2eh
SrchFrs equ	11h
SrchNxt equ	12h

True	equ	0ffh		; Misc equ's
False	equ	0	
DtaAddr equ	80h
CR	equ	13
LF	equ	10
EOF	equ	1ah
Tab	equ	9
Bell	equ	7
BS	equ	8
Bslash	equ	'\'
Fslash	equ	'/'
Escape	equ	27

rt	equ	03	; top row		; Window Equ's
ct	equ	10	; top column
rb	equ	10	; bottom row
cb	equ	69	; bottom column 
color	equ	4fh	; white on red color for window

CmdMax	equ	9	; limit for CmdName	; Counter limits
EBufMax equ	80	; limit for ExtrBuf
InMax	equ	80	; limit for InBuf
OutMax	equ	80	; limit for OutBuf

;	Size and offset equ's

LBufSize equ	128	; size of LineBuf and related buffers

BlkBack equ	0	; offset of back pointer in block stack
BlkDesc equ	2
BlkEflg equ	3	; offset of BatEFlg value in block stack
BlkLine equ	4	; offset of BatLine value in block stack
BlkEcho equ	8	; offset of BatEcho  "   "  "     "
BlkFor	equ	9	; offset of BatForSe "  "  "     "
BlkParm equ	11	; offset of BatParms string in block stack

BlkSize equ	11	; preliminary size of a block, to account
			; for the back pointer, the descriptor,
			; BatLine, BatEcho, and BatForSe

;================== MACROS ==================

True?	MACRO	testflag
	cmp	testflag,true
	ENDM

ResFlg	MACRO	flag
	mov	BYTE PTR flag,False
	ENDM

SetFlg	MACRO	flag
	mov	BYTE PTR flag,True
	ENDM

MOS	MACRO	fn
	mov	ah,fn
	int	21h
	endm

Ljcxz	MACRO	jmpdest ;; Long jumps
	LOCAL	lp1,lp2
	jcxz	lp1
	jmp	lp2
lp1:	jmp	jmpdest
lp2:
	ENDM

Lje	MACRO	jmpdest
	LOCAL	ppp1
	jne	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Ljne	MACRO	jmpdest
	LOCAL	ppp1
	je	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Ljz	MACRO	jmpdest
	LOCAL	ppp1
	jnz	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Ljnz	MACRO	jmpdest
	LOCAL	ppp1
	jz	ppp1
	jmp	jmpdest
ppp1:
	ENDM


Ljc	MACRO	jmpdest
	LOCAL	ppp1
	jnc	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Ljnc	MACRO	jmpdest
	LOCAL	ppp1
	jc	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Lja	MACRO	jmpdest
	LOCAL	ppp1
	jbe	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Ljb	MACRO	jmpdest
	LOCAL	ppp1
	jae	ppp1
	jmp	jmpdest
ppp1:
	ENDM

Ljnb	MACRO	jmpdest
	LOCAL	ppp1
	jb	ppp1
	jmp	jmpdest
ppp1:
	ENDM

;==================== DATA =====================

DATASEG SEGMENT AT 0

DataStart LABEL BYTE

	ORG 0100H

;	Storage for general buffers

;	START OF KEEP IN THIS ORDER SECTION
Attmpt1 db	80 dup(?)	; Attmpt1 and Attmpt2 must always be
Attmpt2 db	80 dup(?)	; allocated in this order since Attmpt2 may
				; be used as a spill over buffer for Attmpt1
;	END OF KEEP IN THIS ORDER SECTION

CmdDrv	db	?	; drive letter from command line
CmdName db	9 dup(?)	; command name from ExtrBuf
Dchar	db	?	; used as buffer for DispChar
			; parameter block for EXEC call
ExecPrm dw	?	; segment address of environment
	dw	?	; offset of command line tail
	dw	?	; segment of command line tail
	dw	?	; offset of FCB1
	dw	?	; segment of FCB1
	dw	?	; offset of FCB2
	dw	?	; segment of FCB2

	db	7 dup(?)	; extension for FCB1
FCB1	db	37 dup(?)	; FCB1
	db	7 dup(?)	; extension for FCB2
FCB2	db	37 dup(?)	; FCB2

ExtPath db	64 dup(?)	; path string extracted from environment
ExtPdr	db	?		; drive letter from extracted path
ExtrBuf db	80 dup(?)	; command line copied here from LineBuf
				; when it is an external command
FlfBuf	db	13 dup(?)	; buffer for FullForm subroutine
ForSbuf db	LBufSize dup(?) ; holds the for command and set members

;	KEEP IN THIS ORDER
	dw	?		; storage for requested and returned count
				; for function 0A call
LineBuf db	128 dup(?)	; initial input buffer for commands
;	KEEP IN THIS ORDER


ParmLen db	?		; length of ParmBuf, for EXEC call
ParmBuf db	128 dup(?)	; the parameter line in copied into here
PathStr db	128 dup(?)	; copy of path from environment
PromStr db	128 dup(?)	; copy of prompt from environment
	db	7 dup(?)	; extension for PrsFCB
PrsFCB	db	37 dup(?)	; FCB for using parse call

SaveDir db	64 dup(?)	; holds original drive\path spec for GenPthStr
SaveName db	8 dup(?)	; for copy of internal command name
SaveSI	dw	?		; for SI when recycling in command search
UseDr1	db	?		; drive letter for first attmept
UseDr2	db	?		; drive letter for second attempt
WorkBuf db	128 dup(?)	; general work area
DirBuf	db	64 dup(?)	;jrbr current directory buffer for DispPrompt

;	variables for redirection

AppFlg	db	?		; indicates that >> was used.  Append to file.
InBuf	db	80 dup(?)	; file name for input redir spec
InCnt	db	?		; length counter for InBuf
OrigIn	db	?		; original PSP system handle for StdIn
OrigOut db	?		; original PSP system handle for StdOut
OutBuf	db	80 dup(?)	; file name for output redir spec
OutCnt	db	?		; length counter for OutBuf
OvrIH	dw	?		; handle for input redir spec
OvrIn	db	?		; indicates that an input redir spec exists
OvrOH	dw	?		; handle for output redir spec
OvrOut	db	?		; indicates that an output redir spec exists
inopen	db	?		; true when input file is already open
outopen	db	?		; true when output file is already open

;	variables for chaining/piping

ChainCnt db	?		; counter to manage chaining sequence
ChainFlg db	?		; indicates that chaining is in effect
PipeStat db	?		; controls I/O redirection sequence
OldPStat db	?		; previous value of PipeStat
PipeFile db	?		; indicates that pipe files exist
PfHandl1 dw	?		; handle of first pipe file
PfHandl2 dw	?		; handle of second pipe file
PfName1 db	80 dup(?)	; string to hold name for first pipe file
PfName2 db	80 dup(?)	; string to hold name for second pipe file

;	variables for batch processing

Batch	db	?		; indicates a batch file is being processed
BatEcho db	?		; indicates the echo state for batch files
BatEcDf db	?		; indicates the default echo state
BatNest db	?		; nesting level  0 for first batch file
BatEnd	dw	?		; segment pointer to end of Block Stack
BatChar db	?		; storage for GetBChar subroutine
BatLCnt db	?		; counter for truncation control when writing
				; into LineBuf from a batch file
BatLPtr dw	?		; point in LineBuf to write next char
BatEFlg db	?		; indicates that an end of file was found
BatLine dd	?		; line pointer of next batch file line to read
BatParms db	128 dup(?)	; holds the strings for %0-%9
BatTabl dw	10 dup(?)	; pointers for %0-%9 in BatParms
BatPrmE dw	?		; pntr to original end of BatParms (for shift)
BatOldNm db	80 dup(?)	; holds the current batch file name for nesting
BatHandl dw	?		; handle of the batch file
BatPtr	dw	?		; pointer to either Attmpt1 or Attmpt2, to
BatForSe dw	?		; record of ForStkE at the start of batch file
ErrLvL	db	?		; value for ERRORLEVEL
nointerr db	?		; flag to disable internal errorlevel setting
dointerr db	?		; flag to hold interr data from cmd list
LastErl db	?		; save for ErrLvl when recycle to internal
BatForCa dw	?		; ForStkE at the start of +call command
Batnonest db	?		; flag to disable batch file nesting
bat@line db	?		; flag that an @ sign started the line

;	vars for the ReadBatLine procedure

DstTrunc db	?	; true if the line read in is longer than	
			; LBufMax
BatLRead db	?	; true if the present buffer is the last
MidLIne db	?	; true if anther buffer must be read to complete
			; show which one successfully opened the file

;	misc variables

AttPtr	dw	?	; Attempt pointer, points to either Attmpt1
			; or Attmpt2
Assumint db	?	; control flag for command search order
BegSI	dw	?	; holds an initial value for pointer SI
Bkattr	db	?	; background color attribute
CmdAddr dw	?	; address of internal command
CmdCnt	db	?	; length counter for CmdName
CmdType db	?	; indicates type of command being processed
			; 0 internal, 1 external, 2 drive change and	
			; 3 'command'
Copt	db	?	; indicates a /c was found in the parameter
CopyFix1 db	?	; clean up verify setting from copy command
CopyFix2 db	?	; clean up copy storage area
CopyFix3 db	?	; reset default output class to OrigClass
CopyFix4 db	?	; close the source file
CopyFix5 db	?	; Delete the source file (full disk error)
TrgHndl dw	?	; handle of target for COPY command
SignFix1 db	?	; clean up Security Information
CopySeg dw	?	; segment address of copy storage area
CopySize dw	?	; byte count of storage area
SourcePtr dd    ?       ; File pointer in "source" file.
TargPtr   dd    ?       ; File pointer in "targ" file.
type_EOF dd     ?       ; EOF point in file being read by TYPE.
CpFlg	db	?	; indicates 'command' was entered without a
			; drive\path spec.  Treat as external.
CpPntr	dw	?	; pointer to drive\path spec for 'command'
Directc db	?	; direction control for the critical error handler
EchoStat db	?	; flag to indicate echo status
EnvAddr dw	?	; segment address of the master environment
EnvSize dw	?	; paragraphs from last envsize command
EnvPara dw	?	; paragraphs allocated for the master enviroment	
ExtrCnt db	?	; counter for ExtrBuf
FndBat	db	?	; flag to indicate that a BAT was found
FndExe	db	?	; flag to indicate that a EXE was found
ForPchr db	?	; the char after the 1st % for FOR IN DO cmd
ForScnt db	?	; number of set members for FOR IN DO cmd
ForSbln db	?	; original length for ForSBuf
ForSptr dw	?	; pointer to next set member for FOR IN DO cmd
ForEnd	db	?	; flag to indicate that the command just 
			; processed was the last of the FOR set
ForStkE dw	?	; segment pointer to the end of the FOR stack
CForStkL dw	?	; record of ForStkE when Batch is false

ForFspec db	?	; flag to indicate a global filespec was found
ForPlen db	?	; length of the path portion of the global filespec
ForPptr dw	?	; pointer to the path portion of the global filespec
ForDTA	db	43 dup(?)	; DTA for a global filespec's processing
ForStop db	?	; flag to indicate that LineBuf should be ignored

Ipass	db	?	; controls attempt choice in EXEC call loop
MlStrt	dw	?	; pointer into LinbBuf for command processing
NoDot	db	?	; flag for the .DOT command
NullParm db	?	; indicates a null ParmBuf (internal commands)

OrigClass db	?	; original value of TCBCDFT at entry to copy command
PathPtr dw	?	; pointer for parsing PathStr
PlusCmd db	?	; true when the command starts with a + sign
Popt	db	?	; indicates a /p was found in the parameter
PSPparnt dw	?	; storage for original PSP parent PSP segment
PSPterm dd	?	; storage for original PSP terminate vector
QuotLvl db	?	; indicates when the data being parsed is
			; within quote marks
SaveSP	dw	?	; holds stack pointer during EXEC call
SkipProc db	?	; controls skipping when don't use a period, fail the
			; external search and succeed an internal search
			; used to prevent piping and redirection from being
			; set up twice
SpecDrv db	?	; indicates that a drive was specified in 
			; the command line
SpecPath db	?	; indicates that a path was specified in
			; the command line
SrcHndl dw	?	; handle of source, made global for error cleanup
TabCnt	db	?	; +text counter for override when expanding a tab
TempSeg dw	?	; temporary segment pointer for +EXCEPT/+ONLY
TcbIDnum dw	?	; ID number of the current TCB
TcbSeg	dw	?	; segment pointer of the current TCB
scboff	dw	?	; offset to SCB
scbseg	dw	?	; segment of SCB
farcall38 dd	?	; 38 vector from SCBFAR38
wordten  dw	10	; Constant 10
minsign  db	'N'	; Minus sign flag
d4_parent dd	?	; holds d4 vector value to use when cleaning up from
			; the BASIC interpreter at the parent shell level
d4_child dd	?	; holds the d4 vector value around an exec call from
			; a non-parent level shell (BASIC interp fix)

;	Window Data for critical-error messages

cursor	 dw	?	; saved cursor position
wactive  db	?	; window active (Y is yes, N is no) 
scrndata db	 ((cb-ct)*(rb-rt)+100) dup (0,0) ; screen data area
devnum	 db	?	; device number of crit err
crit24	 db	?	; zero if a parallel port  (not very critical)
crit24al db	?	; al value use by critical handler
far23hnl db	5 dup (?)    ; JMP ($shell.sys) : INT23

;	storage for a copy of the MOSMIMAN save buffer for function 0A

Save0A	db	519 dup(?)

;	Start of overlay data area for internal commands
;	must manage OverLay and size manually

OvLayAr  LABEL BYTE

	dw	512 dup(?)	; reserve 1k bytes for the overlay area

;	Start of stack area

	db	300 dup('stack')
	
	EVEN

StackTop  LABEL BYTE	; top of normal stack

	dw	?

dataend LABEL BYTE	; the stock environment goes here

DATASEG ENDS

OverLay  equ	OvLayAr - DataStart

CdirS  SEGMENT AT 0	; data for the dir command
	
	ORG  OverLay

DWopt	db	?	; indicates that a /w was found in ParmBuf
DDopt	db	?	; indicates that a /d was found in ParmBuf
DPopt	db	?	; indicates that a /p was found in ParmBuf
DSopt	db	?	; indicates that a /s was found in ParmBuf
DAopt	db	?	; indicates that a /a was found in ParmBuf
DCopt	db	?	; indicates that a /c was found in ParmBuf
DrvNum	db	?	; number of the drive to be used
			; be temporarily overwritten with a 0
Dlines	db	?	; line counter when /p is used
Dnames	db	?	; line counter when /w and /p is used
DfileCnt dw	?	; file counter
DtotBytes dd	?	; total byte counter
MaxFiles dw	?	; file counter for sorting
SortType db	?	; type code for sorting, 0 for sort by file 
			; name, 1 - by ext, 2 - date/time, 3	- size
NextBlk dw	?	; pointer to table of offsets when using from
			; sorted data
TotFiles dw	?	; count of data blocks left when using from 
			; sorted data
DidHead db	?	; true once the column heading has been put up

CdirS  ENDS

CcopyS	SEGMENT AT 0	; data for the copy command
	
	ORG  OverLay

brf1	db	?	; branch control flag
AssumTrg db	?	; a target is being assumed
CtAopt	db	?	; a /A was found for the target
CtBopt	db	?	; a /B was found for the target
CsAopt	db	?	; a /A was found for the source
CsBopt	db	?	; a /B was found for the source
SpecSopt db	?	; true if a source option (/a or /b) was spec'ed
SpecTopt db	?	; true if a target option was spec'ed
CVopt	db	?	; a /V was found 
FindPlus db	?	; true if a '+' sign was found 
TrgGlbl db	?	; global spec in the derived target
OrgTrgGl db	?	; global spec in the original target
SrcGlbl db	?	; global spec in the source
ExisTrg db	?	; a target exists (and must be closed)
SrcOnce db	?	; one source has been processed
SkipForm db	?	; skip formation of a target name
SetSkip db	?	; set the skip flags true
HoldFrst db	?	; indicates hold first name mode
HfMastr db	?	; indicates when the first file spec is being
			; processed for hold first name mode
HfName	db	12 dup(?)	; buffer for the first fname.ext when in hold
			; first mode
SrcPntr dw	?	; pointer to next source spec
WorkBuf2 db	80 dup(?)	; general work area #2
CpyPtt	db	11 dup(?)	; storage for the expanded wild card pattern
LastRead db	?	; flags last read cycle for a source file
CopyCnt dw	?	; count of copied files
MoveDate db	?	; true if the source date is to be transferred
set_sysdate db  ?       ; True if new date is to be set?
NewDate dw	?	; the new date for the target
NewTime dw	?	; the new time for the target
SrcDev	db	?	; true if the source is a device
TrgDev	db	?	; true if the target is a device
CretTrg db	?	; true if a target is to be created
Ccopt	db	?	; true if a /c option was found
CoptCl	db	?	; class letter used with /c (0 if none used)
CdatBuf db	10 dup(?)	; buffer for func 83
TrgBuf	db	80 dup(?)	; copy of target string for func 83
TempName db	80 dup(?)	; buffer for temp file name for class change
srcentry db	128 dup (?)		; source entry dta             	; RG8351
trgentry db	128 dup (?)		; target entry dta             	; RG8351

CcopyS	ENDS

CeraseS  SEGMENT AT 0	; data for the erase command
	
	ORG  OverLay

Evopt	db	?	; indicates that a /v was found in ParmBuf
Eyopt	db	?	; indicates that a /y was found in ParmBuf
EdrvNum db	?	; number of the drive to be used

CeraseS  ENDS

CrenameS  SEGMENT AT 0	; data for the rename command
	
	ORG  OverLay

CPttrn	db	11 dup(?)	; storage for the expanded wild card pattern
Name1	dw	?	; holds location of file name for 1st parm
Name2	dw	?	; holds location of file name for 2nd parm
RspecDrv db	?	; holds the drive number specified in the	
			; first parameter
Prm1Strt dw	?	; holds the location of the start of the 
			; first parameter
renflgs db	?	; used as bit flags - see comments in source code
renbuf	db	128 dup(?)	; temp buffer for string work

CrenameS  ENDS

CtypeS	SEGMENT AT 0	; data for the type command
	
	ORG  OverLay

Hopt	db	?	; indicates that a /h was found in ParmBuf
TypeHndl dw	?	; handle for the file being typed
DataCnt dd	?	; counter for right column of display
	
CtypeS	ENDS

CsignonS SEGMENT AT 0	; data for signon command

	ORG OverLay

len1	db	?
parm1	db	4 dup (?),?
len2	db	?
parm2	db	6 dup (?)
trys	db	?		; no of trys for bad password count
savecls db	?		; save class during get input
soncls	db	3 dup (?)
organsi	db	?		; orignal tcbansi value
	even
hfoff	dw	?	     	; file pointer high
lfoff	dw	?	     	; file pointer low
sign23o	dw	?	     	; orignal signon INT 23 vector offset
sign23s dw	?		; orignal signon INT 23 vector offset
	
CsignonS ENDS
