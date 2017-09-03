	include	page.inc
	title HDSETUP.ASM - the MOS Hard disk setup utility

;*****************************************************************************
;*                                                                           *
;*                        MOS Development Specification                      *
;*                                                                           *
;* Command type: External		Assigned to: Jeffrey S. Weyrich	     *
;* Command name: HDSETUP.COM		Date assigned: 11/20/86		     *
;*					Date completed: 12/23/86	     *
;* Command format: HDSETUP						     *
;* Purpose: Define logical disks on a single physical fixed disk	     *
;* Refer to: Nothing							     *
;* Last Update:	1/6/87,1/8/87			By: JSW			     *
;*              3/2/87				    BMW                      *
;*		 Went through and changed the references to partitions to    *
;*		logical disks as well added routines in create.asm to handle *
;*		disk larger than 32 meg.				     *
;*									     *
;*									     *
;* *** NOTE *** the module CREATE MUST be last one linked to make HDSETUP.COM*
;* other necessary files are MBRDEF.INC and MBR.INC. You must also use the /s*
;* option on the masm command line for assembling hdsetup.asm		     *
;*									     *
;*	External		Values			Values		     *
;*	routines		passed			returned	     *
;* --------------------------------------------------------------------------*
;* 	Create			None			None		     *
;*	Activate		 "			 "		     *
;*      Dactivate		 "			 "		     *
;*	Delete			 "			 "		     *
;*	Display			 "			 "		     *
;*	ChangeFD		 "			 "		     *
;* --------------------------------------------------------------------------*
;*									     *
;*				     HDSETUP				     *
;*									     *
;*	This command builds the logical disk layout by determining the number*
;* of cylinders on the disk for which it is intended. HDSETUP can access two *
;* physical fixed disks on a system for it must interrogate the cmos ram if  *
;* an AT or 386 machine or get a bpb from the device driver to garner the nec*
;*essary information. HDSETUP is menu driven and shows default choices in the*
;* prompts.								     *
;*									     *
;* MOS commands will use the same segment grouping as the MOS kernel. This   *
;* file is a template as is MOSSHELL.ASM. Except that its designed for use i *
;* commands, both internal and external, for MOS. See MOSSHELL.ASM for de-   *
;*tails. The commands should not need to go into as much detail as the kernel*
;*does in keeping track of end of segment pointers in the INC files and such.*
;*Our desire is to maintain the same coding standards thruout MOS and to use *
;*code modularity as much as possible. So, use the same group labels in any  *
;* routine to keep the code and data segments in the same segment.	     *
;*                                                                           *
;*****************************************************************************
;  4/28/87    BMW  modified calculatiion at $c7 to add high word of total of ;
;             sectors in previous partitions to the total number of hidden   ;
; 	      sectors in current partition.				     ;
;----------------------------------------------------------------------------;
;  4/28/87    BMW modified add lmul and ldiv to handle larger disk capacities;
;             example: 1023*ff(heads)*022h(spt) gives a double word operater ;
; 	      as product of the first equation and would otherwise not be    ;
;	      handle correctly in the second equation.			     ;
;----------------------------------------------------------------------------;
;  5/12/87    RBR  Clean up messages 					     ;
;----------------------------------------------------------------------------;
;  5/15/87    BMW  edited the create procedure so that the defaulting to the ;
;             prompts will give the user multiple 32 meg partitions until    ;
;	      the disk is used up or it makes four partitions.		     ;
;----------------------------------------------------------------------------;
;  6/30/87    RBR  Changed method of finding number of hard disks so that    ;
;	      it works on the PS/2 Model 80. Corrected the assumption that   ;
;	      all hard disks have 17 sectors per track. Fixed invalid        ;
;	      occurrence of message saying that you didn't specify enough    ;
;	      cylinders for a logical disk.				     ;
;*****************************************************************************
;* 11-3-87    JSW Fixed writembr to handle writing the master boot record to *
;*	      the correct fixed disk if there are 2 fixed disks in the system*
;*            Upped the version number to 1.02. Fixed ChangeFD so that the ap*
;*	      prorpiate drive is called when the user changes fixed disks.   *
;*****************************************************************************
; 12/15/87    JSM  modified do_32meg_vols code to deal properly with hard    ;
;             disks smaller than 32 megabytes.  Also made sure that the lz   ;
; 	      variable ALWAYS has a value of zero.  Revision mark jsm1.	     ;
;----------------------------------------------------------------------------;
; 03/02/88    RBR  Cleanup of some incomprehensible code with a general      ;
;             goal of dealing with the 2nd hard drive in the same way that   ;
; 	      we deal with the 1st one.                                	     ;
;----------------------------------------------------------------------------;
; 08/16/88    SAH Correct problems with DOS 3.3X extented partitions	     ;
;	      Corrected bug if small partition was allocated after large     ;
;	      partition.  Cleanup module.				     ;
;----------------------------------------------------------------------------;
; 11/03/88    RKG Changes for easier foreign language translation	     ;
;----------------------------------------------------------------------------;
; 12/06/88    RKG006 Hidden was not decremented during deletions.  I doubt   ;
;	      hidden is correct unless deleting all partitions.		     ;
;----------------------------------------------------------------------------;
; 01/18/89    Cosmetic corrections from translations			     ;
;----------------------------------------------------------------------------;
; 02/21/89    SAH   Masm 5.10 Compatibility				     ;
;----------------------------------------------------------------------------;
; 05/19/89    SAH   Re done appearence with online onhelp for installation   ;
;	      program. Added undocumented /D option for installed to set up  ;
;	      messages for Dual MOS and DOS enviroments.  Also corrected bug ;
;	      where default responce to large volume request was invalid.    ;
;	      Undocumented /N is use by install for messages for new system. ;
;----------------------------------------------------------------------------;
; 07/11/89    SAH   Corrected Create Multi-32 making sure it did not clear   ;
;	      the bottom 2 entries for partition information.		     ;
;----------------------------------------------------------------------------;
; 08/18/89    SAH    Correction for Install - via new automatic guidethough  ;
;----------------------------------------------------------------------------;
; 11/27/89    BWR    Messages marked for foreign language translation.	     ;
;----------------------------------------------------------------------------;
; 01/10/90    JRB    Corrections for PSI drive.	Boot sector not being set    ;
;		     correctly if never set intialialy.			     ;
;----------------------------------------------------------------------------;
; 8/7/80      BWR    The Evaluation disk is now called SYSTEM.               ;
;----------------------------------------------------------------------------;
	include	mbrdef.inc

ROM	equ	0f000h		; rom
FORTY	equ	40h		; bios data segment
ZERO	equ	0
TRUE	equ	0FFFFh		
FALSE	equ	0000h
DEBUG	equ	0   		; turn debuging on


grp	group	moss,gdata,bootseg	; use gdata to define any global data.

gdata	segment word public 'code'
gdata	ends

	include hdsetup.pub

	page
moss	segment	word public 'code'

romb	segment at 0f000h
	org	0fff0h
	here	label	far
romb	ends

	assume cs:grp;ds:grp;es:grp,ss:grp

	org	100h

hdsetup	proc	near
	jmp	begin
	db	26

;*****************************************************************************
;*				      MENUS				     *
;*									     *
;* 	1st byte - attribute, 2nd column, 3rd row, remainder is menu	     *
;*									     *
;*****************************************************************************

mainbox db	1fh,0,0
	db	'ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป'
	db	'บ                     PC-MOS Hard Disk Setup Program v4.00                     บ' ;@@XLAT
	db	'บ        (c) Copyright 1987, 1988, 1989 The Software Link, Incorporated        บ' ;@@XLAT
	db	'ฬออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน'
	db	0ffh

midbar1 db	1fh,0,4
	db	'บ'
	db	0ffh
midbar2 db	1fh,79,4
	db	'บ'
	db	0ffh


helpbox db	1fh,0,18
	db	'ฬออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน'
	db	'บ                                                                              บ'
	db	'บ                                                                              บ'
	db	'บ                                                                              บ'
	db	'บ                                                                              บ'
	db	'บ                                                                              บ'
	db	'ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ'
	db	0ffh

main1	db	3,8,5,'                  Options for Hard Disk  ' ;@@XLAT
fdn	db	'1'
	db	0ffh

main3	db	02,5,7
	db	'                 <1> Create a MOS logical disk.                 ',0ffh ;@@XLAT
main3a	db	02,5,8
	db	'                 <2> Activate a logical disk.                   ',0ffh ;@@XLAT
main3b	db	02,5,9
	db	'                 <3> De-activate a logical disk.                ',0ffh ;@@XLAT
main3c	db	02,5,10
	db	'                 <4> Delete a logical disk.                     ',0ffh ;@@XLAT
main3d	db	02,5,11
	db	'                 <5> Display logical disk information.                   ',0ffh ;@@XLAT
main3e	db	02,5,12
	db	'                 <6> Change to next hard disk.                  ',0ffh ;@@XLAT
main3f	db	02,5,13
	db	'                 <7> Exit to the Operating System.              ',0ffh ;@@XLAT
main3g	db	02,5,14
	db	'                 <8> Exit with NO CHANGES.                      ',0ffh	 ;@@XLAT
main4	db	03h,22,16
	db	'Enter your choice or press ENTER   ' ;@@XLAT
	db	0ffh

main5	db	0fh,58,16
	db	'<',0ffh

choice	db	070h,59,16		; reverse video
	db	'1',0ffh

main5a	db	0fh,60,16
	db	'>',0ffh

bootmsg	db	'The system must now be rebooted!!         ',13,10 ;@@XLAT
	db	'Insert system diskette into drive A: and press the               ',13,10 ;@@XLAT
	db	'Ctrl, Alt, and Del keys simultaneously!                         ',13,10,36 ;@@XLAT

boot_sys db     'The system must now be rebooted to continue on with install!!          ',13,10 ;@@XLAT
         db     'Please make sure the SYSTEM disk is in drive A: and press the          ',13,10 ;@@XLAT
         db     'CTRL, ALT and DEL keys simultaneously.                                 ',13,10,36 ;@@XLAT

nofd	db	13,10,'No fixed disks are present.       ',13,10,36 ;@@XLAT
crlf	db	13,10,36
cursor	dw	0607h

;
; The following data is use control message database staging, since system can
; be either use for installing NEW and DUAL system there is 2 tables for
; controlling messages.
;

helpflg db	'A'		; N for New, D for Dual, or A for Activate
reply	db	'N'		; use in auto-installation logic
autoins db	'N'		; are we using auto-installation logic
force	db	'N'		; force help system for message

msg1a	db	'CAUTION!   If you choose YES any existing DOS EXTENDED partitions will $' ;@@XLAT
msg1b	db	'           be saved but, will be inaccessable by PC-MOS.               $' ;@@XLAT
msg1c	db	'                                                                       $'
msg1d	db	'WARNING!   If you choose NO all existing partitions will be destroyed. $' ;@@XLAT
msg1e	db	'           Choose NO to continue with hard disk setup.                 $' ;@@XLAT

msg3a	db	'Answer: YES  To automatically assigned the entire hard disk to PC-MOS. $' ;@@XLAT
msg3b	db	'                                                                       $'
msg3c	db	'Answer: NO   To create multiple logical drives (up to 4)               $' ;@@XLAT
msg3d	db	'                                                                       $'
msg3e	db	'NOTE:        Logical disks larger than 32mb are inaccessable by DOS.   $' ;@@XLAT

msg7a	db	'                                                                       $'
msg7b	db	'Follow the on screen directions to create up to four logical drives.   $' ;@@XLAT
msg7c	db	'                                                                       $'
msg7d	db	'Please Note that 32mb is equal to ' ;@@XLAT
msgval  db      '     Cylinders.                     $' ;@@XLAT

help1	db	'40'
	dw	offset msg1a
        dw	offset msg1b
	dw	offset msg1c
        dw	offset msg1d
	dw	offset msg1e
	dw	0
help2	db	'41'
	dw	0
help3	db	'42'
	dw	offset msg3a
        dw	offset msg3b
	dw	offset msg3c
        dw	offset msg3d
	dw	offset msg3e
	dw	0
help4	db	'43'
	dw	0
help5	db	'44'
	dw	0	
help6	db	'45'
	dw	0
help7	db	'46'
	dw	offset msg7a
        dw	offset msg7b
	dw	offset msg7c
        dw	offset msg7d
	dw	0	
help8   db	'47'
	dw	0


;*****************************************************************************
;*			     Globals				      	     *
;*****************************************************************************

	even
cyls	dw	0
heads	dw	0
mbrs	dw	0
oldmbrs	dw	0
curdisk	db	0		; current physical drive being worked on
bootf	db	0		; flag to indicate a reboot
lz	db	0		; nz if landing zone <> cylinders - default
nfdisks	db	0		;Rod  Number of fixed disk drives
hrdoff	dw	0		; offset of hard drive number
wflags	db	0		;030288 bit 0 on = write 1, bit 1 = write 2

_devp	struc			; structure for old device parameters (dos3.20)
	_sf	db	0	; special function byte
	_dt	db	0	; device type
	_da	dw	0	; device attribute
	_nc	dw	0	; number of cylinders(tracks)
	_mt	db	0	; media type

; This is the bpb
	_bps	dw	0	; byte per sector
	_spc	db	0	; sectors / cluster
	_rs	dw	0	; reserved sectors (usually 1)
	_fc	db	0	; fat count
	_re	dw	0	; number of root directory entries
	_ts	dw	0	; total sectors
	_md	db	0	; media descriptor
	_spf	dw	0	; sectors/fat
;
	_spt	dw	0	; sectors/track
	_hc	dw	0	; head count
	_hs	dd	0	; hidden sectors
	_rsvd1	dd	0	; reserved 1
	_rsvd2	db	6 dup(0); reserved 2
_devp	ends

odevp	_devp	<>	; device parameter block

begin:
	call	GetOptions	; get options
	push	es		; first check f000:fffe to see if its an AT
	mov	ax,ROM
	mov	es,ax
	mov	al,byte ptr es:[0fffeh]
	pop	es

	assume	ds:grp,es:grp

	cmp	al,0fch		; AT or compatible?
	je	AnAt		; yes check CMOS for #of fixed disks, if any
	cmp	al,0f8h		;Rod  PS/2 model 80?
	je	AnAt		;Rod  Yes, jump 
	cmp	al,0fah		;Rod  PS/2 model 30?
	je	AnAt		;Rod  Yes, jump 

; right here should go code to get a bpb since we are not on an AT or 386

	mov	ax,440dh	; use extended i/o crtl call to get device info
	mov	bl,3		; use 3 for first hard disk
	mov	cx,0860h	; get device parms
	lea	dx,odevp
	int	21h
	jnc	$+5
	jmp	NoFixedDisks

	mov	[nfdisks],1	;Rod
	lea	bx,odevp	;Rod

	mov	ax,[bx+4]	; get cylinder count
	mov	[cyls],ax
	mov	ax,[bx+22]	; get head count
	mov	[heads],ax
	jmp	GotHDdata
AnAt:
	mov	ah,08h		;Rod  read drive parameters
	mov	dl,80h		;Rod
	int	13h		;Rod
	mov	al,dl		;Rod  number of fixed disks
	mov	[nfdisks],al	;Rod

	cmp	al,0
	jne	$+5
	jmp	NoFixedDisks	; there are none

	inc	byte ptr [curdisk] ; indicate there is a fixed disk

	push	ax
	push	es

	mov	al,cl		;Rod  save sectors per track
	and	ax,003fh	;Rod
	mov	[spt],ax	;Rod
	mov	[hidden],ax	;Rod
	mov	[hidden+2],0	;Rod
	mov	ax,cx		;Rod  Get number of cylinders
	xchg	al,ah		;Rod
	rol	ah,1		;Rod
	rol	ah,1		;Rod
	and	ah,3		;Rod
	inc	ax		;Rod
	mov	[cyls],ax	;Rod

	mov	al,dh		;Rod  Number of heads
	inc	al 		;Rod

	xor	ah,ah
	mov	[heads],ax	; save it
	pop	es
	pop	ax

GotHDdata:
	mov	bx,cs		; calculate the segment address of new mbr
	mov	ax,offset grp:bootseg
	mov	cl,4
	shr	ax,cl
	add	bx,ax
	mov	[mbrs],bx	; saved segment address
	add	bx,64		;add paragraphs to make sure we don't conflict
				; with new MBR
	mov	[oldmbrs],bx	; saved segment address
	call	readmbr		; TRY TO READ A mbr SECTOR INTO OLD MBR SEG
	mov	ax,0600h
	mov	bx,0007
	xor	cx,cx
	mov	dx,184fh
	int	10h
	mov	ah,2
	xor	dx,dx
	mov	bh,0
	int	10h		; clear the screen and put cursor at 0,0
	lea	bp,mainbox	; paint main screen header
	call	writescr
	push	cx
	mov	byte ptr [midbar1+2],4
	mov	byte ptr [midbar2+2],4
	mov	cx,14
midloop:
	push	cx
	lea	bp,midbar1
	call	writescr
	lea	bp,midbar2
	call	writescr
	pop	cx
	inc	byte ptr [midbar1+2]
	inc	byte ptr [midbar2+2]
	loop	midloop
	pop	cx
	lea	bp,helpbox
	call	writescr

	mov	di,offset msg32+3	; calculate display positions
	call	findansw
	inc	al		; returns length til '<'
	add	al,[msg32 + 1]	; add base of message
	mov	[res32a+1],al
	inc	al		; update display positions
	mov	[res32b+1],al
	
	mov	di,offset crt2+3	; same for next display
	call	findansw
	inc	al
	add	al,[crt2 + 1]	; add base of message
	mov	[answer+1],al
	inc	al
	mov	[crt3+1],al

	cmp	[helpflg],'N'
	je	doauto
	cmp	[helpflg],'D'
	jne	mainmenu
doauto:
	call	auto
	jmp	quit	

mainmenu:
	mov	[choice+3],31h	; reset the default
	call	doMain		; put up the main menu

getChoice:
	mov	ah,2		; position the cursor to the prompt
	xor	bx,bx
	mov	dx,word ptr [choice+1]
	int	10h
	call	conin		; get their menu choice & process
	jnc	NoEsc		; no carry means they didn't hit ESC
	jmp	quit

NoEsc:
	cmp	al,0dh		; did they hit a carriage return
	jne	chk1		; no, see if they hit a 1
	call	create
	jmp	mainmenu
chk1:
	cmp	al,31h		; how about the number 1
	jne	chk2		; no? check for a 2
	call	create		; yes create a partition
	jmp	mainmenu	; do it again

chk2:
	cmp	al,32h		; do they wish to activate a partition
	jne	chk3		; no, check for delete a partition
	mov	[choice+3],32h
	lea	bp,choice
	call	writescr
	call	activate	; yes
	jmp	mainmenu
chk3:
	cmp	al,33h		; how about de-activate a partition
	jne	chk4		; nope, better see if they hit a 4
	mov	[choice+3],33h
	lea	bp,choice
	call	writescr
	call	dactivate	; yup
	jmp	mainmenu

chk4:
	cmp	al,34h		; better see if they want to delete a partition
	jne	chk5
	mov	[choice+3],34h
	lea	bp,choice
	call	writescr
	call	delete
	jmp	mainmenu

chk5:
	cmp	al,35h		; how about checking the partition data
	jne	chk6
	mov	[choice+3],35h
	lea	bp,choice
	call	writescr
	call	display
	jmp	mainmenu

chk6:
	cmp	al,36h	     ;ok, do they want to play with a 2nd fixed disk
	jne	InputBooboo
	mov	[choice+3],36h
	lea	bp,choice
	call	writescr
	call	changeFD
	jmp	mainmenu

InputBooboo:			; they hit something wrong, so flog em
	call	bell
	jmp	getChoice

quit:
	mov	ax,0600h
	mov	bx,0700h
	xor	cx,cx
	mov	dx,184fh
	int	10h
	mov	ah,2
	xor	dx,dx
	mov	bh,0
	int	10h		; clear the screen and put cursor at 0,0

	cmp	[bootf],0
	je	q1
        lea     dx,boot_sys
	cmp	[helpflg],'A'	; check for install version	
	jne	q0	
	lea	dx,bootmsg
q0:
	call	print
	call	writeMBR
	
	sti

if	DEBUG
else
	jmp	$
endif

q1:
	ret			; exit to O/S

NoFixedDisks:
	lea	dx,nofd
	call	print
	jmp	quit

print	label near
	mov	ah,9
	int	21h
	ret

writescr proc near
	mov	ah,2
	mov	bh,0			; display page
	mov	dx,[bp+1]
	int	10h			; position the cursor
	mov	bl,byte ptr [bp]	; get attribute
	add	bp,3			; point to first char

wloop:
	mov	al,[bp]
	cmp	al,0ffh
	je	wloop1
	mov	ah,9
	mov	cx,1
	int	10h
	mov	ah,2
	inc	dx			; advance cursor position
	cmp	dl,50h
	jb	wsetdl
	xor	dl,dl
	inc	dh
wsetdl:
	int	10h
	inc	bp
	jmp	wloop
wloop1:
	ret
writescr endp

conin	proc	near
	mov	ah,0
	int	16h
	cmp	al,37h
	je	setc
	cmp	al,38h
	jne	good_ch
	mov	[bootf],0
	jmp	short setc	
good_ch:
	clc
	ret
setc:
	stc
	jmp	setc-1
conin	endp

doMain	proc	near
	lea	bp,main1
	call	writescr
	lea	bp,main3
	call	writescr
	lea	bp,main3a
	call	writescr
	lea	bp,main3b
	call	writescr
	lea	bp,main3c
	call	writescr
	lea	bp,main3d
	call	writescr
	lea	bp,main3e
	call	writescr
	lea	bp,main3f
	call	writescr
	lea	bp,main3g
	call	writescr
	lea	bp,main4
	call	writescr
	lea	bp,main5
	call	writescr
	lea	bp,choice
	call	writescr
	lea	bp,main5a
	call	writescr
	ret
doMain	endp

bell	label near
	mov	ax,0e07h
	xor	bh,bh
	int	10h
	ret

pscroll	proc

	push	ax
	push	bx
	mov	al,dh
	sub	al,ch
	inc	al
	mov	ah,06h
	mov	bx,0700h	; the header intact
	int	10h
	clc			; clear the carry so gdisp doesn't return invalid info
	pop	bx
	pop	ax
	ret

pscroll	endp

; The following routine is use to clear the screen (working window)

cls	proc	near
	mov	cx,0401h
	mov	dx,114eh
	call	pscroll 	; do partial screen scroll from 4,1 to 17,79
	ret
cls	endp
		      

; following routine is use to display help messages in help window


dohelp	proc	near
	cmp	[force],'Y'		; is message forcement in place
	je	conthelp	
	cmp	[helpflg],'A'
	jne	conthelp
	ret
conthelp:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	ds

	push	cs
	pop	ds

	mov	bx,dx
	cmp	[helpflg],'A'	; skip Install screen # for normal case
	je	dohelp2
	push	bx
	mov	si,bx
	mov	dx,014ah
	mov	ah,2
	mov	bx,1fh
	int	10h
	mov	al,'1'
	cmp	byte ptr [helpflg],'D'
	jne	dohelp1
	mov	al,'3'
dohelp1:
	mov	ah,0eh		
	int	10h
	mov	ah,0eh
	mov	al,'.'
	int	10h
	mov	al,byte ptr [si]
	mov	ah,0eh		
	int	10h
	mov	al,byte ptr [si+1]
	mov	ah,0eh		
	int	10h
	pop	bx
dohelp2:
	inc	bx
	inc	bx

	push	bx
	mov	ax,0600h		; clear help window
	mov	bh,1fh
	mov	cx,1301h
	mov	dx,174eh
	int	10h
	pop	bx

	mov	dx,1302h
	or	bx,bx
	jz	dohdone
dohloop:
	cmp	word ptr [bx],0 	; end of message
	je	dohdone
	push	bx
	push	dx

	push	bx
	mov	ah,2
	xor	bh,bh
	mov	bl,1fh			; set cursor position for message
	int	10h
	pop	bx
	mov	si,word ptr [bx]
dohlp:
	lodsb				; get byte pf message
	cmp	al,'$'
	je	dohend
	mov	ah,0eh
	int	10h			; display it in window
	jmp	short dohlp
dohend:

	pop	dx
	pop	bx
	inc	bx
	inc	bx
	inc	dh
	jmp	short dohloop
dohdone:

	pop	ds
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
dohelp	endp


; the following routine is use to get options from user command line

GetOptions proc near
	push	si
	mov	si,81h
	cld
GOloop:
	lodsb
	cmp	al,0dh	    ; are we done
	je	GOdone
	cmp	al,0ah	    ; are we done
	je	GOdone
	cmp	al,'/'	    ; option?
	je	GOdo
	cmp	al,'-'	    ; unix style is ok
	jne	GOloop	    ; invalid
GOdo:
	lodsb
	and	al,0dfh
	cmp	al,'N'	    ; is this for new system
	je	GOset
	cmp	al,'D'	    ; is dual operation system option
	jne	GOloop
GOset:
	mov	[helpflg],al	; set dual mode
	jmp	short GOloop
GOdone:
	pop	si
	ret
GetOptions endp
;********************* binary-to-decimal routine ********************;

bin2dec proc  near
	push  cx
btdloop1:
	div   [w10]		; dx:ax is source integer
	add   dl,'0'		; cx is length of target
	mov   [bx],dl		; bx is end of target
	dec   bx
	xor   dx,dx
	loop  btdloop1
	pop   cx
btdloop2:
	inc   bx
	dec   cx
	jz    btdret
	cmp   byte ptr [bx],'0'
	jne   btdret
	mov   byte ptr [bx],' '
	jmp   btdloop2
btdret:
	ret

w10	dw	10
bin2dec endp

; The following procedure is for handling automatic processing of
; hdsetup information for install program. This has been modified so
; that it requires min-user intervention.
;
; Basic ideas
;
; 1.	Check MBR for existence of any partitions
; 2.	If partitions don't exits goto step 6
; 3.	Ask user if they want to keeps these partitions
; 4.	if User does not wish to keep partitions then goto step 7
; 5.	Delete all existing partitions on system
; 6.	Create partitions
; 7.	if all partitions are active goto step 11
; 8.	ask user if he wants to activate all partitions
; 9.    if user does not want to activate all partitions then goto step 11
; 10.	Activate all partitions
; 11.   if disk information has not been change go to step 14
; 12.	reset disk information
; 13.	ask user to ctrl-alt-del
; 14.	exit program
;


auto	proc	near
	mov	[autoins],'Y'		; indicate that we are in auto-install
;
;	Check MBR for existence of any partitions
;
	mov	es,cs:[mbrs]
	mov	di,MBRPTAB		; es:di address master disk boot rec
	call	Chk4Mos
	jz	auto6			; if no partitions goto step 6
;
;	now we must disp current partitions and ask use if he wants
;	to keep these partitions 
;
	lea	dx,help1
	call	dohelp
	call	$disp1			; display partion information	
	cmp	[reply],'Y'
	je	auto7
;
;	Now we must clean out partition table so that it will be a clean
;	plate for creating new partitions
;
	mov	es,cs:[mbrs]
	mov	di,MBRPTAB		; es:di address master disk boot rec
	mov	cx,MBRPLEN*2
	cld
	xor	ax,ax
	rep	stosw			; clear out all partitions
;
;	At this point all partitions are remove and we can now create 
;	new partitions
;	
auto6:
;
;	at this point partitions have been created and we should activate
;
 	call	Create		
auto7:
	mov	[autoins],'A'	; indicate auto install - active
	mov	es,cs:[mbrs]
	mov	di,MBRPTAB		; es:di address master disk boot rec
	add	di,MBRPLEN
;
;	if using dual MOS and DOS make sure that drive D is force active
;	
	mov	[ActDrive],'2'
	cmp	[helpflg],'D'
	jne	auto11
	mov	[ActDrive],'3'
	or	byte ptr es:[di+MBRBI],80h	; make D active
auto11:
	ret
auto	endp

writembr proc near			; this proc writes mbrs to disk

if	DEBUG
	ret
endif

	push	es			; -\
	push	ds			; ---\  save out registers used to
	push	si			; ---/	move the MBRs into place!
	push	di			; -/

	mov	di,200h			;030288
	cmp	[curdisk],2		; see which drive's MBR is current
	je 	wmbrsk0			; Is it #2? Yes go to it!
	mov	di,0			;030288
wmbrsk0:				;030288
	cld
	mov	es,cs:[oldmbrs]		; get the destination segment address
	mov	ds,cs:[mbrs]		; get the source segment address
	mov	si,0			; set the offsets point to beginning
	mov	cx,200h			; entire MBR
	rep	movsb

	pop	di
	pop	si
	pop	ds
	pop	es

	push	es		; setup es:bx as read/write buffer
	mov	es,[oldmbrs]
	mov	ax,0301h	; write operation
	xor	bx,bx
	mov	cx,0001h	; cylinder 0,sector 1
	mov	dh,00h		; head 0
	xor	dx,dx		; JSW do fd0 
	or	dl,80h		; dl is fixed disk number

	test	[wflags],01h	;030288  drive 1 to be written?
	jz	wmbrsk1		;030288  no, skip

	push	dx
	int	13h
	pop	dx
wmbrsk1:
	test	[wflags],02h	;030288  drive 2 to be written?
	jz	wmbrsk2		;030288  no, skip

	mov	ax,0301h
	mov	bx,200h
	mov	cx,0001h
	inc	dx		;JSW do fd1
	int	13h
wmbrsk2:
	pop	es
	ret

writembr endp

readmbr	proc near		; this proc reads the mbr from disk
	assume	ds:grp,es:grp
	cmp	[rdflag],0
	je	not_yet_rd
	jmp	ReadRet
not_yet_rd:
	inc	[rdflag]	; indicate sector already read

	push	es		; setup es:bx as read/write buffer
	mov	es,[oldmbrs]
	mov	ax,0201h	; read operation
	xor	bx,bx
	mov	cx,0001h	; cylinder 0,sector 1
	mov	dh,00h		; head 0
	mov	dl,80h
	push	dx
	int	13h
	pop	dx

	cmp	[nfdisks],1
	jbe	cont_read

	mov	ax,0201h
	mov	bx,200h
	mov	cx,0001h
	inc	dx
	int	13h

cont_read:

	push	ds
	push	si
	push	di
	cmp	word ptr es:[03feh],0aa55h
	jne	setflag
	cmp	word ptr es:[200h],0000h
	jne	no_setflag
setflag:
	mov	ds,[mbrs]
	cld
	mov	si,0
	mov	di,200h
	mov	cx,200h
	rep	movsb
no_setflag:
	pop	di
	pop	si
	pop	ds

	cmp	word ptr es:[01feh],0aa55h
	jne	use_new_mbr
	cmp	word ptr es:[00h],0000h
	je	use_new_mbr

	push	ds
	push	si
	push	di
	
	cld
	push	es
	pop	ds
	mov	es,cs:[mbrs]
	mov	si,1beh
	mov	di,1beh
	mov	cx,64
	rep	movsb

	pop	di
	pop	si
	pop	ds

use_new_mbr:	

NotMine:
	assume	es:grp
	pop	es

ReadRet:
	ret

rdflag	db	0

readmbr	endp

	subttl  Activate - subroutine to activate a partition
	page

;-----------------------------------------------------------------------;
;									;
;	Activate - subroutine to activate a partition of the hard disk	;
;									;
;  This routine prompts the user for a partition number to activate and ;
;  then scans tne partition table for the desired partition and the 	;
;  "ors" the first byte with an 80h to mark it as active. MOS allows for;
;   multiply active partitions.						;
;									;
;									;
;-----------------------------------------------------------------------;

activate proc	near
	jmp	begin4
;*****************************************************************************
;*				      MENUS				     *
;*									     *
;* 	1st byte - attribute, 2nd column, 3rd row, remainder is menu	     *
;*									     *
;*****************************************************************************

act1	db	7,27,6,'Activate a MOS Logical Disk          ',0ffh ;@@XLAT
act2	db	7,12,16,'Enter the number of the Logical Disk you want active:  ',0ffh ;@@XLAT
pnum	db	70h,66,16,'1',0ffh

NotaMOS db	70h,29,15,'NOT a MOS Logical Disk!     ',0ffh ;@@XLAT
wflag	db	0	; flag to indicate call to writembr

begin4:
	mov	al,[curdisk]	;030288
	or	[wflags],al	;030288

	call	cls		; clear window
	lea	bp,act1
	call	writescr
	mov	es,cs:[mbrs]
	mov	di,MBRPTAB	; address the partition table
	mov	cx,4
	mov	si,di
	call	gdisp		; display the current partition information
	jnc	$+5
	jmp	$actD1
	mov	di,si
$act1:
	lea	bp,act2
	call	writescr	; put up the prompt
	lea	bp,pnum
	call	writescr
	mov	ah,2		; position the cursor under the default choice
	mov	bh,0
	mov	dx,word ptr [pnum+1]
	int	10h		; thru the bios
	call	getchar
	cmp	al,0dh
	je	UseDef
	cmp	al,1bh
	jne	$+5
	jmp	$actDone
	cmp	al,31h
	jb	$act1
	cmp	al,34h
	ja	$act1
	mov	[pnum+3],al
UseDef:
	inc	[wflag]
	mov	al,[pnum+3]
	sub	al,31h
	xor	ah,ah
	mov	cx,MBRPLEN
	mul	cx
	push	di
	add	di,ax
	mov	al,byte ptr es:[di+MBRSI]
	cmp	al,01h
	jae	$act2
	pop	di
	jmp	NotMOS
$act2:
	cmp	al,04h
	jbe	$act3
	pop	di
	jmp	NotMOS
$act3:
	or	byte ptr es:[di+MBRBI],80h
	pop	di
	call	gdisp		; beginning of the partition table
	call	waitfun
$actDone:
	cmp	[wflag],0
	je	$actD1
	inc	[bootf]		; a reboot necessary
$actD1:
	mov	[pnum+3],'1'	; reset the default
	call	cls		; clear window
	ret
NotMOS:
	push	bx
	push	cx
	lea	bp,NotaMOS
	call	writescr
	mov	bx,000fh
$not1:
	xor	cx,cx
	loop	$
	dec	bx
	jnz	$not1
	mov	cx,0f01h
	mov	dx,0f4eh
	call	pscroll
	pop	cx
	pop	bx
	jmp	$act1

gdisp	proc	near
	jmp	gdisp1

gdisk3	db	7,19,8,'Logical     Active     MOS        Cylinders',0ffh ;@@XLAT
gdisk3a db	7,20,9,'Disk     Non-Active          First Last  Total  ',0ffh ;@@XLAT
gdisk4	db	15,22,10,'1          A         Y         0            ',0ffh ;@@XLAT

nopart1 db	7,25,8,'There are no MOS Logical Disks.         ',0ffh ;@@XLAT
wait3	db	7,28,16,'Press ENTER to continue.       ',0ffh ;@@XLAT

gdisp1:
	mov	es,ds:[mbrs]
	mov	di,MBRPTAB
	push	di			; save it for later

	assume	ds:grp,es:nothing

$g20:
	mov	al,byte ptr es:[di+MBRSI]
	cmp	al,01h
	jae	$dspa
	add	di,MBRPLEN
	loop	$g20
	pop	di
	jmp	NoMOSP
$dspa:
	pop	di
	mov	cx,4
$gdisp2:
	push	cx
	mov	al,es:[di+MBRSI]
	cmp	al,01
	jae	$gds0
	jmp	$gds7
$gds0:
	lea	bp,gdisk3
	call	writescr
	lea	bp,gdisk3a
	call	writescr
	mov	ax,di		; es:di addresses mbr. calculate the partition#
	sub	ax,MBRPTAB	; ax is partition number
	mov	cl,4
	shr	al,cl
	xor	ah,ah
	add	al,31h
	mov	[gdisk4+3],al	; put partition# in message
	mov	al,byte ptr es:[di+MBRBI]	; get boot indicator
	test	al,80h		; see if partition is bootable
	mov	ah,'A'
	jnz	$gds1		; yes
	mov	ah,[nomsg]
$gds1:
	mov	[gdisk4+14],ah	; set active or not

	mov	al,byte ptr es:[di+MBRSI]	; is it a mos partition
	mov	ah,[yesmsg]
	cmp	al,01
	je	$gds3
	cmp	al,4
	je	$gds3
	mov	ah,[nomsg]
$gds3:
	mov	[gdisk4+24],ah
	jmp	short $gds4
	
$gdisk5:				; this is here to make the loop $gdisk5
	jmp	$gdisp2			; work - it was out of range
	
$gds4:
	mov	ax,es:[di+MBRBS]	; do beginning cylinder
	and	al,0c0h			; strip sector bits
	xchg	ah,al
	mov	cl,6
	shr	ah,cl
	mov	cx,4
	xor	dx,dx			; clear it
	lea	bx,gdisk4+34		; put the count in the message
	push	ax			; save it for later
	call	bin2dec
	mov	ax,es:[di+MBRES]	; do ending cylinder
	and	al,0c0h
	xchg	ah,al
	mov	cl,6
	shr	ah,cl
	push	ax			; save it to do the total cylinders
	lea	bx,gdisk4+39
	mov	cx,4
	xor	dx,dx			; clear it
	call	bin2dec
	pop	ax			; get ending cylinder back & do total
	pop	bx
$gds6:
	sub	ax,bx
	inc	ax			; ending cylinder+1 is total cylinders
	xor	dx,dx
	lea	bx,gdisk4+46
	mov	cx,4
	call	bin2dec
	lea	bp,gdisk4
	call	writescr
$gds7:
	inc	[gdisk4+2]		; do the next row
$gds8:
	pop	cx
	add	di,MBRPLEN	; do the next partition
	loop	$gdisk5		; check the next partition
	cmp	[gdisk4+2],10	; see if the row indicator has changed indicating
	je	NoMOSP		; no partitions
	mov	[gdisk4+2],10	; reset the row spec
$nope:
	mov	cx,0e01h
	mov	dx,114eh
	call	pscroll
	ret
$nope1:
	mov	cx,0e01h
	mov	dx,114eh
	call	pscroll
	stc
	ret

	assume	ds:grp,es:nothing

NoMOSP:
	mov	[bootf],0	; clear the boot flag since there are no partitions
	lea	bp,nopart1
	call	writescr
	lea	bp,wait3
	call	writescr
$nmp:
	call	getchar
	cmp	al,0dh
	je	$nmp1
	cmp	al,1bh
	je	$nmp1
	jmp	$nmp
$nmp1:
	mov	cx,0c01h
	mov	dx,0f4eh
	call	pscroll
	jmp	$nope1

gdisp	endp

activate endp

	subttl  Changefd - allows you to change between fixed disk
	page

;-----------------------------------------------------------------------;
;									;
;			     CHANGEFD				      	;
;									;
;  This routine checks to see if its on a 286 or 386 machine. If so, it ;
;  checks the CMOS ram to see if there is a second fixed disk. If so it ;
;  increments the byte curdisk by one and tells the user it has changed ;
;  to the second physical disk. If its not a 286/386 machine it tells 	;
;  the user that the system cannot support a second physical disk. 	;
;  ChangeFD will prompt for input before returning to the main menu.	;
;									;
;-----------------------------------------------------------------------;

changeFD proc	near
	jmp	begin3

;******************************************************************************
;*				      MENUS				      *
;*									      *
;* 	1st byte - attribute, 2nd column, 3rd row, remainder is menu	      *
;*									      *
;******************************************************************************

chng1	db	7,28,6,'Change default fixed disk      ',0ffh ;@@XLAT
chng2	db	7,28,8,'Current fixed disk is #?       ',0ffh ;@@XLAT
chng3	db	15,27,10,'Default fixed disk is now #?        ',0ffh ;@@XLAT

chngerr db	70h,15,13,'This system cannot support a second physical disk!         ',0ffh ;@@XLAT
nofd2	db	15,19,12,'There is no second fixed disk in the system     ',0ffh ;@@XLAT


begin3:
	call	cls		; clear window
	lea	bp,chng1
	call	writescr

	push	es		; first check f000:fffe to see if its an AT
	mov	ax,0f000h
	mov	es,ax
	mov	al,byte ptr es:[0fffeh]
	pop	es

	assume	ds:grp,es:grp

	cmp	al,0fch
	je	AT		; yes check CMOS for #of fixed disks, if any
	cmp	al,0f8h		;Rod
	je	AT		;Rod
	jmp	No2ndFD

AT:				; check the CMOS ram for #of fixed disks and

	cmp	[nfdisks],1	;Rod
	ja	Set2ndFD	;Rod

	lea	bp,nofd2
	call	writescr
	call	waitfun
$ch2:
	call	cls		; clear window
	ret			; return to main menu

Set2ndFD:
	mov	al,[curdisk]
	add	al,30h
	mov	di,offset chng2
	call	replace?
	lea	bp,chng2
	call	writescr

	cmp	[curdisk],2		; is curdisk already 2 	
	jne	set_for_2nd		; no, ok go ahead!
	mov	[curdisk],0		; yes, set it back to zero!

set_for_2nd:  
	inc	[curdisk]
	mov	al,[curdisk]
	add	al,30h
	mov	di,offset chng3
	call	replace?
	mov	[fdn],al

	mov	ah,08h		;Rod  read drive parameters for 2nd disk
	mov	dl,[curdisk]	;JSW get the number of fixed disks
	cmp	dl,2		;JSW are there 2???
	jb	$chfd2		;JSW No - adjust dl accordingly
	dec	dl		;JSW Once dl in 'or'ed with an 80h
	jmp	short $chfd3	;JSW drive number will be correct
$chfd2:				;JSW
	xor	dl,dl		;JSW - the default fixed disk is now the first
$chfd3:				;JSW
	or	dl,80h		;JSW
	int	13h		;Rod
	mov	al,cl		;Rod  save sectors per track
	and	ax,003fh	;Rod
	mov	[spt],ax	;Rod
	mov	[hidden],ax	;Rod
	mov	[hidden+2],0	;Rod
	mov	ax,cx		;Rod  Get number of cylinders
	xchg	al,ah		;Rod
	rol	ah,1		;Rod
	rol	ah,1		;Rod
	and	ah,3		;Rod
	inc	ax		;Rod

	mov	[cyls],ax	; save it

	mov	al,dh		;Rod  Number of heads
	inc	al 		;Rod

	xor	ah,ah
	mov	[heads],ax	; save it
	lea	bp,chng3
	call	writescr

	push	es
	push	ds
	push	si
	push	di
	
	cmp	[curdisk],1
	je 	restore_2

	cld
	mov	es,cs:[oldmbrs]
	mov	ds,cs:[mbrs]
	mov	si,0h
	mov	di,0h
	mov	cx,200h
	rep	movsb

	push	ds
	push	es
	pop	ds
	pop	es
	mov	di,0h
	mov	si,200h
	mov	cx,200h
	rep	movsb

	jmp	end_chng

restore_2:

	cld
	mov	es,cs:[oldmbrs]
	mov	ds,cs:[mbrs]
	mov	si,0h
	mov	di,200h
	mov	cx,200h
	rep	movsb

	push	ds
	push	es
	pop	ds
	pop	es
	mov	di,0h
	mov	si,0h
	mov	cx,200h
	rep	movsb

end_chng:

	pop	di
	pop	si
	pop	ds
	pop	es

	call	waitfun
	jmp	$ch2

No2ndFD	label near
	lea	bp,chngerr
	call	writescr
	call	waitfun
	jmp	$ch2

changeFD endp

	subttl	Deactivate - set a partition active flag off
	page
									
;-----------------------------------------------------------------------;
;  			         DEACTIVATE				;
;									;
;  This routine prompts the user for a partition number to de-activate. ;
;  it then scans tne partition table for the desired partition then 	;
;  "ands" the first byte with an 7fh to mark it as inactive. MOS allows ;
;  for multiply active partitions.					;
;									;
;-----------------------------------------------------------------------;


dactivate proc	near
	jmp	begin5
;******************************************************************************
;*				      MENUS				      *
;*									      *
;* 	1st byte - attribute, 2nd column, 3rd row, remainder is menu	      *
;*									      *
;******************************************************************************

dact1	db	7,26,6,'De-activate a MOS Logical Disk    ',0ffh ;@@XLAT
dact2	db	7,11,16,'Enter the number of the Logical Disk you want inactive:    ',0ffh ;@@XLAT
dpnum	db	70h,67,16,'1',0ffh,0ffh
dNotaMOS	db	70h,29,17,'NOT a MOS Logical Disk!     ',0ffh ;@@XLAT
dwflag	db	0	; flag to indicate call to writembr

begin5:
	mov	al,[curdisk]	;030288
	or	[wflags],al	;030288

	call	cls		; clear window
	lea	bp,dact1
	call	writescr
	mov	es,cs:[mbrs]
	mov	di,MBRPTAB	; address the partition table
	mov	cx,4
	mov	si,di
	call	gdisp		; display the current partition information
	jnc	$+5
	jmp	$dactD1		; error return
	mov	di,si
$dact1:
	lea	bp,dact2
	call	writescr	; put up the prompt
	lea	bp,dpnum
	call	writescr
	mov	ah,2		; position the cursor under the default choice
	mov	bh,0
	mov	dx,word ptr [dpnum+1]
	int	10h		; thru the bios
	call	getchar
	cmp	al,0dh
	je	dUseDef
	cmp	al,1bh
	jne	$+5
	jmp	$dactDone
	cmp	al,31h
	jb	$dact1
	cmp	al,34h
	ja	$dact1
	mov	[dpnum+3],al
dUseDef:
	inc	[dwflag]
	mov	al,[dpnum+3]
	sub	al,31h
	xor	ah,ah
	mov	cx,MBRPLEN
	mul	cx
	push	di
	add	di,ax
	mov	al,byte ptr es:[di+MBRSI]
	cmp	al,01h
	jae	$dact2
	pop	di
	jmp	dNotMOS
$dact2:
	cmp	al,04h
	jbe	$dact3
	pop	di
	jmp	dNotMOS
$dact3:
	and	byte ptr es:[di+MBRBI],not 80h
	pop	di
	call	gdisp		; beginning of the partition table
	call	waitfun
$dactDone:
	cmp	[dwflag],0
	je	$dactD1
	inc	[bootf]		; a reboot necessary
$dactD1:
	mov	[dpnum+3],'1'	; reset the default choice
	call	cls		; clear window
	ret
dNotMOS:
	push	bx
	push	cx
	lea	bp,dNotaMOS
	call	writescr
	mov	bx,000fh
$dnot1:
	xor	cx,cx
	loop	$
	dec	bx
	jnz	$dnot1
	mov	cx,0f01h
	mov	dx,0f4eh
	call	pscroll
	pop	cx
	pop	bx
	jmp	$dact1

dactivate endp

	subttl	Delete - deletes an entry from the partition
	page
									
;-----------------------------------------------------------------------;
;									;
;  			         DELETE				        ;
;									;
;  This program zeros out a partition entry in the mbr and shifts any 	;
;  remaining partition data up into the table so that the logical 	;
;  partitions always start at the beginning of the table.		;
;									;
;-----------------------------------------------------------------------;


delete	proc	near
	jmp	begin6

;*****************************************************************************
;*				      MENUS				     *
;*									     *
;* 	1st byte - attribute, 2nd column, 3rd row, remainder is menu	     *
;*									     *
;*****************************************************************************

del1	db	7,28,5,'Delete a MOS Logical Disk        ',0ffh ;@@XLAT
del2	db	7,12,15,'Enter the number of the Logical Disk you want deleted:    ',0ffh ;@@XLAT
delnum	db	70h,67,15,'1',0ffh

del3	db	8ch,32,14,'**** WARNING **** ',0ffh	; red on black on color screen ;@@XLAT
del4	db	7,21,15,'ALL Data in the Logical Disk will be LOST!!!            ',0ffh ;@@XLAT
del5	db	7,32,16,'   Proceed (Y/N):  ',0ffh ;@@XLAT
del7	db	7,33,16,'    Abort (Y/N):  ',0ffh ;@@XLAT
prcd	db	15,50,16
nomsg	db	'No    ',0ffh ;@@XLAT
noprcd	db	15,49,16
yesmsg	db	'Yes   ',0ffh ;@@XLAT
delwflag db	0		; flag to indicate write
del8	db	7,20,13,'Do you wish to delete the NON-MOS Partition!!!        ',0ffh ;@@XLAT

begin6:
	mov	al,[curdisk]	;030288
	or	[wflags],al	;030288

	call	cls			; call clear window
	lea	bp,del1
	call	writescr
	mov	es,ds:[mbrs]

	assume	ds:grp,es:nothing

	mov	di,MBRPTAB		; es:di addresses boot record
	mov	si,di			; save di
	mov	cx,4
	call	gdisp
	jnc	$+5
	jmp	$DelDone		; no partitions defined
	mov	di,si
	lea	bp,del2
	call	writescr
	lea	bp,delnum
	call	writescr
$del1:
	mov	dx,word ptr [delnum+1]
	mov	ah,2
	xor	bh,bh			; position the cursor under the prompt
	int	10h
	call	getchar
	cmp	al,0dh
	je	UseDelDef
	cmp	al,1bh
	jne	$+5
	jmp	$DelDone
	cmp	al,31h
	jb	$del1
	cmp	al,34h
	ja	$del1
	mov	[delnum+3],al
UseDelDef:
	mov	al,[delnum+3]		; get the response
	sub	al,31h
	xor	ah,ah
	mov	cx,MBRPLEN
	mul	cx
	push	di
	add	di,ax
	mov	al,byte ptr es:[di+MBRSI]
	cmp	al,01h
	je	$del3
$del2:
	cmp	al,04h
	je	$del3
$del2e:
;
;	The following code is use to prompt user that partition
;	is DOS 3.30 extended partion
;
	mov	cx,word ptr [del2+1]
	mov	cl,1
	mov	dx,cx
	inc	dh
	mov	dl,4eh
	call	pscroll		; clear prompt
	lea	bp,del3
	call	writescr
	lea	bp,del8
	call	writescr
	lea	bp,del7
	call	writescr
	lea	bp,noprcd
	call	writescr
	mov	dx,word ptr [noprcd+1]
	xor	bh,bh
	mov	ah,2
	int	10h
$del2e1:
	call	getchar
	cmp	al,0dh
	je	$del2e2
	and	al,0dfh			; make it upper case
	cmp	al,[nomsg]
	je	$del3
	cmp	al,[yesmsg]
	jne	$del2e1
$del2e2:
	pop	di
	jmp	$delDone1
;
$del3:
	pop	di			; get di off the stack
	mov	cx,word ptr [del2+1]
	mov	cl,1
	mov	dx,cx
	inc	dh
	mov	dl,4eh
	call	pscroll			; clear the prompt
	lea	bp,del3			; print the warning message
	call	writescr
	lea	bp,del4
	call	writescr
	lea	bp,del5
	call	writescr
	lea	bp,prcd
	call	writescr
	mov	dx,word ptr [prcd+1]
	xor	bh,bh
	mov	ah,2
	int	10h			; put the cursor under the prompt
$del5:
	call	getchar
	cmp	al,0dh		; did they press return ?
	je	$DelDef1
	and	al,0dfh		; make it upper case
	cmp	al,[yesmsg]
	je	$del6
	cmp	al,[nomsg]
	jne	$del5
$DelDef1:
	jmp	$DelDone1
$del6:

; zero out this partition and then check to see if I need to move any.

	push	di		; save it for now
	mov	al,[delnum+3]	; get the response and make it an offset into ptab
	sub	al,31h
	xor	ah,ah
	mov	cx,MBRPLEN
	mul	cx
	add	di,ax		; di is now partition to delete

	; subtract sectors from hidden so creations will be correct
	mov	ax,es:[di+MBRRSCL]
	sub	[hidden],ax	; correct hidden for deletion		RKG006
	mov	ax,es:[di+MBRRSCH]
	sbb	[hidden+2],ax
	
	mov	ax,MBRSIG-MBRPLEN	; ax will be number of bytes to xfer
	sub	ax,di		; ax-di is #of bytes
	push	ds
	push	es
	pop	ds
	jz	$del6a

	assume	ds:nothing

	mov	si,di		; di is current partition
	add	si,MBRPLEN	; si is next partition
	mov	cx,ax		; cx is now counter
	cld
	rep	movsb		; overwrite the current partition byte moving
				; following partitions up 1 partition
$del6a:				; and zeroing out the last partition
	mov	di,MBRSIG-MBRPLEN	; di points to beginning of last partition
	mov	cx,MBRPLEN
	xor	al,al
	rep	stosb		; zero the partition
	pop	ds
$del4:
	assume	ds:grp,es:nothing
	pop	di		; beginning of the partition table
	mov	ax,es:[di]	; are there any partitions left?
	or	ax,ax
	jnz	$del4a		; some left
	
	mov	[hidden+2],ax	; initialize hidden in case its screwy
	mov	ax,[spt]
	mov	[hidden],ax
$del4a:
	inc	[delwflag]
	mov	cx,0501h
	mov	dx,114eh
	call	pscroll		; clear the screen
	mov	cx,4
	call	gdisp
	jnc	$del7
	jmp	short $DelDone	; terminate
$del7:
	call	waitfun
$DelDone:
	cmp	[delwflag],0
	je	$DelDone1
	inc	[bootf]		; indicate a boot necessary
$DelDone1:
	mov	[delnum+3],'1'
	call	cls		; clear window
	ret
delete	endp

	subttl	Display - displays the information currently in partition table
	page

;-----------------------------------------------------------------------;
;									;
;			         DISPLAY				;
;									;
;  All this routine does is display the partition information of the    ;
;  Master Boot Record. It show partition number, whether its an active  ;
;  partition, if its MOS, the beginning and ending cylinder numbers and ;
;  the total number of cylinders in a partition. Also, it shows the 	;
;  total number of cylinders on the fixed disk. Display first calls 	;
;  readmbr to be sure that the Master disk boot record is loaded. It 	;
;  then scans the partition table for a MOS partition, if none exists,  ;
;  it prints a message and prompts for input.  Upon input, it returns to;
;  the master menu. Otherwise, it retrieves the info and displays it on ;
;  the screen, prompts for input, and then returns to the master menu.	;
;									;
;-----------------------------------------------------------------------;


display	proc	near
	jmp	begin2

;*****************************************************************************
;*				      MENUS				     *
;*									     *
;* 	1st byte - attribute, 2nd column, 3rd row, remainder is menu	     *
;*									     *
;*****************************************************************************

disp1	db	7,32,5,'Display MOS Logical Disks   ',0ffh ;@@XLAT
disp2	db	15,24,6,'    Hard disk #? has ' ;@@XLAT
disp2x	db	'xxxx cylinders.     ',0ffh ;@@XLAT

disp3	db	7,19,8,'Logical     Active     MOS        Cylinders',0ffh ;@@XLAT
disp3a	db	7,20,9,'Disk     Non-Active          First Last  Total  ',0ffh ;@@XLAT
disp4	db	15,22,10,'1          A         Y         0            ',0ffh ;@@XLAT

noparts db	7,26,8,'There are no MOS Logical Disks.         ',0ffh ;@@XLAT

usepart db	7,16,15,'Shall we use current partition table (Y/N/ENTER) <          ',0ffh ;@@XLAT
useans	db	070h,67,15,'N',0ffh
isactive db	7,14,15,'Shall we make partition ' ;@@XLAT
ActDrive db	'x MOS bootable (Y/N/ENTER) <             ',0ffh ;@@XLAT
activeans db	070h,69,15,'N',0ffh

begin2:
	mov	es,cs:[mbrs]
	assume	ds:grp,es:nothing

	mov	di,MBRPTAB	; es:di addresses master disk boot record
	call	Chk4MOS
	jnz	$disp1		; if the zero flag is set - No partitions
	jmp	NoMOS

$disp1:
	mov	al,[curdisk]
	add	al,30h
	push	di
	mov	di,offset disp2
	call	replace?
	pop	di
	call	cls		; clear window
	lea	bp,disp1
	call	writescr	; put the "display" message up
	mov	ax,[cyls]
	mov	cx,4
	lea	bx,disp2x+3	; put the cylinder count in the message
	xor	dx,dx
	call	bin2dec
	lea	bp,disp2
	call	writescr	; display the disk size message
	mov	cx,4
$disp2:
	push	cx
	mov	al,es:[di+MBRSI]
	cmp	al,01
	jae	$ds0
	jmp	$ds7
$ds0:
	lea	bp,disp3
	call	writescr
	lea	bp,disp3a
	call	writescr
	mov	ax,di		; es:di addresses mbr. calculate the partition#
	sub	ax,MBRPTAB	; ax is partition number
	mov	cl,4
	shr	al,cl
	xor	ah,ah
	add	al,31h
	mov	[disp4+3],al	; put partition# in message
	mov	al,byte ptr es:[di+MBRBI]	; get boot indicator
	test	al,80h		; see if partition is bootable
	mov	ah,'A'
	jnz	$ds1		; no
	mov	ah,[nomsg]
$ds1:
	mov	[disp4+14],ah	; set activity

	mov	al,byte ptr es:[di+MBRSI]	; is it a mos partition
	mov	ah,[yesmsg]
	cmp	al,01
	je	$ds3
	cmp	al,4
	je	$ds3
	mov	ah,[nomsg]
$ds3:
	mov	[disp4+24],ah
	jmp	short $ds4
	
$disp5:					; this is here to make the loop $disp5
	jmp	$disp2			; work - it was out of range

$ds4:
	mov	ax,es:[di+MBRBS]	; do beginning cylinder
	and	al,0c0h			; strip sector bits
	xchg	ah,al
	mov	cl,6
	shr	ah,cl
	mov	cx,4
	xor	dx,dx			; clear it
	lea	bx,disp4+34		; put the count in the message
	push	ax			; save it for later
	call	bin2dec
	mov	ax,es:[di+MBRES]	; do ending cylinder
	and	al,0c0h
	xchg	ah,al
	mov	cl,6
	shr	ah,cl
	push	ax			; save it to do the total cylinders
	lea	bx,disp4+39
	mov	cx,4
	xor	dx,dx			; clear it
	call	bin2dec
	pop	ax			; get ending cylinder back & do total
	pop	bx			; get beginning cylinder
$ds6:
	sub	ax,bx
	inc	ax			; ending cylinder+1 is total cylinders
	xor	dx,dx
	lea	bx,disp4+46
	mov	cx,4
	call	bin2dec
	lea	bp,disp4
	call	writescr
	inc	[disp4+2]		; do the next row
$ds7:
	pop	cx
	add	di,MBRPLEN	; do the next partition
	loop	$disp5		; check the next partition
	cmp	[autoins],'N'
	je	$ds7x
	cmp	[autoins],'A'	; is this for activate
	jne	ds7dp
	lea	bp,isactive
	call	writescr
	lea	bp,activeans
	call	writescr
	mov	dx,0f50h
	jmp	short ds7lp
ds7dp:
	lea	bp,usepart
	call	writescr
	lea	bp,useans
	call	writescr
	mov	dx,0f43h
ds7lp:
	mov	ah,2
	xor	bx,bx
	int	10h
	call	conin
	mov	[reply],'N'
	jc      $disp4
	cmp	al,0dh
	je	$disp4
	and	al,0dfh
	cmp	al,[nomsg]
	je	$disp4
	cmp	al,[yesmsg]
	jne	ds7lp
	mov	[reply],'Y'	
	jmp	short $disp4	
$ds7x:
	call	waitfun 	; wait for key press
$disp4:
	mov	[disp4+2],10
	call	cls		; clear window
	ret			; return to main menu

Chk4MOS	label near
	push	di		; upon entry es:di points to partition table
	mov	cx,4		; scan for a mos partition 4x
$chk1:
	mov	al,byte ptr es:[di+MBRSI]	; check the system indicator
	cmp	al,0		; is it non-zero
	je	$chk2		; no, check next entry
	pop	di		; yes so there are mos partitions
	ret
$chk2:
	add	di,MBRPLEN
	loop	$chk1
	or	cx,cx
	pop	di
	ret
NoMOS:
	call	cls		; clear window
	lea	bp,disp1
	call	writescr
	lea	bp,noparts
	call	writescr
	call	waitfun
	jmp	$disp4

display	endp

	subttl	Create - creates a new entry in the partition table
	page

;-----------------------------------------------------------------------;
;			     Create				        ;
;									;
; It is the responsiblity of CREATE to build the partition table in the ;
; Master Disk Boot Record to define the layout of logical volumes on one;
; physical fixed disk. A total of 4 logical volumes may exist on one 	;
; physical fixed disk. Once the partition table has been built, it will ;
; be written to the disk. Create MUST know the dimensions of the disk 	;
; which it will get from the variables "cylinders" and "heads". From 	;
; this, it will ask the user if they wish to use the entire fixed disk 	;
; for MOS. If so, then CREATE will allocate the disk space by maximizing;
; the first logical drive and the using the remainder for any other 	;
; drives. If the physical disk is large enough to allow maximum logical ;
; volumes for every one possible, CREATE will do so.  Once the table has;
; been built, partition data will be displayed. After the user returns 	;
; to the main menu and desires to quit the system will tell them to put ;
; a boot disk into drive A and wait while the system restarts.	      	;
;-----------------------------------------------------------------------;

create	proc	near
	jmp	begin1

;*****************************************************************************
;*				      MENUS				     *
;*									     *
;* 	1st byte - attribute, 2nd column, 3rd row, remainder is menu	     *
;*									     *
;*****************************************************************************

maxsect dd	000000fah
max_sects dw	0
	  dw	0
msg32	db	7,12,8,'Shall I build multiple 32 megabyte partitions (Y/N/ENTER) <    ',0ffh ;@@XLAT
res32a	db	070h,71,8,'Y',0ffh     ; reverse video
res32b	db	7,72,8,'>',0ffh

crt1	db	7,28,5,'Create MOS Logical Disks            ',0ffh ;@@XLAT
crt1a	db	7,24,7,'MOS Logical Disks already exist.        ',0ffh ;@@XLAT
crt2	db	7,12,8,'Shall I use the WHOLE fixed disk for MOS (Y/N/ENTER) <         ',0ffh ;@@XLAT
answer	db	070h,66,8,'Y',0ffh     ; reverse video
crt3	db	7,67,8,'>',0ffh

crt4	db	15,24,6,'Fixed disk #? has ' ;@@XLAT
crt4x	db	'xxxx cylinders.     ',0ffh ;@@XLAT
crt4a	db	15,15,6,'Fixed disk #? has ' ;@@XLAT
crt4ax	db	'xxxx cylinders with   ' ;@@XLAT
crt4axx	db	'xxxx remaining     ',0ffh ;@@XLAT

crt5	db	15,14,14,'How many cylinders do you want for this Logical Disk?    ',0ffh ;@@XLAT
crt6	db	7,30,15,'Enter for none:    ',0ffh ;@@XLAT
ccount	db	70h,46,15,'   0',0ffh
rightmost	dw	$-2			; this MUST stay right after ccount

crt7	db	7,19,8,'Logical     Active     MOS        Cylinders',0ffh ;@@XLAT
crt7a	db	7,20,9,'Disk     Non-Active          First Last  Total  ',0ffh ;@@XLAT
crt8	db	15,22,10,'1          A         Y         0            ',0ffh ;@@XLAT

waitmsg db	7,28,15,'Press ENTER to continue.       ',0ffh ;@@XLAT
SizeError	db	70h,10,16,'You have exceeded the maximum number of cylinders. Try again!       ',0ffh ;@@XLAT
SizeError1	db	70h,10,16,' The specified number of cylinders is too small. Try again!     ',0ffh ;@@XLAT
SizeError2	db	70h,10,16,' The specified number of cylinders is too large. Try again!     ',0ffh ;@@XLAT
blanx	db	'   0'

;*****************************************************************************
;*				      Locals				     *
;*****************************************************************************

remainder dw	0	; remainder of cylinders-calculated
spt	dw	17
hidden	dw	17,0		; number of preceding sectors
StartHead dw	0		; starting head for partitions
endcyl	dw	0		; ending cylinder number
maxcyl	dw	0		; maximum cylinder for prompting
wd10	dw	10		; used to calc cylinder number
mcount	dw	0		; shift counter
pcount	dw	0		; partition counter
nextpos	dw	ccount+6	; ending postion for cylinder count prompt
totsec	dw	2 dup(0)	; total sector count
minsec	dw	2161		; the minimum number of sectors allowable

begin1:
	call	Get32Vol
	mov	al,[curdisk]	;030288
	or	[wflags],al	;030288

	mov	al,[curdisk]
	add	al,30h
	push	di
	mov	di,offset crt4
	call	replace?	; insert drive character in string
	mov	di,offset crt4a
	call	replace?
	pop	di
	call	cls		; clear window
	lea	bp,crt1
	call	writescr

	mov	es,[mbrs]
	assume	es:nothing
	mov	bx,MBRPTAB
	mov	cx,4
$crt1a:
	mov	al,byte ptr es:[bx+MBRSI]
	or	al,al
	jz	$crt2a
	lea	bp,crt1a
	call	writescr
	call	waitfun
	jmp	CreateDone
$crt2a:
	add	bx,16
	loop	$crt1a
	cmp	[helpflg],'A'
	jne	contins	
	call	Get32Wish
	mov	ah,02
	xor	bx,bx
	mov	dx,0847h
	int	10h		; position the cursor to the prompt
$32meg0:
	call	conin		; get response
	jnc	$+5
	jmp	CreateDone
	cmp	al,0dh		; did they hit return to accept default?
	jne	$32meg1
	jmp	Do_32meg_Vols	; yes they did, so do the whole disk
$32meg1:
	and	al,0dfh		; make it uppercase
	cmp	al,[yesmsg]	; see if they entered 'Y'
	jne	$32meg2		; No
	jmp	Do_32meg_Vols	; yes
$32meg2:
	cmp	al,[nomsg]
	jne	$32meg0
	mov	[answer+3],al
        lea	bp,answer
	call	writescr
contins:
	call	cls		; clear window
	cmp	[helpflg],'D'	; is this dual system
	je	CreateCyl
	lea	dx,help3
	call	dohelp	
	call	getWish1	; print crt1-crt3, escmsg
	mov	ah,02
	xor	bx,bx
	mov	dx,0842h
	int	10h		; position the cursor to the prompt
$0:
	call	conin		; get response
	jnc	$+5
	jmp	CreateDone
	cmp	al,0dh		; did they hit return to accept default?
	jne	$1
	jmp	CreateCyl	; yes they did, so do the whole disk
$1:
	and	al,0dfh		; make it uppercase
	cmp	al,[yesmsg]	; see if they entered 'Y'
	jne	$2		; No
	jmp	DoWholeDisk	; yes
$2:
	cmp	al,[nomsg]
	jne	$0
	mov	[answer+3],al
        lea	bp,answer
	call	writescr
CreateCyl:
	jmp	PromptForCyl	; OK, so let them define the disk

CreateDone:
	call	initvars	; re-initialize the variables
	call	cls		; clear window
	ret			; return to main proc

;============================================
;-------------------------------------------;
; The following code was added to allow	    ;
; 32 meg partitions to be created as the    ;
; default size				    ;
;-------------------------------------------;

Do_32meg_Vols:
	inc	[bootf]		; indicate a boot necessary
	mov	cx,0801h	; clear the entire disk prompt
	mov	dx,084eh
	call	pscroll

	mov	bx,cs:[mbrs]	; now access the master boot record
	mov	es,bx

	assume	ds:grp,es:nothing

	call	Get32Vol		; get max sectors for 32 vol

	lea	dx,help4
	call	dohelp
	mov	bx,MBRPTAB	; let es:bx address the partition table
	xor	ax,ax		; clear ax and dx and calculate the number of
	xor	dx,dx		; cylinders for 1st physical disk
	mov	ax,[cyls]	; we do this to determine how large the 1st

	push	ax		; causes dx to be NZ, there is more than 1
	push	bx
	mov	cx,4
	lea	bx,crt4x+3
	call	bin2dec		; prepare the information message
	lea	bp,crt4
	call	writescr
	pop	bx
	pop	ax
	push	ax		; now, commence calculations
	mul	[heads]		; logical disk
	push	cx
	mov	cx,[spt]
	call	lmul	
	pop	cx

	mov	[totsec],ax
	mov	[totsec+2],dx	; save em for later

	cmp	dx,word ptr[max_sects+2]
	pop	ax		; get cylinder count back
	ja	$32too_large	;jsm1 disk bigger than 32 meg
	jb	$5_32meg	;jsm1 the disk is < 32MB therefore use it all
	cmp	ax,word ptr[max_sects]; see if ax > max_sects if so and dx = max_sects+2 then it
				; is too large!
	jbe	$5_32meg 	        ;jsm1 no, it is <=, let's go with it

$32too_large:
	mov	dx,word ptr[max_sects+2]	; set high word
	mov	ax,word ptr[max_sects]		; max sector count

	push	bx
	push	cx
	mov	cx,[heads]
	call	ldiv
	pop	cx
	pop	bx
	push	bx
	push	cx
	mov	cx,[spt]
	call	ldiv
	pop	cx
	pop	bx	

	mov	[maxcyl],ax	; this is the largest #of cylinders to allocate

$5_32meg:
	push	ax				; save it for later
	or	byte ptr es:[bx+MBRBI],80h	; first partition is bootable
	mov	byte ptr es:[bx+MBRBH],1	; start at head one
	mov	byte ptr es:[bx+MBRBS],1	; beginning sector
	mov	byte ptr es:[bx+MBRBC],0	; beginning cylinder

; Now determine the FAT size (12/16 bit) by calculating the number of 
; sectors in the partition

$6_32meg:
	inc	[pcount]		; this word counts the partitions made
	mul	[heads]			; cylinder count * heads * spt - reserved = total sectors
	push	cx
	mov	cx,[spt]
	call	lmul	
	pop	cx
	cmp 	dx,0			; if dx > 0 then we need a 16 bit fat
	jg	$3_32meg
	cmp	ax,20740		; this is the max number of sectors on fixed disk w/12-bit fat
	ja	$3_32meg
	mov	byte ptr es:[bx+MBRSI],01h	; 12-bit fat
	jmp	short $4_32meg
$3_32meg:
	mov	byte ptr es:[bx+MBRSI],04h	; 16-bit fat
$4_32meg:
	cmp	byte ptr es:[bx+MBRBH],0
	je	$16_32meg
	sub	ax,[hidden]		; for the first partition adjust by hidden
$16_32meg:
	mov	es:[bx+MBRRSCL],ax	; dx:ax has sector count for partition
	mov	es:[bx+MBRRSCH],dx	; so save it
	push	bx
	push	si
	mov	si,bx
	mov	cx,ax
	mov	bx,dx
	mov	ax,[hidden]
	mov	es:[si+MBRRSL],ax	; store beginning rel sector number low
	mov	ax,[hidden+2]
	mov	es:[si+MBRRSH],ax	; ditto with high word
	call	DblwAdd			; adjust the count by cx which is #of sectors in partition
	pop	si
	pop	bx
	pop	ax			; get cylinder # back
	push	ax			; save it again
	add	ax,[endcyl]		; add in previous ending cylinder number
	mov	[endcyl],ax		; save it for next time

;Rod	The following 2 lines look like a mistake to me, but as things are
;Rod 	now, lz is always zero anyway.

	cmp	[lz],0			; do we adjust cylinder count?
	jne	$7_32meg

	dec	ax			; adjust it by one for ending cylinder#
$7_32meg:
	xchg	ah,al
	mov	cl,6
	shl	al,cl
	and	al,0c0h			; clear all but bits 6,7
	or	ax,[spt]		; or in the last sector
	mov	word ptr es:[bx+MBRES],ax	; set ending cylinder,sector
	mov	ax,[heads]		; set ending head number silly!!!
	dec	al
	mov	es:[bx+MBREH],al
	mov	ax,[remainder]		; see if we need to do another partition
	pop	cx			; get cylinder number back
	mov	dx,cx			; save it to calc beginning hcs of next
	add	[remainder],cx		; testing - keep a total
	mov	cx,[remainder]		; testing - now check to see if counter=total
	mov	ax,[cyls]		; testing
	sub	ax,cx			; testing
	cmp	ax,0			; testing
	jle	$32NoMore			; out for testing
	cmp	ax,[maxcyl]		; see if remaining cylinders is > maxcyl
	jle	$17_32meg
	sub	ax,[maxcyl]		; calculate a new remainder
	mov	ax,[maxcyl]
$17_32meg:
	push	ax			; save the next partition size
	push	dx			; save it
	xor	dx,dx			; see if there are enough remaining
					; sectors for another disk
	mul	[heads]
	push	cx
	mov	cx,[spt]
	call	lmul	
	pop	cx
	mov	cx,[totsec+2]		; now see how many sectors remain
	sub	ax,[totsec]
	sbb	cx,0
	mov	[totsec+2],cx
	cmp	ax,[minsec]		; is it below minimum ??
	pop	dx
	pop	ax
	push	ax
	jne	$+5
	pop	ax			; clear the stack
	jmp	short $32NoMore		; yes
	add	bx,16			; do the next partition
	mov	byte ptr es:[bx+MBRBH],0; start at head zero
	mov	dx,[remainder]		; remainder is also a count of next cyl
	mov	cl,6
	xchg	dh,dl			; calc beginning cylinder,sector for next partition
	shl	dl,cl
	or	dx,01h			; always start at sector 1
	mov	es:[bx+MBRBS],dx	; set it
	jmp	$6_32meg
$32NoMore:
	lea	dx,help5
	call	dohelp
	xor	ax,ax
	xor	dx,dx
	mov	ax,[pcount]
	dec	ax
	mov	cx,MBRPLEN
	mul	cx
	mov	di,bx			; set up loop to call display1
	sub	di,ax
	add	di,MBRPLEN
	mov	cx,[pcount]
$32nmloop:
	push	cx
	call	display1		; display the info
	add	di,MBRPLEN		; do the next partition
	pop	cx
	loop	$32nmloop
	mov	cx,0e01h		; clear part of the screen
	mov	dx,0f4eh		; SAH correct so it will display all 4
	call	pscroll
	call	waitfun

$32NoMore1:
	jmp	CreateDone

;============================================

DoWholeDisk:
	inc	[bootf]		; indicate a boot necessary
	mov	cx,0801h	; clear the entire disk prompt
	mov	dx,084eh
	call	pscroll

	mov	es,cs:[mbrs]	; now access the master boot record
	assume	ds:grp,es:nothing

	mov	bx,MBRPTAB	; let es:bx address the partition table
	xor	ax,ax		; clear ax and dx and calculate the number of
	xor	dx,dx		; cylinders for 1st physical disk
	mov	ax,[cyls]	; we do this to determine how large the 1st

	push	ax		; causes dx to be NZ, there is more than 1
	push	bx
	mov	cx,4
	lea	bx,crt4x+3
	call	bin2dec		; prepare the information message
	lea	bp,crt4
	call	writescr
	pop	bx
	pop	ax
	push	ax		; now, commence calculations
	mul	[heads]		; logical disk
	push	cx
	mov	cx,[spt]
	call	lmul	
	pop	cx

	mov	[totsec],ax
	mov	[totsec+2],dx	; save em for later

	cmp	dx,00fah
	pop	ax		; get cylinder count back
	jg	too_large	; greater than 130 meg
	jl	$5		; the disk is > 130MB therefore use it all
	cmp	ax,0000		; see if ax > 0000 if so and dx = 00fah then it
				; is too large!
	je	$5 	        ; no, it is 0 lets go with it
too_large:
	mov	dx,00fah	; set high word
	mov	ax,0		; max sector count

	push	bx
	push	cx
	mov	cx,[heads]
	call	ldiv
	pop	cx
	pop	bx	
	push	bx
	push	cx
	mov	cx,[spt]
	call	ldiv
	pop	cx
	pop	bx	

	mov	[maxcyl],ax	; this is the largest #of cylinders to allocate
$5:
	push	ax				; save it for later
	or	byte ptr es:[bx+MBRBI],80h	; the first partition is bootable
	mov	byte ptr es:[bx+MBRBH],1	; start at head one
	mov	byte ptr es:[bx+MBRBS],1	; beginning sector
	mov	byte ptr es:[bx+MBRBC],0	; beginning cylinder

; Now determine the FAT size (12/16 bit) by calculating the number of sectors in the partition

$6:
	inc	[pcount]		; this word counts the partitions made
	mul	[heads]			; cylinder count * heads * spt - reserved = total sectors
	push	cx
	mov	cx,[spt]
	call	lmul	
	pop	cx
	cmp 	dx,0			; if dx > 0 then we need a 16 bit fat
	jg	$3
	cmp	ax,20740		; this is the max number of sectors on fixed disk w/12-bit fat
	ja	$3
	mov	byte ptr es:[bx+MBRSI],01h	; 12-bit fat
	jmp	short $4
$3:
	mov	byte ptr es:[bx+MBRSI],04h	; 16-bit fat
$4:
	cmp	byte ptr es:[bx+MBRBH],0
	je	$16
	sub	ax,[hidden]		; for the first partition adjust by hidden
	sbb	dx,[hidden+2]		; remember Hidden is 32 bits!!	RKG006
$16:
	mov	es:[bx+MBRRSCL],ax	; dx:ax has sector count for partition
	mov	es:[bx+MBRRSCH],dx	; so save it
	push	bx

	push	si
	mov	si,bx
	mov	cx,ax
	mov	bx,dx
	mov	ax,[hidden]
	mov	es:[si+MBRRSL],ax	; store beginning rel sector number low
	mov	ax,[hidden+2]
	mov	es:[si+MBRRSH],ax	; ditto with high word
	call	DblwAdd			; adjust the count by cx which is #of sectors in partition
	pop	si

	pop	bx
	pop	ax			; get cylinder # back
	push	ax			; save it again
	add	ax,[endcyl]		; add in previous ending cylinder number
	mov	[endcyl],ax		; save it for next time

;Rod	The following 2 lines look like a mistake to me, but as things are
;Rod 	now, lz is always zero anyway.

	cmp	[lz],0			; do we adjust cylinder count?
	jne	$7

	dec	ax			; adjust it by one for ending cylinder#
$7:
	xchg	ah,al
	mov	cl,6
	shl	al,cl
	and	al,0c0h			; clear all but bits 6,7
	or	ax,[spt]		; or in the last sector
	mov	word ptr es:[bx+MBRES],ax	; set ending cylinder,sector
	mov	ax,[heads]		; set ending head number silly!!!
	dec	al
	mov	es:[bx+MBREH],al
	mov	ax,[remainder]		; see if we need to do another partition
	pop	cx			; get cylinder number back
	mov	dx,cx			; save it to calc beginning hcs of next
	add	[remainder],cx		; testing - keep a total
	mov	cx,[remainder]		; testing - now check to see if counter=total
	mov	ax,[cyls]		; testing
	sub	ax,cx			; testing
	cmp	ax,0			; testing
	jle	NoMore			; out for testing
	cmp	ax,[maxcyl]		; see if remaining cylinders is > maxcyl
	jle	$17
	sub	ax,[maxcyl]		; calculate a new remainder
	mov	ax,[maxcyl]
$17:
	push	ax			; save the next partition size
	push	dx			; save it
	xor	dx,dx			; see if there are enough remaining
					; sectors for another disk
	mul	[heads]
	push	cx
	mov	cx,[spt]
	call	lmul	
	pop	cx
	mov	cx,[totsec+2]		; now see how many sectors remain
	sub	ax,[totsec]
	sbb	cx,0
	mov	[totsec+2],cx
	cmp	ax,[minsec]		; is it below minimum ??
	pop	dx
	pop	ax
	push	ax
	jne	$+5
	pop	ax			; clear the stack
	jmp	short NoMore		; yes
	add	bx,16			; do the next partition
	mov	byte ptr es:[bx+MBRBH],0; start at head zero
	mov	dx,[remainder]		; remainder is also a count of next cyl
	mov	cl,6
	xchg	dh,dl			; calc beginning cylinder,sector for next partition
	shl	dl,cl
	or	dx,01h			; always start at sector 1
	mov	es:[bx+MBRBS],dx	; set it
	jmp	$6
NoMore:
	lea	dx,help6
	call	dohelp
	xor	ax,ax
	xor	dx,dx
	mov	ax,[pcount]
	dec	ax
	mov	cx,MBRPLEN
	mul	cx
	mov	di,bx			; set up loop to call display1
	sub	di,ax
	add	di,MBRPLEN
	mov	cx,[pcount]
$Nm1:
	push	cx
	call	display1		; display the info
	add	di,MBRPLEN		; do the next partition
	pop	cx
	loop	$Nm1
	mov	cx,0c01h		; clear part of the screen
	mov	dx,0f4eh
	call	pscroll
	call	waitfun
NoMore1:
	jmp	CreateDone

PromptForCyl:
 	mov	ax,cs:[mbrs]	; now setup mbr addressibility
	mov	es,ax
	mov	di,MBRPTAB	; es:di addresses mbr partition table
	mov	cx,0801h	; clear the entire disk prompt
	mov	dx,084eh
	call	pscroll
	mov	ax,[cyls]	; get the number of cylinders and setup message
	mov	[remainder],ax
$8:
	xor	dx,dx
	push	ax
	mov	cx,4		; the number count
	lea	bx,crt4ax+3
	call	bin2dec
	mov	ax,[cyls]
	mov	cx,4
	xor	dx,dx
	lea	bx,crt4axx+3
	call	bin2dec
	lea	bp,crt4a
	call	writescr
	pop	ax
	xor	dx,dx
	mul	[heads]
	push	cx
	mov	cx,[spt]
	call	lmul	
	pop	cx
	mov	[totsec],ax
	mov	[totsec+2],dx	; save these for later
	or	dx,dx
	mov	ax,[cyls]
	jz	$9

	cmp	dx,00fah
	jg	too_large2	; greater than 130 meg
	jl	$9		; the disk is > 130MB therefore use it all
	cmp	ax,word ptr [totsec]; see if ax > 0000 if so and dx = 00fah then it
				; is too large!
	je	letsgo 	        ; no, it is 0 lets go with it
too_large2:
	mov	dx,00fah	; set high word
	mov	ax,0		; max sector count
letsgo:
	push	ax
	mov	dx,word ptr [totsec+2]
	mov	ax,word ptr [totsec]
	push	bx
	push	cx
	mov	cx,[spt]
	call	ldiv
	pop	cx
	pop	bx	
	push	bx
	push	cx
	mov	cx,[heads]
	call	ldiv
	pop	cx
	pop	bx	
	mov	[maxcyl],ax
	pop	ax
	jmp	short $10

$9:
	mov	[maxcyl],ax	; save it

$10:
	push	ax
	push	bx
	push	cx
	push	dx

	mov	dx,word ptr [max_sects+2]
	mov	ax,word ptr [max_sects]
	mov	cx,[spt]
	call	ldiv
	mov	cx,[heads]
	call	ldiv
	mov	cx,4
	lea	bx,msgval+3
	call	bin2dec
	
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	mov	[force],'Y'
	lea	dx,help7
	call	dohelp
	mov	[force],'N'

	lea	bp,crt5		; put up the cylinder prompt
	call	writescr
	lea	bp,crt6
	call	writescr
	lea	bp,ccount
	call	writescr
	mov	cx,4		; number of times to input
	xor	dx,dx		; dx will be cylinder accumulator

$11:
	mov	ah,2
	xor	bh,bh
	mov	dx,0f31h
	int	10h		; postition the cursor to the prompt

$15:
	call	getchar
	jnc	$12
	jmp	NoMore1		; they hit escape, quit

$12:
	cmp	al,0dh		; cr terminates input
	jne	$13
	jmp	PromptDone

$13:
	cmp	al,08h		; allow for backspace
	jne	$18
	call	wipeprompt	; if any backspace just start over
	jmp	$11

$18:
	cmp	al,30h
	jae	$14
	call	bell
	call	wipeprompt	; clear the prompt
	jmp	$11		; they boobooed so, get the info again

$14:
	cmp	al,39h		; only numbers 0-9 are valid
	jbe	PutChar
	call	bell
	call	wipeprompt
	jmp	$11

PutChar:
	push	cx
	push	di
	mov	di,[nextpos]	; address last position

DoShift:
	cmp	di,[rightmost]	; si is index into prompt information
	jne	DoShift1
	jmp	SetChar

DoShift1:
	mov	si,di
	inc	si
	mov	ah,byte ptr [si]
	mov	byte ptr [di],ah
	inc	si
	inc	di
	cmp	si,[rightmost]
	ja	SetChar
	jmp	DoShift1

SetChar:
	mov	si,[rightmost]
	mov	byte ptr [si],al
	dec	[nextpos]
	inc	[mcount]	; adjust the move count
	lea	bp,ccount
	call	writescr
	pop	di
	pop	cx
	loop	$11		; do it 4 times

PromptDone:
	xor	ax,ax		; clear ax to receive cylinder count
	lea	bx,ccount+3
	mov	cx,4
	call	dec2bin
	cmp	ax,[remainder]
	jbe	CylOk
	jmp	TooBig

CylOk:
	cmp	ax,0
	ja	$C0
	jmp	NoMore1		; quit

$C0:
	push	ax		; save it temporarily
	xor	dx,dx		; see if they made it too small by converting
	mul	[heads]		; cylinder count * heads * spt = #sectors
	push	cx
	mov	cx,[spt]
	call	lmul	
	pop	cx
;
;	The following was added for dual MOS and DOS to not allow first
;	partition to be larger the 32 Meg
;
	cmp	[helpflg],'D'
	jne	vol32ok
	cmp	[endcyl],0
	jne	vol32ok
	cmp	dx,word ptr [max_sects+2]
	jb	vol32ok
	ja	vol32bad
	cmp	ax,word ptr [max_sects]
	jbe	vol32ok
vol32bad:
	jmp	TooSmall	; actuall tooLarge			
vol32ok:	
;
	mov	cx,ax		;Rod  Such a joy to clean up shit like this...
	pop	ax		;Rod
	or	dx,dx		;Rod
	jnz	NotSmall	;Rod
	cmp	cx,[minsec]	;Rod
	jae	NotSmall	;Rod
	jmp	TooSmall	;Rod
NotSmall:			;Rod

	mov	cx,[remainder]
	sub	cx,ax		; adjust for remaining stuff
	mov	[remainder],cx	; save it
	push	ax
	mov	ax,cx		; now put the amount remaining in the crt4a message
	mov	cx,4
	lea	bx,crt4axx+3
	xor	dx,dx
	call	bin2dec
	lea	bp,crt4a
	call	writescr
	pop	ax

$c6:
	push	ax		; save the cylinder count
	cmp	[endcyl],0
	jne	$c1
	or	byte ptr es:[di+MBRBI],80h	; set the boot indicator first time thru
	mov	byte ptr es:[di+MBRBH],1
	mov	byte ptr es:[di+MBRBS],1	; start at sector 1
	mov	byte ptr es:[di+MBRBC],0	;   "   "  cylinder 0
	jmp	short	$c2

$c1:
	mov	ax,[endcyl]		; now calculate the beginning HSC
	xchg	ah,al
	mov	cl,6			; create beginning cylinder,sector
	shl	al,cl
	and	al,0c0h
	or	ax,01h			; ax is beginning cylinder,sector
	mov	word ptr es:[di+MBRBS],ax
	mov	ax,[StartHead]
	mov	byte ptr es:[di+MBRBH],al

$c2:
	inc	[bootf]			; tell main we have to reboot
	pop	ax			; retrieve cylinder count
	push	ax
	xor	dx,dx			; calculate the FAT size byte calculating
	mul	[heads]			; the number of sectors in the partition
	push	cx
	mov	cx,[spt]
	call	lmul	
	pop	cx
	or	dx,dx			; SAH check for overflow
	jnz	$c3
	cmp	ax,20740		; check for 12-bit
	ja	$c3
	mov	byte ptr es:[di+MBRSI],01h	; 12-bit fat
	jmp	short	$c4

$c3:
	mov	byte ptr es:[di+MBRSI],04h	; 16-bit fat

$c4:
	cmp	byte ptr es:[di+MBRBH],0	; is this the first partition
	je	$c7			; no
	sub	ax,[hidden]		; yes adjust ax
	jnc	$c7			
	dec	dx			; SAH decrement high value
$c7:
	mov	es:[di+MBRRSCL],ax	; dx:ax is conveniently the #of sectors
	mov	es:[di+MBRRSCH],dx	; so put it into the MBR
	push	bx
	mov	cx,ax
	mov	bx,dx			; BMW put high word of total of sectors here
	mov	ax,[hidden]		; now sector log sector count
	mov	es:[di+MBRRSL],ax	; set low word
	mov	ax,[hidden+2]
	mov	es:[di+MBRRSH],ax
	call	DblwAdd			; keep a running total
	pop	bx
	pop	ax
	push	ax			; save it again
	add	ax,[endcyl]		; calculate new ending cylinder
	mov	[endcyl],ax
	dec	ax			; moved above count - for testing
	xchg	ah,al			; calc ending HSC
	mov	cl,6
	shl	al,cl
	and	al,0c0h
	or	ax,[spt]
	mov	es:[di+MBRES],ax
	mov	ax,[heads]
	dec	al
	mov	byte ptr es:[di+MBREH],al
	pop	cx			; get cylinder count back
	add	di,16
	call	display1
	inc	[pcount]
	call	wipeprompt
	cmp	[remainder],0
	jbe	ClearPrompt
	cmp	[pcount],4
	jae	ClearPrompt
	jmp	$10

TooBig:
	call	wipeprompt
	lea	bp,SizeError
	call	writescr
	mov	bx,000fh
T1:
	xor	cx,cx
	loop	$
	dec	bx
	jnz	T1
	mov	cx,0f01h
	mov	dx,104eh
	call	pscroll
	mov	[bootf],0		; clear the boot flag
	jmp	$10

TooSmall:
	call	wipeprompt
	lea	bp,SizeError1
	call	writescr
	mov	bx,000fh

S1:
	xor	cx,cx
	loop	$
	dec	bx
	jnz	S1
	mov	cx,0f01h
	mov	dx,104eh
	call	pscroll
	mov	[bootf],0
	jmp	$10

ClearPrompt label near
	mov	cx,0e01h		; clear rows 14,15
	mov	dx,0f4eh
	call	pscroll
	call	waitfun
	jmp	NoMore1

getWish1 label near
	lea	bp,crt2
	call	writescr
	lea	bp,answer
	call	writescr
	lea	bp,crt3
	call	writescr
	ret

get32wish label near
	lea	bp,msg32
	call	writescr
	mov	al,[yesmsg]
	mov	[res32a+3],al
	lea	bp,res32a
	call	writescr
	lea	bp,res32b
	call	writescr
	ret

Get32Vol proc 	near
	mov	ax,[spt]		; load AX with sectors per track
	mul	[heads]			; multiply that by the number of heads
	push	ax			; now AX is number of sectors per cylinder, save it!
	mov 	cx,ax			; move AX to CX
	mov	ax,0ffffh		; set AX to number of sectors in 32 meg
	div	cx			; divide that by number of sectors per cylinder
	mov	dx,0			; clear out remainder
	pop	cx			; restore number of sectors per cylinder
	call	lmul			; multiply it to get maximum number of sectors/disk
	mov	word ptr[max_sects],ax	; save out that value
	mov	word ptr[max_sects+2],dx
	ret
Get32Vol endp
	

	subttl	Misc Routines
	page

;-----------------------------------------------------------------------;
;  				Dblwadd					;
;  this routine is called at the end of the loop that creates a 	;
;  partition.  Its purpose is to add the total of sectors in the just	;
;  created partition to the number of hidden sectors there are currently;
;  which sets the value to the correct one for the next partition.	;
;-----------------------------------------------------------------------;

DblwAdd	label near		; this routine does a double word addition, I hope
	mov	ax,[hidden]	; dx:ax is accumulator
	mov	dx,[hidden+2]	; cx is amount to add
	add	ax,cx		; cx is the low word of total sectors in this
				; partition
	adc	dx,bx		; bx is the high word of total sectors in this 
				; partition
	mov	[hidden],ax
	mov	[hidden+2],dx
	ret

;********************* decimal-to-binary routine ********************;

dec2bin	proc  near
	xor   ax,ax		 ; ax will contain the result
	cmp	byte ptr [bx],20h
	pushf
	dec	cx
	popf
	jbe	dtb1
	mov	[minsign],'n'
	cmp	byte ptr [bx],'-'     ; check for minus sign
	jne	dtbloop
	mov	[minsign],'y'
dtb1:
	inc	bx
dtbloop:			    ; bx is source address
	mov	dl,[bx]
	cmp	dl,'0'
	jb	dtbwrap
	cmp	dl,'9'
	ja	dtbwrap
	push	dx
	mul	[wd10]
	pop	dx
	and	dx,000fh
	add	ax,dx
	inc	bx
	jmp	dtbloop
dtbwrap:
	cmp	byte ptr [bx],20h
	je	dtb1
	cmp	[minsign],'y'
	jne	dtbret
	neg	ax
dtbret:
	ret

minsign	db	'n'
dec2bin endp

;-----------------------------------------------------------------------;
;	ldiv -- perform long division					;
;									;
;	Entry:								;
;	DX:AX contains double word dividend				;
;	CX    contains divisor						;
;	Exit:								;
;	DX:AX contains double word quotient of dx:ax / cx		;
;	BX contains remainder						;
;	All other registers unchanged					;
;-----------------------------------------------------------------------;

ldiv	proc

	mov	bx,ax		; save low word of dividend
	mov	ax,dx
	xor	dx,dx		; divide 0:high word by cx
	div	cx
	xchg	bx,ax		; high quotient for low of dividend
	div	cx		; divide remainder:ax by cx
	xchg	bx,dx		; return remainder in bx, and
				; restore high word of quotient
	ret
ldiv	endp

;-----------------------------------------------------------------------;
;	lmul -- perform long multiplication				;
;									;
;	Entry:								;
;	DX:AX contains double word to be multiplied			;
;	CX    contains multiplier					;
;	Exit:								;
;	DX:AX contains double word product of dx:ax * cx		;
;	All other registers unchanged					;
;-----------------------------------------------------------------------;

lmul	proc
	push	bx			; save bx because we use it as a temp
	push	ax			; save low word
	mov	ax,dx			; move high to low word
	mul	cx			; multiply high word
	mov	bx,ax			; save out product of high word value
	pop	ax			; restore low word value
	mul	cx			; multiply low word
	add	dx,bx			; add high word to previous product
	pop	bx			; restore bx
	ret
lmul	endp

wipeprompt label near
	push	es
	push	di
	push	ds
	pop	es
	lea	di,ccount+3
	lea	si,blanx
	mov	cx,4
	rep	movsb
	mov	ax,[rightmost]
	mov	[nextpos],ax
	pop	di
	pop	es
	lea	bp,ccount
	call	writescr
	mov	cx,4
	ret

getchar	proc	near
	mov	ah,0
	int	16h
	cmp	al,1bh
	je	g1
	clc
	ret
g1:
	stc
	jmp	g1-1
getchar	endp

display1 label	near
	lea	bp,crt7
	call	writescr
	lea	bp,crt7a
	call	writescr
	mov	ax,di		; es:di addresses mbr. calculate the partition#
	sub	ax,MBRPLEN
	sub	ax,MBRPTAB	; ax is partition number
	mov	cl,4
	shr	al,cl
	xor	ah,ah
	add	al,31h
	mov	[crt8+3],al	; put partition# in message
	mov	al,byte ptr es:[di-MBRPLEN+MBRBI]	; get boot indicator
	test	al,80h		; see if partition is bootable
	jnz	$d1		; yes
	mov	[crt8+14],'N'	; nope
	jmp	short	$d2

$d1:
	mov	[crt8+14],'A'	; yes its active

$d2:
	mov	al,byte ptr es:[di-MBRPLEN+MBRSI]	; is it a mos partition
	mov	ah,[yesmsg]
	cmp	al,01
	je	$d4
	cmp	al,4
	je	$d4
	mov	ah,[nomsg]
$d4:
	mov	[crt8+24],ah
	
	mov	ax,es:[di-MBRPLEN+MBRBS]	; do beginning cylinder
	and	al,0c0h			; strip sector bits
	xchg	ah,al
	mov	cl,6
	shr	ah,cl
	mov	cx,4
	xor	dx,dx			; clear it
	lea	bx,crt8+34		; put the count in the message
	push	ax			; save it for later
	call	bin2dec
	mov	ax,es:[di-MBRPLEN+MBRES]	; do ending cylinder
	and	al,0c0h
	xchg	ah,al
	mov	cl,6
	shr	ah,cl
	push	ax			; save it to do the total cylinders
	lea	bx,crt8+39
	mov	cx,4
	xor	dx,dx			; clear it
	call	bin2dec
	pop	ax			; get ending cylinder back & do total
	pop	bx

$d6:
	sub	ax,bx
	inc	ax			; ending cylinder+1 is total cylinders
	xor	dx,dx
	lea	bx,crt8+46
	mov	cx,4
	call	bin2dec
	lea	bp,crt8
	call	writescr
	inc	[crt8+2]		; do the next row
	ret

initvars label near
	xor	ax,ax		; this routine initializes critical variables
	mov	[remainder],ax	; in case the create function is re-invoked in
	mov	[endcyl],ax
	mov	[maxcyl],ax
	mov	[mcount],ax
	mov	[pcount],ax
	mov	[totsec],ax
	mov	[totsec+2],ax	; clear out sector count
	lea	ax,ccount+6
	mov	[nextpos],ax
	mov	[crt8+2],10	 ; reset this row spec
	mov	al,[yesmsg]
	mov	[answer+3],al
	ret

waitfun proc	near
	lea	bp,waitmsg
	call	writescr
$wait1:
	call	getchar
	cmp	al,0dh
	je	$wait2
	cmp	al,1bh
	jne	$wait1
$wait2:
	ret
waitfun endp

create	endp

;	replace?  replaces char after # in string (CS:DI) with AL
;	destroys di

replace?:			; replace ? in string with AL
	push	es
	push	ax
	push	cx
	mov	cx,ds		; get GRP segment in ES
	mov	es,cx		; and a large value in CX
	mov	al,'#'
	repnz scasb		; find ? in string
	pop	cx
	pop	ax
	mov	[di],al
	pop	es		; restore ES
	ret
	
;	findansw  returns (AX) offset of answer '<' in string (CS:DI)
;	similar to above but returns length to answer

findansw:
	push	es
	push	cx
	mov	ax,ds		; get GRP segment in ES
	mov	es,ax
	mov	cx,-1		; large value in CX
	mov	al,'<'
	repnz scasb		; find ? in string
	not	cx
	dec	cx		; get length to '<'
	mov	ax,cx
	pop	cx
	pop	es		; restore ES
	ret
	

	
moss	ends
hdsetup	endp

	include	mbr.inc

	end	hdsetup


