	include PAGE.INC
	title	MOSDDINT.ASM - device driver initialization

	subttl	MOSDDINT Development Specification

extrn	bugerror:near	;enable debug stack error reporting
;-----------------------------------------------------------------------;
;		      Development Specification 			;
;									;
; Program Name: $$MOS.COM		 Assigned to: Jim Bean		;
; Module Name:	MOSDDINT		 Assign date: 01/30/86		;
; Entry Points: MOSDDINT		 Completed:   02/12/86		;
; Entry From:	MOSxxxxx						;
; Entry Method: CALL							;
; Calls:	MOSHEMAN						;
; Purpose:	Device Driver Initialization				;
; Last Update:	12/15/89						;
;									;
; This routine provides for initializing a device driver.  If it is	;
; a block device, a BDB is built for it.  If it has a "standard"	;
; name (CON, PRT, etc.), appropriate steps are taken to assure that	;
; it is treated as standard input, output, or whatever. 		;
;									;
; Registers passed are: 						;
;      ES - Address of driver						;
;									;
; Registers returned are:						;
;      AL - Return code; 0 if all is OK 				;
;-----------------------------------------------------------------------;

	subttl	dicussion of MOSDDINT as implemented
	page
;-----------------------------------------------------------------------;
; jrb 02/12/86 10:10 MOSDDINT						;
;									;
; This routine provides for initializing a device driver.  If it is	;
; a block device, a BDB is built for it.  If the standard character	;
; device bits are set, the standard character device pointers are set	;
; to the new driver							;
;									;
; bit 0 = stdin standard input device					;
; bit 1 = stdout standard output device 				;
; bit 2 = NUL device (we allow it to be re-defined, unlike PCDOS)	;
; bit 3 = clock device							;
; device name PRN = standard printer device (not defined in PCDOS)	;
; device name AUX = standard auxilliary device (not defined in PCDOS)	;
;									;
; It is called with ES:BX = address of start of device driver		;
; DS:DX points to the remainder of the arguments from the specification ;
;   of the device driver						;
; it returns AL = 0 if no error 					;
; else AL = error code							;
;									;
; error codes are:							;
; 0	 no error							;
; 1 - 7  MOSHEMAN error codes from driver allocation adjustment 	;
;	  ( driver requested more space than was available)		;
; 8	 block device driver specified an invalid sector size		;
; 9 - 15 MOSLIMAN error codes + 8 from bdb allocation request		;
;	   (block device block allocation failed)			;
;									;
; also changed MOSBDB.INC to reflect the fact that we don't allow a     ;
; block device to set a sector size larger than our maximum and 	;
; added some shift counts to rapidly convert between sectors and blocks ;
; and between allocation units (clusters) and blocks			;
;									;
; added to SYS block							;
; SYSDRIVES:byte the number of drives allocated so far			;
; SYSBUFSZ:word  the maximum size of a sector				;
; SYSSTDIN:dword pointers to standard device drivers			;
; SYSSTDOUT, SYSSTDNUL, SYSSTDCLK, SYSSTDPRN, SYSSTDAUX 		;
;-----------------------------------------------------------------------;
; jrb 02/12/86 17:45 MOSDDINT						;
;									;
; have to set the first byte of the name field to the number of units	;
; after calling a block device driver for INIT				;
;-----------------------------------------------------------------------;
; jrb 02/13/86 08:15 MOSDDINT						;
;									;
; make use of SCBHPADR and SCBHPSIZ to determine if device driver is	;
; a built-in device driver, to more accurately detect whether or not	;
; we need to call MOSHEMAN to adjust the allocation			;
;-----------------------------------------------------------------------;
; jrb 02/17/86 15:05 MOSDDINT						;
;									;
; changed SCB??? to SCBSTD??? as it refers to standard devices as well	;
; as SCBDRIVES to SCBDRIVS (because they ended up in SCB that way)	;
;									;
; changed the allocation of a BDB to use MOSLIMAN instead of MOSHEMAN	;
;-----------------------------------------------------------------------;
; jrb 02/24/86								;
;									;
; support segmentation for romable code 				;
;-----------------------------------------------------------------------;
; jrb 03/03/86								;
;									;
; changed bdbclus and bdbcnum because mosfun39 does the 2 cluster	;
; calculation and doesn't need (or want) it precomputed                 ;
;									;
; bdbunit wasn't being set correctly                                    ;
;-----------------------------------------------------------------------;
; jrb 03/04/86								;
;									;
; corrections from mosinit testing					;
; don't assume ds:grp coming into mosddint                              ;
; device driver in heap points one paragraph past block header for	;
;   purposes of mosehman shrinking, so have to decrement it for 	;
;   mosheman								;
;-----------------------------------------------------------------------;
; jrb 04/09/86								;
;									;
; setbdb was setting bdbssiz incorrectly, and was not setting bdbsshl	;
;-----------------------------------------------------------------------;
; jrb 04/22/86								;
;									;
; added lundef to lproc mosddint variables				;
;-----------------------------------------------------------------------;
; jrb 04/24/86								;
;									;
; changed segment class from 'code' to 'data' for gdata, poll, irq	;
;-----------------------------------------------------------------------;
; jrb 07/28/86								;
; allocate a cdb as well as a bdb when init'ing a block device          ;
; de-allocate bdb on error after it's allocated                         ;
; pass mosbdint -> request block from init instead of -> device driver	;
;									;
; jrb 08/04/86								;
; pass mosbdint -> driver and -> request block				;
;-----------------------------------------------------------------------;
; jrb 08/25/86								;
; set ds to scbseg after storing parameter pointer			;
;-----------------------------------------------------------------------;
; jrb 09/02/86								;
; change setbdb not to set unnecessary bdb parameters - just sets bdb	;
; from bpb								;
;-----------------------------------------------------------------------;
; dam 09/08/86								;
; on exit DX -> segment of next available memory passed back from driver;
;-----------------------------------------------------------------------;
; jrb 09/22/86								;
; add various dpb fields to setbdb					;
;-----------------------------------------------------------------------;
; dam 12/09/86								;
; handle block devices that return 0 size and/or 0 units active		;
;-----------------------------------------------------------------------;
; jsm 03/24/87								;
; Large volume support in setbdb					;
;-----------------------------------------------------------------------;
; rbr 07/05/87								;
; If sector size of standard block device is too big, don't abort...    ;
; just invalidate the drive.     					;
;-----------------------------------------------------------------------;
; SAH	01/20/88	Change SCBSEG and ZERO seg access to MGetXXX	;
;			macros.						;
; SAH   01/22/88	Removed external reference to SCBSEG		;
;-----------------------------------------------------------------------;
; sah\rdr 02/21/88 Move DDT Segment to MO2 Group			;
;-----------------------------------------------------------------------;
; jrb   05/02/88  added init needed for cache to setbdb			;
; jrbr									;
;-----------------------------------------------------------------------;
; jrb   05/13/88  wrong sense of jump invalidating sectors/track if	;
; jrbt		  too many cylinders					;
;-----------------------------------------------------------------------;
; SAH	07/28/88  Corrected problem with UpperMemory by adding a test to;
;		  see if requested value is greater f000h (just in case ;
;		  we change the FFF8 address)				;
;-----------------------------------------------------------------------;
; mjs  9/1/88	Cleaned up extraneous crlf's, spaces, etc.		;
;-----------------------------------------------------------------------;
; sjc	9/16/88	Disallow cacheing on LANLink block devices		;
;-----------------------------------------------------------------------;
; mjs 10/21/88	Combine the actions of linkdrv into mosddint and make	;
;		modifications to support task specific device drivers.	;
;-----------------------------------------------------------------------;
; mjs 10/22/88	Corrections to the calculation of the next free segment	;
;		value which mosddint returns in dx.  For who knows how	;
;		long, when a driver is loaded, we've been wasting SMP	;
;		on it due to this one.					;
;-----------------------------------------------------------------------;
; mjs 04/16/89	Corrected adj_smp_alloc to de-allocate the block when	;
;		the driver returns a status error.  Modify to pass a	;
;		driver status error back to the caller.  Modify to	;
;		restore the root pointer when an error occurs.		;
;-----------------------------------------------------------------------;
; SAH 08/28/89  Corrections to adj_smp_alloc not to delete actual block ;
;		but just leave the header there, it was causing device  ;
;		drivers to lock up  when if user did bad syntax and 	;
;		driver indicated that it did not want to install by     ;
;		return cs:0 in requested header.			;
;-----------------------------------------------------------------------;
; mjs 08/31/89	Complete correction to problem with device drivers 	;
;		which return cs:0 to abort their loading.  Restored	;
;		adj_smp_alloc to its previous state.  Modified the logic;
;		within the mosddint main procedure to unlink a driver	;
;		when a cs:0 return is made.  For the 4.00 masters,	;
;		the ndev4xx.pat series now replaces the dev4xx.pat	; 
;		series.  Convert the mosddint procedure to action chart	;
;		and add 'include xifmacs'.				;
;-----------------------------------------------------------------------;
; mjs 10/10/89	Modified sector size calculations.
; mjs@
;-----------------------------------------------------------------------;
; SAH 12/15/89  Corrections for Split-SMP				;
;-----------------------------------------------------------------------;

	include GROUP.INC

	subttl	group segments and include block definitions
	page

	.xlist
	include	xifmacs.inc
	include MOSREGS.INC

tcb	segment at 1234h
	include MOSTCB.INC	; TCB definition
tcb	ends

	include MOSCDB.INC	; etc., etc., etc.
	include MOSBDB.INC	; this is the only one we need in this module

gdata	segment word public 'data'
	include MOSSCBEX.INC	; specify all SCB items as external
gdata	ends

	.list

irq	segment byte public 'data'
irq	ends

poll	segment byte public 'data'
poll	ends

ddt     segment word public 'code2'
ddt     ends

	subttl	mos segment - MOS module code and local data
	page

mosseg	segment word public 'code1'
	assume	cs:mos,ds:nothing,es:nothing,ss:tcb
	extrn	mosend:byte, sbios:word

	; extrn's rite cheer
	extrn	mosheman:near, mosliman:near

	; public's rite cheer
	public	mosddint, setbdb

	include macros.inc
	include dskstruc.inc
; define the structure of a bios-parameter-blockbytesct dw	?		; bytes per sector
sctclus db	?		; sectors per cluster
rsrvd	dw	?		; number of reserved sectors (FAT #1 sector)
numfat	db	?		; number of fat's
numdir	dw	?		; number of directory entries
sctunit dw	?		; sectors per unit
media	db	?		; media descriptor
sctfat	db	?		; sectors per fat
scthigh	db	?		; high byte of sector count
bpbspt  dw      ?               ;jrbr sectors per track
bpbhds  dw      ?               ;jrbr heads
bpbhddn dd      ?               ;jrbr number of hidden sectors
r of hiddeprnname db	'PRN     '	; name of standard printer device
auxname db	'AUX     '	; name of standard auxilliary device
ramname	db	'$RAMDISK'	;jrbr

	subttl	mosddint - device driver initialization code
	page
;-----------------------------------------------------------------------;
; MOSDDINT provides for initializing a device driver.  If it is 	;
; a block device, a BDB is built for it.  If the standard character	;
; device bits are set, the standard character device pointers are set	;
; to the new driver							;
;									;
; entry parms:	es:bx -> device driver					;
;		ds:dx -> parameter string (e.g. from config.sys line)	;
;		al = 0 if driver is to be linked into scbdrvr list	;
;		al = 1 if to be linked into tcbddpf list (adddev option);
;		al = 2 if not to be linked (special mosinit usage)	;
;									;
; exit parms:	dx = next free segment					;
;		for entry al = 0, al = result code:			;
; 0	 no error							;
; 1 - 7  MOSHEMAN error codes from driver allocation adjustment 	;
;	  ( driver requested more space than was available)		;
; 8	 block device driver specified an invalid sector size		;
; 9 - 15 MOSHEMAN error codes + 8 from bdb allocation request		;
;	   (not enough memory to allocate block device blocks)		;
; FF     error status from device driver				;
;									;
; NOTES:								;
; Attribute word bit values:						;
; bit 0 = stdin standard input device					;
; bit 1 = stdout standard output device 				;
; bit 2 = NUL device (we allow it to be re-defined, unlike PCDOS)	;
; bit 3 = clock device							;
; device name PRN = standard printer device (not defined in PCDOS)	;
; device name AUX = standard auxilliary device (not defined in PCDOS)	;
;-----------------------------------------------------------------------;
===================
	assume	ds:nothing,es:nothing,ss:lstring ddrequest,23		; device request block
ldword	nxtdrvr			; next driver in multi header file
ldword	parmptr			; original ds:dx
lbyte	linktype		; original al
ldword	origesbx		; original es:bx
ldword	origroot		; original root pointer - for restoration on error
ext in list pointer
	push	bx
	push	cx
	push	si
	push	di
	push	ds
	push	es
	mov	word ptr [parmptr],dx
	mov	word ptr [parmptr+2],ds
	mov	[linktype],al
	mov	word ptr [origesbx],bx
	mov	word 	mgetscb	ds
+2],es
	mgetscb ds
	assume	ds:grp
	mov	ax,word ptr [scbdrvr]
	mov	wor	mov	ax,word ptr [scbdrvr+2]	; record the original root pointer so 
nal root pointer so
	mov	word ptr [origroot+2],ax; a restoration c	xif [linktype] == 1 else msdd6
pe],1 
	jne	msdd6 
	mov	ax,word ptr [tcbddpf]	; overwrite for task specific case
	mov	word ptr [origroot],ax
	mov	ax,word ptr [tcbddpf+2]
	mov	word ptr [origroot+2],ax

; when there is more than one header in a file, only the offsets are linked.
; the following line is redundant for the first pass through this loop but
; required for the extra passes which will occur in the multi header case.

msdd6:
	mov	es,wo	xif [linktype] != 2 else msdd3	; linktype 2, special case from mosinit
	mov	ax,es:[bx]		; when linktype == 0 or 1, save the 
== 0 or 1, save the
	mov	word ptr [nxtdrvr],ax	; driver's next pointer in case of
	mov	ax,es:[bx+2]		; multiple headers per file
	mov	word ptr [	xif [linktype] != 1 else msdd4
	mov	ax,word ptr [scbdrvr]	; linktype assumed to be 0, link 
_scbnul
	je	msdd6a
	mov	es:[bx],ax		; into global list
	mov	ax,word ptr [scbdrvr+2]
	mov	es:[bx+2],ax
	mov	word ptr [scbdrvr],bx
	mov	word	jmp	msdd3
s
	jmp	short msdd3
msdd4:
	mov	ax,word ptr [tcbddpf]	; must be adddev, doing a task specifc
	mov	es:[bx],ax		; device driver load (linktype = 1)
	mov	ax,word ptr [tcbddpf+2]
	mov	es:[bx+2],ax
	mov	wo	mov	word ptr [tcbddpf+2],es		
 ptr [tcbddpf+2],es
msdd3:
	sti
	lea	di,[ddrequest]		; ss:di -> device request block
	mov	ax,word ptr [parmptr]
	mov	word ptr ss:[di+18],ax	; set p	mov	ax,word ptr [parmptr+2]	; in request block 
 ; in request block
	mov	word ptr ss:[di+20],ax
	push	di
	call; skip linking details if special mosinit case exit loop if error 
; from mosbdint else, set es:bx to the original next driver pointer 
next driver pointer
; of the current driver and go back through th	xif [linktype] == 2 then msdd5
	xif al == 0 else msdd1
	al,0 
	jne	msdd1 	xif bx != 0ffffh then msdd6
e	msdd1	xif [linktype] == 0 else msdd5	; if linktype = 0 adjust smp allocation 
cation
	jne	msdd5 
	mov	cl,al			; save original error status
	les	bx,[origesbx]		; need original es:bx for smp adjustment
	push	cx
	call	adj_smp_alloc
	pop	cx
	or	al,cl			; form cumulative e	xif [linktype] == 2 then msdd7	; if skip linking, skip recovery test
ry test
	je	msdd7 

; if the driver returns cs:0000 or there is	lea	di,[ddrequest]		; ss:di -> device request block 
	call	calc_size
	xoif dx == <word ptr [origesbx+2]> || al != 0 else msdd7
	je	msdd7 
msdd5a:
	mov	cx,word ptr [origroot]
	mov	dx,wo	xif [linktype] != 1 else msdd8
ype],1 
	je	msdd8 
	mov	word ptr [scbdrvr],cx	; unlink for the global case
	mov	word	jmp	msdd7
s
	jmp	short msdd7
msdd8:
	mov	word ptr [tcbddpf],cx	; unlink for the task specific case
	mov	word ptr [tc	lea	di,[ddrequest]		; ss:di -> device request block 
evice request block
	call	calc_size
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
lundef	ddrequest,23
lundef	nxtdrvr
lundef	parmptr
lundef	linktype
lundef	origest
lundef	origroot;- CALC_SIZE -----------------------------------------------------------;
; calulate a drivers return point					;
;									;
; entry parms:	none							;
; exit parms:	dx = number of paras for driver				;
;-----------------------------------------------------------------------;
calc_size:
calc_size proc near
	mov	dx,ss:[di+14]		; get end res offset
	add	dx,15			; calc seg
	mov	cl,4
	shr	dx,cl
	add	dx,ss:[di+16]		; et
calc_size endp 

	subttl ddinit0 - initial;-----------------------------------------------------------------------;
; ddinit0 - initialize a driver						;
;									;
; entry parms:	es:bx -> device driver					;
;		ss:di -> request block					;
;		ds -> grp						;
;									;
; exit parms:	al = result code  0 if ok 				;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb
ddinit0:

ddinit0 proc near
	mov	al,[scbdrivs]		; get current drive #
	mov	ss:[di+22],al		; and set	mov	byte ptr ss:[di+2],0	; INIT command
	mov	byte ptr ss:[di],22	; length of request block 
th of request block
	mov	byte ptr ss:[di+1],0	; unit number
	mov	word ptr ss:[di+3],0	; status
	push	di
	push	ds
	push	[tcbstkp]	sub	[tcbstkp],96+4	; 96 + following es & bx
	push	es
	push	bx
	push	cs		; emulate far call
	; emulate far call
	call	ddstrat
	pop	bx
	pop	es	push	cs		; emulate far call again
late far call again
	call	ddinter
	pop	bx
	pop	es
	pop	[tcbstkp]
	pop	ds
	p	test	word ptr ss:[di+3],0200h	; error
	jnz	ddi0b
op	di
	mov	al,0ffh
	test	word ptr es:[bx+4],8000h
	jnz	ddi0a	call	mosbdint	; block device (allocate and set bpb's)
	pop	es
	pop	bx
	mov	es:[bx+10],dl	; number of drives actually installed
	add	[scbdrivs],dl	; increasing total number of drives in system
of drives in system	call	moscdint	; character device (look for standard devices)
	xor	al,al		; no errors possible in moscdint
ossible in mos	ret
ddinit0 endp 

	subttl adj_smp_alloc - adjust smp allocatio;-----------------------------------------------------------------------;
; adj_smp_alloc - adjust smp allocation for driver			;
;									;
; entry parms:	es:bx -> device driver					;
;		ss:di -> request block					;
;		ds -> grp						;
;									;
; exit parms:	al = mosheman result code (0 no error)			;
;-----------------------------------------------------------------------;
	assume	ds:grp,es:nothing,ss:tcb
adj_smp_alloc:
	xor	al,al		; prepare error code of 0
are error co	cmp	dx,0f000h	; check if in upper memory
	jae	ddint1		
memory
	jae	ddint1
	mov	cl,4
	shr	bx,cl
	add	dx,bx
	cmp	[scbhp2siz],0
	je	doheap1
	mov	bx,[scbhp2adr]
	or	cmp	dx,bx		; must be >= scbhp2adr or we won't allocate
r we won't allocate
	jb	doheap1
	add	bx,[scb	jb	doheap2		; must be < scbhp2adr + scbhp2siz
bhp2adr + scbhp2siz
doheap1:	cmp	dx,bx		; must be >= scbhpadr or we won't allocate
r we won't allocate
	jb	ddint1
	add	bx,[sc	jae	ddint1		; must be < scbhpadr + scbhpsiz
				; shrink or expand driver's memory allocation
memory allocation

doheap2:
	mov	dx,word ptr ss:[di+14]	; as re	mov	cl,4		; new size is requested end address (rounded
	shr	dx,cl		; up to nearest segment) less start address
 less start address
	add	dx,word ptr ss:[di+16]
	mov	ax,es
	dec	ax
	mo	mov	ah,02h		; setup for modify allocation
	cmp	dx,1		; shrinking down to just the header?
to just the h	mov	ah,1		; if yes, de-allocate the block
-allocate the block
ddint2:
	call	mosh
;-----------------------------------------------------------------------;
; call device driver strategy routine					;
; returns to ddstrat caller						;
; es:bx -> device driver header 					;
; ss:di -> device request block 					;
;-----------------------------------------------------------------------;
:nothing,ss:nothing
ddstrat:
	push	es	push	es:[bx+6]	; device driver strategy far address on stack
	push	ss		; es:bx -> request header
	pop	es
	mov	bx,di
	retf

;-----------------------------------------------------------------------;
; call device driver interrupt routine					;
; returns to ddinter caller						;
; es:bx -> device driver header 					;
; ss:di -> device request block 					;
;-----------------------------------------------------------------------;
:nothing,ss:nothing
ddinter:
	push	es	push	es:[bx+8]	; device driver interrupt far address on stack
	push	ss		; es:bx -> request header
	pop	es
	mov	bx,di
	retf

	subttl	moscdint - look for standard devices
	page
;-----------------------------------------------------------------------;
; determine if device driver represents a standard character device	;
; ex:bx -> device driver header 					;
;									;
; standard input if attribute field bit 0 set				;
; standard output if attribute field bit 1 set				;
; standard nul if attribute field bit 2 set				;
; standard clock if attribute field bit 3 set				;
; standard printer if device name is 'PRN     ' 			;
; standard aux if device name is 'AUX     '				;
;-----------------------------------------------------------------------;
:nothing,ss:nothing
moscdint:
	test	word ptr es:[bx+4],0001h
	jz	moscd1
	mov	word ptr [scbstdin],bx	; standard input device
	mov	word ptr [scbstdin+2],es
moscd1:
	test	word ptr es:[bx+4],0002h
	jz	moscd2
	mov	word ptr [scbstdout],bx ; standard output device
	mov	word ptr [scbstdout+2],es
moscd2:
	test	word ptr es:[bx+4],0004h
	jz	moscd3
	mov	word ptr [scbstdnul],bx ; standard nul device
	mov	word ptr [scbstdnul+2],es
moscd3:
	test	word ptr es:[bx+4],0008h
	jz	moscd4
	mov	word ptr [scbstdclk],bx ; standard clock device
	mov	word ptr [scbstdclk+2],es
moscd4:
	lea	di,[bx+10]
	lea	si,p	repe cmpsw
cx,8/2
	repe	cmpsw
	jne	moscd5
	mov	word ptr [scbstdprn],bx ; standard printer device
	mov	word ptr [scbstdprn+2],es
	ret
moscd5:
	lea	di,[bx+10]
	lea	si,a	repe cmpsw
cx,8/2
	repe	cmpsw
	jne	moscd6
	mov	word ptr [scbstdaux],bx ; standard auxilliary device
	mov	word ptr [scbstdaux+2],	subttl	mosbdint - initialize block device
	page
;-----------------------------------------------------------------------;
; based upon the returned bios parameter blocks (bpb's), allocate       ;
; a block device block for each unit claimed by the block device driver ;
;									;
; ss:di -> request block from call to INIT block device 		;
; es:bx -> device driver						;
;									;
; return al = 0 if no error						;
; else al = 8 if sector size is invalid 				;
; else al = MOSLIMAN error + 8 if can't allocate some bdb               ;
;-----------------------------------------------------------------------;
:nothing,ss:nothing
mo	xor	dl,dl		; this will be the unit number within device
	mov	cl,ss:[di+13]	; number of units defined by this device
ined by this	lds	si,ss:[di+18]	; BPB array pointer returned by driver
 returned by driver
	mov	di,es
	assume	ds:nothing
	or	jmp	mosbd3		; no units (maybe the driver changed its mind)
r changed	push	ds		;Rod
	MGetSCB ds		;Rod
	assume	ds:grp		;Rod
	mov	ax,[scbbufsz]	;Rod  max allowable sector size
	pop	ds		;Rod
	assume	ds:nothing	;Rod
	push	si		;Rod
	mov	si,[si]		;Rod  address next bpb
	cmp	ax,[si+bytesct]	;Rod
	pop	si		;Rod
	jae	mosbd1r		;Rod
	xor	ax,ax		;Rod  if invalid size, just ignore the drive
	jmp	mosbd3		;Rod
mosbd1r:			;Rod
	mov	ah,00h		; allocate the bdb
	mov	al,'B'
	call	mosliman	; call mosliman
	add	al,8		; mosliman error offset for our purposes
	cmp	al,8
	je	mosbd1a		; if enough space to allocate this bdb
o allocate this bdb
	jmp	mosbd3
	assume	es:bdb
mosbd1a:
	mov	word ptr [bdbdrvr],bx	; offset of block device driver
	mov	word ptr [bdbdrvr+2],di ; segment of 	mov	[bdbunit],dl	; sub-unit within block device
within block device
		MGetSCB ds
ush	ds
	mgetscb ds
	assume	ds:grp	mov	[bdbid],al	; absolute drive number of this unit
	mov	ax,[scbbufsz]	; remember max allowable sector size
	pop	ds
	assume	ds:nothing
	push	es		; remember where bdb is
	push	si
	mov	si,[si] 	; -> next bpb
	push	dx
	xor	dx,dx		; say "initialize device"
	call	setbdb		; construct bdb
b			; construct bdb
	pop	dx	jnz	mosbd2		; sector size invalid
	mov	ah,00h		; allocate a cdb for the bdb
e a cdb for t	call	mosliman	; call mosliman
	add	al,8		; mosliman error offset for our purposes
	cmp	al,8
	jne	mosbd2		; not enough space for cdb
nough space for cdb
	assu	MGetSCB ds
ush	ds
	mgetscb ds
	assume	ds:grp
	mov	al,[scbdrivs]
	pop	ds
	assume	ds:	mov	[cdbdrive],al	; drive number
	mov	[cdbclus],0	; at root directory
; at root directory
	mov	[	inc	dl		; next unit for block device driver
block device driver
	add	si,2
	dec	cx
	jz	mosbd1b
	jmp	mosbd1
mosbd1b:
	xor	al,al
		pop	es		; address of bdb
	push	ax		; save error code
	mov	al,1
	mov	al,'B'
	call	mosliman	; call MOSLIMAN
an		; call moslima	MGetSCB ds
	assume	ds:grp
	ret			; return dl = number of units installed

	subttl	setbdb - construct a block device block from a bpb
	page
;-----------------------------------------------------------------------;
; using bpb at ds:si, construct bdb at es:0				;
; di:bx = device driver address 					;
; ax = max sector size allowable					;
; if dx = 0, set bdbroot and bdbalias to 0 too				;
;									;
; returns al = 0 if no error						;
; else al = 8, invalid sector size					;
;									;
; Large volume support added 3/24/87					;
; Alias support added 4/3/87						;
;-----------------------------------------------------------------------;
:nothing,ss:nothing
setbdb:
	assume	ds:nothing,es:bdb
	push	dx
	push	cx
	cmp	ax,[si+	jnb	setbd0		; max sector size < device sector size
 device sector size
		or	dx,dx		; initialize call?
	jnz	setbd0a		; if not initialization time
	mov	[bdbroot],dx	; zero out root directory cluster
	mov	[bdbalias],dx	; alias pointer
	mov	[bdbanxt],dx	; it has no aliases
	mov	[bdbreal],es	; this is a real drive, is its own real bdb
is its own real bdb
setbd0a:
		mov	[bdbssiz],ax	; # of bytes in 1 sector

;mjs@	mov	cx,16
;mjs@setbd1:
;mjs@	shl	ax,1
;mjs@	loopnz	setbd1
;mjs@	mov	[bdbsshl],cl

f bytes in 1 sector	mov	[bdbfat],ax	; first sector of first fat
	mov	al,[si+sctfat]	; # sectors per fat
; # sectors per fat	mov	al,[si+numfat]	; # of fat's
mfat]		; # of fat's
	mov	[bdbfnum],al
	xor	ah,ah
	mul	[si+sctfat]	mov	[bdbdir],ax	; first sector of root directory
r of root directory
	mov	[bdbrnum],ax	; number of root directory entries allowed
ory entries 	mul	cx		; dx:ax = size of directory in bytes
 directory in bytes
	mov	cx,[si+bytesct]
	dec	cx
	add	ax,cx	div	cx		; ax = size of directory in sectors
irectory in sector	mov	[bdbclus],ax	; ax = first sector of cluster #2
ector of cluster #2
		mov	[bdbcsiz],al	; cl = size of cluster in sectors (power of 2)
ectors (p	mov	[bdbcmsk],al	; size - 1 (mask for size) for dpb field
size) for dpb field
	inc	al
	mov	cx,8
setbd2:
	shl	a	mov	[bdbcshl],cl	; shift count to convert clusters to sectors
	mov	ax,[si+sctunit] ; total size of block device unit in sectors
	xor	dx,dx
	mov	dl,[si+scthigh]	; high byte of sector count
	mov	word ptr [bdbsctr],ax	;jrbr
	mov	byte ptr [bdbsctr+2],dl	;jrbr
	mov	[bdbbig],'N'	; assume volume 65535 sectors or less
535 sectors or less
	o	mov	[bdbbig],'Y'	; if volume bigger than 65535 sectors
 than 65535 sectors
setbd3:
	sub	ax,[	xor	ch,ch		; convert shift count to word
shift count to word
	jcxz	setbd6
setbd5:
	shr	dx,1
	rcr	ax,1
	loop	setbd5	mov	[bdbcnum],ax	; number of clusters mapped to unit (valid data
				;   clusters range from 2 to bdbcnum)
	dec	ax
	mov	[bdbcnmx],ax	; number of clusters + 1 for dpb field
s + 1 for dpb field	mov	[bdbmdia],al	; media descriptor byte
	mov	[bdbcfree],-1	; # free clusters not valid yet
	mov	[bdbclustl],1	; pretend last allocated was cluster 1
				;   so first looked at is cluster 2
        call    setbdbc         ;jrbr set bdb parameters for cacheing
	xor	al,al		; no error
	al,al			; no error
setbd7:
	pop	cx
	pop	dx
	ret

; set cache parameters         push    ds
        push    bx

	push	ds
	push	bx
	mov	word ptr [bdbclpf],-1	; no        mov     ax,[si+bpbspt]
        mov     cx,ax
        mul     [si+bpbhds]
        push    ds
        lds     bx,[bdbdrvr]
        assume  ds:nothing
        test    byte ptr [bx+4],40h
        pop     ds
        jz      setbc0a         ;jrbs
pop	ds
	jz	setbc0a

; note the following to determine whether to use spt and spc logic in
; cacheing drive does not invalidate the drive, just the         or      dx,dx
        jnz     setbc0a         ;jrbs
        cmp     ax,2048                 ; 64 sectors per track * 32 heads
        ja      setbc0a         ;jrbs
        mov     [bdbspc],ax             ; sectors / cylinder
        or      ax,ax           ;jrbs
        jz      setbc0a         ;jrbs
        mov     [bdbspt],cx             ; sectors / track
        cmp     cx,8            ;jrbs
        jb      setbc0a         ;jrbs
        mov     ax,word ptr [si+bpbhddn]
        mov     word ptr [bdbhddn],ax
        mov     dx,word ptr [si+bpbhddn+2]      ;jrbs
        mov     word ptr [bdbhddn+2],dx         ;jrbs
        add     ax,word ptr [bdbsctr]
        adc     dl,[bdbsctr+2]
        adc     dh,0
        mov     cx,ax
        mov     ax,dx
        xor     dx,dx
        div     [bdbspc]
        xchg    cx,ax
        div     [bdbspc]
        or      cx,cx
        jnz     setbc0a
        cmp     ax,1024
	jbe	setbdbc0		;jrbt no more than 1023 cylinders
than 1023 cylinders
setbc0a:

; disable         mov     [bdbspc],0
        mov     [bdbspt],0
        mov     word ptr [bdbhddn],0
        mov     word ptr [bdbhddn+2],0
d ptr [bdbh	MGetSCB ds
	assume	ds:grp
        mov     cl,[bdbid]              ; drive number
        mov     bl,cl
        xor     bh,bh
        shr     bx,1
        shr     bx,1
        shr     bx,1                    ; bx = offset into drive enable bit map
        and     cl,7                    ; cl = bit position in byte
        mov     al,1
        shl     al,cl                   ; al = bit set in bit position
        mov     [bdbcach],'Y'           ; preset cache on
		; preset cache on
	mov	cx,word ptr [scbcd]
	or	cx,word ptr [scbcd+2]
	jz	setbdbc1		; cache on for al        test    scbcd[bx],al
        jnz     setbdbc1		; cache on if bit set
cache on if bit set
	mov	[bdbcach],0		; else cache off
setbdbc1:

; set cache off for bdb if device driver name is our ramdisk

	push	es
	push	ds
	push	di
	push	si
	lds	si,[bdbdrvr]	add	si,11		; note 11, not 10 cause our ram disk driver
	push	cs		;   has the name in a weird place
me in a weird place
	pop	es
	assume	es:nothing
	lea	di,[ra	repe cmpsw
cx,8/2
	repe	cmpsw
	pop	si
	pop	di
	pop	ds
	assume	ds:grp
	pop	es
	assume	es:bdb
	jne	setbdbc2
	mov	[bdbc; set cache off for bdb if device driver is LANSAT (LANLink) - sjc 9/16/88
link) - sjc 9/16/88

	push	ds
	push	si
	lds	si,[bdbdrvr]		; get driver seg:off
	assume	ds:nothing
	cmp	word ptr [si+12h],'AS'	; is this driver lansat?
	pop	si
	pop	ds
	assume	ds:grp
	jne	setbdbc3
	mov	[bdbcach],0		; if so, donsetbdbc3:				; end sjc 9/16/88
is drive
setbdbc3:

; compute how many of this bdb's sectors will fit in a cache uob

	mov	ax,[bdbssiz]
	mov	cl,4
	shr	ax,cl			; sector size in para's
	mov	cx,ax
	mov	ax,[scbcuob]
	xor	dx,dx
	div	cx        pop     bx
        pop     ds
        ret
p	bx
	pop	ds
	ret
