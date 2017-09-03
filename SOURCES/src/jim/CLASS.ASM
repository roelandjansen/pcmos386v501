	include page.inc
        title CLASS - MOS Security Class Changes
;
;******************************************************************************
;*                                                                            *
;*                        MOS Development Specification                       *
;*                                                                            *
;* Command type:  EXTERNAL              Assigned to:      Stewart Hyde        *
;* Command name:  CLASS                 Date assigned:    December 10, 1986   *
;*                                      Date completed:   December 22, 1986   *
;* Command format: CLASS filename c                                           *
;*                 CLASS xy                                                   *
;* Purpose:        To change file class from x to y                           *
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
;---------------------------------------------------------------------------;
; 	07/12/87	SAH 	Converted 80+ to INT 38h 00+ calls	    ;
;---------------------------------------------------------------------------;
;	08/24/87	RBR	Spelling error correction.		    ;
;---------------------------------------------------------------------------;
;	02/20/89	SAH	Converted INT 38 to INT SERVICES	    ;
;---------------------------------------------------------------------------;
;	03/21/89	SAH	Remove 386 Reference			    ;
;---------------------------------------------------------------------------;
;	11/17/89	BWR	Messages marked for foreign language        :
;				translation.                                ;
;---------------------------------------------------------------------------;
; 	05/01/90	SAH	Only allowed to change class to class	    ;
;				which user has access to.		    ;
;---------------------------------------------------------------------------;	
;       04/20/92	SAH	Up version to 5.01, copyright notice	    ;
;---------------------------------------------------------------------------;

        subttl  group segments for code, data and extra segments
        page

tcb     segment at 7777h
        include mostcb.inc
tcb     ends

scbs    segment at 08888h
	assume	cs:scbs
        include mosscbdf.inc
	assume	cs:nothing
scbs    ends

moss    segment word public 'code'
        assume cs:moss, ds:moss, es:moss

	include options.inc
        include class.pub


        org     100h

start   label   near
        jmp     begin
        db      8,8,8,'   '

tsl	db	13,10,'PC-MOS CLASS v5.01',13,10
	db	'(c) Copyright 1987 - 1992 The Software Link, Incorporated' ;@@XLAT
	db	13,10
        db      'All rights reserved worldwide ',13,10,'$' ;@@XLAT
	db	8,' ',26

	even
version label   near
        include version.inc

badmos  db      13,10, 'Incorrect MOS Version. ',13,10,'$' ;@@XLAT

syntax  db      13,10
        db      'Usage:    ',13,10 ;@@XLAT
        db      '  CLASS           - display command form       ',13,10 ;@@XLAT
        db      '  CLASS   Dir  C  - change Directory to class C        ',13,10 ;@@XLAT
        db      '  CLASS   PD      - changes Partition (P) and                  ',13,10 ;@@XLAT
	db	'                    User Default (D) Class(es)        ',13,10,'$' ;@@XLAT

Status  db      'CLASS Changing Directory $    ' ;@@XLAT
StMsg   db      '  to Class  ' ;@@XLAT
ClMsg   db      'A.',13,10,'$'
ErrMsg  db      13,10
        db      'CLASS Error:  $   ' ;@@XLAT
ErrEnd  db      '.',13,10,'$'
ClsSpec db      'Invalid Class Specification$      ' ;@@XLAT
ErPath  db      'Invalid Directory Path$       ' ;@@XLAT
ErAcc   db	'Access not allowed$          ' ;@@XLAT
ErDir   db      'Error changing directory$                 ' ;@@XLAT

UtMsg   db      'Partition Class      = $          ' ;@@XLAT
DfMsg   db      'Default Output Class = $           ' ;@@XLAT


len1    db      0               ; parm 1 lenght and storage
parm1   db      63 dup (' ')
len2    db      0               ; parm 2 lenght and storage
parm2   db      2 dup (' ')

buff83  label	byte
	db      (?)		; reserved
clsin	db	'C'		; class
userin	db	'USER'		; user @@XLAT
	db	4 dup (?)	; time & date	

savecls db      0               ; save class
saveacc db      255             ; save access for class
class   db      0               ; output class
cntrlc  db      0               ; control - c checking save state
path    db      63 dup (0),'$'  ; scan path

        even
pathlen dw     0                ; len off scan path
tcbseg  dw     0                ; TCB segment..

        page
;-----------------------------------------------------------------------;
;       Function:   Upper                                               ;
;       Input:                                                          ;
;                AL = character                                         ;
;       OutPut:                                                         ;
;                AL = Upper case character (0 if not character)         ;
;-----------------------------------------------------------------------;

Upper   proc    near
        cmp     al, '_'
        jne     ucont
        mov     al, ' '
        ret

ucont   label   near
        cmp     al, 'A'
        jb      uerror
        cmp     al, 'Z'
        jbe     udone
        cmp     al, 'a'
        jb      uerror
        cmp     al, 'z'
        ja      uerror
        sub     al, 'a'
        add     al, 'A'         ; force upper case

udone   label   near
        ret

uerror  label   near
        xor     al, al
        ret
Upper   endp

        page
;-----------------------------------------------------------------------;
;       Function:   SkipSpc                                             ;
;       Input:                                                          ;
;                SI = Command Position                                  ;
;                BL = Character Count                                   ;
;       OutPut:                                                         ;
;                SI = New Command Position                              ;
;                BL = New Character Count                               ;
;-----------------------------------------------------------------------;

SkipSpc proc near
        push    ax

ss1     label   near
        lodsb
        cmp     al, ' '         ; space??
        jne     ss2
        dec     bl              ; decrement counter
        or      bl,bl           ; done
        jnz     ss1             ; no??
        jmp     short ss3

ss2     label   near
        dec     si              ; decremnt command position

ss3     label   near
        pop     ax
        ret
SkipSpc endp

        page
;-----------------------------------------------------------------------;
;       Function:   CpyParm                                             ;
;       Input:                                                          ;
;                SI = Command Position                                  ;
;                BL = Character Count                                   ;
;       OutPut:                                                         ;
;                SI = New Command Position                              ;
;                DI = Destination                                       ;
;                BL = New Character Count                               ;
;                CX = Count                                             ;
;-----------------------------------------------------------------------;

CpyParm proc    near
        push    ax

        xor     cx, cx

cp1     label   near
        lodsb
        cmp     al, ' '         ; space??
        je      cp2
        or      al, al
        je      cp2
        stosb                   ; store byte
        inc     cx              ; increment buff counter
        dec     bl              ; decrement counter
        or      bl,bl           ; done
        jnz     cp1             ; no??
        jmp     short cp3

cp2     label   near
        dec     si              ; decremnt command position

cp3     label   near
        pop     ax
        ret
CpyParm endp

        page
;-----------------------------------------------------------------------;
;       Function:   Error                                               ;
;                   This place specally format error message            ;
;       Input:                                                          ;
;                   DX = offset of error message                        ;
;       OutPut:                                                         ;
;                   DX = destroyed                                      ;
;-----------------------------------------------------------------------;

Error   proc    near
        push    ax

        push    dx
        lea     dx, ErrMsg
        mov     ah, 9
        int     21h
        pop     dx
        int     21h
        lea     dx, ErrEnd
        int     21h

        pop    ax
        ret
Error   endp


;---------------------------------------------------------------------;
; Routine: ChkClass						      ;
; Extry:   AL = Class to check					      ;
; Exit:	   CARRY if class is not valid				      ;
;---------------------------------------------------------------------;

ChkClass proc	near
	push	ax
	push	bx
	push	cx
	push	dx

	mov	cl,al
	mov	bx,-1
	mov	ah,2fh		; check security class
	int	SERVICES
	jnc	CCOk
	cmp	ax,1		; invalid function 
	je	CCOk
	lea     dx, ErAcc
	call	Error
	stc
	jmp	short CCDone
	
CCOk:
	clc			; all ok

CCDone:
	pop	dx
	pop	cx
	pop	bx
	pop	ax				
	ret
ChkClass endp

        page
;---------------------------------------------------------------------;+

begin   label   near
;
;       Routine to check mos version
;
        mov     ah, 30h
        mov     bx, ax
        mov     cx, ax
        mov     dx, ax
        int     21h
        cmp     ax, word ptr [version]
        je      mosok
        lea     dx, badmos
        mov     ah, 9
        int     21h
        mov     ax, 4c01h
        int     21h

mosok   label   near
;
;       all ok continue with bussiness
;
        mov     ax, 3300h
        int     21h
        mov     [cntrlc], dl
        xor     dl, dl
        mov     ax, 3301h
        int     21h
        mov     si, 80h         ; start of command line
        mov     bl, byte ptr [si]   ; get command lenght  (bug in MASM )
        inc     si
        or      bl, bl
        jz      begin0
        call    SkipSpc         ; skip spaces
        or      bl, bl
        jnz     begin1

begin0  label   near
        mov     dx, offset tsl
        mov     ah, 9
        int     21h
        mov     dx, offset syntax
        mov     ah, 9
        int     21h
        int     20h

begin1  label   near
        push    bx
        push    es
        mov     ah, 002h
	int	SERVICES
        assume  es:scbs
        mov     ax, es:[bx+SCBTCBPC]
        pop     es
        pop     bx
        mov     [tcbseg], ax
        lea     di, parm1
        call    CpyParm
        mov     [len1], cl
        call    SkipSpc
        or      bl, bl
	jnz     begin11
        jmp     begin2

begin11 label	near
        lea     di, parm2
        call    CpyParm
        mov     [len2], cl
        or      cl, cl
        jnz     begin12
	jmp     begin2

begin12 label	near
        cmp     cl, 1
	je      begin13
        jmp     begin3

begin13 label	near
        mov     al, byte ptr [parm2]
        call    Upper
        or      al, al
	jnz     begin14
        jmp     begin3

begin14 label	near
        mov     [class], al
	push	cs
	pop	es
	mov	bl, [len1]
	xor     bh, bh
	mov	[bx+parm1], 0
	lea     dx, parm1		; get directory path
	lea     bx, Buff83
	mov	ax, 0300h		; get security information
	int	SERVICES
	jnc	begin1a	
	lea     dx, ErPath		; error in path
	call	Error
	jmp	finish

begin1a label	near
	cmp	al, 3			; must have access of 3
	je	Begin1b			
	lea     dx, ErAcc		; invalid access
	call	Error
	jmp	finish

begin1b label	near
	mov	al, [class]		; get class
	mov	[clsin], al
	lea     bx, Buff83
	lea     dx, parm1
	mov	ax, 0301h		; set security information
	int	SERVICES
	jnc	begin1c
	lea     dx, ErDir		; error processing directory
	call	error
	jmp	finish

begin1c	label	near
	lea	dx, Status
	mov	ah, 9
	int     21h
	mov	cl, [len1]
	xor     ch, ch
	lea     si, parm1

begin1d label	near
	lodsb
	call	Upper			; convert to upper case
	mov	dl, al			; display character
	mov     ah, 2
	int	21h
	loop    begin1d

	mov	al, [class]
	mov	[ClMsg], al
	lea     dx, StMsg
	mov	ah, 9
	int     21h
        jmp     short finish

begin2  label   near
        cmp     [len1], 2
        jne     begin3
        mov     es, [tcbseg]
        assume  es:tcb

        mov     al, [parm1+1]
        cmp     al, '*'
        jne     begin2a
        mov     al, es:[TCBCDFT]
        jmp     short begin2b

begin2a label   near
        call    Upper
        or      al, al
        je      begin3

begin2b label   near
        mov     [class], al
        mov     al, [parm1]
        cmp     al, '*'
        jne     begin2c
        mov     al, es:[TCBCLASS]
        jmp     short begin4

begin2c label   near
        call    Upper
        or      al, al
        jnz     begin4

begin3  label   near
        lea     dx, ClsSpec
        call    Error
        jmp     short finish

begin4  label   near
	push	ax
	mov	al,[class]
	call	ChkClass
	pop	ax
	jc	Finish
	call	ChkClass
	jc	finish
	
	
        mov     es, [tcbseg]
        assume  es:tcb

        mov     es:[TCBCLASS], al
        mov     [ClMsg], al
        lea     dx, UtMsg
        mov     ah, 9
        int     21h
        lea     dx, ClMsg
        int     21h
        mov     al, [class]
        mov     es:[TCBCDFT], al
        mov     [ClMsg], al
        lea     dx, DfMsg
        int     21h
        lea     dx, ClMsg
        int     21h

finish  label   near
        mov     dl, [cntrlc]
        mov     ax, 3301h
        int     21h
        int     20h

moss    ends

        end     start

