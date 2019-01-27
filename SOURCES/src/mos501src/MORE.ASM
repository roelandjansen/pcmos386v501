	 include page.inc
         title   MORE - a filter to paginate piped output

         subttl  MORE Development Specification

 ;-----------------------------------------------------------------------;
 ;                                                                       ;
 ;                    Development Specification                          ;
 ;                                                                       ;
 ;                                                                       ;
 ; Program Name: MORE.COM               Assigned to: Martin Stitt	 ;
 ; Module Name:  MORE                   Assign date: 08/06/86            ;
 ; Entry Points: MORE                   Completed:  8/8/86       	 ;
 ; Entry From:   MOS command processor                                   ;
 ; Entry Method:                                                         ;
 ; Purpose:                                                              ;
 ; Refer To:                                                             ;
 ; Last Update:                                                          ;
 ;                                                                       ;
 ; Description: Filter the charactor stream from the standard input      ;
 ; device by counting the number of display lines and providing a pause  ;
 ; each time the display fills up.  This process must account for        ;
 ; control codes which do not advance the cursor, lines longer than the  ;
 ; current screen width and the current screen width (80, 40 or 20).     ;
 ;-----------------------------------------------------------------------;

 ;------------------------- Revision Log -------------------------------;
 ;									;
 ; BWR	11/28/89	Marked messages for foreign language		;
 ;			translation.					;
 ;----------------------------------------------------------------------;
         subttl  MORE macros, equates, data
         page

 ;dos function calls
 readfil equ     3fh
 writfil equ     40h
 stdin   equ     0000
 stdout  equ     0001
 stderr  equ     0002
 prnstr  equ     09h
 prnchr  equ     02h
 duphndl equ     45h
 quit    equ     4ch

 true    equ     0ffh
 false   equ     0

 cr      equ     13
 lf      equ     10
 eof     equ     1ah
 tab     equ     9
 bell    equ     7
 bs      equ     8
 maxlins equ     25

 MOS     MACRO   fn
         mov     ah,fn
         int     21h
         endm

 PushRegSet      MACRO
         pushf
         push ax
         push bx
         push cx
         push dx
         push di
         push si
         push bp
         push ds
         push es
         ENDM

 PopRegSet       MACRO
         pop es
         pop ds
         pop bp
         pop si
         pop di
         pop dx
         pop cx
         pop bx
         pop ax
         popf
         ENDM

 Ljcxz   MACRO   jmpdest         ; Long jumps
         LOCAL   lp1,lp2
         jcxz    lp1
         jmp     lp2
 lp1:    jmp     jmpdest
 lp2:
         ENDM

 Lje     MACRO   jmpdest
         LOCAL   lp1,lp2
         je      lp1
         jmp     lp2
 lp1:    jmp     jmpdest
 lp2:
         ENDM

 Ljz     MACRO   jmpdest
         LOCAL   lp1,lp2
         jz      lp1
         jmp     lp2
 lp1:    jmp     jmpdest
 lp2:
         ENDM

 Ljnz    MACRO   jmpdest
         LOCAL   lp1,lp2
         jnz     lp1
         jmp     lp2
 lp1:    jmp     jmpdest
 lp2:
         ENDM

         subttl  main code for MORE
         page

 codeseg SEGMENT

         ORG     0100h
         ASSUME  CS:CODESEG,DS:CODESEG

 start:
         jmp     EntryPnt

 ermsg1  db      "MORE: Insufficient memory available!        ",cr,lf ;@@XLAT
 erm1ln  db      $ - ermsg1
 moremsg db      "Continued . . .$" ;@@XLAT
 eolmsg  db      cr,lf,"$"

 maxcols db      ?
 lincntr db      1
 chrcntr db      1

 ;-----------------------------------------------------------------------;
 ;                    Send a crlf pair to the display                    ;
 ;                                                                       ;
 ;-----------------------------------------------------------------------;

 DispEOL PROC  NEAR
         lea     dx,eolmsg
         MOS     prnstr
         ret
 DispEOL ENDP

         subttl  main procedure, filter data stream
         page
 ;--------------------------------------------------------------------;
 ;                          Main procedure                            ;
 ;                       for MOS MORE command                         ;
 ;--------------------------------------------------------------------;
 EntryPnt:

	jmp	Vrchk1		; skip around the data
version	label	byte
	include	version.inc

vermsg	db	13,10,'Improper MOS Version.',13,10,'$' ;@@XLAT

Vrchk1:
	mov	ah,30h
	mov	bx,ax		; read the MOS version number
	mov	cx,ax
	mov	dx,ax
	int	21h
	cmp	ax,word ptr [version]
	jne	Vrchk2
	cmp	bx,word ptr [version+2]
	je	Vrchk3
Vrchk2:
	lea	dx,[vermsg]	; report mismatch
	push	cs
	pop	ds
	mov	ah,9
	int	21h
	mov	al,2		; errorlevel 2
	mov	ah,4ch		; and terminate
	int	21h
Vrchk3:

 ;
 ; develop a paragraph count of available memory from the end of this program
 ; to the end of total free memory.  Report and exit if not enough room for
 ; this program's buffer needs
 ;
         lea     bx,EndOfProg 
         test    bx,0fh
         pushf
         mov     cl,4
         shr     bx,cl           ; calc paragraphs for offset
         popf
         jz      SkipInc
         inc     bx

 SkipInc:
         mov     ax,cs
         add     bx,ax           ; add to paragraphs in segment
         int     12h             ; read number of Kbytes total memory
         mov     cl,6
         shl     ax,cl           ; convert to paragraphs
         sub     ax,bx           ; and find free paragraphs
         cmp     ax,256          ; need 256 paragraphs for 4k buffer
         jae     EnoughMem
         lea     dx,ermsg1       ; not enough memory 
         mov     bx,stderr       ; report and quit
         mov     cl,erm1ln
         xor     ch,ch
         MOS     writfil
         MOS     quit

 EnoughMem:
         mov     ah,0fh          ; read video mode to get number of 
         int     10h             ; columns for display
         mov     [maxcols],ah
         call    DispEOL

 GetData:
         lea     dx,EndOfProg    ; read a buffer of data from standard input
         mov     si,dx
         mov     cx,4096
         mov     bx,stdin
         MOS     readfil
         mov     cx,ax
         Ljcxz   CleanExit
         cld

 ReadChar:
         lodsb                   ; read a charactor from the buffer
         cmp     al,eof          ; an test it to see if it is in the 
         Lje     CleanExit       ; set of control charactors which are
         cmp     al,cr           ; not displayable.  Special accounting
         Lje     Rc1             ; must be done for non-displayable control
         cmp     al,lf           ; charactors to insure only a screen full
         Lje     Rc2             ; of charactors is passed at a time.
         cmp     al,bs
         Lje     Rc3
         cmp     al,tab
         Lje     Rc4
         cmp     al,bell
         Lje     WriteChar
         inc     [chrcntr]       ; must be a displayable charactor
         mov     bh,[maxcols]
         cmp     [chrcntr],bh
         jng     WriteChar
         inc     [lincntr]       ; if chrcntr > maxcols then advance the line
         mov     [chrcntr],1

 WriteChar:
         mov     dl,al           ; send the charactor to standard output
         MOS     prnchr
         mov     bl,al
         cmp     [lincntr],maxlins
         jl      Wc1
         lea     dx,moremsg      ; if a screen full has been sent, put up
         MOS     prnstr          ; message and pause for key.  
         mov     ah,1
         int     16h

 DrainKeyBuf:
         jz      Drained         ; Use BIOS to read keyboard directly rather  
         mov     ah,0            ; than a MOS call because of redirection.
         int     16h             
         mov     ah,1
         int     16h
         jmp     DrainKeyBuf

 Drained:
         mov     ah,0            ; BIOS call to wait for key
         int     16h
         cmp     al,3            ; check for ^C
         je      CleanExit
         call    DispEOL
         mov     [lincntr],1     ; re-init counters
         mov     [chrcntr],1
         cmp     bl,lf
         je      Wc1
         dec     si
         inc     cx

 Wc1:
         dec     cx
         Ljcxz   GetData         ; buffer empty, get another
         jmp     ReadChar        ; read another charactor from the buffer

 Rc1:
         mov     [chrcntr],1     ; reset charactor counter when a cr is 
         jmp     WriteChar       ; detected

 Rc2:
         inc     [lincntr]       ; advance line counter when a lf is detected
         jmp     WriteChar

 Rc3:
         dec     [chrcntr]       ; backup charactor counter when a bs is
         Ljnz    WriteChar       ; detected
         inc     [chrcntr]
         jmp     WriteChar

 Rc4:
         mov     ah,[chrcntr]    ; when a tab charactor is found, anticipate
         add     ah,7            ; how the display function will expand the
         and     ah,0f8h         ; tab to the next column of the set:
         inc     ah              ; 1,9,17,25,33...   (every 8th col)
         mov     [chrcntr],ah
         jmp     WriteChar

CleanExit:
	xor	al,al		; errorlevel 0

 ExitMore:
         MOS     quit            ; terminate program, return to MOS

 EndOfProg LABEL BYTE

 codeseg ENDS

         END     start
