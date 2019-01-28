	include page.inc
        title   moxems - virtual expanded memory specification driver
;
;******************************************************************************
;*                                                                            *
;*                        mos development specification                       *
;*                                                                            *
;* command type: device driver          assigned to:      Stewart Hyde        *
;* command name: moxems.sys             date assigned:    feb 02, 1987        *
;*                                      date completed:                       *
;* command format: device=moxems.sys [size]                                   *
;* purpose: provide ems support for pc-mos/386                                *
;* refer to:                                                                  *
;* last update:                         by:                                   *
;******************************************************************************
;

;------------------------------------------------------------------------
;  	SAH	08/08/87	minor changes plus changes so non-memory
;				management case will not crash context
;				switching
;------------------------------------------------------------------------
;	SAH	04/10/89	corrections for copyright
;------------------------------------------------------------------------
;	BWR	11/30/89	marked messages for foreign language
;				translations.
;------------------------------------------------------------------------
;	SAH	08/07/90	cleanup of source
;	SAH     08/07/90	LIM 4.00 Support Started
;	SAH	10/26/90	Lim 4.00 Support Completed
;	SAH     10/26/90	Started Task Specific EMS 4.0 data areas
;	SAH     11/02/90	Completed Task Specific EMS 4.0 with
;				MOS 4.10 Dynamic Patching
;	SAH     12/19/90	Up version to 4.00 for Release
;------------------------------------------------------------------------
;	SAH     08/12/90        Added /G=option for global EMS allocations
;				for compucon.
;-----------------------------------------------------------------------
;       SAH     04/10/92	Corrections for function 4b and dx
;				Also if address is A000h, allow ems to
;				be place there if not ega or vga and
;				the memdev fill options is not used.
;------------------------------------------------------------------------
;       SAH     04/16/92	Gramma correction that Bob S. found     
;------------------------------------------------------------------------
;       SAH     08/14/92        Made sure Interupts are clear during
;				context save and restore routines
;				Fix problem with loosing data
;------------------------------------------------------------------------

         page
	 if	0 eq 0
         comment  |

                  author:  stewart a. hyde
                  updated: 08/07/90

                  modified for PC-MOS operating system

                  this program emulates the hardware and provides the lim/ems
                  interupt 67h for ems support on computers that do not have
                  ems boards on them.  this version supports version 3.2 and
                  4.0 the lim/ems only.  Direct i/o (in and out) to page
		  registers not	available with this device.


                  function       ah       description
                      1          40       get status                  06/06/86
                      2          41       get page frame address      06/06/86
                      3          42       get unallocated page count  06/05/86
                      4          43       allocate pages              06/06/86
                      5          44       map handle pages            06/09/86
                      6          45       deallocate pages            06/06/86
                      7          46       get emm version             06/04/86
                      8          47       save page map               06/09/86
                      9          48       restore page map            06/09/86
                      10         49       reserved                    06/09/86
                      11         4a       reserved                    06/09/86
                      12         4b       get emm handle count        06/04/86
                      13         4c       get emm handle pages        06/05/86
                      14         4d       get all emm handle pages    06/05/86
                      15         4e       get/set page map            06/09/86


		  ems 4.0 functions added august 7, 1990

		       16	  4f	  get\set partial page map     08/08/90
		       17	  50      map\unmap multi-handle       08/17/90	
		       18	  51	  reallocate pages	       08/20/90	
		       19         52      get\set attribute	       02/01/89
		       20	  53      get\set handle name	       02/01/89
		       21	  54      get\set handle directory     02/02/89
		       22	  55      alter page map and jump      08/20/90
		       23	  56      alter page map and call      08/20/90	
		       24	  57	  move\exchange address region 08/31/90
		       25         58      map physical address array   02/01/89
		       26	  59      get memory information       08/08/90
		       27	  5a	  allocate raw pages	       08/08/90
		       28	  5b	  alternate map register set   08/08/90
		       29         5c	  warm reboot		       02/01/89
/		       30	  5d	  enable\disable os/e funs     02/01/89

                  |
         endif

         page

	 if    0 eq 0		; fake out public.com
true           	equ   1
false          	equ   0
	include mosems.inc

TCBID	  equ	010h
TCBSTATION equ  076eh
TCBUNREG  equ	07a6h
TCBEMSSEG equ	07f2h
SCBTCBPF  equ   0h
SCBTCBPC  equ	13h
SCBSAVE   equ	1adh
SCBRESTORE equ  1B1h
SCBMOSADR  equ  11bh
SCBVTYPE   equ	2beh

FARCALL	   equ  9ah
SAVEPATCH  equ  8242h
SAVEJMP	   equ  10ebh
RESTPATCH  equ  83ceh
RESTJMP	   equ  14ebh
CHKPATCH   equ  8255h
CHKVALUE   equ  67cdh

	endif

	include _ems.pub

	.286

mainseg  segment para
         assume cs:mainseg,ds:nothing,es:nothing
begin    label near

         page
;------------------------- device header ----------------------------

devheadr label byte
         dd    -1                    ; pointer to next driver
         dw	8000h                 ; attribute: indicate character device
         dw	strategy              ; ptr to strategy routine
         dw	interupt              ; ptr to interrupt routine
devname  db	'EMMXXXX0'            ; device name

         even
address  db    0e0h                  ; segment address
baseaddr dw    0                     ; start of extended memory allocation
mroutine dw    2 dup (?)             ; memory management address
zero     dw    0
cur_hand db    0                     ; current handle using database
phy_page db    0                     ; physical page storage
ems_page dw    0                     ; ems page storage
subfunction db	0
function db	0
taddress dd	0
overlap	db	'N'
savemap	dw	0,0
CurPage1 dw	0
CurPage2 dw	0
TranSize dw	0
Map2	 db	'N'
Raw_Hand dw     -1		     ; -1 means don't set raw handle	
ZeroCheck db	'Y'		     ; ZeroCheck for Allocate
SaveDS	 dw	0
ScbPtr	 dd	0		     ; pointer to SCB

map_area db	map_size	     ; number of 16k mapable pages

map_segments dw	MAX_MAP_SIZE dup (0)	     ; map segment areas

windmap  dw    MAX_MAP_SIZE  dup (max_page)     ; map of pages in window

OldSave	dd	0		      ; Old Context Save Routine (ZERO)
OldRestore dd	0		      ; Old Context Restore Routine (ZERO)	

EMSGlobal db	'N'			; EMS is not global

funtab   label word
         dw	init
         dw	mediachk
         dw	buildbpb
         dw	ioctlin
         dw	input
         dw	ndinput
         dw	instatus
         dw	inflush
         dw	output
         dw	outputv
         dw	oustatus
         dw	ouflush
         dw	ioctlout

rhoff    dw    0                     ; request header pointer
rhseg    dw    0
         page
strategy label near
         mov	cs:[rhseg],es
         mov	cs:[rhoff],bx
farret1  proc  far
         ret
farret1  endp

interupt label near
         push	es
         push	ds
	 push	bp
         push	di
         push	si
         push	dx
         push	cx
         push	bx
         push	ax

	 cld
         push	cs                    ; init ds register
         pop	ds
         les	bx,dword ptr [rhoff]  ; load rh pointer
         mov	al,es:[bx+2]          ; get command code byte
         mov	ah,0
         shl	ax,1
         mov	di,ax
         jmp	[di+funtab]

donestat label near
         les	bx,dword ptr [rhoff]
         or	word ptr es:[bx+03],0100h   ; "DONE" status

         clc
         pop	ax
         pop	bx
         pop	cx
         pop	dx
         pop	si
         pop	di
	 pop	bp
         pop	ds
         pop	es
farret2  proc  far
         ret
farret2  endp
         page
input    label near
output   label near
outputv  label near
ioctlin  label near
ioctlout label near
         mov	word ptr es:[bx+18],0     ; no data transferred
ndinput  label near
inflush  label near
ouflush  label near
mediachk label near
buildbpb label near
         or	word ptr es:[bx+03],8102h ; indicate device not ready
         jmp	short donestat


instatus label near
oustatus label near
         and	word ptr es:[bx+03],0000h ; indicate device ready
         jmp	short donestat
         page
;--------------------------------------------------------------------
;                         int 67h handler
;--------------------------------------------------------------------



entint67 label near
	 sti
	 cld
	 push	bp				; [bp+4]
         push	ds				; [bp+2]
         push	bx				; [bp]
	 mov	bp,sp				
	 mov	cs:[function],ah		; save for InitEMS
	 call	GetEMSSeg			; retrieved EMS segment
	 assume   ds:ems40seg
	 jnc	contint67
	 cmp	ah,41h				; get frame address
	 je	contint67
	 cmp	ah,46h				; is this get version
	 je	contint67			; if so...continue 
	 cmp	ah,4eh				; if get/set map
	 je	contint67
	 mov	ah,no_hard			; indicate no hardware
	 jmp	short skip67
contint67:
         cmp	ah,40h
         jb	invalid67
         sub	ah,40h
         cmp	ah,1eh
         jbe	ok67
invalid67:
	 mov	ah,invalid_parm
	 jmp	short skip67 
ok67:
         xor	bh,bh
         mov	bl,ah
         shl	bx,1
         call	cs:[funtable+bx]
	 mov	bx,ds 				; skip setting syserror
	 or	bx,bx				; if segment does not exist
	 je	skip67
	 mov	[syserror],ah
skip67:
	 pop	bx
	 pop	ds
	 pop	bp
	 iret
	 
         even
funtable label word
         dw	status                ; 1  - get status
         dw	pageaddr              ; 2  - get page frame address
         dw	pcount                ; 3  - get unallocated page count
         dw	alpages               ; 4  - allocate pages
         dw	maphand               ; 5  - map handle pages
         dw	free                  ; 6  - deallocate pages
         dw	version               ; 7  - get emm version
         dw	savepmap              ; 8  - save page map
         dw	restpmap              ; 9  - restore page map
         dw	rsv10                 ; 10 - reserved
         dw	rsv11                 ; 11 - reserved
         dw	hcount                ; 12 - get emm handle count
         dw	hpages                ; 13 - get emm handle pages
         dw	ahpages               ; 14 - get all emm handle pages
         dw	getset                ; 15 - get/set page map
;
;	The following are EMS 4.0 functions
;
	 dw	gspartial		; 16 - get\set partial page map
	 dw	multimap		; 17 - map\unmap mult handle
	 dw	realloc			; 18 - reallocate pages
	 dw	gsattribute		; 19 - get\set attribute
	 dw	gsname			; 20 - get\set handle name
	 dw	gsdir			; 21 - get\set handle directory
	 dw	mapjump			; 22 - alter page map and jump
	 dw	mapcall			; 23 - alter page map and call
	 dw	moveexch		; 24 - move\exchange memory
	 dw   	getphymap		; 25 - map physical address array
	 dw	getinfo			; 26 - get expanded memory information
	 dw	rawalloc		; 27 - allocate raw pages
	 dw	altermap		; 28 - alternate map register set
	 dw	warmboot		; 29 - warm boot
	 dw	osefun			; 30 - enable\disable OS/E functions



         page
;---------------------------------------------------------------------------
; function: 1 - get status
;---------------------------------------------------------------------------

status   proc	near
         mov	ah, [syserror]        ; get latest error code
	 ret
status	 endp


;---------------------------------------------------------------------------
; function: 2 - get page address
;---------------------------------------------------------------------------

pageaddr proc	near
         mov	bh, cs:[address]      ; get stored segment address
         xor	bl, bl                ; zero out lower byte
	 mov	TBX,bx
         xor	ah, ah                ; indicate ok....
	 ret
pageaddr endp

;---------------------------------------------------------------------------
; function: 3 - get unallocated pages count
;---------------------------------------------------------------------------

pcount   proc	near
         xor	ah, ah                ; indicate ok....
         mov	bx, [pgsleft]         ; get # of unallocated pages
	 mov	TBX,bx		      ; return to user registers	
         mov	dx, [pgsavail]        ; get max # of pages
         cmp	bx, dx                ; compare them....
         jbe	pdone                 ; should always happen...
         mov	ah, soft_error        ; indicate error in software

pdone:
         mov	[syserror], ah        ; save system error code
	 ret
pcount	endp

;---------------------------------------------------------------------------
; function: 4 - allocated pages
;---------------------------------------------------------------------------

alpages  proc	near
	 mov	[ZeroCheck],'Y'	      ; check for zero check	
allocate:	      		      ; entry point for Function 27
         mov	ah, not_enough        ; indicate not enought pages in memory
	 mov	bx,TBX		      ; get user bx register	
         cmp	bx, [pgsleft]         ; cmp to # of unallocated pages
         jbe	alp1                  ; continue
         jmp	alpdone1              ; not enough pages

alp1:
         mov	ah, all_used          ; indicate all handles used up...
	 mov	dx,[handles]
         call	IsMaxHandle	      ; compare handles count  to max
         jb	alp2                  ; continue
         jmp	alpdone1              ; all emm handles use

alp2:
	 cmp    [ZeroCheck],'Y'	      ; is this function 27	
	 jne	alp3		      ; yes skip check	
         mov	ah, not_zero          ; can'T ALLOCATED ZERO PAGES
         or	bx, bx                ; zero pages????
         jne	alp3                  ; continue
         jmp	alpdone1              ; yes...abort....

alp3:
         push	bp
         push	si                    ; save si
         push	cx                    ; save cx

; 	update counters

       	sub	[pgsleft], bx         ; update page counter

; 	find unused handle and update it

         mov	si, hand_len          ; start out at handle 1
         mov	dx, 1                 ; start out at handle 1
         mov	ah, soft_error        ; should never happen
alphand:
         cmp	byte ptr database[si].alloc, false ; look for unused handle
         je	alpfin                ; fin doing handles
         inc	dx                    ; increment dx
         add	si, hand_len          ; add lenght of handle record
         call	IsMaxHandle	      ; over the hill bud!!!
         jbe	alphand               ; no...repeat
         pop	cx
         jmp	alpdone               ; get out of here
alpfin:
         mov	bp, dx                ; save handle
         mov	cx, bx                ; place bx in cx
         inc	[handles]             ; up counter
         mov	byte ptr database[si].alloc, true  ; unused handle found
         mov	word ptr database[si].pages, cx    ; save pages
	 call	ClearName	      ; clear name field       
	 or	cx,cx		      ; zero pages
	 jz	alzero				
         mov	bx, si                ; save handle pointer
         xor	si, si                ; zero out source pointer
         mov	dx, max_page          ; indicates top of list
         call	getpage               ; get page
         cmp	dx, max_page          ; this indicates system error
         jb	alp4                  ; continue
         mov	ah, soft_error        ; idicate software error
         pop	cx                    ; get cx
         jmp	alpdone               ; abort......
alzero:
	 mov	word ptr database[bx].link, max_page
	 jmp	short skipout		

alp4:
         mov	word ptr database[bx].link, dx     ; place link into database
         mov	bx, si                ; save pointer
         dec	cx                    ; decrement cx
         or	cx, cx                ; done
         jz	skiploop              ; only one page wanted
         add	si, bmap_len          ; point to next item
alploop:
;
;	allocate and store pages in link list here - bx points to start
;   	si points to the next avaiable page
;
         call	getpage               ; get page
         cmp	dx, max_page          ; this indicates system error
         jb	alp5                  ; continue
         mov	ah, soft_error        ; idicate software error
         pop	cx                    ; get cx
         jmp	short alpdone         ; abort......

alp5:
	 add	bx,[bitoffset]
         mov	word ptr [bx].linkptr, dx  ; setup link...
	 sub	bx,[bitoffset]
         mov	bx, si                ; save pointer
         add	si, bmap_len          ; point to next item
         loop	alploop               ; loop until done
skiploop:
	 add	bx,[bitoffset]
         mov	word ptr [bx].linkptr, -1  ; setup link...
skipout:
         pop	cx                    ; get cx
         mov	dx, bp                ; get handle
         xor	ah, ah                ; indicate ok

alpdone:
         pop	si
         pop	bp

alpdone1:
	 ret
alpages  endp

;---------------------------------------------------------------------------
; function: 5 - map handle pages
;---------------------------------------------------------------------------

maphand  proc	near
         push	si                    ; save si
         push	dx
	 push	ax
	 mov	bx,TBX		      ; get user BX		
	 xor	dh, dh		      ; better-basic fix 4-9-87
         mov	[phy_page], al        ; save physical page
         mov	[ems_page], bx        ; save ems page
         mov	ah, soft_error        ; indicate error in software
         call	IsMaxHandle	      ; compare to max # of handles
         ja	mhdone                ; bad handle #
         mov	ah, phys_range        ; indicate physical range error
         cmp	al, 3                 ; out of range
         ja	mhdone                ; yes....abort...
         mov	ah, bad_handle        ; indicated bad handle
	 call	GetEntry	      ; calculate offset into structure	
         cmp	byte ptr database[si].alloc, true   ; allocated block???
         jne	mhdone                ; no...error
         mov	ah, logic_range       ; indicate error in software
         mov	bx, [ems_page]        ; get ems page (bx)
	 cmp	bx, max_page	      ; un map page
	 jae	unmapit			
         cmp	bx, word ptr database[si].pages  ; compare to log range
         jae	mhdone                ; out of range
         mov	dx, word ptr database[si].link   ; get link
         mov	ah, soft_error        ; indicate error in software
         mov	bx, [ems_page]        ; get ems page (bx)
         inc	bx
         push	dx

maploop:
         or	bx, bx                ; done????
         je	mapdone               ; yes..ok
         dec	bx                    ; decrement counter
         pop	si                    ; get old copy (remove from stack)
         mov	si, dx                ; get page #
         shl	si, 2                 ; only if bmap_len = 4
         push	dx
	 push	si
	 add	si,[bitoffset]
         mov	dx, word ptr [si].linkptr   ; get next page link
	 pop	si
	 cmp	dx, -1 		      ; if last entry than get out	
	 je	maploop
         cmp	dx, [pgsavail]        ; in physical range????
         jae	mhdone1               ; no...abort
         jmp	short maploop         ; yes...continue...

unmapit:
	 mov	al,[phy_page]
	 call	unmapmem	       ; un map memory	
	 xor	ah,ah		       ; no errors  
	 jmp	short mhdone

mapdone:
         pop	dx
         push	dx
         mov	al, [phy_page]          ; get physical page (al)
         call	getmem                  ; get it!!!!
         xor	ah, ah                  ; no errors!!!!

mhdone1:
         pop	dx

mhdone:
	 mov	bx,ax
	 pop	ax
	 pop	dx
	 pop	si
	 mov	ah,bh			; make sure ah has error code
	 ret
maphand  endp

;---------------------------------------------------------------------------
; function: 6  -  deallocate pages
;---------------------------------------------------------------------------

free     proc	near
	 push	dx
         push	si                    ; save si
	 
	 xor	dh, dh		      ; better basic fix 4-9-87
         mov	ah, soft_error        ; indicate error in software
         call	IsMaxHandle	      ; compare to max # of handles
         ja	jfdone                ; bad handle #
	 call	GetEntry	      ; calcuate offset into structure
         mov	ah, bad_handle        ; indicated bad handle
         cmp	byte ptr database[si].alloc, true   ; allocated block???
         jne	jfdone                 ; no...error

         mov	ah, soft_error        ; indicate error in software
         mov	bx, [pgsleft]         ; get max pages
         add	bx, word ptr database[si].pages      ; add pages in handle
         cmp	bx, [pgsavail]        ; compare to max pages available
	 jna	fdealloc
jfdone:
         jmp	fdone                 ; error in software {not me}
fdealloc:

         ; at this point we can deallocate the space

         mov	[pgsleft], bx         ; set new pages left
         dec	[handles]
	 mov	ah,false
	 or	si,si
	 jnz	freenot1
	 mov	ah,true
freenot1:
         mov	bx, word ptr database[si].link       ; get start of link list
	 cmp	word ptr database[si].pages,0	
	 jne	freeclr		  
;
;	 removing a zero page entry 
;
         mov	byte ptr database[si].alloc, ah   ; remove handle
         mov	word ptr database[si].link, max_page    ; zero out link list
	 call	ClearName			     ; clear name field	
	 xor	ah,ah
	 jmp	short fdone		 	

freeclr:
         mov	byte ptr database[si].alloc, ah   ; remove handle
         mov	word ptr database[si].pages, 0       ; set pages to zero
	 call	ClearName			     ; clear name field	
         mov	bx, word ptr database[si].link       ; get start of link list
         mov	word ptr database[si].link, max_page    ; zero out link list

floop:
         mov	ah, soft_error        ; indicate error in software
	 mov	ax,bx
	 call	CheckMapArea	      ; check Map Area if In area, UnMap it		
         mov	si, bx                ; place bx in si
         shl	si, 2                 ; multiply by for - (only if bmap_len=4)
	 add	si,[bitoffset]
         cmp	byte ptr [si].inuse, false   ; test to see if allocated
         je	fdone
         mov	byte ptr [si].inuse, false   ; deallocate page
         cmp	dl, byte ptr [si].assign     ; same handle
         jne	fdone
         mov	bx, word ptr [si].linkptr    ; get link pointer
         mov	word ptr [si].linkptr, max_page  ; reset link ptr
         cmp	bx,-1                 ; end of list???
         jne	floop                 ; repeat until done

         xor	ah, ah                ; indicate all ok and dandy...

fdone:
         pop	si
	 pop	dx
	 ret
free	endp

;---------------------------------------------------------------------------
; function: 7  -  get ems version
;---------------------------------------------------------------------------

version  proc near
         xor	ah,ah                 ; indicated ok...
         mov	al,ems_version        ; indicate version 4.0
	 ret
version  endp

;---------------------------------------------------------------------------
; function: 8  -  save page map
;---------------------------------------------------------------------------

savepmap proc   near
         push	cx
         push	dx
         push	si
         push	di

	 xor	dh, dh		      ; better basic fix 4-9-87
         mov	ah, bad_handle        ; indicate bad handle
         call	IsMaxHandle           ; bad handle???
         ja	spdone                ; abort....
	 call	GetEntry	      ; calcuate offset into structure
         mov	ah, bad_handle        ; indicated bad handle
         cmp	byte ptr database[si].alloc, true   ; allocated block???
         jne	spdone                 ; no...error
	 mov	ah,savemap_saved
	 cmp	word ptr database[si].hsavemap,-1
	 jne	spdone
	 mov	cx,4 			; only first 4 maps are store
	 lea	di,database[si].hsavemap
	 mov	si,offset windmap
	 push	es
	 push	ds
	 push	ds
	 pop	es
	 push	cs
	 pop	ds
	 rep	movsw
	 pop	ds
	 pop	es
	 xor	ah,ah
spdone:
         pop	di
         pop	si
         pop	dx
         pop	cx
	 ret
savepmap endp

;---------------------------------------------------------------------------
; function: 9  -  restore page map
;---------------------------------------------------------------------------

restpmap proc   near
         push	cx
         push	dx
         push	si
         push	di

	 xor	dh, dh		      ; better basic fix 4-9-87 (sah)
         mov	ah, bad_handle        ; indicate bad handle
         call	IsMaxHandle	      ; bad handle???
         ja	rpdone                ; abort....
	 call	GetEntry	      ; calcuate offset into structure
         mov	ah, bad_handle        ; indicated bad handle
         cmp	byte ptr database[si].alloc, true   ; allocated block???
         jne	rpdone                 ; no...error
	 mov	ah,no_savemap
	 cmp	word ptr database[si].hsavemap,-1
	 je	rpdone
	 push	es
	 push	cs
	 pop	es

	 push	si
	 mov	di,offset windmap
	 lea	si,database[si].hsavemap
	 mov	cx,4				; only first 4 are store 
	 rep	movsw
	 pop	si

	 push	ds
	 pop	es
	 mov	cx,4				; only first 4 are stored
	 lea	di,database[si].hsavemap
	 push	ax
	 mov	ax,-1
	 rep	stosw
	 pop	ax
	 pop	es
	 mov	ah,[map_area]			; get map_area
	 mov	[map_area],4			; force map area to 4
	 call	setport				; do the mapping
	 mov	[map_area],ah			; retore map area

	 xor	ah,ah
rpdone:
         pop	di
         pop	si
         pop	dx
         pop	cx
         ret
restpmap endp
;---------------------------------------------------------------------------
; function: 10 - reserved # 10
;---------------------------------------------------------------------------

rsv10    proc   near
         xor	ax, ax                ; indicate 0 boards and ok
	 ret
rsv10    endp

;---------------------------------------------------------------------------
; function: 11 - reserved # 11
;---------------------------------------------------------------------------

rsv11    proc near
         push	cx
	 push	dx
         push	si                    ; save si
         push	di

	 xor	dh, dh		      ; better basic fix 4-9-87 (sah)
         mov	ah, bad_handle        ; indicated bad handle
         call	IsMaxHandle           ; compare to max # of handles
         ja	r11done               ; bad handle #
	 call	GetEntry	      ; calcuate offset into structure	
         cmp	byte ptr database[si].alloc, true   ; allocated block???
         jne	r11done               ; no...error

         ; at this point we scan and collect pages for lim/ems translation

         mov	ah, soft_error
         mov	bx, word ptr database[si].link       ; get start of link list
         cmp	bx, max_page
         jae	r11done                              ; error...

r11loop:
         mov	si, bx                ; place bx in si
         shl	si, 2                 ; multiply by for - (only if bmap_len=4)
	 add	si,[bitoffset]
         cmp	byte ptr [si].inuse, false   ; test to see if allocated
         je	r11done
         cmp	dl, byte ptr [si].assign     ; same handle
         jne	r11done
         mov	bx, word ptr [si].linkptr    ; get link pointer
         cmp	bx, max_page          ; end of list???
         jae	r11ok
         mov	cx, bx

         ; we now to the actual translation

         shl	cx, 1                 ; shift high bit of cl int ch
         shr	cl, 1
         or	cl, 80h               ; set enable bit
         mov	word ptr es:[di], cx  ; save byte in table
         inc	di
         inc	di
         jmp	short r11loop         ; repeat until done

r11ok:
         xor	ah, ah                ; indicate all ok and dandy...

r11done:
         pop	di
         pop	si
	 pop	dx
         pop	cx
	 ret
rsv11    endp

;---------------------------------------------------------------------------
; function: 12 - get emm handle count
;---------------------------------------------------------------------------

hcount   proc near
         mov	ah, soft_error        ; indicate error in software
         mov	bx, [handles]         ; get handle count
	 mov	TBX,bx
	 push	dx
	 mov	dx,bx		      ; must have handles in dx	
         call	IsMaxHandle	      ; compare to max # of handles
	 pop	dx
         ja	hdone                 ; should not happen...
         xor	ah, ah                ; indicate ok....
hdone:
	 ret
hcount   endp

;---------------------------------------------------------------------------
; function: 13 - get emm handle pages
;---------------------------------------------------------------------------

hpages   proc near
         push	dx                    ; save dx
         push	si                    ; save si
	 xor	dh, dh		      ; better basic fix 4-9-87 (sah)
         mov	ah, soft_error        ; indicate error in software
         call	IsMaxHandle           ; compare to max # of handles
         ja	hpdone                ; bad handle #
	 call	GetEntry	      ; calculate offset into structure
         mov	bl, byte ptr database[si].alloc   ; get allocated block
         mov	ah, bad_handle        ; indicated bad handle
         cmp	bl, true              ; allocated???
         jne	hpdone                ; no...error
         mov	ah, soft_error        ; indicate error in software
         mov	bx, word ptr database[si].pages   ; get number of allocated pages
	 mov	TBX,bx
         cmp	bx, [pgsavail]        ; can'T BE MORE THAN AVAILABLE
         ja	hpdone                ; if so report error....
         xor	ah, ah                ; indicate ok....
hpdone:
         pop	si
         pop	dx
	 ret
hpages   endp

;---------------------------------------------------------------------------
; function: 14 - get all emm handle pages
;---------------------------------------------------------------------------

ahpages  proc near
         push	cx
         push	si                    ; save si
         push	di                    ; save di
         xor	si, si                ; clear si
         xor	cx, cx                ; clear counter

ahloop:
         mov	bl, byte ptr database[si].alloc   ; get allocated block
         cmp	bl, true              ; allocated????
         jne	ahskip                ; no..skip
         mov	word ptr es:[di], cx  ; send handle #
         mov	bx, word ptr database[si].pages   ; get number of allocated pages
         mov	word ptr es:[di+2], bx  ; send page count
	 add	di,4		      ; adjust di to next record	
         inc	cx                    ; increment counter
ahskip:
         add	si, hand_len          ; add lenght of hand record
	 push	si
	 lea	si, database[si]
         cmp	si, [bitoffset]	      ; compare to max (assumes hand then bit)
	 pop	si
         jb	ahloop                ; loop until done
         xor	ah, ah                ; indicate ok....
         mov	TBX, cx                ; get counter
         pop	di
         pop	si
         pop	cx
	 ret
ahpages	 endp

;---------------------------------------------------------------------------
; function: 15 - get / set page map
;---------------------------------------------------------------------------
getset   proc near
	 push	ds
	 mov	bx,ds
	 mov	cs:[SaveDS],bx
	 mov	bx,TDS
	 mov	ds,bx
         mov	ah, invalid_parm      ; invalid parameter???
         cmp	al, 3                 ; sub-function 0 -- 3????
         ja	gsdone                ; abort.....
         xor	ah, ah                ; indicate ok....
         or	al, al                ; subfunction 0....
         jne	gs1                   ; no...skip
         call	getarray              ; get page array
         jmp	short gsdone          ; exit ok

gs1:
         cmp	al, 1                 ; subfunction 1....
         jne	gs2                   ; no...skip
         call	savarray              ; save page array
         call	setport               ; setup gizmo allocation
         jmp	short gsdone          ; exit ok...

gs2:
         cmp	al, 2                 ; subfunction 2....
         jne	gs3                   ; no...skip
         call	getarray              ; get page array
         call	savarray              ; save page array
         call	setport               ; setup gizmo allocation
         jmp	short gsdone          ; exit ok...

gs3:
         mov	al, map_area           ; return map size
	 shl	al,1
gsdone:
	 pop	ds
	 ret
getset   endp

;---------------------------------------------------------------------
; Function 16 -	get\set partial map
;
; Storage area will be store has follows
;	byte 0	= # of entries in list
;	byte 1  = window page #			] duplicate for each
;	word 2  = ems page #			] entry
;---------------------------------------------------------------------
gspartial proc	near
	cmp	al,02h		; is this this function 02h
	jne	not1602
;
;	Handle function 02 - return partial map size
;
	mov	bx,TBX			; get user BX
	mov	ah,phys_range
	or	bh,bh	    		; if request > 255 then error
	jnz	done1602
	or	bl,bl			; if request is 0 then error
	jz	done1602
	cmp	bl,[map_area]		; if request > map area then error
	ja	done1602	
	mov	al,bl 			; size is request*3 + 1
	shl	al,1
	add	al,bl			
	inc	al			; add 1 for number of elements
	xor	ah,ah			; indicate ok
done1602:
	jmp	done16
not1602:
	mov	ah,invalid_parm 
	cmp	al,01h
	ja	done16
	jne	do1600
;
;	handle function 01 - set partial map
;
	push	cx
	push	dx
	push	si
	push	ds

	mov	dx,TDS
	mov	ds,dx 

	xor	ch,ch
	mov	cl,byte ptr ds:[si]
	inc	si
	xor	ah,ah
Loop1601:
	lodsb			; get window page
	mov	dx,word ptr ds:[si]
	inc	si
	inc	si
	call	getmem
	loop	Loop1601
	xor	ah,ah

	pop	ds		
	pop	si
	pop	dx
	pop	cx
	jmp	short done16

do1600:
;
;	handle function 00 - get partial map
;
	push	cx
	push	dx
	push	si
	push	di
	push	ds


	mov	cx,TDS
	mov	ds,cx
	
	mov	ah,corrupted
	mov	cx,word ptr ds:[si]		; get # of entries
	inc	si
	inc	si
	or	ch,ch 				; must be lest < 255
	jnz	done16
	mov	al,cl
	stosb					 ; store size into array
	mov	dx,si
;
;	Now we will loop through each entry, validate segment derive
;	physical map location and EMS logical page
;
loop1600:
	push	cx
	mov	bx,word ptr ds:[si]	; get segment 
;
;	first we will need to check to see if EMS segment is alreay
;	been declare in list
;
	push	si
	push	dx
	xchg	si,dx			; start at begining of list
Loop16ck:
	cmp	si,dx			; are we done with what we
	je	Loop16ok		; what we are store in
	mov	cx,word ptr ds:[si]	; get segment
	inc	si
	inc	si
	cmp	cx,bx			; is this segment equal to
	jne	Loop16ck		; new one, no continue
;
;	we have found a duplicate
;
	mov	ah,corrupted		
	stc	
	jmp	short Loop16out
Loop16ok:
	clc
Loop16out:
	pop	dx
	pop	si
	jc	Error1600
	inc	si
	inc	si
	call	SegToHand		; covert segment into map
	jc	Error1600		; out of range error?	
	stosb				; store physical page
	mov	ax,bx
	stosw	  			; store logical page
	pop	cx
	loop	loop1600
	xor	ah,ah			; all ok
	jmp	short done1600
Error1600:
	pop	cx
Done1600:	
	pop	ds
	pop	di
	pop	si
	pop	dx
	pop	cx
done16:
	ret
gspartial endp

;---------------------------------------------------------------------
; Function 17 -	map\unmap multible handle pages
;---------------------------------------------------------------------
multimap proc	near
	push	cx
	push	dx
	push	di
	push	es

	mov	bx,TDS
	mov	es,bx
	
	mov	[subfunction],al
	mov	ah,invalid_parm
	cmp	al,01h
	ja	jdone17
	xor	dh,dh
        mov	ah, soft_error        ; indicate error in software
	xor	dh,dh			
        call	IsMaxHandle	      ; compare to max # of handles
	jna	cont17a
jdone17:
        jmp	done17                ; bad handle #
cont17a:	
	jcxz	ok17		      ; if nothing to do then all ok	
	push	si
	call	getentry
	mov	di,si
	pop	si
        mov	ah, bad_handle        ; indicated bad handle
        cmp	byte ptr database[di].alloc, true   ; allocated block???
        jne	done17                ; no...error
	mov	di,database[di].link		; place link into DI

multiloop:
	push	cx
	mov	ax,word ptr es:[si]
	inc	si
	inc	si
	cmp	ax,-1
	je	mskip17
	call	LogToEMS			; convert handle page to ems
	cmp	ax,max_page
	jb	mskip17
	mov	ah,logic_range
	jmp	short skip17
mskip17:
	mov 	[ems_page],ax
	mov	ax,word ptr es:[si]
	inc	si
	inc	si
	push	si
	push	ds
	cmp	[subfunction],00h
	je	skip17
	call	SegToPage
skip17:			
        mov	ah, phys_range        ; indicate physical range error
	cmp	al,[map_area]
	jae	bad17
;
;	At this point AL has physical page numbe
;	[ems_page] has logical page number
;	
 	mov	dx,[ems_page]
	cmp	dx,max_page
	jb	map17
	call	UnMapMem
	jmp	short Cont17
Map17:
        mov	ah, soft_error        ; should never happen
	cmp	dx,max_page
	ja	bad17
      	call	getMem
Cont17:
	pop	ds
	pop	si
	pop	cx
	loop	multiloop 		; loop for each entry
ok17:
	xor	ah,ah			; all ok
	jmp	short done17
bad17:
	pop	ds
	pop	si
	pop	cx
done17:
	mov	al,cs:[subfunction]
	pop	es
	pop	di
	pop	dx
	pop	cx
	ret
multimap endp

assume  ds:ems40seg, es:nothing

;---------------------------------------------------------------------
; Function 18 -	reallocate pages
;---------------------------------------------------------------------
realloc proc	near
	push	si
	push	bp
	mov	bx,TBX
	mov	[ems_page],bx
        mov	ah, soft_error        ; indicate error in software
        call	IsMaxHandle	      ; compare to max # of handles
        ja	redone                ; bad handle #
	mov	bp,dx		      ; save handle	
        mov	ah, bad_handle        ; indicated bad handle
	call	GetEntry	      ; calculate offset into structure	
        cmp	byte ptr database[si].alloc, true   ; allocated block???
        jne	redone                ; no...error
	xor	ah,ah		      ; all ok...for same amount of pages	
	mov	bx,word ptr database[si].pages
	cmp	bx,[ems_page]
	je	redone
	jb	reincrease		; we are going to raise allocation
;
;	decrease memory allocations
;
	call	ReShrink
	jmp	short	ReContinue
reincrease:
;
;	increase memory allocation
;
	push	cx
	mov	cx,[ems_page]	
	sub	cx,bx
	cmp	cx,[pgsleft]
	pop	cx
	mov	ah,not_enough
	ja	redone
	call	ReRaise	
ReContinue:
	mov	bx,word ptr database[si].pages
redone:
	pop	bp
	pop	si
	ret
realloc endp

;---------------------------------------------------------------------
; Function 19 -	get\set handle attribute
;---------------------------------------------------------------------
; 
; Since this is a simulate software version of EMS, we don't support
; non-violatile memory management, we will simple return all requests
; that memory is violatile
;
;---------------------------------------------------------------------
gsattribute proc near
	xor	ah,ah
	cmp	al,02h
	je	gsattrout
	mov	ah,no_attribute
	jb	gsattrout
	mov	ah,invalid_parm
gsattrout:
	ret
gsattribute endp

;---------------------------------------------------------------------
; Function 20 -	get\set handle name
;---------------------------------------------------------------------
gsname  proc	near
	push	si
	push	di
	push	cx

	xor	dh,dh		
	mov	ah, soft_error
	call	IsMaxHandle			; compare to max # of handles
	ja	gsndone
	mov	ah, invalid_parm
	mov	bx,si				; save si temporary for function 01
	call	getentry			; calcuate offset into structure
	mov	cx,4				; both functions move 4 words
	or	al,al				; test for function 00
	jnz	gsn1
;	
;	subfunction 00 - returns handle name in ES:DI
;
	lea	si,database[si].hname
	push	di
	rep	movsw			; copy the data
	pop	di
	xor	ah,ah			; all ok
	jmp	short gsndone
gsn1:
	cmp	al,1			;test for function 01
	jne	gsndone			
;	
;	
;	subfunction 01 - sets handle name in DS:SI
;
	push	si
	push	es
	push	ds

	mov	di,ds
	mov	es,di
	mov	di,TDS
	mov	ds,di
	lea	di,database[si].hname
	mov	si,bx
	rep	movsw

	pop	ds
	pop	es
	pop	si
	xor	ah,ah

gsndone:
	pop	cx
	pop	di
	pop	si
	ret
gsname	endp

;---------------------------------------------------------------------
; Function 21 -	get\set handle directory
;---------------------------------------------------------------------
gsdir	proc	near
	push	cx
	push	si
	push	di
	push	bp    
	push	es	
	or	al,al			; function 00?
	jnz	notgsd0
;
;	function 00 - get handle directory
;
	push	dx

	xor	si,si
	xor	bx,bx			; clear start pointer
	xor	dx,dx			; clear handle
	xor	bp,bp			; clear counter
gsd0lp:
	cmp	byte ptr database[bx].alloc,TRUE
	jne 	gsd0nx
	inc	bp			; increment counter
	mov	ax,dx
	stosw
	mov	cx,4
	lea	si,database[bx].hname	; store handle name
	rep	movsw
gsd0nx:
	inc	dx
	add	bx,hand_len		; next structure
	push	bx
	lea	bx,database[bx]
	cmp	bx,[bitoffset]		; done
	pop	bx
	jb	gsd0lp
	mov	ax,bp			; return count in AL
	pop	dx
	jmp	short gsdok
notgsd0:		
	cmp	al,1
	jne	notgsd1			; function 01?
;
;	function 01 - search for name handle
;
	mov	cx, TDS
	mov	es, cx
;
;	first check if hanlde is all 00's
;	
	push	si
	mov	cx,4
gsd1nulp:
	cmp	word ptr es:[si],0
	jnz	gsd1nnul 
	inc	si
	inc	si
	loop	gsd1nulp
	pop	si			
	mov	ah,null_name
	jmp	short gsddone
gsd1nnul:
	pop	si
	xor	bx,bx
	xor	dx,dx
gsd1lp:
	cmp	 byte ptr database[bx].alloc,TRUE
	jne	gsd1nx
;
;	test name handle to see if they are equal
;	
	push	si
	push	ds
	push	es

	mov	cx,ds
	mov	di,es
	mov	ds,di		; swap ds and es
	mov	es,cx

	lea	di,database[bx].hname
	mov	cx,4
	repe 	cmpsw				; check string
	pop	es
	pop	ds
	pop	si
	je	gsdok	
gsd1nx:
	inc	dx
	add	bx,hand_len		; next structure
	push	bx
	lea	bx,database[bx]
	cmp	bx,[bitoffset]		; done
	pop	bx
	mov	ah,handle_notfound
	jb	gsd1lp
	jmp	short gsddone
notgsd1:
	mov	ah,invalid_parm
	cmp	al,2
	jne	gsddone
;
;	function 02 - get total handle
;
	mov	bx,[maxhandles]
	mov	TBX,bx
gsdok:
	xor	ah,ah
gsddone:
	pop	es
	pop	bp
	pop	di
	pop	si
	pop	cx
	ret
gsdir	endp

;---------------------------------------------------------------------
; Function 22 -	alter map and jump
;       AL = physical page number/segment selector
;	DX = handle
;	DS:SI -> map_and_jump structure
;		dd	target address
;		db	log_phys_map_len
;		dd	log_phys_map ptr
;      log_phys_map:
;		dw	log_page_number
;		dw	phys_page_number_seg
;---------------------------------------------------------------------
mapjump proc	near
	push	cx
	push	si
	push	di
	push	es

	mov	cx,TDS
	mov	es,cx
	mov	ah,invalid_parm
	cmp	al,1  		     ; function 00 or 01	
	ja	jmjdone 
	mov	[subfunction],al      ; save map type
        mov	ah, soft_error        ; indicate error in software
        call	IsMaxHandle           ; compare to max # of handles
	jna	mjcont
jmjdone:
        jmp	mjdone                ; bad handle #
mjcont:
        mov	ah, bad_handle        ; indicated bad handle
	mov	di,si
	call	GetEntry	      ; calculate offset into structure	
	mov	ax,word ptr es:[di]
	mov	word ptr [taddress],ax
	mov	ax,word ptr es:[di+2]
	mov	word ptr [taddress+2],ax
	mov	cl,byte ptr es:[di+4]	; get number map entries
	or	cl,cl		
	jz	dojump
       	xor	ch,ch
	mov	ax,word ptr es:[di+7]	; get structure's segment
	mov	di,word ptr es:[di+5]	; get structure's offset
	mov	es,ax
jumploop:
	push	cx
	push	di
	push	es

	mov	dx,word ptr es:[di]
	mov	ax,word ptr es:[di+2]
	cmp	[subfunction],00h
	je	skipjump
	call	SegToPage
skipjump:
        mov	ah, phys_range        ; indicate physical range error
	cmp	al,[map_area]
	jae	badjump

	call	LogToPhy
        mov	ah, soft_error        ; should never happen
	cmp	dx,[max_page]
	ja	badjump
      	call	getMem

	pop	es
	pop	di
	pop	cx
	add	di,4			; point to next structure
	loop	jumploop
	jmp	short dojump
badjump:
	pop	es
	pop	di
	pop	cx

dojump:
;
;	do the jump
;
	pop	es
	pop	di
	pop	si
	pop	cx
	pop	ax		; disregard ret address for this function
	pop	bx
	pop	ds
	pop	bp
	pop	ax		; disregard offset of INT 67 handle
	pop	ax		; disregard segment of INT 67 handle
	popf			; disregard flags of INT 67 handle
	jmp	dword ptr cs:[taddress]
	
mjdone:
	pop	es
	pop	di
	pop	si
	pop	cx
	ret
mapjump endp


;---------------------------------------------------------------------
; Function 23 -	alter map and call
;       AL = physical page number/segment selector
;	AL = 2 (Return Stack Size)
;	DX = handle
;	DS:SI -> map_and_jump structure
;		dd	target address
;		db	log_phys_map_len
;		dd	log_phys_map ptr
;      log_phys_map:
;		dw	log_page_number
;		dw	phys_page_number_seg
;---------------------------------------------------------------------
mapcall proc	near
	cmp	al,02h			; is this return stack size
	jne	mapcont
	xor	ah,ah
	mov	bx,64			; require atleast 64 bytes of stack
	mov	TBX,bx			; 35 is count but leave room 
	ret
mapcont:
	push	cx
	push	si
	push	di
	push	es

	mov	cx,TDS
	mov	es,cx
	mov	ah,invalid_parm
	cmp	al,1  		     ; function 00 or 01	
	ja	jmcdone 
	mov	[subfunction],al      ; save map type
        mov	ah, soft_error        ; indicate error in software
        call	IsMaxHandle           ; compare to max # of handles
	jna	mchandok
jmcdone:
        jmp	mcdone                ; bad handle #
mchandok:
	mov	di,si		      ; save si into di	
        mov	ah, bad_handle        ; indicated bad handle
	call	GetEntry	      ; calculate offset into structure	
	mov	ax,word ptr es:[di]
	mov	word ptr [taddress],ax
	mov	ax,word ptr es:[di+2]
	mov	word ptr [taddress+2],ax


	push	di
	push	es
	mov	cl,byte ptr es:[di+4]	; get number map entries
	or	cl,cl		
	jz	docall
       	xor	ch,ch
	mov	ax,word ptr es:[di+7]	; get structure's segment
	mov	di,word ptr es:[di+5]	; get structure's offset
	mov	es,ax
callloop:
	push	cx
	push	di
	push	es

	mov	dx,word ptr es:[di]
	mov	ax,word ptr es:[di+2]
	cmp	[subfunction],00h
	je	skipcall
	call	SegToPage
skipcall:
        mov	ah, phys_range        ; indicate physical range error
	cmp	al,[map_area]
	jae	badcall

	call	LogToPhy
        mov	ah, soft_error        ; should never happen
	cmp	dx,[max_page]
	ja	badcall
      	call	getMem

	pop	es
	pop	di
	pop	cx
	add	di,4			; point to next structure
	loop	callloop
	jmp	short docall
badcall:
	pop	es
	pop	di
	pop	cx
	pop	es
	pop	di
	jmp	mcdone
docall:
	pop	es
	pop	di
;
;	do the call
;
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	ds
	push	es

	call	dword ptr cs:[taddress]	; 4 bytes of stack

	pop	es    			;
	pop	ds			; \
	pop	bp			;  \
	pop	di			;   14 bytes of Stack 
	pop	si			;  /
	pop	dx			; /
	pop	cx			;
					
	mov	cl,byte ptr es:[di+9]	; get number map entries
	or	cl,cl		
	jz	nomap2
       	xor	ch,ch
	mov	ax,word ptr es:[di+12]	; get structure's segment
	mov	di,word ptr es:[di+10]	; get structure's offset
	mov	es,ax
callloop2:
	push	cx
	push	di
	push	es

	mov	dx,word ptr es:[di]
	mov	ax,word ptr es:[di+2]
	cmp	[subfunction],00h
	je	skipcall2
	call	SegToPage
skipcall2:
        mov	ah, phys_range        ; indicate physical range error
	cmp	al,[map_area]
	jae	badcall2

	call	LogToPhy
        mov	ah, soft_error        ; should never happen
	cmp	dx,[max_page]
	ja	badcall2
      	call	getMem

	pop	es
	pop	di
	pop	cx
	add	di,4			; point to next structure
	loop	callloop2
nomap2:
	xor	ah,ah
	jmp	short mcdone
badcall2:
	pop	es
	pop	di
	pop	cx
mcdone:
	pop	es			;
	pop	di			; \
	pop	si			;  \ 12 bytes of stack
	pop	cx			;  /
	ret
mapcall	endp

;---------------------------------------------------------------------
; Function 24 -	move\exchange memory region
;---------------------------------------------------------------------

moveexch proc	near
	push	es
	mov	ah,invalid_parm
	cmp	al,1  		     ; function 00 or 01	
	ja	movedone
	mov	[subfunction],al
	mov	bx,TDS
	mov	es,bx
	call	moveparms	      ; check parms for valid paramters	
	jc	movedone
	cmp	[subfunction],01h     ; is this exchange	
	jne	domove
	call	exchange	      ; do exchange sublogic
	jmp	short movedone
domove:
	call	move			; do move sublogic
movedone:	  
	pop	es  
	ret
moveexch endp

;-------------------------------------------------------------------
; Procedures use by function 24 move\echange memory
;-------------------------------------------------------------------


moveparms proc	near
	push	bx
	push	cx
	push	dx
	push	si
	push	di

	mov	[overlap],'N'
;
;	we will first check to see if dest\source parmaters are
;	valid
;
	mov	ah,unsource_dest	
	cmp	byte ptr es:[si+SOURCE_TYPE],01h 	; check source
	ja	jmoveerror
	cmp	byte ptr es:[si+DEST_TYPE],01h		; check destination
	ja	jmoveerror
;
;	we will see if region size is too big
;	if total size > 1 Meg then this is an error
;
	mov	ah,region_too_big
	cmp	word ptr es:[si+REGION+2],10h		; > 1meg
	ja	jmoveerror
;
;	check to see if source, if expanded memory, handle
;	is valid or not
;
	cmp	byte ptr es:[si+SOURCE_TYPE],01h
	jne	skipsource
	mov 	cx,word ptr es:[si+REGION]
	mov	ax,word ptr es:[si+REGION+2] 	; size of region in ax:cx
	mov	bx,word ptr es:[si+SOURCE_SEGPAGE]		; get initial page
	mov	di,word ptr es:[si+SOURCE_OFFSET]		; get initial offset
	mov	dx,word ptr es:[si+SOURCE_HANDLE]		; get handle
	call	CheckHandle
	jnc	chkdest
jmoveerror:
	jmp	moveerror
skipsource:
;
;	the following is for checking convential memory
;
;
;	the following is for checking convential memory
;
	mov	bx,word ptr es:[si+SOURCE_SEGPAGE]		; get initial page
	mov	di,word ptr es:[si+SOURCE_OFFSET]		; get initial offset
;
;	convert seg:offset into dword offset 
;
	call	Intel2Dword
	add	di,word ptr es:[si+REGION]		; add lower size
	adc	bx,word ptr es:[si+REGION+2] 		; add higher size		
	cmp	bx,10h				; greater than 1 neg
	jb	chkdest
	mov	ah,meg1wrap
	jmp	moveerror	
chkdest:
;
;	check to see if destination, if expanded memory, handle
;	is valid or not
;
	cmp	byte ptr es:[si+DEST_TYPE],01h
	jne	skipdest
	mov 	cx,word ptr es:[si+REGION]
	mov	ax,word ptr es:[si+REGION+2] 		; size of region in ax:cx
	mov	bx,word ptr es:[si+DEST_SEGPAGE]		; get initial page
	mov	di,word ptr es:[si+DEST_OFFSET]		; get initial offset
	mov	dx,word ptr es:[si+DEST_HANDLE]		; get handle
	call	CheckHandle
	jnc	contdest
	jmp	moveerror
skipdest:
;
;	the following is for checking convential memory
;
	mov	bx,word ptr es:[si+DEST_SEGPAGE]		; get initial page
	mov	di,word ptr es:[si+DEST_OFFSET]		; get initial offset
;
;	convert page:offset into dword offset 
;
	call	Intel2Dword
	add	di,word ptr es:[si+REGION]		; add lower size
	adc	bx,word ptr es:[si+REGION+2] 		; add higher size		
	cmp	bx,10h				; greater than 1 neg
	jb	contdest
	mov	ah,meg1wrap
	jmp	moveerror	
contdest:
;
;	Now we must check for overlaps
;	We have 3 possiable error conditions here
;	   1. Overlapping convential memory
;	   2. Overlapping expanding memory
;	   3. overlap of convential memory with expanded
;
;	First we will check if source is expanded	
;
	cmp	byte ptr es:[si+SOURCE_TYPE],01h		; check source
	jne	mp1
;
;	source is Expanded memory
;	
	cmp	byte ptr es:[si+DEST_TYPE],01h		; check destination
	je	mpchkdest
	jmp	mp2
mpchkdest:
;
;	both source and destination are expanded memory
;	check to see if handle are idential, if not it is ok
;
	mov	ax,word ptr es:[si+SOURCE_HANDLE] 		; get source handle
	cmp	ax,word ptr es:[si+DEST_HANDLE]		; compare it to dest handle
	je	mpchkol
	jmp	mpisok
mpchkol:
;
;	check to see if expanded memory pages overlap
;	
	mov	ax,word ptr es:[si+SOURCE_SEGPAGE]		; get source page
	mov	bx,word ptr es:[si+SOURCE_OFFSET]		; get source offset
	mov	cx,word ptr es:[si+DEST_OFFSET]		; get dest page
	mov	dx,word ptr es:[si+DEST_SEGPAGE]		; get dest offset
	cmp	ax,cx				; check source - dest
	ja	mp0source			; source is greater
	jne	mp0dest				; destination is greater
	cmp	bx,dx				; = compare soure - dest offset
	ja	mp0source			; source is greater
mp0dest:
;
;	destination is higher than source so exchange values
;
	xchg	ax,cx
	xchg	bx,dx	
mp0source:
;
;	now calcuated diference ax:bx - cx:dx
;
	sub	bx,dx
	jnc	mp0diff
	dec	ax			
	add	bx,4000h
mp0diff:
	sub	ax,cx
;
;	ax:bx has  difference is region
;	convert page:offset into dword size
;
	mov	cx,ax
	shr	ax,2
	shl	cx,2
	mov	ch,cl
	and	cx,0c000h
	add	bx,cx
	adc	ax,0
;
;	now compare size difference to copy\echnage region size
;
	cmp	ax,word ptr es:[si+REGION+2]
	ja	mp0ok
	cmp	bx,word ptr es:[si+REGION]
	ja	mp0ok
;
;	we have detected an overlap
;
	mov	[overlap],'Y'
	mov	ah,exch_overlap
	cmp	[subfunction],01h		; is this exchange
	je	omoveerror
	jmp	mpisok
omoveerror:
	jmp	moveerror
mp0ok:
	jmp	mpisok
;
;	come here if source is convential memory
;
mp1:
	cmp	byte ptr es:[si+DEST_TYPE],01h		; check destination
	je	mp2				
;
;	both source and destination are in convential memory and we have
; 	and overlap
;
	mov	bx,word ptr es:[si+SOURCE_OFFSET]		; get source offset
	mov	ax,word ptr es:[si+SOURCE_SEGPAGE]		; get source segment
	mov	di,bx
	shr	di,4
	add	ax,di
	and	bx,000fh
	mov	cx,word ptr es:[si+DEST_OFFSET]		; get dest segment
	mov	dx,word ptr es:[si+DEST_SEGPAGE]		; get dest offset
	mov	di,dx
	shr	di,4
	add	cx,di
	and	dx,000fh
	cmp	ax,cx				; check source - dest
	ja	mp1source			; source is greater
	jne	mp1dest				; destination is greater
	cmp	bx,dx				; = compare soure - dest offset
	ja	mp1source			; source is greater
mp1dest:
;
;	destination is higher than source so exchange values
;
	xchg	ax,cx
	xchg	bx,dx	
mp1source:
	sub	bx,dx
	jnc	mp1diff
	dec	ax
	add	bx,10h
mp1diff:
	sub	ax,cx	
	mov	dx,ax
	shl	dx,4
	or	bx,dx
	shr	ax,4
	cmp	ax,word ptr es:[si+REGION+2]
	ja	mp1ok
	cmp	bx,word ptr es:[si+REGION]
	ja	mp1ok
;
;	we have detected an overlap
;
	mov	[overlap],'Y'
mp1ok:
	jmp	mpisok    
;
;	come here if source and destination are diferent we will check for
;	overlap of memory use by convential
;	
mp2:
	cmp	byte ptr es:[si+SOURCE_TYPE],01h		; is source expanded memory
	je	sexpanded
;
;	handle destination in expanded expanded memory
;
	mov	ax,word ptr es:[si+DEST_SEGPAGE]		; get dest segment
	mov	bx,word ptr es:[si+DEST_OFFSET]		; get dest offset
	jmp	short mp3

sexpanded:
;
;	hande source in expanded memory
;
	mov	ax,word ptr es:[si+SOURCE_SEGPAGE]		; get source segment
	mov	bx,word ptr es:[si+SOURCE_OFFSET]		; get source offset
mp3:
	mov	cx,bx
	shr	cx,4				; convert offset into seg
	add	ax,cx
	and	bx,0000fh			; bx has remainder
	mov	cx,word ptr es:[si+REGION]		; get low part of size
	shr	cx,4				; convert offset into seg
	add	ax,cx
	mov	cx,word ptr es:[si+REGION]		; get low part of size
	add	cx,0000fh
	add	bx,ax
	cmp	bx,10h
	jb	mp4 				; is offset > paragraph
	inc	ax				; if so inc segments
mp4:
	mov	cx,word ptr es:[si+REGION+2]
	mov	ch,cl
	shl	cx,1
	shl	cx,1
	and	cx,0c000h
	add	ax,cx				
;
;	ax contains highest position that convential memory can have
;
	mov	cl,[map_area]
	xor	ch,ch
	xor	si,si
mploop:
	mov	bx,[map_segments+si]
	cmp	ax,bx
	jb	mpcont
	add	bx,4000h/16
	cmp	ax,bx
	jb	mp4err
mpcont:
	inc	si
	inc	si
	loop	mploop	
mpisok:
	xor	ah,ah
	clc
	jmp	short mpisdone
mp4err:
	mov	ah,conv_exp_overlap
moveerror:
	stc
mpisdone:
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	ret
moveparms endp

;
;	Convert Intel SEG:OFFSET into dword bytes
;
;	INPUT/EXIT BX:DI
;

Intel2Dword proc near
	push	cx
	xor	cx,cx
	mov	ax,bx
	and	ax,0fh
	shl	ax,4
	mov	bl,bh
	xor	bh,bh
	shr	bx,4
	add	di,ax
	adc	bx,0	
	pop	cx
	ret
Intel2Dword endp


CheckHandle	proc	near
	push	ds
	push	si
	mov	ah,offset_bad
	cmp	di,3fffh	      ; if initialial offset bad	
	ja	chbad
        mov	ah, soft_error        ; indicate error in software
        call	IsMaxHandle           ; compare to max # of handles
        ja	chbad                 ; bad handle #
        mov	ah, bad_handle        ; indicated bad handle
	call	GetEntry	      ; calculate offset into structure	
	cmp	byte ptr database[si].alloc,true
	jne	chbad
;
;	first we will check first handle to make sure that it 
;	will exist in our handle
;
	cmp	bx,word ptr database[si].pages			
	jae	chbadsz
	push	ax
	mov	ax,cx
	and	ax,03fffh		; mask size done for last page 
	add	ax,di
	cmp	ax,03fffh
	pop	ax
	jbe	ioffok
	inc	bx			; add a page 
ioffok:
	xor	ah,ah	
	rol	cx,1			; / 4000h
	rcl	ax,1			; move upper 2 bits 	
	rol	cx,1			; of lower word into upper word
	rcl	ax,1			
	add	bx,ax
	cmp	bx,word ptr database[si].pages
	jbe	chszok
chbadsz:
	mov	ah,page_exceed		; page limit exceeded
	jmp	chbad
chszok:

	pop	si
	pop	ds	
	clc
	ret
chbad:
	pop	si
	pop	ds
	stc
	ret
CheckHandle	endp

exchange proc	near
	cmp	byte ptr es:[si+SOURCE_TYPE],01h
	je	ExchExpTest
	cmp	byte ptr es:[si+DEST_TYPE],01h
	je	ExchToExp
	call	ExchConv			; Exchange Convential memory
	ret
ExchToExp:
	call	ExchConvExp			; Exchange convential to expanded
	ret
ExchExpTest:
	cmp	byte ptr es:[si+DEST_TYPE],01h
	jne	ExchToConv
	call	ExchExp				; Exchange expanded memory
	ret
ExchToConv:
	call	ExchExpConv			; Exchange expanded to convential
	ret
exchange endp


ExchConv proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	es

	push	ds
	push	si

	mov	ah,exch_overlap
	cmp	cs:[Overlap],'Y'
	je	ExchConvOut
;
;	Handle no overlap
;
	mov	bx,word ptr es:[si+SOURCE_SEGPAGE]
	mov	ax,word ptr es:[si+SOURCE_OFFSET]
	mov	dx,word ptr es:[si+DEST_SEGPAGE]
	mov	cx,word ptr es:[si+DEST_OFFSET]
	mov	[CurPage1],-1
	mov	[CurPage2],-1
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
ExchCLoop:
	push	si
	push	di
	call	ConvNext
	cmp	[TranSize],0
	jz	ExchCDone
	push	cx
	push	ds
	push	es

	mov	cx,[TranSize]
	mov	es,[CurPage1]
	mov	ds,[CurPage2]
	shr	cx,1			; for restoration if need to retry
	pushf
ConvLoop:
	mov	ax,word ptr ds:[si]
	xchg	ax,word ptr es:[di]
	mov	word ptr ds:[si],ax
	add	si,2
	add	di,2
	loop	ConvLoop
	popf
	jnc	LPEConvEven
	mov	al,byte ptr ds:[si]
	xchg	al,byte ptr es:[di]
	mov	byte ptr ds:[si],al
LPEConvEven:

	pop	es
	pop	ds
	pop	cx

	pop	di
	pop	si
	jmp	short ExchCLoop	
ExchCDone:
	pop	di
	pop	si
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]
	
	xor	ah,ah
ExchConvOut:
	

	pop	si
	pop	ds

	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
ExchConv endp


ExchExp	proc	near
	push	bx
	push	cx
	push	dx
	push	di
	push	es

	call	SaveTMap		; Save Transfer Map area
	push	ds
	push	si

	mov	cx,word ptr es:[si+SOURCE_HANDLE]
	cmp	cx,word ptr es:[si+DEST_HANDLE]
	jne	ExchSDiff
	mov	ah,exch_overlap
	cmp	cs:[Overlap],'Y'
	je	ExchExpOut
ExchSDiff:
;
;	handle different handles  or same handles and no overlap
;
	mov	bx,word ptr es:[si+SOURCE_SEGPAGE]
	mov	ax,word ptr es:[si+SOURCE_OFFSET]
	mov	dx,word ptr es:[si+DEST_SEGPAGE]
	mov	cx,word ptr es:[si+DEST_OFFSET]
	mov	[CurPage1],-1
	mov	[CurPage2],-1
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
ExchSLoop:
	push	si
	push	di
	call	MapNext
	cmp	[TranSize],0
	jz	ExchSDone
	push	cx
	push	ds
	push	es

	mov	cx,[TranSize]
	mov	es,word ptr map_segments[2]
	mov	ds,word ptr map_segments[0]
	shr	cx,1			; for restoration if need to retry
	pushf
ExpLoop:
	mov	ax,word ptr ds:[si]
	xchg	ax,word ptr es:[di]
	mov	word ptr ds:[si],ax
	add	si,2
	add	di,2
	loop	ExpLoop
	popf
	jnc	LPEExpEven
	mov	al,byte ptr ds:[si]
	xchg	al,byte ptr es:[di]
	mov	byte ptr ds:[si],al
LPEExpEven:

	pop	es
	pop	ds
	pop	cx

	pop	di
	pop	si
	jmp	short ExchSLoop	
ExchSDone:
	pop	di
	pop	si
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]
	xor	ah,ah
ExchExpOut:

	pop	si
	pop	ds
	call	RestoreTMap		; Restore TRansfer Map Area

	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	ret
ExchExp	endp

ExchExpConv proc near
	push    bx
	push	cx
	push	di
	push	es

	call	SaveTMap		; Save Transfer Map area
	push	ds
	push	si

	mov	ax,word ptr es:[si+DEST_SEGPAGE]
	mov	word ptr [taddress+2],ax
	mov	ax,word ptr es:[si+DEST_OFFSET]
	mov	word ptr [taddress],ax
	mov	ax,word ptr es:[si+REGION+2]
	mov	bx,word ptr es:[si+REGION]
	mov	cx,4000h		
	mov	di,word ptr es:[si+SOURCE_OFFSET]
	sub	cx,di
	mov	dx,word ptr es:[si+SOURCE_SEGPAGE]
	mov	[Ems_Page],dx
	mov	dx,word ptr es:[si+SOURCE_HANDLE]
LPXExpConv:
	or	ax,ax
	jnz	LPECX1
	cmp	bx,cx
	jae	LPECX1
	mov	cx,bx
LPECX1:
	call	MapTran
;
;	Transfer CX bytes from Work map area to tranfer area
;
	push	cx
	push	si
	push	di
	push	ds
	push	es

	mov	si,di
	mov	es,word ptr [taddress+2]
	mov	di,word ptr [taddress]
	mov	ds,word ptr map_segments[0]
	shr	cx,1	
	pushf
ECLoop:
	mov	ax,word ptr ds:[si]
	xchg	ax,word ptr es:[di]
	mov	word ptr ds:[si],ax
	add	si,2
	add	di,2
	loop	ECLoop
	popf
	jnc	LPECXEven
	mov	al,byte ptr ds:[si]
	xchg	al,byte ptr es:[di]
	mov	byte ptr ds:[si],al
LPECXEven:



	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx

;
;	test to see if we are done
;	
	or	ax,ax
	jnz	LPECX2
	cmp	bx,cx
	je	LPECXSkip		
LPECX2:
	
;
;	Now adjust pointers for next Exchange
;
	add	word ptr [taddress],cx
	adc	word ptr [taddress+2],0
	inc	[Ems_Page]
	sub	bx,cx
	sbb	ax,0
	mov	cx,4000h
	xor	di,di
	jmp	LPXExpConv
LPECXSkip:			
	pop	si
	pop	ds
	call	RestoreTMap		; Restore TRansfer Map Area
	xor	ah,ah

	pop	es
	pop	di
	pop	cx
	pop	bx
	ret
ExchExpConv endp

ExchConvExp proc near
	push	cx
	push	di
	push	es

	call	SaveTMap		; Save Transfer Map area
	push	ds
	push	si

	mov	ax,word ptr es:[si+SOURCE_SEGPAGE]
	mov	word ptr [taddress+2],ax
	mov	ax,word ptr es:[si+SOURCE_OFFSET]
	mov	word ptr [taddress],ax
	mov	ax,word ptr es:[si+REGION+2]
	mov	bx,word ptr es:[si+REGION]
	mov	cx,4000h		
	mov	di,word ptr es:[si+DEST_OFFSET]
	sub	cx,di
	mov	dx,word ptr es:[si+DEST_SEGPAGE]
	mov	[Ems_Page],dx
	mov	dx,word ptr es:[si+DEST_HANDLE]
LPXConvExp:
	or	ax,ax
	jnz	LPCEX1
	cmp	bx,cx
	jae	LPCEX1
	mov	cx,bx
LPCEX1:
	call	MapTran
;
;	Transfer CX bytes from transfer area to work area
;
	push	cx
	push	si
	push	di
	push	ds
	push	es

	mov	si,word ptr [taddress]
	mov	es,word ptr map_segments[0]
	mov	ds,word ptr [taddress+2]
	shr	cx,1	
	pushf
CELoop:
	mov	ax,word ptr ds:[si]
	xchg	ax,word ptr es:[di]
	mov	word ptr ds:[si],ax
	add	si,2
	add	di,2
	loop	CELoop
	popf
	jnc	LPCEXEven
	mov	al,byte ptr ds:[si]
	xchg	al,byte ptr es:[di]
	mov	byte ptr ds:[si],al
LPCEXEven:

	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx

;
;	test to see if we are done
;	
	or	ax,ax
	jnz	LPCEX2
	cmp	bx,cx
	je	LPCEXSkip		
LPCEX2:
	
;
;	Now adjust pointers for next Exchange
;
	add	word ptr [taddress],cx
	adc	word ptr [taddress+2],0
	inc	[Ems_Page]
	sub	bx,cx
	sbb	ax,0
	mov	cx,4000h
	xor	di,di
	jmp	LPXConvExp
LPCEXSkip:			

	pop	si
	pop	ds
	call	RestoreTMap		; Restore TRansfer Map Area

	xor	ah,ah

	pop	es
	pop	di
	pop	cx
	ret
ExchConvExp endp



move	proc	near
	cmp	byte ptr es:[si+SOURCE_TYPE],01h
	je	moveExpTest
	cmp	byte ptr es:[si+DEST_TYPE],01h
	je	MoveToExp
	call	MoveConv			; Move Convential memory
	ret
MoveToExp:
	call	MoveConvExp			; move convential to expanded
	ret
MoveExpTest:
	cmp	byte ptr es:[si+DEST_TYPE],01h
	jne	MoveToConv
	call	MoveExp				; move expanded memory
	ret
MoveToConv:
	call	MoveExpConv			; move expanded to convential
	ret
move	endp

MoveConv proc	near
	push	bx
	push	cx
	push	dx
	push	di
	push	es

	push	ds
	push	si

	cmp	cs:[Overlap],'Y'
	jne	MoveCDiff
	jmp	MoveCConv			; handle OverLap
MoveCDiff:
;
;	Handle no overlap
;
	mov	bx,word ptr es:[si+SOURCE_SEGPAGE]
	mov	ax,word ptr es:[si+SOURCE_OFFSET]
	mov	dx,word ptr es:[si+DEST_SEGPAGE]
	mov	cx,word ptr es:[si+DEST_OFFSET]
	call	MoveConvMain			; main move routine		
	jmp	MoveConvOut
MoveCConv:
;
;	we are mapping at with overlap area, we must first transfer
;	area which is overlaped first and then we will transfer 
;	lower portion.  We need to test for condition of move up in memory
;	or move down in memory
;
	mov	ax,word ptr es:[si+SOURCE_SEGPAGE]
	mov	cx,word ptr es:[si+DEST_SEGPAGE]
	mov	bx,word ptr es:[si+SOURCE_OFFSET]
	mov	di,bx
	shr	di,4
	add	ax,di
	and	bx,000fh
	mov	dx,word ptr es:[si+DEST_OFFSET]
	mov	di,dx
	shr	di,4
	add	cx,di
	and	dx,000fh
	cmp	ax,cx
	ja	jMoveCDown
	jb	MoveCUp
	cmp	bx,dx
	jb	MoveCUp
	je	JMoveConvOut
JMoveCDown:	
	jmp	MoveCDown
JMoveConvOut:
	jmp	MoveConvOut			; both equal, we are done
;
;	Moving Up in memory
;
MoveCUp:
	xchg	ax,cx
	xchg	bx,dx
	sub	ax,cx
	cmp	bx,dx
	jae	MoveCUp1
	dec	ax
	add	bx,10
MoveCUp1:
	sub	bx,dx
	mov	cx,ax				
	mov	dx,bx
;
; 	convert page\bytes into dword of bytes
;
	push	cx
	mov	cx,ax
	shr	ax,4
	shl	cx,4
	or	bx,cx
	pop	cx	
;	
	push	ax
	push	bx
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
	sub	word ptr es:[si+REGION],bx
	sbb	word ptr es:[si+REGION+2],ax
	add	bx,word ptr es:[si+SOURCE_SEGPAGE]
	add	ax,word ptr es:[si+SOURCE_OFFSET]
	add	cx,word ptr es:[si+DEST_OFFSET]
	add	dx,word ptr es:[si+DEST_SEGPAGE]
	call	MoveConvMain			; main move routine		
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]
	pop	bx
	pop	ax
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
	mov	word ptr es:[si+REGION],bx
	mov	word ptr es:[si+REGION+2],ax
	mov	bx,word ptr es:[si+SOURCE_SEGPAGE]
	mov	ax,word ptr es:[si+SOURCE_OFFSET]
	mov	dx,word ptr es:[si+DEST_SEGPAGE]
	mov	cx,word ptr es:[si+DEST_OFFSET]
	call	MoveConvMain			; main move routine		
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]
	jmp	MoveConvOut	


;
; Moving down in memory
;
MoveCDown:
	sub	ax,cx
	cmp	bx,dx
	jae	MoveCUp1
	dec	ax
	add	bx,10
MoveCDown1:
	sub	bx,dx
	mov	cx,ax				
	mov	dx,bx
;
; 	convert page\bytes into dword of bytes
;
	push	cx
	mov	cx,ax
	shr	ax,4
	shl	cx,4
	or	bx,cx
	pop	cx	
	push	ax
	push	bx
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
	sub	word ptr es:[si+REGION],bx
	sbb	word ptr es:[si+REGION+2],ax
	sub	bx,word ptr es:[si+SOURCE_SEGPAGE]
	sbb	ax,word ptr es:[si+SOURCE_OFFSET]
	add	cx,word ptr es:[si+DEST_OFFSET]
	add	dx,word ptr es:[si+DEST_SEGPAGE]
	call	MoveConvMain			; main move routine		
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]
	pop	bx
	pop	ax
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
	mov	word ptr es:[si+REGION],bx
	mov	word ptr es:[si+REGION+2],ax
	mov	bx,word ptr es:[si+SOURCE_SEGPAGE]
	mov	ax,word ptr es:[si+SOURCE_OFFSET]
	mov	dx,word ptr es:[si+DEST_SEGPAGE]
	mov	cx,word ptr es:[si+DEST_OFFSET]
	call	MoveConvMain			; main move routine		
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]

MoveConvOut:
	xor	ah,ah

	pop	si
	pop	ds

	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	ret
MoveConv endp

MoveExp	proc	near
	push	bx
	push	cx
	push	dx
	push	di
	push	es

	call	SaveTMap		; Save Transfer Map area
	push	ds
	push	si

	mov	cx,word ptr es:[si+SOURCE_HANDLE]
	cmp	cx,word ptr es:[si+DEST_HANDLE]
	jne	MoveSDiff
	cmp	cs:[Overlap],'Y'
	jne	MoveSDiff
	jmp	MoveSExp			; same handles
MoveSDiff:
;
;	handle different handles  or same handles and no overlap
;
	mov	bx,word ptr es:[si+SOURCE_SEGPAGE]
	mov	ax,word ptr es:[si+SOURCE_OFFSET]
	mov	dx,word ptr es:[si+DEST_SEGPAGE]
	mov	cx,word ptr es:[si+DEST_OFFSET]
	call	MoveExpMain			; main move routine		
	jmp	MoveExpOut
MoveSExp:
;
;	we are mapping at with overlap area, we must first transfer
;	area which is overlaped first and then we will transfer 
;	lower portion.  We need to test for condition of move up in memory
;	or move down in memory
;
	mov	ax,word ptr es:[si+SOURCE_SEGPAGE]
	cmp	ax,word ptr es:[si+DEST_SEGPAGE]
	ja	jMoveDown
	jb	MoveUp
	mov	ax,word ptr es:[si+SOURCE_OFFSET]
	cmp	ax,word ptr es:[si+DEST_OFFSET]
	jb	MoveUp
	je	JMoveExpOut
JMoveDown:	
	jmp	MoveDown
JMoveExpOut:
	jmp	MoveExpOut			; both equal, we are done
;
;	Moving Up in memory
;
MoveUp:
	mov	ax,word ptr es:[si+DEST_SEGPAGE]
	sub	ax,word ptr es:[si+SOURCE_SEGPAGE]
	mov	bx,word ptr es:[si+DEST_OFFSET]
	cmp	bx,word ptr es:[si+SOURCE_OFFSET]
	jae	MoveUp1
	dec	ax
	add	bx,4000h
MoveUp1:
	sub	bx,word ptr es:[si+SOURCE_OFFSET]
	mov	cx,ax				
	mov	dx,bx
;
; 	convert page\bytes into dword of bytes
;
	push	cx
	mov	ch,al
	xor	cl,cl
	shl	cx,2
	or	bx,cx
	shr	ax,2
	pop	cx	
;	
	push	ax
	push	bx
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
	sub	word ptr es:[si+REGION],bx
	sbb	word ptr es:[si+REGION+2],ax
	add	bx,word ptr es:[si+SOURCE_SEGPAGE]
	add	ax,word ptr es:[si+SOURCE_OFFSET]
	cmp	ax,4000h
	jb	MoveUp2
	sub	ax,4000h
	inc	bx
MoveUp2:
	add	cx,word ptr es:[si+DEST_OFFSET]
	add	dx,word ptr es:[si+DEST_SEGPAGE]
	cmp	cx,4000h
	jb	MoveUp3
	sub	cx,4000h
	inc	dx
MoveUp3:	
	call	MoveExpMain			; main move routine		
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]
	pop	bx
	pop	ax
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
	mov	word ptr es:[si+REGION],bx
	mov	word ptr es:[si+REGION+2],ax
	mov	bx,word ptr es:[si+SOURCE_SEGPAGE]
	mov	ax,word ptr es:[si+SOURCE_OFFSET]
	mov	dx,word ptr es:[si+DEST_SEGPAGE]
	mov	cx,word ptr es:[si+DEST_OFFSET]
	call	MoveExpMain			; main move routine		
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]
	jmp	MoveExpOut	


;
; Moving down in memory
;
MoveDown:
	mov	ax,word ptr es:[si+SOURCE_SEGPAGE]
	sub	ax,word ptr es:[si+DEST_SEGPAGE]
	mov	bx,word ptr es:[si+SOURCE_OFFSET]
	cmp	bx,word ptr es:[si+DEST_OFFSET]
	jae	MoveDown1
	dec	ax
	add	bx,4000h
MoveDown1:
	sub	bx,word ptr es:[si+DEST_OFFSET]
;
; 	convert page\bytes into dword of bytes
;
	push	cx
	mov	ch,al
	xor	cl,cl
	shl	cx,2
	or	bx,cx
	shr	ax,2
	pop	cx	
;
	push	ax
	push	bx
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
	sub	word ptr es:[si+REGION],bx
	sbb	word ptr es:[si+REGION+2],ax
	sub	bx,word ptr es:[si+SOURCE_SEGPAGE]
	sub	ax,word ptr es:[si+SOURCE_OFFSET]
	cmp	ax,0
	jb	MoveDown2
	add	ax,4000h
	dec	bx
MoveDown2:
	add	cx,word ptr es:[si+DEST_OFFSET]
	add	dx,word ptr es:[si+DEST_SEGPAGE]
	cmp	cx,0
	jb	MoveDown3
	add	cx,4000h
	dec	dx
MoveDown3:	
	call	MoveExpMain			; main move routine		
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]
	pop	bx
	pop	ax
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
	mov	word ptr es:[si+REGION],bx
	mov	word ptr es:[si+REGION+2],ax
	mov	bx,word ptr es:[si+SOURCE_SEGPAGE]
	mov	ax,word ptr es:[si+SOURCE_OFFSET]
	mov	dx,word ptr es:[si+DEST_SEGPAGE]
	mov	cx,word ptr es:[si+DEST_OFFSET]
	call	MoveExpMain			; main move routine		
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]

MoveExpOut:

	pop	si
	pop	ds
	call	RestoreTMap		; Restore TRansfer Map Area
	xor	ah,ah

	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	ret
MoveExp	endp

MoveExpConv proc near
	push	cx
	push	di
	push	es

	call	SaveTMap		; Save Transfer Map area
	push	ds
	push	si

	mov	ax,word ptr es:[si+DEST_SEGPAGE]
	mov	word ptr [taddress+2],ax
	mov	ax,word ptr es:[si+DEST_OFFSET]
	mov	word ptr [taddress],ax
	mov	ax,word ptr es:[si+REGION+2]
	mov	bx,word ptr es:[si+REGION]
	mov	cx,4000h		
	mov	di,word ptr es:[si+SOURCE_OFFSET]
	sub	cx,di
	mov	dx,word ptr es:[si+SOURCE_SEGPAGE]
	mov	[Ems_Page],dx
	mov	dx,word ptr es:[si+SOURCE_HANDLE]
LPExpConv:
	or	ax,ax
	jnz	LPEC1
	cmp	bx,cx
	jae	LPEC1
	mov	cx,bx
LPEC1:
	call	MapTran
;
;	Transfer CX bytes from Work map area to tranfer area
;
	push	cx
	push	si
	push	di
	push	ds
	push	es

	mov	si,di
	mov	es,word ptr [taddress+2]
	mov	di,word ptr [taddress]
	mov	ds,word ptr map_segments[0]
	shr	cx,1			; for restoration if need to retry
	rep	movsw
	jnc	LPECEven
	movsb
LPECEven:

	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
;
;	test to see if we are done
;	
	or	ax,ax
	jnz	LPEC2
	cmp	bx,cx
	je	LPECSkip		
LPEC2:
	
;
;	Now adjust pointers for next move
;
	add	word ptr [taddress],cx
	adc	word ptr [taddress+2],0
	inc	[Ems_Page]
	sub	bx,cx
	sbb	ax,0
	mov	cx,4000h
	xor	di,di
	jmp	LPExpConv
LPECSkip:			

	pop	si
	pop	ds
	call	RestoreTMap		; Restore TRansfer Map Area
	xor	ah,ah

	pop	es
	pop	di
	pop	cx
	ret
MoveExpConv endp

MoveConvExp proc near
	push	cx
	push	di
	push	es

	call	SaveTMap		; Save Transfer Map area
	push	ds
	push	si

	mov	ax,word ptr es:[si+SOURCE_SEGPAGE]
	mov	word ptr [taddress+2],ax
	mov	ax,word ptr es:[si+SOURCE_OFFSET]
	mov	word ptr [taddress],ax
	mov	ax,word ptr es:[si+REGION+2]
	mov	bx,word ptr es:[si+REGION]
	mov	cx,4000h		
	mov	di,word ptr es:[si+DEST_OFFSET]
	sub	cx,di
	mov	dx,word ptr es:[si+DEST_SEGPAGE]
	mov	[Ems_Page],dx
	mov	dx,word ptr es:[si+DEST_HANDLE]
LPConvExp:
	or	ax,ax
	jnz	LPCE1
	cmp	bx,cx
	jae	LPCE1
	mov	cx,bx
LPCE1:
	call	MapTran
;
;	Transfer CX bytes from transfer area to work area
;
	push	cx
	push	si
	push	di
	push	ds
	push	es

	mov	si,word ptr [taddress]
	mov	es,word ptr map_segments[0]
	mov	ds,word ptr [taddress+2]
	shr	cx,1	
	rep	movsw
	jnc	LPCEEven
	movsb
LPCEEven:

	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx

;
;	test to see if we are done
;	
	or	ax,ax
	jnz	LPCE2
	cmp	bx,cx
	je	LPCESkip		
LPCE2:
	
;
;	Now adjust pointers for next Exchange
;
	add	word ptr [taddress],cx
	adc	word ptr [taddress+2],0
	inc	[Ems_Page]
	sub	bx,cx
	sbb	ax,0
	mov	cx,4000h
	xor	di,di
	jmp	LPConvExp
LPCESkip:			

	pop	si
	pop	ds
	call	RestoreTMap		; Restore TRansfer Map Area
	xor	ah,ah

	pop	es
	pop	di
	pop	cx
	ret
MoveConvExp endp


;
;	BX:AX -> Source Page\offset
;	DX:CX -> Dest Page\Offset
;

MoveExpMain	proc	near
	mov	[CurPage1],-1
	mov	[CurPage2],-1
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
MoveSLoop:
	push	si
	push	di
	call	MapNext
	cmp	[TranSize],0
	jz	MoveSDone
	push	cx
	push	ds
	push	es

	mov	cx,[TranSize]
	mov	es,word ptr map_segments[2]
	mov	ds,word ptr map_segments[0]
	shr	cx,1			; for restoration if need to retry
	rep	movsw
	jnc	LPExpEven
	movsb
LPExpEven:

	pop	es
	pop	ds
	pop	cx

	pop	di
	pop	si
	jmp	short MoveSLoop	
MoveSDone:
	pop	di
	pop	si
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]
	ret
MoveExpMain endp

;
;	BX:AX -> Source Page\offset
;	DX:CX -> Dest Page\Offset
;

MoveConvMain	proc	near
	mov	[CurPage1],-1
	mov	[CurPage2],-1
	push	word ptr es:[si+REGION]
	push	word ptr es:[si+REGION+2]
MoveCLoop:
	push	si
	push	di
	call	ConvNext
	cmp	[TranSize],0
	jz	MoveCDone
	push	cx
	push	ds
	push	es

	mov	cx,[TranSize]
	mov	es,[CurPage1]
	mov	ds,[CurPage2]
	shr	cx,1			; for restoration if need to retry
	rep	movsw
	jnc	LPConvEven
	movsb
LPConvEven:

	pop	es
	pop	ds
	pop	cx

	pop	di
	pop	si
	jmp	short MoveCLoop	
MoveCDone:
	pop	di
	pop	si
	pop	word ptr es:[si+REGION+2]
	pop	word ptr es:[si+REGION]
	ret
MoveConvMain endp

;
;	BX:AX -> Source Page\offset
;	DX:CX -> Dest Page\Offset
;

ConvNext proc	near
	mov	[TranSize],0FFF0h		; set max for transfer size
	mov	di,ax				; get source offset
	cmp	di,cx				; compare it to destination
	ja	CNext1
	mov	di,cx				; use destination
CNext1:
	sub	[TranSize],di			; max size we can tranfers
	mov	di,-1	
	cmp	word ptr es:[si+REGION+2],0		; to we have a high value
	jne	CNext2
	mov	di,word ptr es:[si+REGION]		; no so get low value
	cmp	[TranSize],di			; if desired > remaining
	jbe	CNext2				; no use desired....
	mov	[TranSize],di			; use size remaining
CNext2:
	cmp	[TranSize],0			; are we done?
	jne	CNext3
	ret
CNext3:
;
; 	Set Segment for Source
;
	cmp	bx,[CurPage1]
	je	CNext4
	mov	[CurPage1],bx
CNext4:
;
; 	SetSegment for destination
;
	cmp	dx,[CurPage2]
	je	CNext5
	mov	[CurPage2],dx
CNext5:		
;
;	Sub transfer size from counter
;	
	mov	di,[TranSize]
	sub	word ptr es:[si+REGION],di
	cmp	word ptr es:[si+REGION],0
	jb	CNext6
	cmp	word ptr es:[si+REGION+2],0
	je	CNext6
	dec	word ptr es:[si+REGION+2]
CNext6:
;
;	Set Si and DI to starting offsets
;
	mov	si,ax
	mov	di,cx
;
;	adjust BX:AX and DX:AX to new locations
;
	push	di
	add	ax,[TranSize]
	cmp	ax,0fh
	jb	CNext7
	mov	di,ax
	and	ax,000fh
	shr	di,4
	add	bx,di
CNext7:
	add	cx,[TranSize]
	cmp	cx,0fh
	jb	CNext8
	mov	di,cx
	and	cx,000fh
	shr	di,4
	add	dx,di
CNext8:
	pop	di
	ret
ConvNext endp

;
;	BX:AX -> Source Page\offset
;	DX:CX -> Dest Page\Offset
;

MapNext	proc	near
	mov	[TranSize],4000h		; set max for transfer size
	mov	di,ax				; get source offset
	cmp	di,cx				; compare it to destination
	ja	MNext1
	mov	di,cx				; use destination
MNext1:
	sub	[TranSize],di			; max size we can tranfers
	mov	di,-1	
	cmp	word ptr es:[si+REGION+2],0		; to we have a high value
	jne	MNext2
	mov	di,word ptr es:[si+REGION]		; no so get low value
	cmp	[TranSize],di			; if desired > remaining
	jbe	MNext2				; no use desired....
	mov	[TranSize],di			; use size remaining
MNext2:
	cmp	[TranSize],0			; are we done?
	jne	MNext3
	ret
MNext3:
;
; 	Now Map in handle BX to Physical Page 1
;
	cmp	bx,[CurPage1]
	je	MNext4
	mov	[CurPage1],bx
	mov	[Ems_page],bx
	push	dx
	mov	dx,word ptr es:[si+SOURCE_HANDLE]
	call	MapTran
	pop	dx
MNext4:
;
; 	Now Map in handle DX to Physical Page 2
;
	cmp	dx,[CurPage2]
	je	MNext5
	mov	[CurPage2],dx
	mov	[Ems_Page],dx
	push	dx
	mov	dx,word ptr es:[si+DEST_HANDLE]
	call	MapTran2
	pop	dx
MNext5:		
;
;	Sub transfer size from counter
;	
	mov	di,[TranSize]
	sub	word ptr es:[si+REGION],di
	cmp	word ptr es:[si+REGION],0
	jb	MNext6
	cmp	word ptr es:[si+REGION+2],0
	je	MNext6
	dec	word ptr es:[si+REGION+2]
MNext6:
;
;	Set Si and DI to starting offsets
;
	mov	si,ax
	mov	di,cx
;
;	adjust BX:AX and DX:CX to new locations
;
	add	ax,[TranSize]
	cmp	ax,4000h
	jb	MNext7
	sub	ax,4000h
	inc	bx
MNext7:
	add	cx,[TranSize]
	cmp	cx,4000h
	jb	MNext8
	sub	cx,4000h
	inc	dx
MNext8:
	ret
MapNext	endp


MapTran2 proc	near
	mov	cs:[Map2],'Y'
	call	MapTran
	mov	cs:[Map2],'N'
	ret
MapTran2 endp

MapTran	proc	near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	ds

	call	getentry
	mov	dx,word ptr database[si].link
	mov	bx,[ems_page]
MTLoop:
	or	bx,bx
	jz	MTDone
	dec	bx
	push	si
	mov	si,dx
	shl	si,2
	add	si,[bitoffset]
	mov	dx,word ptr [si].linkptr
	pop	si
	jmp	short MTLoop
MTDone:
	cmp	[Map2],'Y'
	je	MTMap2
	xor	al,al			; place into first slot
	call	getmem
	jmp	short MTFinsh

MTMap2:
	mov	al,1			; place into second slot
	call	getmem
MTFinsh:

	pop	ds
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
MapTran	endp

SaveTMap proc	near
	push	ax
	mov	ax,word ptr windmap[0]
	mov	[savemap],ax
	mov	ax,word ptr windmap[2]
	mov	[savemap+2],ax
	pop	ax
	ret
SaveTMap endp

RestoreTMap proc near
	push	ax
	push	dx
	mov	dx,[savemap]   		; get save map 
	xor	al,al			; place into first slot
	call	getmem
	mov	dx,[savemap+2]   	; get save map #2
	mov	al,1			; place into second slot
	call	getmem
	pop	dx
	pop	ax
	ret
RestoreTMap endp

;--------------------------------------------------------------------

;---------------------------------------------------------------------
; Function 25 -	get physical address array
;---------------------------------------------------------------------
getphymap proc	near
	cmp	al,01h
	jne	Not2501
	xor	ah,ah
	mov	cl,cs:[map_area]
	xor	ch,ch
	jmp	short Out25
Not2501:
	mov	ah,invalid_parm
	or	al,al
	jnz	Out25
	mov	ah,cs:[address]	; get base address
	xor	al,al
	xor	bx,bx
	push	di
	mov	cl,cs:[map_area]
	xor	ch,ch
gpyloop:
	stosw
	mov	word ptr es:[di],bx
	inc	di
	inc	di
	inc	bl
	add	ah,4			; adjust to next address
	loop	gpyloop
	pop	di
	mov	cl,cs:[map_area]	
	xor	ch,ch
	xor	ah,ah
Out25:
	ret
getphymap endp


;---------------------------------------------------------------------
; Function 26 -	get expanded memory hardware information
;---------------------------------------------------------------------
getinfo	proc	near
	mov	ah,access_denied
	cmp	[OSEEnable],'Y'		; is OS/E available
	jne	ginfoout
	or	al,al
	jnz	ginfo1
;
;	Handle subfunction 00h - get hardware configuration array
;
	push	di
	mov	ax,0400h			; ram page is 16K
	stosw
	xor	ax,ax				; 0 alternate reg set
	stosw
	mov	al,map_area			; return context size
	shl	ax,1
	stosw
	xor	ax,ax				; no dma channels
	stosw		
	pop	di
	xor	ah,ah	      			; no errors
	jmp	short ginfoout			

ginfo1:
	mov	ah,invalid_parm
	dec	al
	jnz	ginfoout			; invalid parameter if > 1
	xor	ah,ah
        mov	bx, [pgsleft]         ; get # of unallocated pages
	mov	TBX,bx
        mov	dx, [pgsavail]        ; get max # of pages
        cmp	bx, dx                ; compare them....
        jbe	ginfoout              ; should always happen...
        mov	ah, soft_error        ; indicate error in software
ginfoout:
	ret
getinfo endp

;---------------------------------------------------------------------------
; Function 27 -	allocate raw pages
;---------------------------------------------------------------------------
rawalloc proc	near
	cmp	al,02h
	jb	jmpalloc
	mov	ah,invalid_parm
	ret

jmpalloc:
	mov	[ZeroCheck],'N'		; don't check for Zero pages
	jmp	allocate		; jmp to allocate routine
rawalloc endp

;---------------------------------------------------------------------
; Function 28 -	alternate map register set
;		DMA register sets are not supported
;		Internal Alternate Register Map are not supported
;---------------------------------------------------------------------
altermap proc	near
	mov	cs:[subfunction],al
	mov	ah,access_denied
	cmp	[OSEEnable],'Y'		; is OS/E available
	jne	jalterout
	mov	ah,invalid_parm
	cmp	al,08
	jbe	alterfunok
jalterout:
	jmp	alterout
alterfunok:
	mov	ah,regset0
	or	al,al
	jnz	not2800
;
;	Get current register state and place it into ES:DI
;	Get Task Pointer for current Alternate Register Set
;
	mov	di,word ptr [TaskAltReg]
	mov	es,word ptr [TaskAltReg+2]
	mov	ax,es
	or	ax,di
	jz	skip2800
	call	GetArray
skip2800:
	mov	bx,TBX
	xor	bl,bl			; return no alternate register sets
	mov	TBX,bx
	jmp	short alterout1
not2800:
	cmp	al,01h
	jne	not2801
;
;	Save alternate register state from ES:DI
;
	mov	ah,no_alternate
	mov	bx,TBX
	or	bl,bl
	jnz	alterout
	push	ax
	mov	ax,es
	or	ax,di
	or	ax,ax
	pop	ax
	jz	SkipSaveAlter
DoSaveAlter:
	push	si
	push	ds
	mov	si,es
	mov	ds,si	
	mov	si,di
	call	savarray
	pop	ds
	pop	si
	call	setport	
SkipSaveAlter:
;
;	set Internal Alternate Register Set for Current Task
;
	push	ax
	mov	word ptr [TaskAltReg],di
	mov	ax,es
	mov	word ptr [TaskAltReg+2],ax
	pop	ax
	jmp	short alterout1
not2801:
	cmp	al,02h
	jne	not2802
	mov	dl,map_area
	xor	dh,dh
	shl	dx,1
	jmp	short alterout1
not2802:
	mov	ah,not_supported
	cmp	al,03h
	je	do280305
	cmp	al,05h
	jne	alterout
do280305:
	mov	bx,TBX
	xor	bl,bl			; return 0 sets
	mov	TBX,bx
alterout1:
	xor	ah,ah
alterout:
	mov	al,cs:[subfunction]
	ret
altermap endp

;---------------------------------------------------------------------
; Function 29 -	prepare expanded memory hardware for warm boot
;---------------------------------------------------------------------
;
; Since this is a simulate software version of EMS, we don't support
; non-violatile memory management. 
; 
;-----------------------------------------------------------------------
warmboot proc	near
    	xor	ah,ah
	ret
warmboot endp

;---------------------------------------------------------------------
; Function 30 -	enable\disable OS/E functions
;---------------------------------------------------------------------
osefun  proc	near
	mov	ah,invalid_parm
	cmp	al,02h
	ja	oseout
	je	osechk
;
;	now check to see if OSE is set
;
	cmp	[OSEKeyBX],-1
	jne	osechk
	cmp	[OSEKeyCX],-1
	jne	osechk
;
;	derive new OS/E keys
;
	mov	bx,040h
	mov	ds,bx
	mov	bx,ds:[6ch]		; get time values
	mov	cx,ds:[6eh]		
	add	bx,ds:[1eh]		; add start of keyboard
	add	cx,ds:[20h]		
	sub	cx,ds:[6dh]		; sub mid-portion of timer
	add	bx,05555h		; add a contant
	mov	[OSEKeyBX],bx
	mov	[OSEKeyCX],cx	; save keys	
	jmp	short osecont
osechk:
	mov	ah,access_denied
	cmp	bx,[OSEKeyBX]
	jne	oseout
	cmp	cx,[OSEKeyCX]
	jne	oseout
;
;	handle OS/E functions
;
osecont:
	cmp	al,01h		
	ja	oseok		; ok for check handle
	mov	bl,'Y'
	jne	oseset		; if function 00 enable it
	mov	bl,'N'		; else disable it
oseset:
	mov	[OSEEnable],bl	
oseok:
	xor	ah,ah	
	mov	bx,[OSEKeyBX]
	mov	TBX,bx			; return to users BX register
	mov	cx,[OSEKeyCX]
oseout:
	ret
osefun	endp

	page

IsMaxHandle proc	near
	push	ax
	mov	ax,[maxhandles]
	cmp	dx,ax
	pop	ax
	ret
IsMaxHandle endp


SegToPage proc	near
	push	cx
	push	si

	mov	cl,[map_area]
	xor	ch,ch	
	xor	si,si
LpSeg17:
	cmp	ax,[map_segments+si]
	je	LpSegOut
	inc	si
	inc	si
	loop	LpSeg17
	mov	al,-1		      ; force error
	jmp	short SPSkip
LpSegOut:
	mov	ax,si		
	shr	ax,1		       ; /2 	
SPSkip:

	pop	si
	pop	cx
	ret
SegToPage endp


CheckMapArea proc	near
	     push	ax	
	     push	cx
	     push	si
	     mov	cl,[map_area]	
	     xor	ch,ch
	     xor	si,si		
CheckLoop:
	     cmp	ax,word ptr windmap[si]
	     je		FoundMapArea
	     add	si,2
	     loop	CheckLoop
	     jmp	short CheckExit
FoundMapArea:
	     mov	ax,si
	     shr	ax,1
	     call	unmapmem				
CheckExit:						     					
	     pop	si		
	     pop	cx
	     pop	ax	
	     ret	
CheckMapArea endp

EmsToLog proc	near
	 push	si
EmsLogLoop:
	 cmp	si,max_page
	 je	EmsLogOut	
	 shl	si,2
	 add	si,[bitoffset]
	 cmp	ax,word ptr ds:[si].linkptr
	 je	EmsLogfound
	 mov	si,word ptr ds:[si].link
	 jmp	short EmsLogLoop
EmsLogOut:
	 mov	ax,si	  
EmsLogFound:
	 pop	si
	 ret
EmsToLog endp
;
; Logical to EMS page
; Input:
;	AX = Logical Handle Page
;	DI = First Link for handle
; OutPut:
;	AX = EMS page (MAX_PAGE) if Not found
;

LogToEMS proc	near
	 push	di
LEMSLoop:
	 or	ax,ax			; first page
	 jz	LEMSExit
	 shl	di,2
	 add	di,[bitoffset]
	 cmp	word ptr [di].linkptr,-1
	 je	LEMSError
	 dec	ax
	 mov	di,word ptr [di].linkptr
	 jmp	short LEMSLoop
LEMSError:
	 sub	di,[bitoffset]
	 shr	di,2
	 dec	ax
	 jz	LEMSExit
	 mov	di,max_page
LEMSExit:
	 mov	ax,di			; return link
	 pop	di
	 ret
LogToEMS endp

;
; Input:
;	 DX: Logical Page
;	 DS:SI -> Handle structure
; Output:
;	 DX -> Physical Page
;
LogToPhy proc	near
	 push	ax
	 push	di

	 mov	ax,dx
	 mov	di,word ptr database[si].link
	 call	LogToEms
	 mov	dx,ax

	 pop	di
	 pop	ax
	 ret
LogToPhy endp

FindEnd	proc	near
        mov	bx, word ptr database[si].link       ; get start of link list
	mov	di,bx
	cmp	bx, max_page
	jae	FindExit1
	shl	bx,2
FindLoop:
	mov	di,bx
	add	bx,[bitoffset]
	cmp	word ptr [bx].linkptr,-1
	je	FindExit
	mov	bx,word ptr [bx].linkptr
	shl	bx,2
	jmp	short	FindLoop
FindExit:	
	sub	bx,[bitoffset]
	shr	bx,2
	shr	di,2
FindExit1:
	ret
FindEnd endp

ReShrink proc	near
	push	cx
	push	bx
;
;	shink memory allocation
;
	mov	cx,bx
	sub	cx,[ems_page]
;
;	for	CX entries delete the last entry
;
ShrinkLoop:
	call	FindEnd			; find end of allocation
	cmp	bx,word ptr database[si].link
	jne	ShrinkCont
	mov	word ptr database[si].link, max_page
ShrinkCont:	
	dec	word ptr database[si].pages
	inc	[pgsleft]
	push	cx
	push	ax
	mov	ax,bx
	call	CheckMapArea
	pop	ax
	shl	bx,2
	add	bx,[bitoffset]
        mov	byte ptr [bx].inuse, false   ; deallocate page
	shl	di,2
	add	di,[bitoffset]
        mov	word ptr [di].linkptr,-1	   ; reset link ptr (previous)
	pop	cx
	loop	ShrinkLoop

	xor	ah,ah			; indicate all ok	
	pop	bx
	pop	cx
	ret
ReShrink endp

ReRaise proc	near
	push	bx
	push	cx
	push	dx
	push	si
	push	di
;
;	increase memory allocation
;	
	mov	cx,[ems_page]
	sub	cx,bx
	call	FindEnd			; find end pointer
	xchg	si,di
;
;	For 	CX entries attempt to allocate new entry and
;		append to end of entries
;
RaiseLoop:
	push	cx
	push	si
	xor	si,si		      ; start at top
	mov	dx,max_page	
        call	getpage               ; get page
	pop	si
	cmp	dx,max_page
	je	RaiseSkip
	inc	word ptr database[di].pages
	dec	[pgsleft]
	cmp	si, max_page
	jne	NoMaxRaise
	mov	database[di].link,dx
	jmp	short maxfirst
NoMaxRaise:
	shl	si,2
	add	si,[bitoffset]
	mov	[si].linkptr,dx
maxfirst:
	mov	si,dx
	shl	si,2
	add	si,[bitoffset]
	mov	[si].linkptr,-1
	mov	si,dx

RaiseSkip:
	pop	cx
	loop	RaiseLoop
	xor	ah,ah
	cmp	dx,max_page
	jb	RaiseOk
	mov	ah,not_enough
RaiseOk:

	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	ret
ReRaise	endp

;
; UnRegister handler - this far call will be call by MOSRTASK, using
;		       the tcbunreg conventions, it will deallocate
;		       all EMS handles which are allocated by the task
;		       being removed.
;			

Unregister proc	far
	push	ax
	push	bx
	push	ds
	push	es

	cmp	[EMSGlobal],'Y'
	je	UnRegSkip
	mov	bx,word ptr ds:[TCBID]
	cmp	bx,-1
	je	UnRegSkip
	mov	ax,word ptr ds:[TCBEMSSEG]
	or	ax,ax
	jz	UnRegSkip
;
;	Free up extended memory used by task for EMS
;
	push	cx
	mov	es,ax
	assume  es:EMS40seg,ds:nothing
	mov	bx,[addrbase]		; get base addr	
	mov	cx,[pgsavail]
	mov	[pgsavail],0
	shl	cx,2			; convert 16k pages to 4k pages
	mov	ah,2
        call	dword ptr cs:[mroutine] ; call memory management
	pop	cx

	cmp	word ptr [TaskUnreg+2],0
	je	UnRegSkip1
	push	es
	call	dword ptr [TaskUnreg]
	pop	es
UnRegSkip1:
;
;	Now we must deallocate SMP entry
;
	mov	ax,0a01h
	int	0d4h
UnregSkip:
 	 pop	es
	 pop	ds
	 pop	bx
	 pop	ax
	 retf	
Unregister endp

assume  ds:EMS40Seg,es:nothing

;--------------------------------------------------------------------
; GetEntry - compute entry offset
;	DX = handle
;   returns
;	SI = offset of entry
;---------------------------------------------------------------------

getentry proc	near
	push	ax
	mov	al,hand_len		; get lenght of hand structures
	mul	dl			; multible by handle
	mov	si,ax			; to return handle offset
	pop	ax
	ret
getentry endp
	
;----------------------------------------------------------------------
; 	ClearName - clear name field in structure
;		    SI offset into database structure
;	Note: This procedure also resets save table for function 8 and 9
;----------------------------------------------------------------------

ClearName proc	near
	push	ax
	push	cx
	push	di
	push	es

	mov	di,ds
	mov	es,di
	lea	di,database[si].hname
	mov	cx,4
	xor	ax,ax
	rep	stosw
	lea	di,database[si].hsavemap
	mov	cx,4
	mov	ax,-1
	rep	stosw
	
	pop	es
	pop	di
	pop	cx
	pop	ax
	ret
ClearName endp

;--------------------------------------------------------------------
; Get Handle from Segment Value
; Input:  BX = Segment
; 	  BX = Handle
;	  AL = page
;  Carry means error, segment not in list
;---------------------------------------------------------------------

SegToHand proc	near
	push	cx
	push	si

	mov	cl,[map_area]
	xor	ch,ch
	xor	al,al
	xor	si,si
SHandLP:
	cmp	bx,[map_segments+si]
	je	SHandDone
	inc	al
	inc	si
	inc	si
	loop	SHAndLP
	mov	ah,phys_range
	stc				; indicate error
	jmp	short SHandEnd
SHandDone:
;
;	We have valid segment, so derive handle
;
	mov	bx,[windmap+si]
	clc
			
SHandEnd:
	pop	si
	pop	cx
	ret
SegToHand endp



         page
;---------------------------------------------------------------------
;  getpage - get the next page available for system
;        ds must point code segment
;---------------------------------------------------------------------

getpage  proc  near
	 add	si,[bitoffset]
gploop:
         cmp	byte ptr [si].inuse, false  ; unallocated
         je	gpfound                ; ok..we got it
         add	si, bmap_len           ; update pointer
	 push	si
	 sub	si,[bitoffset]
	 shr	si,2			; assume bmap_len=4	 
         cmp	si, [pgsavail]		; at end of list?? never...
	 pop	si
         jb	gploop                 ; no....repeat
         mov	dx, max_page           ; indicates abort
         ret

gpfound:
         mov	byte ptr [si].inuse, true  ; allocated it
	 mov	dx,bp
         mov	byte ptr [si].assign, dl   ; set handle assigment
	 sub	si,[BitOffset]
         mov	dx, si                 ; get loop position
         shr	dx, 2                  ; divide by four (only for bmap_len=4)
         ret

getpage  endp

;---------------------------------------------------------------------
; setport -  set gizdrive memory allocation for a port
;---------------------------------------------------------------------

setport  proc  near
         push	ax
         push	cx
         push	dx
         push	si
         push	di
         xor	si, si
         mov	cl, map_area
	 xor	ch,ch
         xor	al, al

setloop:
         mov	dx, word ptr cs:windmap[si]  ; get page for page map
         inc	si
         inc	si                    ; by 2 ....
	 cmp	dx,max_page
	 jae	dounmap
         call	getmem                ; get memory area
	 jmp	short setcont
dounmap:
  	 call	unmapmem	      ; un map memory area	
setcont:
         inc	al
         loop	setloop               ; loop until done

         pop	di
         pop	si
         pop	dx
         pop	cx
         pop	ax
         ret
setport  endp


;---------------------------------------------------------------------
; getarray - get current page array
;            array will be stored at es:di
;---------------------------------------------------------------------

getarray proc  near
         push	di
         push	si
         push	cx
         push	ds

	 mov	cx, cs
	 mov	ds, cx
         mov	cl, map_area     ; there are four pages registers
	 xor	ch,ch
	 xor	ah,ah
         mov	si, offset windmap
         rep	movsw         ; move bytes

         pop	ds
         pop	cx
         pop	si
         pop	di
         ret
getarray endp

;---------------------------------------------------------------------
; savarray - save current page array
;            array come from ds:si
;---------------------------------------------------------------------

savarray proc  near
         push	di
         push	si
         push	cx
         push	es

	 mov	cx, cs
	 mov	es, cx
         mov	cl, map_area  ; there are four pages registers
	 xor	ch,ch
         mov	di, offset windmap
         rep	movsw         ; move bytes

         pop	es
         pop	cx
         pop	si
         pop	di
         ret
savarray endp

;----------------------------------------------------------------
; UNMAPMEM - unmap 16k page at window page w
;            al = window page  w
;----------------------------------------------------------------		

unmapmem proc  near
         push	ax
         push	bx
         push	cx
         push	es

         xor	ah, ah
         shl	al, 1                   ; multi by 4 (16k offsets)
	 mov	bx,ax
	 mov	word ptr WindMap[bx],max_page
         shl	al, 1
         add	al, byte ptr cs:[address]        ; get window segment
         xchg   ah, al
         mov	es, ax
         mov	cx, 4                   ; unmap 4 4k pages 16k
         mov	ah, 4
         call	dword ptr cs:[mroutine] ; call memory management
	 

         pop	es
         pop	cx
         pop	bx
         pop	ax
         ret
unmapmem endp


;---------------------------------------------------------------------
;  getmem  - transfer 16k of ems page  p   to window page  w
;            al = window page  w
;            dx = ems page     p
;---------------------------------------------------------------------

getmem   proc  near
         push	ax
         push	bx
         push	cx
         push	es

         xor	ah, ah
         shl	al, 1                   ; multi by 4 (16k offsets)
	 mov	bx,ax
	 mov	word ptr cs:WindMap[bx],dx
         shl	al, 1
         add	al, byte ptr cs:[address]        ; get window segment
         xchg  	ah, al
         mov	es, ax
         mov	bx, dx                  ; get page
         shl	bx, 2                   ; multi by 4 to get
         add	bx, cs:[baseaddr]       ; add base address of extended memory
         mov	cx, 4                   ; map 4 4k pages 16k
         mov	ah, 3
	 cmp	dx,max_page
	 jb	getmem1			
	 inc	ah			; if not in list, unmap
getmem1:
         call	dword ptr cs:[mroutine] ; call memory management

         pop	es
         pop	cx
         pop	bx
         pop	ax
         ret
getmem   endp


GetEMSSeg proc	near
	  push	ax	
	  push	bx
	  push	es

	  les	bx,cs:[ScbPtr]
	  mov	ax,word ptr es:[bx+SCBTCBPC]
	  cmp	[EMSGlobal],'Y'
	  jne	GetGlobal
	  mov	ax,word ptr es:[bx+SCBTCBPF]	  
GetGlobal:
	  mov	es,ax
	  mov	ax,es:[TCBEMSSEG]
	  mov	ds,ax
	  or	ax,ax
	  jz	ErrEMSseg
	  assume  ds:EMS40Seg
	  mov	ax,[addrbase]
	  mov	cs:[baseaddr],ax		; get base address for board
	  assume ds:nothing
	  call  InitEMS				; init EMS if necessary
	  clc
	  jmp   short ContEMSseg
ErrEMSSeg:
	  stc
ContEMSSeg:

	  pop	es		
	  pop	bx
	  pop	ax   
	  ret	
GetEMSSeg endp

	  assume  ds:EMS40Seg
InitEMS	  proc	near
          cmp	byte ptr [EMSTag],'E'		; has it been inited yet
	  jne	InitEMSCont
	  ret	  
InitEMSCont:
	  cmp	cs:[function],04eh		; mapping calls from kernel
	  jne	InitEMSCont2
	  ret
InitEMSCont2:
	  push	bx
	  push	cx
	  push	si
	  push	es

	  mov   [handles],1				; only system handle
	  mov	ax,[pgsavail]
	  mov	[pgsleft],ax				; 
	  mov	[TaskAltReg],0
	  mov	[TaskAltReg+2],0
	  mov	[OSEEnable],'Y'				; OSE enabled
	  mov	[OSEKeyBX],-1				; OSE Key BX not set
	  mov	[OSEKeyCX],-1				; OSE Key CX not set
	  mov	[syserror],0				; No System Error
;
	  mov	cx,[maxhandles]
	  xor	si,si
InitLp1:
	  mov	database[si].alloc,false
	  mov	database[si].pages,0
	  mov	database[si].link,max_page
	  mov	word ptr database[si].hsavemap,-1
	  mov	word ptr database[si+2].hsavemap,-1
	  mov	word ptr database[si+4].hsavemap,-1
	  mov	word ptr database[si+6].hsavemap,-1
	  mov	word ptr database[si].hname,0
	  mov	word ptr database[si+2].hname,0
	  mov	word ptr database[si+4].hname,0
	  mov	word ptr database[si+6].hname,0
	  add	si,hand_len
	  loop	InitLp1
;
	  mov	cx,pgsavail
	  xor	ax,ax
	  mov	si,[bitoffset]
InitLp2:
	  mov	word ptr [si],ax
	  mov	word ptr [si+2],-1
	  add	si,bmap_len
	  loop	InitLp2		  
;
	  mov	byte ptr database[0].alloc,TRUE		; Handle 0 (system)
;
;  we must set Unregister handler to our handler
;	  
	  mov	ah,4
	  mov	bx,-1
	  int	0d4h
	  mov	ax,word ptr es:[TCBUNREG]
	  mov	word ptr [TaskUnReg],ax			
	  mov	ax,word ptr es:[TCBUNREG+2]
	  mov	word ptr [TaskUnReg+2],ax			

	  cli
	  mov	word ptr es:[TCBUNREG],offset unregister
	  mov	word ptr es:[TCBUNREG+2],cs
	  mov	word ptr EmsContext[0],max_page
	  mov	word ptr EmsContext[2],max_page
	  mov	word ptr EmsContext[4],max_page
	  mov	word ptr EmsContext[6],max_page
	  mov	byte ptr [EMSTag],'E'
	  sti

	  pop	es
	  pop	si
	  pop	cx
	  pop	bx	
	  ret
InitEMS   endp
	  assume  ds:nothing

;------------- EMS Context Save and Restore Routines -------------------

; Special Notes: These routines are call from MOSCNTXT to save and 
; restore context of EMS task. These routines have been optimized for
; fastest speed and mimimiz calls to memory manager if necessary.  If
; EMS is not include for task, These routine will unmap EMS base address
; area.
;

; Context Same Routine 
;
; ES -> TCB
;
; If TCBEMSSEG is not zero
;     save Current Context into tasks save area

EmsSave	proc	far
	pushf
	cli
	push	ax
	push	si
	
	cmp	word ptr es:[TCBEMSSEG],0
	je 	SkipSave
	push	cx
	push	ds
	mov	cl,cs:[map_area]
	xor	ch,ch
	xor	si,si
	mov	ax,word ptr es:[TCBEMSSEG]
	mov	ds,ax
	assume  ds:EMS40Seg
ESaveLoop:
	mov	ax,word ptr cs:WindMap[si]
	mov	word ptr EMSContext[si],ax
	inc	si
	inc	si
	loop	ESaveLoop
	pop	ds
	pop	cx
	assume  ds:nothing
SkipSave:
	xor	si,si
	xor	al,al
SaveMapLoop:
	cmp	word ptr cs:WindMap[si],max_page
	je	SkipSaveMap
	call	unmapmem
SkipSaveMap:
	inc	al
	inc	si
	inc	si
	cmp	al,cs:[map_area]
	jb	SaveMapLoop
	pop	si
	pop	ax
GSkipSave:
;
; Pass on to next context save routine
;
	cmp	word ptr cs:[OldSave+2],0
	je	PassSave
	call	dword ptr cs:[OldSave]
PassSave:
	popf
	ret
EmsSave endp

;
; Context Restore Routine 
;
; ES -> TCB
;
; if TCBEMSSEG is Not zero and EMSTAG is Enable
;	Restore context save in save table
;  else unmap all reqions which are map in
;


EmsRestore	proc	far
	pushf
	cli
	push	ax
	push	si
	xor	si,si
	mov	ax,es:[TCBEMSSEG]
	or	ax,ax
	je	EmsUnMap
	push	es
	mov	es,ax
	assume  es:EMS40Seg
	cmp	[EmsTag],'E'
	je	EmsMapIn
	pop	es
EmsUnMap:
	xor	al,al
UnMapLoop:
	cmp	word ptr cs:WindMap[si],max_page
	je	UnMapSkip
	call	unmapmem
UnMapSkip:
	inc	al
	inc	si
	inc	si
	cmp	al,cs:[map_area]
	jb	UnMapLoop
	jmp	short EMSRCont
;
;	The following logic is use to map in items from EMS save table
;
EmsMapIn:
	xor	al,al
	push	dx
	push	cs:[baseaddr]
	mov	dx,AddrBase
	mov	cs:[BaseAddr],dx
MapInLoop:
	mov	dx,word ptr EmsContext[si]
	cmp	dx,word ptr cs:WindMap[si]
	je	DoMapIn
	cmp	dx,max_page
	je	MapInSkip
DoMapIn:
	call	getmem			; note getmem will unmap if necessary
MapInSkip:
	inc	al
	inc	si
	inc	si
	cmp	al,cs:[map_area]
	jb	MapInLoop	
	pop	cs:[BaseAddr]
	pop	dx
	pop	es			
EmsRCont:
	pop	si
	pop	ax
SKipRestore:
;
;	Pass on	to next context restore routine
;
	cmp	word ptr cs:[OldRestore+2],0
	je	PassRestore
	call	dword ptr cs:[OldRestore]
PassRestore:
	popf
	ret
EmsRestore endp


progend  label byte                  ; end of retained code

         page
mpage	 db	' 4 EMS Pages installed with Work Area at $         ' ;@@XLAT  
work     db    'E0000H'
         db	13,10,'$'


message  db	'PC-MOS LIM 4.0 Expanded Memory Driver v5.02 (920814) $          ' ;@@xlat
pagesnins db	'not installed         ',13,10,'$'	       ;@@XLAT	
pagesins  db	'installed         ',13,10,'$' 		;@@xlat

global	  db	'Global EMS Memory Installed.',13,10,'$'     ;@@XLAT

gizdrive  db	'Memory management required for MOS EMS driver!       ',13,10,'$' ;@@xlat

badaddr  db    'Invalid work area specified!        ',13,10,'$' ;@@xlat

errfreemem DB  'Work address conflicts with freemem!      ',13,10,'$'    ;@@xlat
errbadvid  db  'VGA/EGA master console detected!         ',13,10,'$'
errbadvtype db 'VTYPE Fill option specified!          ',13,10,'$'
errnoa000  db  'Work address at A000h not allowed on this machine!      ',13,10,'$'    ;@@XLAT

errmos	db	'Requires PC-MOS Version 4.10 or Higher!       ',13,10,'$'	;@@XLAT
errsmp  db	'This driver must be loaded globally                ',13,10,'$' ;@@XLAT

oldint67 dd    0                     ; saves old vector

memdev   db    '$$MEMDEV', 0

temp     db    '    '

ten      dw    10                    ; constant
memptr   dd    0
Mos_Version dw	0 		      ; MOS Version

FreeBuff db	3*16 dup ('N'), 8 dup ('N')

GetIndex proc	near
	sub	ax,0c000h
	mov	al,ah
	xor	ah,ah
	mov	bx,ax
	ret
GetIndex endp

InitBuff proc	near
	push	ds
	push	es
	mov	ah,2
	int	0d4h
	mov	word ptr [ScbPtr],bx
	mov	word ptr [ScbPtr+2],es
	push	es
	pop	ds
	lea	si,[bx+04cdh-240h]
	mov	cx,5
IBuffLoop:
	lodsw	
	or	ax,ax
	jz	IBuffEnd
	push	cx
	call	GetIndex
	push	bx
	lodsw
	call	GetIndex
	mov	cx,bx
	pop	bx
	sub	cx,bx
IBuffLoop2:
	mov	byte ptr cs:FreeBuff[bx],'Y'
	inc	bx
	loop	IBuffLoop2			
	pop	cx
	loop	IBuffLoop
IBuffEnd:
	pop	es
	pop	ds
	ret	
InitBuff endp


CheckMOS proc	near
	 mov	ax,3000h
	 mov	bx,ax
	 mov	cx,ax
	 mov	dx,ax
	 int	21h
	 push	ax
	 mov	ax,30ffh
	 int	21h
	 pop	bx
	 cmp	ax,bx
	 je	BadMos
	 xchg	bl,bh		
	 cmp	bx,040ah
	 jb	BadMos
	 mov	[Mos_Version],bx
	 mov	dx,cs
	 mov	ah,25h
	 int	0d4h
	 or	ax,ax
	 jz	BadSmp
	 clc		 
	 ret
BadSmp:
	 mov	dx,offset errsmp
	 stc
	 ret
BadMos:
	 mov	dx,offset errmos
	 stc
	 ret	 
CheckMOS endp

InstallContext proc	near
	       cmp	[EMSGlobal],'Y'
	       jne	DoInstallContext
		ret
DoInstallContext:
	       push	es	
	       push	ds
	       push	si

	       	
	       lds	si,[ScbPtr]
	       cmp	cs:[Mos_Version],040ah
	       jne	DoNewKernel		
	       mov	ax,ds:[si+SCBMOSADR]
	       mov	es,ax
	       cmp	word ptr es:[CHKPATCH],CHKVALUE
	       jne	DoNewKernel
;
; Handle shiping 410 code here
;
		push	di
	 	cld
		mov	di,SAVEPATCH
		mov	al,FARCALL
		cli
		stosb			
		mov	ax,offset EmsSave
		stosw
		mov	ax,cs
		stosw
		mov	ax,SAVEJMP
		stosw					
		mov	di,RESTPATCH
		mov	al,FARCALL
		stosb			
		mov	ax,offset EmsRestore
		stosw
		mov	ax,cs
		stosw
		mov	ax,RESTJMP
		stosw					
		sti
		pop	di
		jmp	short InstallDone

;
; Handle code later than shipping kernel here
;

DoNewKernel:
	       mov	ax,word ptr ds:[si+SCBSAVE]
	       mov	word ptr cs:[OldSave],ax						
	       mov	ax,word ptr ds:[si+SCBSAVE+2]
	       mov	word ptr cs:[OldSave+2],ax						
	       mov	ax,word ptr ds:[si+SCBRESTORE]
	       mov	word ptr cs:[OldRestore],ax						
	       mov	ax,word ptr ds:[si+SCBRESTORE+2]
	       mov	word ptr cs:[OldRestore+2],ax						

	       cli
	       mov	word ptr ds:[si+SCBSAVE],offset EmsSave
	       mov	word ptr ds:[si+SCBSAVE+2],cs
	       mov	word ptr ds:[si+SCBRESTORE],offset EmsRestore
	       mov	word ptr ds:[si+SCBRESTORE+2],cs				
	       sti	
InstallDone:
	       pop	si
	       pop	ds
	       pop	es			
	       ret	
InstallContext endp

;
;	AX = Start Segment 
;	CL = Number of Banks
;

CheckBuff proc	near
	  cmp	ax,0c000h
	  jb	CBuffErr
	  cmp	ax,0f000h
	  jae	CbuffOk
	  call	GetIndex
CBuffLoop:
	  cmp	byte ptr FreeBuff[bx],'N'
	  jne	CBuffErr
	  inc	bx
	  loop	CbuffLoop
CBuffOk:
	  clc
	  ret
CBuffErr:
	  stc
	  ret
CheckBuff endp

CheckA000 proc	near
	  push	ax
	  push	bx
	  push	es
;
; first we must valid tcbstation to make sure video is not ega or vga
;
	  mov	ah,4
	  xor	bx,bx
	  int	0d4h
	  mov	al,es:[TCBSTATION]
	  cmp	al,2		
	  jb	CA000step1		; ok if mono or CGA
	  mov	dx,offset errbadvid
	  cmp	al,4
	  jne	CA000Bad		; ok if hercules
CA000step1:
	  mov	ah,2
	  int	0d4h	 
	  mov	al,es:[bx+SCBVTYPE]	; get vtype
	  mov	dx,offset errbadvtype
	  test	al,80h			; test for fill option
	  jnz	CA000Bad 

   	  clc		       		; all ok ....
	  jmp	short CA000Exit		  
CA000Bad:
	  stc
CA000Exit:
	  pop	es
	  pop	bx
	  pop	ax
	  ret
CheckA000 endp


CheckGlob   proc  near
	 cmp	byte ptr es:[bx],'/'
	 je	CGlob
	 cmp	byte ptr es:[bx],0dh
	 je	CGRet 
	 inc	bx
	 jmp	short	CheckGlob
CGRet:
	 ret	
CGlob:
	inc	bx
	mov	al,byte ptr es:[bx]
	and	al,0dfh
	cmp	al,'G'
	jne	CheckGlob
	mov	word ptr es:[bx-2],2020h
	mov	cs:[EMSGlobal],'Y'
	ret
CheckGLob   endp


CheckPFrame proc  near
	    cmp	  byte ptr es:[bx],'/'
	    je	  CPFrame
	    cmp	  byte ptr es:[bx],0dh
	    je	  CPRet 
	    inc	  bx
	    jmp	short	checkPFrame
CPRet:	
	    ret
CPFrame:
	    push  si
	    push  cx
	    
	    mov	  si,bx
	    mov	  cx,1
	    xor	  ah,ah
CPLoop:
	    inc	  bx
	    mov	  al,byte ptr es:[bx]
	    cmp	  al,'0'
	    jb	  Cpdone
	    cmp	  al,'9'
	    ja	  CPdone
	    inc	  cx
	    sub	  al,'0'
	    or    ah,ah
	    jnz	  Cpnext
	    mov	  ah,al
	    jmp	short  CPloop
Cpnext:
	    cmp	  ah,1
	    ja	  Cperror
	    mov	  ah,10
	    add	  ah,al
Cpdone:
	    cmp	  ah,4
	    jb	  Cperror
	    cmp	  ah,12
	    ja	  Cperror
	    mov	  [map_area],ah	    
Cperror:
	    mov	  byte ptr es:[si],' '
	    inc	  si
	    loop  Cperror
	    pop	  si
	    pop	  cx
	    jmp	  CheckPFrame
CheckPFrame endp	    

         page
;--------------------------------------------------------------------
;             initialization code - discarded later
;--------------------------------------------------------------------

init     label near

         mov	word ptr es:[bx+14],offset progend
         mov	word ptr es:[bx+16],cs


	 call	CheckMOS
	 jnc	InitMosOk
	 push	dx
	 mov	dx,offset message
	 mov	ah,9
	 int	21h
	 mov	dx,offset pagesnins
	 mov	ah,9
	 int	21h
         pop	dx
	 mov	ah,9
	 int	21h
	 mov	word ptr [devname],'\\'	  ; so it can't be open
	 jmp	donestat
InitMosOk:
	 

;---------------------- replace int 67h vector ----------------------

         mov	es,[zero]
         mov	ax,es:[019ch]         ; save original vector
         mov	word ptr [oldint67],ax
         mov	ax,es:[019eh]
         mov	word ptr [oldint67+2],ax

         mov	word ptr es:[019ch],offset entint67
         mov	es:[019eh],cs

;-------------------- locate memory device driver ------------------

         mov	dx, offset memdev
         mov	ax,3d02h
         int	21h
         jnc	lmem1
         mov	bp, 0
         jmp	finish

lmem1:
         mov	bx,ax
         mov	ax, 4400h
         int	21h
         xor	dh, dh
         or	dl, 20h             ; binary mode
         mov	ax, 4401h
         int	21h
         mov	ax, 3f00h
         mov	cx, 4
         mov	dx,offset memptr
         int	21h
         mov	ah, 3eh
         int	21h
         push	es
         les	bx,memptr
         mov	ax, es:[bx+2]
         mov	word ptr [mroutine+2], ax
         mov	ax, es:[bx]
         mov	word ptr [mroutine], ax
         pop	es
         mov	bp, 1                   ; mem-man found

;-------------------- get command parameter ------------------------

         les	bx,dword ptr [rhoff]
         les	bx,dword ptr es:[bx + 18]  ; get parameter pointer

	 push	bx
	 call	CheckGlob		; check for global ems memory
	 pop	bx
	 push	bx
	 call	CheckPFrame
	 pop	bx
	 
scan1:
         inc	bx
         mov	al,es:[bx]            ; scan for blank
         cmp	al, 0dh
         jne	scan1a
         jmp	scandone              ; return terminates

scan1a:
         cmp	al, 20h
         jne	scan1                 ; repeat until blank

scan2:
         inc	bx
         cmp	byte ptr es:[bx],20h  ; scan for non-blank
         je	scan2
	 cmp	byte ptr es:[bx],0dh
	 je	ddsbad		     ; use defaults	
         xor	dx, dx               ; zero work address
         xor	cx, cx
         xor	ah, ah
         mov	di, offset work

ddsloop5:
         mov	al, byte ptr es:[bx]  ; get hex value
         inc	bx
         cmp	al, '0'
         jb	ddschk
         cmp	al, '9'
         ja	ddshex
         sub	al,'0'
         jmp	short ddsnext

ddshex:
         cmp	al,'a'
         jb	ddshex2
         cmp	al,'f'
         ja	ddschk
         sub	al,'a'-10
         jmp	short ddsnext

ddshex2:
         cmp	al,'A'
         jb	ddschk
         cmp	al,'F'
         ja	ddschk
         sub	al,'A'-10

ddsnext:                                ; adjust value
         shl	dx, 4
         add	dx, ax
         cmp	al, 10
         jb	ddslow
         add	al, 'A'-10
         jmp	short ddsout

ddslow:
         add	al, '0'

ddsout:
         mov	[di], al
         inc	di
         inc	cx
         cmp	cx, 4
         jb	ddsloop5

ddschk:
         cmp	cx, 4                    ; for bytes
         jne	ddsbad
         mov	ax, dx                   ; check for 4k bondary
         and	ax, 0fc00h
         cmp	ax, dx
         je	ddsgood
         mov	ah, 9                    ; display error message
         mov	dx, offset [message]
         int	21h
	 mov	dx,offset [pagesnins]
	 mov	ah,9
   	 int	21h
         mov	dx, offset [badaddr]
         int	21h
         jmp	donestat

ddsgood:
         mov	[address], dh            ; save value
         jmp	short scandone

ddsbad:
         mov	word ptr [work], '0E'
         mov	word ptr [work+2], '00'

scandone:
         page
;------------------------ write copyright notice --------------------

finish:
	 call	InitBuff
         mov	ah,9
         mov	dx,offset [message]
         int	21h
	 mov	ah,cs:[address]
	 cmp	ah,0a0h				; is this A000
	 jne	nota000
	 call	CheckA000			; verify that A000 is valid
	 jnc	freememok
	 push	dx
	 mov	dx,offset [pagesnins]
	 mov	ah,9
	 int	21h
	 pop	dx
	 mov	ah,9
	 int	21h
	 mov	dx,offset [errnoa000]
	 mov	ah,9
	 int	21h
	 jmp	short FError
nota000:
	 xor	al,al
	 mov	cl,cs:[map_area]
	 xor	ch,ch
	 shl	cx,2
	 call	CheckBuff
	 jnc	freememok
freemembad:
	 mov	dx,offset [pagesnins]
	 mov	ah,9
	 int	21h
	 mov	dx,offset [errfreemem]
	 mov	ah,9
	 int	21h
FError:
	 mov	word ptr [devname],'\\'	  ; so it can't be open

	 mov	es,[zero]
	 mov	ax,word ptr [oldint67]	  ; replace vectors so context doesn'T
	 mov	es:[19ch],ax	          ; crash
	 mov	ax,word ptr [oldint67+2]
	 mov	es:[19eh],ax
         jmp	donestat
Freememok:
;
; 	Initialialize map_segments values
;
	 mov	cl,cs:[map_area]
	 xor	ch,ch
	 mov	ah,[address]
	 xor	al,al
	 xor	bx,bx
msegloop:
	 mov	cs:[map_segments+bx],ax
	 inc	bx
	 inc	bx
	 add	ah,4		; point to next segment
	 loop	msegloop
;
         or	bp,bp                 ; memmanagement error
         jnz	memmanok
	 mov	es,[zero]
	 mov	ax,word ptr [oldint67]	  ; replace vectors so context doesn'T
	 mov	es:[19ch],ax	          ; crash
	 mov	ax,word ptr [oldint67+2]
	 mov	es:[19eh],ax
	 mov	dx,offset [pagesnins]
	 mov	ah,9
	 int	21h
	 mov	ah,9
         mov	dx,offset [gizdrive]
         int	21h
	 jmp	donestat

memmanok:
	 call	InstallContext		; Install Context Code
         mov	dx,offset [pagesins]
	 mov	ah,9
         int	21h
	 mov	al,byte ptr [map_area]
	 mov	dx,offset mpage+1
	 mov	si,dx
	 cmp	al,10
	 jb	memmanx
	 sub	al,10
	 mov	byte ptr cs:[si-1],'1'
	 dec	dx
memmanx:
	 add	al,'0'
	 mov	byte ptr cs:[si],al
	 mov	ah,9
	 int	21h
	 mov	dx,offset work
	 mov	ah,9
	 int	21h
	 cmp	[EMSGlobal],'Y'
	 jne	memxglob
	 mov	dx,offset global
	 mov	ah,9
	 int	21h
memxglob:
         jmp	donestat				; is always allocated



         if1
                %out    pass 1  completed.
         else
                %out    pass 2  completed.
         endif


mainseg  ends
         end   begin
