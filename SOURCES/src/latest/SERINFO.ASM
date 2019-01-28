	title	serinfo - serial dump program
comment ^===============================================================
		      development specification

 program name:	serinfo.asm			assigned to: stewart hyde
 module name:	serinfo				assign date: 10/07/91
 entry points:	serinfo				completed:   10/07/91
 entry from:	command processor
 entry method:	
 calls: 
 purpose:	serial dump program
 refer to:	stewart hyde
 last update:	09/16/92
-------------------------------------------------------------------------
 SAH	11/26/91	max out high bit on port  address 

 SAH    04/01/92	update copyright

 SAH    09/16/92	Corrections for Inteligent Serial systems
=========================================================================^

codeseg SEGMENT

         ORG     0100h
         ASSUME  CS:CODESEG

start:
	jmp	 EntryPnt


Intro	 db	'PC-MOS Serial Information Version 1.01 (920916)        ',13,10    ; @@XLAT@@
	 db	'Copyright 1991,1992 The Software Link, Incorporated.',13,10
	 db	'All Rights Reserved Worldwide',13,10,10
d_hdr    db   ' PORT       AD      IB      OB    '
         db   'HS    IN  CN    IF   OF    UART TYPE'
         db   13,10,'$'

d_detail  db  ' COM'
d_pnum_1  db  '?'               ;port number first (or only) digit
d_pnum_2  db  '?'               ; port number second digit (or colon)
d_pnum_3  db  '?'               ; blank (or colon)
          db  '   $'

HSNone	 db	'*NONE*'	

d_bstart  label	byte		
d_ad      db  '????'            ; port address (in hex)
          db  '   '
d_ib      db  '?????'           ; input buffer size
          db  '   '
d_ob      db  '?????'           ; output buffer size
          db  '  '
d_hs      db  '??????'             ; handshaking info
          db  '  '
d_inhi	  db  ' '
d_in      db  '?'               ; interrupt level
          db  '   '
d_cn      db  '?'               ; connection type
          db  '    '
d_if      db  '??'              ; receive fifo threshhold
          db  '   '
d_of      db  '??'              ; transmit fifo burst size
          db  '    '

d_bend    label byte            ; end of area to be blanked out
          db  '$'

MaxFun	  db	0
Port	  dw	0
SerName	  dd	0

NoInfo	  db	'- Information for port not available -$'
NonSpec	  db	'Non-Specific Serial Driver              '
NoVal	  db	'no'	

Driver	  db	'==== Driver: $'

SerialTab  label word
	 dw	offset None
	 dw	offset M8250B
	 dw	offset M16450
	 dw	offset M16550
	 dw	offset M16550A
	 dw	offset special

None	db	'**NONE**$'
M8250B  db	'8250B$'
M16450	db	'8250A/16450$'
M16550	db	'16550$'	
M16550A	db	'16550A$'
Special db	'Inteligent$'

crlf	db	13,10,'$'

prstruc	struc	
pirec_ad     dw	   0
pirec_ib     dw    0
pirec_ob     dw    0
pirec_in     db    0
pirec_cn     db    0
pirec_hs     db    0
pirec_xxon   db    0
pirec_rxon   db    0
pirec_xxoff  db    0
pirec_rxoff  db    0
pirec_if     db    0
pirec_of     db    0
pirec_uart   db    0

prstruc	ends	

pr	prstruc	<>

HSLetter db	'xXdrDR'

EntryPnt:
	mov	dx,offset Intro
	mov	ah,9
	int	21h
PortLoop:
	mov	ah,6
	mov	dx,[Port]
	int	14h
	cmp	ah,0ffh
	je	ExitPort
	and	ah,80h
	jz	ExitPort
	mov	[MaxFun],al		 
	call	DumpPort		
NextPort:
	inc	[Port]	      		; bump to next port
	jmp	short PortLoop
ExitPort:	
	mov	ax,4c00h
	int	21h

DumpPort proc	near
	mov	ax,cs
	mov	bx,offset NonSpec
	cmp	[MaxFun],18
	jb	DP1
	mov	dx,[Port]
	mov	ah,18
	int	14h
	mov	ax,ds
DP1:
	cmp	ax,word ptr [SerName+2]
	je	DP2
	mov	word ptr [SerName],bx
	mov	word ptr [SerName+2],ax
	push	ax
	push	bx
	push	cs
	pop	ds
	mov	dx,offset Driver
	mov	ah,9
	int	21h
	pop	bx
	pop	ax
	cld
	mov	ds,ax
	mov	si,bx
	mov	cx,40
DP1Loop:
	lodsb
	mov	dl,al
	mov	ah,2
	int	21h
	loop	DP1Loop
	push	cs
	pop	ds
	mov	dx,offset crlf
	mov	ah,9
	int	21h
DP2:	
	mov	ax,[Port]
	inc	al
	
	cmp	al,10
	jae	dp3
	mov	[d_pnum_2],':'
	mov	[d_pnum_3],' '
	add	al,'0'
	mov	[d_pnum_1],al
	jmp	short DP4
DP3:
	mov	[d_pnum_3],':'
	mov	ah,'0'
DP3Loop:
	cmp	al,10
	jb	DP3low
	sub	al,10
	inc	ah
	jmp	short DP3Loop
DP3Low:
        mov	[d_pnum_1],ah
	add	al,'0'
	mov	[d_pnum_2],al	
DP4:
	push	cs
	pop	ds
	mov	dx,offset d_detail
	mov	ah,9
	int	21h

	cmp	[MaxFun],24
	jae	DP5
	mov	dx,offset NoInfo
	mov	ah,9
	int	21h
	jmp	DPExit
DP5:
	mov	dx,[Port]
	mov	ah,24
	mov	cx,type(prstruc)
	mov	bx,offset PR
	push	cs
	pop	es
	int	14h
	mov	ax,PR.pirec_ad
	and	ax,07fffh			; mask out high bit
	lea	bx,d_ad+3
	call	bintohex
	mov	ax,word ptr [NoVal]
	mov	word ptr [d_inhi],ax
	mov	al,PR.pirec_in
	cmp	al,0ffh
	je	DP6a
	mov	[d_inhi],' '
	cmp	al,10	
	jb	DP6
	mov	[d_inhi],'1'
	sub	al,10
DP6:
	add	al,'0'
	mov	[d_in],al
DP6a:
	mov	al,PR.pirec_cn
	mov	[d_cn],al
	mov	al,PR.pirec_hs
	call	DecodeHS
	mov	al,PR.pirec_if
	or	al,al
	jnz	DP7
	mov	ax,word ptr [NoVal]
	mov	word ptr [d_if],ax
	jmp	short DP8
DP7:
	call	Format2
	mov	word ptr [d_if],ax
DP8:
	mov	al,PR.pirec_of
	cmp	al,1
	ja	DP9
	mov	ax,word ptr [NoVal]
	mov	word ptr [d_of],ax
	jmp	short DP10
DP9:
	call	Format2
	mov	word ptr [d_of],ax
DP10:
        mov     di,offset d_ob+4         ;Point at last digit
        mov     ax,PR.pirec_ob
        call    format_dec               ;Make it printable

        mov     di,offset d_ib+4         ;Point at last digit
        mov     ax,PR.pirec_ib
        call    format_dec               ;Make it printable


	mov	dx,offset d_bstart
	mov	ah,9
	int	21h	

	xor	bx,bx
	mov	bl,PR.pirec_uart
	cmp	bl,4
	jbe	DPUart
	mov	bl,5
DPUart:
	shl	bx,1
	mov	dx,word ptr [bx+SerialTab]
	mov	ah,9
	int	21h

DPExit:
	mov	dx,offset crlf
	mov	ah,9
	int	21h
	ret
DumpPort endp

Format2 proc	near
	mov	ah,' '
	cmp	al,10
	jb	F2
	mov	ah,'1'
	sub	al,10
F2:
	add	al,'0'
	xchg	al,ah
	ret
Format2 endp	

format_dec  proc near
	 push	di
	 push	cx
	 mov	cx,6
fdeclp:
	 mov	byte ptr [di],' '
	 dec	di
	 loop	fdeclp	 
	 pop	cx
	 pop	di
         push dx                ; save work regs
         push bx
         mov  bx,10             ; divisor

format_dec1:
         xor  dx,dx             ; zap the high half
         div  bx                ; extract lowest digit into dx
         add  dl,'0'            ; ascii-ize
         mov  [di],dl           ; store it
         dec  di                ; point to prior char
         cmp  ax,0              ; any more digits?
         jnz  format_dec1          ; yes: process them

         pop  bx                ; restore regs
         pop  dx
         ret

format_dec endp

DecodeHS proc	near
	or	al,al
	jnz	DHS1
	mov	ax,word ptr [HSNone]
	mov	word ptr [d_hs],ax
	mov	ax,word ptr [HSNone+2]
	mov	word ptr [d_hs+2],ax
	mov	ax,word ptr [HSNone+4]
	mov	word ptr [d_hs+4],ax
	ret	 
	 
DHS1:
	mov	word ptr [d_hs],2020h
	mov	word ptr [d_hs+2],2020h
	mov	word ptr [d_hs+4],2020h
	mov	cx,6
	xor	si,si
	mov	di,offset [d_hs]
	mov	bx,1
DHSLoop:
	push	cx
	mov	cx,bx
	test	al,cl
	jz	DHSSkip
	mov	ah,byte ptr [si+HSLetter]
	mov	byte ptr [di],ah
	inc	di
DHSSkip:
	inc	si
	shl	bx,1
	pop	cx
	loop	DHSLoop
	ret
DecodeHS endp

;------------------- binary-to-hexadecimal routine ------------------;
hextable db    '0123456789ABCDEF'

bintohex proc
	push  si
	mov   dl,4
bthloop1:
	mov   si,ax
	and   si,000fh
	mov   cl,[hextable+si]
	mov   [bx],cl
	mov   cl,4
	shr   ax,cl
	dec   bx
	dec   dl
	jg    bthloop1
	pop   si
	ret
bintohex endp



EndOfProg LABEL BYTE

codeseg ENDS

         END     start
