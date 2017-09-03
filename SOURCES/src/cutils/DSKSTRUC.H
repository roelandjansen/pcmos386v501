/*=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        dskstruc.h
 task name:          various modules
 creation date:      04/01/92
 revision date:      04/01/92
 author:             sah/mjs
 description:        disk structures

 NOTE: if you make corrections to this module, make parallel 
 changes to dskstruc.inc.

=======================================================================

mjs 04/01/92	created this module.

=====================================================================*/

/*
;======================================================================
; structure of data within a boot sector, including the 
; extended boot record fields
;
*/

struct brec {
 byte  btJump[3];		/* jmp instruction */
 byte  btOemName[8];		/* oem name */
/*==== start of BPB */
 word  btBytesPerSec;		/* bytes per sector */
 byte  btSecPerClust;		/* sectors per cluster */
 word  btResSectors;		/* # of reserved sectors */
 byte  btFATs;			/* # of FAT tables */
 word  btRootDirEnts;		/* # of root directory entries */
 word  btSectors;		/* total # of sectors */
 byte  btMedia;			/* media descriptor */
 word  btFATsecs;		/* # of sectors per FAT */
 word  btSecPerTrack;		/* # of sectors per track */
 word  btHeads;			/* # of heads */
 dword btHiddenSecs;		/* # of hidden sectors */
 dword btHugeSectors;		/* # of sectors when bsSectors == 0 */
/*==== end of BPB  */
 byte  btDriveNumber;		/* drive number */
 byte  btReserved1;		/* reserved */
 byte  btBootSignature;		/* extended PBR signature (29h) */
 dword btVolumeID;		/* volume id number */
 byte  btVolumeLabel[11];	/* volume label */
 byte  btFileSysType[8];	/* file-system type */
 };

typedef struct brec bt_type;


/*
;======================================================================
; structure of data within a bpb, including the 
; extended boot record fields
;
; NOTE: the bsJump and bsOemName fields are purposely left out of
; this structure.  the addressability of this structure starts with
; the bpb information.
*/

struct bpb {
/*==== start of BPB */
 word  bsBytesPerSec;		/* bytes per sector */
 byte  bsSecPerClust;		/* sectors per cluster */
 word  bsResSectors;		/* # of reserved sectors */
 byte  bsFATs;			/* # of FAT tables */
 word  bsRootDirEnts;		/* # of root directory entries */
 word  bsSectors;		/* total # of sectors */
 byte  bsMedia;			/* media descriptor */
 word  bsFATsecs;		/* # of sectors per FAT */
 word  bsSecPerTrack;		/* # of sectors per track */
 word  bsHeads;			/* # of heads */
 dword bsHiddenSecs;		/* # of hidden sectors */
 dword bsHugeSectors;		/* # of sectors when bsSectors == 0 */
/*==== end of BPB  */
 byte  bsDriveNumber;		/* drive number */
 byte  bsReserved1;		/* reserved */
 byte  bsBootSignature;		/* extended PBR signature (29h) */
 dword bsVolumeID;		/* volume id number */
 byte  bsVolumeLabel[11];	/* volume label */
 byte  bsFileSysType[8];	/* file-system type */
 };

typedef struct bpb bpb_type;


/*
;======================================================================
; structure of data within a partition table entry
*/

struct erec {
 byte  peBootable;		/* 80h = bootable, 0 = non */
 byte  peBeginHead;		/* beginning head */
 byte  peBeginSector;		/* beginning sector */
 byte  peBeginCylinder;		/* beginning cylinder */
 byte  peFileSystem;		/* name of file system */
 byte  peEndHead;		/* ending head */
 byte  peEndSector;		/* ending sector */
 byte  peEndCylinder;		/* ending cylinder */
 dword peStartSector;		/* starting sector (rel to beg of disk) */
 dword peSectors;		/* total sectors in partition */
 };

typedef struct erec pe_type;


/* values for the Partition Type Code */

#define PTCnil  0			/* nada */
#define PTCsm12 1			/* small partition, 12 bit fat */
#define PTCsm16 4			/* small, 16 bit fat */
#define PTCext  5			/* extended partition */
#define PTCdlg	6			/* DLG partition */


/*
;======================================================================
; structure of data for the i21f44s0Ds40 and i21f44s0Ds60 ioctl calls
*/

struct dprec {
 byte  dpSpecFunc;		/* special functions */
 byte  dpDevType;		/* device type */
 word  dpDevAttr;		/* device attributes */
 word  dpCylinders;		/* number of cylinders */
 byte  dpMediaType;		/* media type */
/*==== start of BPB */
 word  dpBytesPerSec;		/* bytes per sector */
 byte  dpSecPerClust;		/* sectors per cluster */
 word  dpResSectors;		/* # of reserved sectors */
 byte  dpFATs;			/* # of FAT tables */
 word  dpRootDirEnts;		/* # of root directory entries */
 word  dpSectors;		/* total # of sectors */
 byte  dpMedia;			/* media descriptor */
 word  dpFATsecs;		/* # of sectors per FAT */
 word  dpSecPerTrack;		/* # of sectors per track */
 word  dpHeads;			/* # of heads */
 dword dpHiddenSecs;		/* # of hidden sectors */
 dword dpHugeSectors;		/* # of sectors when bsSectors == 0 */
 byte  dpResv[6];		/* reserved area */
/*==== end of BPB */
 word  dpTracks;		/* # of tracks in track table */
 word  dpTrackTable;		/* starting location of track table */
 };

typedef struct dprec dp_type;


/*
;======================================================================
; structure of data for the i21f44s0Ds41 and i21f44s0Ds61 ioctl calls
*/

struct rwrec {
 byte  rwSpecFunc;		/* special functions (must be 0) */
 word  rwHead;			/* head to read/write */
 word  rwCylinder;		/* cylinder to read/write */
 word  rwFirstSector;		/* first sector to read/write */
 word  rwSectors;		/* number of sectors to read/write */
 dword rwBuffer;		/* address of buffer */
 };

typedef struct rwrec rw_type;

/*
;======================================================================
; structure of data for the i21f44s0Ds42 and i21f44s0Ds62 ioctl calls
*/

struct fvblock {
 byte  fvSpecFunc;		/* special functions (must be 0) */
 word  fvHead;			/* head to format/verify */
 word  fvCylinder;		/* cylinder to format/verify */
 };

typedef struct fvblock fv_type;


/*
;======================================================================
; structure of data within a dpb (drive parameter block)
; use with i21f32
; NOTE: this is for dos versions 4.00 and above
*/

struct dpbrec {
 byte  dpbDrive;			/* drive # (0 = A, 1 = B, etc) */
 byte  dpbUnit;			/* unit # for driver */
 word  dpbSectorSize;		/* sector size, in bytes */
 byte  dpbClusterMask;		/* bytes per cluster - 1 */
 byte  dpbClusterShift;		/* sectors per cluster, as power of 2 */
 word  dpbFirstFAT;		/* first FAT sector */
 byte  dpbFATCount;		/* # of FATs */
 word  dpbRootEntries;		/* # of root directory entries */
 word  dpbFirstSector;		/* first sector of first cluster */
 word  dpbMaxCluster;		/* number of clusters + 1 */
 word  dpbFATSize;		/* # of FAT sectors */
 word  dpbDirSector;		/* first sector of directory */
 dword dpbDriverAddr;		/* address of device driver */
 byte  dpbMedia;			/* media descriptor */
 byte  dpbFirstAccess;		/* indicates access to drive */
 dword dpbNextDPB;		/* address of next dpb */
 word  dpbNextFree;		/* last allocated cluster */
 word  dpbFreeCnt;		/* # of free clusters */
 };

typedef struct dpbrec dpb_type;


/*
;======================================================================
; structure of data for an int25/int26 parameter buffer
; use with dos 4.00 and above, and mos newer than 4.10
*/

struct diskio {
 dword diStartSector;		/* sector number to start */
 word  diSectors;		/* number of sectors */
 dword diBuffer;		/* address of buffer */
 };

typedef struct diskio dio_type;


/*
;======================================================================
; structure of data for an extended fcb
*/

struct extfcb {
 byte  extSignature;		/* should be ff */
 byte  extReserved1[5];
 byte  extAttribute;		/* attribute byte */
 byte  extDriveID;		/* 0=default, 1=a... */
 byte  extFileName[8];
 byte  extExtent[3];
 word  extCurBlockNo;		/* current block number */
 word  extRecSize;		/* record size */
 dword extFileSize;		/* bytes in file */
 word  extFileDate;		/* date last modified */
 word  extFileTime;		/* time last modified */
 byte  extReserved2[8];
 byte  extCurRecNo;		/* current record number */
 dword extRandomRecNo;		/* random record number */
 };

typedef struct extfcb xfcb_type;

/*
;======================================================================
; structure of data for a directory entry
*/

struct direntry {
 byte  deName[8];
 byte  deExtension[3];
 byte  deAttributes;
 byte  deReserved[10];
 word  deTime;
 word  deDate;
 word  deStartCluster;
 dword deFileSize;
 };

typedef struct direntry de_type;


/*
;======================================================================
; structure of data for a media id request (i21f44s0Ds66)
*/

struct mid {
 word midInfoLevel;
 dword midSerialNum;
 byte midVolLabel[11];
 byte midFileSysType[8];
 };

typedef struct mid mid_type;

