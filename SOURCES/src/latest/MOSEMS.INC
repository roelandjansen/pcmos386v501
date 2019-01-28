;---------------------------------------------------------------------
;
; MOSEMS.INC - EMS 4.0 Definition file
;
;--------------------------------------------------------------------- 

	 if    0 eq 0		; fake out public.com
REGION		equ	0
SOURCE_TYPE	equ	4
SOURCE_HANDLE	equ	5
SOURCE_OFFSET	equ	7
SOURCE_SEGPAGE	equ	9
DEST_TYPE	equ	11
DEST_HANDLE	equ	12
DEST_OFFSET	equ	14
DEST_SEGPAGE	equ	16

max_handle     	equ   255
max_page       	equ   512
ems_version    	equ   40h
map_size       	equ   4
MAX_MAP_SIZE    equ   12		; C0000-F0000 

soft_error     	equ   80h
no_hard        	equ   81h
bad_handle     	equ   83h
all_used       	equ   85h
not_enough     	equ   87h
not_zero       	equ   89h
logic_range    	equ   8ah
phys_range     	equ   8bh
savemap_saved   equ   8dh
no_savemap	equ   8eh
invalid_parm   	equ   8fh
no_attribute	equ   091h
page_exceed	equ   093h
conv_exp_overlap equ  094h
offset_bad	equ   095h
region_too_big	equ   096h
exch_overlap	equ   097h
unsource_dest	equ   098h
no_alternate	equ   09ah
not_supported   equ   09ch
regset0		equ   09dh
handle_notfound	equ   0a0h
null_name	equ   0a1h
meg1wrap	equ   0a2h
corrupted	equ   0a3h
access_denied	equ   0a4h		

bmap     struc
inuse    db    0	            ; indicates if inuse
assign   db    0                    ; indicates which handle owns it
linkptr  dw    0                    ; next link pointer
bmap     ends

bmap_len equ   4

hand     struc
alloc    db    0	             ; indicates if handle is allocated
pages    dw    0                    ; no pages allocate (1-512) if allocated
link     dw    max_page             ; page link pointer
hname	 db    8 dup (0)	    ; handle name	
hsavemap dw    4 dup (-1)	    ; save table for Function 8 and 9	
hand     ends

hand_len equ   21

tbp	equ	(word ptr [bp+4])
tds	equ	(word ptr [bp+2])
tbx	equ	(word ptr [bp])
	endif


;--------------------------------------------------------------------;
;								     ;
; EMS 4.0 Task Specific Data Structure			             ;
;--------------------------------------------------------------------;
;

EMS40Seg	segment at 01234h

EMSTag	        db    ?			; 'E' means that structure is inited
handles  	dw    1                 ; emm handle count (1 system handle)
maxhandles	dw    0			; max handles on system
pgsavail 	dw    0                 ; indicates total pages available on board
pgsleft  	dw    0          	; indicates pages unallocated
TaskAltReg	dw    0,0		; task Alternate register pointer
TaskUnReg	dd    0			; Task Unregister Handler
OSEEnable 	db    'Y'		; OSE is Enable
OSEKeyBX  	dw    -1		; -1 means key is not set
OSEKeyCX  	dw    -1		; -1 means key is not set
syserror 	db    0                 ; byte indicates latest syserror
addrbase	dw	0		; base address for task
EMSContext      dw    MAX_MAP_SIZE  dup (0) ; Context Save area
bitoffset	dw	0		; Offset to BitMap offset
					; this entry must be stored after
					; handle database
database	hand	<>		; offset of database entries  
					; This must be last entry

EMS40Seg	ends

