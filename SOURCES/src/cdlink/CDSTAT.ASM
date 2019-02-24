	page	80,132

;--------------------------------------------------------------------;
;          Copyright 1993 Rod Roark                                  ;
;--------------------------------------------------------------------;

uCIStruc	struc			; cache index structure
dCIVolHash	dd	?		; identifies the cd-rom volume
dCISector	db	3 dup(?)	; cd-rom sector number
bCILocation	db	?		; entry number within this bucket
uCIStruc	ends

CILEN		equ	8		; length of the above structure

;----------------------- Code/Data Segment -------------------------;

mainseg	segment	para
	assume	cs:mainseg,ds:mainseg
	db	100h dup(?)

entry	label	near
	jmp	start

	db	13,'   '
	db	10,13,'Copyright 1993 Rod Roark'
	db	10,13,26

	even

;------------------- Data Retrieved from CD-Link --------------------;

dNoLongReads	dw	0,0
dNoShortReads	dw	0,0
dNoCacheHits	dw	0,0
dNoCacheRewrites dw	0,0
wNoCacheOpens	dw	0
wNoCacheErrors	dw	0
sCacheFileName	db	66 dup(0)

;---------------------------- Messages ------------------------------;

sMsgStatus	db	13,10
		db	'-- CD-Link Cache Statistics --',13,10,13,10
sMsgShortReads	db	'Short (cached) reads ?????????',13,10
sMsgCacheHits	db	'Cache hits           ?????????',13,10
sMsgCacheRewrites db	'Cache index rewrites ?????????',13,10
sMsgLongReads	db	'Long (uncached) reads?????????',13,10
sMsgCacheOpens	db	'Cache file opens         ?????',13,10
sMsgCacheErrors	db	'Cache file errors        ?????',13,10
		db	'$'

sMsgStatus2	db	13,10
sMsgCacheCap	db	'Capacity (sectors)   ?????????',13,10
sMsgCacheUsed	db	'Sectors cached       ?????????',13,10
		db	'$'

sMsgError	db	13,10,'Unable to read cache file',13,10,'$'

NUMOFFSET	equ	29		; offset to last digit in each message
NUMLEN		equ	9		; number of digits in each message

		even

w10		dw	10
w10000		dw	10000

dSectorsCached	dw	0,0		; number of sectors cached

;--------------------------- I/O Areas ------------------------------;

lCacheHeader	label	byte		  ; read cache header starting here
wBucketSectors	dw	20		  ; no of 2k sectors per cache bucket
wBucketBytes	dw	20*(CILEN+2048+8) ; bytes per bucket 
wCacheBuckets	dw	3		  ; no of buckets in the cache file
wCacheIxBytes	dw	20*CILEN	  ; length of each cache bucket index
CACHEHDRLEN	equ	8		  ; length of cache header

lCacheIndex	label	byte		; read cache index starting here
		db	20*CILEN dup(0)

	page
;------------------------------ Code --------------------------------;

start	label	near
	mov	ax,1511h		; get CD-Link statistics
	push	ds
	pop	es
	mov	bx,offset dNoLongReads
	int	2fh

	mov	ax,[dNoLongReads]
	mov	dx,[dNoLongReads+2]
	mov	bx,offset sMsgLongReads+NUMOFFSET
	mov	cl,NUMLEN
	call	BinToDec

	mov	ax,[dNoShortReads]
	mov	dx,[dNoShortReads+2]
	mov	bx,offset sMsgShortReads+NUMOFFSET
	mov	cl,NUMLEN
	call	BinToDec

	mov	ax,[dNoCacheHits]
	mov	dx,[dNoCacheHits+2]
	mov	bx,offset sMsgCacheHits+NUMOFFSET
	mov	cl,NUMLEN
	call	BinToDec

	mov	ax,[dNoCacheRewrites]
	mov	dx,[dNoCacheRewrites+2]
	mov	bx,offset sMsgCacheRewrites+NUMOFFSET
	mov	cl,NUMLEN
	call	BinToDec

	mov	ax,[wNoCacheOpens]
	xor	dx,dx
	mov	bx,offset sMsgCacheOpens+NUMOFFSET
	mov	cl,NUMLEN
	call	BinToDec

	mov	ax,[wNoCacheErrors]
	xor	dx,dx
	mov	bx,offset sMsgCacheErrors+NUMOFFSET
	mov	cl,NUMLEN
	call	BinToDec

	mov	ah,9			; write stats part 1
	mov	dx,offset sMsgStatus
	int	21h

;------------------- Process Cache File -----------------------------;

	mov	ax,3dc0h		; private, deny none, read-only
	mov	dx,offset sCacheFileName
	int	21h
	jc	IOError
	mov	bx,ax

	mov	ah,3fh			; read cache header
	mov	dx,offset lCacheHeader
	mov	cx,CACHEHDRLEN
	int	21h
	jc	IOError
	mov	si,[wCacheBuckets]
ixloop1:
	mov	ah,3fh			; read next bucket index
	mov	dx,offset lCacheIndex
	mov	cx,[wCacheIxBytes]
	int	21h
	jc	IOError
	xor	ax,ax
	xor	di,di
	cld
ixloop2:
	push	di			; count used index entries
	add	di,offset lCacheIndex
	mov	cx,7
	repe	scasb
	pop	di
	je	ixskip
	add	[dSectorsCached],1
	adc	[dSectorsCached+2],ax
ixskip:
	add	di,CILEN
	cmp	di,[wCacheIxBytes]
	jb	ixloop2

	mov	ax,4201h		; position to next bucket index
	xor	cx,cx
	mov	dx,[wBucketBytes]
	sub	dx,[wCacheIxBytes]
	int	21h
	jc	IOError

	dec	si			; repeat for all buckets
	jnz	ixloop1

	mov	ax,[wCacheBuckets]
	mul	[wBucketSectors]
	mov	bx,offset sMsgCacheCap+NUMOFFSET
	mov	cl,NUMLEN
	call	BinToDec

	mov	ax,[dSectorsCached]
	mov	dx,[dSectorsCached+2]
	mov	bx,offset sMsgCacheUsed+NUMOFFSET
	mov	cl,NUMLEN
	call	BinToDec

	mov	ah,9			; write stats part 2
	mov	dx,offset sMsgStatus2
	int	21h
done:
	int	20h
IOError:
	mov	ah,9			; write stats part 2
	mov	dx,offset sMsgError
	int	21h
	jmp	done

;--------------------- BINARY-TO-DECIMAL ROUTINE --------------------;

BinToDec proc	near
	push	cx
btdloop0:
	mov	ch,4			; do 4 digits at a time
	div	[w10000]
	mov	si,ax			; si holds quotient
	mov	ax,dx
	xor	dx,dx
btdloop1:
	div	[w10]
	add	dl,'0'
	mov	[bx],dl
	dec	bx
	xor	dx,dx
	dec	cl
	jz	btdpart2
	dec	ch
	jnz	btdloop1
	mov	ax,si			; get quotient
	xor	dx,dx
	jmp	btdloop0
btdpart2:
	pop	cx
btdloop2:
	inc	bx
	dec	cl
	jz	btdret
	cmp	byte ptr [bx],'0'
	jne	btdret
	mov	byte ptr [bx],' '
	jmp	btdloop2
btdret:
	ret
BinToDec endp

mainseg	ends
        end	entry
