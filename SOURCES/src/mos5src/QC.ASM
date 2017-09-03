comment ^===============================================================
		       Development Specification

 Program Name:	QC.ASM	            		Assigned to: Rick Ruhl
 Module Name:	QC				Assign date: 01/10/91
 Entry Points:	Command Processor 		Completed:  01/25/91
 Entry From:
 Entry Method:	
 Calls:		
 Purpose: This program reads in a disk track by track, creating a file with
          CRC 16.  It is used for QC to do a track by track analysis of the
          production diskettes.	
 Refer to:	
;Updated: Friday, 25 January 1991.   17:14  
==========================================================================
^



	 page



disp	macro	msg, len
	mov	dx,offset msg
	mov	bx,2
	mov	cx,len
	mov	ah,40h
	int	21h
	endm



 codeseg SEGMENT

         ORG     0100h
         ASSUME  CS:CODESEG,DS:CODESEG

 start:
	 jmp	 EntryPnt
	db	8,8,8
tsl	db	'QC Quality Control Program 1.2 (920512)'
	db	13,10
	db	'For internal use only',13,10
	db	'(c) Copyright 1991-1992 The Software Link, Incorporated',13,10,10
tsllen	equ     ($-tsl)

	db	'$',8,' ',26
HelpMsg	db	'Syntax:',13,10
	db	'QC /F=pathname [/B] [/P] [/h]'
	db	13,10
	db	'Where:',13,10
        db      ' /F=pathname    : path and filename of data file',13,10
        db      ' /P             : use if disk is a PC-MOS disk',13,10
	db	' /B             : If using the B drive, default is A',13,10
	db	' /h             : Displays command line help',13,10
HelpLen equ	($-HelpMsg)

StartSerial     dw      ?               ; use for serial # processing

infofile	label   byte

noserial        db      0               ;number of serial numbers

cyl             db      ?               ; cyl of serial #
softset         dw      ?               ; offset of serial # within 9K buffer

                db      5 dup (?,?,?)   ; next 	 5 cyl and offsets

crc	        dw     80 dup (?)
infolen         equ    ($-infofile)


Begin	db	'Starting Test.',13,10
beginlen	 equ	($-Begin)

Exit	db	'Exiting Test.',13,10
exitlen	 equ	($-Exit)

message db	'Finding Serial number$'
ser	db	'Serial number $'
snum	db	12 dup (?)
cerr    db      13,10,10,'Production disk failed QC check',13,10,'$'
diskmsg	       db	13,10,'Put disk in drive and hit any key$',13,10
msgrerr	  db	13,10,10,'Diskette read error!',13,10,'$'
errlen    db    ($-msgrerr)
msgwerr	  db	13,10,'Error writing output file!',13,10,'$'
createlen equ   ($-msgwerr)
msgcrlf	  db	13,10,'$'
msgdot	  db	0fah,'$'
msgsearch db	13,10,13,10
	  db	'Searching for Head,Cylinder,Track and Offset'
	  db	13,10,'$'
MsgFound  db	13,10                          
	  db	'Serial # Found!',13,10,10
	  db	'Head:         '
VHead	  db	'x.',13,10
	  db	 'Track:       '
VCyl	  db	 '00.',13,10  
	  db	 'Cylinder:    '
VTRack	  db	 'x.',13,10
	  db	 'Offset:      '
VOff	  db	 '000.',13,10,10,'$'	
tempdir	db	64 dup (0)	; temporary directory to use

SerialMsg       db      13,10,'Serial # found on disk is '
SerialVal       db      '$$$$$$$$$$$'

Creatmsg        db      13,10,'Creating Disk Information file $'

deffilename     db      'qc.dat'
deflen          equ     ($-deffilename)

search		db	'X0X0X',0
search1		db	'SeRiAl',0
mos		db	'N'
filename        db      'qc.dat', 80 dup (0)   
filehandle	dw	?
checksum	dw	?
Creating	db	'N'
error		db	'N'
onedottwo         db      'N'
threehalf	db	'N'
Bdrive		db	'N'


buffaddr dw	0
cylinder db	0
drive	 db	0
retries	 db	3
crcoff	 dw	0

SavCyl	 db	0			; save cylinder for serial # inplant
SavOff	 dw	0			; save offset for serial # implant

crlf	db	13,10

dohelp	db	'N'		; flag to indicate to do help messages


EofFlag db	'N'
ReadCount dw	0
StdOut	db	'N'


startpos  dw	0		; default start pos is column 0
sortlen	  dw	-1		; default is to include all of it

msgperror db	13,10
	  db	'Error in Parmeter : '
msgplen	 equ	($-msgperror)

Char	db	0		; Temporary character
Buffer	dw	0		; offset to buffer
BuffMax	dw	0		; Maximun values in Buffer
BuffPtr	dw	0		; Current Pointer in Buffer

ten	dw	10		; constant 10


crc_tbl	dw	00000h,0c0c1h,0c181h,00140h,0c301h,003c0h,00280h,0c241h
	dw	0c601h,006c0h,00780h,0c741h,00500h,0c5c1h,0c481h,00440h
	dw	0cc01h,00cc0h,00d80h,0cd41h,00f00h,0cfc1h,0ce81h,00e40h
	dw	00a00h,0cac1h,0cb81h,00b40h,0c901h,009c0h,00880h,0c841h
	dw	0d801h,018c0h,01980h,0d941h,01b00h,0dbc1h,0da81h,01a40h
	dw	01e00h,0dec1h,0df81h,01f40h,0dd01h,01dc0h,01c80h,0dc41h
	dw	01400h,0d4c1h,0d581h,01540h,0d701h,017c0h,01680h,0d641h
	dw	0d201h,012c0h,01380h,0d341h,01100h,0d1c1h,0d081h,01040h
	dw	0f001h,030c0h,03180h,0f141h,03300h,0f3c1h,0f281h,03240h
	dw	03600h,0f6c1h,0f781h,03740h,0f501h,035c0h,03480h,0f441h
	dw	03c00h,0fcc1h,0fd81h,03d40h,0ff01h,03fc0h,03e80h,0fe41h
	dw	0fa01h,03ac0h,03b80h,0fb41h,03900h,0f9c1h,0f881h,03840h
	dw	02800h,0e8c1h,0e981h,02940h,0eb01h,02bc0h,02a80h,0ea41h
	dw	0ee01h,02ec0h,02f80h,0ef41h,02d00h,0edc1h,0ec81h,02c40h
	dw	0e401h,024c0h,02580h,0e541h,02700h,0e7c1h,0e681h,02640h
	dw	02200h,0e2c1h,0e381h,02340h,0e101h,021c0h,02080h,0e041h
	dw	0a001h,060c0h,06180h,0a141h,06300h,0a3c1h,0a281h,06240h
	dw	06600h,0a6c1h,0a781h,06740h,0a501h,065c0h,06480h,0a441h
	dw	06c00h,0acc1h,0ad81h,06d40h,0af01h,06fc0h,06e80h,0ae41h
	dw	0aa01h,06ac0h,06b80h,0ab41h,06900h,0a9c1h,0a881h,06840h
	dw	07800h,0b8c1h,0b981h,07940h,0bb01h,07bc0h,07a80h,0ba41h
	dw	0be01h,07ec0h,07f80h,0bf41h,07d00h,0bdc1h,0bc81h,07c40h
	dw	0b401h,074c0h,07580h,0b541h,07700h,0b7c1h,0b681h,07640h
	dw	07200h,0b2c1h,0b381h,07340h,0b101h,071c0h,07080h,0b041h
	dw	05000h,090c1h,09181h,05140h,09301h,053c0h,05280h,09241h
	dw	09601h,056c0h,05780h,09741h,05500h,095c1h,09481h,05440h
	dw	09c01h,05cc0h,05d80h,09d41h,05f00h,09fc1h,09e81h,05e40h
	dw	05a00h,09ac1h,09b81h,05b40h,09901h,059c0h,05880h,09841h
	dw	08801h,048c0h,04980h,08941h,04b00h,08bc1h,08a81h,04a40h
	dw	04e00h,08ec1h,08f81h,04f40h,08d01h,04dc0h,04c80h,08c41h
	dw	04400h,084c1h,08581h,04540h,08701h,047c0h,04680h,08641h
	dw	08201h,042c0h,04380h,08341h,04100h,081c1h,08081h,04040h

acc     dw     0



;------------ Parameter Analysis Routines ----------------------------;

parmtab	 label	byte
	 db	'H'
	 dw	offset parmhelp
	 db	'P'			   ;MOS
	 dw	offset parmMOS
	 db	'C'
	 dw	offset parmcreate	   ;Create flag
	 db	'B'
	 dw	offset parmdisk
         db     'F'
         dw     offset parmfile
	 db	0		           ;terminator
	 dw	0


parmfile        proc    near
		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		push	ss
                mov     si,di
                cld
                push    es
                lea     di,filename
                mov     cl,deflen
                xor	ch,ch
		xor     ax,ax
                rep     stosb
                pop     es
                lodsb
                cmp     al,'='
                jne     parmdef
                lodsb
                cmp     al,'/'
                je      parmdef
                cmp     al,' '
                je      parmdef
                cmp     al,13
                je      parmdef
                lea     di,filename
                stosb
parmloop:
                lodsb
                cmp     al,'/'
                je      parmexit
                cmp     al,' '
                je      parmexit
                cmp     al,13
                je      parmexit
                stosb
                jmp     parmloop
parmexit:
                dec     si
                mov     di,si
                clc
		pop	ss
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
                ret        
parmdef:
                dec     si
                push    es
                push    si
                lea     si,deffilename
                lea     di,filename
                mov     cx,deflen
                push	cs
		pop	es
		pop	si
		cld
		rep     movsb
                pop     es
                mov     di,si
                clc
		pop	ss
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax

                ret
parmfile        endp

parmdisk	proc   near
	        mov	[bdrive],'Y'
		mov	[drive],1
	        clc
	        ret
parmdisk	endp




parmcreate proc	near
	 mov	[Creating],'Y'
	 clc
	 ret
parmcreate endp

parmhelp proc	near
	 mov	[dohelp],'Y'
	 disp	tsl,tsllen
	 disp   helpmsg,helplen
	 mov	[error],'Y'
	 clc
	 ret
parmhelp endp

parmMOS  proc	near
	 mov	[MOS],'Y'
	 clc
	 ret
parmMOS endp



parmtemp proc	near
	 lea	di,tempdir
 	 xor	cx,cx
temploop:
	 lodsb
	 cmp	al,' '
	 je	tempend
	 cmp	al,13
	 je	tempend
	 cmp	al,'/'
	 je	tempend
	 cmp	cx,63
	 jae	temperr
	 inc	cx
	 stosb
	 jmp	short temploop
	 
tempend:
	 clc
	 ret
temperr:
	 stc
	 ret
parmtemp endp

parmpos  proc	near
	 call	dectobin
	 mov	[StartPos],ax
;
;	 now we will check for optional second parmeter for lenght
;
pploop:
	 lodsb
	 cmp	al,13
	 je	ppdone
	 cmp	al,','
	 je	ppnext
	 cmp	al,' '
	 jmp	short pploop
ppnext:
	 lodsb
	 cmp	al,' '
	 je	ppnext
	 dec	si
	 call	dectobin
	 mov	[sortlen],ax	 
ppdone:
	 clc
	 ret
pperror:	 	 
	 stc
	 ret
parmpos  endp

GetParms proc	near
	 mov	si,81h
	 cld
GPStart:
	 lodsb
	 cmp	al,13
;	 je	GPEnd
	 je	GpError
	 cmp	al,' '
	 je	GPStart
;
;	 at this point we have parameter on command line
;	 
GPSearch:
	 cmp	al,'/'		; is it paramerter key
	 jne	GPError
	 lodsb	
	 and	al,0dfh
	 mov	bl,al
	 mov	di,si
	 lea	si,parmtab
GPparms:
	 lodsb
	 or	al,al
	 je	GPError1
	 cmp	al,bl		; is it a match
	 pushf
	 lodsw
	 popf
	 jne	GPparms		; check parmater on list
	 mov	bx,ax
	 push	di
	 call	bx
	 pop	di
	 jc	GPError1
;
; at this point we have finish with parmeter
;
	 mov	si,di
GPLoop:
	 lodsb	
	 cmp	al,13
	 je	GPEnd
	 cmp	al,'/'
	 jne	GPLoop
	 jmp	short GPSearch
GPError1:
	 mov	si,di
	 sub	si,2
GPError:
	 Disp	msgperror,msgplen
	 mov	[error],'Y'
GPDispErr:
	 lodsb
	 cmp	al,13
	 je	GPDispEnd
	 mov	byte ptr cs:[Char],al
	 Disp	Char,1
	 jmp	short GPDispErr
GPDispEnd:
	 Disp	crlf,2
	 stc
	 ret	 
GPEnd:
	 clc
	 ret	 
GetParms endp

dectobin proc	near
	 push	di
	 xor	di,di
	 xor	bx,bx
	 xor	cx,cx
decloop:
	 lodsb
	 cmp	al,'0'
	 jb	decend
	 cmp	al,'9'
	 ja	decend
	 sub	al,'0'
	 mov	cl,al
	 mov	ax,bx
	 mul	[ten]
	 add	ax,cx
	 mov	bx,ax
	 inc	di
	 cmp	di,4
	 jae	decexit
	 jmp	short decloop	 	 
decend:
	 dec	si
decexit:
	 mov	ax,bx
	 pop	di
	 ret
dectobin endp


create	  proc	near
          mov	ax,3c00h
	  xor	cx,cx
          lea   dx,[filename]
	  int	21h
          jc    cerror

	  mov	  [filehandle],ax
	  mov     [StartSerial],offset Cyl

          call	  searchdisk

	  mov	ah,40h
	  mov	bx,[filehandle]
	  lea	dx, infofile
	  mov	cx,infolen
	  int	21h
          jc    cerror


	  mov	bx,[filehandle]
	  mov	ah,3eh
	  int	21h
          jc    cerror

	  ret
cerror:
          lea   dx,msgwerr
          mov   ah,9
          int   21h
          mov   ax,4c01h
          int   21h

create	  endp

Compare	  proc	near
          mov	ax,3d00h
          lea   dx,[filename]
	  int	21h
	  jc    rerr
          mov	  [filehandle],ax

          mov   ah,3fh      
	  mov	bx,[filehandle]
	  lea	dx, infofile
	  mov	cx,infolen
	  int	21h
          jc    rerr


	  mov	bx,[filehandle]
	  mov	ah,3eh
	  int	21h
          jc    rerr
  	  mov     [StartSerial],offset Cyl

          call  searchdisk
	  ret
rerr:
          lea   dx,msgrerr
          mov   ah,9
          int   21h
          mov   ax,4c02h
          int   21h

compare	  endp

crc16	proc	near
	jcxz	no_len			; branch if zero buffer length
        mov     dx,cs:[acc]
	xor     si,si
	cld				; auto-increment
nxt_byt:
	xor	ax,ax			; clear AX
	lodsb				; get next byte of buffer
	xor	al,dl			; XOR with accum lo-byte
	add	ax,ax			; multiply by 2
	mov	bx,ax			; to BX
	
	mov	ax,cs:crc_tbl[bx]
	
	xor	al,dh			; finish translation
	mov	dx,ax			; update accum
	loop	nxt_byt			; do all bytes in buffer
        mov     cs:[acc],dx               ; set new value
no_len:
	ret

crc16	endp

calccrc         proc    near
                push    ds
                cmp     [onedottwo],'Y'
                jne     c1
                mov     cx,30*512
                jmp     c2
c1:
                mov     cx,18*512
c2:   
                mov     ds,[buffaddr]
                call    crc16
                pop     ds                
                ret
calccrc         endp

searchdisk	proc	 near
        mov     dx,offset Creatmsg
        mov     ah,9
        int     21h
        cld
        lea     si,filename
fmsgloop:
        lodsb
        or      al,al
        jz      fmsgdone
        cmp     al,'a'
        jb      fmsgdo
        cmp     al,'z'
        ja      fmsgdo
        sub     al,'a'
        add     al,'A'
fmsgdo:
        mov     dl,al
        mov     ah,2
        int     21h
        jmp     fmsgloop
fmsgdone:
        disp    crlf,2
	mov	dx,offset diskmsg
	mov	ah,9
	int	21h
	xor	ax,ax
	int 	16h
	mov	dx,offset msgsearch
	mov	ah,9
	int	21h

	mov	ax,ds			; compute I/O buffer address
	mov	bx,offset progend+15
	mov	cl,4
	shr	bx,cl
	add	ax,bx
	add	ax,0fffh
	and	ax,0f000h
	mov	[buffaddr],ax
	push	es
	mov	es,ax
	xor	di,di
        cmp     [onedottwo],'Y'
        jne     fm1
        mov     cx,15*512
        jmp     fm2
fm1:
	mov	cx,9*512
fm2:
        xor	ax,ax
	rep	stosw
	pop	es

	mov	dx,offset msgcrlf
	mov	ah,9
	int	21h

;	mov	[cylinder],0		; start at cylinder 0
	mov	[cylinder],1    	; start at cylinder 0
	mov	[retries],3

	mov	ah,0			; reset diskette controller
	int	13h

	mov	ah,08h
	mov	dl,[drive]
	int	13h
	
	jnc	checkdisktype
	jmp	exitprog
checkdisktype:
        cmp     bl,02h
        jne     not12
        mov     [onedottwo],'Y'
        jmp     nextcyl
not12:
	cmp	bl,03h
	jne	nextcheck
	Mov	[threehalf],'Y'
nextcheck:
	cmp	bl,04h
   	jne	nextcyl
	mov	[threehalf],'Y'
	
nextcyl label	near
	mov	es,[buffaddr]		; prepare to read data
	mov	ch,[cylinder]
	mov	cl,1
	mov	dl,[drive]

	mov	ax,0209h		; read 9 sectors on head 0
	mov	bx,0
	mov	dh,0
	int	13h
	jnc	gothead0
	dec	[retries]		; allow timeout for motor startup
	jnz	nextcyl
	jmp	rerror
gothead0:
        cmp     [onedottwo],'Y'
        jne     gt1
	mov	ax,020fh		; read 9 sectors on head 1
	mov	bx,15*512
gt1:
	mov	ax,0209h		; read 9 sectors on head 1
	mov	bx,9*512
gt2:
        mov	dh,1
	int	13h
        jnc     gothead1
	jmp	rerror
gothead1:

	mov	ah,09h			; write a period for each cylinder
	mov	dx,offset msgdot
	int	21h

        cmp     [Creating],'Y'
        je      docreate
;
;       This handles the case of comparing file info  to disk
;
        mov     cl,[noserial]
        or      cl,cl
        jz      CylSkip
        xor     ch,ch
        mov     bx,[StartSerial]
        mov     al,[cylinder]
CylLoop:
        cmp     cs:[bx],al
        je      Cylfound
CylReloop:
        add     bx,3                    ; for cylinder and offset
        loop    CylLoop
        jmp     CylSkip                 ; no on this track.....
Cylfound:
        push    cx
        push    es
        mov     es,[buffaddr]
        mov     di,word ptr [bx+1]
        mov     cx,10
        cmp     [Mos],'Y'
        je      CylFound1
        mov     cx,6
CylFound1:
        cld
        push    cx
        push    di
        push    si
        push    ds
        push    es
        push    es
        pop     ds
        push    cs
        pop     es
        mov     si,di
        lea     di,SerialVal
        rep     movsb
        pop     es
        pop     ds
        pop     si
        pop     di
        pop     cx
        mov     al,0ffh
        rep     stosb
        pop     es
        pop     cx
        jmp     CylReloop
        
CylSkip:
        call    calccrc
        mov     bl,[cylinder]
        xor     bh,bh
        shl     bx,1
        mov     ax,word ptr [acc]
        cmp     word ptr crc[bx],ax
        jne     jCompareErr
        jmp     donext
jcompareerr:
        jmp     CompareErr
docreate:
;
;       This handles the case of creating file info
;
        call    SearchIt
        cmp     [SavOff],0
        je      SkipOffset
        push    di
        push    es
        mov     di,[StartSerial]
        mov     al,[cylinder]
        mov     cs:[di],al                      ; store cylinder into struc
        mov     ax,[SavOff]
        mov     cs:[di+1],ax                    ; store offset into struc
        add     [StartSerial],3                 ; point to next struc
        inc     [noserial]
        mov     es,[buffaddr]
        mov     di,[SavOff]
        mov     cx,10
        cmp     [Mos],'Y'
        je      CreatMos
        mov     cx,6
CreatMos:
        mov     al,0ffh
        rep     stosb
        pop     es
        pop     di
SkipOffset:
        call    CalcCrc
        mov     bl,[cylinder]
        xor     bh,bh
        shl     bx,1
        mov     ax,word ptr [acc]
        mov     word ptr crc[bx],ax
donext:

	inc	[cylinder]
	cmp	[threehalf],'Y'
	je	its80
        cmp     [onedottwo],'Y'
        je      its80
;	cmp	[cylinder],40
	cmp	[cylinder],39
	jmp	its40
its80:
;	cmp	[cylinder],80
	cmp	[cylinder],79
its40:
        jae     found
	jmp	nextcyl
found:
	

	jmp	alldone

werror	label	near
	mov	dx,offset msgwerr
	mov	ah,9
	int	21h
	jmp	alldone

CompareErr:
        mov     dx,offset cerr
        mov     ah,9
        int     21h
        mov     ax,4cffh
        int     21h
        jmp     alldone

rerror	label	near
	mov	dx,offset msgrerr
	mov	ah,9
	int	21h
	jmp	alldone

alldone	label	near
;	int	20h
	ret
searchdisk	endp

SearchIT proc	near
        mov     [SavOff],0              ; if 0 then this mean no serial # 
	push	ds    
                        ; found!
        cmp     [onedottwo],'Y'
        jne     s1
	mov	cx,30*512
        jmp     s2
s1:
	mov	cx,18*512
s2:   
        mov	ds,[buffaddr]
	cld
	xor	di,di
BadSearch:
	mov	si,di
SearchLoop:
	mov	bx,offset Search
	cmp	byte ptr cs:[Mos],'Y'
	je	SearchA
	mov	bx,offset Search1
SearchA:
	lodsb
	dec	cx
	jnz	SearchCheck
	jmp	NotToday
SearchCheck:
	cmp	al,byte ptr cs:[bx]  		
	jne	SearchLoop
	mov	di,si
	lodsw
	cmp	ax,word ptr cs:[bx+1]		 
	jne	BadSearch
	lodsw
	cmp	ax,word ptr cs:[bx+3]		 
	jne	BadSearch
	dec	di
	pop	ds
	mov	[SavOff],di
	mov	al,[cylinder]
	mov	[SavCyl],al
	clc
	mov	al,'0'
        cmp     [onedottwo],'Y'
        jne     sc1
      	cmp	di,15*512
        jmp     sc2
sc1:
	cmp	di,9*512
sc2:
	jb	SHead0
	inc	al
SHead0:
	mov	[VHead],al
	mov	al,[SavCyl]
	mov	[VCyl],'0'
SCylLoop:
	cmp	al,10
	jb	SCyl1
	inc	[VCyl]
	sub	al,10
	jmp	short SCylLoop
SCyl1:
	add	al,'0'
	mov	[VCyl+1],al
	mov	ax,[SavOff]
	and	ax,511
	mov	word ptr [Voff],'00'
	mov	byte ptr [Voff+2],'0'
SOffLoop:
	cmp	ax,100
	jb	Soff1
	inc	[VOff]
	sub	ax,100	
	jmp	short SoffLoop
Soff1:
	cmp	ax,10
	jb	Soff2
	inc	[VOff+1]
	sub	ax,10
	jmp	short Soff1
Soff2:
	add	al,'0'
	mov	[VOff+2],al
	mov	ax,[SavOff]
	cmp	[VHead],'0'
	je	STrack
        cmp     [onedottwo],'Y'
        jne     sof1
	sub	ax,15*512
        jmp     STRack
sof1:
	sub	ax,9*512
STRack:
	mov	al,ah
	shr	al,1
	inc	al
	add	al,'0'
	mov	[VTrack],al	

d1:
	mov	dx,offset MsgFound
	mov	ah,9
	int	21h

x1:
	ret
NotToday:
	pop	ds
	stc
	ret
SearchIT endp




EntryPnt:
;	Disp	Begin,beginlen
	call	getparms
	cmp	[error],'Y'
	je	exitprog
        disp    tsl,tsllen
	cmp	[creating],'Y'
	jne	ccompare
	call	create 
	jmp	exitprog
ccompare:
	call    compare
         cmp    [SerialVal],'$'
	 je     ExitProg
	 lea    dx,SerialMsg
         mov    ah,9
         int    21h
         disp   crlf,2
ExitProg:
	 mov	ax,4c00h
	 int	21h

progend	label	near

 codeseg ENDS

         END     start
