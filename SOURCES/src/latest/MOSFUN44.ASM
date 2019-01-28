	include page.inc
	title	mosfun44 - mos function 44
comment ^===============================================================
		      development specification

 program name:	$$mos.com		 assigned to: jim bean
 module name:	mosfun44		 assign date: 05/02/88
 entry points:	mosfun44		 completed: 05/02/88
 entry from:	mosint21, mosfun0f
 entry method:	call
 calls:		mosfutil, mosliman, gettime, caps
 purpose:	file handle functions
 last update:	08/18/1992
========================================================================

jrb 05/02/88	correct ioctl fn 0e and 0f (get/set logical drive)
		change get current dir to do a media check (which also
		returns cdb ptr) because dos does and it's needed on
		floppies
		split mosfun44 into new mosfun44.asm cause mosfun39
		ran out of room

sjc 07/06/88	correct ioctl fn 0b to use the right reg (dx, not bx).

jrb 12/03/88	generic ioctl wasn't looking to see if it was supported
		by the device driver before calling the device driver
		lanlink and ramdisk (in particular) went off into
		space

sah 01/26/89	change lock equate to nlock (masm 5.10 compatibility)

sah 03/23/89	notice that dos places return value in ax for function
		4400h.

sah 07/26/89	corrections for function 4400 via mjs

sah 12/14/89	remove mosregs2.inc

sah 04/20/90	corrections for 4409 and 440a for proper report device
		is local or remote.

sah 10/08/90	corrections for 4400, inverted eof bit for dbase iv

bwr 11/05/90	compatibility fix for corel cd-worm driver.  device
		driver being called with wrong request header length.
		due to some weird microsoft convention, the device
		header length field does not consider the volume id
		fields as part of the request header length for dos
		versions < 4.00.  for dos 4.0 or later, the entire
		header is included in the length field.
		the corel driver was deciding that the request
		header was a dos 4.00 request header based on the fact
		that the rh length was not 22 bytes, causing him to
		look for the starting sector number at a different
		location in the rh, and to make matters worse, he was
		looking for a double-word sector number at that
		location which was, of course, garbage.	 the side
		effect of all this wound up being a divide overflow
		condition within the driver.

sah 01/24/91	make sure that al is return 00 for hard drives in 440eh
		this is corrected for attempting to make geoworks work.

mjs 12/16/91	dlg mods: converted ioctl02 and ioctl03 to use the common
		function ioctl_rwc.  converted ioctl04 and ioctl05 to use
		the common function ioctl_rwb.  converted the ioctl0d logic
		into the common function io0d.  this function is also
		called by the makelbl and delete functions (mosfutil.asm). 
		the todriver error code value is no longer reduced by 19
		for the i21f44s0d call.  added ioctl10, for i21f44s10. 
		added ioctl11, for i21f44s11.

mjs 03/03/92	correct glitches introduced in the 12/16/91 overhaul.

================ 5.01 Kernel Ends Here ====================================

mjs 04/23/92	restored "add ax,19" to the io0d function.  necessary
		to prevent a write-protect critical error from being
		ignored.
		effected with updat501.sys version 1.00.

mjs 08/18/92	clean up segment declarations

=======================================================================^

.xlist
;	include mosfun44.pub
	include group.inc
	include mosregs.inc
	include moscdb.inc
	include mosgfb.inc
	include mostfb.inc
	include mosrlb.inc
	include mosbdb.inc
	include macros.inc
	include errcodes.inc
	include dskstruc.inc

tcb	segment at 1234h
	include mostcb.inc
tcb	ends

gdata	segment
	include mosscbex.inc
gdata	ends

.list

;======================================================== ddt segment
if 0 eq 0
segment_num = 2
endif
ddt	segment
	assume	cs:mo2,ds:grp,es:nothing,ss:tcb

	extrn	mosend:byte, sbios2:word
	extrn	mosliman:near, caps:near
	extrn	gettime:near, execopen:near
	extrn	mo1seg:word

; extrn's from MOSFUTIL.ASM

	extrn	alloclust:near, blkread:near, blkwrite:near
	extrn	chklock:near, closefile:near, clrclust:near, create:near
	extrn	dealloc:near, delete:near, devchk:near, todriver:near
	extrn	emptydir:near, findbdb:near, findgfb:near, findlbl:near
	extrn	findnm:near, findrlb:near, findtfb:near, flushdir:near
	extrn	getfat:near, getphdl:near, makelbl:near
	extrn	moserror:near, nextnm:near, openfile:near
	extrn	pathfind:near, putfat:near, rddir:near, slash:near
	extrn	timestamp:near, wrsector:near, setphdl:near, iolock:near
	extrn	devread:near, devwrite:near, finddrv:near, exclude:near
	extrn	okchar:near, encrypt:near, decrypt:near, classlvl:near
	extrn	cpycmap:near, eblcmap:near, capscmps:near

; extrn's from MOSMIMAN.ASM

	extrn	readguts:near, writeguts:near, truncguts:near
	extrn	creatguts:near, checkexon:near
	extrn	buffinp:near, cdevinp:near

; extrn's from MOSFUN39.ASM

	extrn	noswt:near
	extrn	okswt:near
	extrn	sttax0:near

	public	mosfun44

if 0 eq 0				; trick public.com

; error codes defined

syshdl	equ	127 or 8000h		; attempt to dup or fdup a non-psp handle
xshare	equ	error_sharing_violation or 8000h  ; fail from int 24h sharing
xlock	equ	error_lock_violation or 8000h  ; fail from int 24h locking
err24h	equ	error_fail_i24 or 8000h	; fail error from int 24h (signal for moserror)
intern	equ	80ffh			; internal error

; directory entry fields

datr	equ	11			; offset of attribute byte
dclass0 equ	13			; offset of class byte
dtime	equ	22			; offset of time word
ddate	equ	24			; offset of date word
dsize	equ	28			; offset of size dword
dclust	equ	26			; offset of bof cluster word

; directory entry file attribute bits defined

override equ	80h			; dir search class level override
arch	equ	20h			; archive
dir	equ	10h			; directory
lbl	equ	08h			; label
sys	equ	04h			; system
hid	equ	02h			; hidden
ro	equ	01h			; read-only

; critical error coding

rdx	equ	00h			; read operation
wrx	equ	01h			; write operation
failx	equ	08h			; fail not allowed
retryx	equ	10h			; retry not allowed
ignorex equ	20h			; ignore not allowed
allx	equ	failx or retryx or ignorex
sysx	equ	failx or retryx		; ignore not allowed in system areas
dosx	equ	00h or allx		; dos area of disk?
fatx	equ	02h or sysx		; fat area
dirx	equ	04h or sysx		; dir area
datax	equ	06h or allx		; data area

endif

	assume	cs:mo2,ds:nothing,es:nothing,ss:nothing

; vectors for ioctl subfunctions

ioctl	dw	mo2:ioctl00, mo2:ioctl01, mo2:ioctl02, mo2:ioctl03
	dw	mo2:ioctl04, mo2:ioctl05, mo2:ioctl06, mo2:ioctl07
	dw	mo2:ioctl08, mo2:ioctl09, mo2:ioctl0a, mo2:ioctl0b
	dw	mo2:ioctl0c, mo2:ioctl0d, mo2:ioctl0e, mo2:ioctl0f
	dw	mo2:ioctl10, mo2:ioctl11
endioct equ	this byte

	subttl mosfun44 - i/o control for devices (ioctl)
	page
;======================================================================
;,fs
; mosfun44 - i/o control for devices (ioctl)
;
; in:	see subfunctions
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_function  - invalid function number
;	  sub-function-specific errors below
;	carry bit of tflag clear if no error
;	 see sub-functions for other returned values
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	mosfun44
	mov	si,bp
	mov	bp,[bp]
	mov	al,[tal]
	mov	bx,[tbx]
	mov	cx,[tcx]
	mov	dx,[tdx]
	mov	di,[tds]
	mov	bp,si
	call	noswt
	xor	ah,ah
	mov	si,ax
	mov	ax,error_invalid_function
	cmp	si,(endioct-ioctl)/2
	jae	mosf44x			; invalid sub-function if greater than 0bh
	add	si,si
	call	ioctl[si]
	assume	ds:nothing,es:nothing,ss:tcb
mosf44x:
	call	okswt			; safe to allow a task switch
	mov	bx,bp
	mov	bp,[bp]			; address task registers to report tax error
	and	[tflag],not carry
	or	ax,ax
	jz	mosf44sk		; if clear means no error
	mov	cx,ax
	and	cx,not 8000h
	call	moserror
mosf44sk:
	mov	bp,bx
lendp	mosfun44

	subttl ioctl00 - get device information
	page
;======================================================================
;,fs
; ioctl00 - get device information
;
; in:	bx = file handle
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle
;	carry bit of tflag clear if no error
;	 tdx = device data
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl00:
	call	findtfb
	assume	es:tfb
	mov	ax,error_invalid_handle
	jc	ioctl00x
	mov	ds,[tfbgfb]
	assume	ds:gfb
	xor	dh,dh
	cmp	[gfbdev],0		; is this a character device
	je	ioctl00a		; then set dh == hi-order byte of driver
	lds	si,[gfbdrvr]		; attribute word, esle set to 0
	assume	ds:nothing
	mov	dh,[si+5]		; hi-order byte of driver attribute word
ioctl00a:
	mov	dl,[tfbioctl]
	xor	dl,40h			; invert eof bit
	mov	bx,bp
	mov	bp,[bp]
	mov	[tdx],dx
	mov	[tax],dx		; dos appears to put it in ax too
	mov	bp,bx
	xor	ax,ax
ioctl00x:
	ret

	subttl ioctl01 - set device information
	page
;======================================================================
;,fs
; ioctl01 - set device information
;
; in:	bx = file handle
;	dx = device information to set
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle
;	  error_invalid_function  - device information invalid
;	carry bit of tflag clear if no error
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl01:
	call	findtfb
	assume	es:tfb
	mov	ax,error_invalid_handle
	jc	ioctl01x
	mov	ds,[tfbgfb]
	assume	ds:gfb
	mov	ax,error_invalid_function
	test	[tfbioctl],80h
	jz	ioctl01x		; invalid function for block device
	or	dh,dh
	jnz	ioctl01x		; "DH must be zero for call AL=01H"
	or	dl,80h			; can't change the ISDEV bit
	mov	[tfbioctl],dl
	xor	ax,ax
ioctl01x:
	ret

	subttl ioctl_rwc - read/write from device control channel
	page
;======================================================================
;,fs
; ioctl_rwc - read/write from device control channel
;
; in:	bx = file handle
;	cx = number of bytes to read/write
;	di:dx -> buffer
;	al = driver command byte
;	ah = entry ah for todriver call
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle
;	  error_invalid_function  - device doesn't support IOCTL
;	carry bit of tflag clear if no error
;	 tax = number of bytes read/written
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lproc	ioctl_rwc
lstring request,26
lbyte	todrah
	push	ax
	push	cx
	push	dx
	push	di
	mov	ax,ss
	mov	es,ax
	lea	di,[request]
	xor	ax,ax
	mov	cx,26/2
	cld
	rep	stosw
	pop	word ptr [request].irwrBuffer+2
	pop	word ptr [request].irwrBuffer
	pop	word ptr [request].irwrBytes
	pop	ax
	mov	[request].irwrFunction,al  ; record command
	mov	[todrah],ah		; record ah value for todriver
	call	findtfb
	assume	es:tfb
	mov	ax,error_invalid_handle
	jc	ioctl02x
	mov	es,[tfbgfb]
	assume	es:gfb
	mov	ax,error_invalid_function
	cmp	[gfbdev],0
	je	ioctl02x		; e if not a character device
	lds	si,[gfbdrvr]
	test	byte ptr [si+5],40h
	jz	ioctl02x		; ioctl not allowed if z
	mov	[request],22		; length of request block
	push	ss
	pop	es
	lea	bx,[request]
	xor	cx,cx			; no retries
	xor	al,al			; no drive
	mov	ah,[todrah]
	call	todriver
	mov	cx,word ptr [request+18]
	call	sttax
ioctl02x:
lundef	request,26
lundef	todrah
lendp	ioctl_rwc

	subttl ioctl02 - read from device control channel
	page
;======================================================================
;,fs
; ioctl02 - read from device control channel
;
; in:	bx = file handle
;	cx = number of bytes to read
;	di:dx -> buffer
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle
;	  error_invalid_function  - device doesn't support IOCTL
;	carry bit of tflag clear if no error
;	 tax = number of bytes read
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
ioctl02 proc near
	mov	al,3
	mov	ah,80h or dosx
	jmp	ioctl_rwc
ioctl02 endp

	subttl ioctl03 - write to device control channel
	page
;======================================================================
;,fs
; ioctl03 - write to device control channel
;
; in:	bx = file handle
;	cx = number of bytes to write
;	di:dx -> data to write
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle
;	  error_invalid_function  - device doesn't support IOCTL
;	carry bit of tflag clear if no error
;	 tax = number of bytes written
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
ioctl03 proc near
	mov	al,12
	mov	ah,80h or dosx or wrx
	jmp	ioctl_rwc
ioctl03 endp

	subttl ioctl_rwb - read from block device control channel
	page
;======================================================================
;,fs
; ioctl_rwb - read from block device control channel
;
; in:	bl = block device drive (0=default)
;	cx = number of bytes to read
;	di:dx -> buffer
;	al = driver command byte
;	ah = entry ah for todriver call
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_drive - invalid drive
;	  error_invalid_function	- device doesn't support IOCTL
;	carry bit of tflag clear if no error
;	 tax = number of bytes read
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
lproc	ioctl_rwb
lstring request,26
lbyte	todrah
	push	ax
	push	cx
	push	dx
	push	di
	mov	ax,ss
	mov	es,ax
	lea	di,[request]
	xor	ax,ax
	mov	cx,26/2
	cld
	rep	stosw
	pop	word ptr [request].irwrBuffer+2
	pop	word ptr [request].irwrBuffer
	pop	word ptr [request].irwrBytes
	pop	ax
	mov	[request].irwrFunction,al  ; record command
	mov	[todrah],ah		; record ah value for todriver
	mov	al,bl
	dec	al
	jns	ioctl04a
	mov	al,[tcbcdriv]
ioctl04a:
	call	findbdb
	assume	ds:bdb
	jc	ioctl04x
	push	ds
	pop	es
	assume	es:bdb
	lds	si,[bdbdrvr]
	assume	ds:nothing
	mov	ax,error_invalid_function
	test	byte ptr [si+5],40h
	jz	ioctl04x		; ioctl not allowed if z
	mov	al,[bdbmdia]
	mov	[request+13],al
	mov	al,[bdbunit]		; unit within block device driver
	mov	[request+1],al
	mov	[request],22
	mov	al,[bdbid]
	push	ss
	pop	es
	assume	es:nothing
	lea	bx,[request]
	mov	ah,[todrah]
	xor	cx,cx			; no retries
	call	todriver
	mov	cx,word ptr [request+18]
	call	sttax
ioctl04x:
lundef	request,26
lundef	todrah
lendp	ioctl_rwb

	subttl ioctl04 - read from block device control channel
	page
;======================================================================
;,fs
; ioctl04 - read from block device control channel
;
; in:	bl = block device drive (0=default)
;	cx = number of bytes to read
;	di:dx -> buffer
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_drive - invalid drive
;	  error_invalid_function	- device doesn't support IOCTL
;	carry bit of tflag clear if no error
;	 tax = number of bytes read
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
ioctl04 proc near
	mov	al,3
	mov	ah,dosx or rdx
	jmp	ioctl_rwb
ioctl04 endp

	subttl ioctl05 - write to block device control channel
	page
;======================================================================
;,fs
; ioctl05 - write to block device control channel
;
; in:	bl = block device drive (0=default)
;	cx = number of bytes to write
;	di:dx -> data to write
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_drive - invalid drive
;	  error_invalid_function	- device doesn't support IOCTL
;	carry bit of tflag clear if no error
;	 tax = number of bytes written
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
ioctl05 proc near
	mov	al,12
	mov	ah,dosx or wrx
	jmp	ioctl_rwb
ioctl05 endp

	subttl ioctl06 - get input status
	page
;======================================================================
;,fs
; ioctl06 - get input status
;
; in:	tbx = file or device handle
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle
;	carry bit of tflag clear if no error
;	 tal = 0ffh if ready for read (chars are buffered or not at eof)
;	 tal = 00h if not ready (no chars ready or at eof if file)
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl06:
	call	findtfb
	assume	es:tfb
	mov	ax,error_invalid_handle
	jc	ioctl06x
	mov	bx,word ptr [tfbpos]
	mov	dx,word ptr [tfbpos+2]
	mov	es,[tfbgfb]
	assume	es:gfb
	cmp	[gfbdev],0
	jne	ioctl06a
	mov	al,0ffh
	sub	bx,word ptr [gfbsize]
	sbb	dx,word ptr [gfbsize+2]
	jc	ioctl06b		; sah input file ready if prior to eof
	inc	al			; else is not ready (al=0)
	jmp	ioctl06b		; sah fixed bugs with turbo-pascal
ioctl06a:
	lds	si,[gfbdrvr]
	assume	ds:nothing
	mov	al,6
	mov	ah,80h			; character device
	xor	dx,dx
	call	devchk
	mov	al,00h
	jc	ioctl06b
	test	ah,02h
	jnz	ioctl06b		; busy bit set if no chars ready
	dec	al
ioctl06b:
	call	sttal			; set tal reg w/ al
ioctl06x:
	ret

	subttl ioctl07 - get output status
	page
;======================================================================
;,fs
; ioctl07 - get output status
;
; in:	tbx = file or device handle
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle
;	carry bit of tflag clear if no error
;	 tal = 0ffh if ready for write (won't wait)
;	 tal = 00h if not ready
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl07:
	call	findtfb
	assume	es:tfb
	mov	ax,error_invalid_handle
	jc	ioctl07x
	mov	es,[tfbgfb]
	assume	es:gfb
	mov	al,0ffh
	cmp	[gfbdev],0
	je	ioctl07b		; output status of file is always ready
	lds	si,[gfbdrvr]
	assume	ds:nothing
	mov	al,10
	mov	ah,80h			; 80h for character device
	xor	dx,dx
	call	devchk
	mov	al,00h
	jc	ioctl07b
	test	ah,02h
	jnz	ioctl07b		; busy bit set if write would wait
	dec	al
ioctl07b:
	call	sttal
ioctl07x:
	ret

	subttl ioctl08 - is a block device changeable?
	page
;======================================================================
;,fs
; ioctl08 - is a block device changeable?
;
; in:	tbl = drive of block device (0=default)
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_drive - invalid drive
;	carry bit of tflag clear if no error
;	 tax = 1 if not changeable
;	 tax = 0 if changeable
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl08:
	mov	al,bl
	dec	al
	jns	ioctl08a
	mov	al,[tcbcdriv]
ioctl08a:
	call	findbdb
	assume	ds:bdb
	mov	ax,error_invalid_function ; this is where it should be done
	jc	ioctl08x
	mov	dl,[bdbunit]		; dl = unit within block device driver
	mov	dh,[bdbid]		; dh = drive number
	lds	si,[bdbdrvr]
	assume	ds:nothing
	mov	ax,1			; indicated device is not changeable
	test	word ptr [si+4],0800h
	jz	ioctl08b		; device doesn't support this call
	mov	al,15
	mov	ah,00h			; bit 7 clear for block device
	call	devchk
	test	ah,02h
	mov	ax,0
	jz	ioctl08b
	inc	ax
ioctl08b:
	call	sttax0
ioctl08x:
	ret

	subttl ioctl09 - is a block device local or remote
	page
;======================================================================
;,fs
; ioctl09 - is a block device local or remote
;
; in:	tbl = drive of block device (0=default)
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_drive - invalid drive
;	carry bit of tflag clear if no error
;	 tdx = device attribute (bit 12 on implies remote)
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl09:
	mov	al,bl
	dec	al
	jns	ioctl09a
	mov	al,[tcbcdriv]
ioctl09a:
	call	findbdb
	assume	ds:bdb
	jc	ioctl09x
	les	bx,[bdbdrvr]
	assume	es:nothing
	mov	ax,es:[bx+4]
	and	ah,7fh
	test	ah,10h
	jz	ioctl09b
	or	ah,80h
ioctl09b:
	call	sttdx
ioctl09x:
	ret

	subttl ioctl0a - is a handle local or remote
	page
;======================================================================
;,fs
; ioctl0a - is a handle local or remote
;
; in:	tbx = handle
;
; out:	carry bit of tflag set if error
;	 tax = error code
;	  error_invalid_handle - invalid handle
;	carry bit of tflag clear if no error
;	 tdx = device attribute (bit 12 on implies remote)
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl0a:
	call	findtfb
	assume	es:tfb
	mov	ax,error_invalid_handle
	jc	ioctl0ax
	mov	es,[tfbgfb]
	assume	es:gfb
	les	bx,[gfbdrvr]
	assume	es:nothing
	mov	ax,es:[bx+4]
	and	ah,7fh
	test	ah,10h
	jz	ioctl0ab
	or	ah,80h
ioctl0ab:
	call	sttdx
ioctl0ax:
	ret

	subttl ioctl0b - set sharing retry count
	page
;======================================================================
;,fs
; ioctl0b - set sharing retry count
;
; in:	tdx = number of retries
;	tcx = time to wait between retries
;
; out:	carry bit of tflag clear
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl0b:
	mov	[tcbntry],dx		; use dx, not bx!
	mov	[tcbttry],cx		; interval between retries for share violations
	xor	ax,ax
	ret

	subttl ioctl0c - undocumented
	page
;======================================================================
;,fs
; ioctl0c - undocumented
;
; in:	
;
; out:	ax = error_invalid_function
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl0c:
	mov	ax,error_invalid_function
	ret

	subttl io0d - generic ioctl functions
	page
;======================================================================
;,fs
; io0d - generic ioctl functions
;
; in:	cx = function major and minor codes
;	bl = drive number (0 default)
;	di:dx -> parameter block
;	ss -> tcb
;
; out:	ax = error code from device driver if error, else 0
;	crashes ax,bx,cx,si,di,ds,es
; 
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:tcb
public io0d
lproc	io0d
lstring request,23
	xchg	ch,cl
	mov	word ptr [request+13],cx
	mov	word ptr [request+19],dx
	mov	word ptr [request+21],di
	mov	al,bl
	dec	al
	jns	ioctl0da
	mov	al,[tcbcdriv]
ioctl0da:
	call	findbdb
	assume	ds:bdb
	jc	ioctl0dx
	mov	al,[bdbunit]
	mov	[request+1],al
	mov	[request],23
	mov	[request+2],19
	lds	si,[bdbdrvr]
	assume	ds:nothing
	mov	ax,error_invalid_function
	test	byte ptr [si+4],40h
	jz	ioctl0dx
	lea	di,[request+3]
	mov	cx,(13-3)/2
	push	ss
	pop	es
	assume	es:nothing
	xor	ax,ax
	rep	stosw
	lea	bx,[request]
	xor	cx,cx			; no retries, no int 24h
	call	todriver
	mov	ax,word ptr [request+3]
	and	al,7fh
	test	ah,80h
	jnz	ioctl0db
	xor	ax,ax
	jmp	ioctl0dx
ioctl0db:
	xor	ah,ah
	add	ax,19
ioctl0dx:
lundef	request,23
lendp	io0d

	subttl ioctl0d - generic ioctl functions
	page
;======================================================================
;,fs
; ioctl0d - generic ioctl functions
;
; in:	tcx (cx) = function major and minor codes
;	tbl (bl) = drive number (0 default)
;	tds:tdx (di:dx) -> parameter block
;
; out:	ax = error code from device driver if error, else 0
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl0d proc near
	jmp	io0d
ioctl0d endp

	subttl ioctl0e - get logical device
	page
;======================================================================
;,fs
; ioctl0e - get logical device
;
; in:	tbl (bl) = drive number (0 default)
;
; out:	ax = error code from device driver, else 0 and tal = assigned
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl0e:
	mov	al,bl
	dec	al
	jns	ioctl0ea
	mov	al,[tcbcdriv]
ioctl0ea:
	call	findbdb
	assume	ds:bdb
	jc	ioctl0ex
	mov	dl,[bdbunit]		; yes it is
	lds	si,[bdbdrvr]		; so it isn't passed as subunit)
	assume	ds:nothing
	mov	ax,error_invalid_function
	test	byte ptr [si+4],40h
	jz	ioctl0ex		; device doesn't support this call
	xor	ax,ax			; block device
	mov	al,23
	call	devchk
	jnc	ioctl0eb
	xor	dl,dl			; make sure dl is 0 for hard drives
ioctl0eb:
	call	sttal0
ioctl0ex:
	ret

	subttl ioctl0f - set logical device
	page
;======================================================================
;,fs
; ioctl0f - set logical device
;
; in:	tbl (bl) = drive number (0 default)
;
; out:	ax = error code from device driver, else 0 and tal = assigned
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl0f:
	mov	al,bl
	dec	al
	jns	ioctl0fa
	mov	al,[tcbcdriv]
ioctl0fa:
	call	findbdb
	assume	ds:bdb
	jc	ioctl0fx
	mov	dl,[bdbunit]		; yes it is
	lds	si,[bdbdrvr]		; so it isn't passed as subunit)
	assume	ds:nothing
	mov	ax,error_invalid_function
	test	byte ptr [si+4],40h
	jz	ioctl0fx		; device doesn't support this call
	xor	ax,ax			; block device
	mov	al,24
	call	devchk
	jnc	ioctl0fb
	xor	dl,dl			; make sure dl is 0 for hard drives
ioctl0fb:
	call	sttal0
ioctl0fx:
	ret

	subttl ioctl10 - query ioctl for character devices
	page
;======================================================================
;,fs
; ioctl10 - query ioctl for character devices
;
; in:	tcx (cx) = function major and minor codes
;	tbl (bl) = drive number (0 default)
;
; out:	ax = error code from device driver if error, else 0
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
ioctl10 proc near
	mov	ax,error_access_denied
	ret
ioctl10 endp

	subttl ioctl11 - query ioctl for block devices
	page
;======================================================================
;,fs
; ioctl11 - query ioctl for block devices
;
; in:	tcx (cx) = function major and minor codes
;	tbl (bl) = drive number (0 default)
;
; out:	ax = error code from device driver if error, else 0
; 
;,fe
;======================================================================
	assume	ds:grp,es:nothing,ss:tcb
lproc	ioctl11
lstring request,23
	xchg	ch,cl
	mov	word ptr [request+13],cx
	mov	al,bl
	dec	al
	jns	ioctl11a
	mov	al,[tcbcdriv]
ioctl11a:
	call	findbdb
	assume	ds:bdb
	jc	ioctl11x
	mov	al,[bdbunit]
	mov	[request+1],al
	mov	[request],23
	mov	[request+2],19h
	lds	si,[bdbdrvr]
	assume	ds:nothing
	mov	ax,error_invalid_function
	test	byte ptr [si+4],40h
	jz	ioctl11x
	lea	di,[request+3]
	mov	cx,(13-3)/2
	push	ss
	pop	es
	assume	es:nothing
	xor	ax,ax
	rep	stosw
	lea	bx,[request]
	xor	cx,cx			; no retries, no int 24h
	call	todriver
	mov	ax,word ptr [request+3]
	and	al,7fh
	test	ah,80h
	jnz	ioctl11b
	xor	ax,ax
	jmp	ioctl11x
ioctl11b:
	xor	ah,ah
ioctl11x:
lundef	request,23
lendp	ioctl11

	subttl sttax - set [tax] from cx
	page
;======================================================================
;,fs
; sttax - set [tax] from cx
;
; set tax reg with processor cx reg;
; sah 12/07/87 this will only work with nested (1 level) lprocs
;
; in:	
;
; out:	
; 
;,fe
;======================================================================
sttax	proc	near
	mov	bx,bp
	mov	bp,[bp]
	mov	bp,[bp]			; remember that function 44x calls are
	mov	[tax],cx		; nested lproc's
	mov	bp,bx
	xor	ax,ax
	ret
sttax	endp

	subttl sttal - set [tal] reg from al
	page
;======================================================================
;,fs
; sttal - set [tal] reg from al
;
; in:	
;
; out:	
; 
;,fe
;======================================================================
sttal	proc	near
	mov	bx,bp
	mov	bp,[bp]
	mov	[tal],al
	mov	bp,bx
	xor	ax,ax
	ret
sttal	endp

	subttl sttdx - set [tdx] reg with processor ax reg
	page
;======================================================================
;,fs
; sttdx - set [tdx] reg with processor ax reg
;
; in:	
;
; out:	
; 
;,fe
;======================================================================
sttdx	proc	near
	mov	bx,bp
	mov	bp,[bp]
	mov	[tdx],ax
	mov	bp,bx
	xor	ax,ax
	ret
sttdx	endp

	subttl sttal0 - set [tal] from dl
	page
;======================================================================
;,fs
; sttal0 - set [tal] from dl
;
; in:	
;
; out:	
; 
;,fe
;======================================================================
sttal0	proc	near
	mov	ax,bp
	mov	bp,[bp]
	mov	[tal],dl		; returned drive parameter
	mov	bp,ax
	xor	ax,ax
	ret
sttal0	endp

ddt	ends
	end

