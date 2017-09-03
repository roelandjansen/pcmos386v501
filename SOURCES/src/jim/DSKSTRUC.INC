comment ^==============================================================

; NOTE: when you make changes to this module, make parallel 
; changes to dskstruc.inc.

=======================================================================

mjs 12/16/91	dlg mods: created this module.

mjs 03/03/92	added the mgrec structure for msys/m.

======================================================================^


;======================================================================
; structure of data within a boot sector, including the 
; extended boot record fields

brec struc
 btJump			db	3 dup(?)  ; jmp instruction
 btOemName		db	8 dup(?)  ; oem name
;==== start of BPB
 btBytesPerSec		dw	?	  ; bytes per sector
 btSecPerClust		db	?	  ; sectors per cluster
 btResSectors		dw	?	  ; # of reserved sectors
 btFATs			db	?	  ; # of FAT tables
 btRootDirEnts		dw	?	  ; # of root directory entries
 btSectors		dw	?	  ; total # of sectors
 btMedia		db	?	  ; media descriptor
 btFATsecs		dw	?	  ; # of sectors per FAT
 btSecPerTrack		dw	?	  ; # of sectors per track
 btHeads		dw	?	  ; # of heads
 btHiddenSecs		dd	?	  ; # of hidden sectors
 btHugeSectors		dd	?	  ; # of sectors when btSectors == 0
;==== end of BPB 
 btDriveNumber		db	?	  ; drive number
 btReserved1		db	?	  ; reserved
 btBootSignature	db	?	  ; extended PBR signature (29h)
 btVolumeID		dd	?	  ; volume id number
 btVolumeLabel		db	11 dup(?) ; volume label
 btFileSysType		db	8 dup(?)  ; file-system type
brec ends


;======================================================================
; structure of data within a bpb, including the 
; extended boot record fields
;
; NOTE: the bsJump and bsOemName fields are purposely left out of
; this structure.  the addressability of this structure starts with
; the bpb information.

bpb struc
;==== start of BPB
 bsBytesPerSec		dw	?	  ; bytes per sector
 bsSecPerClust		db	?	  ; sectors per cluster
 bsResSectors		dw	?	  ; # of reserved sectors
 bsFATs			db	?	  ; # of FAT tables
 bsRootDirEnts		dw	?	  ; # of root directory entries
 bsSectors		dw	?	  ; total # of sectors
 bsMedia		db	?	  ; media descriptor
 bsFATsecs		dw	?	  ; # of sectors per FAT
 bsSecPerTrack		dw	?	  ; # of sectors per track
 bsHeads		dw	?	  ; # of heads
 bsHiddenSecs		dd	?	  ; # of hidden sectors
 bsHugeSectors		dd	?	  ; # of sectors when bsSectors == 0
;==== end of BPB 
 bsDriveNumber		db	?	  ; drive number
 bsReserved1		db	?	  ; reserved
 bsBootSignature	db	?	  ; extended PBR signature (29h)
 bsVolumeID		dd	?	  ; volume id number
 bsVolumeLabel		db	11 dup(?) ; volume label
 bsFileSysType		db	8 dup(?)  ; file-system type
bpb ends


;======================================================================
; structure of data within an mlg boot sector

mlgrec struc
;==== start of BPB
 mlBytesPerSec		dw	?	  ; bytes per sector
 mlSecPerClust		db	?	  ; sectors per cluster
 mlResSectors		dw	?	  ; # of reserved sectors
 mlFATs			db	?	  ; # of FAT tables
 mlRootDirEnts		dw	?	  ; # of root directory entries
 mlSectors		dw	?	  ; total # of sectors
 mlMedia		db	?	  ; media descriptor
 mlFATsecs		db	?	  ; # of sectors per FAT
 mlSectorsHi		db	?	  ; high byte of 24 bit sector count
 mlSecPerTrack		dw	?	  ; # of sectors per track
 mlHeads		dw	?	  ; # of heads
 mlHiddenSecs		dw	?	  ; # of hidden sectors
 mlDrive		db	?	  ; placeholder
 mlHiddenHi		db	?	  ; msb of hidden
;==== end of BPB 
mlgrec ends


;======================================================================
; structure of data within a partition table entry

pterec struc
 peBootable		db	?	; 80h = bootable, 0 = non
 peBeginHead		db	?	; beginning head
 peBeginSector		db	?	; beginning sector
 peBeginCylinder	db	?	; beginning cylinder
 peFileSystem		db	?	; name of file system
 peEndHead		db	?	; ending head
 peEndSector		db	?	; ending sector
 peEndCylinder		db	?	; ending cylinder
 peStartSector		dd	?	; starting sector (rel to beg of disk)
 peSectors		dd	?	; total sectors in partition
pterec ends


; values for the Partition Type Code

PTCnil  equ	0			; nada
PTCsm12 equ	1			; small partition, 12 bit fat
PTCsm16 equ	4			; small, 16 bit fat
PTCext  equ	5			; extended partition
PTCdlg	equ	6			; DLG partition


;======================================================================
; structure of data for the i21f44s0Ds40 and i21f44s0Ds60 ioctl calls

dprec struc
 dpSpecFunc		db	?	; special functions
 dpDevType		db	?	; device type
 dpDevAttr		dw	?	; device attributes
 dpCylinders		dw	?	; number of cylinders
 dpMediaType		db	?	; media type
;==== start of BPB
 dpBytesPerSec		dw	?	; bytes per sector
 dpSecPerClust		db	?	; sectors per cluster
 dpResSectors		dw	?	; # of reserved sectors
 dpFATs			db	?	; # of FAT tables
 dpRootDirEnts		dw	?	; # of root directory entries
 dpSectors		dw	?	; total # of sectors
 dpMedia		db	?	; media descriptor
 dpFATsecs		dw	?	; # of sectors per FAT
 dpSecPerTrack		dw	?	; # of sectors per track
 dpHeads		dw	?	; # of heads
 dpHiddenSecs		dd	?	; # of hidden sectors
 dpHugeSectors		dd	?	; # of sectors when bsSectors == 0
 dpResv			db	6 dup(?); reserved area
;==== end of BPB
 dpTracks		dw	?	; # of tracks in track table
 dpTrackTable		dw	?	; starting location of track table
dprec ends


;======================================================================
; structure of data for the i21f44s0Ds41 and i21f44s0Ds61 ioctl calls

rwrec struc
 rwSpecFunc		db	?	; special functions (must be 0)
 rwHead			dw	?	; head to read/write
 rwCylinder		dw	?	; cylinder to read/write
 rwFirstSector		dw	?	; first sector to read/write
 rwSectors		dw	?	; number of sectors to read/write
 rwBuffer		dd	?	; address of buffer
rwrec ends

;======================================================================
; structure of data for the i21f44s0Ds42 and i21f44s0Ds62 ioctl calls

fvblock struc
 fvSpecFunc		db	?	; special functions (must be 0)
 fvHead			dw	?	; head to format/verify
 fvCylinder		dw	?	; cylinder to format/verify
fvblock ends


;======================================================================
; structure of data within a dpb (drive parameter block)
; use with i21f32
; NOTE: this is for dos versions 4.00 and above

dpbrec struc
 dpbDrive		db	?	; drive # (0 = A, 1 = B, etc)
 dpbUnit		db	?	; unit # for driver
 dpbSectorSize		dw	?	; sector size, in bytes
 dpbClusterMask		db	?	; sectors per cluster - 1
 dpbClusterShift	db	?	; sectors per cluster, as power of 2
 dpbFirstFAT		dw	?	; first FAT sector
 dpbFATCount		db	?	; # of FATs
 dpbRootEntries		dw	?	; # of root directory entries
 dpbFirstSector		dw	?	; first sector of first cluster
 dpbMaxCluster		dw	?	; number of clusters + 1
 dpbFATSize		dw	?	; # of FAT sectors
 dpbDirSector		dw	?	; first sector of directory
 dpbDriverAddr		dd	?	; address of device driver
 dpbMedia		db	?	; media descriptor
 dpbFirstAccess		db	?	; indicates access to drive
 dpbNextDPB		dd	?	; address of next dpb
 dpbNextFree		dw	?	; last allocated cluster
 dpbFreeCnt		dw	?	; # of free clusters
dpbrec ends


;======================================================================
; structure of data for an int25/int26 parameter buffer
; use with dos 4.00 and above, and mos newer than 4.10

diskio struc
 diStartSector		dd	?	; sector number to start
 diSectors		dw	?	; number of sectors
 diBuffer		dd	?	; address of buffer
diskio ends


;======================================================================
; structure of data for an extended fcb

extfcb struc
 extSignature		db	?	; should be ff
 extReserved1		db	5 dup(?)
 extAttribute		db	?	; attribute byte
 extDriveID		db	?	; 0=default, 1=a...
 extFileName		db	8 dup(?)
 extExtent		db	3 dup(?)
 extCurBlockNo		dw	?	; current block number
 extRecSize		dw	?	; record size
 extFileSize		dd	?	; bytes in file
 extFileDate		dw	?	; date last modified
 extFileTime		dw	?	; time last modified
 extReserved2		db	8 dup(?)
 extCurRecNo		db	?	; current record number
 extRandomRecNo		dd	?	; random record number
extfcb ends

;======================================================================
; structure of data for a directory entry

direntry struc
 deName			db	8 dup(?)
 deExtension		db	3 dup(?)
 deAttributes		db	?
 deReserved		db	10 dup(?)
 deTime			dw	?
 deDate			dw	?
 deStartCluster		dw	?
 deFileSize		dd	?
direntry ends


;======================================================================
; structure of part of the data within the dta after i21f11

extheader struc
 ehSignature		db	?
 ehReserved		db	5 dup(?)
 ehSearchAttrs		db	?
extheader ends


;======================================================================
; structure of data for a media id request (i21f44s0Ds66)

mid struc
 midInfoLevel		dw	?
 midSerialNum		dd	?
 midVolLabel		db	11 dup(?)
 midFileSysType		db	8 dup(?)
mid ends



;=============== device driver structures

;======================================================================
; structure of data for basic request (device driver)

ddheader struc
 dhLink			dd	?	; link to next driver
 dhAttributes		dw	?	; device attributes
 dhStrategy		dw	?	; offset of strategy function
 dhInterrupt		dw	?	; offset of interrupt function
 dhNameOrUnits		db	8 dup(?) ; logical device name (char)
					 ; number of units (block)
ddheader ends


;======================================================================
; structure of data for basic request (device driver)

basic_rq struc
 rhLength		db	?	; length of record, in bytes
 rhUnit			db	?	; unit number (block dev only)
 rhFunction		db	?	; function number
 rhStatus		dw	?	; return status word
 rhReserved		db	8 dup(?)
basic_rq ends


;======================================================================
; structure of data for init request (device driver)
; (driver command 00h)

init_rq struc
 irLength		db	?	; length of record, in bytes
 irUnit			db	?	; unit number (block dev only)
 irFunction		db	?	; function number
 irStatus		dw	?	; return status word
 irReserved		db	8 dup(?)
 irUnits		db	?	; in:  number of units
 irEndAddress		dd	?	; in:  end available driver memory
					; out: end resident code
 irParamAddress		dd	?	; in:  addr config.sys device= line
					; out: addr bpb pointer array
 irDriveNumber		db	?	; in:  first drive number
 irMessageFlag		dw	?	; out: error message flag
init_rq ends


;======================================================================
; structure of data for media request request (device driver)
; (driver command 01h)

media_rq struc
 mrLength		db	?	; length of record, in bytes
 mrUnit			db	?	; unit number (block dev only)
 mrFunction		db	?	; function number
 mrStatus		dw	?	; return status word
 mrReserved		db	8 dup(?)
 mrMediaID		db	?	; in:  current media descriptor
 mrReturn		db	?	; out: return value
 mrVolumeID		dd	?	; out: previous volume identifier
media_rq ends


;======================================================================
; structure of data for build bpb request (device driver)
; (driver command 02h)

buildbpb_rq struc
 bbrLength		db	?	; length of record, in bytes
 bbrUnit		db	?	; unit number (block dev only)
 bbrFunction		db	?	; function number
 bbrStatus		dw	?	; return status word
 bbrReserved		db	8 dup(?)
 bbrMediaID		db	?	; in:  current media descriptor
 bbrFATSector		dd	?	; in:  buffer with 1st FAT sector
 bbrBPBAddress		dd	?	; out: BPB address
buildbpb_rq ends


;======================================================================
; structure of data for ioctl read/write request (device driver)
; (driver command 03h and 0ch)

ioctlread_rq struc
 irwrLength		db	?	; length of record, in bytes
 irwrUnit		db	?	; unit number (block dev only)
 irwrFunction		db	?	; function number
 irwrStatus		dw	?	; return status word
 irwrReserved		db	8 dup(?)
 irwrData		db	?	; not used
 irwrBuffer		dd	?	; in:  buffer address
 irwrBytes		dw	?	; in:  # of bytes requested
					; out: # of bytes read
ioctlread_rq ends


;======================================================================
; structure of data for read/write request (device driver)
; (driver commands 04h, 08h and 09h)

readwrite_rq struc
 rwrLength		db  	?	; length of record, in bytes
 rwrUnit		db  	?	; unit number (block dev only)
 rwrFunction		db  	?	; function number
 rwrStatus		dw  	?	; return status word
 rwrReserved		db  	8 dup(?)
 rwrMediaID		db  	?	; in:  media descriptor
 rwrBuffer		dd  	?	; in:  buffer address
 rwrBytesSec		dw  	?	; in:  # of bytes/sectors to read
			    		; out: # of bytes/sectors read
 rwrStartSec		dw  	?	; in:  starting sector number
 rwrVolumeID		dd  	?	; out: volume identifier
 rwrHugeStartSec	dd  	?	; in:  32-bit starting sector #
readwrite_rq ends


;======================================================================
; structure of data for nondestructive read request (device driver)
; (driver command 05h)

nread_rq struc
 nrrLength		db	?	; length of record, in bytes
 nrrUnit		db	?	; unit number (block dev only)
 nrrFunction		db	?	; function number
 nrrStatus		dw	?	; return status word
 nrrReserved		db	8 dup(?)
 nrrChar		db	?	; out: character read from device
nread_rq ends


;======================================================================
; structure of data for input/output status request (device driver)
; (driver command 06h and 0ah)

status_rq struc
 srLength		db	?	; length of record, in bytes
 srUnit			db	?	; unit number (block dev only)
 srFunction		db	?	; function number
 srStatus		dw	?	; return status word
 srReserved		db	8 dup(?)
status_rq ends


;======================================================================
; structure of data for input/output flush request (device driver)
; (driver command 07h and 0bh)

flush_rq struc
 frLength		db	?	; length of record, in bytes
 frUnit			db	?	; unit number (block dev only)
 frFunction		db	?	; function number
 frStatus		dw	?	; return status word
 frReserved		db	8 dup(?)
flush_rq ends


;======================================================================
; structure of data for open/close request (device driver)
; (driver command 0dh and 0eh)

openclose_rq struc
 ocrLength		db	?	; length of record, in bytes
 ocrUnit		db	?	; unit number (block dev only)
 ocrFunction		db	?	; function number
 ocrStatus		dw	?	; return status word
 ocrReserved		db	8 dup(?)
openclose_rq ends


;======================================================================
; structure of data for removable media request (device driver)
; (driver command 0fh)

rmedia_rq struc
 rmrLength		db	?	; length of record, in bytes
 rmrUnit		db	?	; unit number (block dev only)
 rmrFunction		db	?	; function number
 rmrStatus		dw	?	; return status word
 rmrReserved		db	8 dup(?)
rmedia_rq ends


;======================================================================
; structure of data for output until busy request (device driver)
; (driver command 10h)

output_rq struc
 orLength		db	?	; length of record, in bytes
 orUnit			db	?	; unit number (block dev only)
 orFunction		db	?	; function number
 orStatus		dw	?	; return status word
 orReserved		db	8 dup(?)
 orData			db	?	; not used
 orBuffer		dd	?	; in:  buffer address
 orBytes		dw	?	; in:  # of bytes to write
					; out: # of bytes written
output_rq ends


;======================================================================
; structure of data for generic ioctl/ioctl query request (device driver)
; (driver command 13h and 19h)

ioctl_rq struc
 giLength		db	?	; length of record, in bytes
 giUnit			db	?	; unit number (block dev only)
 giFunction		db	?	; function number
 giStatus		dw	?	; return status word
 giReserved		db	8 dup(?)
 giCategory		db	?	; in:  device category
 giMinorCode		db	?	; in:  minor code
 giReserved2		dd	?
 giIOCTLData		dd	?	; in:  iocto data address
ioctl_rq ends


;======================================================================
; structure of data for get/set logical device request (device driver)
; (driver command 17h and 18h)

logdev_rq struc
 ldrLength		db	?	; length of record, in bytes
 ldrUnit		db	?	; in:  unit number for drive to check
					; out: active drive number
 ldrFunction		db	?	; function number
 ldrStatus		dw	?	; return status word
 ldrReserved		db	8 dup(?)
logdev_rq ends

