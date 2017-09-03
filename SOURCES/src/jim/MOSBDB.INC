comment ^==============================================================

mjs 12/16/91	dlg mods: changed bdbfsiz from a byte to a word to match the
		dos4/5 dpb definition.  moved bubclustl and bdbcfree to
		match dpb defintion.  change bdbsctr from 24 bits to 32 for
		dlg sector numbers.  reduced the cownid field from a word
		containing a tcb segment to a byte containing the tcbid
		value.  enlarged the csector field from 24 bits to 32 bits
		for 32 bit dlg sector numbers.

======================================================================^

bdb segment at 0beefh

;==== bdb prefix

		db	?	; reserved
bdbtype 	db	?	; 'b' to indicate bdb
		db	6 dup(?) ; reserved
bdbnext 	dw	?	; address of next bdb
bdbprev 	dw	?	; address of previous bdb
bdbreal 	dw	?	; address of real bdb for drive
bdbanxt 	dw	?	; next alias for real drive

;==== end of prefix

;==== start of dpb area

bdbdpb	label	byte
bdbid		db	?	; logical drive
bdbunit 	db	?	; driver unit number
bdbssiz 	dw	?	; sector size
bdbcmsk 	db	?	; cluster mask
bdbcshl 	db	?	; cluster shift count
bdbfat		dw	?	; fat 1 start sector
bdbfnum 	db	?	; number fat's
bdbrnum 	dw	?	; number root dir entries
bdbclus 	dw	?	; cluster 2 start sector
bdbcnmx 	dw	?	; number of clusters + 1
bdbfsiz 	dw	?	; fat size in sectors
bdbdir		dw	?	; directory start sector
bdbdrvr 	dd	?	; address of device driver
bdbmdia 	db	?	; media byte
		db	?	; needed by bernoulli driver
bdbdpbpn	dd	?	; next dpb in chain, for bernoulli driver
bdbclustl 	dw	?	; last cluster allocated for this bdb
bdbcfree	dw	?	; number of clusters free (-1 if invalid)
				;   (needs to be evaluated)
;==== end of dpb

bdbbig		db	?	; n if dos size volume, y if large
		db	?	; filler
bdbcsiz 	db	?	; number of sectors in one cluster
bdbcnum 	dw	?	; number of clusters on device
bdbroot		dw	?	; root directory cluster
bdbalias	dw	?	; pointer to alias string
bdbtask 	dw	?	; task owning this bdb
bdbcach 	db	?	; = 0 if drive not to be cached (e.g. ramdisk)
bdbsuob 	dw	?	; max # bdbssiz in uob
bdbclpf 	dw	?	; head of location list for bdb
bdbslo		dw	?	; sector position after last disk i/o
bdbshi		dw	?
bdbspc		dw	?	; sectors per cylinder for media
bdbspt		dw	?	; sectors per track for media
bdbhddn 	dd	?	; hidden sectors
bdbdmtr 	db	?	; drive motor select byte if floppy, else 0
bdbsctr 	dw	?,?	; total sectors on device
bdbcerr 	db	?	; 'y' if waiting for tcb other than scbtcbpc to
				;   dispose of critical error (so we don't turn
				;   the motor off)

bdblen	equ	$-bdb
bdb ends

dbb segment at 0dadah

dbbbuf		equ	this byte	; start of sector buffer

dbb ends

;======================================================================
; critical error coding & cstatus values

rdx		equ	00h		; read operation
wrx		equ	01h		; write operation

failx		equ	08h		; fail not allowed
retryx		equ	10h		; retry not allowed
ignorex 	equ	20h		; ignore not allowed
allx		equ	failx or retryx or ignorex
sysx		equ	failx or retryx ; ignore not allowed in system areas

dosx		equ	00h or allx	; dos area of disk?
fatx		equ	02h or sysx	; fat area
dirx		equ	04h or sysx	; dir area
datax		equ	06h or allx	; data area

fatflg		equ	( fatx and not sysx ) xor 06h
dirflg		equ	( dirx and not sysx ) xor 06h

vrfflg		equ	80h
flshflg 	equ	40h

;======================================================================
; cache element descriptor

cache struc
cstatus 	db	?	; changed, fat, dir, data (0 if unused)
csector 	dw	?,?	; start sector for cache element
cuseprv 	dw	?	; usage-ordered linkage
cusenxt 	dw	?	;	"
clocprv 	dw	?	; bdb/sector-ordered linkage
clocnxt 	dw	?	;	"
cerror		db	?	; error code if error on write attempt
cownid		db	?	; tcbid (byte) of last task to write
cnumsct 	db	?	; # sectors in this uob (0 = unused)
cache ends

; attention:
; type cache must be equal to 16 or the code which divides by 16 by
; shifts needs to change and the size of scbcsave needs to change
if type cache ne 16
	%out	cache element descriptor size error, must be cachesize bytes
endif

;======================================================================
; disk sector block - block for holding sector numbers

sectorblk struc
seclow		dw	?	; low word of sector number
sechigh 	dw	?	; high word of sector number
secoper 	db	?	; operation for sector
secpad		db	?	; pad byte
secclst 	dw	?	; extra space for cluster number
sectmp		dw	?	; temporary space for anything
sectorblk ends

