	include page.inc
	title DISKCOPY.COM - Diskcopy utility for PC-MOS/386
;
;*****************************************************************************
;*                                                                           *
;*                        MOS Development Specification                      *
;*                                                                           *
;* Command type: External		Assigned to: Robert M. Wright	     *
;* Command name: DISKCOPY.COM		Date assigned: 1/20/87		     *
;*					Date completed:			     *
;* Command format: DISKCOPY [d:] [d:]					     *
;* Purpose: copy floppy diskettes					     *
;* Refer to: DOS reference manual					     *
;* Last Update: 02/19/87		By: Robert M. Wright		     *
;*              03/04/87                    BMW                              *
;*            Added Version checking and fix a problem of the reverse routine*
;*            printing to page 3 of the video instead of page 0.             *
;*             05/18/87		    BMW 				     *
;*            changed comparison from signed to unsigned values to account   *
;*            rollover( if we have over 8000h paragraphs of free memory we   *
;*            had a problem when we compared to see if we had enough to read *
;*            another cylinder.)				             *
;*                                                                           *
;*                                                                           *
;*	External		Values			Values		     *
;*	routines		passed			returned	     *
;* ------------------------------------------------------------------------- *
;*        none                                                               *
;* ------------------------------------------------------------------------- *
;*                                                                           *
;*                        *** General Program Logic ***                      *
;*                                                                           *
;*  Call's syntax:  Diskcopy  <S:> <D:>                                      *
;*                                                                           *
;* The program sets up its own stack after the program is loaded by calcu-   *
;* lating the first avaible paragraph address that is 3k past the end of the *
;* program and sets the SP to that point.  The program then resizes the cur- *
;* rent memory to point only from the top of the program to the top of the   *
;* stack.  Then request a block of memory that consists of 0FFFFh paragraphs *
;* and take what you can get.  Next check the version of the O/S that is     *
;* running, if it is not 3.20 PC-DOS or PC-MOS/386 then abort with an error. *
;* The program then begins to parse the command line to make sure that the   *
;* command that the user input was syntantically correct and contained the   *
;* proper information.  The program then displays the diskcopy banner and    *
;* request the user to insert the diskette that they wish to copy into the   *
;* first disk they specified on the command line.  The program then checks   *
;* to see if the machine has two physical disk drives if so it sets the      *
;* appropriate flag to indicate such. The program then issues a command to   *
;* build the BPB for the diskette in the first drive specified on the command*
;* line.  The program next calculates from the information returned from the *
;* build BPB call the number of paragraphs needed to store one cylinder of   *
;* the disk, if you do not have enough paragraphs returned from your get     *
;* memory call to store one cylinder then abort program with a error message.*
;* If every thing checks out up to this point then set the current drive to  *
;* the first drive specified on the command line and begin reading the disk  *
;* using the generic IOCTL calls to read a track at a time.  Inside of the   *
;* read disk routine there is a loop controler that reads the track of each  *
;* head of the drive and stores it in a reserved block of memory that is set *
;* according to the track and head currently being read.  When the routine   *
;* that sets the block of memory used to save a diskette's information runs  *
;* out of available memory then it calls a routine to dump the reserved      *
;* memory out to the disk to be copied to.  The dump buffer routine calls    *
;* the write disk routine and specifies the first and last cylinder to write *
;* and begins a loop to include only these in the dump.  The program then    *
;* prompts the user of a single drive system to insert the diskette to be    *
;* to in the drive and hit a key.  The write disk routine sets the current   *
;* disk to be the destination disk to avoid MOS from issuing the message for *
;* the user to exchange the disk.  The write routine then uses the set device*
;* call to set the BPB and track layout of the destination disk drive.  The  *
;* write routine next checks to see if the destination disk is formatted if  *
;* so then it doesn't bother to format any tracks unless it gets an error.   *
;* If the destination disk is not formatted then the routine formats each    *
;* track before it writes to it.  When the write routine finishes the loop   *
;* if it was called from dump buffer then set the buffer pointer back to the *
;* beginning of free memory and sets the beginning track number of the next  *
;* write disk call and returns to read disk.  When read disk completes its   *
;* loop then it calls write disk and goes through its loop.  Then if there   *
;* was enough free memory available to copy the disk in a single pass the    *
;* program ask the user if they would like to copy that disk again if so the *
;* program resets the necessary flags and calls write disk again.  It then   *
;* prompts the user if the would like to copy another disk if so then it     *
;* resets the appropriate flags and starts the main loop over again.         *
;*                                                                           *
;* Diskcopy uses the generic IOCTL functions to accomplish its tasks.        *
;*                                                                           *
;*                                                                           *
;*****************************************************************************
;
	subttl	group segments for code, data and extra segments
	page

;*****************************************************************************
;*                                                                           *
;* The next statement tells the assembler and linker to keep all the segments*
;* together when assembled and linked.					     *
;*                                                                           *
;*****************************************************************************
;


;---------------------------------------------------------------------------;
;	SAH	11/23/87	Change to version 2.00			    ;
;---------------------------------------------------------------------------;
;	SAH     09/01/88	Corrections for 1.44M drives		    ;
;---------------------------------------------------------------------------;
; PTR133 10/11/88 RKG	Clear Key Buffer before accepting start character   ;
;			Replace version checking and copyright		    ;
;---------------------------------------------------------------------------;
;	RKG002	11/02/88	Changes for translation problems	    ;
;---------------------------------------------------------------------------;
;	SAH	03/20/89	Remove 386, Up version to 3.10		    ;
;---------------------------------------------------------------------------;
;	BWR	11/27/89	Messages marked for foreign language        ;
;				translation.				    ;
;---------------------------------------------------------------------------;
;       RSR     02/28/92        Modified for finding and displaying a       ;
;                               720K disk                                   ;
;---------------------------------------------------------------------------;
;	SAH     04/17/92	Update version to 5.01 and copyright        ;
;---------------------------------------------------------------------------;

ADVANCE equ	0

grp	group	moss,gdata	; use gdata to define any global data.

gdata	segment para public 'code'
gdata	ends

	page

MOSS	segment	para public 'code'
	assume cs:grp;ds:grp;es:grp

dc_start label 	byte

	org	100h			;skip to end of the psp
diskcpy	proc	near
	jmp	begin			; jump around data area	

;*****************************************************************************
;                                                                            *
;       	 	Title Screen and copyright notice                    *
;                                                                            *
;*****************************************************************************
                       
	db	8,8,8,'   '
dctsl:	db	13,10,'PC-MOS Diskcopy Utility v5.01 (920417)' ;@@XLAT
	
	if	ADVANCE
	db	' - Advance Product Release' ;@@XLAT
	endif

	db	13,10
	include	copyrit.inc
	db	13,10
	db	'All rights reserved worldwide ',13,10,'$' ;@@XLAT
	db	8,' '
dc_syntax:
	db	13,10,'Syntax:   Diskcopy  <S:> <D:>   ',13,10 ;@@XLAT
	db	      '          Where <S:> =  Source Drive         ',13,10 ;@@XLAT
	db	      '                <D:> =  Destination Drive        ',13,10,'$' ;@@XLAT
	db	8,' ',26	

	include diskcopy.pub

;*****************************************************************************
;									     *
; 			Message Definition Area				     *
;									     *
;*****************************************************************************

	dc_error_header	db	13,10,13,10,'Diskcopy Error - $ ' ;@@XLAT
	dc_fix_dsk_err1	db	'Source drive can not be a fixed disk!   ' ;@@XLAT
			db	13,10,'$'
	dc_fix_dsk_err2	db	'Destination drive can not be a fixed disk!              ' ;@@XLAT
			db	13,10,'$'
	dc_noparams_msg	db	'Parameters missing or invalid              ',13,10,'$' ;@@XLAT
	dc_mem_dealoc	db	'Error in setting memory blocks to lower size            ' ;@@XLAT
			db	13,10,'$'
	dc_mem_alloc	db	'Error in allocating memory blocks           ',13,10,'$' ;@@XLAT
	dc_360k_dsk	db	13,10,'Diskcopying a 360K diskette      ',13,10,'$' ;@@XLAT
	dc_1m_dsk	db     13,10,'Diskcopying a 1.2 MB diskette    ',13,10,'$' ;@@XLAT
        dc_720_dsk     db     13,10,'Diskcopying a 720K diskette      ',13,10,'$' ;@@XLAT
	dc_144_dsk	db	13,10,'Diskcopying a 1.44 MB diskette   ' ;@@XLAT
			db     13,10,'$'
	dc_not_ready	db	'Drive error  -  Check drive!          ',13,10,'$' ;@@XLAT
	dc_bad_dsk_typ  db	'Bad diskette or unsupported media           ',13,10,'$' ;@@XLAT
	dc_press_a_key	db	'Press any key to continue.$         ' ;@@XLAT
	dc_blank_line	db	'                                    ',13,10,'$'
	dc_source_drv	db      13,10
			db	'   Place the ORIGINAL disk in drive ?:  ' ;@@XLAT
			db	0ffh,13,10,13,10,'$'	
	dc_destin_drv	db	13,10
			db	' Place the DESTINATION disk in drive ?: ' ;@@XLAT
			db	0ffh,13,10,13,10,'$'
	dc_copy_again	db	13,10,10
		db	'Do you wish to make another copy of this disk (y/n)? $          ' ;@@XLAT
	dc_copy_another db	13,10,10
			db     'Do you want to diskcopy another disk (y/n)? $     ' ;@@XLAT
	dc_cyl_src_cnt	db	'  Reading disk cylinder number: ',13,'$' ;@@XLAT
	dc_cyl_des_cnt	db      '  Writing disk cylinder number: ',13,'$' ;@@XLAT
	dc_memory_error db	'Insufficent memory to run this program!                           ' ;@@XLAT
			db	13,10,'$'
	dc_cyl_cnt	db	'     $'
	dc_media_err	db	13,10,'MEDIA ERROR - Copy Failed                         ',13,10,'$' ;@@XLAT

	yesmsg		db	'Yes   '  ; for translations ;@@XLAT
	
;*****************************************************************************
;									     *
;  			Equates/Variable Definition Area		     *
;									     *
;*****************************************************************************

	dc_params	equ	80h		; offset for command line variables
	true		equ	1		; set equate for true
	false		equ	0		; set equate for false
	x_for_cyl_cnt	equ	32		; x coordinate for cylinder counter string
	y_for_src_msg	equ	14		; y coordinate for source cylinder message
	y_for_des_msg	equ	16		; y coordinate for destination cylinder message
	x_for_cyl_msgs	equ	0		; x coordinate for cylinder display messages
	x_for_drive_ptr equ	0		; x coordinate for drive pointer
	y_for_src_ptr	equ	7		;  	
	y_for_des_ptr	equ	9
	x_press		equ	2	
	y_press		equ	12		
	y_dsk_type	equ	4

	number_of_heads db	0		
	chk_format	db	0		; flag to show if you need to check to 
						; see if disk is formatted
	formatted	db	0		; flag to show if destination disk is formatted
	not_first_write	db	0		; flag to show if this is the first write
						; to this disk
	drive		db	0		; temp value for drive variable
	disk_typ	db	0		; variable to show (0=360 1=1.2 meg)
	dsk_cnt		db	0		; variable for parse command to seperate drives
	source_drv	db	0		; variable to hold source drive value
	destin_drv	db	0		; variable to hold destin drive value
	same_drive	db	0		; flag to tell if (=1 copying to same disk drives)
						;                 (=0 copying to different disk drives)
	single_pass	db	0		; flag to if copy can be done in
						; a single pass (1=yes 0=no)
	track_num	db	0		; current track being read/written
	sector_siz	dw	0		; size of sectors on disk
	num_cyls	dw	0		; number of cylinders to copy
	sects_per_trk	dw	0		; number of sectors per track
	Total_tracks	db	0		; total num of tracks to be copied
	head_num	db	0		; current head being read/written 
	buff_offset	dw	0		; amount of memory required to buffer each track
	buff_size	dw	0		; total amount memory required to store disk
	start_seg	dw	0		; starting segment of heap buffer
	start_off	dw	0		; starting offset of heap offset
	curr_seg	dw	0		; current segment value
	num_paras	dw	0		; number of paragraphs allocated
	rem_num_paras	dw	0		; number of paragraphs remaining
	count		dw	0		; count variable
	stack_top	dw	0		; pointer to top of stack
	buff_reset	db	0		; if set to true the set curr_seg to start_seg
	temp		dw	0
	temp1		dw	0
	end_cnt		dw	0
	start_cnt	dw	0
	read_flag	dw	0
	bad		dw	0
	row		db	0
	col		db	0
	recopy		db	0
	bad_read	db	0		; count for read errors encountered
	bad_write	db	0		; count bad writes
	MAXWRIT		equ	5		; maximum write try count
	another		db	0
	media_type	db	0
	two_drvs	db	0		; flag indicating two physical drives
	same_drv	db	0		; flag indicating same drive letter
	first_call	db	0		; flag indicating that the insert source disk
						; message has been printed already

;*****************************************************************************
;									     *
;  			Structures Definition Area			     *
;									     *
;*****************************************************************************


;
; allowable dt values are as follow: 0 - 320/360k 5.25 inch drive
; 1 - 5.25" 1.2m   2 - 3.50" 720k drive   3 - 8" single density
; 4 - 8" double density   5 - fixed disk   6 - tape drive   7 - other
; we will allow only 0 - 2 and 5
;

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

; This is the track layout
	_totsec	dw	0h
	_s1	dw	1h	; sector number
	_ss1	dw	200h	; sector size in bytes
	_s2	dw	2h
	_ss2	dw	200h
	_s3	dw	3h
	_ss3	dw	200h
	_s4	dw	4h
	_ss4	dw	200h
	_s5	dw	5h
	_ss5	dw	200h
	_s6	dw	6h
	_ss6	dw	200h
	_s7	dw	7h
	_ss7	dw	200h
	_s8	dw	8h
	ss8	dw	200h
	_s9	dw	9h
	ss9	dw	200h
	_s10	dw	0ah
	ss10	dw	200h
	_s11	dw	0bh
	ss11	dw	200h
	_s12	dw	0ch
	ss12	dw	200h
	_s13	dw	0dh
	ss13	dw	200h
	_s14	dw	0eh
	ss14	dw	200h
	_s15	dw	0fh
	ss15	dw	200h
	_s16	dw	10h
	ss16	dw	200h
	_s17	dw	11h
	ss17	dw	200h
	_s18	dw	12h
	ss18	dw	200h
	_s19	dw	13h
	ss19	dw	200h
	_s20	dw	14h
	ss20	dw	200h	
_devp	ends


_formatp	struc		; a format packet for i/o format/verify call
	_fpsf	db	0	; special function byte
	_fphdn	dw	0	; head number
	_fpcyl	dw	0	; cylinder number
_formatp	ends

_rwpack	struc			; read/write logical track packet
	_rwpsf	db	0	; special functions byte
	_rwphd	dw	0	; head
	_rwpcyl	dw	0	; cylinder
	_rwpfs	dw	0	; starting sector - 0 based
	_rwpns	dw	1	; number of sectors - 0 based
	_rwpbuf	dw	2 dup(0); transfer address
_rwpack	ends

odevp	_devp	<>		; use the defaults

save_devp  _devp  <>		; save the orignal BPB

fp1	_Formatp	<>	; format packet

rwp	_RWpack	<>		; read/write packet



;*****************************************************************************
;									     *
;  			Begin Main Procedure   				     *
;									     *
;*****************************************************************************
		
begin:					; Start Program
	include	verschk.inc		; check version and exit

	call	set_stack		; calculate the value for the top of stack
	mov	sp,[stack_top]		; move stack pointer to top of new stack
	call	getmem			; get all available memory
	call	num_drvs		; get the number of drives the system has
	call	parse			; parse command line
	call	valid_drvs		; be sure drives are not hard drives
	call	set_drv_msg		; set drive letters in insert messages
start:
	call	get_banner		; clear the screen and show banner
	mov	read_flag,true		; set initial flag of read to true
	call	display_msg		; display the insert disk message
	call	drv_type		; determine what type of drive you have
	call	set_dsk_off		; get the number of paragraphs required to 
					; store one cylinder
	call	set_drv_flg		; set last logical drive used 
	call	read_dsk		; read tracks to a disk	
   redo_disk:	
	cmp	recopy,true		; Do you want another copy of the same disk
	jne	no_header		; no, don't reprint cylinder counter header
   writ_head:
	call	show_cyl_header		; yes, show cylinder counter header
   no_header:
	call	writ_dsk		; write tracks to a disk
	jz	writ_ok
	lea	dx,dc_error_header
	call	print
	lea	dx,dc_media_err		; display bad media message
	call	print
	call	beep			; wait to continue
	call	press
	mov	read_flag,true		; set read flag to true
	call	set_drv_flg		; set drive flag
	call    re_copy			; see if user wants copy on other disk
	cmp	recopy,true		; well does he!
	jz	writ_head
	jmp	ask_another
	
writ_ok:	
	mov	read_flag,true		; set read flag to true
	call	set_drv_flg		; set drive flag
	call    re_copy			; see if user wants another copy of the same disk
	cmp	recopy,true		; well does he!
	je	redo_disk		; yes, do it!
	call	init_device		; initialize the drive
ask_another:
	call	copy_another		; see if user wants to copy another disk
	cmp	another,true		; check his replay	
	je	start			; yes, go to start
	jmp	exit			; done! exit program


;*****************************************************************************
;									     *
;  			Begin Parsing Routine  				     *
;  Get the drive letters and make sure that the drive letters are followed by*
;  a colon.   								     *
;                 Example command line:  diskcopy a: b:			     *
;									     *
;*****************************************************************************

parse	proc	near

	mov	si,dc_params 		; Set SI to point to arguments
	inc	si			; point to first character of command line
dc_parse:
	mov	[Dsk_cnt],0		; Initialize counter	
	lodsb				; Load the first byte from SI location
	cmp	al,13			; If character is a CR then No params
	jz	dc_noparams		; Jump to no parameters' routine
	mov	bx,offset DC_PARAMS
	
getdrv:
	inc	bx			; point to first character of passed info
	call    findnb			; find the first non-blank
	jnc	is_drive		; if no carry see if it is a real drive 
	jmp	dc_noparams		; if carry bogus information leave
	
is_drive:
	mov	al, byte ptr [bx]	; get the drive letter
	and	al,0dfh			; turn to upper case
	mov	[drive],al		; save out drive to temp name
	cmp	al,'A'			; is letter 'A' or greater?
	jae	is_hi			; yes.
	jmp	dc_noparams		; no, bad drive letter!

is_hi:
	cmp	al,'Z'			; is letter 'Z' or less?
	jbe	is_colon		; yes.
	jmp	dc_noparams		; no, bad drive letter!

is_colon:
	cmp	byte ptr [bx+1],':'	; is there a colon after letter
	je	got_drive		; yes!
	jmp	dc_noparams		; no, bad drive letter!

got_drive:				
	sub	al,40h			; set drive to correct val a=1 etc.
	mov	[drive],al		; Save this letter it is a valid drive
	cmp	[dsk_cnt],1		; Is this the first past
	je	set_second_drv		; Yes, set drive to source drive
set_first_drv:
	mov	al,byte ptr [drive]	; move drive number to al
	mov	[source_drv],al		; Set source drive to current drive
	inc	[dsk_cnt]		; increment counter for parse line
	inc	bx			; increment parse line position indicator
	inc	bx			; increment parse line position to 1 past the ':'
	jmp	getdrv			; continue loop
set_second_drv:
	mov	[destin_drv],al		; No, set destination drive
	jmp	leave_parse		; check if either drive is a fixed disk

;         end parsing routine

dc_noparams:
	lea	dx,dc_error_header	; Point to error message header
	call	print			; print header message
	lea	dx,dc_noparams_msg	; Point to specific error message
	call	print			; print no parameters passed message
	jmp	exit_error		; Jump to error routine

leave_parse:

	ret

parse	endp


;*****************************************************************************
;									     *
;  			Begin Valid Drive Procedure 			     *
;   	!!!!  WARNING THIS SECTION NEEDS TO BE REMOVED TO ALLOW THE          *
;	      COPYING OF HARD DISK                                   !!!!    *
;*****************************************************************************

valid_drvs  proc  near

	mov	ax,4408h			; set function to 44h subroutine 08h
	mov	bl,[source_drv]			; set drive number to check to source	
	int	21h				; call dos
	cmp	ax,0				; does ax = 0
	je	next_dsk			; yes, check next disk
	lea	dx,dc_error_header		; no, print error message header
	call	print			
	lea	dx,dc_fix_dsk_err1		; no, print exact error message
	call	print
	jmp	exit_error			; goto exit with error routine
   next_dsk:
	mov	ax,4408h			; set function to 44h subroutine 08h 
	mov	bl,[destin_drv]			; set drive number to check to destination 
	int	21h				; call dos
	cmp	ax,0				; does ax = 0
	je	leave_valid			; yes, see if diskettes are formatted
	lea	dx,dc_error_header		; no, print error message header
	call	print				
	lea	dx,dc_fix_dsk_err2		; no, print exact error message
	call	print				
	jmp	exit_error			; goto exit with error routine

   leave_valid:
	mov	al,[source_drv]		; load source drive in al	
	cmp	al,[destin_drv]		; test value of al against value of destination drive
	jne	lv_valid		; if not equal skip over the assignment 
	mov	same_drv,true		; set same drive flag to true
	mov	two_drvs,false		; set two_drvs flag off
   lv_valid:

	ret

valid_drvs  endp	

;*****************************************************************************
;									     *
;  		     Recopy Same disk (y/n) ?  				     *
;									     *
;*****************************************************************************

re_copy	proc	near
	
	cmp	single_pass,true		; was the copy a single pass
	jne	leave_re_copy			; no, forget it!	

	mov	recopy,false			; yes, set response to false
	mov	dx,0				; set subfunction value
	call	again				; call again routine
	mov	recopy,dl			; move answer into recopy
	cmp	recopy,true			; well, is it true or what?
	jne	leave_re_copy			; no, bye!
	call	get_banner			; display diskcopy banner!
	mov	not_first_write,false		; reset first time write flag
	mov	read_flag,false			; set read flag to that I am writing
	mov	chk_format,false		; set flag so that we check the format
	mov	first_call,false
	mov	formatted,false			; set flag to false because, at this point we don't
						; know?
	call	set_drv_flg			; set logical flag for destination drive

   leave_re_copy:
	ret					; say Good-bye guys!

re_copy endp

;*****************************************************************************
;									     *
;  		     See if we want to copy another disk		     *
;									     *
;*****************************************************************************

copy_another proc	near
	
	mov	another,false			; set flag's initial value to false 
	mov	dx,1				; set subfunction call value
	call	again				; call again routine
	mov	another,dl			; move returned value to another flag
	mov	chk_format,false		; reset chk_format flag
	mov	formatted,false			; reset formatted flag
	mov	first_call,false
	mov	not_first_write,false		; this is not the first write, reset flag
	ret					; bye!

copy_another endp



;*****************************************************************************
;									     *
;  			Get Drive Type Procedure 			     *
;									     *
;    Determine what type of drive you are copying by using the get device    *
;    function of the generic IOCTL.  Determine the number of heads and 	     *
;    cylinders by reading the BPB that is returned as well reading the media *
;    type byte to determine if a 360/320k disk is being copied inside of a   *
;    1.2 meg drive.							     *
;									     *
;*****************************************************************************

drv_type:
	mov	ax,440dh		; set function to use generic IOCTL call
	mov	cx,0860h		; set function for get device params call
	lea	si,odevp		; set si to point to the parameter block header
	mov	[si]._sf,1		; set special flag to build BPB block
	mov	dx,si			; mov header offset to dx
	mov	bl,[source_drv]		; set drive to read parameters from
	int	21h			; call MOS

	mov	ax,440dh		; set function to use generic IOCTL call
	mov	cx,0860h		; set function for get device params call
	lea	si,save_devp		; set si to point to the parameter block header
	mov	[si]._sf,0		; set special flag to build BPB block
	mov	dx,si			; mov header offset to dx
	mov	bl,[source_drv]		; set drive to read parameters from
	int	21h			; call MOS

	lea	si,odevp		; set si to point to the parameter block header
	mov	cx,[odevp]._bps		; move the number of bytes per sector to cx
	mov	[sector_siz],cx		; move cx to sector_siz


	mov	bl,byte ptr [si]._md	; move media descriptor to bl
	cmp	bl,0fdh			; compare bl to byte value of a 360k disk
	jne	ck_4_1m			; if they are not equal go check to see if 
					; it is a 1.2 meg diskette
	mov	dx,40			; move the number of cylinders to cl
	mov	[num_cyls],dx		; store cl in the variable "num_cyls" 
	mov	[media_type],1
	lea	dx,dc_360k_dsk		; move 360k disk message offset to dx
	jmp	leave_rout		; done! return

ck_4_1m:
	cmp	bl,0f9h			; compare bl to byte value of a 1.2M
	jne	ck_4_7k			; if not a 1.2M go check to see if
					; it is a 720k diskette
	mov	dx,80			; move the number of cylinders to cl
	mov	[num_cyls],dx		; store cl in the variable "num_cyls" 
	mov	[media_type],0
        cmp     byte ptr [si]._spt,9
	je      ck_4_1ma
        lea	dx,dc_1m_dsk		; move 1.2M disk message offset to dx
        jmp     ck_4_1mb
ck_4_1ma:
        lea     dx,dc_720_dsk
ck_4_1mb:
	jmp	leave_rout		; done! return
ck_4_7k:
	cmp	bl,0f0h			; Is this a 1.44M
	jne	bad_type		; jump if not equal to bad message 
	mov	dx,80			; move the number of cylinders to cl
	mov	[num_cyls],dx		; store cl in the variable "num_cyls" 
	mov	[media_type],0		
	lea	dx,dc_144_dsk		; move 1.44M disk message offset to dx
	jmp	leave_rout		; done! return
bad_type:
	lea	dx,dc_error_header	; move error header message to dx
	call	print			; print error header message
	lea	dx,dc_bad_dsk_typ	; move bad disk media message offset to dx
	call	print			; print message
	jmp	exit_error		; done! jump to exit with error routine

   leave_rout:
	mov	[row],y_dsk_type	; set the y value to display disk type string
	mov	[col],0			; set the x value to the first column	
	call	gotoxy			; position cursor 
	call	print			; print it
	ret				; bye!

;*****************************************************************************
;									     *
; Calculate the buffer size and whether or no there can be a single pass copy*
;									     *
;*****************************************************************************

set_dsk_off proc  near

	mov	[single_pass],false	; set single pass flag to false
	mov	ax,word ptr [sector_siz]; store number of bytes per sector in ax
	mov	cl,4			; store 4 in cl
	shr	ax,cl			; divide ax by 16 to leave the number of 
					; paragraphs needed to store a single 
					; sector in ax
	xor	bx,bx			; zero out bx
	mov	bx,[odevp]._spt		; move sectors per track into bx
	mov	[sects_per_trk],bx	; store bx into the variable "sects_per_trk"
	mul	bx			; multiply sectors per track by the number of
					; of paragraphs it takes to store one sector.
					; this leaves the number of paragraphs it
					; takes to store a track in ax 
	shl	ax,1			; multiply contents of ax by two which
					; the number of paragraphs needed to store
					; a cylinder in ax
	mov	[buff_offset],ax	; store ax in buff_offset
	mov	bx,[num_cyls]		; move number of cylinders on disk in bl
	mul	bx			; multiply the number of cylinders by the
					; value of ax which leaves the number of 
					; paragraphs needed to store a disk in ax
	mov	[buff_size],ax		; store ax in buffer size	
	cmp	[num_paras],ax		; compare ax to the number of available
					; paragraphs	
	mov	ax,[num_paras]
	mov	[rem_num_paras],ax	; save the remaining number of paragraphs
	jae	buff_ok			; if ax is less than the number of 
					; available paragraphs then jump to buff_ok
	jmp 	lv_set_buff		; else jump to lv_set_buff
buff_ok:
	mov	byte ptr [single_pass],true ; set single pass flag to true

lv_set_buff:
	ret				; done! leave routine

set_dsk_off endp

;*****************************************************************************
;									     *
;  	Set the segment address of the buffer to store the current Track     *
;	and head in.							     *
;*****************************************************************************

set_marker   proc  near

	push	ax			; save ax
	push	bx			; save bx	
	push	cx			; save cx
			
	mov	dx,[temp]		; get track number 	
	mov	bx,[buff_offset]	; get the number of paragraphs it takes to store
					; a cylinder 
	cmp	read_flag,true		; are we reading or writing the disk?
	jne	step_buff		; we are writing, jump over subtraction!
	cmp	[rem_num_paras],bx	; compare number of paragraphs needed to the 
					; remaining number of paragraphs
	jb	dump_buffer		; if there are less fewer remaining paragraphs
					; dump that buffer

   step_buff:
	sub	dx,[start_cnt]		; subtract the starting track number 
					; from the current track number	
	mov	ax,bx			; store buffer size into ax	
	mul	dx			; multiply the track number times the size
					; of the buffer to point the right paragraph 
					; address
	inc	ax			; add one paragraph to keep from overlapping
	add	ax,[start_seg]		; add starting segment to buffer cylinder offset	

	cmp	[si]._rwphd,0		; is this head 0
	jz	leave			; yes, jump over the following
	
   head_one:
	cmp	read_flag,true		; are we reading?
	jne	no_sub			; no, jump over the subtraction
	sub	[rem_num_paras],bx	; subtract cylinder buffer size from the 
					; remaining number of paragraphs 
   no_sub:
	shr	bx,1			; divide the cylinder buffer size in half
	add	ax,bx			; add one half of the cylinder buffer size
					; to the current value of the segment address
   leave:
	mov	es,ax			; set es equal to the segment address of
					; the cylinder buffer area	
	call	set_device		; set the drive parameters	
	pop	cx			; restore cx
	pop	bx			; restore bx
	pop	ax			; restore ax

	ret				; bye!

   dump_buffer:
	push	bx			; save bx
	push	read_flag		; save read_flag
	push	[end_cnt]		; save end_cnt
	push	[si]._rwphd		; save the head number being read

	mov	[end_cnt],dx		; make end count equal to the next track
					; to be read	
	inc	[end_cnt]		; increment end count by one to compensate
					; for the dec in the first of write disk
;	mov	read_flag,false		; set read flag to show that we are writing now 
;	call	display_msg		; display the insert source disk message
	call	writ_dsk		; write this buffer out

	pop	[si]._rwphd		; restore the head number
	pop	[end_cnt]		; restore the end_cnt value used by read disk

		;***************************************
		;  House keeping section of the dump   *
		;  buffer routine.  Set start_cnt and  *
		;  Reset the remaining number of paras *
		;***************************************     

 	mov	bx,[num_paras]		; store the original number of paragraphs available
					; in bx
	mov	[rem_num_paras],bx	; reset the number of remaining paragraphs to
					; number there was originally
	pop	read_flag		; restore the read flag
	pop	bx			; restore bx
	mov	dx,[temp]		; move the current track number to dx
	mov	[start_cnt],dx		; set the starting count number equal to
					; the current track number
	call	set_device		; call set device
	call	display_msg		; display the insert source disk message
	mov	single_pass,false	; set single pass flag to false
	jmp	step_buff		; return to set marker routine

		;***************************************
		;  End of the dump buffer routine      *
		;***************************************     

set_marker   endp	


;*****************************************************************************
;									     *
;  	Allocation of memory routine:                                        *
;	Resize the current block and allocate the remaining free memory to   *
;	the buffer memory pool to store the the cylinders as they are read.  *
;									     *
;*****************************************************************************

getmem	proc	near
	mov	ax,cs				; store cs to ax
	mov	es,ax				; store ax to es
	mov	ax,[stack_top]			; set memory pool to paragraph
	add	ax,16				; just past top of stack
	lea	bx,dc_start			; get address at start of program
	sub	ax,bx				; get difference of top & bottom
	mov	cl,4				; divide by 16 to get number of paragraphs
	shr	ax,cl				; divide ax by 16	
	mov	bx,ax				; mov number of paragraphs to bx
	mov	ah,4ah				; set up for function call
						; to resize current block
	int	21h				; call dos
	jnc	setmem				; if not an error set up memory pool	
	jmp	exit_error			; else exit with error

setmem: mov	ah,48h				; setup for memory request
	mov	bx,0ffffh			; request 1023k
	int	21h				; call dos
	jnc	gotmem				; if no carry then got 384k
	mov	ah,48h				; else recall with available size
						; set
	int	21h				; call dos
	jnc	gotmem				; if no carry got available memory
	lea	dx,dc_error_header		; else print error header
	call	print				; print message 
	lea	dx,dc_mem_alloc			; print memory allocation error
	call	print				; print message
	jmp	exit_error			; exit with an error

gotmem:	mov	[start_seg],ax			; save segment address 
	mov	[curr_seg],ax			; save curr_seg
	mov	[start_off],0			; set offset to 0
	mov	[num_paras],bx			; save number of paragraphs returns
	mov	[rem_num_paras],bx		; save number of paragraphs left
		
	ret					; done! leave routine
getmem	endp


;****************************************************************************
;                                                                           *
;  Read disk routine:                                                       *
;                                                                           *
;****************************************************************************


read_dsk    proc	near

	mov	read_flag,true		; set the read flag to show that we are reading
	call	show_cyl_header		; display the cylinder counter templates

	push	ax			; store ax--\
	push	bx			; store bx---\	
	push	cx			; store cx-------  Save these even though it
	push	dx			; store dx---/     serves no real purpose 
	push	es			; store es--/

	lea	si,dc_cyl_cnt		; load the offset off the cylinder count
					; message into si
	mov	ax,'  '
	mov	word ptr [si],ax	; blank out the first four chars of message
	mov	word ptr [si+2],ax

	mov	cx,[num_paras]		; move the number of available paragraphs
	mov	[rem_num_paras],cx	; into the remaining number of paragraphs variable
	mov	cx,[num_cyls]		; mov the number of cylinders into cx
					; to be your loop counter
	mov	[end_cnt],cx		; initialize end count to be the number of cylinders
	mov	[start_cnt],0000h	; initialize start count to be 0

	mov	ax,0			; initialize the track counter to be zero

	lea	si,rwp			; initialize si to point to the read/write
					; packet 
	mov	[si]._rwpsf,0		; set the special flag to be zero 
	mov	dx,[sects_per_trk]	; store the number of sectors in dx
	mov	[si]._rwpns,dx		; then transfer them to the number of sectors'
					; field in the read/write packet
	mov	[si]._rwpbuf,0		; initialize the buffer to 0 and it will
					; always be zero, only the segment will
					; be changed

   begin_read_loop:
	mov	[temp],ax		; set temp to hold the current track number
	mov	[si]._rwpcyl,ax		; set the current cylinder number in the read/write packet
	call	display_cyl		; display the cylinder counter
	push	ax			; save the track counter
	push	cx			; save the loop controller

	mov	ax,0			; set ax as the head counter, initialize it to 0
	mov	[bad_read],0

	inner_loop:			; this is the head loop
		mov	[si]._rwphd,ax  ; set the head number in the read/write packet
		push	ax		; save the head number
		call	set_marker	; set the buffer segment	
		mov	[si+2]._rwpbuf,es ; set the segment buffer address in read/write packet
		mov	ax,440dh	; set function call value
		mov	bl,[source_drv]	; set drive number
		mov	cx,0861h	; set subfunction code for generic IOCTL, read track
		mov	dx,si		; set dx to the offset of the read/write packet
		int	21h		; call MOS
		jc	read_err	; if error is encountered handle it

		pop	ax		; restore head counter
		inc	ax		; inc head counter to the next head
		cmp	ax,2		; compare current head to the number of heads on drive
		mov	[bad_read],0
		jb	inner_loop	; if less than number of heads on drive then loop
	; end of inner loop

	pop	cx			; restore outer loop counter
	pop	ax			; restore track counter
	inc	ax			; step to next track
	loop	begin_read_loop		; loop back if all tracks are not read

	pop	es			; restore es
	pop	dx			; restore dx
	pop	cx			; restore cx
	pop	bx			; restore bx
	pop	ax			; restore ax

	ret				; bye! end of read.
	
read_dsk   endp

read_err:

	inc	[bad_read]
	cmp	[bad_read],9
	jb 	inner_loop
	jmp	extend_err

;****************************************************************************
;                                                                           *
;  Write disk routine:                                                      *
;                                                                           *
;****************************************************************************

writ_dsk    proc	near
	mov	read_flag,false		; set read flag to show that we are writing now 
	call	display_msg		; display the appropriate insert disk message 	
	call	set_device		; set the BPB to match the device parameters
					; return from IOCTL function, get device
	cmp	not_first_write,true	; is this the first time that I have gone through
					; this routine?
	je	no_chk_fmt		; no, skip the check format routine
	call	check_format		; yes, see if the destination disk is formatted
   no_chk_fmt:
	push	ax			;----\
	push	bx			;-----\
	push	cx			;---------   save these(I don't know why?)!
	push	dx			;-----/
	push	es			;----/

	lea	si,dc_cyl_cnt		; load the offset off the cylinder count
					; message into si
	mov	ax,'  '			; blank out first four characters of message
	mov	ax,[si]
	mov	ax,[si+2]

	mov	ax,[start_cnt]		; set ax to the first track to be written 
	mov	cx,[end_cnt]		; set cx to the last value that was read
	sub	cx,ax			; subtract the difference of the two and leave it in cx
	lea	si,rwp			; set si to the offset of the read/write packet

	mov	[si]._rwpsf,0		; set the special function flags to be 0
	mov	dx,[sects_per_trk]	; use dx to move sects per track 
	mov	[si]._rwpns,dx		; into the number of sectors field of the 
					; read/write packet
	mov	[si]._rwpbuf,0		; set the buffer offset to be 0, it won't change


   begin_writ_loop:
	mov	[temp],ax		; set temp to be the current track being written
	mov	[si]._rwpcyl,ax		; set the cylinder field of the read/write packet
					; to be the track being written
	call	display_cyl		; display the cylinder counter
	push	ax			; save the track counter on stack
	push	cx			; save the loop counter on stack
	mov	ax,0			; set ax to be the first head of a track
		
	writ_inner_loop:
		mov	[si]._rwphd,ax	; set head number of read/write packet 
		push	ax		; save head number	
		call	set_marker	; set buffer address
		mov	[si+2]._rwpbuf,es; set buffer segment of read/write packet
		mov	[bad_write],0	; bad format/write counter
		cmp	formatted,true	; is diskette formatted?
		je	no_format	; yes, skip the format
	    format_the_track:
	    	inc	[bad_write]
		cmp	[bad_write],MAXWRIT
		jge	bad_disk	; too many bad format/writes
		call	format		; no, format the track
	    no_format:
		mov	ax,440dh	; set up the function code
		mov	bl,[destin_drv]	; set bl equal to the drive number
		mov	cx,0841h	; set up the sub function call of generic IOCTL	
		mov	dx,si		; set dx to the offset of the read/write packet
		int	21h		; call MOS
		jc	format_the_track; if there is an error writing the track format it!
		pop	ax		; restore head counter
		inc	ax		; increment the head counter
		cmp	ax,2		; is current head number greater the number of drive? 
		jb	writ_inner_loop ; no, loop back
	; end of inner loop

	pop	cx			; restore loop counter
	pop	ax			; restore track counter
	inc	ax			; increment track counter
	loop	begin_writ_loop		; loopback if not done
	xor	ax,ax			; flag write success

wr_dsk_exit:
	pop	es			; restore es
	pop	dx			; restore dx
	pop	cx			; restore cx
	pop	bx			; restore bx
	or	ax,ax			; set ZF for return value
	pop	ax			; restore ax

	ret				; bye! we are done!

bad_disk:
	add	sp,6
	mov	ax,-1
	jmp	wr_dsk_exit
writ_dsk   endp

;*****************************************************************************
;                                                                            *
;    Check the disk to see if it disk is formatted.                          *
;                                                                            *
;*****************************************************************************

check_format proc	near

	push	ax			; save ax
	push	bx			; save bx
	push	cx			; save cx
	push	dx			; save dx
	push	si			; save si
	mov	not_first_write,true    ; set flag to show that we have read the
					; format of the disk already!
	mov	ax,440dh		; set the function code
	mov	bl,[destin_drv]		; set the drive letter
	mov	cx,0862h		; set the generic IOCTL subfunction
	lea	si,fp1			; set si to the offset of format packet
	mov	[si]._fphdn,0		; set head number to be zero
	mov	[si]._fpsf,1		; set special function flag to 1 to verify 
					; format!
	mov	dx,[temp]		; move current track number to dx
	mov	[si]._fpcyl,0		; move current track number to the cylinder
					; field of the format packet
	mov	dx,si			; set dx to the offset of the format packet
					
	int	21h			; call MOS		
	jc	set_not_fmt		; is there an error? yes, go set a flag
	mov	formatted,true		; no, set format flag on
	jmp	leave_fmt_ck		; if formatted I need to be going!  
   set_not_fmt:
	mov	formatted,false		; set the format flag off
	clc				; clear the carry bit
   leave_fmt_ck:
	pop	si			; restore si
	pop	dx			; restore dx
	pop	cx			; restore cx
	pop	bx			; restore bx
	pop	ax			; restore ax
	ret				; bye! we are through here.
check_format endp	


;*****************************************************************************
;                                                                            *
;    Format a track                                                          *
;                                                                            *
;*****************************************************************************

format	proc	near

	push	ax			; save ax
	push	bx			; save bx
	push	cx			; save cx
	push	dx			; save dx
	push	si			; save si
	mov	bad,0			; set error counter to 0
	

	lea	si,fp1			; set si to the offset of the format packet

    f_loop:

	mov	dx,[temp]		; set dx to the current track number
	mov	[si]._fpcyl,dx		; set the cylinder number field in the format packet
	mov	[si]._fpsf,0		; reset the special functions flag of the packet
	mov	ax,0

	inner_fmt_loop:
		push	ax		; save head counter
		mov	[si]._fphdn,ax	; set head number of packet
		mov	ax,440dh	; set function call
		mov	bl,[destin_drv] ; set bl to the desination drive value
		mov	cx,0842h	; set subfunction code
		mov	dx,si		; set dx to point to format packet
		int	21h		; call MOS
		pop	ax		; restore head counter
		inc	ax		; increment head counter
		cmp	ax,2		; are we less than the number of heads?
		jb	inner_fmt_loop	; no, lets go again!

	; end of the inner loop


	pop	si			; restore si
	pop	dx			; restore dx
	pop	cx			; restore cx
	pop	bx			; restore bx
	pop	ax			; restore ax
	ret				; say good-bye!

format	endp	

dsk_error:

	mov	ah,59h
	mov	bx,0000h
	int	21h
	
	inc	bad
	cmp	bad,8
	jbe	f_loop
	jmp	exit_error

;*****************************************************************************
;  	       Display insert disk message at the appropriate times          *
;*****************************************************************************

display_msg  proc   near

	push	ax			; save ax
	push	bx			; save bx
	push	cx			; save cx
	push	dx			; save dx

	cmp	two_drvs,true		; see if we have two physical drives on the system 
	jne	one_drive		; if not two drives jump to one_drive routine
	cmp	first_call,true		; If true we have called this routine before
	jne	two_drives		; if not first call process the call
	jmp	leave_msg		; if there is two drives and we have already displayed the
  					; messages leave routine
   two_drives:
	call	two_drvs_msg		; display both the source & destination at once
	call	beep			; beep at the user
	call	press			; tell user to press any key and wait for him
	mov	first_call,true		; set the first call flag to true
	jmp	leave_msg		; leave rotuine, you are done!

   one_drive:
	call	set_drv_flg		; set the MOS next logical drive to keep
					; that damn message, that tells you to 
					; switch disk, from appearing!
	mov	byte ptr [row],y_for_src_ptr   ; set row to the y value of the insert message
	mov	byte ptr [col],x_for_drive_ptr ; set col to the x value of the insert message 
	cmp	read_flag,true		; am I reading the disk?
	jne	disp_des_drv		; no, display the destination drive message.
	lea	bp,dc_source_drv	; yes, display the source drive message	
	call	reverse			; print the message in reverse video
	call	beep			; beep at the user
	call	press			; tell user to press any key and wait for him
	jmp	leave_msg		; we are done! go to end.	
   disp_des_drv:

	lea	bp,dc_destin_drv	; load the offset of the destination message
	call	reverse			; print the message in reverse video	
	call	beep			; beep at the user
	call	press			; tell user to press any key and wait for him

   leave_msg:   
	pop	dx			; restore dx
	pop	cx			; restore cx
	pop	bx			; restore bx
	pop	ax			; restore ax

	ret				; bye! leave routine.

display_msg  endp

;*****************************************************************************
;                                                                            *
;    Display both the source and destination message at the same time        *
;                                                                            *
;*****************************************************************************

two_drvs_msg  proc  near

	push	dx			; save dx
	mov	[row],y_for_src_ptr	; set row to y value of source disk message
	mov	[col],0			; set col to be column 1
	call	gotoxy			; set the cursors position
	lea	dx,dc_source_drv	; load dx with the offset of the source message
	call	print			; print message
	mov	[row],y_for_des_ptr	; set row to y value of destination disk message
	call	gotoxy			; set the cursors position
	lea	dx,DC_destin_drv	; load dx with the offset of the destination message
	call	print			; print message
	pop	dx			; restore dx	
	ret				; bye! return to whence it came.

two_drvs_msg  endp

;*****************************************************************************
;                                                                            *
;    Reinitialize the BPB of the source drive.                               *
;                                                                            *
;*****************************************************************************

init_device  proc   near

	push	ax			; save ax
	push	bx			; save bx
	push	cx			; save cx
	push	dx			; save dx

	mov	read_flag,true		; set read flag back to true

	call	set_drv_flg		; set drive to point	
	mov	ax,440dh		; set function code
	mov	bl,[source_drv]		; set bl to drive number
	mov	cx,0840h		; set subfunction code
	lea	dx,save_devp		; set dx to be the offset of the default
					; BPB of the device
	int	21h			; call MOS

	pop	dx			; restore dx
	pop	cx			; restore cx
	pop	bx			; restore bx
	pop	ax			; restore ax	

	ret				; bye!

init_device  endp
			
;*****************************************************************************
;                                                                            *
;    Set the device parameters through generic IOCTL                         *
;                                                                            *
;*****************************************************************************

set_device  proc   near

	push	ax			; save ax
	push	bx			; save bx
	push	cx			; save cx
	push	dx			; save dx	
	push	si			; save si
	push	es			; save es
	push	di			; save di
	
	mov	ax,440dh		; set function code
	mov	bl,[drive]		; set drive number
	mov	cx,0840h		; set sub_function code to set device
	lea	si,odevp		; set si to the offset of the BPB packet
	mov	dx,[sects_per_trk]	; set dx to the number of sectors per track
	mov	word ptr [si]._totsec,dx; set the total sectors field of the BPB block to be 
					; the number of sectors per track
	mov	dl,byte ptr [media_type]; set dl to be the media type return from the
					; get device call made for source drive 
	mov	byte ptr [si]._mt,dl	; set media type field of BPB to be dl
   over:	
	mov	byte ptr [si]._sf,4	; set bit 2 of special flag field in the BPB
					; to indicate that all sectors are of the same size
	mov	dx,[num_cyls]		; copy number of cylinders to dx
	mov	word ptr [si]._nc,dx	; copy dx to number of cylinders' field in the BPB

   go_set:
	mov	dx,si			; set dx equal to the offset of the BPB block

	int	21h			; call MOS
	jc 	dsk_error1		; if there is an error go take care of it!
   bye:

	pop	di			; restore di
	pop	es			; restoer es
	pop	si			; restore si
	pop	dx			; restore dx
	pop	cx			; restore cx
	pop	bx			; restore bx
	pop	ax			; restore ax
	ret				; bye!

dsk_error1:

	mov	ah,59h			; set function to get extended error code
	mov	bx,0000h		; zero out bx
	int	21h			; call MOS
	
	jmp	bye			; jump to bye!

set_device  endp

;*****************************************************************************
;                                                                            *
;    Set the last logical drive used                                         *
;                                                                            *
;*****************************************************************************

set_drv_flg  proc  near

	push	ax			; save ax
	push	bx			; save bx
		
	mov	ax,440fh		; set function code to set how a device was
					; was last listed
	cmp 	read_flag,true		; are we reading the disk? 
	je	set_source		; yes, go set the next reference to be the source
					; drive.
	mov	bl,[destin_drv]		; set bl to destination drive number
	jmp	call_set		; jump to the setting routine

   set_source:
	mov	bl,[source_drv]		; set bl to the source drive number
	
   call_set:
	int	21h			; call MOS

	pop	bx			; restore bx
	pop	ax			; restore ax

	ret				; bye! 

set_drv_flg  endp

;*****************************************************************************
;                                                                            *
;    Calculate the values to set up a new stack                              *
;                                                                            *
;*****************************************************************************

set_stack proc	near
	lea	bx,lastbyte+3087	; set bx to lastbyte of program plus the
					; value of 1000 words plus 15 bytes to push
					; significant values to paragraph boundaries
	and	bx,0fff0h		; set bx to equal the starting value of a boundary
	mov	[stack_top],bx		; store bx to the value "stack_top"
	ret				; return to calling routine
set_stack endp				; end of routine

;*****************************************************************************
;                                                                            *
;    Determine the number of physical disk that a user has.                  *
;                                                                            *
;*****************************************************************************

num_drvs proc	near

	push	ax			; save ax
	
	mov	two_drvs,false		; set flag to false just in case
	int	11h			; call bios
	and	ax,0041h		; and function so ax only contains relevant bits
	cmp	al,1			; is al greater than 1?
	jbe	leave_num		; no, we have one drive!
	mov	two_drvs,true		; yes, we have at least two drives!
   leave_num:
	pop	ax			; restore ax
	ret				; bye! we're done!

num_drvs  endp
		
;*****************************************************************************
;                                                                            *
;                    Set drive letter in insert message                      *
;                                                                            *
;*****************************************************************************

set_drv_msg proc near	
	
	lea	di,dc_source_drv	; move the offset of source message into si
	mov	ah,[source_drv]		; store contents of source_drv into bl
	call	replace?		; place drive letter in source disk message
	lea	di,dc_destin_drv	; move the offset of destination message into si
	mov	ah,[destin_drv]		; store contents of source_drv into bl
	call	replace?		; place drive letter in destination disk message
	ret				; done! leave routine

replace?:			; string may be variable length 	RKG002
	mov	al,'?'		; replace ? in string 
	or	ah,64		; ensure drive is upper case
	mov	cx,ax		; large value in CX
	repnz	scasb		; find ? in string
	mov	[di-1],ah	; stuff drive char in string
	ret

set_drv_msg endp

;*****************************************************************************
;									     *
;  		     Display Diskcopy banner            		     *
;									     *
;*****************************************************************************

get_banner  proc   near

	call 	cls			; clear the screen	
	mov	dx,offset dctsl		; Point to Banner for Diskcopy
	call	print			; Display diskcopy banner
	ret				; bye!

get_banner  endp	

;*****************************************************************************
;                                                                            *
;                  Copy same disk again or another routine                   *
;                                                                            *
;*****************************************************************************

again	proc	near			 
	cmp	dx,1			; compare dx to 1
	je	do_anth			; if 1 then jmp to copy another disk
	lea	dx,dc_copy_again	; else store the offset of copy disk again
					; message in dx
	call	print			; print copy disk again message
	call	getYN			; get a yes or no response
	jmp	leave_again		; go handle response

do_anth:
	lea	dx,dc_copy_another	; store the offset of copy another disk message
	call	print			; print message
	call	getYN			; get a yes or no response
leave_again:				
	ret				; done! leave routine

again	endp

	
;*****************************************************************************
;                                                                            *
;                        Get Yes or No response	                 	     *
;                                                                            *
;*****************************************************************************

getYN	proc	near
	mov	ax,0C01h		; clear buffer read key		PTR133
	int	21h
	and	al,0dfh			; convert al value to upper case
	mov	dl,al			; store al in dl

	cmp	al,[yesmsg]		; if answer is 'Y'
	jne	not_y			; no! goto not_y
	mov	dx,true			; yes! store true in dx for return
	jmp	leaveyn			; jmp to end of routine
not_y:	mov	dx,false		; store false in dx for return

leaveyn: 
	push	dx
	lea	dx,dc_blank_line	; store offset of blank line message
	call	print			; print blank line
	pop	dx			; restore dx
	ret				; done! leave routine

getYN   endp

;*****************************************************************************
;                                                                            *
;                            Press a Key Routine                             *
;                                                                            *
;*****************************************************************************

press	proc	near
	push	ax			; save ax
	push	dx			; save dx
	mov	byte ptr [col],x_press  ; load col with the x value of the message
	mov	byte ptr [row],y_press  ; load row with the y value of the message
	call	gotoxy			; call cursor position routine	
	lea	dx,dc_press_a_key	; load offset of press any key message
	call	print			; print message
	mov	ax,0C08h
	int	21h			; clear buffer get key no echo 	PTR133
	mov	byte ptr [col],x_press  ; load col with the x value of the message
	mov	byte ptr [row],y_press  ; load row with the y value of the message
	call	gotoxy			; call cursor position routine
	lea	dx,dc_blank_line	; load offset of blank line message
	call	print			; print blank line
	pop	dx			; restore dx
	pop	ax			; restore ax	
	ret				; done! leave routine
press	endp	

;*****************************************************************************
;                                                                            *
;                          Print string routine                              *
;                                                                            *
;*****************************************************************************

print	proc	near
	push	ax			; save ax
	mov	ah,9h			; store 9 in ah register - print a string
					; function
	int	21h			; call MOS
	pop	ax			; restore ax
	ret				; done! leave routine
print	endp

;*****************************************************************************
;                                                                            *
;                GotoXY:  Cursor position routine                            *
;                                                                            *
;*****************************************************************************

gotoxy  proc    near
	push	ax			; save ax
	push	bx			; save bx
	push	dx			; save dx

	mov	ah,2			; set function to 2 - position cursor
	mov	bx,0			; set page to current
	mov	dh,byte ptr [row]	; set dh to the y coordinate
	mov	dl,byte ptr [col]	; set dl to the x coordinate	
	int	10h			; call BIOS

	pop	dx			; restore dx
	pop	bx			; restore bx
	pop	ax			; restore ax
	ret				; bye! leave routine.

	gotoxy	endp

;*****************************************************************************
;                                                                            *
;                        Clear the screen function                           *
;                                                                            *
;*****************************************************************************

cls	proc	near
	;
	  xor	al,al		     	; zero al	
	  mov	ah,6 		     	; function 6 = scroll a window up
	  mov	bh,7		     	; normal video
	  mov	ch,0		     	; upper left y of window
	  mov	cl,0		     	; upper left x of window
	  mov	dh,24		     	; lower right y of window
	  mov	dl,79		     	; lower right x of window
	  int	10h			; call BIOS
	  mov	dx,0			; set dx to home cursor position
	  mov	bx,0 		        ; set bx to be video page 0
	  mov	ah,2	     	     	; set cursor position function
	  int	10h		     	; call BIOS
	  ret				; its clear! Bye!

cls	endp

;*****************************************************************************
;                                                                            *
;                    Find next non-blank character                           *
;                                                                            *
;*****************************************************************************

findnb	proc	near
	mov	al,byte ptr [bx]	; store bl to al(character to check out)
	cmp	al,20h			; compare al to a space
	jbe	nxtc			; if below or equal to a space jump to nxtc
	cmp	cx,00h			; compare 0 and cx
	jz	nf			; if equal then jump to nf
	clc				; clear the carry to indicate found
	ret				; done! leave routine
nf:					;*** this label MUST follow the ret ***
	stc				; set carry if not found
jmp	nf-1				; indicate not found & return
nxtc:
	inc	bx			; increment bx to point to the next value
	dec	cx			; adjust the cx register
	jmp	findnb			; next character	
findnb	endp	

reverse	proc	near

	push	ax			; save ax
	push	bx			; save bx
	push	cx			; save cx
	push	dx			; save dx

	mov	bx,0070h		; set video attribute to reverse video
	mov	dh,[row]		; set y value
	mov	dl,[col]		; set x value
	call	gotoxy			; call screen positioning routine
	add	bp,2			; add two to bp to bypass string header
					; information.

   writ_loop:
	mov	al,[bp]			; load al with the first character of string
	cmp	al,0ffh			; is character 0ffh? 
	je	wloop1			; yes, we are done: leave loop!
	mov	ah,9			; set function to write character with attribute
	mov	cx,1			; set counter to 1
	int	10h			; call BIOS
	mov	ah,2			; set ah to position cursor routine
	inc	dx			; inc x coordinate value	
	int	10h			; call bios
	inc	bp			; increment string pointer to point to next character
	jmp	writ_loop		; loop back to top
   wloop1:

	pop	dx			; restore dx
	pop	cx			; restore cx
	pop	bx			; restore bx
	pop	ax			; restore ax

	ret				; bye!

reverse	endp

;*****************************************************************************
;                                                                            *
;         Display current cylinder number for either reading or writing      *
;                                                                            *
;*****************************************************************************

display_cyl  proc   near

	push	ax			; save ax
	push	bx			; save bx	
	push	cx			; save cx
	push	dx			; save dx
	push	si			; save si
	push 	es			; save es

	lea	si,dc_cyl_cnt
	mov	byte ptr [col],x_for_cyl_cnt ; set the x_coordinate
	cmp	read_flag,true		; are we reading?	
	je	show_read		; yes, go here!
	mov	byte ptr [row],y_for_des_msg ; set the y coordinate for the destination
					; message
	jmp	show_cnt		; jump to show_cnt
   show_read:
	mov	byte ptr [row],y_for_src_msg ; set the y coordinate for the source message
   show_cnt:
	call	gotoxy			; positioning the cursor	
	mov	bx,si			; bx equal to the offset of the message
	call	adj_cyl			; calculate the new value 
	mov	dx,bx			; move the offset of the message to dx
	call	print			; print out the message

	pop	es			; restore es
	pop	si			; restore si
	pop	dx			; restore dx
	pop	cx			; restore cx
	pop	bx			; restore bx
	pop	ax			; restore ax

	ret				; goodbye!

display_cyl  endp			

;*****************************************************************************
;                                                                            *
;         Display cylinder header messages                                   *
;                                                                            *
;*****************************************************************************


show_cyl_header  proc  near

	push	dx			; save dx

	mov	byte ptr [row],y_for_src_msg ; load row with the y coordinate of 
					     ; the source message
	mov	byte ptr [col],x_for_cyl_msgs; load col with the x coordinate of the message

	call	gotoxy			; position the cursor
	lea	dx,dc_cyl_src_cnt	; load dx with the offset of message 
	call	print			; print the message
	mov	byte ptr [row],y_for_des_msg ; load col with the y coordinate of
					     ; the destination message
	call	gotoxy			; position the cursor
	lea	dx,dc_cyl_des_cnt	; load dx with the offset of destination message
	call	print			; print the message

	pop	dx			; restore dx

	ret				; bye for now!

show_cyl_header  endp

;*****************************************************************************
;                                                                            *
;    Adjust the cylinder display to reflect the current cylinder number      *
;                                                                            *
;*****************************************************************************

ten	dw	10

adj_cyl	proc	near

	push	ax			; save ax
	push	bx			; save bx
	push	cx			; save cx

	mov	ax,'  '
	mov	[bx],ax
	mov	[bx+2],ax

	mov	ax,[temp]		; get number to xlate
	mov	cx,4			; loop counter
	add	bx,cx

adj_loop:
	xor	dx,dx
	div	ten			; get least significant digit
	or	dl,'0'
	dec	bx
	mov	[bx],dl
	test	ax,ax
	loopnz	adj_loop
	
	pop	cx			; restore cx
	pop	bx			; restore bx
	pop	ax			; restore ax	
	ret				; bye!
adj_cyl	endp

;*****************************************************************************
;                                                                            *
;    Beep at user                                                            *
;                                                                            *
;*****************************************************************************

beep	proc	near
	push	ax			; save ax
	push	bx			; save bx
	push	cx			; save cx

	mov	ax,0e07h		; set function to be TTY write of a ^G
	mov	bx,0			; print to active page
	mov	cx,1			; print one character
	int	10h			; call BIOS
	
	pop	cx			; restore cx
	pop	bx			; restore bx
	pop	ax			; restore ax
	ret				; goodbye!

beep	endp

;*****************************************************************************
;                                                                            *
;    Get the extended error code and display an appropriate error the Exit.  *
;                                                                            *
;*****************************************************************************

extend_err:

	call	cls
	call	get_banner
	lea	dx,dc_error_header
	call	print
	lea	dx,dc_not_ready
	call	print
	call	init_device

;*****************************************************************************
;                                                                            *
;    Exit program and return a value in errorlevel                           *
;                                                                            *
;*****************************************************************************

exit_error:
	lea	dx,dc_syntax		; store the offset of the syntax message
					; in dx
	call	print			; print syntax message
	mov	ax,4c01h		; set terminate with return value code
					; and set return code to 1
	int	21h			; call MOS

;*****************************************************************************
;                                                                            *
;    Exit program and set errorlevel to zero                                 *
;                                                                            *
;*****************************************************************************

Exit:
	call	cls
	mov	ax,4c00h		; set terminate with return value code
	int	21h			; call MOS	

	


lastbyte label near			; label to show where the bottom of the
					; program is


diskcpy	endp
moss	ends
	end	diskcpy

