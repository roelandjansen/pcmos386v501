	include page.inc
	title	KEYMAP - Keyboard code translation
;--------------------------------------------------------------------
;			>> Revision Log <<
;		     keyboard enhancement program
;--------------------------------------------------------------------
;	SAH	11/23/87	Updated to version 2.00
;--------------------------------------------------------------------
;	SAH	04/04/89	Corrected a bug in yes\no
;--------------------------------------------------------------------
;	SAH	09/26/89	Corrections for Germans
;--------------------------------------------------------------------
;	BWR	11/27/89	Marked messages for foreign
;				language translation.
;--------------------------------------------------------------------
;	BWR	04/27/90	Yes/No prompt was not working on 2nd
;				invokation of KEYMAP because routine
;				was assuming a DS: reference to the
;				Yes/No character strings.  However, the
;				end-resident-code marker was above
;				these message strings, so the routine
;				was comparing against non-existant data.
;				To correct this, the reference is now
;				to CS: so the KEYMAP.COM that is currently
;				running has a copy of the compare strings
;				available.
;--------------------------------------------------------------------
;       BWR     10/09/90        Marked Yes/No prompt for foreign language
;                               translation.  THIS version of the source
;                               to build all foreign language versions of
;                               MOS 4.10
;---------------------------------------------------------------------
;
_text	segment word	public	'code'
	assume cs:_text, ds:_text

	 ORG 05Ch

fcb	label byte
drive		db ?		 ; default drive
filename	db 11 dup(?)	 ; filename & extension
curblock	dw ?		 ; current block
recsize 	dw ?		 ; record size
filesize	dw 2 dup(?)	 ; file size
		db 12 dup(?)	 ; reserved for system
currecno	db ?		 ; current record # in block
ranrecno	dw 2 dup(?)	 ; record # for random i/o

	 ORG 100h

start:
	 jmp	begin

msg1	db    13,'   ',13,10,'KEYMAP v4.00',13,10
	db    '(c) Copyright 1987, 1988, 1989 The Software Link, Incorporated.' ;@@XLAT
	db    13,10,'$',8,32,26

	even
;--------------------------------------------------------------------
;			   Work areas
;--------------------------------------------------------------------
okybdio  dd    0             ; original keyboard i/o vector
outindex dw    0             ; offset to current output character
lastntry dw    0             ; offset to end of table
prvtimer dw    0             ; timer value at previous keystroke
wkstring dw    5 dup(0)      ; pending keyboard input
wkindex  dw    0             ; indexes wkstring
lit_zero     dw    0		 ; constant zero

	page
;--------------------------------------------------------------------
;		   Keyboard I/O interrupt routine
;--------------------------------------------------------------------
nkybdio  label near
	 sti
	 push  es
	 push  ds
	 push  si
         push  dx
         push  cx
         push  bx

         push  cs
         pop   ds
         mov   si,[outindex]
	 mov   es,[lit_zero]
         
         cmp   ah,1                  ; 0 = read keyboard
         je    nkybtest              ; 1 = test keyboard
         jg    nkybshif              ; 2 = shift status request

;-------------------- Function 0 - Read keyboard --------------------
nkybread label near
         mov   ax,[si]               ; get next character
         or    ax,ax
         jnz   nkybincr
         call  readkybd              ; read keyboard if none there
         jmp   nkybread

;-------------------- Function 1 - Test keyboard --------------------

nkybtest label near
	 mov	ax,[si] 	      ; get character
         or    ax,ax                 ; is one there?
         jnz   nkybtsav              ; yes, jump
         mov   ah,1                  ; test keyboard
         pushf
         cli
         call  [okybdio]
         jz    nkybtsna              ; jump if nothing there
         call  readkybd              ; otherwise, go get it
         mov   [outindex],si
         mov   ax,[si]
nkybtsav:
	 or    ax,ax		     ; Clear ZF
         jmp   nkybbak0
nkybtsna:
	 cmp   ax,ax		     ; Set ZF
         jmp   nkybbak0

;------------------- Function 2 - Test shift status -----------------

nkybshif label near
         mov   ah,2                  ; test shift status
         pushf
         cli
         call  [okybdio]
         jmp   short nkybbak0

;---------------------------- Exit ----------------------------------

nkybincr label near
         add   si,2
         mov   [outindex],si
nkybbak0:
         pop   bx
         pop   cx
         pop   dx
         pop   si
         pop   ds
         pop   es
fareturn proc  far
         ret   2                     ; discard flags
fareturn endp

;--------------- Read from keyboard and attempt lookup --------------

readkybd proc  near
         lea   si,keytable           ; initialize table scanner
         mov   [wkindex],0
rkbloop1:
         mov   ah,0                  ; read keyboard character
         pushf
         cli
         call  [okybdio]
         mov   bx,[wkindex]
         mov   [wkstring+bx],ax      ; save it
         add   bx,2
         mov   [wkstring+bx],0       ; mark end of string
         mov   [wkindex],bx
         mov   bx,es:[046ch]         ; get timer low word
         mov   [prvtimer],bx
rkbloop2:
         cmp   si,[nextntry]         ; check if end of table
         jnb   rkbentab
         xor   bx,bx                 ; initialize loop
rkbloop3:
         mov   ax,[wkstring+bx]      ; get value to compare
         cmp   ax,[si+2+bx]
         je    rkbcont3
         add   si,[si]
         jmp   rkbloop2
rkbcont3:
         add   bx,2
         cmp   bx,8                  ; see if max length reached
         jnl   rkbmatch              ; yes, match completed
         cmp   word ptr [si+2+bx],0  ; see if another char required
         je    rkbmatch              ; no, match completed
         cmp   [wkstring+bx],0       ; have we got it yet?
         jne   rkbloop3              ; yes, go compare
rkbloop4:
         mov   ah,15                 ; innocuous call avoids deactivation
         int   10h
         mov   ah,1                  ; test keyboard
         pushf
         cli
         call  [okybdio]
         jnz   rkbloop1              ; jump if something to read

         and   [prvtimer],7fffh
         mov   ax,es:[046ch]         ; get timer low word
         and   ax,7fffh
         cmp   ax,[prvtimer]
         jnb   notmwrap
         or    ah,80h                ; handle timer wraparound
notmwrap:
         sub   ax,28                 ; allow 1.5 seconds
         cmp   ax,[prvtimer]
         jna   rkbloop4
rkbentab:
         lea   si,[wkstring]
         ret
rkbmatch:
         add   si,10                 ; address target data
         ret
readkybd endp

;--------------------- Key substitution table -----------------------

nextntry dw    0             ; offset to next available keytable entry
keytable label word
         dw    4096 dup(0)
endofres label word
         page
;--------------------------------------------------------------------
;		      Data for user interface
;--------------------------------------------------------------------
msgask1  db  13,10,13,10,'Translate from? $' ;@@XLAT
msgask2  db  13,10,'Translate to  ? $' ;@@XLAT
msgask3  db  13,10,'Is the above entry correct? $' ;@@XLAT
msgask4  db  13,10,13,10,'All finished? $' ;@@XLAT
msgask5  db  13,10,'That one is already assigned. Do you want to delete it? $' ;@@XLAT
msgask6  db  13,10,'Old entry is now deleted. Do you want a new assignment for it? $'  ;@@XLAT
msgyorn  db  13,10,'Please answer Y or N: $' ;@@XLAT
msgfull  db  13,10,13,10,'Table is full - session terminated!',13,10,'$' ;@@XLAT
msgifile db  13,10,'Enter input filename (Return if none): $' ;@@XLAT
msgofile db  13,10,13,10,'Enter output filename (Return if none): $' ;@@XLAT
msgnfind db  13,10,'File not found!',13,10,'$' ;@@XLAT
msgfsize db  13,10,'Input file too large!',13,10,'$' ;@@XLAT
msgbadof db  13,10,'Open failed!',13,10,'$' ;@@XLAT
msgwrite db  13,10,'Error on disk write!',13,10,'$' ;@@XLAT
msgcrlf  db  13,10,'$'
inbuffer db  15,0,16 dup (' ')
autoload db  'N'
yesmsg   db  'Yes',10,13,24h    ;@@XLAT
nomsg    db  'No  ',10,13,24h   ;@@XLAT

;--------------------------------------------------------------------
;			  user interface logic
;--------------------------------------------------------------------
begin:
	 mov   es,[lit_zero]
	 cmp   word ptr es:[0058h], offset nkybdio
         jne   skip01                ; vector offset matches?
         mov   ds,es:[005ah]         ; if so, pgm already installed
         jmp   short skip02
skip01:
         mov   ax,es:[0058h]         ; save old keyboard vector
         mov   word ptr [okybdio],ax
         mov   ax,es:[005ah]
         mov   word ptr [okybdio+2],ax
         lea   ax,keytable           ; initialize keytable
         mov   [nextntry],ax
         lea   ax,endofres-12
         mov   [lastntry],ax
	 lea   ax,[lit_zero]
         mov   [outindex],ax
skip02:
         cmp   byte ptr cs:[fcb+1],20h
         je    autoskp1
         mov   cs:[autoload],'Y'     ; indicate no operator input
         jmp   short openiput
autoskp1:
         lea   dx,msg1               ; display copyright notice
         call  writemsg
getiname:
	 cmp   cs:[autoload],'Y'     ; terminate if no operator input
	 jne   @F
         jmp   termnate
@@:
         lea   dx,msgifile           ; get input filename & format fcb
         call  getfname
         cmp   byte ptr cs:[fcb+1],20h
         je    asksrce               ; jump if no input file
openiput:
         push  ds
         push  cs
         pop   ds
         mov   ah,0fh                ; open input file
         lea   dx,fcb
         int   21h
         pop   ds
         or    al,al
         jz    ifilopnd
         lea   dx,msgnfind           ; file not found
         call  writemsg
         jmp   getiname
errsize:
         lea   dx,msgfsize           ; handle input file too large
         call  writemsg
         jmp   getiname
ifilopnd:
         cmp   cs:[filesize+2],0     ; now check if file too big
         jne   errsize
         mov   ax,cs:[filesize]
         add   ax,offset nextntry
         cmp   ax,[lastntry]
         ja    errsize

         lea   dx,nextntry
         mov   ah,1ah                ; set dta address
         int   21h

         push  ds
         push  cs
         pop   ds
         mov   [recsize],1
         xor   ax,ax
         mov   [currecno],al
         mov   [ranrecno],ax
         mov   [ranrecno+2],ax
         mov   cx,[filesize]         ;1
         mov   ah,27h                ; random block read
         lea   dx,fcb
         int   21h
         pop   ds
         add   word ptr [nextntry],offset nextntry ; relocate index
asksrce:
         cmp   cs:[autoload],'Y'
	 jne   @F
         jmp   termnate
@@:
         lea   dx,msgask1            ; ask for source keys
         call  writemsg
         mov   si,[nextntry]         ; prepare to define next table entry
         xor   ax,ax
         mov   [si],ax
         mov   [si+2],ax
         mov   [si+4],ax
         mov   [si+6],ax
         mov   [si+8],ax
         add   si,2                  ; point to source data
srceloop:
         call  getinput
         mov   [si],ax               ; save source keystroke
         add   si,2
         cmp   ax,0                  ; check if return key hit
         je    gotsrce
         mov   bx,[nextntry]
         add   bx,10
         cmp   si,bx                 ; 4 keystrokes is max
         jl    srceloop
gotsrce:
         mov   si,[nextntry]         ; point to target data
         cmp   word ptr [si+2],0     ; check if source is null
	 jne   @F
         jmp   nosource
@@:
         cld
         push  ds
         pop   es
         lea   di,keytable
srckloop:
         cmp   word ptr [di],0       ; check if end of table
         je    getarget
         push  di
         add   di,2
         mov   si,[nextntry]
         add   si,2
         mov   cx,4
         repe  cmpsw
         pop   di
         je    srckoops              ; source is already in table
         add   di,[di]
         jmp   srckloop
srckoops:
         lea   dx,msgask5            ; ask if user wants to delete it
         call  yesorno
         jne   asksrce               ; jump if not
         cld
         mov   si,di
         mov   ax,[di]               ; save length of deleted entry
         add   si,ax                 ; compute move-from address
         mov   cx,[nextntry]         ; compute length of move
         sub   cx,si
         add   cx,12                 ; include new source data
         rep   movsb                 ; do the move
         sub   [nextntry],ax         ; adjust end-of-table address
         lea   dx,msgask6            ; ask if new definition desired
         call  yesorno
         je    getarget
         jmp   asksrce
getarget:
         mov   si,[nextntry]
         add   si,10
         lea   dx,msgask2            ; ask for target keys
         call  writemsg
targloop:
         call  getinput
         mov   [si],ax               ; save target keystroke
         add   si,2
         cmp   si,[lastntry]
         jnb   tabfull
         cmp   ax,0                  ; check if return key hit
         jne   targloop

         lea   dx,msgask3            ; get final ok
         call  yesorno
	 je    @F
         jmp   asksrce
@@:
         mov   bx,[nextntry]         ; update chain pointer
         mov   ax,si
         sub   ax,bx
         mov   [bx],ax
         mov   [nextntry],si         ; update next-entry pointer
         mov   word ptr [si],0       ; flag end of table
         jmp   asksrce
nosource:
         lea   dx,msgask4            ; ask if all done
         call  yesorno
         je    alldone
         jmp   asksrce
tabfull:
         lea   dx,msgfull
         call  writemsg
alldone:
         lea   dx,msgofile           ; get output filename & format fcb
         call  getfname
         lea   dx,msgcrlf
         call  writemsg
         cmp   byte ptr cs:[fcb+1],20h
         je    termnate              ; jump if no input file

         push  ds
         push  cs
         pop   ds
         mov   ah,16h                ; open output file
         lea   dx,fcb
         int   21h
         pop   ds
         or    al,al
         jz    ofilopnd
         lea   dx,msgbadof           ; open failed
         call  writemsg
         jmp   alldone
ofilopnd:
         lea   dx,nextntry
         mov   ah,1ah                ; set dta address
         int   21h

         sub   word ptr [nextntry],offset nextntry ; un-relocate
         mov   cx,[nextntry]
         push  ds
         push  cs
         pop   ds
         mov   [recsize],1
         xor   ax,ax
         mov   [currecno],al
         mov   [ranrecno],ax
         mov   [ranrecno+2],ax
         mov   ah,28h                ; random block write
         lea   dx,fcb
         int   21h
         pop   ds
         add   word ptr [nextntry],offset nextntry
         cmp   al,0
         je    closeout
         lea   dx,msgwrite           ; write failed
         call  writemsg
         jmp   alldone
closeout:
         push  ds
         push  cs
         pop   ds
         mov   ah,10h                ;close file
         lea   dx,fcb
         int   21h
         pop   ds
termnate:
         mov   ax,ds
         mov   bx,cs
         cmp   ax,bx
         je    stayres
         mov   ds,bx
         int   20h
stayres:
	 mov   es,[lit_zero]
         mov   word ptr es:[0058h],offset nkybdio
         mov   es:[005ah],cs
         mov   dx,[nextntry]
         add   dx,1024               ; allow 1k for table additions
         mov   [lastntry],dx
         add   dx,16
         int   27h

getfname proc  near
         call  writemsg              ; ask for filename
         push  ds
         push  cs
         pop   ds

         lea   dx,inbuffer
         mov   ah,0ah                ; request buffered keyboard input
         int   21h

         lea   si,inbuffer+2         ; ds:si is filename
         push  cs
         pop   es                    ; es:di is fcb
         lea   di,fcb
         mov   ax,2901h              ; parse filename
         int   21h

         pop   ds
         ret
getfname endp

yesorno  proc  near
	 call	 writemsg
	 xor   ax,ax
	 int   16h
	 and   al,0DFh		;Convert to upper case.
	 cmp   al, cs:[yesmsg]
         je    yesornox
	 cmp   al, cs:[nomsg]
         je    yesornon
         lea   dx,msgyorn
         jmp   yesorno
yesornon:
	 lea   dx,nomsg
	 call  writemsg	
         or    al,al
	 ret
yesornox:
	 pushf
	 lea	dx,yesmsg
	 call   writemsg
	 popf
         ret
yesorno  endp

writemsg proc  near
         push  ds
         push  cs
         pop   ds
         mov   ah,9                  ; write message to console
         int   21h
         pop   ds
         ret
writemsg endp

getinput proc  near
         mov   ah,0                  ; read next kb character
         pushf
         call  [okybdio]
         cmp   al,0dh                ; check for carriage return
         je    getinxor
         cmp   al,'$'
         jne   getindis
         mov   ah,0
         pushf
         call  [okybdio]
         cmp   al,'R'
         je    getincr
         cmp   al,'r'
         jne   getindis
getincr:   
         mov   ax,1c0dh              ; translate to carriage return
         push  ax
         mov   al,'/'
         jmp   short getinsk1
getinxor:
         xor   ax,ax
         ret
getindis:
         push  ax
         cmp   al,0
         jne   getinsk1
         mov   al,'*'
getinsk1:
         cmp   al,20h                ; check for control codes
         jnb   getinsk2
         mov   ax,0e5eh              ; write a carat
         mov   bx,0007h
         int   10h
         pop   ax
         push  ax
         add   al,40h
getinsk2:
         mov   ah,0eh                ; write teletype
         mov   bx,0007h
         int   10h
         pop   ax
         ret
getinput endp

_text  ends
         end   start
