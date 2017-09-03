	include page.inc
	title	verify.asm - software link pc-mos x86 disk check program
comment ^--------------------------------------------------------------
  verify.exe - software link pc-mos x86 disk check program

  verify - mos disk allocation check program.

  this program checks for cross linked and un-allocated clusters in
  the disk file system. if any are found, corrections can be made
  and changed rewritten to disk.

  verify		check file system and report errors.
  verify  n:		check file system on drive n.
  verify  /c		display non-contiguous files on disk.
  verify  /f		fix any errors found on disk.
  verify  /v		display files on screen as checked.

  author:
	stuart warren & john graham
	warren consulting company
	rt. 2, box 74
	danielsville, ga 30633
	(404) 789-2364

----------------------------------------------------------------------

jsm 04/23/87	entabbed file (50k space reduction).
		made sure di was set to 0fffch before
		all int 25h & 26h calls.
		modified verify function to calculate
		size of a fat correctly if > 64k bytes.
		fixed read_fat, write_fat, get_fat, and
		put_fat to work correctly with fat's
		bigger than 64k (80h, 128d sectors).


sah 07/08/87	remove messages about fragment files

sah 07/12/87	converted 80+ to interupt 38h 00+

sah 08/18/87	correct parameters without spaces

sah 08/20/87	corrected problems with insufiecent
				memory when running verify

jsm 11/20/87	revision mark [2].  changed method of
		recognizing directories so that the
		directories could have their archive
		bits set.  version 1.03

sah 11/23/87	updated version 2.00

sah 12/07/87	corrected problem with awesome i/o use
		use of addition volume label to store
 		extra storage area.

jsm 12/14/87	revision mark [3].  don't reset disk
		drive to a before calling get_args.
		changed test for success/failure of fns
		11h and 12h to testing al, not cy.
		changed method of determining program
		size to use real size, not arbitrary
		figure.  use int 21h, function 4ch to
		exit program and set error codes.

sah 03/15/88	completed and corrected jsm's 04/23/87
		changes for fats > 64k.  corrected
		verify handling of pseudo-fat for fats
		greater than 64k (ug...)

rdg 04/18/88	correct pushdir and format_pathname.
		  do not insert a '.' in pathname if the
		  directory name has no extension.
            	correct popdir.  make sure all pathnames
		  terminate with '0'
		update s_err_dir message.
		change popdir.  abort verify if
		  directory structure is to deep.
		change popd020 - temporary.  abort
		  verify if bad return from func 11 or
		  12.  this occurs when a default
		  directory is set that is exactly 64
		  characters long.
		update exit_report.  add number of
		  hidden files, number of user files
		  bytes used by hidden files, user
		  files and directories.  changes in
		  next,  next05,  next15,  pushd010,
		  exit_report.

mjs 5/16/88	moved call to check_mos_media to be after the get drive
		and get directory calls.  this corrects a the situation
		where someone does a verify of a 1.2m floppy and then
		does one on a 360k one.  having an int25 direct disk
		read be the first thing done was preventing a proper
		media check from being done.

rbr 06/01/88	modified 2 places where the segment portion of a fat
		entry address is "normalized"... we want to avoid
		problems with the 286 driver, so we now only change
		the segment portion of the address if the entry is
		more than 64k into the fat.  changes flagged ;060188.

sah 02/20/89	converted int 38 calls to int services

mjs 08/16/89	modify to insure tcbansi != 0 when issue clearscreen

mjs 11/16/89	found that for a lost chain with only one cluster, verify
		would not report.  the values in bad_sec_table were
		ff0 and fff0 rather than ff7 and fff7.  fixed these and
		removed an "and dl,11110000" from validate_rest.  also,
		made the good_fat routine return nc for (f)ff7 clusters.
		cleaned up module - made it readable and reduced file
		size from 103K to 87K.

bwr 11/30/89	marked messages for foreign language translation.

mjs 05/03/90	gutted the main tree parsing loop and the tree parsing
		loop within recurse_fsystem.  deleted pushdir, popdir,
		first_dir and next_dir.  added a new tree parsing
		method which doesn't have to use up 65 bytes in a 
		stack for each directory passed while scanning through
		any given directory.  this corrects a crash when
		more than 768 directories exist within a given 
		subdirectory.  also corrected bug with endless loop
		reporting of a crosslinked file.

----------------------------------------------------------------------^

if 01 eq 01	; to appease/fool public.com

null		equ 00			; eol terminator
false		equ 00
true		equ 01
lf		equ 10			; line feed character
cr		equ 13			; carriage return character
setdrive	equ 0eh			; set current drive
getdrive	equ 019h		; get current drive

volmask 	equ 00001000b		; volume label search mask
filmask 	equ 00011111b		; sah file search include volume
dirmask 	equ 00010000b		; directory only search mask
hidden		equ 00000010b		; hidden dir entry attribute
system		equ 00000100b		; system dir entry attribute

dirlen		equ 65			; length of asciiz directory length.
dirstk		equ 768			; maximum number of directories in stack.
dtalen		equ 512

start_cluster	equ word ptr ds:[dta+34]; offset for cluster number.
dir_file_size	equ word ptr ds:[dta+36]; offset for lsb of filesize.
file_attrib	equ byte ptr ds:[dta+19]; offset for file attribute.

	include options.inc
	include macros.inc

mosint		macro	v		;; do mos executive call
ifnb <v>				;; is variable passed to macro?
	mov	ah, v			;; assign ah to variable if so.
endif
	int	021h			;; do mos executive interrupt
endm

retc		macro			;; macro to return if carry is set
local		llabel
	jnc	llabel
	ret
llabel:
endm

callz		macro	j
local		llabel
	jnz	llabel
	call	j
llabel:
endm

callnz		macro	j
local		llabel
	jz	llabel
	call	j
llabel:
endm


begin_seg	segment para public 'begin'  ;[3] first segment in program
begin_seg	ends			;[3]

chkstack	segment stack		;; real stack segment!
	dw	512 dup(0)
chkstack	ends

tcb segment at 0
	org	00801h
tcbansi db	?			; ansi.sys emulation flag non-zero = on
tcb     ends

;----------------------------------------------------------------------
;
;  program style:
;
;  all buffers will be prefixed by b_
;  all counters will be prefixed by c_
;  all boolean flags will be prefixed by f_
;  all strings will be prefixed by s_
;
;  ds will remain the static data segment
;  es is available for use to the programmer
;
;  for the sake of simplicity and ease of future maintenance of this
;  product, please maintain these style conventions.
;
;----------------------------------------------------------------------

chkdata 	segment para public 'DATA'
	assume cs:chkcode, es:chkdata, ds:chkdata


Public  s_bad_drive, s_bad_arg, s_cls, s_crlf, s_xl01, s_xl02, s_xl03, s_frag1
Public  s_frag2, s_fragment, s_err_dirs, s_err_dir, s_invld_sub, s_help
Public  s_media_err, s_non_mos, s_sign_on, s_spec_err, s_d_toolong, s_f_toolong
Public  s_f_dir_has_ch, s_convert_lost, s_lost_clstr, s_fix, s_mos_version
Public  s_fixup_err, s_vnamstr, s_total_vfiles, s_total_hfiles, s_total_dirs
Public  s_total_frags, s_vfile_bytes, s_hfile_bytes, s_dir_bytes, s_bad_sects
Public  s_avail_bytes, s_total_bytes, s_inv_unalloc, s_inv_unalloc1
Public  s_inv_unalloc2, s_root, s_cdir, s_volprefix, s_volname, s_dotdot
Public  f_fix, f_frag, f_dfrag, f_verify, f_xlink, f_fat_modified
Public  f_dir_modified, f_dir_init, b_fats, b_fatnum, b_media, b_fatlen
Public  b_current, b_check_drive, b_exit_status, w_psp_seg, w_fragment, w_dirs
Public  w_fatsize, w_fat1, w_non_contig, w_file_count, w_hide_count
Public  w_dir_count, w_frag_count, w_file_clus, w_hide_clus, w_dir_clus, w_temp
Public  w_comma, w_dir, w_sect, w_dir_sec_off, w_last_dir_sec, w_bad_sec_cnt
Public  w_unall_clus, w_alloc_clus, w_lost_start, cshift, clusters, cluster_siz
Public  sector_siz, w_dirs_seg, w_dirs_off, extvect, curtcb, stklvl, x_off
Public  x_dir, x_dta, dta, numlen, numbuf, asciizfn, w_fat_seg, normal_fat_seg
Public  expected_size, eoc_table, eoc, file_clusters, last_cluster
Public  bad_sec_table, bad_sec_val, dir_entry, clstrcnt, chkfcb, chknum, delfcb
Public  s_extfcb, extatrb, fcb, fname, fexten, cblock, lrecsiz, fsize, fdate
Public  stuff

s_bad_drive	db  'Bad drive specified. Command aborted.             ',cr,lf,null ;@@XLAT
s_bad_arg	db  'Bad argument specified. Command ignored.         ',cr,lf,null ;@@XLAT
s_cls		db  27,'[2J',0
s_crlf		db  cr,lf,null
s_xl01		db  'WARNING: Cross-linked files exist!                    ',cr,lf,null ;@@XLAT
s_xl02		db  cr,'         Files are:   ',null ;@@XLAT
s_xl03		db  ' and ',null ;@@XLAT
s_frag1 	db  ' has   ',null ;@@XLAT
s_frag2 	db  ' non-contiguous clusters.       ',cr,lf,null ;@@XLAT
s_fragment	db  cr,lf,'Fragmented files exist in filesystem.         ',cr,lf,null ;@@XLAT
s_err_dirs	db  'Insufficent memory to run verify.  ',cr,lf,null ;@@XLAT
s_err_dir	db  'Error: Length of directory pathname exceeds legal limit.                ',cr,lf  ; 041888 ;@@XLAT
           	db	'       Verify Aborted!    ',cr,lf,null  ; 041888 ;@@XLAT
s_invld_sub	db  'Invalid Subdirectory!       ',cr,lf,null ;@@XLAT
s_help		db  'VERIFY verifies the disk system for file allocation errors             ',cr,lf ;@@XLAT
	db	'and displays any errors found. If the /f option is requested           ',cr,lf ;@@XLAT
	db	'VERIFY will attempt to fix errors and write them back to disk.         ',cr,lf ;@@XLAT
	db	'For more information refer to PC-MOS users guide.                      ',cr,lf,lf ;@@XLAT
	db	'VERIFY /c         Display any non-contiuous files.                     ',cr,lf ;@@XLAT
	db	'VERIFY /f         Fix any errors found on disk.                        ',cr,lf ;@@XLAT
	db	'VERIFY /h         Display this help screen.                            ',cr,lf ;@@XLAT
	db	'VERIFY /v         Display files as checked.                            ',cr,lf,null ;@@XLAT
s_media_err	db  'Disk Error: Unable to read boot sector of specified drive.             ',cr,lf ;@@XLAT
	db	'            Make sure drive is ready and try again.                    ',cr,lf,null ;@@XLAT
s_non_mos	db  'Disk Error: Suspected NON-MOS disk accessed.                           ',cr,lf ;@@XLAT
	db	'            Cannot continue until disk can be identified.              ',cr,lf,null ;@@XLAT
s_sign_on	db  '                              PC-MOS VERIFY v4.00',cr,lf  ; 041888 ;@@XLAT
	db	'         (c) Copyright 1987, 1988, 1989'  ; 041888 ;@@XLAT
	db	' The Software Link, Incorporated',cr,lf  ; 041888 ;@@XLAT
	db	'                         All rights reserved worldwide',cr,lf,lf,null  ; 041888 ;@@XLAT
s_spec_err	db  'Unable to get disk specifications.                   ',cr,lf,null ;@@XLAT
s_d_toolong	db  ' directory file size adjusted to match FAT cluster count.           ',cr,lf,null ;@@XLAT
s_f_toolong	db  ' FAT allocation chain truncated to match file size.                 ',cr,lf,null ;@@XLAT
s_f_dir_has_ch	db  'Dir entry of zero length file has FAT chain; released.                    ',cr,lf,null ;@@XLAT
s_convert_lost	db  'Lost cluster chain converted to file.                          ',cr,lf,null ;@@XLAT
s_lost_clstr	db  'Lost cluster found in chain.                                ',cr,lf ;@@XLAT
	db	'Restart VERIFY using /f option to convert to file.                     ',cr,lf,null ;@@XLAT
s_fix		db  '/F option chosen.        ',cr,lf,null ;@@XLAT

s_mos_version	db  'Incorrect MOS Version!    ',cr,lf,null ;@@XLAT

s_fixup_err	db  'Warning:   ',cr,lf ;@@XLAT
	db	'You may not use the /F option while there are other tasks           ',cr,lf ;@@XLAT
	db	'running under MOS. Severe disk errors can result if you are         ',cr,lf ;@@XLAT
	db	'allowed to continue. Please alert all users and remove all          ',cr,lf ;@@XLAT
	db	'other tasks and re-start VERIFY.                            ',cr,lf,null ;@@XLAT

s_vnamstr	db  '                           Volume ID of ',null  ; 041888 ;@@XLAT
s_total_vfiles	db  '        Number of Visible Files on volume:    ',null  ; 041888 ;@@XLAT
s_total_hfiles	db  '        Number of Hidden Files on volume:     ',null  ; 041888 ;@@XLAT
s_total_dirs	db  '        Number of Directories on volume:      ',null  ; 041888 ;@@XLAT
s_total_frags	db  '        Number of Fragmented Files on volume: ',null  ; 041888 ;@@XLAT
s_vfile_bytes	db  '        Bytes in Visible Files on volume:     ',null  ; 041888 ;@@XLAT
s_hfile_bytes	db  '        Bytes in Hidden Files on volume:      ',null  ; 041888 ;@@XLAT
s_dir_bytes	db  '        Bytes in Directories on volume:       ',null  ; 041888 ;@@XLAT
s_bad_sects	db  '        Bytes of Defective Space on volume:   ',null  ; 041888 ;@@XLAT
s_avail_bytes	db  '        Bytes Available on volume:            ',null  ; 041888 ;@@XLAT
s_total_bytes	db  '        Total Capacity of volume:             ',null  ; 041888 ;@@XLAT
s_inv_unalloc	db  'Invalid cluster number   ',null ;@@XLAT
s_inv_unalloc1	db  ' in Allocation table position ',null ;@@XLAT
s_inv_unalloc2	db  '.',cr,lf,null
s_root		db  '\',null
s_cdir		db  65 dup (0)		; startup directory storage area.
s_volprefix	db  8 dup (0)
s_volname	db  'No Label    ',null	; current volume name. ;@@XLAT
	db	22 dup (0)
s_dotdot db	'..',0

f_fix		db  0			; if true then write fixup data to disk.
f_frag		dw  0			; true if the current file is frag'd.
f_dfrag 	db  0			; true if fragmented files are displayed.
f_verify	db  0			; if true then display status during operation.
f_xlink 	db  0			; cross linked files found.
f_fat_modified	db  0			; true if in-memory fat has been corrected.
f_dir_modified	db  0			; true if individual directory was corrected.
f_dir_init	db  0			; true if we have created dir mask fcb.

b_fats		db  0			; number of fats on device.
b_fatnum	db  0			; current fat in fat segment.
b_media 	db  0			; device media descriptor byte.
b_fatlen	db  0			; length of each fat in sectors.
b_current	db  0			; start up drive.
b_check_drive	db  0			; drive to check.
b_exit_status	db  2			;[3] exit status (assume bad error)

w_psp_seg	dw  0			; segment of psp base segment.
w_fragment	dw  0			; count of files fragmented in system.
w_dirs		dw  0			; number of root directory entries.
w_fatsize	dw  0			; fatsize (0=1.5, 1=2, etc).
w_fat1		dw  0			; start sector of fat #1.
w_non_contig	dw  0			; non-contiguous cluster count.
w_file_count	dw  0			; file counter.
w_hide_count	dw  0			; hidden file counter.
w_dir_count	dw  0			; dir counter.
w_frag_count	dw  0			; fragmented file counter.
w_file_clus	dw  0			; clusters used by visible files ; 041888
w_hide_clus	dw  0			; clusters used by hidden files  ; 041888
w_dir_clus	dw  0			; clusters used by directories   ; 041888
w_temp		dw  0			; temporary used by divide32.
w_comma 	dw  0			; comma counter for 32-bit decimal output.
w_dir		dw  0			; start sector of directory.
w_sect		dw  0			; current sector in  w_dirs_seg buffer.
w_dir_sec_off	dw  0
w_last_dir_sec	dw -1
w_bad_sec_cnt	dw  0
w_unall_clus	dw  0
w_alloc_clus	dw  0
w_lost_start	dw  0
cshift		db  0			; sector shift count
clusters	dw  0			; number of clusters on drive.
cluster_siz	dw  0			; number of sectors in cluster.
sector_siz	dw  0			; number of bytes in sector.
w_dirs_seg	dw  0			; directory stack segment.
w_dirs_off	dw  0			; next entry space.
extvect		dd	0		; pointer to extended services handler
curtcb		dw	0		; segment of current tcb
stklvl		db	0		; nest level 

x_off		dw  0			; xlinked dirs offset preserve area.
x_dir		db  66 dup(0)		; xlinked directory preserve area.
x_dta		db  dtalen dup(0)	; xlinked dta preserve area.
dta		db  dtalen dup (?)

numlen		db  0			; length of string in [numbuf]
numbuf		db  20 dup (0)		; asciiz number conversion buffer.
asciizfn	db  128 dup(0)		; asciiz file name buffer
w_fat_seg	dw  0			; segment base of fat table buffer
normal_fat_seg	dw  0			; segment of dummy 16bit fat table
expected_size	dw  0

eoc_table	dw  0fffh		; end of cluster values for 12&16 fat
	dw	0ffffh
eoc		dw  0			; end of cluster value for current disk.
file_clusters	dw  0			; cluster count of current file.
last_cluster	dw  0			; last cluster processed by mark_fat_chain

bad_sec_table	dw  00ff7h		; bad cluster values for 12&16 bit fat.
	dw	0fff7h
bad_sec_val	dw  0
dir_entry	db  32 dup (0)
clstrcnt	dw  0			; number of cluster files written.
chkfcb		db  0,'LOSTDAT'		; lost cluster file control block.
chknum		db  '0000',24 dup (0)	; number buffer

delfcb		db  0,'LOSTDAT????',24 dup (0)

s_extfcb	db  0ffh		; extended fcb flag byte.
	db	0,0,0,0,0		; who knows what is here.
extatrb 	db  00000000b		; extended attribute.
fcb		db  0			; fcb drive number.
fname		db  '????????'		; file name.
fexten		db  '???'		; file extension.
cblock		dw  0			; current block of file pointer.
lrecsiz 	dw  0			; logical record size.
fsize		dd  0			; file size in bytes.
fdate		dw  0			; last change date of file.
stuff		db  12 dup(0)		; other stuff.

;   offsets into structure returned from mosint 032h
dbp		struc
xdrive		db  0			;logical drive.
xunit		db  0			;driver unit number.
xssize		dw  0			;sector size.
xcmask		db  0			;cluster mask.
xcshift 	db  0			;cluster shift count.
xfat1		dw  0			;fat 1 start sector.
xfnum		db  0			;number fat's.
xdnum		dw  0			;number root dir entries.
xdata1		dw  0			;cluster 2 start sector.
xcnum		dw  0			;number of clusters + 1
xfsize		db  0			;fat size in sectors.
xdir1		dw  0			;directory start sector.
xdriver 	dd  0			;address of device driver.
xmedia		db  0			;media byte.
xfirst		db  0			;first access?
xnext		dd  0			;next dpb.
xcd		db  64 dup(0)		;current directory.
dbp		ends

;	*****	end of data segment   *****

chkdata 	ends

endif		; end of action taken to appease/fool public.com

chkcode 	segment para public 'CODE'
	assume cs:chkcode, es:chkdata, ds:chkdata

	include	verify.pub

	subttl verify - disk allocation check routine
	page
;======================================================================
; .func: verify - disk allocation check routine
;
; input:
;
; output:
;
; comments:
;  	check disk main entry point.
;	free unneeded memory.
;	get current drive
;	parse command line tail.
;	    change drive if specified.
;	set specified drive if requested in command tail.
;	preserve current directory.
;	set current directory to root directory.
;	get drive specifications.
;	get current drive label name.
;	allocate data segment for fat table and load fat table.
;	allocate directory stack area.
;
;	restore current directory.
;	restore current drive.
;	return to mos.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
verify:
	mov	bx, offset end_of_code+15  ; calculate end of code
	mov	cl,4
	shr	bx, cl
	add	bx, seg chkcode		; add to start of code segment
	sub	bx, seg begin_seg	;[3]
	add	bx,10h			;[3] remember the psp
	mosint	04ah			; mos shrink mem block function.
	mov	bx, ds
	mov	ax, seg chkdata		; get data segment address.
	mov	ds, ax			; set up our data segment.
	mov	w_psp_seg, bx		; store base of psp.
	mov	bx, (dirlen*dirstk+15)/16  ; allow dirstk levels on stack.
	mosint	048h			; allocate dir stack area.
	jnc	chk005			; abort on error.
	mov	dx, offset s_err_dirs	; get allocation error msg
	call	printline		; print it.
	jmp	exit_err1		;[3] abort process.
chk005:
	mov	w_dirs_seg, ax		; preserve directory segment
	mov	w_dirs_off, 00		; reset offset pointer.
	push	ax
	push	bx
	push	es
	mosint	34h
	les	bx,es:[bx-18h]		; initialize extvect by
	mov	word ptr [extvect],bx	; indirect access to
	mov	word ptr [extvect+2],es	; mos's SCB data structure.
	mov	ah,4
	mov	bx,-1
	pushf				; call mos's extended services
	cli				; using the local vector
	call	[extvect]
	assume	es:tcb
	mov	bl,[tcbansi]		; get current ansi emulation
	mov	[tcbansi],0ffh		; put system in ansi emulation
	mov	dx, offset s_cls
	call	printline
	mov	[tcbansi],bl
	pop	es
	assume	es:chkdata
	pop	bx
	pop	ax
	mov	dx, offset s_sign_on	; get signon message.
	call	printline		; print it
	mosint	getdrive		; get current logged drive
	mov	b_check_drive, al	; assume current drive for now.
	mov	b_current, al		; store it.
	mosint	30h			; get mos version number
	push	bx
	mov	ax, 3000h
	mov	bx, ax
	mov	cx, ax
	mov	dx, ax
	mosint	30h			; get mos version number
	pop	cx
	cmp	bx, cx			; compare both returned values.
	jnz	chk003
	mov	dx, offset s_mos_version
	call	printline
	jmp	exit_err1		;[3] exit if we are running on pcdos
chk003:
	call	get_args		; get command tail arguments.
	ljc	exit_err		; also sets specified drive.
	mov	si, offset s_cdir+1	; get current directory store area
	mov	dl, b_check_drive	; get check drive number
	inc	dl			; make base 1
	mosint	047h			; mos get current directory.
	mov	byte ptr s_cdir, '/'	; precede with backslash
	mov	dx, offset s_root	; get root dir asciiz string addr.
	mosint	03bh			; mos set current directory.
	ljc	exit_err		; skip to exit on error.
	call	check_mos_media		; verify that device is mos media!
	ljc	exit_err		; exit if disk appears to be foreign
	cmp	f_fix, 0		; do we need to delete old files?
	callnz	delete_old_chk_files	; delete all \chk0????.err files.

;	get volume name of current device, and write it to s_volname buffer
;	buffer should already default to no label on entry.
;	routine assumes that we are logged into desired drive and are in
;	the root directory.

	mov	dx, offset s_volprefix	; point to volume name buffer.
	mosint	01ah			; set disk transfer address.
	mov	extatrb, volmask	; set volume name bit.
	mov	dx, offset s_extfcb	; point to extended fcb.
	mosint	011h			; perform search for first.
	mov	byte ptr [s_volname+11], 0

	call	get_specs		; get disk specifications.
	ljc	exit_err		; skip to exit on error.
	xor	ax, ax
	mov	al, byte ptr b_fatlen	; get fat length in sectors
	mov	bx, sector_siz
	mul	bx			; multiply by sector size
	mov	cx, 4			; jsm 4/23/87
fatll1:
	shr	dx, 1
	rcr	ax, 1
	loop	fatll1			; convert to paragraphs
	mov	bx, ax			; put it in bx
	inc	bx
	push	ds
	mosint	48h			; allocate fat segment.
	mov	w_fat_seg, ax		; store segment base.
	pop	ds
	ljc	exit_err		; abort on allocation error.
	call	read_fat		; read fat into ram.
	jnc	first			; sah 08/20/87 abort on error.
	lea	dx, s_err_dirs		; sah insuficent memory
	call	printline		; sah
	jmp	exit_read		; sah abort verify
first:
	mov	[b_exit_status],0	;[3] normal exit code
	mov	dx,offset dta
	mosint	1ah
dlp1:
	call	process_files		; process all file in current dir
	mov	[extatrb],00010111b	; find all directories
	mov	dx,offset s_extfcb
	mosint	11h
dlp3:
	cmp	al,0			; when al != 0, done with current dir
	jz	dlp5
	cmp	[stklvl],0		; need to restore to previous dir?
	lje	dlp2
	mov	dx,offset s_dotdot
	mosint	3bh			; back up to parent
	dec	[stklvl]
	call	restore_pos		; restore the fcb search data
	jmp	short dlp6
dlp5:

; filter out all but honest-to-goodness directories

	test	byte ptr [dta+19],dirmask
	jz	dlp6
	cmp	byte ptr [dta+8],'.'	; skip . and .. at this point
	je	dlp6
	call	save_pos		; save fcb search data
	inc	[stklvl]		; update depth record
	mov	di,offset asciizfn	; convert dta name to asciiz
	call	dtanam2z
	mov	dx,offset asciizfn	; and change to that directory
	mosint	3bh
	inc	w_dir_count		; increment directory counter.
	call	process_dir		; process the current directory

; verify .

	mov	[extatrb],00010111b	; find all directories
	mov	dx,offset s_extfcb
	mosint	11h
	or	al,al
	jnz	dlp4
	test	byte ptr [dta+19],dirmask
	jz	dlp7
	cmp	byte ptr [dta+8],'.'
	jne	dlp7

; verify ..

	mov	dx,offset s_extfcb
	mosint	12h			; find the next entry
	or	al,al
	jnz	dlp4
	test	byte ptr [dta+19],dirmask
	jz	dlp7
	cmp	byte ptr [dta+8],'.'
	jne	dlp7
	cmp	byte ptr [dta+9],'.'
	jne	dlp7
	jmp 	dlp1
dlp6:
	mov	dx,offset s_extfcb
	mosint	12h			; find the next entry
	jmp 	dlp3
dlp4:
	mov	dx, offset asciizfn	; otherwise...
	call	printline		; print error message on console
	call	docrlf
	call	docrlf
	mov	dx, offset s_err_dir
	jmp	short dlp8
dlp7:
	mov	dx, offset s_invld_sub
	call	printline		; print error message
	mov	dx, offset asciizfn	; get bad file name
dlp8:
	call	printline		; print it.
	jmp	exit_read		; no use to carry on
dlp2:
	call	validate_rest		; perform fat unused validation.
	call	exit_report		; perform final statistics display.
exit_read:
	mov	dx, offset s_cdir	;sah 08/20 get saved directory area.
	mosint	03bh			; mos set current directory.
	mosint	0dh			; reset the disk system.
exit_err:
	mov	dl, b_current		; get current drive!
	mosint	setdrive		; restore original drive.
exit_err1:
	mov	al,[b_exit_status]
	mov	ah,4ch
	int	21h			; return to mos


	subttl get_args - process command line arguments
	page
;======================================================================
; .func: get_args - process command line arguments
;
; input:
;
; output:
;	[f_fix] set true if '/f' in command tail.
;	[f_verify] set true if '/v' in command tail.
;	[f_dfrag] set true if /c in command tail.
;	cf set true if error occurred
;
; comments:
;
;	get_args - get arguments passed in the command line.
;
;	this function parses the command line tail to determine the options
;	requested by the user.
;
;	mos passes command tail in [psp_seg]:80
;	first byte is length of command tail
;
;	x:	set drive specifier ( assume current drive if not found )
;	/f	set fix flag to true.
; 	/v	set verify flat to true.
;	/h	display help screen
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
get_args:
	mov	si, 080h		; set offset
	mov	al, es:[si]		; get command tail length
	or	al, al			; check for no tail
	jnz	ga_10			; nothing to parse...
	xor	ax, ax			; clear error report
	clc
	ret				; and return to caller.
ga_10:
	xor	cx, cx			; clear counter.
	mov	cl, al			; move length to counter.
	inc	si			; increment input pointer.
ga_20:
	mov	al, es:[si]		; get a byte.
	cmp	al, ' '			; is it a space?
	jz	ga_35			; then skip it.
	cmp	al, '/'			; is it a slash?
	jz	slash			; check for user flag.
	cmp	al, ':'			; is it a colon?
	jz	colon			; check for drive letter.
	cmp	al, '?'			; do they want help?
	jnz	ga_35			; display help as requested.
	cmp	al, '.'			; ignore wildcard characters.
	jz	ga_35
	cmp	al, '?'			; ignore wildcard characters
	jz	ga_35
	cmp	al, '*'			; ignore wildcard characters
	jz	ga_35
ga_25:
	mov	dx, offset s_help	; get help screen string
	call	printline		; print it.
	mov	[b_exit_status],1	;[3] error code for exit
	stc				; set carry flag
	ret				; return to main loop
ga_35:
	inc	si			; increment input pointer
	dec	cx			; decrement length counter
	jnz	ga_20			; loop until counter is zero.
	clc
	ret				; return to caller.
slash:
	inc	si			; skip over slash character
	dec	cx			; sah 08/18/87 dec counter
	mov	al, es:[si]		; get character from tail.
	call	ucase			; uppercase character
	cmp	al, 'V'			; is it verify flag?
	jnz	fragchk			; continue if not...
	mov	f_verify, true		; set verify flag
	jmp	ga_35			; loop back around.
fragchk:
	cmp	al, 'C'			; is it non-contig?
	jnz	fixup			; continue if not...
	mov	f_dfrag, true		; set display flag true.
	jmp	ga_35			; loop back around.

; warning:
; if the user asks for the fixup option you must check to see if there 
; are any other tasks running on the system.  if there are then you 
; must not allow the user to write any changes to the fat or dir entries. 
; if there are any files open in the system and are being written sequentially
; then a problem will arise. the fixup option will truncate the newly 
; written part to the end as pointed to by the dir entry. this will 
; cause loss of data and possibly cross linked files! allow the 
; user to perform /f only if there are no other tasks running under mos!

fixup:
	cmp	al, 'F'			; is it fixup flag?
	jnz	helpdisp		; continue if not.
	push	es
	push	ax
	mov	ah, 02h			; get mos task control block
	int	services
	mov	dx, es:[bx]		; get pointer to first tcb
	inc	bx
	inc	bx			; and compare it to last tcb
	cmp	dx, es:[bx]		; if they are alike then continue
	pop	ax
	pop	es
	jz	fix_go
	mov	dx, offset s_fixup_err	; print error message
	call	printline
	jmp	ga_35			; skip to next char.
fix_go:
	mov	f_fix, true		; set fix flag true.
	jmp	ga_35			; loop back around.
helpdisp:
	cmp	al, 'H'			; do they want help?
	jz	ga_25			; go to help display options
invalid:
	mov	dx, offset s_bad_arg	; get bad argument string
	call	printline		; and print it.
	jmp	ga_35			; return to loop.
colon:
	mov	al, es:[si-1]		; get previous character
	call	ucase
	sub	al, 'A'
	mov	dl, al			; put drive number in dl
	mosint	setdrive		; do set drive function
	mosint	getdrive		; do get drive function
	cmp	dl, al			; are they the same?
	jnz	bad_drv			; report bad drive.
	mov	b_check_drive, al	; store good drive.
	jmp	ga_35			; loop around for more..
bad_drv:
	mov	dx, offset s_bad_drive	; get bad drive string
	call	printline		; print it
	stc				; set carry flag to report error
	ret				; return to caller


	subttl get_specs - get drive specifications.
	page
;======================================================================
; .func: get_specs - get drive specifications.
;
; input:
;	dl = drive letter (0=default..a=1)
;	be sure to preserve ds before entry.
;
; output:
;	ds:bx points to device descriptor table.
;	cf set true if error occurred
;
; comments:
;
;	drive specifications are returned to caller by pointing ds:bx to
;	the disk param block. this is a un-documented function according
;	to jim bean.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
get_specs:
	push	es
	push	ds			; save data segment
	mov	dl, b_check_drive	; get drive (a=0
	inc	dl			; a=1...
	mosint	032h			; special mos function.
	push	ds			; save returned pointer.
	pop	es			; put it in es:
	pop	ds			; restore data segment
	or	al, al			; is al zero?
	jnz	gs_error		; if not then report error.
	assume	es:nothing
	mov	dx, word ptr es:[bx].xfat1  ; start sector number of fat
	mov	w_fat1, dx
	xor	ax, ax
	mov	al, byte ptr es:[bx].xfsize  ; fat length in sectors.
	mov	b_fatlen, al		; store fat length.
	mov	dx, word ptr es:[bx].xssize  ; sector size in bytes.
	mov	sector_siz, dx
	mov	dx, word ptr es:[bx].xdir1  ; get directory start sector
	mov	w_dir, dx
	mov	al, byte ptr es:[bx].xcmask  ; mask is sectors/cluster-1
	mov	al, byte ptr es:[bx].xfnum  ; number of fat's
	mov	b_fats, al
	mov	ax, word ptr es:[bx].xdnum  ; number of root directory entries
	mov	w_dirs, ax
	mov	ax, word ptr es:[bx].xcnum  ; number of clusters + 1
	dec	ax			; sah actual # of clusters
	mov	clusters, ax		; store cluster count.
	cmp	ax, 4087		; is drive smaller than 4087 clusters?
	jb	gs0028			; if below, assume 12 bit fat.
	mov	w_fatsize, 1		; otherwise indicate 16 bit fat.
gs0028:
	mov	cl, byte ptr es:[bx].xcshift
	mov	cshift, cl
	add	ax, word ptr es:[bx].xdata1  ; address of start of data clusters (cluster 2)
	mov	al, byte ptr es:[bx].xmedia  ; media desriptor byte
	mov	b_media, al
gs0030:
	assume	es:chkdata
	pop	es			; restore es
	or	ax, ax			; clear error return flag (cf)
	ret				; return to caller
gs_error:
	pop	es			; restore es
	mov	dx, offset s_spec_err	; get error message addr
	call	printline		; print it.
	stc				; return with cf set.
	ret


	subttl dtanam2z - xfer dta filename to asciiz buffer
	page
;======================================================================
; .func: dtanam2z - xfer dta filename to asciiz buffer
; 
; input:	
; 	es:di -> buffer for asciiz string
;
; output:
;
; comments:
; 
; .calls: 
; .reads: 
; .writes: 
; 
; .endfn
;======================================================================
dtanam2z:
	pushset ax,cx,si,di,es
	mov	cx,ds
	mov	es,cx
	mov	si,offset dta+8
	mov	cx,8			; xfer up to 8 chars for fname
dnz1:
	lodsb
	cmp	al,' '
	je	dnz2
	stosb
	loop 	dnz1
dnz2:
	mov	si,offset dta+16	; advance to extension
	cmp	byte ptr [si],' '
	jne	dnz3
	xor	al,al
	stosb				; if no ext, all done
	jmp	short dnz4
dnz3:
	mov	al,'.'
	stosb				; insert seperator
	mov	cx,3
dnz6:
	lodsb				; xfer up to 3 characters
	cmp	al,' '
	je	dnz7
	stosb
	loop 	dnz6
dnz7:
	xor	al,al
	stosb
dnz4:
	popset ax,cx,si,di,es
	ret


	subttl save_pos - record fcb search data
	page
;======================================================================
; .func: save_pos - record fcb search data
;
; input:
;	ds -> segment for s_extfcb
;
; output:
; 
; comments:
; 	crashes ax and bx
; 	mos places the following position data within the fcb:
;
; extfcb+19	byte	search attribute
; extfcb+20	word	offset into sector
; extfcb+22	word	low part of sector #
; extfcb+24	word	high part of sector #
; extfcb+26	byte	drive #
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
save_pos:
	pop	bx
	mov	ax,word ptr [s_extfcb+19]
	push	ax
	mov	ax,word ptr [s_extfcb+21]
	push	ax
	mov	ax,word ptr [s_extfcb+23]
	push	ax
	mov	ax,word ptr [s_extfcb+25]
	push	ax
	jmp	bx


	subttl restore_pos - restore search data to fcb
	page
;======================================================================
; .func: restore_pos - restore search data to fcb
;
; input:
;	ds -> segment for s_extfcb
;
; output:
;
; comments:
; 	crashes ax and bx
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
restore_pos:
	pop	bx
	pop	ax			; restore search pos
	mov	word ptr [s_extfcb+25],ax
	pop	ax
	mov	word ptr [s_extfcb+23],ax
	pop	ax
	mov	word ptr [s_extfcb+21],ax
	pop	ax
	mov	word ptr [s_extfcb+19],ax
	jmp	bx


	subttl process_dir - process the current directory 
	page
;======================================================================
; .func:  process_dir - process the current directory 
; 
; input:	
; 
; output:	
;
; comments:
; 
; .calls: 
; .reads: 
; .writes: 
; 
; .endfn
;======================================================================
process_dir:
	mov	f_frag,0
	call	mark_fat_chain
	call	update_counts
	ret

	subttl process_files - process each entry within the current dir
	page
;======================================================================
; .func:  process_files - process each entry within the current dir
; 
; input:	
; 
; output:	
;
; comments:
; 
; .calls: 
; .reads: 
; .writes: 
; 
; .endfn
;======================================================================
process_files:

; setup for loop to find all files within the current directory

	call	save_pos
	mov	[extatrb],00000111b	; find all files
	mov	dx,offset s_extfcb
	mosint 11h
pts1:
	cmp	al,0			; end of current directory?
	jne	pts2

; processing for each file entry goes here

	test	byte ptr [dta+19],hidden
	jz	pts3
	inc	w_hide_count
	jmp	short 	pts4
pts3:
	inc	w_file_count
pts4:
	mov	al,f_dfrag
	or	al,f_verify		; do they want to see operations
	callnz format_pathname		; format file name if so
	mov	f_frag,0		; reset fragmented file flag
	call	mark_fat_chain		; check allocation chain.
	call	update_counts		; update count of files, etc.
	call	print_filename_stuff	; display file stuff if needed.

	mov	dx,offset s_extfcb
	mosint 12h			; find the next entry
	jmp 	pts1
pts2:
	call	restore_pos
	ret


	subttl read_fat - read fat from current drive into fat segment.
	page
;======================================================================
; .func: read_fat - read fat from current drive into fat segment.
;
; input:
;
; output:
;
; comments:
;
;	this function will read the fat from the current drive into the
;	allocated fat segment. if it is called again, it reads the next
;	fat into the fat segment. this routine will read as many fats as
;	are on the device.  reads fats of up to 256 sectors ok
;
;	allocate fat segment large enough to hold one fat. load first fat
;	into fat segment.
;	allocate cluster buffer and initialize it to zeros.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
read_fat:
	push	ds
	mov	al, b_check_drive	; get current drive number.
	xor	cx, cx
	mov	cl, b_fatlen		; get fat length in sectors.
	push	cx			; remember this when ds is gone
	cmp	cl, 80h
	jbe	rdf10			; if fat fits in 64k
	mov	cl, 80h			; it doesn't fit, read 64K
rdf10:
	mov	dx, w_fat1		; get fat start sector number.
	mov	ds, w_fat_seg		; set data segment
	xor	si, si
	mov	di,0fffch
	xor	bx, bx			; set up ds:bx to allocated fat seg.
	push	ax
	push	dx
	int	25h			; mos abs read fn.
	popf				; restore flags.
	pop	dx			; restore sector number
	pop	ax			; disk number
	pop	cx			; and fat length
	sub	cx, 80h
	jle	rdf20			; if fat <= 64k

; fat bigger than 64k, read the rest of it.
; ax is ok as is, cx already has number of sectors to read.

	add	dx,80h			; next sector number is 80h greater
	mov	bx,ds
	add	bx,1000h		; advance ds 4096 paras (64k)
	mov	ds,bx
	xor	bx,bx			; offset in new segment is 0
	xor	si,si			; high word of sector should be 0
	mov	di,0fffch
	int	25h			; read the rest of the blocks
	popf				; get rid of flags
rdf20:
	pop	ds			; restore our data segment.

; build 16bit fat buffer and initialize it to zeros.

	mov	bx, clusters		; allocate space for the normalized
	add	bx, 9			; sah take acount for 2 at beginning
	mov	cl, 3
	shr	bx, cl
	mosint	48h
	retc				; return on allocation error
	mov	normal_fat_seg, ax
	push	es			; initialize the normalized fat table
	mov	es, ax			; to zeroes.
	xor	ax, ax
	mov	cx, clusters
	inc	cx			; sah
	inc	cx			; sah
	mov	di, ax

; following fix initializes pseudo-fat (ug...)	for fat > 64k

	cmp	cx,8000h
	jbe	rdfatfix
	sub	cx,8000h
	push	cx
	mov	cx,8000h
	rep	stosw
	pop	cx
	mov	di,es
	add	di,1000h
	mov	es,di
	xor	di,di
rdfatfix:
	rep	stosw
	pop	es
	mov	bx, w_fatsize		; set variable eoc to current
	shl	bx, 1			; end of cluster chain marker
	mov	ax, eoc_table[bx]	; (00fffh for 12-bit fat and
	mov	eoc, ax			;  0ffffh for 16-bit fat).
	mov	ax, bad_sec_table [bx]	; do the same for the bad sector
	mov	bad_sec_val, ax		; value.
	clc				; clear carry (error flag)
	ret				; return to caller.


	subttl write_fat - write current copy of fat in w_fat_seg to disk.
	page
;======================================================================
; .func: write_fat - write current copy of fat in w_fat_seg to disk.
;
; input:
;
; output:
;
; comments:
;
;	if [f_fix] is false, then skip write, fixup is ignored.
;	if [f_fat_modified] is false, then skip write, no fixup is needed.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
write_fat:
	push	ds
	mov	al, byte ptr f_fix
	or	al, al
	jz	write_exit		; exit if fat is not to be written
	cmp	f_fat_modified, 0	; has fat been changed?
	jz	write_exit		; exit if not.
	mov	al, b_check_drive	; get current drive number.
	xor	cx, cx
	mov	cl, b_fatlen		; get fat length in sectors.
	push	cx			; save for after int 26 call
	cmp	cl, 80h
	jbe	wrf10			; if fat fits in 64k
	mov	cl,80h			; if too big, read first 64k
wrf10:
	mov	dx, w_fat1		; get fat start sector number.
	mov	ds, w_fat_seg		; set data segment
	xor	si, si
	mov	di,0fffch
	xor	bx, bx			; set up ds:bx to allocated fat seg.
	push	ax
	push	dx
	int	26h			; mos abs read fn.
	popf				; restore flags.
	pop	dx			; remember sector number
	pop	ax			; disk number
	pop	cx			; and fat length
	sub	cx,80h
	jle	write_exit		; if fat < 64k & all written now

; write part of fat above 64k.

	add	dx,80h			; next sector is 80h further.
	mov	bx,ds			; advance ds by 64k (4096 paragraphs)
	add	bx,1000h
	mov	ds,bx
	xor	bx,bx			; offset in segment is 0
	xor	si,si			; high word of sector will be 0
	mov	di,0fffch
	int	26h			; write the rest of it
	popf
write_exit:
	pop	ds			; restore our data segment.
	ret


	subttl get_fat - get cluster number for specified fat entry.
	page
;======================================================================
; .func: get_fat - get cluster number for specified fat entry.
;
; input:
;	bx  fat entry number (2..xx)
;
; output:
;	ax  cluster number
;
; comments:
;
;	return specified cluster data depending on whether the fat is 12 or
;	16 bit fat.
;	all registers but ax preserved.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
get_fat:
	push	bx
	push	cx
	push	dx
	push	di
	push	es
	mov	es, w_fat_seg
	mov	ax, w_fatsize
	or	ax, ax
	jz	get_12bit_fat

; get 16-bit fat entry.  calculate segment & byte offsets.

	mov	ax,es			; we will do arithmetic on segment
	mov	di, bx			; save for byte offset calculation
	mov	cl,3
	shr	bx,cl			; convert to normalized segment
	and	bx,1000h		;060188  bit 12 on only if > 64k fat
	add	ax,bx
	mov	es,ax			; es is now segment in fat
	shl	di, 1
	mov	ax, word ptr es:[di]	; get word from fat buffer.
	jmp	get_fat_exit

;     get 12-bit fat entry.

get_12bit_fat:
	call	calc_12bit
	mov	ax, word ptr es:[di]	; get word from fat buffer.
	test	bl, 1			; is it odd or even fat entry?
	jz	gf55
	mov	cl, 4
	shr	ax, cl			; discard lsb nybble
	jmp	get_fat_exit
gf55:
	and	ah, 0fh			; discard msb nybble
get_fat_exit:
	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	ret				; return to caller


	subttl put_fat - set cluster number for specified fat entry.
	page
;======================================================================
; .func: put_fat - set cluster number for specified fat entry.
;
; input:
;	ax = cluster number
;	bx = fat entry number (2..xx)
;
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
put_fat:
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	es
	mov	es, w_fat_seg
	mov	dx, ax
	mov	ax, w_fatsize
	or	ax, ax
	jz	put_12bit_fat

; write to a 16 bit fat.

	mov	ax,es			; we will do arithmetic on segment
	mov	di, bx			; save for byte offset calculation
	mov	cl,3
	shr	bx,cl			; convert to normalized segment
	and	bx,1000h		;060188  bit 12 on only if > 64k fat
	add	ax,bx
	mov	es,ax			; es is now segment in fat
	shl	di, 1
	mov	es:[di], dx		; put it back
	jmp	put_fat_exit

put_12bit_fat:	call	calc_12bit
	mov	ax, es: [di]
	test	bl, 1
	jnz	pf55
	and	ax, 1111000000000000b
	jmp	pf60
pf55:
	and	ax, 0000000000001111b
	mov	cl, 4
	shl	dx, cl
pf60:
	or	ax, dx
	mov	es: [di], ax		; put it back
put_fat_exit:
	pop	es			; restore es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret				; return to caller


	subttl calc_12bit - calc offset into fat table for 12bit fat entry
	page
;======================================================================
; .func: calc_12bit - calc offset into fat table for 12bit fat entry
;
; input:
;	bx = fat entry number
;
; output:
;	di = offset into real fat buffer based zero.
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
calc_12bit:
	push	dx
	mov	ax, 3			; di = bx * 3 / 2
	mul	bx
	shr	ax, 1
	mov	di, ax
	pop	dx			; restore used registers.
	ret

	
	subttl mark_fat_chain - mark clusters used by file in pseudo-fat.
	page
;======================================================================
; .func: mark_fat_chain - mark clusters used by file in pseudo-fat.
;
; input:
;	  dta set to directory entry of file to scan and mark.
;
; output:
;	  carry flag set if error.
;	  ax  error code.
;
; comments:
;
;	this routine does a number of things, including:
;	look for cross-linked fat chains.
;	verify the actual file (data) size against the value stored
;	in the directory.
;	call various correction and identification routines in the
;	event that an error is detected.
;	all registers but ax preserved.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
mark_fat_chain:
	push	bx
	push	dx
	push	di
	push	es			; set up access to normal fat segment.
	mov	es, normal_fat_seg
	call	calc_exp_size		; calculate expected size of file in clusters
	or	ax, ax			; if non-zero, skip.
	jnz	mark_fat_nonz
	mov	ax, start_cluster	; if starting cluster of file is
	or	ax, ax			; also zero, then everything is okay
	ljz	mark_fat_okay		; so exit.
mark_fat_nonz:
	mov	file_clusters, 0	; initialize file cluster counter.
	mov	ax, start_cluster	; get starting cluster from directory.
	or	ax, ax			; no clusters in file (or a directory)?
	ljz	mark_fat_exit
	call	good_fat		; check starting cluster number.
	jnc	mark_fat_begin
	xor	ax, ax
	mov	[b_exit_status],1	;[3] error code for exit
	mov	dir_file_size+0, ax	; set the file length in the
	mov	dir_file_size+2, ax	; directory to zero.
	mov	f_dir_modified, 1	; set the directory modified flag.

; note:  the current directory entry has been modified and
; needs to be written out at this point.

	stc
	jmp	mark_fat_exit
mark_fat_begin:
	mov	dx, ax
	mov	last_cluster, ax	; initialize the last cluster counter.
	mov	f_frag, 0		; clear fragmented file flag.
mark_fat_00:
	inc	file_clusters		; bump up the cluster count.
	mov	di, ax			; calculate address of cluster in
	shl	di, 1			; normalized fat table.

; the following is necessary for fats > 64k

	mov	bx,normal_fat_seg
	test	ah,80h
	jz	mark_fat_01
	add	bx,1000h
mark_fat_01:
	mov	es,bx
	mov	bx, es:[di]		; get existing value in normalized
	or	bx, bx			; fat table.
	jz	mark_fat_10		; if non-zero, means we have a cross-link.
	call	recurse_fsystem		; identify the cross-linked file.
	jmp	mark_fat_exit
mark_fat_10:
	mov	bx, ax			; get pointer to next cluster from real
	call	get_fat			; fat table.
	call	eoc_chain		; last cluster of chain?
	lje	mark_fat_eoc		; exit loop if so.
	call	good_fat		; check for invalid cluster numbers.
	jnc	mark_fat_12
	mov	bx, last_cluster	; terminate the file at the last valid
	mov	ax, eoc			; cluster.
	call	put_fat			; replace fat entry
	mov	ax, sector_siz		; calculate the file size in bytes
	mov	cl, cshift		; from the cluster size and the number
	shl	ax, cl			; of valid clusters.
	mul	file_clusters
	mov	dir_file_size+0, ax	; put the corrected size into the
	mov	dir_file_size+2, dx	; directory entry.
	cmp	f_fix, 0
	callnz	truncate_filesize	; otherwise, get rid of the rest of
	mov	f_fat_modified, 1	; set "modified" flags.
	mov	f_dir_modified, 1

; note:  both the fat and the current directory entry
; have been modified and need to be written out!

	stc				; set carry and exit on invalid cluster
	jmp	mark_fat_exit		; number.
mark_fat_12:
	mov	es:[di], dx		; write starting cluster number
					; of file to normal fat table.
	mov	bx, ax			; calculate what last cluster should
	dec	bx			; be for a contigous file.
	cmp	bx, last_cluster	; if they don't match
	je	mark_fat_20
	inc	w_non_contig		; increment non-contiguous counter
	inc	f_frag			; set fragmented file flag.
mark_fat_20:
	mov	last_cluster, ax
	jmp	mark_fat_00
mark_fat_30:
	mov	bx, last_cluster	; terminate the file at the last
	call	get_fat
	push	ax
	mov	ax, eoc			; cluster (directory-resident file size
	call	put_fat			; has been satisfied at this point).
	pop	bx
	call	release_chain		; release additional space in fat

; note:  the fat has been modified and needs to be written back out!

mark_fat_34:
	mov	f_fat_modified, 1	; set the "modified" flag.
	call	format_pathname
	mov	dx, offset asciizfn
	call	printline
	mov	dx, offset s_f_toolong
	call	printline
	stc
	jmp	mark_fat_exit
mark_fat_eoc:
	mov	word ptr es:[di], dx	; write starting cluster number
					; of file to normalized fat table.
	test	byte ptr [dta+19], dirmask  ;[2] is it a dir?
	jnz	mark_fat_okay		;[2] skip if so
	mov	ax, file_clusters	; is file size correct?
	cmp	ax, expected_size
	je	mark_fat_okay
	mov	[b_exit_status],1	;[3] error code for exit
	mov	ax, sector_siz		; calculate the file size in bytes
	mov	cl, cshift		; from the cluster size and the number
	shl	ax, cl			; of valid clusters.
	mul	file_clusters
	mov	dir_file_size+0, ax	; put the corrected size into the
	mov	dir_file_size+2, dx	; directory entry.
	cmp	f_fix, 0
	callnz	truncate_filesize	; otherwise, get rid of the rest of
	call	format_pathname
	mov	dx, offset asciizfn
	call	printline
	mov	dx, offset s_d_toolong
	call	printline
	stc
	jmp	mark_fat_exit
mark_fat_okay:
	clc
mark_fat_exit:
	pop	es
	pop	di
	pop	dx
	pop	bx
	ret

	
	subttl release_chain - release clusters past (bx) in alloc chain
	page
;======================================================================
; .func: release_chain - release clusters past (bx) in alloc chain
;
; input:
;	bx = starting cluster number
;
; output:
;
; comments:
;
;	release all clusters past (bx) in allocation chain
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
release_chain:
	call	get_fat			; get the next fat entry in the chain.
	mov	dx, ax
	xor	ax, ax			; zero it (mark it as available).
	call	put_fat			; put it back.
	mov	ax, dx			; restore next fat entry.
	call	eoc_chain		; last cluster of chain?
	je	rel_exit		; exit loop if so.
	call	good_fat		; check for valid cluster number
	jc	rel_err			; abort on error
	mov	bx, ax
	jmp	release_chain		; loop around again
rel_exit:
	clc				; return ok status
	ret
rel_err:
	mov	dx, ax
	stc				; return err status
	ret


	subttl update_counts - update count of clusters used in file system.
	page
;======================================================================
; .func: update_counts - update count of clusters used in file system.
;
; input:
;
; output:
;
; comments:
;
;	this function will update the count of clusters used by visible
;	files, hidden files, and directories for use in the output report.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
update_counts:
	push	ax			; save ax
	push	bx			; save bx
	mov	ax, [file_clusters]	; get count of clusters used
	cmp	ax,0			; did it use any
	je	update_exit		; exit if no clusters
update_10:
	test	byte ptr [dta+19], dirmask  ; is this a directory
	jz	update_20		; process as file if no
	add	[w_dir_clus], ax	; add to directory cluster count
	jmp	update_exit		; exit now
update_20:
	mov	bx, dir_file_size	; get the recorded file size
	cmp	bx,0			; anything there
	je	update_exit		; exit if 0 size
       	test	byte ptr [dta+19], hidden  ; is it a hidden file
	jz	update_30		; treat as normal file if no
	add	[w_hide_clus], ax	; add to hidden file cluster cou
	jmp	update_exit		; exit now
update_30:
	add	[w_file_clus], ax	; add to visible file cluster co
update_exit:
	pop	bx			; restore bx
	pop	ax			; restore ax
	ret				; return to caller


	subttl rf_helper - perform test for recurse_fsystem
	page
;======================================================================
; .func: rf_helper - perform test for recurse_fsystem
;
; input:
;	bx = cross linked file cluster to search for.
;	valid dta entry
;
; output:
;	zr if cross linked cluster found and reported
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
rf_helper:
	cmp	bx, start_cluster	; is it file we're looking for?
	jnz	rfh1			; skip if not.
	mov	byte ptr ds:[dta+19], 0	; insert null byte at end of fname
	mov	dx, offset dta+8	; point to start of fname
	call	printline		; print it
	call	docrlf
	cmp	ax,ax			; set zr flag
rfh1:
	ret


	subttl recurse_fsystem - recurse file system to find cross linked file.
	page
;======================================================================
; .func: recurse_fsystem - recurse file system to find cross linked file.
;
; input:
;	bx = cross linked file cluster to search for.
;
; output:
;
; comments:
;
;	this function preserves the directory scan while backtracking to
;	find another file that thinks it owns the cluster contained in bx.
;	bx will be the number in the first cluster field of the fcb so we
;	won't have to scan the FAT chain.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
recurse_fsystem:
	push	ax
	push	bx			; save cross linked cluster number.
	push	cx
	push	dx
	push	di
	push	si
	push	es
	mov	al,[stklvl]		; save and clear stklvl
	push	ax
	mov	[stklvl],0
	mov	si,bx			; save_pos will crash bx
	call	save_pos		; save fcb search data
	mov	bx,si			; recover entry bx
	mov	si, offset x_dir+1	; get current directory store area
	mov	dl, b_check_drive	; get check drive number
	inc	dl			; make base 1
	mosint	047h			; mos get current directory.
	mov	byte ptr x_dir, '\'	; precede with backslash
	mov	dx, offset s_root	; get root dir asciiz string addr.
	mosint	03bh			; mos set current directory.
	push	ds
	pop	es
	mov	si, offset dta
	mov	di, offset x_dta
	mov	cx, dtalen		; get dta length
	rep	movsb			; save current dta
	cmp	f_xlink, 0		; have we printed xlink error?
	jnz	r_start			; skip if so.
	mov	dx, offset s_xl01	; get cross linked file message
	call	printline
	mov	[b_exit_status],1	;[3] error code for exit
	mov	f_xlink, 1
r_start:
	mov	dx, offset s_xl02
	call	printline
	mov	byte ptr ds:[dta+19], 0	; insert null byte in filename
	mov	dx, offset dta+8	; point to start of fname
	call	printline		; print it
	mov	dx, offset s_xl03	; get " and " message
	call	printline		; print it.
r_dlp1:

; loop to find and process all files within the current directory

	mov	si,bx
	call	save_pos
	mov	bx,si
	mov	[extatrb],00000111b	; find all files
	mov	dx,offset s_extfcb
	mosint 11h
r_dlp8:
	cmp	al,0			; end of current directory?
	jne	r_dlp9
	call	rf_helper		; check the file entry
	jnz	r_dlp4
	call	restore_pos		; if find, counterbalance stack
	jmp	r_dlp2			; and get out
r_dlp4:
	mov	dx,offset s_extfcb
	mosint 12h			; find the next entry
	jmp 	short r_dlp8
r_dlp9:
	mov	si,bx
	call	restore_pos
	mov	bx,si

; loop to process each directory within the tree

	mov	[extatrb],00010111b	; find all directories
	mov	dx,offset s_extfcb
	mosint	11h
r_dlp3:
	cmp	al,0			; when al != 0, done with current dir
	jz	r_dlp5
	cmp	[stklvl],0		; need to restore to previous dir?
	lje	r_dlp2
	mov	dx,offset s_dotdot
	mosint	3bh			; back up to parent
	dec	[stklvl]
	call	restore_pos		; restore the fcb search data
	jmp	short r_dlp6
r_dlp5:

; filter out all but honest-to-goodness directories

	test	byte ptr [dta+19],dirmask
	jz	r_dlp6
	cmp	byte ptr [dta+8],'.'	; skip . and .. at this point
	je	r_dlp6
	call	save_pos		; save fcb search data
	inc	[stklvl]		; update depth record
	mov	di,offset asciizfn	; convert dta name to asciiz
	call	dtanam2z
	mov	dx,offset asciizfn	; and change to that directory
	mosint	3bh
	call	rf_helper		; check the directory entry
	jz	r_dlp2
	mov	dx,offset s_extfcb
	mosint	11h			; skip past the .
	or	al,al
	jnz	r_dlp2
	mov	dx,offset s_extfcb
	mosint	12h			; skip past the ..
	or	al,al
	jnz	r_dlp2
	jmp 	r_dlp1
r_dlp6:
	mov	dx,offset s_extfcb
	mosint	12h			; find the next entry
	jmp 	r_dlp3
r_dlp2:
	cmp	[stklvl],0		; need to unwind the stack?
	je	r_dlp7
	dec	[stklvl]		; back out a level
	call	restore_pos		; restore the fcb search data
	jmp	short r_dlp2
r_dlp7:
	push	ds
	pop	es
	mov	si, offset x_dta
	mov	di, offset dta
	mov	cx, dtalen		; get dta length
	rep	movsb			; restore previous dta
	mov	dx, offset x_dir	; get previous directory.
	mosint	03bh			; mos set current directory.
	call	restore_pos		; restore fcb search data
	pop	ax
	mov	[stklvl],al		; restore original stklvl
	pop	es
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


	subttl ucase - convert to upper case
	page
;======================================================================
; .func: ucase - convert to upper case
;
; input:
;	al = input character.
;
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
ucase:
	cmp	al, 'a'			; is it below lowercase?
	jb	uc_end			; exit if so.
	cmp	al, 123			; is it above lowercase?
	jnb	uc_end			; exit if so.
	sub	al, 32			; otherwise uppercase it.
uc_end: 	ret


	subttl docrlf - print a cr/lf to console
	page
;======================================================================
; .func: docrlf - print a cr/lf to console
;
; input:
;
; output:
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
docrlf:
	push	dx
	mov	dx, offset s_crlf
	call	printline
	pop	dx
	ret


	subttl printline - output string to console.
	page
;======================================================================
; .func: printline - output string to console.
;
; input:
;	ds:dx pointer to string to print.
;
; output:
;
; comments:
;
;	we scan for end of string with scasb instruction setting cx to
;	length of string. next call mos write function to output string.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
printline:
	push	ax			; preserve all registers changed
	push	bx			; including flags
	push	cx
	push	es
	push	di
	push	si
	pushf
	push	ds
	pop	es			; set es=ds
	xor	ax, ax			; clear ax
	mov	cx, 0ffffh		; set default counter.
	mov	di, dx
	cld				; clear direction flag ( increment )
	repne	scasb			; loop until null is found.
	mov	ax, -2			; correct result
	sub	ax, cx
	xchg	ax, cx			; put result back in cx
	mov	bx, 01			; get mos console handle
	mosint	040h			; mos write to console
	popf				; restore flags
	pop	si			; and other registers
	pop	di
	pop	es
	pop	cx
	pop	bx
	pop	ax
	ret


	subttl putchar - output character in al to console device.
	page
;======================================================================
; .func: putchar - output character in al to console device.
;
; input:
;
; output:
;
; comments:
;
;	output character in al to console. if re-direction is done 
;	then the character will be re-directed in normal fashion.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
putchar:
	push	dx
	push	ax
	mov	dl, al			; put character in dl.
	mosint	2			; mos print character on display.
	pop	ax
	pop	dx
	ret				; return to caller.


	subttl dec16out - output 16 bit value in dx on console.
	page
;======================================================================
; .func: dec16out - output 16 bit value in dx on console.
;
; input:
;	dx = number to convert to decimal and output to console.
;
; output:
;
; comments:
;
;	no registers are changed.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
dec16out:
	push	es			; preserve registers
	push	di
	push	dx
	push	bx
	push	ax
	pushf
	std
	mov	di, offset numbuf+5	; get data area
	mov	ax, ds
	mov	es, ax
	mov	bx, 10			; set divisor (number base).
	xor	al, al
	stos	byte ptr es:[di]	; terminate string.
d16o10:
	mov	ax, dx			; get remaining portion of number.
	xor	dx, dx			; clear top half of 32-bit dividend.
	div	bx			; divide by 10.
	xchg	ax, dx
	add	al, '0'			; make number into ascii.
	stos	byte ptr es:[di]	; save it into numbuf.
	or	dx, dx			; is remainder zero?
	jnz	d16o10
	lea	dx, [di+1]		; point to leftmost ascii decimal digit.
	call	printline		; print it.
	popf
	pop	ax			; restore registers..
	pop	bx
	pop	dx
	pop	di
	pop	es
	ret


	subttl dec32out - decimal conversion
	page
;======================================================================
; .func: dec32out - decimal conversion
;
; input:
;	dx:ax = number to convert and output.
;
; output:
;
; comments:
;
;	no registers are changed.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
dec32out:
	push	ax			; save 'em all.
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	pushf
 	push	ax			; save lsw of number for initialization.
	mov	ax, ds			; set es = ds for string moves.
	mov	es, ax
 	cld				; blank-pad the output buffer.
	mov	di, offset numbuf
	mov	cx, 13
	mov	al, ' '
	rep	stos byte ptr es:[di]
 	std				; zero-terminate the buffer and position
	xor	al, al			; di to last digit position.
	stos	byte ptr es:[di]
 	mov	w_comma, 0		; initialize the comma counter.
 	pop	ax			; restore lsw of number.
dec32out_00:
	push	di
	mov	di, 0			; setup 32-bit divisor.
	mov	si, 10
	call	divide32		; divide by 10.
	pop	di
	push	ax
	mov	al, bl			; get the remainder of the division.
	add	al, '0'			; make number into ascii.
	stos	byte ptr es:[di]	; save it into numbuf.
	pop	ax
	mov	bx, ax			; have we run out of digits?
	or	bx, dx
	jz	dec32out_01		; if not, go around again.
	inc	w_comma			; increment comma counter.
	cmp	w_comma, 11b
	jnz	dec32out_00
	mov	w_comma, 0
	push	ax
	mov	al, ','
	stos	byte ptr es:[di]
	pop	ax
	jmp	dec32out_00
dec32out_01:
	mov	dx, offset numbuf	; print it!
	call	printline
	popf				; get 'em all back.
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


	subttl verify_fsize - check dir filesize against fat clusters
	page
;======================================================================
; .func: verify_fsize - check dir filesize against fat clusters
;
; input:
;	dta must contain current file.
;
; output:
;
; comments:
;
;	compare dir filesize field against total allocated space in fat.
;	if filesize is larger than allocated space, then truncate filesize
;	to total of allocated space.
;	if filesize is smaller than allocated space, then truncate fat
;	clusters to amount in filesize.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
verify_fsize:
	mov	bx, sector_siz		; calculate the number of clusters
	mov	cl, cshift		; the file should take up, which is
	shl	bx, cl			; file size divided by cluster size
	mov	ax, dir_file_size+0	; rounded up to the next
	mov	dx, dir_file_size+2	; integral value.
	lea	cx, [bx-1]
	add	ax, cx
	adc	dx, 0			; correct for carry if needed.
	div	bx			; compute number of clusters in file.
	mov	expected_size, ax
 	cmp	ax, file_clusters	; if calculated and actual match,
	je	verify_fs_exit		; then we're done.
verify_fs_exit:
	ret


	subttl format_pathname - develop full pathname
	page
;======================================================================
; .func: format_pathname - develop full pathname
;
; input:
;
; output:
;
; comments:
;
;	all registers preserved.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
format_pathname:
	push	ax			; save 'em.
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	push	ds			; set es=ds
	pop	es

; initialize asciizfn buffer to nulls.

	mov	cx, dirlen		; set buffer length
	shr	cx, 1
	xor	ax, ax
	mov	di, offset asciizfn
	rep	stos word ptr es:[di]
	mov	al, b_check_drive	; print the drive name.
	add	al, 'A'
	mov	asciizfn+0, al		; plug drive letter into asciizfn
	mov	asciizfn+1, ':'		; and colon:
	mov	byte ptr asciizfn+2, '\'; plug backslash prefix

; get current mos pathname into asciizfn buffer

	mov	si, offset asciizfn+3
	xor	dx, dx			; specify default drive.
	mosint	047h			; get current directory.

; check to see if we need to suffix returned string with a slash

	mov	di, offset asciizfn+3
	cmp	asciizfn+3, 0		; is it root directory?
	jz	ffn020			; skip middle slash stuff.
	xor	ax, ax			; clear comparison bytes.
	mov	cx, dirlen		; set max scan count
	repne	scasb			; look for eol byte.
	mov	byte ptr es:[di-1], '\'	; suffix current dir with slash
ffn020:
	call	dtanam2z		; put current dta fcb file name in asciizfn.
	pop	es
	pop	di			; restore 'em.
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


	subttl print_filename_stuff
	page
;======================================================================
; .func: print_filename_stuff
;
; input:
;
; output:
;
; comments:
;
;	if [f_verify] is true then display the filename on console.
;	if [f_dfrag] is true then display only the fragmented files.
;	if both are true then display whole display in line
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
print_filename_stuff:
	cmp	f_frag, 0
	jz	pfs_05
	inc	w_frag_count		; record another fragmented file.
pfs_05:
	cmp	f_verify, 0		; do they want to see operations
	jz	pfs_10			; skip if not.
	mov	dx, offset asciizfn	; get filename
	call	printline		; print it.
pfs_10:
	cmp	f_dfrag, 0		; are fragmented files displayed?
	jz	pfs_18			; skip it if not.
	cmp	f_frag, 0		; is file fragmented flag set?
	jz	pfs_18			; skip message if not.
	cmp	f_verify, 0		; have we already printed filename?
	jnz	pfs_15			; skip if so.
	mov	dx, offset asciizfn	; get filename
	call	printline		; print it.
pfs_15:
	mov	dx, offset s_frag1	; get "has " string
	call	printline		; print it.
	mov	dx, f_frag		; get number of fragments.
	inc	dx
	call	dec16out		; output ascii number
	mov	dx, offset s_frag2	; get "frag... clusters" string
	call	printline		; print it.
	ret
pfs_18:
	cmp	f_verify, 0		; print crlf.
	callnz	docrlf
	ret


	subttl calc_exp_size - calculate expected file size.
	page
;======================================================================
; .func: calc_exp_size - calculate expected file size.
;
; input:
;	dta must contain current file.
;
; output:
;
; comments:
;
;	calculates the expected length of the file based on the file size
;	field of the directory entry.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
calc_exp_size:
	mov	bx, sector_siz		; calculate the number of clusters
	mov	cl, cshift		; the file should take up, which is
	shl	bx, cl			; file size divided by cluster size
	mov	ax, dir_file_size+0	; rounded up to the next
	mov	dx, dir_file_size+2	; integral value.
	lea	cx, [bx-1]
	add	ax, cx
	adc	dx, 0			; correct for carry if needed.
	div	bx			; compute number of clusters in file.
	mov	expected_size, ax
	ret


	subttl divide32 - divide a 32-bit number by another 32-bit number
	page
;======================================================================
; .func: divide32 - divide a 32-bit number by another 32-bit number
;
; input:
;	dx:ax  dividend.
;	di:si  divisor.
;
; output:
;	dx:ax	result/remainder.
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
divide32:
	xor	bx, bx
	mov	w_temp, bx
	mov	cx, 32
divide32_00:
	xchg	cx, w_temp
	sal	ax, 1
	rcl	dx, 1
	rcl	bx, 1
	rcl	cx, 1
	cmp	di, cx
	ja	divide32_02
	jb	divide32_01
	cmp	si, bx
	ja	divide32_02
divide32_01:
	sub	bx, si
	sbb	cx, di
	inc	ax
divide32_02:
	xchg	cx, w_temp
	loop	divide32_00
	ret


	subttl check_mos_media
	page
;======================================================================
; .func: check_mos_media
;
; input:
;
; output:
;
; comments:
;
;	this is a simple check to see if the device is a "MOS" formatted
;	disk. return carry set if error reading drive or suspected non-mos
;	disk is detected.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
check_mos_media:
	mov	al, b_check_drive	; get current drive number.
	xor	cx, cx
	mov	cl, 1			; get fat length in sectors
	mov	dx, 0			; get fat start sector number
	push	ds
	mov	ds, w_dirs_seg		; set data segment
	xor	si, si
	mov	di,0fffch
	xor	bx, bx			; set up ds:bx to w_dirs_seg
	int	25h			; mos abs read fn.
	jc	cdm_read_err		; abort on read error.
	popf				; restore flags.
	pop	ds			; restore our data segment
	push	es			; save es
	mov	es, w_dirs_seg		; point to data buffer
	cmp	byte ptr es:[21], 0f0h	; make sure it is within range
	jb	non_mos			; from f0h to ffh
	pop	es			; restore es
	clc				; clear any error flag
	ret				; return to caller.

; probable non-mos disk. warn user and continue at their risk!

non_mos:
	pop	es
	mov	dx, offset s_non_mos
	call	printline
	stc
	ret

; report error reading the disk boot sector. drive is probably not ready!

cdm_read_err:
	popf				; restore flags
	pop	ds
	mov	dx, offset s_media_err
	call	printline
	stc				; set carry to report error.
	ret


	subttl bytes_to_kbytes - convert bytes to k-bytes
	page
;======================================================================
; .func: bytes_to_kbytes - convert bytes to k-bytes
;
; input:
;	dx:ax  number to convert.
;
; output:
;	dx:ax	result.
;
; comments:
;
;	registers ax and dx modified.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
bytes_to_kbytes:
	push	cx
	add	ax, 1023		; round up.
	adc	dx, 0
	mov	cx, 10			; shift 32-bit number right by 10-bits.
bytes_to_00:
	shr	dx, 1
	rcr	ax, 1
	loop	bytes_to_00
	pop	cx
	ret


	subttl validate_rest - validates parts of fat not part of file chain.
	page
;======================================================================
; .func: validate_rest - validates parts of fat not part of file chain.
;
; input:
;
; output:
;
; comments:
;
;	this function runs through the fat table again and looks for parts
;	of the disk that are not marked as free and also not part of any
;	fat allocation chain. it's job is to report them if the /F option
;	is not selected and if /f is true then convert the lost clusters
;	to files in the root directory.
;	after all fat entries are scanned then write out the modified fat
;	to disk.
;	all registers are preserved.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
validate_rest:
	push	ax			; save 'em.
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	xor	ax, ax
	mov	w_bad_sec_cnt, ax
	mov	w_unall_clus, ax
	mov	w_alloc_clus, ax
	mov	dx, offset s_root	; get root dir asciiz string addr.
	mosint	03bh			; mos set current directory.
	mov	es, normal_fat_seg	; set up access to normalized fat.
	mov	si, 2 * 2
	mov	bx, 2
	mov	cx, clusters
validate_00:
	lods	word ptr es:[si]	; get a word from the normalized fat.
	push	bx			; save loop variables.
	push	cx
	push	si
	or	ax, ax			; in a file?
	jz	validate_01
	inc	w_alloc_clus
	jmp	validate_30
validate_01:
	call	get_fat			; get the entry out of the real fat.
	or	ax, ax			; is the entry unallocated?
	jnz	validate_02
	inc	w_unall_clus
	jmp	validate_30
validate_02:
	mov	dx, ax			; is the entry a cluster containing a
	cmp	dx, bad_sec_val		; bad sector?
	jne	validate_10
	inc	w_bad_sec_cnt		; counter 'em up.
	jmp	validate_30
validate_10:
	call	eoc_chain		; is it a one cluster file?
	je	validate_20		; if so, convert it to a file.
	call	good_fat		; is the cluster number valid?
	jnc	validate_20		; if so, convertr the chain to a file.
validate_inv:
	push	bx			; save for printing error message.
	push	ax
	mov	[b_exit_status],1	;[3] error code for exit
	xor	ax, ax			; zero the fat entry, since it's
	call	put_fat			; invalid.
	mov	f_fat_modified, 1	; set the "FAT modified" flag.
	mov	dx, offset s_inv_unalloc
	call	printline
	pop	dx
	call	dec16out
	mov	dx, offset s_inv_unalloc1
	call	printline
	pop	dx
	call	dec16out
	mov	dx, offset s_inv_unalloc2
	call	printline
	jmp	validate_30

; here, we follow the cluster chain to make sure it is valid,
; terminating it at the first invalid entry.  then a file can
; be made out of the validated cluster chain, hopefully
; recovering something of value.

validate_20:
	mov	w_lost_start, bx
	mov	last_cluster, bx
	mov	file_clusters, 0
	mov	dx, bx
validate_22:
	inc	file_clusters
	mov	di, bx
	shl	di, 1
	call	get_fat
	call	eoc_chain		; last cluster of chain?
	je	validate_24
	call	good_fat		; valid cluster number?
	jc	validate_21		; if not,
	mov	bx, word ptr es:[di]	; get existing value in normalized
	or	bx, bx			; fat table.
	jnz	validate_21		; cross-links detected at this point
					; just terminate the chain.
	mov	word ptr es:[di], dx
	mov	last_cluster, ax
	mov	bx, ax
	jmp	validate_22

; routine to terminate a chain in the event of a bad cluster number.

validate_21:
	mov	bx, last_cluster	; terminate the file at the last valid
	mov	ax, eoc			; cluster.
	call	put_fat
validate_24:
	mov	word ptr es:[di], dx
	mov	[b_exit_status],1	;[3] error code for exit
	cmp	f_fix, 0		; if fixup is to be done
	jnz	validate_25
	mov	dx, offset s_lost_clstr
	call	printline
	jmp	validate_30
validate_25:
	call	build_lost_dir		; then build a dir entry for the cluster.
	mov	dx, offset s_convert_lost
	call	printline		; print message
validate_30:
	pop	si			; restore loop variables.
	pop	cx
	pop	bx
	inc	bx
	dec	cx			; this instead of a loop instruction.

; following additions are for fats > 64k

	jz	validate_32
	or	si,si
	jnz	validate_31
	mov	ax,es
	add	ax,1000h
	mov	es,ax
validate_31:
	jmp	validate_00
validate_32:
	call	write_fat		; write out modified fat segment
validate_40:
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


	subttl good_fat - perform range check on fat cluster number in ax.
	page
;======================================================================
; .func: good_fat - perform range check on fat cluster number in ax.
;
; input:
;	ax = cluster number.
;
; output:
;	carry set on error.
;
; comments:
;
;	perform range check on fat cluster number in ax.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
;----------------------------------------------------------------------
good_fat:
	or	ax, ax			; value (0)000 is invalid.
	jz	not_good_fat
	cmp	ax, 1			; value (0)001 is invalid.
	je	not_good_fat
	cmp	ax,[bad_sec_val]	; don't regard a cluster already
	je	really_good		; marked as invalid as "bad"
	push	ax			; sah
	dec	ax			; sah
	dec	ax			; sah
	cmp	ax, clusters		; values larger than cluster count are
	pop	ax			; sah
	ja	not_good_fat		; invalid.
really_good:
	clc
	jmp	good_fat_exit
not_good_fat:
	stc
good_fat_exit:
	ret


	subttl eoc_chain - detect end of cluster chain
	page
;======================================================================
; .func: eoc_chain - detect end of cluster chain
;
; input:
;	ax = cluster number
;
; output:
;	zf = true on end of cluster chain
;
; comments:
;
;	note:  the specification says that (f)ff8-(f)fff are valid eoc 
;	values and that (f)ff8 is the only one used.  in fact, we have 
;	observed that (f)fff is the only value used.  therefore, this 
;	routine has been modified to recognize only (f)fff as eoc 
;	until we know better.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
eoc_chain:
	push	bx
	mov	bx, ax			; is this is the last cluster of the
	cmp	bx, eoc
	pop	bx
	ret


	subttl build_lost_dir
	page
;======================================================================
; .func: build_lost_dir
;
; input:
;
; output:
;
; comments:
;
;	build directory entry for lost cluster chain.  uses [clstrcnt] for
;	number in file name.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
build_lost_dir:
	push	es
	mov	dx, clstrcnt		; get current cluster file number
	call	fill_fcb_pad		; plug number into fcb area
	mov	dx, offset chkfcb	; get dummy fcb area
	push	dx
	mosint	016h			; create a file.
	pop	dx
	mosint	010h			; close the file.

; find the newly created directory entry and load it into the dta.

	call	find_dir_entry		; search for just created entry.

; update the directory entry and write it back out.

b_found:
	mov	ax, sector_siz		; calculate the file size in bytes
	mov	cl, cshift		; from the cluster size and the number
	shl	ax, cl			; of valid clusters.
	mul	file_clusters
	mov	word ptr dir_entry+28, ax  ; put the corrected size into the
	mov	word ptr dir_entry+30, dx  ; directory entry.
	mov	ax, w_lost_start
	mov	word ptr dir_entry+26, ax
	call	write_dir_entry
	pop	es
	ret


	subttl find_dir_entry
	page
;======================================================================
; .func: find_dir_entry
;
; input:
;
; output:
;
; comments:
;
;	perform search for matching directory entry while scanning the
;	root directory disk area.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
find_dir_entry:
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	es
	pushf
	mov	ax, ds
	mov	es, ax
	cld
	mov	bx, 0			; init dir entry number.
	mov	cx, w_dirs		; get max dir entry for root dir.
find_dir_00:
	call	read_dir_entry		; read entry from dir area
	push	cx			; save number of entries in root
	mov	si, offset dir_entry
	mov	di, offset chkfcb+1	; get our file fcb area
	mov	cx, 11
	or	ax, ax
	repe	cmpsb			; look for our fcb
	pop	cx
	je	find_dir_10		; exit loop if found.
	inc	bx			; otherwise loop around
	loop	find_dir_00
	popf
	stc				; if no find, set carry and exit.
	jmp	find_dir_exit
find_dir_10:
	popf
	clc
find_dir_exit:
	pop	es
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret


	subttl read_dir_entry - read a dir sector from disk into dir segment
	page
;======================================================================
; .func: read_dir_entry - read a dir sector from disk into dir segment
;
; input:
;	bx = directory entry number (offset zero) to read.
;
; output:
;	carry flag set on error.
;	first 32-bytes of dta set to the directory entry.
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
read_dir_entry:
	push	ax			; save 'em.
	push	bx
	push	cx
	push	dx
	push	ds
	push	es
	mov	ax, bx
	mov	bx, sector_siz		; calculate directory entries per
	mov	cl, 5			; sector.
	shr	bx, cl
	div	bl			; calculate sector number within dir.
	mov	bl, ah			; calculte byte offset with directory
	xor	ah, ah
	shl	bx, cl			; sector.
	mov	w_dir_sec_off, bx
	cmp	ax, w_last_dir_sec	; is it already in buffer
	je	read_dir_ent_2		; skip if so.
	mov	w_last_dir_sec, ax	; preserve sector number
	call	read_dir_sector		; perform disk sector read.
read_dir_ent_2:
	mov	si, w_dir_sec_off
	mov	di, offset dir_entry
	mov	cx, 32 / 2
	mov	ax, ds
	mov	es, ax
	mov	ds, w_dirs_seg
	rep	movs word ptr es:[di], word ptr ds:[si]
	pop	es			; get 'em back.
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


	subttl read_dir_sector - read a sector block from the directory
	page
;======================================================================
; .func: read_dir_sector - read a sector block from the directory
;
; input:
;	ax = sector offset into directory.
;
; output:
;	w_dirs_seg:0 is loaded with 512 bytes of data from read.
;	if carry is set then error occurred!
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
read_dir_sector:
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	ds
	add	ax, w_dir		; add in directory base offset
	mov	dx, ax			; put it in dx
	mov	w_sect, ax		; save it for later write.
	mov	al, b_check_drive	; get drive letter to check.
	mov	cx, 1			; get read sector count.
	mov	ds, w_dirs_seg		; get output buffer address
	xor	si, si
	mov	di,0fffch
	xor	bx, bx
	int	25h			; read sector from disk
	pop	ax			; throw away previous flags
	pop	ds
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


	subttl write_dir_entry
	page
;======================================================================
; .func: write_dir_entry
;
; input:
;
; output:
;	carry flag set on error.
;	entire directory sector containing the previously read
;	directory entry is written back out.
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
write_dir_entry:
	push	ax			; save 'em.
	push	bx
	push	cx
	push	dx
	push	es
	mov	es, w_dirs_seg		; get storage area
	mov	si, offset dir_entry
	mov	di, w_dir_sec_off
	mov	cx, 32 / 2
	rep	movs word ptr es:[di], word ptr ds:[si]
	call	write_dir_sector
	pop	es			; get 'em back.
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


	subttl write_dir_sector - write a sector block from the directory
	page
;======================================================================
; .func: write_dir_sector - write a sector block from the directory
;
; input:
;
; output:
;	w_dirs_seg:0 is written back to same sector as was read.
;
; comments:
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
write_dir_sector:
	push	ax
	push	bx
	push	cx
	push	dx
	push	ds
	mov	al, b_check_drive	; get drive letter to check.
	mov	cx, 1			; get write sector count.
	mov	dx, w_sect		; get current sector in buffer
	mov	ds, w_dirs_seg		; get output buffer address
	xor	si, si
	mov	di, 0fffch
	xor	bx, bx
	int	26h			; write sector from disk function
	pop	ax			; throw away previous flags
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


	subttl fill_fcnb pad - pad fcb number with 4 digit hex number.
	page
;======================================================================
; .func: fill_fcnb pad - pad fcb number with 4 digit hex number.
;
; input:
;
; output:
;
; comments:
;
;	this procedure takes [clstrcnt] and builds a ascii number filled
;	into the chkfcb file control block.
;	no registers are changed.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
fill_fcb_pad:
	push	es
	push	si
	push	ax			; preserve registers
	push	cx
	push	dx
	mov	dx, clstrcnt		; get number to use.
	mov	cx, 4			; character output counter
	push	ds
	pop	es
	mov	di, offset chknum	; get number area to pad.
ho10:
	push	cx			; save loop counter counter
	mov	cl, 4
	rol	dx, cl
	mov	al, dl
	and	al, 0fh
	daa
	add	al, 0f0h
	adc	al, 040h
	stosb				; store byte in al to fcb area
	pop	cx			; restore loop counter.
	loop	ho10
	inc	clstrcnt		; increment counter for next file.
	pop	dx			; restore registers
	pop	cx
	pop	ax
	pop	si
	pop	es
	ret


	subttl truncate_filesize
	page
;======================================================================
; .func: truncate_filesize
;
; input:
;
; output:
;
; comments:
;
;	this function will truncate the size of the file contained in [dta]
;	to the size specified in the filesize dword in [dta].
;
;	called by mark_fat_chain when a file dir entry has fewer clusters
;	than the fat claims.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
truncate_filesize:
	call	format_pathname		; format dta into asciiz filename
	mov	dx, offset asciizfn	; get asciiz formatted filename
	mov	al, 01			; set for write mode
	mosint	03dh			; mos open file handle
	mov	bx, ax
	mov	dx, dir_file_size	; put the corrected size into the
	mov	cx, dir_file_size+2	; directory entry.
	xor	al, al
	mosint	042h			; mos lseek file pointer
	xor	cx, cx
	mosint	040h			; mos write file handle
	mosint	03eh			; mos close file handle
	ret


	subttl delete_old_chk_files
	page
;======================================================================
; .func: delete_old_chk_files
;
; input:
;
; output:
;
; comments:
;
;	delete all root directory files matching chk0xxxx.err to allow
;	reuse of the filenames.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
delete_old_chk_files:
	push	ax
	push	dx
	mov	dx, offset delfcb
	mosint	013h
	pop	dx
	pop	ax
	ret


	subttl exit_report
	page
;======================================================================
; .func: exit_report
;
; input:
;
; output:
;
; comments:
;
;	print final statistics screen for verify before exiting.
;
; .calls: 
; .reads: 
; .writes: 
;
; .endfn
;======================================================================
exit_report:
	call	docrlf			; skip down two lines
	mov	dx, offset s_vnamstr
	call	printline
	mov	al, [b_check_drive]	; get drive checked
	add	al, 'A'			; convert to ascii
	call		putchar		; display the drive
	mov	al, ':'
	call	putchar
	mov	al, ' '
	call	putchar
	mov	dx, offset s_volname	; get current volume name
	call	printline		; print it.
	call	docrlf
	call	docrlf			; skip down two lines
	mov	dx, offset s_total_vfiles
	call	printline
	xor	dx, dx
	mov	ax, w_file_count	; get visible file count.
	call	dec32out		; print it
	call	docrlf
	mov	dx, offset s_total_hfiles
	call	printline
	xor	dx, dx
	mov	ax, w_hide_count	; get hidden file count.
	call	dec32out		; print it
	call	docrlf
c_dirn:
	mov	dx, offset s_total_dirs
	call	printline
	xor	dx, dx
	mov	ax, w_dir_count		; get "total dirs" count
	call	dec32out		; output it
	call	docrlf
	cmp	f_dfrag,0		; did they request fragment sta
	je	c_vfileb		; show visible files if no
	mov	dx, offset s_total_frags; otherwise report non-contigs.
	call	printline
	xor	dx, dx
	mov	ax, w_frag_count	; get non-contig file count.
	call	dec32out		; output it on console
	call	docrlf			; with cr lf.

; calculate bytes used by visible files

c_vfileb:
	call	docrlf			; add another blank line
       	mov	dx, offset s_vfile_bytes
	call	printline
	mov	ax, sector_siz		; calculate cluster size.
	mov	cl, cshift
	shl	ax, cl
	mov	bx, w_file_clus
	mul	bx
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al, 'k'
	call	putchar
	call	docrlf

; calculate bytes used by hidden files

c_hfileb:
	mov	dx, offset s_hfile_bytes
	call	printline
	mov	ax, sector_siz		; calculate cluster size.
	mov	cl, cshift
	shl	ax, cl
	mov	bx, w_hide_clus
	mul	bx
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al, 'k'
	call	putchar
	call	docrlf

;   calculate bytes used by directories

c_dirb:
	mov	dx, offset s_dir_bytes
	call	printline
	mov	ax, sector_siz		; calculate cluster size.
	mov	cl, cshift
	shl	ax, cl
	mov	bx, w_dir_clus
	mul	bx
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al, 'k'
	call	putchar
	call	docrlf

; calculate total bytes tied up in bad sectors.

c_bad:
	mov	bx, w_bad_sec_cnt
	mov	dx, offset s_bad_sects
	call	printline
	mov	ax, sector_siz		; calculate cluster size.
	mov	cl, cshift
	shl	ax, cl
	mul	bx
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al, 'k'
	call	putchar
	call	docrlf

; calculate total bytes available on drive

c_free:
	mov	dx, offset s_avail_bytes
	call	printline
	mov	ax, sector_siz		; calculate cluster size.
	mov	cl, cshift
	shl	ax, cl
	mov	bx, w_unall_clus
	mul	bx
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al, 'k'
	call	putchar
	call	docrlf
	call	docrlf			; 041888

; calculate total bytes on drive

c_total:
	mov	dx, offset s_total_bytes
	call	printline
	mov	ax, sector_siz		; calculate cluster size.
	mov	cl, cshift
	shl	ax, cl
	mov	bx, clusters		; multiply by total number of clusters
	mul	bx			; to get total bytes on drive.
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al, 'k'
	call	putchar
	call	docrlf
er_99:
	ret

end_of_code	label	near

chkcode	ends
	end verify

