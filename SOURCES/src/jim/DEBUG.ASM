	include page.inc
	title DEBUG.ASM - MOS DEBUG Command main program and Command Proc.
;
;******************************************************************************
;*									      *
;*			  MOS Development Specification			      *
;*									      *
;* Command type: External		Assigned to:	    Stewart A. Hyde   *
;* Command name: DEBUG			Date assigned:	    August 20, 1986   *
;*					Date completed:			      *
;* Command format: DEBUG d:[path][filename][.ext][parm1][parm2]		      *
;* Purpose:  To provide debugging facilities to MOS			      *
;* Refer to: IBM PC-DOS 3.2 DOC and MOSDEBUG.DOC			      *
;* Last Update:				By:				      *
;******************************************************************************
;-----------------------------------------------------------------------;
; 	07/23/87	SAH  	Misc Cleanup and Maintinance		;
;-----------------------------------------------------------------------;
;       08/20/87	SAH     faster dump out to screen		;
;-----------------------------------------------------------------------;
;	03/02/88	SAH 	Corrected problem with 286 MOS		;
;-----------------------------------------------------------------------;
;	09/08/88	RKG	Misc Cleanup				;
;	11/22/88	RKG	Message changes 			;
;-----------------------------------------------------------------------;
;	12/09/88	SAH	Up version to 3.00 (bug fixes made)	;
;-----------------------------------------------------------------------;
;	02/20/89	SAH	Converted INT 38 to INT SERVICES	;
;-----------------------------------------------------------------------;
;	03/20/89	SAH	Remove 386 from messages		;
;-----------------------------------------------------------------------;
;	11/27/89	BWR	Messages marked for foreign language	;
;				translation.				;
;-----------------------------------------------------------------------;
;	04/26/90	SAH	Added 486 detection, update copyright	;
;-----------------------------------------------------------------------;
; 	05/17/90	SAH	Correction for g=c800:0005 		;
;-----------------------------------------------------------------------;
;	04/17/92	SAH     Up to version 5.01, copyright		;
;-----------------------------------------------------------------------;

	page
	include debug.pub
	include options.inc
;=========================================================================
;  Note:
;
;	The reason that certain EQU's are enclosed in the redundant
;	"if" group is to hide them from Periscope's PUBLIC facility.
;	PUBLIC considers EQU symbols when generating the list of
;	publics when run on an assembly module.
;=========================================================================
	if	0 eq 0
BPSOFT	equ	10	; # of soft break points
BPHARD	equ	10	; # of hard break points
	endif

	page
;	MAIN.ASM
extrn	asm:near, comp:near, dump:near, entr:near, fill:near, go:near
extrn	hex:near, input:near, load:near, move:near, nameout:near
extrn	output:near, proceed:near, reg:near, search:near
extrn	trace:near, unasm:near, write:near, asmun:near, verify:near

;	EXTRA.ASM
extrn	bpon:near, bpoff:near, math:near, help:near, swap:near
extrn	shell:near, config:near, console:near, pause:near, delay:near
extrn	bpset:near, bpclr:near, bplist:near, bpdisp:near
extrn	mosinfo:near

;	TRACE.ASM
extrn	SetInt:near, RestInt:near, SStep:near, Break2:near, Break3:near
extrn	SaveReg:near, RestReg:near, SetBrk:near, ClrBrk:near
extrn	Term:near, CtlBrk:near, Fatal:near, InsBrk:near, RemBrk:near
extrn	SwapScr:near, ClrSBuf:near, SetTrap:near
 
;	SUPPORT.ASM
extrn	GetCmd:near, GetOp:near, GetReg:near
extrn	GetRang:near, GetLen:near, GetList:near, GetAddr:near, SynErr:near
extrn	GetHex:near, LoadPrg:near, ErrMsg:near, DispFg:near, DispOp:near
extrn	MakeEA:near, MakeReg:near, MakeHex:near, GetEnv:near, RemSpac:near
extrn	MakeOp:near, ScanEa:near,  FixBuff:near, GetKBD:near, DumpReg:near
extrn	MakeFcb:near, SetSegs:near, SizeMax:near, SizeMin:near

;	MATH.ASM
extrn	Is8087:near

;	CONSOLE.ASM
extrn	GetKey:near, GetMsg:near, OutChar:near, OutMsg:near, ComOut:near

;	LASTMOD.ASM
extrn	endbyte:byte

	page
;-------------------------------------------------------------------------;
;	Macro:	  makech						  ;
;		  sends char to pointer specify by di and increments di	  ;
;	Input:	  char to be stored					  ;
;	Output:								  ;
;-------------------------------------------------------------------------;

makech	macro	value
	mov	byte ptr [di], value
	inc	di
	endm

	page

tcb	segment at 07777h
	include	   mostcb.inc
	include	   mostcb.pub
tcb	ends

moss	segment word public 'code'
	assume cs:moss;ds:moss;es:moss


	org	100h

start:
	jmp	start1
	db	8,8,8
tsl	db	'PC-MOS Debugger v5.01 (920417)',13,10 ;@@XLAT
	db	'(c) Copyright 1987 - 1992 The Software Link, Incorporated' ;@@XLAT
	db	13,10
	db	'All rights reserved worldwide ',13,10,13,10,'$' ;@@XLAT
	db	8,' ',26, 13, 10

OnMOS	db	'Y'

start1:
;
;	Routine to check mos version
;
	mov	ah, 30h
	mov	bx, ax
	mov	cx, ax
	mov	dx, ax
	int	21h
	push	ax
	mov	ah,30h
	mov	bx,-1
	int	21h
	pop	bx
	cmp	ax,bx
	jne	mosok
	mov	[OnMOS],'N'
mosok:
;
;	all ok continue with bussiness
;
	mov	ax,word ptr cs:[2]		; get high place in memory
	mov	cs:[maxmem],ax		; save it for loadpgm
	call	SetTrap ; set traps
	jmp	begin	; solves 1a problem for nice display when typed..  

cpumsg	label  byte
	db     '86 $'
	db     '186$'
	db     '286$'
	db     '386$'
	db     '486$'

	page
	even
exetab	label	word
	dw	offset dummy	; dummy return for carriage returns
	dw	offset asm	; assemble command  
	dw	offset comp	; compare command   
	dw	offset dump	; dump command	    
	dw	offset entr	; enter command	    
	dw	offset fill	; fill command	    
	dw	offset go	; go command	    
	dw	offset hex	; hex command	    
	dw	offset input	; input command	    
	dw	offset load	; load command	    
	dw	offset move	; move command	    
	dw	offset nameout	; name command	    
	dw	offset output	; output command    
	dw	offset proceed	; proceed command
	dw	offset quit	; quit command	       
	dw	offset reg	; register command     
	dw	offset search	; search command       
	dw	offset trace	; trace command
	dw	offset unasm	; unassemble command	       
	dw	offset write	; write command		       
	dw	offset asmun	; assemble unassemble command  
	dw	offset bpset	; break point set	       
	dw	offset bpclr	; break point clear	       
	dw	offset bpoff	; break point disable	       
	dw	offset bpon	; break point enable	       
	dw	offset bplist	; break point list	       
	dw	offset verify	; verify command       
	dw	offset math	; dump coprocessor registers   
	dw	offset swap	; swap screen to see output    
	dw	offset shell	; shell to MOS operating system
	dw	offset help	; online help on command       
	dw	offset config	; display debug configuration  
	dw	offset console	; set extern console	       
	dw	offset pause	; pause and wait for key       
	dw	offset delay	; delay			       
	dw	offset dummy	; comment		       
	dw	offset dummy	; comment		       
	dw	offset mosinfo	; mos info dump				    
	dw	offset dummy	;			      

exeend	label	word

exelen	equ	($-exetab)/2	; lenght of table in words

	page
cmdtab	label	word
	db	'  '		; dummy return for carriage returns
	db	'A '		; assemble command
	db	'C '		; compare command
	db	'D '		; dump command
	db	'E '		; enter command
	db	'F '		; fill command
	db	'G '		; go command
	db	'H '		; hex command
	db	'I '		; input command
	db	'L '		; load command
	db	'M '		; move command
	db	'N '		; name command
	db	'O '		; output command
	db	'P '		; proceed command
	db	'Q '		; quit command
	db	'R '		; register command
	db	'S '		; search command
	db	'T '		; trace command
	db	'U '		; unassemble command
	db	'W '		; write command
	db	'AU'		; assemble-unassemble command
	db	'BS'		; break point set
	db	'BC'		; break point clear
	db	'BD'		; break point disable
	db	'BE'		; break point enable
	db	'BL'		; break point list
	db	'V '		; verify command
	db	'7 '		; dump coprocessor registers
	db	'\ '		; swap screen to see output
	db	'! '		; shell to MOS operating system
	db	'? '		; online help on command
	db	'C?'		; display debug configuration
	db	'CO'		; External Console Toggle for Com1
	db	'" '		; pause and wait for key
	db	': '		; delay
	db	'* '		; comment
	db	'; '		; comment
	db	'X '		; mosinfo dump
	db	'  '		;

cmdend	label	 word

cmdln	equ	($-cmdtab)/2	; lenght of table in words

if1
	if	 cmdln - exelen
		 %out	 ERROR in Generating Command Tables
	endif
endif

	page
	even
regall	label	word	   ; storage area for registers
regax	dw	0
regcx	dw	0
regdx	dw	0
regbx	dw	0
regsp	dw	0
regbp	dw	0
regsi	dw	0
regdi	dw	0
reges	dw	0
regcs	dw	0
regss	dw	0
regds	dw	0
regip	dw	0100h
regflag dw	0

regbak	dw     14 dup (0)

regdb	dw     9  dup (0)

regtran dw	0, 6, 2, 4, 8, 10, 12, 14, 22, 16, 20, 18, 24, 26

RegType db	0		; regtype use in assembly process

	even
r87all	label	word
r87ctr	dw	0
r87stat dw	0
r87tag	dw	0
r87iseg dw	0
r87ioff dw	0
r87dseg dw	0
r87doff dw	0
r87stk	dw	80 dup (0)

maxmem	dw	0		; high point in memory
fullload db	1		; flag to indicate if full image loaded

	page
allias	label	word
	dw	offset opjb
	dw	offset opjc	; redirected to JC
	dw	offset opjnae
	dw	offset opjc	; redirected to JC
	dw	offset opjnb
	dw	offset opjnc	; redirected to JNC
	dw	offset opjae
	dw	offset opjnc	; redirected to JNC
	dw	offset opje
	dw	offset opjz	; redirected to JZ
	dw	offset opjne
	dw	offset opjnz	; redirected to jNZ
	dw	offset opjbe
	dw	offset opjna	; redirected to JBE
	dw	offset opjnbe
	dw	offset opja	; redirected to JA
	dw	offset opjp
	dw	offset opjpe	; redirected to JPE
	dw	offset opjnp
	dw	offset opjpo	; redirected to JPO
	dw	offset opjnge
	dw	offset opjl	; redirected to JL
	dw	offset opjnl
	dw	offset opjge	; redirected to JGE
	dw	offset opjng
	dw	offset opjle	; redirected to JLE
	dw	offset opjnle
	dw	offset opjg	; redirected to JG
	dw	offset oplne
	dw	offset oplnz	; redirected to LOOPNZ
	dw	offset ople
	dw	offset oplz	; redirected to LOOPZ
	dw	offset oprepne
	dw	offset oprepnz	; redirected to REPNZ
	dw	offset oprepe
	dw	offset oprep	; redirected to REP
	dw	offset oprepz
	dw	offset oprep	; redirected to REP
	dw	offset opsal
	dw	offset opshl	; redirected to SHL
	dw	0, 0

	page
optab	label	byte
opadd	db	3, 'ADD'
oppush	db	4, 'PUSH'
oppop	db	3, 'POP'
opor	db	2, 'OR'
opadc	db	3, 'ADC'
opsbb	db	3, 'SBB'
opand	db	3, 'AND'
opdaa	db	3, 'DAA'
opsub	db	3, 'SUB'
opdas	db	3, 'DAS'
opxor	db	3, 'XOR'
opaaa	db	3, 'AAA'
opcmp	db	3, 'CMP'
opaas	db	3, 'AAS'
opinc	db	3, 'INC'
opjo	db	2, 'JO'
opjno	db	3, 'JNO'
opjc	db	2, 'JC'
opjb	db	2, 'JB'
opjnae	db	4, 'JNAE'
opjnc	db	3, 'JNC'
opjnb	db	3, 'JNB'
opjae	db	3, 'JAE'
opjz	db	2, 'JZ'
opje	db	2, 'JE'
opjnz	db	3, 'JNZ'
opjne	db	3, 'JNE'
opjna	db	3, 'JNA'
opjbe	db	3, 'JBE'
opja	db	2, 'JA'
opjnbe	db	4, 'JNBE'
opjs	db	2, 'JS'
opjns	db	3, 'JNS'
opjpe	db	3, 'JPE'
opjp	db	2, 'JP'
opjpo	db	3, 'JPO'
opjnp	db	3, 'JNP'
opjnge	db	4, 'JNGE'
opjl	db	2, 'JL'
opjge	db	3, 'JGE'
opjnl	db	3, 'JNL'
opjle	db	3, 'JLE'
opjng	db	3, 'JNG'
opjg	db	2, 'JG'
opjnle	db	4, 'JNLE'
optest	db	4, 'TEST'
opxchg	db	4, 'XCHG'
opmov	db	3, 'MOV'
oplea	db	3, 'LEA'
opnop	db	3, 'NOP'
opcbw	db	3, 'CBW'
opcwd	db	3, 'CWD'
opcall	db	4, 'CALL'
opwait	db	4, 'WAIT'
oppushf db	5, 'PUSHF'

	page
oppopf	db	4, 'POPF'
opsahf	db	4, 'SAHF'
oplahf	db	4, 'LAHF'
opmovsb db	5, 'MOVSB'
opmovsw db	5, 'MOVSW'
opcmpsb db	5, 'CMPSB'
opcmpsw db	5, 'CMPSW'
opstosb db	5, 'STOSB'
opstosw db	5, 'STOSW'
oplodsb db	5, 'LODSB'
oplodsw db	5, 'LODSW'
opscasb db	5, 'SCASB'
opscasw db	5, 'SCASW'
opret	db	3, 'RET'
opretf	db	4, 'RETF'
oples	db	3, 'LES'
oplds	db	3, 'LDS'
opint	db	3, 'INT'
opinto	db	4, 'INTO'
opiret	db	4, 'IRET'
opaam	db	3, 'AAM'
opaad	db	3, 'AAD'
opxlat	db	4, 'XLAT'
opesc	db	3, 'ESC'
oplnz	db	6, 'LOOPNZ'
oplz	db	5, 'LOOPZ'
oplne	db	6, 'LOOPNE'
ople	db	5, 'LOOPE'
oploop	db	4, 'LOOP'
opjcxz	db	4, 'JCXZ'
opin	db	2, 'IN'
opout	db	3, 'OUT'
opjmp	db	3, 'JMP'
oplock	db	4, 'LOCK'
oprepnz db	5, 'REPNZ'
oprepz	db	4, 'REPZ'
oprepne db	5, 'REPNE'
oprepe	db	4, 'REPE'
oprep	db	3, 'REP'
ophlt	db	3, 'HLT'
opcmc	db	3, 'CMC'
opclc	db	3, 'CLC'
opstc	db	3, 'STC'
opcli	db	3, 'CLI'
opsti	db	3, 'STI'
opcld	db	3, 'CLD'
opstd	db	3, 'STD'
opnot	db	3, 'NOT'
opneg	db	3, 'NEG'

	page
opmul	db	3, 'MUL'
opimul	db	4, 'IMUL'
opdiv	db	3, 'DIV'
opidiv	db	4, 'IDIV'
opdec	db	3, 'DEC'
oprol	db	3, 'ROL'
opror	db	3, 'ROR'
oprcl	db	3, 'RCL'
oprcr	db	3, 'RCR'
opshl	db	3, 'SHL'
opsal	db	3, 'SAL'
opshr	db	3, 'SHR'
opsar	db	3, 'SAR'

	page
op186	label	byte
opbound db	5, 'BOUND'
openter db	5, 'ENTER'
opins	db	3, 'INS'
opinsb	db	4, 'INSB'
opinsw	db	4, 'INSW'
opleave db	5, 'LEAVE'
opouts	db	4, 'OUTS'
opoutsb db	5, 'OUTSB'
opoutsw db	5, 'OUTSW'
oppopa	db	4, 'POPA'
oppusha db	5, 'PUSHA'

	page
op286	label	byte
oparpl	db	4, 'ARPL'
opclts	db	4, 'CLTS'
oplgdt	db	4, 'LGDT'
oplidt	db	4, 'LIDT'
oplldt	db	4, 'LLDT'
oplmsw	db	4, 'LMSW'
oplsl	db	3, 'LSL'
opltr	db	3, 'LTR'
opsgdt	db	4, 'SGDT'
opsidt	db	4, 'SIDT'
opsldt	db	4, 'SLDT'
opsmsw	db	4, 'SMSW'
opstr	db	3, 'STR'
opverr	db	4, 'VERR'
opverw	db	4, 'VERW'

	page
op386	label	byte
opmovsx db	5, 'MOVSX'
opmovzx db	5, 'MOVZX'
oplfs	db	3, 'LFS'
oplgs	db	3, 'LGS'
oplss	db	3, 'LSS'
opshld	db	4, 'SHLD'
opbsf	db	3, 'BSF'
opbsr	db	3, 'BSR'
opbt	db	2, 'BT'
opbtc	db	3, 'BTC'
opbtr	db	3, 'BTR'
opbts	db	3, 'BTS'
opibts	db	4, 'IBTS'
opxbts	db	4, 'XBTS'
opjecxz db	5, 'JECXZ'
opseto	db	4, 'SETO'
opsetno db	5, 'SETNO'
opsetb	db	4, 'SETB'
opstnae db	6, 'SETNAE'
opsetnb db	5, 'SETNB'
opsete	db	4, 'SETE'
opsetz	db	4, 'SETZ'
opsetne db	5, 'SETNE'
opsetnz db	5, 'SETNZ'
opsetbe db	5, 'SETBE'
opsetna db	5, 'SETNA'
opstnbe db	6, 'SETNBE'
opseta	db	4, 'SETA'
opsets	db	4, 'SETS'
opsetns db	5, 'SETNS'
opsetp	db	4, 'SETP'
opsetpe db	5, 'SETPE'
opsetnp db	5, 'SETNP'
opsetpo db	5, 'SETPO'
opsetl	db	4, 'SETL'
opstnge db	6, 'SETNGE'
opsetnl db	5, 'SETNL'
opsetge db	5, 'SETGE'
opsetle db	5, 'SETLE'
opsetng db	5, 'SETNG'
opstnle db	6, 'SETNLE'
opsetg	db	4, 'SETG'


	page
op87	label	byte
opfld	db	3, 'FLD'
opfst	db	3, 'FST'
opfstp	db	4, 'FSTP'
opfxch	db	4, 'FXCH'
opfcom	db	4, 'FCOM'
opfcomp db	5, 'FCOMP'
opfcmpp db	6, 'FCOMPP'
opftst	db	4, 'FTST'
opfxam	db	4, 'FXAM'
opfadd	db	4, 'FADD'
opfsub	db	4, 'FSUB'
opfmul	db	4, 'FMUL'
opfdiv	db	4, 'FDIV'
opfsqrt db	5, 'FSQRT'
opfscal db	6, 'FSCALE'
opfrem	db	4, 'FREM'
opfrnd	db	7, 'FRNDINT'
opfxtr	db	7, 'FXTRACT'
opfabs	db	4, 'FABS'
opchs	db	4, 'FCHS'
opfptan db	5, 'FPTAN'
opfpatn db	6, 'FPATAN'
opf2xm1 db	5, 'F2XM1'
opfyl2x db	5, 'FYL2X'
opfyxp1 db	7, 'FYL2XP1'
opfldz	db	4, 'FLDZ'
opfld1	db	4, 'FLD1'
opfldp1 db	5, 'FLDP1'
opfll2t db	6, 'FLDL2T'
opfll2e db	6, 'FLDL2E'
opfllg2 db	6, 'FLDLG2'
opflln2 db	6, 'FLDLN2'
opfinit db	5, 'FINIT'
opfeni	db	4, 'FENI'
opfdisi db	5, 'FDISI'
opfldcw db	5, 'FLDCW'
opfstcw db	5, 'FSTCW'
opfclex db	5, 'FCLEX'
opfsenv db	6, 'FSTENV'
opflenv db	6, 'FLDENV'
opfsave db	5, 'FSAVE'
opfrstr db	6, 'FRSTOR'
opfincs db	6, 'FINCSP'
opfdecs db	6, 'FDECSP'
opffree db	5, 'FFREE'
opfnop	db	4, 'FNOP'
opfwait db	5, 'FWAIT'

	page
op287	label	near
opfspm	db	6, 'FSETPM'


opcsseg db	3, 'CS:'
opdsseg db	3, 'DS:'
opesseg db	3, 'ES:'
opssseg db	3, 'SS:'

opbad	db	3, '???'
opdb	db	2, 'DB'
op	db	0

	page
; modifiers

modbyte db	8, 'BYTE PTR'
modword db	8, 'WORD PTR'
modfar	db	3, 'FAR'

; register operands

rop2	label	byte		; word registers
ropax	db	2, 'AX'
ropcx	db	2, 'CX'
ropdx	db	2, 'DX'
ropbx	db	2, 'BX'
ropsp	db	2, 'SP'
ropbp	db	2, 'BP'
ropsi	db	2, 'SI'
ropdi	db	2, 'DI'

ropsreg label	byte
ropes	db	2, 'ES'
ropcs	db	2, 'CS'
ropss	db	2, 'SS'
ropds	db	2, 'DS'

ropip	db	2, 'IP'
ropf	db	2, 'F '

rop1	label	byte		; byte registers
robal	db	2, 'AL'
robcl	db	2, 'CL'
robdl	db	2, 'DL'
robbl	db	2, 'BL'
robah	db	2, 'AH'
robch	db	2, 'CH'
robdh	db	2, 'DH'
robbh	db	2, 'BH'
	db	0		; terminator

	page
;	OPCODE	INSTRUCTION  TYPES EQUATES

	if	0 eq 0

MEMREG1 equ	8100H		; mem/reg, reg (byte)
MEMREG2 equ	8100H		; mem/reg, reg (word)
REGMEM1 equ	8101H		; reg, mem/reg (byte)
REGMEM2 equ	8101H		; reg, mem/reg (word)
ALKK	equ	0102H		; AL, kk       (byte)
AXJJKK	equ	0203H		; AX, jjkk     (word)
STKREG	equ	0004H		; STACK (REG)  (word)
STKSREG equ	0005H		; STACK (SREG) (word)
SEGOVR	equ	002dH		; SEG:	       treated like a single op
SINGLE	equ	002DH		; Single op
INVALID equ	002DH		; Treated like a single op
ADRCOND equ	010AH		; Conditional Jump
ADRNEAR equ	020BH		; Near Address Reference (JMP, CALL)
ADRFAR	equ	040CH		; Far Address Reference
ADRSHOR equ	010AH		; Short Address Reference
REGADR2 equ	040DH		; register far address
MREG1	equ	810EH		; mem/reg      (byte)
MREG2	equ	810FH		; mem/reg      (word)
MRGKK	equ	8211H		; mem/reg, kk	(byte)
MRGJJKK equ	8312H		; mem/reg, jjkk (word)
REGOP1	equ	0010H		; register operation (byte)
REGOP2	equ	0013H		; register operation (word)
REGADR	equ	8114H		; register address
MEMSREG equ	8115H		; mem/reg, segreg
SREGMEM equ	8116H		; segreg, mem/reg
REGREG1 equ	0017H		; AL, reg (byte)
ALADDR	equ	0218H		; al, addr
AXADDR	equ	0219H		; ax, addr
ADDRAL	equ	021AH		; addr, al
ADDRAX	equ	021BH		; addr, ax
IMDREG1 equ	011CH		; immed reg (byte)
IMDREG2 equ	021DH		; immed reg (word)
INT3	equ	001EH		; interupt 3
INTX	equ	011FH		; interupts
DOUBLE	equ	0120H		; double op codes
ALIPORT equ	0121H		; in al, kk
AXIPORT equ	0122H		; in ax, kk
ALOPORT equ	0123H		; out kk, al
AXOPORT equ	0124H		; out kk, ax
ALIFIX	equ	0025H		; in al, dx
AXIFIX	equ	0026H		; in ax, dx
ALOFIX	equ	0027H		; out dx, al
AXOFIX	equ	0028H		; out dx, ax
OP8087	equ	0129H		; 8087/80287 Opcodes
REGREG2 equ	002AH		; AX, reg  (word)
ADDR16	equ	0206H		; address 16 bit
SHF1	equ	8108H		; Shift mem/reg, 1
SHFCL	equ	8109H		; Shift mem/reg, CL
DEFBYTE equ	002BH		; DB XX
MEMFAR	equ	810fH		; FAR mem/reg

	endif

	page
	even
opptr	label	word
	dw	MEMREG1		; 00   ADD mem/reg,reg (byte)
	dw	offset opadd
	dw	MEMREG2		; 01   ADD mem/reg,reg (word)
	dw	offset opadd
	dw	REGMEM1		; 02   ADD reg,mem/reg (byte)
	dw	offset opadd
	dw	REGMEM2		; 03   ADD reg,mem/reg (word)
	dw	offset opadd
	dw	ALKK		; 04   ADD AL,kk
	dw	offset opadd
	dw	AXJJKK		; 05   ADD AX,jjkk
	dw	offset opadd
	dw	STKSREG		; 06   PUSH ES
	dw	offset oppush
	dw	STKSREG		; 07   POP ES
	dw	offset oppop
	dw	MEMREG1		; 08   OR  mem/reg,reg (byte)
	dw	offset opor
	dw	MEMREG2		; 09   OR  mem/reg,reg (word)
	dw	offset opor
	dw	REGMEM1		; 0A   OR  reg,mem/reg (byte)
	dw	offset opor
	dw	REGMEM2		; 0B   OR  reg,mem/reg (word)
	dw	offset opor
	dw	ALKK		; 0C   OR  AL,kk
	dw	offset opor
	dw	AXJJKK		; 0D   OR  AX,jjkk
	dw	offset opor
	dw	STKSREG		; 0E   PUSH CS
	dw	offset oppush
	dw	DEFBYTE		; 0F   Invalid
	dw	offset opdb
	page
	dw	MEMREG1		; 10   ADC mem/reg,reg (byte)
	dw	offset opadc
	dw	MEMREG2		; 11   ADC mem/reg,reg (word)
	dw	offset opadc
	dw	REGMEM1		; 12   ADC reg,mem/reg (byte)
	dw	offset opadc
	dw	REGMEM2		; 13   ADC reg,mem/reg (word)
	dw	offset opadc
	dw	ALKK		; 14   ADC AL,kk
	dw	offset opadc
	dw	AXJJKK		; 15   ADC AX,jjkk
	dw	offset opadc
	dw	STKSREG		; 16   PUSH SS
	dw	offset oppush
	dw	STKSREG		; 17   POP SS
	dw	offset oppop
	dw	MEMREG1		; 18   SBB mem/reg,reg (byte)
	dw	offset opsbb
	dw	MEMREG2		; 19   SBB mem/reg,reg (word)
	dw	offset opsbb
	dw	REGMEM1		; 1A   SBB reg,mem/reg (byte)
	dw	offset opsbb
	dw	REGMEM2		; 1B   SBB reg,mem/reg (word)
	dw	offset opsbb
	dw	ALKK		; 1C   SBB AL,kk
	dw	offset opsbb
	dw	AXJJKK		; 1D   SBB AX,jjkk
	dw	offset opsbb
	dw	STKSREG		; 1E   PUSH DS
	dw	offset oppush
	dw	STKSREG		; 1F   POP DS
	dw	offset oppop
	page
	dw	MEMREG1		; 20   AND mem/reg,reg (byte)
	dw	offset opand
	dw	MEMREG2		; 21   AND mem/reg,reg (word)
	dw	offset opand
	dw	REGMEM1		; 22   AND reg,mem/reg (byte)
	dw	offset opand
	dw	REGMEM2		; 23   AND reg,mem/reg (word)
	dw	offset opand
	dw	ALKK		; 24   AND AL,kk
	dw	offset opand
	dw	AXJJKK		; 25   AND AX,jjkk
	dw	offset opand
	dw	SEGOVR		; 26   ES:
	dw	offset opesseg
	dw	SINGLE		; 27   DAA
	dw	offset opdaa
	dw	MEMREG1		; 28   SUB mem/reg,reg (byte)
	dw	offset opsub
	dw	MEMREG2		; 29   SUB mem/reg,reg (word)
	dw	offset opsub
	dw	REGMEM1		; 2A   SUB reg,mem/reg (byte)
	dw	offset opsub
	dw	REGMEM2		; 2B   SUB reg,mem/reg (word)
	dw	offset opsub
	dw	ALKK		; 2C   SUB AL,kk
	dw	offset opsub
	dw	AXJJKK		; 2D   SUB AX,jjkk
	dw	offset opsub
	dw	SEGOVR		; 2E   CS:
	dw	offset opcsseg
	dw	SINGLE		; 2F   DAS
	dw	offset opdas
	page
	dw	MEMREG1		; 30   XOR mem/reg,reg (byte)
	dw	offset opxor
	dw	MEMREG2		; 31   XOR mem/reg,reg (word)
	dw	offset opxor
	dw	REGMEM1		; 32   XOR reg,mem/reg (byte)
	dw	offset opxor
	dw	REGMEM2		; 33   XOR reg,mem/reg (word)
	dw	offset opxor
	dw	ALKK		; 34   XOR AL,kk
	dw	offset opxor
	dw	AXJJKK		; 35   XOR AX,jjkk
	dw	offset opxor
	dw	SEGOVR		; 36   SS:
	dw	offset opssseg
	dw	SINGLE		; 37   AAA
	dw	offset opaaa
	dw	REGMEM1		; 38   CMP reg,mem/reg (byte)
	dw	offset opcmp
	dw	REGMEM2		; 39   CMP reg,mem/reg (word)
	dw	offset opcmp
	dw	MEMREG1		; 3A   CMP mem/reg,reg (byte)
	dw	offset opcmp
	dw	MEMREG2		; 3B   CMP mem/reg,reg (word)
	dw	offset opcmp
	dw	ALKK		; 3C   CMP AL,kk
	dw	offset opcmp
	dw	AXJJKK		; 3D   CMP AX,jjkk
	dw	offset opcmp
	dw	SEGOVR		; 3E   DS:
	dw	offset opdsseg
	dw	SINGLE		; 3F   AAS
	dw	offset opaas
	page
	dw	REGOP2		; 40   INC AX
	dw	offset opinc
	dw	REGOP2		; 41   INC CX
	dw	offset opinc
	dw	REGOP2		; 42   INC DX
	dw	offset opinc
	dw	REGOP2		; 43   INC BX
	dw	offset opinc
	dw	REGOP2		; 44   INC SP
	dw	offset opinc
	dw	REGOP2		; 45   INC BP
	dw	offset opinc
	dw	REGOP2		; 46   INC SI
	dw	offset opinc
	dw	REGOP2		; 47   INC DI
	dw	offset opinc
	dw	REGOP2		; 48   DEC AX
	dw	offset opdec
	dw	REGOP2		; 49   DEC CX
	dw	offset opdec
	dw	REGOP2		; 4A   DEC DX
	dw	offset opdec
	dw	REGOP2		; 4B   DEC BX
	dw	offset opdec
	dw	REGOP2		; 4C   DEC SP
	dw	offset opdec
	dw	REGOP2		; 4D   DEC BP
	dw	offset opdec
	dw	REGOP2		; 4E   DEC SI
	dw	offset opdec
	dw	REGOP2		; 4F   DEC DI
	dw	offset opdec
	page
	dw	STKREG		; 50   PUSH AX
	dw	offset oppush
	dw	STKREG		; 51   PUSH CX
	dw	offset oppush
	dw	STKREG		; 52   PUSH DX
	dw	offset oppush
	dw	STKREG		; 53   PUSH BX
	dw	offset oppush
	dw	STKREG		; 54   PUSH SP
	dw	offset oppush
	dw	STKREG		; 55   PUSH BP
	dw	offset oppush
	dw	STKREG		; 56   PUSH SI
	dw	offset oppush
	dw	STKREG		; 57   PUSH DI
	dw	offset oppush
	dw	STKREG		; 58   POP AX
	dw	offset oppop
	dw	STKREG		; 59   POP CX
	dw	offset oppop
	dw	STKREG		; 5A   POP DX
	dw	offset oppop
	dw	STKREG		; 5B   POP BX
	dw	offset oppop
	dw	STKREG		; 5C   POP SP
	dw	offset oppop
	dw	STKREG		; 5D   POP BP
	dw	offset oppop
	dw	STKREG		; 5E   POP SI
	dw	offset oppop
	dw	STKREG		; 5F   POP DI
	dw	offset oppop
	page
	dw	DEFBYTE		; 60   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 61   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 62   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 63   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 64   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 65   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 66   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 67   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 68   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 69   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 6A   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 6B   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 6C   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 6D   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 6E   INVALID
	dw	offset opdb
	dw	DEFBYTE		; 6F   INVALID
	dw	offset opdb
	page
	dw	ADRCOND		; 70   JO
	dw	offset opjo
	dw	ADRCOND		; 71   JNO
	dw	offset opjno
	dw	ADRCOND		; 72   JC or (JB or JNAE)
	dw	offset opjc
	dw	ADRCOND		; 73   JNC or (JNB or JAE)
	dw	offset opjnc
	dw	ADRCOND		; 74   JZ or (JE)
	dw	offset opjz
	dw	ADRCOND		; 75   JNZ or (JNE)
	dw	offset opjnz
	dw	ADRCOND		; 76   JNA or (JBE)
	dw	offset opjna
	dw	ADRCOND		; 77   JA or (JNBE)
	dw	offset opja
	dw	ADRCOND		; 78   JS
	dw	offset opjs
	dw	ADRCOND		; 79   JNS
	dw	offset opjns
	dw	ADRCOND		; 7A   JPE or (JP)
	dw	offset opjpe
	dw	ADRCOND		; 7B   JPO or (JNP)
	dw	offset opjpo
	dw	ADRCOND		; 7C   JL or (JNGE)
	dw	offset opjl
	dw	ADRCOND		; 7D   JGE or (JNL)
	dw	offset opjge
	dw	ADRCOND		; 7E   JLE or (JNG)
	dw	offset opjle
	dw	ADRCOND		; 7F   JG or (JNLE)
	dw	offset opjg
	page
	dw	0		; 80   Misc
	dw	offset op
	dw	0		; 81   Misc
	dw	offset op
	dw	0		; 82
	dw	offset op
	dw	0		; 83
	dw	offset op
	dw	REGMEM1		; 84   TEST reg,mem/reg (byte)
	dw	offset optest
	dw	REGMEM2		; 85   TEST reg,mem/reg (word)
	dw	offset optest
	dw	REGMEM1		; 86   XCHG reg,mem/reg (byte)
	dw	offset opxchg
	dw	REGMEM2		; 87   XCHG reg,mem/reg (word)
	dw	offset opxchg
	dw	MEMREG1		; 88   MOV  mem/reg,reg (byte)
	dw	offset opmov
	dw	MEMREG2		; 89   MOV  mem/reg,reg (word)
	dw	offset opmov
	dw	REGMEM1		; 8A   MOV  reg,mem/reg (byte)
	dw	offset opmov
	dw	REGMEM2		; 8B   MOV  reg,mem/reg (word)
	dw	offset opmov
	dw	MEMSREG		; 8C   MOV  mem/reg,segreg
	dw	offset opmov
	dw	REGADR		; 8D   LEA  reg,addr
	dw	offset oplea
	dw	SREGMEM		; 8E   MOV  segreg,mem/reg
	dw	offset opmov
	dw	MREG2		; 8F   POP  mem/reg
	dw	offset oppop
	page
	dw	SINGLE		; 90   NOP
	dw	offset opnop
	dw	REGREG2		; 91   XCHG AX,CX
	dw	offset opxchg
	dw	REGREG2		; 92   XCHG AX,DX
	dw	offset opxchg
	dw	REGREG2		; 93   XCHG AX,BX
	dw	offset opxchg
	dw	REGREG2		; 94   XCHG AX,SP
	dw	offset opxchg
	dw	REGREG2		; 95   XCHG AX,BP
	dw	offset opxchg
	dw	REGREG2		; 96   XCHG AX,SI
	dw	offset opxchg
	dw	REGREG2		; 97   XCHG AX,DI
	dw	offset opxchg
	dw	SINGLE		; 98   CBW
	dw	offset opcbw
	dw	SINGLE		; 99   CWD
	dw	offset opcwd
	dw	ADRFAR		; 9A   CALL FAR
	dw	offset opcall
	dw	SINGLE		; 9B   WAIT
	dw	offset opwait
	dw	SINGLE		; 9C   PUSHF
	dw	offset oppushf
	dw	SINGLE		; 9D   POPF
	dw	offset oppopf
	dw	SINGLE		; 9E   SAHF
	dw	offset opsahf
	dw	SINGLE		; 9F   LAHF
	dw	offset oplahf
	page
	dw	ALADDR		; A0   MOV  AL,addr
	dw	offset opmov
	dw	AXADDR		; A1   MOV  AX,addr
	dw	offset opmov
	dw	ADDRAL		; A2   MOV  addr,AL
	dw	offset opmov
	dw	ADDRAX		; A3   MOV  addr,AX
	dw	offset opmov
	dw	SINGLE		; A4   MOVSB
	dw	offset opmovsb
	dw	SINGLE		; A5   MOVSW
	dw	offset opmovsw
	dw	SINGLE		; A6   CMPSB
	dw	offset opcmpsb
	dw	SINGLE		; A7   CMPSW
	dw	offset opcmpsw
	dw	ALKK		; A8   TEST AL,kk
	dw	offset optest
	dw	AXJJKK		; A9   TEST AX,jjkk
	dw	offset optest
	dw	SINGLE		; AA   STOSB
	dw	offset opstosb
	dw	SINGLE		; AB   STOSW
	dw	offset opstosw
	dw	SINGLE		; AC   LODSB
	dw	offset oplodsb
	dw	SINGLE		; AD   LODSW
	dw	offset oplodsw
	dw	SINGLE		; AE   SCASB
	dw	offset opscasb
	dw	SINGLE		; AF   SCASW
	dw	offset opscasw
	page
	dw	IMDREG1		; B0   MOV  AL,kk
	dw	offset opmov
	dw	IMDREG1		; B1   MOV  CL,kk
	dw	offset opmov
	dw	IMDREG1		; B2   MOV  DL,kk
	dw	offset opmov
	dw	IMDREG1		; B3   MOV  BL,kk
	dw	offset opmov
	dw	IMDREG1		; B4   MOV  AH,kk
	dw	offset opmov
	dw	IMDREG1		; B5   MOV  CH,kk
	dw	offset opmov
	dw	IMDREG1		; B6   MOV  DH,kk
	dw	offset opmov
	dw	IMDREG1		; B7   MOV  BH,kk
	dw	offset opmov
	dw	IMDREG2		; B8   MOV  AX,jjkk
	dw	offset opmov
	dw	IMDREG2		; B9   MOV  CX,jjkk
	dw	offset opmov
	dw	IMDREG2		; BA   MOV  DX,jjkk
	dw	offset opmov
	dw	IMDREG2		; BB   MOV  BX,jjkk
	dw	offset opmov
	dw	IMDREG2		; BC   MOV  SP,jjkk
	dw	offset opmov
	dw	IMDREG2		; BD   MOV  BP,jjkk
	dw	offset opmov
	dw	IMDREG2		; BE   MOV  SI,jjkk
	dw	offset opmov
	dw	IMDREG2		; BF   MOV  DI,jjkk
	dw	offset opmov
	page
	dw	DEFBYTE		; C0   INVALID
	dw	offset opdb
	dw	DEFBYTE		; C1   INVALID
	dw	offset opdb
	dw	ADDR16		; C2   RET   jjkk
	dw	offset opret
	dw	SINGLE		; C3   RET
	dw	offset opret
	dw	REGADR		; C4   LES  reg,addr
	dw	offset oples
	dw	REGADR		; C5   LDS  reg,addr
	dw	offset oplds
	dw	MRGKK		; C6   MOV  mem/reg,kk
	dw	offset opmov
	dw	MRGJJKK		; C7   MOV  mem/reg,jjkk
	dw	offset opmov
	dw	DEFBYTE		; C8   INVALID
	dw	offset opdb
	dw	DEFBYTE		; C9   INVALID
	dw	offset opdb
	dw	ADDR16		; CA   RETF jjkk
	dw	offset opretf
	dw	SINGLE		; CB   RETF
	dw	offset opretf
	dw	INT3		; CC   INT  3
	dw	offset opint
	dw	INTX		; CD   INT
	dw	offset opint
	dw	SINGLE		; CE   INTO
	dw	offset opinto
	dw	SINGLE		; CF   IRET
	dw	offset opiret
	page
	dw	SHF1		; D0   Shift\Rotate
	dw	offset op
	dw	SHF1		; D1   Shift\Rotate
	dw	offset op
	dw	SHFCL		; D2   Shift\Rotate
	dw	offset op
	dw	SHFCL		; D3   Shift\Rotate
	dw	offset op
	dw	DOUBLE		; D4   AAM
	dw	offset opaam
	dw	DOUBLE		; D5   AAD
	dw	offset opaad
	dw	DEFBYTE		; D6   INVALID
	dw	offset opdb
	dw	SINGLE		; D7   XLAT
	dw	offset opxlat
	dw	OP8087		; D8   ESC mem/reg  \
	dw	offset opesc
	dw	OP8087		; D9   ESC mem/reg   \
	dw	offset opesc
	dw	OP8087		; DA   ESC mem/reg     \
	dw	offset opesc
	dw	OP8087		; DB   ESC mem/reg	 \
	dw	offset opesc
	dw	OP8087		; DC   ESC mem/reg	 /    8087 Ins Set
	dw	offset opesc
	dw	OP8087		; DD   ESC mem/reg	/
	dw	offset opesc
	dw	OP8087		; DE   ESC mem/reg    /
	dw	offset opesc
	dw	OP8087		; DF   ESC mem/reg   /
	dw	offset opesc
	page
	dw	ADRSHOR		; E0   LOOPNZ disp
	dw	offset oplnz
	dw	ADRSHOR		; E1   LOOPZ  disp
	dw	offset oplz
	dw	ADRSHOR		; E2   LOOP   disp
	dw	offset oploop
	dw	ADRSHOR		; E3   JCXZ   disp
	dw	offset opjcxz
	dw	ALIPORT		; E4   IN   AL,kk
	dw	offset opin
	dw	AXIPORT		; E5   IN   AX,kk
	dw	offset opin
	dw	ALOPORT		; E6   OUT  kk,AL
	dw	offset opout
	dw	AXOPORT		; E7   OUT  kk,AX
	dw	offset opout
	dw	ADRNEAR		; E8   CALL NEAR
	dw	offset opcall
	dw	ADRNEAR		; E9   JMP  NEAR
	dw	offset opjmp
	dw	ADRFAR		; EA   JMP  FAR
	dw	offset opjmp
	dw	ADRSHOR		; EB   JMP  SHORT
	dw	offset opjmp
	dw	ALIFIX		; EC   IN   AL,DX
	dw	offset opin
	dw	AXIFIX		; ED   IN   AX,DX
	dw	offset opin
	dw	ALOFIX		; EE   OUT  DX,AL
	dw	offset opout
	dw	AXOFIX		; EF   OUT  DX,AX
	dw	offset opout
	page
	dw	SINGLE		; F0   LOCK
	dw	offset oplock
	dw	DEFBYTE		; F1   INVALID
	dw	offset opdb
	dw	SINGLE		; F2   REPNZ
	dw	offset oprepnz
	dw	SINGLE		; F3   REP
	dw	offset oprep
	dw	SINGLE		; F4   HLT
	dw	offset ophlt
	dw	SINGLE		; F5   CMC
	dw	offset opcmc
	dw	0		; F6
	dw	offset op
	dw	0		; F7
	dw	offset op
	dw	SINGLE		; F8   CLC
	dw	offset opclc
	dw	SINGLE		; F9   STC
	dw	offset opstc
	dw	SINGLE		; FA   CLI
	dw	offset opcli
	dw	SINGLE		; FB   STI
	dw	offset opsti
	dw	SINGLE		; FC   CLD
	dw	offset opcld
	dw	SINGLE		; FD   STD
	dw	offset opstd
	dw	0		; FE
	dw	offset op
	dw	0		; FF
	dw	offset op

	page
op80	label	word
	dw	MRGKK		; 0100 ADD mem/reg,kk (byte or word)
	dw	offset opadd
	dw	MRGKK		; 0101 OR  mem/reg,kk (byte or word)
	dw	offset opor
	dw	MRGKK		; 0102 ADC mem/reg,kk (byte or word)
	dw	offset opadc
	dw	MRGKK		; 0103 SBB mem/reg,kk (byte or word)
	dw	offset opsbb
	dw	MRGKK		; 0104 AND mem/reg,kk (byte or word)
	dw	offset opand
	dw	MRGKK		; 0105 SUB mem/reg,kk (byte or word)
	dw	offset opsub
	dw	MRGKK		; 0106 XOR mem/reg,kk (byte or word)
	dw	offset opxor	
	dw	MRGKK		; 0107 CMP mem/reg,kk (byte or word)
	dw	offset opcmp

op81	label	word
	dw	MRGJJKK		; 0108 ADD mem/reg,jjkk (byte or word)
	dw	offset opadd
	dw	MRGJJKK		; 0109 OR  mem/reg,jjkk (byte or word)
	dw	offset opor
	dw	MRGJJKK		; 010A ADC mem/reg,jjkk (byte or word)
	dw	offset opadc
	dw	MRGJJKK		; 010B SBB mem/reg,jjkk (byte or word)
	dw	offset opsbb
	dw	MRGJJKK		; 010C AND mem/reg,jjkk (byte or word)
	dw	offset opand
	dw	MRGJJKK		; 010D SUB mem/reg,jjkk (byte or word)
	dw	offset opsub
	dw	MRGJJKK		; 010E XOR mem/reg,jjkk (byte or word)
	dw	offset opxor
	dw	MRGJJKK		; 010F CMP mem/reg,jjkk (byte or word)
	dw	offset opcmp

	page
op8283	label	word
	dw	MRGKK		; 0110 ADD mem/reg,kk (byte or word)
	dw	offset opadd
	dw	MRGKK		; 0111 OR  mem/reg,kk (byte or word)
	dw	offset opor
	dw	MRGKK		; 0112 ADC mem/reg,kk (byte or word)
	dw	offset opadc
	dw	MRGKK		; 0113 SBB mem/reg,kk (byte or word)
	dw	offset opsbb
	dw	MRGKK		; 0114 AND mem/reg,kk (byte or word)
	dw	offset opand
	dw	MRGKK		; 0115 SUB mem/reg,kk (byte or word)
	dw	offset opsub
	dw	DEFBYTE		; 0116 INVALID
	dw	offset opdb
	dw	MRGKK		; 0117 CMP mem/reg,kk (byte or word)
	dw	offset opcmp

	page
opd0d1	label	word
	dw	SHF1		; 0118 ROL mem/reg, 1
	dw	offset oprol
	dw	SHF1		; 0119 ROR mem/reg, 1
	dw	offset opror
	dw	SHF1		; 011A RCL mem/reg, 1
	dw	offset oprcl
	dw	SHF1		; 011B RCR mem/reg, 1
	dw	offset oprcr
	dw	SHF1		; 011C SHL mem/reg, 1
	dw	offset opshl
	dw	SHF1		; 011D SHR mem/reg, 1
	dw	offset opshr
	dw	DEFBYTE		; 011E INVALID
	dw	offset opdb
	dw	SHF1		; 011F SAR mem/reg, 1
	dw	offset opsar

opd2d3	label	word
	dw	SHFCL		; 0120 ROL mem/reg, CL
	dw	offset oprol
	dw	SHFCL		; 0121 ROR mem/reg, CL
	dw	offset opror
	dw	SHFCL		; 0122 RCL mem/reg, CL
	dw	offset oprcl
	dw	SHFCL		; 0123 RCR mem/reg, CL
	dw	offset oprcr
	dw	SHFCL		; 0124 SHL mem/reg, CL
	dw	offset opshl
	dw	SHFCL		; 0125 SHR mem/reg, CL
	dw	offset opshr
	dw	DEFBYTE		; 0126 INVALID
	dw	offset opdb
	dw	SHFCL		; 0127 SAR mem/reg, CL
	dw	offset opsar

	page
opf6	label	word
	dw	MRGKK		; 0128 TEST mem/reg,kk (byte)
	dw	offset optest
	dw	DEFBYTE		; 0129 INVALID
	dw	offset opdb
	dw	MREG1		; 012A NOT  mem/reg (byte)
	dw	offset opnot
	dw	MREG1		; 012B NEG  mem/reg (byte)
	dw	offset opneg
	dw	MREG1		; 012C MUL  mem/reg (byte)
	dw	offset opmul
	dw	MREG1		; 012D IMUL mem/reg (byte)
	dw	offset opimul
	dw	MREG1		; 012E DIV  mem/reg (byte)
	dw	offset opdiv
	dw	MREG1		; 012F IDIV mem/reg (byte)
	dw	offset opidiv

	page
opf7	label	word
	dw	MRGJJKK		; 0130 TEST mem/reg,jjkk (word)
	dw	offset optest
	dw	DEFBYTE		; 0131 INVALID
	dw	offset opdb
	dw	MREG2		; 0132 NOT  mem/reg (word)
	dw	offset opnot
	dw	MREG2		; 0133 NEG  mem/reg (word)
	dw	offset opneg
	dw	MREG2		; 0134 MUL  mem/reg (word)
	dw	offset opmul
	dw	MREG2		; 0135 IMUL mem/reg (word)
	dw	offset opimul
	dw	MREG2		; 0136 DIV  mem/reg (word)
	dw	offset opdiv
	dw	MREG2		; 0137 IDIV mem/reg (word)
	dw	offset opidiv

opfe	label	word
	dw	MREG1		; 0138 INC  mem/reg (byte)
	dw	offset opinc
	dw	MREG1		; 0139 DEC  mem/reg (byte)
	dw	offset opdec
	dw	DEFBYTE		; 013A INVALID
	dw	offset opdb
	dw	DEFBYTE		; 013B INVALID
	dw	offset opdb
	dw	DEFBYTE		; 013C INVALID
	dw	offset opdb
	dw	DEFBYTE		; 013D INVALID
	dw	offset opdb
	dw	DEFBYTE		; 013E INVALID
	dw	offset opdb
	dw	DEFBYTE		; 013F INVALID
	dw	offset opdb

	page
opff	label	word
	dw	MREG2		; 0140 INC  mem/reg (word)
	dw	offset opinc
	dw	MREG2		; 0141 DEC  mem/reg (word)
	dw	offset opdec
	dw	MREG2		; 0142 CALL mem/reg (Near Indirect)
	dw	offset opcall
	dw	MEMFAR		; 0143 CALL FAR mem (Far  Indirect)
	dw	offset opcall
	dw	MREG2		; 0144 JMP  mem/reg (Near Indirect)
	dw	offset opjmp
	dw	MEMFAR		; 0145 JMP  FAR mem (Far  Indirect)
	dw	offset opjmp
	dw	MREG2		; 0146 PUSH mem
	dw	offset oppush
	dw	DEFBYTE		; 0147 INVALID
	dw	offset opdb

opnono	label	word
	dw	0FFFFH		; Marks end of Opcode Tabels
	dw	0FFFFH		; Use in Asm Searches
	dw	0ffffh

	page
helptab label	byte		;     for Martin!	
	db	'Assembler Command   $' ;@@XLAT
	db	'Compare Command     $' ;@@XLAT
	db	'Dump Command        $' ;@@XLAT
	db	'Enter Command       $' ;@@XLAT
	db	'Fill Command        $' ;@@XLAT
	db	'Go Command          $' ;@@XLAT
	db	'Hex Command         $' ;@@XLAT
	db	'Input Command       $' ;@@XLAT
	db	'Load Command        $' ;@@XLAT
	db	'Move Command        $' ;@@XLAT
	db	'Name Command        $' ;@@XLAT
	db	'Output Command      $' ;@@XLAT
	page
	db	'Proceed Command     $' ;@@XLAT
	db	'Quit Command        $' ;@@XLAT
	db	'Register Command    $' ;@@XLAT
	db	'Search Command      $' ;@@XLAT
	db	'Trace Command       $' ;@@XLAT
	db	'Unassemble Command  $' ;@@XLAT
	db	'Write Command       $' ;@@XLAT
	db	'Assemble-Unassemble $' ;@@XLAT
	db	'Break Point Set     $' ;@@XLAT
	db	'Break Point Clear   $' ;@@XLAT
	db	'Break Point Disable $' ;@@XLAT
	db	'Break Point Enable  $' ;@@XLAT
	page
	db	'Break Point List    $' ;@@XLAT
	db	'Verify Command      $' ;@@XLAT
	db	'Coprocessor Register$' ;@@XLAT
	db	'Swap Screen Output  $' ;@@XLAT
	db	'Shell To MOS        $' ;@@XLAT
	db	'Online Help Command $' ;@@XLAT
	db	'Debug Configuration $' ;@@XLAT
	db	'External Console    $' ;@@XLAT
	db	'Pause for key       $' ;@@XLAT
	db	'Delay               $' ;@@XLAT
	db	'Comment             $' ;@@XLAT
	db	'Comment             $' ;@@XLAT
	db      '                    $'
	db	'                    $'

helplen equ	($-helptab)/21


	page
	if	0 eq 0

RAX	equ	    10h
RCX	equ	    20h
RDX	equ	    30h
RBX	equ	    40h
RSP	equ	    50h
RBP	equ	    60h
RSI	equ	    70h
RDI	equ	    80h
RES	equ	    0A0h
RCS	equ	    0B0H
RSS	equ	    0C0H
RDS	equ	    0D0H
RAL	equ	    01h
RDL	equ	    03h
RBL	equ	    04h
RAH	equ	    05h
RCH	equ	    06h
RDH	equ	    07h
RBH	equ	    08h

	page
FILE1	equ	005CH
FILE2	equ	006CH
LINELEN equ	0080H
LINEBEG equ	0081H
SCREEN	equ	0FFFFH
SCRSIZE equ	4096		; Screen Size (Assume to be multible of 16)
XOFF	equ	13H
STKSIZE equ    8192		; Stack Size (Assume to be multoble of 16)
STDIN	equ	0
STDOUT	equ	1

	endif

hextab	db	'0123456789ABCDEF'


cpu	db	0		; default cpu is 8086
mcpu	db	0		; indicates if math coprocessor is available
notdone db	1		; indicates if still functioning
retcode db	0		; retcode to exit with	
bpflag	db	1		; indicates if breakpoints are enable
stpflag db	0		; indicates if single step mode is in effect
goflag	db	0		; indicates if program execution is in effect
nfile	db	0		; indicates if file as been named or loaded
brk	db	0		; indicates if break int2 or int3 executed
quitprg db	0		; indicated if quit is done
usrterm db	0		; indicates if user terminated
bflag	db	0		; indicates if cntrl-c enter
redout	db	0		; indicates if redirected output
redin	db	0		; indicates if redirected input 
maincon db	1		; indicates if using main console
isload	db	0		; indicates if program been loaded
segflag db	0		; indicates if default segments changed 
exeflag db	0
AllMem	db	0		; indicates if memory allocated or not

	page
	even
map1718 label	word		; fd17 map table for assembly
	dw	0404h		; reg8	<- reg8
	dw	0480h		; reg8	<- mem8
	dw	8004h		; mem8	<- reg8 
	dw	0808h		; reg16 <- reg16
	dw	0880h		; reg16 <- mem16
	dw	8008h		; mem16 <- reg16
	dw	0100h		; al	<- xx
	dw	0200h		; ax	<- xxyy
	dw	0400h		; reg8	<- xx
	dw     0a000h		; mem8	<- xx
	dw	0800h		; reg16 <- xxyy (or xx if fd17)
	dw     0c000h		; mem16 <- xxyy (or xx if fd17)
	dw	   0

map10	label	word		; fd10 map table for assemble
	dw	0180h		; al	<- mem8
	dw	0280h		; ax	<- mem16

map10a	label	word		; fd10 map (rest and start of second try)
	dw	8010h		; mem16 <- sreg
	dw	0810h		; reg16 <- sreg
	dw	1080h		; sreg	<- mem16
	dw	1008h		; sreg	<- reg16
	dw	0404h		; reg8	<- reg8
	dw	0480h		; reg8	<- mem8
	dw	8004h		; mem8	<- reg8 
	dw	0808h		; reg16 <- reg16
	dw	0880h		; reg16 <- mem16
	dw	8008h		; mem16 <- reg16
	dw	0400h		; reg8	<- xx	   (assumed to be immed to reg)
	dw     0a000h		; mem8	<- xx
	dw	0800h		; reg16 <- xxyy	   (assumed to be immed to reg)
	dw     0c000h		; mem16 <- xxyy
	dw	   0
	page

SaveOff dw	0

rmtab	label	byte
	db	06h		; bx + si + disp
	db	0ah		; bx + di + disp
	db	05h		; bp + si + disp
	db	09h		; bp + di + disp
	db	04h		; si + disp
	db	08h		; di + disp
	db	01h		; bp + disp
	db	02h		; bx + disp
	db	00h		; disp only
	
	page
;	Messages follow here

chip	db     'Microprocessor Chip on System is an 80$' ;@@XLAT

nomath	db     'No '
mchip	db     'Math Coprocessor exists on this System.    ',13,10,'$' ;@@XLAT

syntax	db     '^ Above Line contains a Syntax Error    ', 13,10,'$' ;@@XLAT
crlf2	db     13, 10
crlf	db     13, 10, '$'

regmsg	db     ' AX   BX   CX   DX   SI   DI   BP  '
	db     ' DS   ES   SS   SP   '
flagmsg db     'ODISZAPC',13,10,'$'

r87msg	db	'Control=nnnn  Status=nnnn  Tag=nnnn  ' ;@@XLAT
	db	'Instruction=nnnn:nnnn  Data=nnnn:nnnn',13,10 ;@@XLAT
	db	' Reg   Sign  Exponent  Significant    ',13,10 ;@@XLAT
	db	'-----------------------------------'
	db	'--------------------------------',13,10,'$'
r87msg1 db	' Rx      n      nnnn    nnnn nnnn  '
	db	'nnnn nnnn  nnnn nnnn  nnnn nnnn',13,10,'$'


bsetmsg db     'Breakpoint n set to nnnn:nnnn' ;@@XLAT
bsetend db     '.',13,10,'$'
bclrmsg db     'Breakpoint n cleared     ',13,10,'$' ;@@XLAT
badbp	db     'Invalid breakpoint specified!  ',13,10,'$' ;@@XLAT
badbpad db     'Invalid breakpoint address specified!  ',13,10,'$' ;@@XLAT
badadr	db     'Invalid start execution address specified!       ',13,10,'$' ;@@XLAT
bpfull	db     'Breakpoint table is full!   ',13,10,'$' ;@@XLAT
bpthere db     'Breakpoint is already in table!       ',13,10,'$' ;@@XLAT
bonmsg	db     'Breakpoints are enabled.   ',13,10,'$' ;@@XLAT
boffmsg db     'Breakpoints are disabled.    ',13,10,'$' ;@@XLAT
shmsg	db     'Shell to PC-MOS, enter EXIT to return to DEBUG.              ',13,10,'$' ;@@XLAT
fnfmsg	db     'Cannot find file$        ' ;@@XLAT
nommsg	db     'Insufficent memory to perform function$  ' ;@@XLAT
rdmsg	db     'Error reading program into memory$                ' ;@@XLAT
notall	db     'Program not completely loaded into memory$             ' ;@@XLAT
badreg	db     'Invalid register specified   ',13,10,'$' ;@@XLAT
badflag db     'Invalid flag map dpecified',13,10,'$' ;@@XLAT
ptn	db     'Program completed execution.       ',13,10,'$' ;@@XLAT
nobrk	db     'No breakpoints set on system.       ',13,10,'$' ;@@XLAT
tmbrk	db     'Too many soft breakpoints entered!',13,10,'$' ;@@XLAT
wperr	db     'Write protect detected on drive $    ' ;@@XLAT
dnrerr	db     'Drive not ready - drive $         ' ;@@XLAT
drv	db     'A:',13,10,'$'
wrbytes db     'Writing  ' ;@@XLAT
wbyte	db     8 dup (' '),'$'
wrname	db     'H bytes of program $ ' ;@@XLAT
noname	db     'No filename specified with NAME command or loaded with' ;@@XLAT
	db     ' LOAD command!                  ',13,10,'$' ;@@XLAT
dbmsg	db     'Debug console port is COM $         ' ;@@XLAT
dbad	db     '1.  ',13,10,'$'
cbadmsg db     'Invalid COM port specified for external console.              ',13,10,'$' ;@@XLAT
badname db     'Invalid file #   ' ;@@XLAT
nbad	db     'n specification for NAME command.',13,10,'$' ;@@XLAT
intern	db     'PC-MOS debugger internal error - $ ' ;@@XLAT
sizeovr db     'Size overflow when writing program.        ',13,10,'$' ;@@XLAT
badop	db     'Opcode reference invalid.    ',13,10,'$' ;@@XLAT
badread db     'Error reading from disk.         ',13,10,'$' ;@@XLAT
badwrit db     'Error writing to disk.               ',13,10,'$' ;@@XLAT

;	buffers

buff	label  byte
funct	label  word
	db     ' '
cmdbuff db     '     '
	db     73 dup (' ')
lenbuff db     0

buffbkp db     10 dup (' BACKUP ') ;@@XLAT
lenbkp	db     0

tempbuf db     '  $'
comspec db     'COMSPEC',0
cpbuff	db     79 dup (0)
cmdout	db     0, 0DH
flagbuf db     8 dup (' '), '$'
space7	db     5  dup (' ')
blank2	db     ' '
blank1	db     ' $'
opbuff	db     79 dup (' '), 13, 10, '$'
dumpbuff db    79 dup (' '), 0
minfo	db     'D 40:0'

getbuff db     80 dup (0)

cdirlen db     0
current db     'A:\'
cdir	db     64 dup (0)
path	db     64 dup (0)
asmarea db     'nnnn:nnnn $'

loadct	db     0
loadbuf db     64 dup (0)

	even
uasmloc dw     0,     0100h
asmloc	dw     0,     0100h
dumploc dw     0,     0100h
envseg	dw     0
wrloc	dw     0100h 
childpsp dw    0
debugpsp dw    0
shrink	 dw    0

sbufseg dw     0		; segment of screen buffer

retaddr label  word
retoff	dw     0		; offset  of return from tracing
retseg	dw     0		; segment of return from tracing
retflag dw     0		; flags	  of return from tracing
retloc	dw     0		; return offset to be sent to terminate

cmdss	dw     0		; command processor (debug) ss
cmdsp	dw     0		; command processor (debug) sp
cmdes	dw     0		; command processor (debug) es

userprg dw     0, 0		; far value for call to user prg
tcount	dw     0		; trace counter for single stepping


parmblk label  word
env	dw     0		; segment of enviroment block
parmlin dw     0,     0		; -> command line
fcb1loc dw     5ch,   0		; -> FCB at 5C in PSP
fcb2loc dw     6ch,   0		; -> FCB at 6C in PSP
stkloc	dw     0,     0		; ss:sp of loaded program
dloc	dw     0100h, 0		; cs:ip of loaded program


dbaddr	dw     SCREEN
dbport	dw     1
scraddr dw     0B800h		; defaults to color
scursor dw     00000h		; home position

valsi	dw     0
valdi	dw     0
valbx	dw     0
sizehi	dw     0		; high value of size during writes
sizelo	dw     0		; low
getsi	dw     0		; value of si during getop 
lastop	dw     0		; last opcode for assembly
seabx	dw     0		; temporary value for bx during scanea
saveip	dw     0		; temporary ip during int simulation

cpparms dw     24 dup (0)
stkptr	dw     0
stkseg	dw     0

;
;	screen modes for out instruction to turn off screen
;
modes	db     02ch, 028h, 02dh, 029h, 02ah, 02eh, 03dh


spage	db     0
vmode	db     0	       ; current mode (one in swap)
smode	db     2	       ; default mode is color
lastval db     0	       ; last character input from com port
rubout	db     8,' ',8,'$'     ; use for rubbing out characters
lasterr db     0	       ; last error

	even
old01	dw	01h, 01h
old02	dw	02h, 02h
old03	dw	03h, 03h
old20	dw	20h, 20h
old22	dw	22h, 22h
old23	dw	23h, 23h
old24	dw	24h, 24h

bptab	dw	BPSOFT+BPHARD dup (0,0)	  ; table for bp address
bpins	db	BPSOFT+BPHARD dup (0)	  ; table for original opcodes at bp's

fcbbuf1 db	16 dup (0)
fcbbuf2 db	16 dup (0)

	page
;	start of main code section

begin:
	mov	ah, 51h
	int	21h
	mov	[debugpsp], bx
	mov	bx, STDOUT
	mov	ax, 4400H
	int	21h
	test	dl, 080h		; redirected output
	jnz	norout
	mov	cs:[redout], 1

norout:
	mov	bx, STDIN
	mov	ax, 4400H
	int	21h
	test	dh, 080h		; redirected input
	jnz	norin
	mov	cs:[redin], 1

norin:
	call	Is8087
	mov	[mcpu], al
	mov	ah, 15
	int	10h
	and	al, 7
	mov	[vmode], al
	cmp	al, 7
	jne	begina
	mov	word ptr [scraddr], 0B000h	; set mono


;	allocate start location for new program

begina:
	lea	ax, endbyte
	add	ax, 15
	mov	cl, 4
	shr	ax, cl
	mov	cx, cs
	add	ax, cx
	mov	[sbufseg], ax
	add	ax, SCRSIZE/16
	call	ClrSBuf		; clear screen buffer
	mov	[stkloc], ax
	mov	word ptr [stkloc+2], 0400h
	add	ax, STKSIZE/16
	inc	ax
	mov	word ptr [regsp], 0FFEEH

amstart:
	clc
	mov	bx, ax
	mov	ax, cs
	sub	bx, ax
	dec	bx
	mov	word ptr [shrink], 100h
	mov	es, ax
	mov	ah, 4ah
	xor	al, al

ambegin:
	int	21h
amend:
;	the following additions are necessary for adjust made with 286 stuff

	push	bx
	push	es
	mov	ax,es
	dec	ax
	mov	es,ax
	mov	bx,es:[3]
	mov	ax,cs
	add	ax,bx
	inc	ax
	pop	es
	pop	bx

        mov     [regcs], ax
        mov     [regds], ax
        mov     [reges], ax
        mov     [childpsp], ax
        mov     [dumploc], ax
        mov     [uasmloc], ax
        mov     [asmloc], ax
        mov     [regss], ax
;
;	make sure value at SS:SP is 00 for next 18 bytes
;
	push	es
	push	di
	push	cx
	mov	es,ax
	mov	di,0ffeeh
	mov	cx,18/2
	xor	ax,ax
	rep	stosw
	pop	cx
	pop	di
	pop	es
;	

;	end of addtions

	dec	bx
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	dec	bx
	dec	bx
	mov	sp, bx

	call	SizeMax

	page
;	save neccessary interupts for program load
	push	bx
	push	es
	mov	ax, 3522h	; save int 22h
	int	21h
	mov	[old22], bx
	mov	ax, es
	mov	[old22+2], ax
	pop	es
	pop	bx

;	get current directory and drive

	mov	ah, 19h
	int	21h		; get current drive
	mov	dl, al
	add	al, 'A'
	mov	byte ptr [current], al
	mov	ah, 47h
	lea	si, cdir
	inc	dl
	int	21h		; get current directory
	xor	bx, bx
	lea	si, cdir

begin1:
	cmp	byte ptr [bx+si], 0
	je	begin2
	cmp	bx, 63
	jae	begin2
	inc	bx
	jmp	short begin1

begin2:
	mov	byte ptr [cdirlen], bl

;	check command line for parameters and load program if so desired


	mov	ah, 3		; get cursor position
	int	10h
	mov	si, 80h
	mov	cl, byte ptr [si]
	inc	si
	push	es
	mov	es, [regcs]
	mov	word ptr es:[0ah], offset Term
	mov	es:[0ch], cs
	mov	word ptr es:[12h], offset Fatal
	mov	es:[14h], cs
	mov	word ptr es:[100h], 20cdh
	pop	es

	page
begin3:
	or	cl, cl
	jz	begin4

;	load program in memory

	push	bx
	push	dx			; save cursor position

begin3a:
	or	cl, cl
	je	begin3c
	lodsb
	cmp	al, ' '
	jne	begin3b
	dec	cl
	jmp	short begin3a

begin3b:
	dec	si			; point si at point - 1
	xor	ch, ch
	mov	bx, cs
	mov	[fcb1loc+2], bx
	mov	[fcb1loc], offset fcbbuf1
	mov	[fcb2loc+2],bx
	mov	[fcb2loc], offset fcbbuf2
	lea	bx, parmblk
	mov	[loadct], cl
	push	cx
	push	si
	push	di
	push	es
	
	push	cs
	pop	es
	lea	di, loadbuf
	rep	movsb
	lea	si, loadbuf
	
initfcb:		; search buffer for first fcb entry
	lodsb
	cmp	al, 0dh
	je	endfcb
	cmp	al, ' '
	jz	endfcb
	or	al, al
	jnz	initfcb

endfcb:
	dec	si
	mov	es, [regcs]
	lea	di, fcbbuf1
	call	MakeFcb
	lea	di, fcbbuf2
	call	MakeFcb

	pop	es
	pop	di
	pop	si
	pop	cx
	call	LoadPrg

begin3c:
	pop	dx			; set old cursor position
	pop	bx
	mov	ah, 2
	int	10h
	
	page
begin4:
	cmp	[isload],0
	jne	begin4a
	mov	ax,[debugpsp]
	mov	[childpsp],ax
begin4a:

;	determine if on main console

	push	es
	cmp	[OnMOS],'Y'
	jne	nottcb
	mov	ah, 04h
	mov	bx, -1
	int	SERVICES
	assume	es:tcb
	cmp	byte ptr es:[bx+TCBTYPE], 'T'
	jne	nottcb
	xor	ax, ax
	cmp	es:[bx+TCBPORT], ax
	jne	isterm
	cmp	word ptr es:[bx+TCBBAUD], ax
	jne	isterm
	cmp	word ptr es:[bx+TCBBAUD+2], ax
	je	nottcb

isterm:
	mov	byte ptr [maincon], 0

nottcb:
	pop	es
	assume	es:moss

;	determine cpu type

	pushf
	xor	ax, ax
	push	ax
	popf			; try to put zero in flags
	pushf
	pop	ax
	and	ax, 0F000H
	xor	bl, bl		; indicate 808X series
	cmp	ax, 0F000H
	je	begin5

	mov	bl, 3		; indicate 80386 series
	mov	ax, 0F000H	; try to but 1's in high bits
	push	ax
	popf
	pushf
	pop	ax
	and	ax, 0F000H
	jne	cpuver

	dec	bl		; indicate 80286 series
	push	sp
	pop	ax
	cmp	ax, sp		; test for prefetch
	je	cpuver
	xor	bl, bl

begin5:
	mov	cx, 33
	mov	al, 0ffh
	shl	al, cl
	jz	cpuver		; must be an 808X series
	mov	bl, 1		; indicate 8018X series


	page
cpuver:
	popf
	cmp	bl,3	
	jne	not386
;
;	now we will test for 486
;
	.386
	mov	edx,esp
	and	esp,not 3
	pushfd
	pop     eax
	mov	ecx,eax
	xor	eax,40000h
	push	eax
	popfd
	pushfd	
	pop	eax
	xor	eax,40000h
	shr	eax,18
	and	eax,1
	push	ecx
	popfd
	mov	esp,edx
	.286
	or	al,al
	jnz	not386
	inc	bl

not386:
	mov	[cpu], bl
 
dbcon1:
	lea	si, comspec
	lea	di, cpbuff
	mov	cx, 7
	call	GetEnv
	call	SwapScr
	cmp	cs:[redout], 1
	je	dotsl
	mov	ah, 15
	int	10h
	cmp	al, 7
	je	dotsl
	mov	ax, 2
	int	10h

dotsl:
	lea	dx, tsl	       ; display copy right
	call	OutMsg
	call	ErrMsg	       ; display error message from load
	cmp	cs:[lasterr], 0
	je	dotsl1
	push	di
	push	es

	mov	es, cs:[regcs]
	mov	di, cs:[regip]
	mov	word ptr es:[di], 20CDH	; insert a INT 20

	pop	es
	pop	di

dotsl1:
	lea	dx, crlf
	call	OutMsg	       ; display cr-lf
	call	Config	       ; display configeration
	lea	dx, crlf
	call	OutMsg
	mov	cx, 14
	push	es
	push	cs
	pop	es
	lea	si, regall
	lea	di, regbak
	rep	movsw
	pop	es
	mov	byte ptr [lenbuff], 0
	call	DumpReg
	mov	[cmdes], es
	cli
	mov	[cmdss], ss
	mov	[cmdsp], sp
	sti
	
	page
repeat:
	call	SetSegs	       ; set defaults if neccessary	
	mov	dl, ']'	       ; display -
	call	OutChar
	call	GetCmd	       ; get next command from user
	or	bh, bh	       ; error
	jz	noerr

errrp:
	call	SynErr	       ; display syntax error message
	jmp	cont

noerr:
	shl	bx, 1
	call	word ptr [bx+exetab]
	or	bh, bh
	jnz	errrp

cont:
	cmp	[notdone], 1
	je	repeat
	call	SwapScr	       ; swap to original screen

exitdeb:
	mov	[quitprg], 1
	mov	[retloc], offset qreturn
	mov	ah, 4ch
	mov	al, [retcode]
	int	21h

qreturn:
	mov	dx, [old22+2]
	mov	ax, [old22]
	mov	ds, ax
	mov	ax, 2522h
	int	21h
	mov	ah, 4Ch	     ; terminate program
	mov	al, cs:[retcode]
	int	21h

quit:
	mov	[notdone], 0   ; we are done!!!
	cmp	[dbaddr], SCREEN
	je	dummy
	call	SwapScr		; swap in debug screen
	mov	dl, 26
	call	OutChar
	

dummy:
	xor	bh, bh
	ret

;-------------------------------------------------------------------------;
moss	ends
	end	start

