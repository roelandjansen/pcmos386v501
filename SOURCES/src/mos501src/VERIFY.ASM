	include page.inc
	title	verify.asm - software link pc-mos x86 disk check program
comment ^===============================================================
  verify.exe - software link pc-mos x86 disk check program

  verify - mos disk allocation check program.

  this program checks for cross linked and un-allocated clusters in
  the disk file system. if any are found, corrections can be made
  and	changed rewritten to disk.

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

=======================================================================

jsm 04/23/87	entabbed file (50k space reduction).  made sure di was
		set to 0fffch before all int 25h & 26h calls. modified
		verify function to calculate size of a fat correctly
		if > 64k bytes.  fixed read_fat, write_fat, get_fat,
		and put_fat to work correctly with fat's bigger than
		64k (80h, 128d sectors).

sah 07/08/87	remove messages about fragment files

sah 07/12/87	converted 80+ to interupt 38h 00+

sah 08/18/87	correct parameters without spaces

sah 08/20/87	corrected problems with insufiecent memory when 
		running verify

jsm 11/20/87	changed method of recognizing directories so that the
		directories could have their archive bits set. version
		1.03

sah 11/23/87	updated version 2.00

sah 12/07/87	corrected problem with awesome i/o use use of addition 
		volume label to store extra storage area.

jsm 12/14/87	don't reset disk drive to a before calling get_args.
		changed test for success/failure of fns 11h and 12h to
		testing al, not cy.  changed method of determining
		program size to use real size, not arbitrary figure. 
		use int 21h, function 4ch to exit program and set
		error codes.

sah 03/15/88	completed and corrected jsm's 04/23/87 changes for
		fats > 64k.  corrected verify handling of pseudo-fat
		for fats greater than 64k (ug...)

rdg 04/18/88	correct pushdir and format_pathname.  do not insert a
		'.' in pathname if the directory name has no
		extension.  correct popdir.  make sure all pathnames
		terminate with '0' update s_err_dir message.  change
		popdir.  abort verify if directory structure is to
		deep.  change popd020 - temporary.  abort verify if
		bad return from func 11 or 12.  this occurs when a
		default directory is set that is exactly 64 characters
		long.  update exit_report.  add number of hidden
		files, number of user files bytes used by hidden
		files, user files and directories.  changes in next, 
		next05,  next15,  pushd010, exit_report.

mjs 5/16/88	moved call to check_mos_media to be after the get drive
		and	get directory calls.  this corrects a the situation
		where someone does a verify of a 1.2m floppy and then
		does one on a 360k one.  having an int25 direct disk
		read be the first thing done was preventing a proper
		media check from being done.

rbr 06/01/88	modified 2 places where the segment portion of a fat
		entry address is "normalized"... we want to avoid
		problems with the 286 driver, so we now only change
		the segment portion of the address if the entry is
		more than 64k into the fat.  changes flagged  ;060188.

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

mjs 05/03/90	gutted the main tree parsing loop within recurse_fsystem.  
		deleted pushdir, popdir, first_dir and next_dir.  added a 
		new tree parsing method which doesn't have to use up 
		65 bytes in a stack for each directory passed while 
		scanning through any given directory.  this corrects a 
		crash when more than 768 directories exist within a given
		subdirectory.  also corrected bug with endless loop
		reporting of a crosslinked file.

mjs 12/31/91	dlg mods: overhaul for dlg support.  fix bug where 
		had to run this tool several times to clean up cases
		of multiple lost cluster chains.  modified to work
		properly in the presence of secured files.

mjs 01/10/92	corrected oversight error in the handling of fat tables
		that are > 64k in read_fat and write_fat.

SAH 03/09/92	use true dos to check version, also check if on network
		drive.

================ 5.01 kernel ends here ====================================

mjs 07/13/92	corrected use of b_check_drive for i21f4409 call
		(when checking for a network drive).

mjs 08/11/92	corrected saving of bx within recurse_fsystem around
		calls to save_pos and restore_pos.  this was causing
		two problems: improper message format for cross
		linked files (where 2nd filename wasn't reported)
		and improper accounting of lost clusters (brooks).
		can mangle a disk if /f is used to clean up lost clusters.

======================================================================^

if 01 eq 01				; to appease/fool public.com

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

	include options.inc
	include macros.inc
	include dskstruc.inc

begin_seg segment para public 'begin'
begin_seg ends

stack segment para stack 'STACK'
	dw	512 dup(0)
stack ends

tcb segment at 0
	org	80h
tcbcmap	label byte
tcb     ends

endif

;----------------------------------------------------------------------
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
;----------------------------------------------------------------------

chkdata	segment para public 'DATA'
	assume cs:chkcode,ds:nothing,es:nothing,ss:nothing
;
; copyright notice inside the code but not displayed.
;

copyright	db	'(C) Copyright 1987-1992 The Software Link, Incorporated.'
		db	'All Rights Reserved Worldwide.'

;==== informational messages

s_help		db  'VERIFY verifies the disk system for file allocation errors             ',cr,lf  ;@@XLAT
		db  'and displays any errors found. If the /f option is requested           ',cr,lf  ;@@XLAT
		db  'VERIFY will attempt to fix errors and write them back to disk.         ',cr,lf  ;@@XLAT
		db  'For more information refer to PC-MOS users guide.                      ',cr,lf,lf  ;@@XLAT
		db  'VERIFY /c         Display any non-contiuous files.                     ',cr,lf  ;@@XLAT
		db  'VERIFY /f         Fix any errors found on disk.                        ',cr,lf  ;@@XLAT
		db  'VERIFY /h         Display this help screen.                            ',cr,lf  ;@@XLAT
		db  'VERIFY /v         Display files as checked.                            ',cr,lf,0  ;@@XLAT

s_vnamstr	db  ' Volume ID of ',0  ;@@XLAT

;==== the following lines must stay together
s_volprefix	db  8 dup (0)
s_volname	db  'No Label    ',0	; current volume name. ;@@XLAT
		db	22 dup (0)
;==== the above lines must stay together

s_total_vfiles	db  ' Number of visible Files:    ',0 ;@@XLAT
s_total_hfiles	db  ' Number of hidden Files:     ',0 ;@@XLAT
s_total_dirs	db  ' Number of directories:      ',0 ;@@XLAT
s_total_frags	db  ' Number of fragmented Files: ',0 ;@@XLAT
s_vfile_bytes	db  ' Bytes in visible Files:     ',0 ;@@XLAT
s_hfile_bytes	db  ' Bytes in hidden Files:      ',0 ;@@XLAT
s_dir_bytes	db  ' Bytes in directories:       ',0 ;@@XLAT
s_bad_sects	db  ' Bytes of defective Space:   ',0 ;@@XLAT
s_avail_bytes	db  ' Bytes available:            ',0 ;@@XLAT
s_total_bytes	db  ' Total capacity:             ',0 ;@@XLAT

;==== error messages

nonetdr db	'Cannot VERIFY a network drive!               ',13,10,0  ;@@xlat

s_bad_drive	db  'Bad drive specified. Command aborted.             ',cr,lf,0  ;@@XLAT
s_bad_arg	db  'Bad argument specified. Command ignored.         ',cr,lf,0  ;@@XLAT
s_xl01		db  'WARNING: Cross-linked files exist!                    ',cr,lf,0  ;@@XLAT
s_xl02		db  cr,'         Files are:   ',0  ;@@XLAT
s_xl03		db  ' and ',0	;@@XLAT
s_frag1 	db  ' has   ',0	;@@XLAT
s_frag2 	db  ' non-contiguous clusters.       ',cr,lf,0  ;@@XLAT
s_fragment	db  cr,lf,'Fragmented files exist.         ',cr,lf,0  ;@@XLAT
s_err_dirs	db  'Insufficent memory.  ',cr,lf,0  ;@@XLAT
s_err_dir	db  'Error: Length of directory pathname exceeds legal limit.                ',cr,lf  ;@@XLAT
           	db  '       Verify Aborted!    ',cr,lf,0  ;@@XLAT
s_invld_sub	db  'Invalid Subdirectory!       ',cr,lf,0  ;@@XLAT
s_media_err	db  'Disk Error: Unable to read boot sector of specified drive.             ',cr,lf  ;@@XLAT
		db  '            Make sure drive is ready and try again.                    ',cr,lf,0  ;@@XLAT
s_non_mos	db  'Disk Error: Suspected NON-MOS disk accessed.                           ',cr,lf  ;@@XLAT
		db  '            Cannot continue until disk can be identified.              ',cr,lf,0  ;@@XLAT
s_spec_err	db  'Unable to get disk specifications.                   ',cr,lf,0  ;@@XLAT
s_d_toolong	db  ' directory file size adjusted to match FAT cluster count.           ',cr,lf,0  ;@@XLAT
s_convert_lost	db  'Lost cluster chain converted to file.                          ',cr,lf,0  ;@@XLAT
s_inv_first	db  ' first cluster is invalid.       ',cr,lf,0  ;@@XLAT
s_inv_trunc	db  ' truncated at invalid cluster.       ',cr,lf,0  ;@@XLAT
s_lost_clstr	db  ' lost clusters were found in           ',0;@@XLAT
s_lost_clstr2	db  ' chains.           ',cr,lf  ;@@XLAT
		db  'Restart VERIFY using /f option to convert chains to files.                     ',cr,lf,0  ;@@XLAT
s_fix		db  '/F option chosen.        ',cr,lf,0  ;@@XLAT
s_bad_version	db  'Incorrect MOS Version!    ',cr,lf,0  ;@@XLAT
s_fixup_err	db  'Warning:   ',cr,lf	;@@XLAT
		db  'You may not use the /F option while there are other tasks           ',cr,lf  ;@@XLAT
		db  'running under MOS. Severe disk errors can result if you are         ',cr,lf  ;@@XLAT
		db  'allowed to continue. Please alert all users and remove all          ',cr,lf  ;@@XLAT
		db  'other tasks and re-start VERIFY.                            ',cr,lf,0  ;@@XLAT
s_inv_unalloc	db  'Invalid cluster number   ',0  ;@@XLAT
s_inv_unalloc1	db  ' in Allocation table position ',0  ;@@XLAT
s_inv_unalloc2	db  '.',cr,lf,0


s_cmsg_lead	db	cr,lf,'A critical error occured - ',0
s_cmsg13	db	'write protect',cr,lf,0 ;@@XLAT
s_cmsg14	db	'unknown unit',cr,lf,0 ;@@XLAT
s_cmsg15	db	'drive not ready',cr,lf,0 ;@@XLAT
s_cmsg16	db	'unknown command',cr,lf,0 ;@@XLAT
s_cmsg17	db	'data error',cr,lf,0 ;@@XLAT
s_cmsg18	db	'bad request structure',cr,lf,0 ;@@XLAT
s_cmsg19	db	'seek error',cr,lf,0 ;@@XLAT
s_cmsg1a	db	'unknown media',cr,lf,0 ;@@XLAT
s_cmsg1b	db	'sector not found',cr,lf,0 ;@@XLAT
s_cmsg1c	db	'printer out ofpaper',cr,lf,0 ;@@XLAT
s_cmsg1d	db	'device write error',cr,lf,0 ;@@XLAT
s_cmsg1e	db	'device read error',cr,lf,0 ;@@XLAT
s_cmsg1f	db	'general failure',cr,lf,0 ;@@XLAT

s_cmsg_tbl	dw	s_cmsg13,s_cmsg14,s_cmsg15,s_cmsg16
		dw	s_cmsg17,s_cmsg18,s_cmsg19
		dw	s_cmsg1a,s_cmsg1b,s_cmsg1c
		dw	s_cmsg1d,s_cmsg1e,s_cmsg1f

;==== misc strings

s_root		db  '\',0
s_cdir		db  65 dup (0)	; startup directory storage area.
s_dotdot db	'..',0
s_crlf		db  cr,lf,0

;==== flag variables

f_fix		db	0	; if true then write fixup data to disk.
f_dfrag 	db	0	; true if fragmented files are displayed.
f_verify	db	0	; if true then display status during operation.
f_xlink 	db	0	; cross linked files found.
f_fat_modified	db	0	; true if in-memory fat has been corrected.
f_dir_modified	db	0	; true if individual directory was corrected.
f_dir_init	db	0	; true if we have created dir mask fcb.
f_shut_state	db	0	; b0 = 1 if need to restore drive
				; b1 = 1 if need to restore directory
				; b2 = 1 if need to restore int1b
				; b3 = 1 if need to restore tcbcmap
;==== byte variables

b_fats		db	0	; number of fats on device.
b_fatnum	db	0	; current fat in fat segment.
b_media 	db	0	; device media descriptor byte.
b_current	db	0	; start up drive.
b_check_drive	db	0	; drive to check.
b_exit_status	db	2	; exit status (assume bad error)
stklvl		db	0	; nest level
is_mos		db	0	; flags when mos is the host os
cshift		db	0	; sector shift count
b_i24_error	db	0	; al value from i21f59 during i24

;==== word variables

w_frag		dw	0	; true if the current file is frag'd.
w_fatlen	dw	0	; length of each fat in sectors.
w_psp_seg	dw	0	; segment of psp base segment.
w_fragment	dw	0	; count of files fragmented in system.
w_dirs		dw	0	; number of root directory entries.
w_fatsize	dw	0	; fatsize (0=1.5, 1=2, etc).
w_fat1		dw	0	; start sector of fat #1.
w_non_contig	dw	0	; non-contiguous cluster count.
w_file_count	dw	0	; file counter.
w_hide_count	dw	0	; hidden file counter.
w_dir_count	dw	0	; dir counter.
w_frag_count	dw	0	; fragmented file counter.
w_file_clus	dw	0	; clusters used by visible files
w_hide_clus	dw	0	; clusters used by hidden files
w_dir_clus	dw	0	; clusters used by directories
w_temp		dw	0	; temporary used by divide32.
w_comma 	dw	0	; comma counter for 32-bit decimal output.
w_dir		dw	0	; start sector of directory.
w_sect		dw	0	; current sector in  w_dirs_seg buffer.
w_dir_sec_off	dw	0
w_last_dir_sec	dw	-1
w_bad_sec_cnt	dw	0
w_unall_clus	dw	0
w_alloc_clus	dw	0
w_lost_start	dw	0
clusters	dw	0	; number of clusters on drive.
cluster_siz	dw	0	; number of sectors in cluster.
sector_siz	dw	0	; number of bytes in sector.
w_dirs_seg	dw	0	; directory stack segment.
dos_version	dw	?	; dos version number
mos_version	dw	?	; mos specific version number
lost_clusters	dw	0	; total lost clusters found
lost_chains	dw	0	; total lost chains found
x_off		dw	0	; xlinked dirs offset preserve area.
w_fat_seg	dw	0	; segment base of fat table buffer
normal_fat_seg	dw	0	; segment of dummy 16bit fat table
expected_size	dw	0
eoc_table	dw	0fffh	; end of cluster values for 12&16 fat
		dw	0ffffh
eoc		dw	0	; end of cluster value for current disk.
file_clusters	dw	0	; cluster count of current file.
last_cluster	dw	0	; last cluster processed by mark_fat_chain
bad_sec_table	dw	00ff7h	; bad cluster values for 12&16 bit fat.
		dw	0fff7h
bad_sec_val	dw	0
clstrcnt	dw	0	; number of cluster files written.
curtcb		dw	?	; segment of current tcb

;==== dword variables

extvect		dd	0	; pointer to extended services handler
orig1b		dd	?	; original int1b vector

;==== misc buffers

dtalen		equ	1+(size extheader)+(size direntry)

;==== start of fields which must stay together
dta_base	db	?	; i21f11 puts drive code here
dta_exhd	extheader <>	; extended header portion
dta_dir		direntry <>	; directory entry portion
;==== end of fields which must stay together

x_dir		db	66 dup(0)	; xlinked directory preserve area.
x_dta		db	dtalen dup(0)	; xlinked dta preserve area.
numlen		db	0		; length of string in [numbuf]
numbuf		db	20 dup (0)	; asciiz number conversion buffer.
asciizfn	db	128 dup(0)	; asciiz file name buffer
dir_entry	db	32 dup (0)
chkfcb		db	0,'LOSTDAT'	; lost cluster file control block.
chknum		db	'0000',24 dup (0)  ; number buffer
delfcb		db	0,'LOSTDAT????',24 dup (0)
s_extfcb	extfcb	<>
control_packet	diskio	<>	; parameter buffer for int25 and int26 calls
orig_cmap	db	7 dup(0)	; original tcbcmap values

chkdata 	ends

chkcode	segment para public 'CODE'
	assume cs:chkcode,ds:nothing,es:nothing,ss:nothing

	include	verify.pub

	subttl verify - disk allocation check routine
	page
;======================================================================
;,fs
; verify - disk allocation check routine
;
; check disk main entry point.
; free unneeded memory.
; get current drive
; parse command line tail.
; set specified drive if requested in command tail.
; preserve current directory.
; set current directory to root directory.
; get drive specifications.
; get current drive label name.
; allocate data segment for fat table
; load fat table.
; allocate directory stack area.
; restore current directory.
; restore current drive.
; return to mos.
;
; in:	ss:sp -> stack
;	ds -> psp segment
;
; out:
;
;,fe
;======================================================================
	assume ds:nothing,es:nothing,ss:nothing
verify proc near

; calc end of code/data/stack and shrink back

	mov	bx,offset end_of_code+15
	mov	cl,4
	shr	bx,cl
	add	bx,seg chkcode
	sub	bx,seg begin_seg
	add	bx,10h
	mov	ah,04ah
	int	21h

; record psp segment and establish data segment

	mov	bx,ds
	mov	ax,seg chkdata
	mov	ds,ax
	assume	ds:chkdata
	mov	[w_psp_seg],bx
	call	docrlf

; to ensure an orderly shutdown, hook the int1b, int23 and int24 vectors.
; note: not saving int23 and int24 since there's no need to restore them
; upon termination.

	mov	ax,351bh
	int	21h
	mov	word ptr [orig1b],bx
	mov	word ptr [orig1b+2],es
	push	ds
	mov	ax,ds
	mov	es,ax
	assume	es:chkdata
	mov	ax,cs
	mov	ds,ax
	assume	ds:nothing
	mov	ax,251bh
	mov	dx,offset i23_iret
	int	21h
	or	[f_shut_state],00000100b
	mov	ax,2523h
	mov	dx,offset i23_iret
	int	21h
	mov	ax,2524h
	mov	dx,offset i24_fail
	int	21h
	pop	ds
	assume	ds:chkdata,es:nothing

; read the mos and dos version numbers

	mov	ax,3000h
	mov	bx,ax
	mov	cx,ax
	mov	dx,ax
	int	21h
	mov	[mos_version],ax
	mov	ax,30ffh
	int	21h
	mov	[dos_version],ax

; use the dos version number to verify that this tool can run.
; this way, this verify.exe can run under dos 4.x or newer and
; under any version of mos which represents a dos version number
; of 4.x or newer.

	cmp	al,4
	jnb	ver011

; if dos version is less than 4.0, we must check true dos version
; using INT 21h function 3306

	xor	bx,bx
	mov	ax,3306h
	int	21h
	cmp	bl,5
	jne	ver05
	mov	ax,bx	
	jmp	short ver011
ver05:
	mov	dx,offset s_bad_version
	call	printline
	jmp	ver130
ver011:

; still need to know if we're running under dos or mos -- for the
; sake of the multiple task test and security issues.

	cmp	ax,[mos_version]
	je	ver020
	mov	[is_mos],true

; if running under mos, initialize extvect by indirect access to
; mos's SCB data structure.

	mov	ah,34h
	int	21h
	assume	es:nothing
	les	bx,es:[bx-18h]
	mov	word ptr [extvect],bx
	mov	word ptr [extvect+2],es

; if running under mos, get segment of current tcb for future use.

	mov	ah,4
	mov	bx,-1
	pushf
	cli
	call	[extvect]
	mov	[curtcb],es

; if running under mos, save the current class map array and
; then reset it to open up security.

	push	ds
	mov	ds,[curtcb]
	assume	ds:tcb
	mov	si,offset tcbcmap
	mov	di,seg chkdata
	mov	es,di
	mov	di,offset orig_cmap
	mov	cx,7
	cld
	rep	movsb
	pop	ds
	assume	ds:chkdata
	mov	es,[curtcb]
	mov	di,offset tcbcmap
	mov	cx,7
	mov	al,0ffh
	rep	stosb
	or	[f_shut_state],00001000b
ver020:

; init the s_extfcb record

	mov	[s_extfcb].extSignature,0ffh
	mov	di,offset s_extfcb.extFileName
	mov	cx,ds
	mov	es,cx
	mov	cx,11
	mov	al,'?'
	cld
	rep	stosb

; record original default drive

	mov	ah,getdrive
	int	21h
	mov	[b_check_drive],al	; assume current drive for now.
	mov	[b_current],al

; get command tail arguments (also sets specified drive).

	mov	es,[w_psp_seg]
	call	get_args
	ljc	ver130

; if running under mos and more than one task exists and the /f option
; was specified, must not continue.

	cmp	[f_fix],true
	jne	ver024
	cmp	[is_mos],true
	jne	ver024
	push	es
	mov	ah,2
	pushf
	cli
	call	[extvect]
	mov	dx,es:[bx]		; get pointer to first tcb
	inc	bx
	inc	bx			; and compare it to last tcb
	cmp	dx,es:[bx]		; if they are alike then continue
	pop	es
	jz	ver024
	mov	dx,offset s_fixup_err	; print error message
	call	printline
	jmp	ver130
ver024:

; check to see if on network drive

	xor	bh,bh
	mov	bl,[b_check_drive]
	inc	bl
	mov	ax,4409h
	int	21h
	test	dx,1000h
	jz	ver025
	mov	dx,offset nonetdr
	call	printline
	jmp	ver130
ver025:

; get disk specifications.

	call	get_specs
	ljc	ver130

; now that the sector size is known, allocate a sector buffer area

	mov	bx,[sector_siz]
	add	bx,15
	shr	bx,1
	shr	bx,1
	shr	bx,1
	shr	bx,1
	mov	ah,048h
	int	21h
	jnc	ver026
	mov	dx,offset s_err_dirs
	call	printline
	jmp	ver130
ver026:
	mov	[w_dirs_seg],ax

; record the current directory and make the root be the current dir

	mov	si,offset s_cdir+1
	mov	dl,[b_check_drive]
	inc	dl
	mov	ah,047h
	int	21h
	mov	byte ptr s_cdir,'/'
	mov	dx,offset s_root
	mov	ah,03bh
	int	21h
	ljc	ver130
	or	[f_shut_state],00000010b

; verify media

	call	check_mos_media
	ljc	ver130

; if /f was specified, delete any existing fixup files

	cmp	f_fix,0
	jz	ver028
	mov	dx,offset delfcb
	mov	ah,013h
	int	21h
ver028:

; get volume name of current device, and write it to s_volname buffer.
; buffer defaults to no label on entry.

	mov	dx,offset s_volprefix
	mov	ah,01ah
	int	21h
	mov	[s_extfcb].extAttribute,volmask
	mov	dx,offset s_extfcb
	mov	ah,011h
	int	21h
	mov	byte ptr [s_volname+11],0

; calc memory required to hold 1 fat copy and allocate a buffer

	mov	ax,[w_fatlen]
	mul	[sector_siz]
	mov	cx,4
ver030:
	shr	dx,1
	rcr	ax,1
	loop	ver030
	mov	bx,ax
	inc	bx
	push	ds
	mov	ah,48h
	int	21h
	mov	[w_fat_seg],ax
	pop	ds
	ljc	ver130

; read fat into the buffer.

	call	read_fat
	jnc	ver040
	lea	dx,s_err_dirs
	call	printline
	jmp	ver130
ver040:
	mov	[b_exit_status],0
	mov	dx,offset dta_base
	mov	ah,1ah
	int	21h

; this is the start of the main processing loop.
; process all file in current dir.

ver050:
	call	process_files		
	mov	[s_extfcb].extAttribute,00010111b ; find all directories
	mov	dx,offset s_extfcb
	mov	ah,11h
	int	21h
ver060:
	cmp	al,0			; when al != 0,done with current dir
	jz	ver070
	cmp	[stklvl],0		; need to restore to previous dir?
	lje	ver120
	mov	dx,offset s_dotdot
	mov	ah,3bh			; back up to parent
	int	21h
	dec	[stklvl]
	call	restore_pos		; restore the fcb search data
	jmp	short ver080
ver070:

; filter out all but honest-to-goodness directories

	test	[dta_dir].deAttributes,dirmask
	jz	ver080
	cmp	[dta_dir].deName,'.'	; skip . and .. at this point
	je	ver080
	call	save_pos		; save fcb search data
	inc	[stklvl]		; update depth record
	mov	di,offset asciizfn	; convert dta name to asciiz
	call	dtanam2z
	mov	dx,offset asciizfn	; and change to that directory
	mov	ah,3bh
	int	21h
	inc	[w_dir_count]		; increment directory counter.

; process the current directory

	mov	[w_frag],0
	call	mark_fat_chain
	call	update_counts

; verify .

	mov	[s_extfcb].extAttribute,00010111b ; find all directories
	mov	dx,offset s_extfcb
	mov	ah,11h
	int	21h
	or	al,al
	jnz	ver090
	test	[dta_dir].deAttributes,dirmask
	jz	ver100
	cmp	[dta_dir].deName,'.'
	jne	ver100

; verify ..

	mov	dx,offset s_extfcb
	mov	ah,12h			; find the next entry
	int	21h
	or	al,al
	jnz	ver090
	test	[dta_dir].deAttributes,dirmask
	jz	ver100
	cmp	[dta_dir].deName,'.'
	jne	ver100
	cmp	[dta_dir].deName+1,'.'
	jne	ver100
	jmp	ver050
ver080:
	mov	dx,offset s_extfcb
	mov	ah,12h			; find the next entry
	int	21h
	jmp	ver060

; error handlers.

ver090:
	mov	dx,offset asciizfn
	call	printline
	call	docrlf
	call	docrlf
	mov	dx,offset s_err_dir
	jmp	short ver110
ver100:
	mov	dx,offset s_invld_sub
	call	printline
	mov	dx,offset asciizfn
ver110:
	call	printline
	jmp	ver130

; final processing for non-error case.

ver120:
	call	validate_rest
	call	exit_report
ver130:
	call	shutdown
verify endp

	subttl shutdown - prepare for termination
	page
;======================================================================
;,fs
; shutdown - prepare for termination
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
shutdown proc near
	mov	ax,seg chkdata
	mov	ds,ax
	assume	ds:chkdata

; if a critical error occured, report it.

	mov	al,[b_i24_error]
	cmp	al,0
	je	shu030
	mov	dx,offset s_cmsg_lead
	call	printline
	cmp	al,13h
	jb	shu010
	cmp	al,1fh
	jbe	shu020
shu010:
	mov	al,1fh
shu020:
	sub	al,13h
	xor	ah,ah
	add	ax,ax
	mov	bx,ax
	lea	bx,[bx+s_cmsg_tbl]
	mov	dx,[bx]
	call	printline
shu030:

; decode the shutdown state.

	test	[f_shut_state],00000001b
	jz	shu040

; restore the original drive.

	mov	dl,[b_current]
	mov	ah,setdrive
	int	21h
shu040:
	test	[f_shut_state],00000010b
	jz	shu050

; restore the original directory.

	mov	dx,offset s_cdir
	mov	ah,03bh
	int	21h
	mov	ah,0dh
	int	21h
shu050:
	test	[f_shut_state],00000100b
	jz	shu060

; restore the original int1b vector.

	mov	ax,251bh
	push	ds
	lds	dx,[orig1b]
	assume	ds:nothing
	int	21h
	pop	ds
	assume	ds:chkdata
shu060:
	test	[f_shut_state],00001000b
	jz	shu070

; restore the original security class map.

	mov	si,offset orig_cmap
	mov	es,[curtcb]
	assume	es:tcb
	mov	di,offset tcbcmap
	mov	cx,7
	cld
	rep	movsb
shu070:
	mov	ah,4ch
	mov	al,[b_exit_status]
	int	21h
shutdown endp

	subttl i23_iret - prevent cntrl-c termination
	page
;======================================================================
;,fs
; i23_iret - prevent cntrl-c termination
;
; also used for int1b
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
i23_iret proc far
	iret
i23_iret endp

	subttl i24_fail - ensure orderly termination
	page
;======================================================================
;,fs
; i24_fail - ensure orderly termination
;
; in:	
;
; out:	
;
;,fe
;======================================================================
	assume	ds:nothing,es:nothing,ss:nothing
i24_fail proc far
	pushset	ax,bx,cx,dx,si,di,bp,ds,es
	mov	ax,seg chkdata
	mov	ds,ax
	assume	ds:chkdata
	mov	ah,59h
	int	21h
	mov	[b_i24_error],al
	popset	ax,bx,cx,dx,si,di,bp,ds,es
	assume	ds:nothing
	mov	al,3
	iret
i24_fail endp

	subttl get_args - process command line arguments
	page
;======================================================================
;,fs
; get_args - process command line arguments
;
; this function parses the command line tail to determine the options
; requested by the user.
;
; mos passes command tail in [psp_seg]:80
; first byte is length of command tail
;
; x:	set drive specifier ( assume current drive if not found )
; /f	set fix flag to true.
; /v	set verify flat to true.
; /h	display help screen
;
; in:	es -> psp
;
; out:	[f_fix] set true if '/f' in command tail.
;	[f_verify] set true if '/v' in command tail.
;	[f_dfrag] set true if /c in command tail.
;	cf set true if error occurred
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
get_args proc near
	mov	si,080h			; set offset
	mov	al,es:[si]		; get command tail length
	or	al,al			; check for no tail
	jnz	gtg010			; nothing to parse...
	xor	ax,ax			; clear error report
	clc
	ret				; and return to caller.
gtg010:
	xor	cx,cx			; clear counter.
	mov	cl,al			; move length to counter.
	inc	si			; increment input pointer.
gtg020:
	mov	al,es:[si]		; get a byte.
	cmp	al,' '			; is it a space?
	jz	gtg040			; then skip it.
	cmp	al,'/'			; is it a slash?
	jz	gtg050			; check for user flag.
	cmp	al,':'			; is it a colon?
	jz	gtg110			; check for drive letter.
	cmp	al,'?'			; do they want help?
	jnz	gtg040			; display help as requested.
	cmp	al,'.'			; ignore wildcard characters.
	jz	gtg040
	cmp	al,'?'			; ignore wildcard characters
	jz	gtg040
	cmp	al,'*'			; ignore wildcard characters
	jz	gtg040
gtg030:
	mov	dx,offset s_help	; get help screen string
	call	printline
	mov	[b_exit_status],1	; error code for exit
	stc				; set carry flag
	ret				; return to main loop
gtg040:
	inc	si			; increment input pointer
	dec	cx			; decrement length counter
	jnz	gtg020			; loop until counter is zero.
	clc
	ret				; return to caller.
gtg050:
	inc	si			; skip over gtg050 character
	dec	cx			; dec counter
	mov	al,es:[si]		; get character from tail.
	call	ucase			; uppercase character
	cmp	al,'V'			; is it verify flag?
	jnz	gtg060			; continue if not...
	mov	[f_verify],true		; set verify flag
	jmp	gtg040			; loop back around.
gtg060:
	cmp	al,'C'			; is it non-contig?
	jnz	gtg070			; continue if not...
	mov	[f_dfrag],true		; set display flag true.
	jmp	gtg040			; loop back around.
gtg070:
	cmp	al,'F'			; is it fixup flag?
	jnz	gtg090			; continue if not.
	mov	[f_fix],true		; set fix flag true.
	jmp	gtg040			; loop back around.
gtg090:
	cmp	al,'H'			; do they want help?
	jz	gtg030			; go to help display options
gtg100:
	mov	dx,offset s_bad_arg	; get bad argument string
	call	printline		; and print it.
	jmp	gtg040			; return to loop.
gtg110:
	mov	al,es:[si-1]		; get previous character
	call	ucase
	sub	al,'A'
	mov	dl,al			; put drive number in dl
	mov	ah,setdrive		; do set drive function
	int	21h
	mov	ah,getdrive		; do get drive function
	int	21h
	cmp	dl,al			; are they the same?
	jnz	gtg120			; report bad drive.
	mov	[b_check_drive],al	; store good drive.
	or	[f_shut_state],00000001b
	jmp	gtg040			; loop around for more..
gtg120:
	mov	dx,offset s_bad_drive	; get bad drive string
	call	printline
	stc				; set carry flag to report error
	ret				; return to caller
get_args endp

	subttl get_specs - get drive specifications.
	page
;======================================================================
;,fs
; get_specs - get drive specifications.
;
; drive specifications are returned to caller by pointing ds:bx to
; the disk param block. this is a un-documented function according
; to jim bean.
;
; in:	dl = drive letter (0=default..a=1)
;	be sure to preserve ds before entry.
;
; out:	ds:bx points to device descriptor table.
;	cf set true if error occurred
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
get_specs proc near
	push	es
	push	ds

; find the dpb

	mov	dl,[b_check_drive]
	inc	dl
	mov	ah,032h
	int	21h
	push	ds
	pop	es
	pop	ds
	or	al,al
	jnz	gts030
	assume	es:nothing

; make local record of dpb data

	mov	dx,word ptr es:[bx].dpbFirstFAT
	mov	[w_fat1],dx
	mov	ax,es:[bx].dpbFatSize
	mov	[w_fatlen],ax
	mov	dx,word ptr es:[bx].dpbSectorSize
	mov	[sector_siz],dx
	mov	dx,word ptr es:[bx].dpbDirSector
	mov	[w_dir],dx
	mov	al,byte ptr es:[bx].dpbFATCount
	mov	[b_fats],al
	mov	ax,word ptr es:[bx].dpbRootEntries
	mov	[w_dirs],ax
	mov	ax,word ptr es:[bx].dpbMaxCluster
	dec	ax
	mov	[clusters],ax

; if drive is smaller than 4087 clusters, 12 bit fat, else 16

	cmp	ax,4087
	jb	gts010
	mov	[w_fatsize],1
gts010:
	mov	cl,byte ptr es:[bx].dpbClusterShift
	mov	[cshift],cl
	add	ax,word ptr es:[bx].dpbFirstSector
	mov	al,byte ptr es:[bx].dpbMedia
	mov	[b_media],al
gts020:
	pop	es
	or	ax,ax
	ret
gts030:
	pop	es
	mov	dx,offset s_spec_err
	call	printline
	stc
	ret
get_specs endp

	subttl dtanam2z - xfer dta filename to asciiz buffer
	page
;======================================================================
;,fs
; dtanam2z - xfer dta filename to asciiz buffer
;
; in:	es:di -> buffer for asciiz string
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
dtanam2z proc near
	pushset ax,cx,si,di,es
	mov	cx,ds
	mov	es,cx
	mov	si,offset [dta_dir].deName
	mov	cx,8			; xfer up to 8 chars for fname
dtz010:
	lodsb
	cmp	al,' '
	je	dtz020
	stosb
	loop	dtz010
dtz020:
	mov	si,offset [dta_dir].deExtension	; advance to extension
	cmp	byte ptr [si],' '
	jne	dtz030
	xor	al,al
	stosb				; if no ext,all done
	jmp	short dtz060
dtz030:
	mov	al,'.'
	stosb				; insert seperator
	mov	cx,3
dtz040:
	lodsb				; xfer up to 3 characters
	cmp	al,' '
	je	dtz050
	stosb
	loop	dtz040
dtz050:
	xor	al,al
	stosb
dtz060:
	popset ax,cx,si,di,es
	ret
dtanam2z endp

	subttl save_pos - record fcb search data
	page
;======================================================================
;,fs
; save_pos - record fcb search data
;
; mos places the following position data within the fcb:
;
; extfcb+19	byte	search attribute
; extfcb+20	word	offset into sector
; extfcb+22	word	low part of sector #
; extfcb+24	word	high part of sector #
; extfcb+26	byte	drive #
;
; in:	ds -> segment for s_extfcb
;
; out:	crashes ax and bx
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
save_pos proc near
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
save_pos endp

	subttl restore_pos - restore search data to fcb
	page
;======================================================================
;,fs
; restore_pos - restore search data to fcb
;
; in:	ds -> segment for s_extfcb
;
; out:	crashes ax and bx
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
restore_pos proc near
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
restore_pos endp

	subttl process_files - process each entry within the current dir
	page
;======================================================================
;,fs
;  process_files - process each entry within the current dir
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
process_files proc near

; setup for loop to find all files within the current directory

	call	save_pos
	mov	[s_extfcb].extAttribute,00000111b ; find all files
	mov	dx,offset s_extfcb
	mov	ah,11h
	int	21h
pfl010:
	cmp	al,0			; end of current directory?
	jne	pfl040

; processing for each file entry goes here

	test	[dta_dir].deAttributes,hidden
	jz	pfl020
	inc	[w_hide_count]
	jmp	short 	pfl030
pfl020:
	inc	[w_file_count]
pfl030:
	mov	al,[f_dfrag]
	or	al,[f_verify]		; do they want to see operations
	jz	pfl032
	call	format_pathname		; format file name if so
pfl032:
	mov	[w_frag],0		; reset fragmented file flag
	call	mark_fat_chain		; check allocation chain.
	call	update_counts		; update count of files,etc.
	call	print_filename_stuff	; display file stuff if needed.
	mov	dx,offset s_extfcb
	mov	ah,12h			; find the next entry
	int	21h
	jmp	pfl010
pfl040:
	call	restore_pos
	ret
process_files endp

	subttl read_fat - read fat from current drive into fat segment.
	page
;======================================================================
;,fs
; read_fat - read fat from current drive into fat segment.
;
; this function will read the fat from the current drive into the
; allocated fat segment. if it is called again,it reads the next
; fat into the fat segment. this routine will read as many fats as
; are on the device.  reads fats of up to 256 sectors ok
;
; allocate fat segment large enough to hold one fat. load first fat
; into fat segment.
; allocate cluster buffer and initialize it to zeros.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
read_fat proc near
	push	ds
	mov	al,[b_check_drive]	; get current drive number.
	mov	cx,[w_fatlen]		; get fat length in sectors.
	push	cx			; remember this when ds is gone
	cmp	cx,80h
	jbe	rdf010			; if fat fits in 64k
	mov	cx,80h			; it doesn't fit,read 64K
rdf010:
	mov	dx,[w_fat1]		; get fat start sector number.
	push	ax
	mov	bx,offset control_packet
	mov	dx,[w_fat1]
	mov	word ptr [bx].diStartSector,dx
	mov	word ptr [bx].diStartSector+2,0
	mov	word ptr [bx].diSectors,cx
	mov	word ptr [bx].diBuffer,0
	mov	cx,[w_fat_seg]
	mov	word ptr [bx].diBuffer+2,cx
	mov	cx,-1
	push	dx
	int	25h
	popf				; restore flags.
	pop	dx
	pop	ax			; disk number
	pop	cx			; and fat length
	sub	cx,80h
	jle	rdf020			; if fat <= 64k

; fat bigger than 64k,read the rest of it.
; ax is ok as is,cx already has number of sectors to read.

	add	dx,80h			; next sector number is 80h greater


;!!!!!	mov	si,ds
	mov	si,[w_fat_seg]

	add	si,1000h		; advance seg 4096 paras (64k)
	mov	bx,offset control_packet
	mov	word ptr [bx].diStartSector,dx
	mov	word ptr [bx].diStartSector+2,0
	mov	word ptr [bx].diSectors,cx
	mov	word ptr [bx].diBuffer,0
	mov	word ptr [bx].diBuffer+2,si
	mov	cx,-1
	int	25h
	popf				; get rid of flags
rdf020:
	pop	ds			; restore our data segment.

; build 16 bit fat buffer and initialize it to zeros.

	mov	bx,[clusters]		; allocate space for the normalized
	add	bx,9			; take acount for 2 at beginning
	mov	cl,3
	shr	bx,cl
	mov	ah,48h
	int	21h
	jc	rdf040			; return on allocation error
	mov	[normal_fat_seg],ax
	push	es			; initialize the normalized fat table
	mov	es,ax			; to zeroes.
	xor	ax,ax
	mov	cx,[clusters]

;!!!!!!! could wrap?

	inc	cx
	inc	cx
	mov	di,ax

; following fix initializes pseudo-fat (ug...)	for fat > 64k

	cmp	cx,8000h
	jbe	rdf030
	sub	cx,8000h
	push	cx
	mov	cx,8000h
	rep	stosw
	pop	cx
	mov	di,es
	add	di,1000h
	mov	es,di
	xor	di,di
rdf030:
	rep	stosw
	pop	es
	mov	bx,[w_fatsize]		; set variable eoc to current
	shl	bx,1			; end of cluster chain marker
	mov	ax,eoc_table[bx]	; (00fffh for 12-bit fat and
	mov	[eoc],ax		;  0ffffh for 16-bit fat).
	mov	ax,bad_sec_table [bx]	; do the same for the bad sector
	mov	[bad_sec_val],ax	; value.
	clc				; clear carry (error flag)
rdf040:
	ret				; return to caller.
read_fat endp

	subttl write_fat - write current copy of fat in w_fat_seg to disk.
	page
;======================================================================
;,fs
; write_fat - write current copy of fat in w_fat_seg to disk.
;
; if [f_fix] is false,then skip write,fixup is ignored.
; if [f_fat_modified] is false,then skip write,no fixup is needed.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
write_fat proc near
	push	ds
	mov	al,byte ptr [f_fix]
	or	al,al
	jz	wrf020			; exit if fat is not to be written
	cmp	[f_fat_modified],0	; has fat been changed?
	jz	wrf020			; exit if not.
	mov	al,[b_check_drive]	; get current drive number.
	mov	cx,[w_fatlen]		; get fat length in sectors.
	push	cx			; save for after int 26 call
	cmp	cx,80h
	jbe	wrf010			; if fat fits in 64k
	mov	cx,80h			; if too big,read first 64k
wrf010:
	push	ax
	mov	bx,offset control_packet
	mov	dx,[w_fat1]
	mov	word ptr [bx].diStartSector,dx
	mov	word ptr [bx].diStartSector+2,0
	mov	word ptr [bx].diSectors,cx
	mov	word ptr [bx].diBuffer,0
	mov	cx,[w_fat_seg]
	mov	word ptr [bx].diBuffer+2,cx
	mov	cx,-1
	push	dx
	int	26h
	popf				; restore flags.
	pop	dx			; remember sector number
	pop	ax			; disk number
	pop	cx			; and fat length
	sub	cx,80h
	jle	wrf020			; if fat < 64k & all written now

; write part of fat above 64k.

	add	dx,80h			; next sector is 80h further.

;!!!!	mov	si,ds			; advance ds by 64k (4096 paragraphs)
	mov	si,[w_fat_seg]

	add	si,1000h
	mov	bx,offset control_packet
	mov	word ptr [bx].diStartSector,dx
	mov	word ptr [bx].diStartSector+2,0
	mov	word ptr [bx].diSectors,cx
	mov	word ptr [bx].diBuffer,0
	mov	word ptr [bx].diBuffer+2,si
	mov	cx,-1
	push	dx
	int	26h
	popf				; restore flags.
wrf020:
	pop	ds			; restore our data segment.
	ret
write_fat endp

	subttl get_fat - get cluster number for specified fat entry.
	page
;======================================================================
;,fs
; get_fat - get cluster number for specified fat entry.
;
; return specified cluster data depending on whether the fat is 12 or
; 16 bit fat.
; all registers but ax preserved.
;
; in:	bx  fat entry number (2..xx)
;
; out:	ax  cluster number
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
get_fat proc near
	push	bx
	push	cx
	push	dx
	push	di
	push	es
	mov	es,[w_fat_seg]
	mov	ax,[w_fatsize]
	or	ax,ax
	jz	gft010

; get 16-bit fat entry.  calculate segment & byte offsets.

	mov	ax,es			; we will do arithmetic on segment
	mov	di,bx			; save for byte offset calculation
	mov	cl,3
	shr	bx,cl			; convert to normalized segment
	and	bx,1000h		; bit 12 on only if > 64k fat
	add	ax,bx
	mov	es,ax			; es is now segment in fat
	shl	di,1
	mov	ax,word ptr es:[di]	; get word from fat buffer.
	jmp	gft030

; get 12-bit fat entry.

gft010:
	call	calc_12bit
	mov	ax,word ptr es:[di]	; get word from fat buffer.
	test	bl,1			; is it odd or even fat entry?
	jz	gft020
	mov	cl,4
	shr	ax,cl			; discard lsb nybble
	jmp	gft030
gft020:
	and	ah,0fh			; discard msb nybble
gft030:
	pop	es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	ret				; return to caller
get_fat endp

	subttl put_fat - set cluster number for specified fat entry.
	page
;======================================================================
;,fs
; put_fat - set cluster number for specified fat entry.
;
; in:	ax = cluster number
;	bx = fat entry number (2..xx)
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
put_fat proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	es
	mov	es,[w_fat_seg]
	mov	dx,ax
	mov	ax,[w_fatsize]
	or	ax,ax
	jz	ptf010

; write to a 16 bit fat.

	mov	ax,es			; we will do arithmetic on segment
	mov	di,bx			; save for byte offset calculation
	mov	cl,3
	shr	bx,cl			; convert to normalized segment
	and	bx,1000h		; bit 12 on only if > 64k fat
	add	ax,bx
	mov	es,ax			; es is now segment in fat
	shl	di,1
	mov	es:[di],dx		; put it back
	jmp	ptf040
ptf010:
	call	calc_12bit
	mov	ax,es:[di]
	test	bl,1
	jnz	ptf020
	and	ax,1111000000000000b
	jmp	ptf030
ptf020:
	and	ax,0000000000001111b
	mov	cl,4
	shl	dx,cl
ptf030:
	or	ax,dx
	mov	es:[di],ax		; put it back
ptf040:
	pop	es			; restore es
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret				; return to caller
put_fat endp

	subttl calc_12bit - calc offset into fat table for 12bit fat entry
	page
;======================================================================
;,fs
; calc_12bit - calc offset into fat table for 12bit fat entry
;
; in:	bx = fat entry number
;
; out:	di = offset into real fat buffer based zero.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
calc_12bit proc near
	push	dx
	mov	ax,3			; di = bx * 3 / 2
	mul	bx
	shr	ax,1
	mov	di,ax
	pop	dx			; restore used registers.
	ret
calc_12bit endp

	subttl mark_fat_chain - mark clusters used by file in pseudo-fat.
	page
;======================================================================
;,fs
; mark_fat_chain - mark clusters used by file in pseudo-fat.
;
; this routine does a number of things,including:
; look for cross-linked fat chains.
; verify the actual file (data) size against the value stored
; in the directory.
; call various correction and identification routines in the
; event that an error is detected.
; all registers but ax preserved.
;
; in:	  dta set to directory entry of file to scan and mark.
;
; out:	  carry flag set if error.
;	  ax  error code.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
mark_fat_chain proc near
	push	bx
	push	dx
	push	di
	push	es

; calculate the expected length of the file based on the file size
; field of the directory entry.  dta must contain current file.
; the number of clusters the file should take up is file size divided 
; by cluster size rounded up to the next integral value.

	mov	bx,[sector_siz]		
	mov	cl,[cshift]		
	shl	bx,cl			
	mov	ax,word ptr [dta_dir].deFileSize    
	mov	dx,word ptr [dta_dir].deFileSize+2  
	lea	cx,[bx-1]
	add	ax,cx
	adc	dx,0
	div	bx
	mov	[expected_size],ax

; if both the directory size and starting cluster are 0, exit

	or	ax,ax
	jnz	mfc010
	mov	ax,[dta_dir].deStartCluster
	or	ax,ax
	ljz	mfc110
mfc010:

; init counter for actual clusters.  then, if starting cluster number
; is 0, skip to termination logic at mfc101

	mov	[file_clusters],0
	mov	ax,[dta_dir].deStartCluster
	or	ax,ax
	ljz	mfc095

; validate the starting cluster number.

	call	good_fat
	jnc	mfc020

; starting cluster number is invalid.  zero the filesize and 
; starting cluster number and set the 'needs to be written' flag.

	xor	ax,ax
	mov	[b_exit_status],1
	mov	word ptr [dta_dir].deFileSize,ax
	mov	word ptr [dta_dir].deFileSize+2,ax
	mov	[dta_dir].deStartCluster,0
	mov	[f_dir_modified],1
	mov	dx,offset s_inv_first
	jmp	mfc120

; hold the starting cluster number in dx.  this value will be poked
; into each entry of the normalized fat table corresponding to a 
; cluster for this file.  init [last_cluster] and [w_frag] for 
; fragmented file monitoring.

mfc020:
	mov	dx,ax
	mov	[last_cluster],ax
	mov	[w_frag],0

; count this as an actual cluster and derive the address of
; the entry in the normalized fat table.

mfc030:
	inc	[file_clusters]
	mov	di,ax
	shl	di,1

; the following is necessary for fats > 64k

	mov	bx,[normal_fat_seg]
	test	ah,80h
	jz	mfc040
	add	bx,1000h
mfc040:
	mov	es,bx

; if the existing entry in the normalized fat table has already
; been set, this file is cross-linked.

	mov	bx,es:[di]
	or	bx,bx
	jz	mfc050
	call	recurse_fsystem
	jmp	mfc130
mfc050:

; get pointer to next cluster from reading the fat table.

	mov	bx,ax
	call	get_fat
	call	eoc_chain
	je	mfc090
	call	good_fat
	jnc	mfc070

; when find an invalid cluster in a chain, terminate the chain at the
; last valid cluster.  then, set the corresponding record in the
; normalized fat chain to show ownership by this file.  finally,
; update the file size to match the retained cluster count.  

	mov	bx,[last_cluster]
	mov	ax,[eoc]
	call	put_fat
	mov	es:[di],dx
	mov	ax,[sector_siz]
	mov	cl,[cshift]
	shl	ax,cl
	mul	[file_clusters]
	mov	word ptr [dta_dir].deFileSize,ax
	mov	word ptr [dta_dir].deFileSize+2,dx

; if /f was specified, make the os free the clusters.

	cmp	[f_fix],0
	jz	mfc060
	call	truncate_filesize
mfc060:
	mov	[f_fat_modified],1
	mov	[f_dir_modified],1

; note:  both the fat and the current directory entry
; have been modified and need to be written out!

	mov	dx,offset s_inv_trunc
	jmp	mfc120
mfc070:

; write starting cluster number of file to normal fat table.
; then calc what next cluster should be for a contiguous file,
; incrementing the counter and setting the flag if non-contig.

	mov	es:[di],dx
	mov	bx,ax
	dec	bx
	cmp	bx,[last_cluster]
	je	mfc080
	inc	[w_non_contig]
	inc	[w_frag]
mfc080:
	mov	[last_cluster],ax
	jmp	mfc030

; end of chain found.  write starting cluster number of file 
; to normalized fat table.  then, if the file is a directory,
; skip out.

mfc090:
	mov	word ptr es:[di],dx
	test	[dta_dir].deAttributes,dirmask
	jnz	mfc110

; does expected cluster count match with the actual number of 
; clusters counted?

mfc095:
	mov	ax,[file_clusters]
	cmp	ax,[expected_size]
	je	mfc110

; adjust directory size to match actual clusters

	mov	[b_exit_status],1
	mov	ax,[sector_siz]
	mov	cl,[cshift]
	shl	ax,cl
	mul	[file_clusters]
	mov	word ptr [dta_dir].deFileSize,ax
	mov	word ptr [dta_dir].deFileSize+2,dx
	cmp	[f_fix],0
	jz	mfc100
	call	truncate_filesize
mfc100:
	mov	dx,offset s_d_toolong
	jmp	short mfc120
mfc110:
	clc
	jmp	short mfc130
mfc120:
	push	dx
	call	format_pathname
	mov	dx,offset asciizfn
	call	printline
	pop	dx
	call	printline
	stc
mfc130:
	pop	es
	pop	di
	pop	dx
	pop	bx
	ret
mark_fat_chain endp

	subttl release_chain - release clusters past (bx) in alloc chain
	page
;======================================================================
;,fs
; release_chain - release clusters past (bx) in alloc chain
;
; release all clusters past (bx) in allocation chain
;
; in:	bx = starting cluster number
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
release_chain proc near
	call	get_fat			; get the next fat entry in the chain.
	mov	dx,ax
	xor	ax,ax			; zero it (mark it as available).
	call	put_fat			; put it back.
	mov	ax,dx			; restore next fat entry.
	call	eoc_chain		; last cluster of chain?
	je	rlc010			; exit loop if so.
	call	good_fat		; check for valid cluster number
	jc	rlc020			; abort on error
	mov	bx,ax
	jmp	release_chain		; loop around again
rlc010:
	clc				; return ok status
	ret
rlc020:
	mov	dx,ax
	stc				; return err status
	ret
release_chain endp

	subttl update_counts - update count of clusters used in file system.
	page
;======================================================================
;,fs
; update_counts - update count of clusters used in file system.
;
; this function will update the count of clusters used by visible
; files,hidden files,and directories for use in the output report.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
update_counts proc near
	push	ax
	push	bx
	mov	ax,[file_clusters]	; get count of clusters used
	cmp	ax,0			; did it use any
	je	upc040			; exit if no clusters
upc010:
	test	[dta_dir].deAttributes,dirmask  ; is this a directory
	jz	upc020			; process as file if no
	add	[w_dir_clus],ax		; add to directory cluster count
	jmp	upc040			; exit now
upc020:
	mov	bx,word ptr [dta_dir].deFileSize
	or	bx,word ptr [dta_dir].deFileSize+2
	je	upc040			; exit if 0 size
       	test	[dta_dir].deAttributes,hidden  ; is it a hidden file
	jz	upc030			; treat as normal file if no
	add	[w_hide_clus],ax	; add to hidden file cluster cou
	jmp	upc040			; exit now
upc030:
	add	[w_file_clus],ax	; add to visible file cluster co
upc040:
	pop	bx
	pop	ax
	ret				; return to caller
update_counts endp

	subttl rf_helper - perform test for recurse_fsystem
	page
;======================================================================
;,fs
; rf_helper - perform test for recurse_fsystem
;
; in:	bx = cross linked file cluster to search for.
;	valid dta entry
;
; out:	zr if cross linked cluster found and reported
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
rf_helper proc near
	cmp	bx,[dta_dir].deStartCluster ; is it file we're looking for?
	jnz	rfh010			; skip if not.
	mov	[dta_dir].deAttributes,0  ; insert null byte at end of fname
	mov	dx,offset [dta_dir].deName ; point to start of fname
	call	printline
	call	docrlf
	call	docrlf
	cmp	ax,ax			; set zr flag
rfh010:
	ret
rf_helper endp

	subttl recurse_fsystem - recurse file system to find cross linked file.
	page
;======================================================================
;,fs
; recurse_fsystem - recurse file system to find cross linked file.
;
; this function preserves the directory scan while backtracking to
; find another file that thinks it owns the cluster contained in bx.
; bx will be the number in the first cluster field of the fcb so we
; won't have to scan the FAT chain.
;
; in:	bx = cross linked file cluster to search for.
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
recurse_fsystem proc near
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
	mov	si,offset x_dir+1	; get current directory store area
	mov	dl,[b_check_drive]	; get check drive number
	inc	dl			; make base 1
	mov	ah,047h			; mos get current directory.
	int	21h
	mov	byte ptr x_dir,'\'	; precede with backslash
	mov	dx,offset s_root	; get root dir asciiz string addr.
	mov	ah,03bh			; mos set current directory.
	int	21h
	push	ds
	pop	es
	mov	si,offset dta_base
	mov	di,offset x_dta
	mov	cx,dtalen		; get dta length
	rep	movsb			; save current dta
	cmp	[f_xlink],0		; have we printed xlink error?
	jnz	rcf010			; skip if so.
	mov	dx,offset s_xl01	; get cross linked file message
	call	printline
	mov	[b_exit_status],1	; error code for exit
	mov	[f_xlink],1
rcf010:
	mov	dx,offset s_xl02
	call	printline
	mov	[dta_dir].deAttributes,0 ; insert null byte in filename
	mov	dx,offset [dta_dir].deName  ; point to start of fname
	call	printline
	mov	dx,offset s_xl03	; get " and " message
	call	printline
rcf020:

; loop to find and process all files within the current directory

	mov	si,bx
	call	save_pos
	mov	bx,si
	mov	[s_extfcb].extAttribute,00000111b ; find all files
	mov	dx,offset s_extfcb
	mov	ah,11h
	int	21h
rcf030:
	cmp	al,0			; end of current directory?
	jne	rcf050
	call	rf_helper		; check the file entry
	jnz	rcf040
	call	restore_pos		; if find,counterbalance stack
	jmp	rcf090			; and get out
rcf040:
	mov	dx,offset s_extfcb
	mov	ah,12h			; find the next entry
	int	21h
	jmp	short rcf030
rcf050:
	mov	si,bx
	call	restore_pos
	mov	bx,si

; loop to process each directory within the tree

	mov	[s_extfcb].extAttribute,00010111b ; find all directories
	mov	dx,offset s_extfcb
	mov	ah,11h
	int	21h
rcf060:
	cmp	al,0			; when al != 0,done with current dir
	jz	rcf070
	cmp	[stklvl],0		; need to restore to previous dir?
	lje	rcf090
	mov	dx,offset s_dotdot
	mov	ah,3bh			; back up to parent
	int	21h
	dec	[stklvl]
	mov	si,bx
	call	restore_pos		; restore the fcb search data
	mov	bx,si
	jmp	short rcf080
rcf070:

; filter out all but honest-to-goodness directories

	test	[dta_dir].deAttributes,dirmask
	jz	rcf080
	cmp	[dta_dir].deName,'.'	; skip . and .. at this point
	je	rcf080
	mov	si,bx
	call	save_pos		; save fcb search data
	mov	bx,si
	inc	[stklvl]		; update depth record
	mov	di,offset asciizfn	; convert dta name to asciiz
	call	dtanam2z
	mov	dx,offset asciizfn	; and change to that directory
	mov	ah,3bh
	int	21h
	call	rf_helper		; check the directory entry
	jz	rcf090
	mov	dx,offset s_extfcb
	mov	ah,11h			; skip past the .
	int	21h
	or	al,al
	jnz	rcf090
	mov	dx,offset s_extfcb
	mov	ah,12h			; skip past the ..
	int	21h
	or	al,al
	jnz	rcf090
	jmp	rcf020
rcf080:
	mov	dx,offset s_extfcb
	mov	ah,12h			; find the next entry
	int	21h
	jmp	rcf060
rcf090:
	cmp	[stklvl],0		; need to unwind the stack?
	je	rcf100
	dec	[stklvl]		; back out a level
	call	restore_pos		; restore the fcb search data
	jmp	short rcf090
rcf100:
	push	ds
	pop	es
	mov	si,offset x_dta
	mov	di,offset dta_base
	mov	cx,dtalen		; get dta length
	rep	movsb			; restore previous dta
	mov	dx,offset x_dir		; get previous directory.
	mov	ah,03bh			; mos set current directory.
	int	21h
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
recurse_fsystem endp

	subttl ucase - convert to upper case
	page
;======================================================================
;,fs
; ucase - convert to upper case
;
; in:	al = input character.
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
ucase proc near
	cmp	al,'a'			; is it below lowercase?
	jb	ucs010			; exit if so.
	cmp	al,123			; is it above lowercase?
	jnb	ucs010			; exit if so.
	sub	al,32			; otherwise uppercase it.
ucs010:
	ret
ucase endp

	subttl docrlf - print a cr/lf to console
	page
;======================================================================
;,fs
; docrlf - print a cr/lf to console
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
docrlf proc near
	push	dx
	mov	dx,offset s_crlf
	call	printline
	pop	dx
	ret
docrlf endp

	subttl printline - output string to console.
	page
;======================================================================
;,fs
; printline - output string to console.
;
; we scan for end of string with scasb instruction setting cx to
; length of string. next call mos write function to output string.
;
; in:	ds:dx pointer to string to print.
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
printline proc near
	push	ax			; preserve all registers changed
	push	bx			; including flags
	push	cx
	push	es
	push	di
	push	si
	pushf
	push	ds
	pop	es			; set es=ds
	xor	ax,ax			; clear ax
	mov	cx,0ffffh		; set default counter.
	mov	di,dx
	cld				; clear direction flag ( increment )
	repne	scasb			; loop until null is found.
	mov	ax,-2			; correct result
	sub	ax,cx
	xchg	ax,cx			; put result back in cx
	mov	bx,01			; get mos console handle
	mov	ah,040h			; mos write to console
	int	21h
	popf				; restore flags
	pop	si			; and other registers
	pop	di
	pop	es
	pop	cx
	pop	bx
	pop	ax
	ret
printline endp

	subttl putchar - output character in al to console device.
	page
;======================================================================
;,fs
; putchar - output character in al to console device.
;
; output character in al to console. if re-direction is done
; then the character will be re-directed in normal fashion.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
putchar proc near
	push	dx
	push	ax
	mov	dl,al			; put character in dl.
	mov	ah,2			; mos print character on display.
	int	21h
	pop	ax
	pop	dx
	ret				; return to caller.
putchar endp

	subttl dec16out - output 16 bit value in dx on console.
	page
;======================================================================
;,fs
; dec16out - output 16 bit value in dx on console.
;
; in:	dx = number to convert to decimal and output to console.
;
; out:	no registers are changed.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
dec16out proc near
	push	es			; preserve registers
	push	di
	push	dx
	push	bx
	push	ax
	pushf
	std
	mov	di,offset numbuf+5	; get data area
	mov	ax,ds
	mov	es,ax
	mov	bx,10			; set divisor (number base).
	xor	al,al
	stos	byte ptr es:[di]	; terminate string.
dct010:
	mov	ax,dx			; get remaining portion of number.
	xor	dx,dx			; clear top half of 32-bit dividend.
	div	bx			; divide by 10.
	xchg	ax,dx
	add	al,'0'			; make number into ascii.
	stos	byte ptr es:[di]	; save it into numbuf.
	or	dx,dx			; is remainder zero?
	jnz	dct010
	lea	dx,[di+1]		; point to leftmost ascii decimal digit.
	call	printline
	popf
	pop	ax			; restore registers..
	pop	bx
	pop	dx
	pop	di
	pop	es
	ret
dec16out endp

	subttl dec32out - decimal conversion
	page
;======================================================================
;,fs
; dec32out - decimal conversion
;
; in:	dx:ax = number to convert and output.
;
; out:	no registers are changed.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
dec32out proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	pushf
 	push	ax			; save lsw of number for initialization.
	mov	ax,ds			; set es = ds for string moves.
	mov	es,ax
 	cld				; blank-pad the output buffer.
	mov	di,offset numbuf
	mov	cx,13
	mov	al,' '
	rep	stos byte ptr es:[di]
 	std				; zero-terminate the buffer and position
	xor	al,al			; di to last digit position.
	stos	byte ptr es:[di]
 	mov	w_comma,0		; initialize the comma counter.
 	pop	ax			; restore lsw of number.
dco010:
	push	di
	mov	di,0			; setup 32-bit divisor.
	mov	si,10
	call	divide32		; divide by 10.
	pop	di
	push	ax
	mov	al,bl			; get the remainder of the division.
	add	al,'0'			; make number into ascii.
	stos	byte ptr es:[di]	; save it into numbuf.
	pop	ax
	mov	bx,ax			; have we run out of digits?
	or	bx,dx
	jz	dco020			; if not,go around again.
	inc	w_comma			; increment comma counter.
	cmp	w_comma,11b
	jnz	dco010
	mov	w_comma,0
	push	ax
	mov	al,','
	stos	byte ptr es:[di]
	pop	ax
	jmp	dco010
dco020:
	mov	dx,offset numbuf
	call	printline
	popf
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
dec32out endp

	subttl format_pathname - develop full pathname
	page
;======================================================================
;,fs
; format_pathname - develop full pathname
;
; in:
;
; out:	all registers preserved.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
format_pathname proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	push	ds
	pop	es

; initialize asciizfn buffer to nulls.

	mov	cx,dirlen		; set buffer length
	shr	cx,1
	xor	ax,ax
	mov	di,offset asciizfn
	rep	stos word ptr es:[di]
	mov	al,[b_check_drive]	; print the drive name.
	add	al,'A'
	mov	[asciizfn],al		; plug drive letter into asciizfn
	mov	[asciizfn+1],':'	; and colon:
	mov	byte ptr [asciizfn+2],'\' ; plug backslash prefix

; get current mos pathname into asciizfn buffer

	mov	si,offset asciizfn+3
	xor	dx,dx			; specify default drive.
	mov	ah,047h			; get current directory.
	int	21h

; check to see if we need to suffix returned string with a slash

	mov	di,offset asciizfn+3
	cmp	[asciizfn+3],0		; is it root directory?
	jz	fmp010			; skip middle slash stuff.
	xor	ax,ax			; clear comparison bytes.
	mov	cx,dirlen		; set max scan count
	repne	scasb			; look for eol byte.
	mov	byte ptr es:[di-1],'\'	; suffix current dir with slash
fmp010:
	call	dtanam2z		; put current dta fcb file name in asciizfn.
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
format_pathname endp

	subttl print_filename_stuff
	page
;======================================================================
;,fs
; print_filename_stuff
;
; if [f_verify] is true then display the filename on console.
; if [f_dfrag] is true then display only the fragmented files.
; if both are true then display whole display in line
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
print_filename_stuff proc near
	cmp	w_frag,0
	jz	pfs010
	inc	[w_frag_count]		; record another fragmented file.
pfs010:
	cmp	f_verify,0		; do they want to see operations
	jz	pfs020			; skip if not.
	mov	dx,offset asciizfn	; get filename
	call	printline
pfs020:
	cmp	[f_dfrag],0		; are fragmented files displayed?
	jz	pfs040			; skip it if not.
	cmp	[w_frag],0		; is file fragmented flag set?
	jz	pfs040			; skip message if not.
	cmp	[f_verify],0		; have we already printed filename?
	jnz	pfs030			; skip if so.
	mov	dx,offset asciizfn	; get filename
	call	printline
pfs030:
	mov	dx,offset s_frag1	; get "has " string
	call	printline
	mov	dx,[w_frag]		; get number of fragments.
	inc	dx
	call	dec16out		; output ascii number
	mov	dx,offset s_frag2	; get "frag... clusters" string
	call	printline
	ret
pfs040:
	cmp	[f_verify],0		; print crlf.
	jz	pfs042
	call	docrlf
pfs042:
	ret
print_filename_stuff endp

	subttl divide32 - divide a 32-bit number by another 32-bit number
	page
;======================================================================
;,fs
; divide32 - divide a 32-bit number by another 32-bit number
;
; in:	dx:ax  dividend.
;	di:si  divisor.
;
; out:	dx:ax	result/remainder.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
divide32 proc near
	xor	bx,bx
	mov	[w_temp],bx
	mov	cx,32
dvd010:
	xchg	cx,[w_temp]
	sal	ax,1
	rcl	dx,1
	rcl	bx,1
	rcl	cx,1
	cmp	di,cx
	ja	dvd030
	jb	dvd020
	cmp	si,bx
	ja	dvd030
dvd020:
	sub	bx,si
	sbb	cx,di
	inc	ax
dvd030:
	xchg	cx,[w_temp]
	loop	dvd010
	ret
divide32 endp

	subttl check_mos_media
	page
;======================================================================
;,fs
; check_mos_media
;
; this is a simple check to see if the device is a "MOS" formatted
; disk. return carry set if error reading drive or suspected non-mos
; disk is detected.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
check_mos_media proc near
	mov	al,[b_check_drive]	; get current drive number.
	mov	si,[w_dirs_seg]
	mov	bx,offset control_packet
	mov	word ptr [bx].diStartSector,0
	mov	word ptr [bx].diStartSector+2,0
	mov	word ptr [bx].diSectors,1
	mov	word ptr [bx].diBuffer,0
	mov	word ptr [bx].diBuffer+2,si
	mov	cx,-1
	int	25h
	jc	ckm020			; abort on read error.
	popf				; restore flags.
	push	es
	mov	es,[w_dirs_seg]		; point to data buffer
	cmp	byte ptr es:[21],0f0h	; make sure it is within range
	jb	ckm010			; from f0h to ffh
	pop	es
	clc				; clear any error flag
	ret				; return to caller.

; probable non-mos disk. warn user and continue at their risk!

ckm010:
	pop	es
	mov	dx,offset s_non_mos
	call	printline
	stc
	ret

; report error reading the disk boot sector. drive is probably not ready!

ckm020:
	popf
	mov	dx,offset s_media_err
	call	printline
	stc				; set carry to report error.
	ret
check_mos_media endp

	subttl bytes_to_kbytes - convert bytes to k-bytes
	page
;======================================================================
;,fs
; bytes_to_kbytes - convert bytes to k-bytes
;
; in:	dx:ax  number to convert.
;
; out:	dx:ax	result.
;	registers ax and dx modified.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
bytes_to_kbytes proc near
	push	cx
	add	ax,1023			; round up.
	adc	dx,0
	mov	cx,10			; shift 32-bit number right by 10-bits.
btk010:
	shr	dx,1
	rcr	ax,1
	loop	btk010
	pop	cx
	ret
bytes_to_kbytes endp

	subttl validate_rest - validates parts of fat not part of file chain.
	page
;======================================================================
;,fs
; validate_rest - validates parts of fat not part of file chain.
;
; this function runs through the fat table again and looks for parts
; of the disk that are not marked as free and also not part of any
; fat allocation chain. it's job is to report them if the /F option
; is not selected and if /f is true then convert the lost clusters
; to files in the root directory.
; after all fat entries are scanned then write out the modified fat
; to disk.
; all registers are preserved.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
validate_rest proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	es
	mov	[w_bad_sec_cnt],0
	mov	[w_unall_clus],0
	mov	[w_alloc_clus],0
	mov	dx,offset s_root	; get root dir asciiz string addr.
	mov	ah,03bh			; mos set current directory.
	int	21h
	mov	es,[normal_fat_seg]	; set up access to normalized fat.
	assume	es:nothing
	mov	si,2 * 2
	mov	bx,2
	mov	cx,[clusters]
vld010:
	lods	word ptr es:[si]	; get a word from the normalized fat.
	push	bx			; save loop variables.
	push	cx
	push	si
	or	ax,ax			; in a file?
	jz	vld020
	inc	[w_alloc_clus]
	jmp	vld110
vld020:
	call	get_fat			; get the entry out of the real fat.
	or	ax,ax			; is the entry unallocated?
	jnz	vld030
	inc	[w_unall_clus]
	jmp	vld110
vld030:
	mov	dx,ax			; is the entry a cluster containing a
	cmp	dx,[bad_sec_val]	; bad sector?
	jne	vld040
	inc	[w_bad_sec_cnt]		; counter 'em up.
	jmp	vld110
vld040:

; entry in normalized fat not marked but real fat entry is non-0
; and not marked as a known-bad cluster.

	call	eoc_chain		; is it a one cluster file?
	je	vld060			; if so,convert it to a file.
	call	good_fat		; is the cluster number valid?
	jnc	vld060			; if so,convertr the chain to a file.

; the entry in the actual fat is a rouge.

	push	bx			; save for printing error message.
	push	ax
	mov	[b_exit_status],1	; error code for exit
	xor	ax,ax			; zero the fat entry,since it's
	call	put_fat			; invalid.
	mov	[f_fat_modified],1	; set the "FAT modified" flag.
	mov	dx,offset s_inv_unalloc
	call	printline
	pop	dx
	call	dec16out
	mov	dx,offset s_inv_unalloc1
	call	printline
	pop	dx
	call	dec16out
	mov	dx,offset s_inv_unalloc2
	call	printline
	jmp	vld110

; have found a lost cluster so follow the chain to make sure it 
; is valid, terminating it at the first invalid entry.  
; then a file can be made out of the validated cluster chain,
; hopefully recovering something of value.

vld060:
	mov	[w_lost_start],bx
	mov	[last_cluster],bx
	mov	[file_clusters],0
	mov	dx,bx
vld070:
	inc	[file_clusters]
	inc	[lost_clusters]
	mov	di,bx
	shl	di,1
	call	get_fat
	call	eoc_chain		; last cluster of chain?
	je	vld090
	call	good_fat		; valid cluster number?
	jc	vld080			; if not,
	mov	bx,word ptr es:[di]	; get existing value in normalized
	or	bx,bx			; fat table.
	jnz	vld080			; cross-links detected at this point
					; just terminate the chain.
	mov	word ptr es:[di],dx
	mov	[last_cluster],ax
	mov	bx,ax
	jmp	vld070

; routine to terminate a chain in the event of a bad cluster number.

vld080:
	mov	bx,[last_cluster]	; terminate the file at the last valid
	mov	ax,[eoc]		; cluster.
	call	put_fat
vld090:
	mov	word ptr es:[di],dx
	mov	[b_exit_status],1	; error code for exit
	cmp	[f_fix],0		; if fixup is to be done
	jnz	vld100
	inc	[lost_chains]
	jmp	vld110
vld100:
	call	build_lost_dir		; then build a dir entry for the cluster.
	mov	dx,offset s_convert_lost
	call	printline		; print message
vld110:
	pop	si			; restore loop variables.
	pop	cx
	pop	bx
	inc	bx
	dec	cx			; this instead of a loop instruction.

; following additions are for fats > 64k

	jz	vld130
	or	si,si
	jnz	vld120
	mov	ax,es
	add	ax,1000h
	mov	es,ax
vld120:
	jmp	vld010
vld130:
	call	write_fat		; write out modified fat segment

; if not doing /f, report count of clusters and chains.

	cmp	[f_fix],0
	jne	vld140
	mov	dx,[lost_clusters]
	or	dx,dx
	je	vld140
	call	dec16out

; trim extra spaces off end of substring

	push	es
	mov	ax,ds
	mov	es,ax
	cld
	xor	al,al
	mov	cx,0ffffh
	mov	di,offset s_lost_clstr
	repne	scasb
	dec	di
vld134:
	dec	di
	cmp	byte ptr es:[di],' '
	je	vld134
	mov	byte ptr es:[di+2],0
	pop	es

; display the message

	mov	dx,offset s_lost_clstr
	call	printline
	mov	dx,[lost_chains]
	call	dec16out
	mov	dx,offset s_lost_clstr2
	call	printline
vld140:
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
validate_rest endp

	subttl good_fat - perform range check on fat cluster number in ax.
	page
;======================================================================
;,fs
; good_fat - perform range check on fat cluster number in ax.
;
; perform range check on fat cluster number in ax.
;
; in:	ax = cluster number.
;
; out:	carry set on error.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
good_fat proc near
	or	ax,ax			; value (0)000 is invalid.
	jz	gdf020
	cmp	ax,1			; value (0)001 is invalid.
	je	gdf020
	cmp	ax,[bad_sec_val]	; don't regard a cluster already
	je	gdf010			; marked as invalid as "bad"
	push	ax
	dec	ax
	dec	ax
	cmp	ax,[clusters]		; values larger than cluster count are
	pop	ax
	ja	gdf020			; invalid.
gdf010:
	clc
	jmp	gdf030
gdf020:
	stc
gdf030:
	ret
good_fat endp

	subttl eoc_chain - detect end of cluster chain
	page
;======================================================================
;,fs
; eoc_chain - detect end of cluster chain
;
; note:  the specification says that (f)ff8-(f)fff are valid eoc
; values and that (f)ff8 is the only one used.  in fact,we have
; observed that (f)fff is the only value used.  therefore,this
; routine has been modified to recognize only (f)fff as eoc
; until we know better.
;
; in:	ax = cluster number
;
; out:	zf = true on end of cluster chain
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
eoc_chain proc near
	push	bx
	mov	bx,ax			; is this is the last cluster of the
	cmp	bx,[eoc]
	pop	bx
	ret
eoc_chain endp

	subttl build_lost_dir
	page
;======================================================================
;,fs
; build_lost_dir
;
; build directory entry for lost cluster chain.  uses [clstrcnt] for
; number in file name.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
build_lost_dir proc near
	push	es
	mov	dx,[clstrcnt]		; get current cluster file number
	call	fill_fcb_pad		; plug number into fcb area

; reset the fcb

	mov	[chkfcb],0
	push	cx
	push	di
	push	es
	mov	dx,ds
	mov	es,dx
	mov	di,offset chknum+4
	mov	cx,24
	xor	al,al
	cld
	rep	stosb
	pop	es
	pop	di
	pop	cx

; create a file just to create a directory entry.
; then close it right away and invalidate the sector number record
; so find_dir_entry will be sure to do a fresh read of the directory
; sectors.

	mov	dx,offset chkfcb
	push	dx
	mov	ah,016h
	int	21h
	pop	dx
	mov	ah,010h
	int	21h
	mov	[w_last_dir_sec],-1

; find the newly created directory entry and load it into the dta.

	call	find_dir_entry		; search for just created entry.

; update the directory entry and write it back out.

bld010:
	mov	ax,[sector_siz]		; calculate the file size in bytes
	mov	cl,[cshift]		; from the cluster size and the number
	shl	ax,cl			; of valid clusters.
	mul	[file_clusters]
	mov	word ptr dir_entry+28,ax; put the corrected size into the
	mov	word ptr dir_entry+30,dx; directory entry.
	mov	ax,[w_lost_start]
	mov	word ptr dir_entry+26,ax
	call	write_dir_entry
	pop	es
	ret
build_lost_dir endp

	subttl find_dir_entry
	page
;======================================================================
;,fs
; find_dir_entry
;
; perform search for matching directory entry while scanning the
; root directory disk area.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
find_dir_entry proc near
	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push	es
	pushf
	mov	ax,ds
	mov	es,ax
	cld
	mov	bx,0			; init dir entry number.
	mov	cx,[w_dirs]		; get max dir entry for root dir.
fde010:
	call	read_dir_entry		; read entry from dir area
	push	cx			; save number of entries in root
	mov	si,offset dir_entry
	mov	di,offset chkfcb+1	; get our file fcb area
	mov	cx,11
	or	ax,ax
	repe	cmpsb			; look for our fcb
	pop	cx
	je	fde020			; exit loop if found.
	inc	bx			; otherwise loop around
	loop	fde010
	popf
	stc				; if no find,set carry and exit.
	jmp	fde030
fde020:
	popf
	clc
fde030:
	pop	es
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
find_dir_entry endp

	subttl read_dir_entry - read a dir sector from disk into dir segment
	page
;======================================================================
;,fs
; read_dir_entry - read a dir sector from disk into dir segment
;
; in:	bx = directory entry number (offset zero) to read.
;
; out:	carry flag set on error.
;	first 32-bytes of dta set to the directory entry.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
read_dir_entry proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	ds
	push	es
	mov	ax,bx
	mov	bx,[sector_siz]		; calculate directory entries per
	mov	cl,5			; sector.
	shr	bx,cl
	div	bl			; calculate sector number within dir.
	mov	bl,ah			; calculte byte offset with directory
	xor	ah,ah
	shl	bx,cl			; sector.
	mov	[w_dir_sec_off],bx
	cmp	ax,[w_last_dir_sec]	; is it already in buffer
	je	rde010			; skip if so.
	mov	[w_last_dir_sec],ax	; preserve sector number
	call	read_dir_sector		; perform disk sector read.
rde010:
	mov	si,[w_dir_sec_off]
	mov	di,offset dir_entry
	mov	cx,32 / 2
	mov	ax,ds
	mov	es,ax
	mov	ds,[w_dirs_seg]
	rep	movsw
	pop	es
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
read_dir_entry endp

	subttl read_dir_sector - read a sector block from the directory
	page
;======================================================================
;,fs
; read_dir_sector - read a sector block from the directory
;
; in:	ax = sector offset into directory.
;
; out:	w_dirs_seg:0 is loaded with 512 bytes of data from read.
;	if carry is set then error occurred!
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
read_dir_sector proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	push	ds
	add	ax,[w_dir]		; add in directory base offset
	mov	dx,ax			; put it in dx
	mov	[w_sect],ax		; save it for later write.
	mov	al,[b_check_drive]	; get drive letter to check.
	mov	bx,offset control_packet
	mov	word ptr [bx].diStartSector,dx
	mov	word ptr [bx].diStartSector+2,0
	mov	word ptr [bx].diSectors,1
	mov	word ptr [bx].diBuffer,0
	mov	cx,[w_dirs_seg]
	mov	word ptr [bx].diBuffer+2,cx
	mov	cx,-1
	int	25h			; read sector from disk
	pop	ax			; throw away previous flags
	pop	ds
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
read_dir_sector endp

	subttl write_dir_entry
	page
;======================================================================
;,fs
; write_dir_entry
;
; in:
;
; out:	carry flag set on error.
;	entire directory sector containing the previously read
;	directory entry is written back out.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
write_dir_entry proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	es
	mov	es,[w_dirs_seg]		; get storage area
	mov	si,offset dir_entry
	mov	di,[w_dir_sec_off]
	mov	cx,32 / 2
	rep	movsw
	call	write_dir_sector
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
write_dir_entry endp

	subttl write_dir_sector - write a sector block from the directory
	page
;======================================================================
;,fs
; write_dir_sector - write a sector block from the directory
;
; in:
;
; out:	w_dirs_seg:0 is written back to same sector as was read.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
write_dir_sector proc near
	push	ax
	push	bx
	push	cx
	push	dx
	push	ds
	mov	al,[b_check_drive]	; get drive letter to check.
	mov	dx,[w_sect]		; get current sector in buffer
	mov	bx,offset control_packet
	mov	word ptr [bx].diStartSector,dx
	mov	word ptr [bx].diStartSector+2,0
	mov	word ptr [bx].diSectors,1
	mov	word ptr [bx].diBuffer,0
	mov	cx,[w_dirs_seg]
	mov	word ptr [bx].diBuffer+2,cx
	mov	cx,-1
	int	26h			; write sector from disk function
	pop	ax			; throw away previous flags
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
write_dir_sector endp

	subttl fill_fcnb pad - pad fcb number with 4 digit hex number.
	page
;======================================================================
;,fs
; fill_fcnb pad - pad fcb number with 4 digit hex number.
;
; this procedure takes [clstrcnt] and builds a ascii number filled
; into the chkfcb file control block.
;
; in:
;
; out:	no registers are changed.
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
fill_fcb_pad proc near
	push	es
	push	si
	push	ax
	push	cx
	push	dx
	mov	dx,[clstrcnt]		; get number to use.
	mov	cx,4			; character output counter
	push	ds
	pop	es
	mov	di,offset chknum	; get number area to pad.
ffp010:
	push	cx			; save loop counter counter
	mov	cl,4
	rol	dx,cl
	mov	al,dl
	and	al,0fh
	daa
	add	al,0f0h
	adc	al,040h
	stosb				; store byte in al to fcb area
	pop	cx			; restore loop counter.
	loop	ffp010
	inc	[clstrcnt]		; increment counter for next file.
	pop	dx
	pop	cx
	pop	ax
	pop	si
	pop	es
	ret
fill_fcb_pad endp

	subttl truncate_filesize
	page
;======================================================================
;,fs
; truncate_filesize
;
; this function will truncate the size of the file contained in [dta]
; to the size specified in the filesize dword in [dta].
; called by mark_fat_chain when a file dir entry has fewer clusters
; than the fat claims.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
truncate_filesize proc near
	call	format_pathname		; format dta into asciiz filename
	mov	dx,offset asciizfn	; get asciiz formatted filename
	mov	al,01			; set for write mode
	mov	ah,03dh			; mos open file handle
	int	21h
	mov	bx,ax
	mov	dx,word ptr [dta_dir].deFileSize ; put the corrected size into the
	mov	cx,word ptr [dta_dir].deFileSize+2 ; directory entry.
	xor	al,al
	mov	ah,042h
	int	21h
	xor	cx,cx
	mov	ah,040h
	int	21h
	mov	ah,03eh
	int	21h
	ret
truncate_filesize endp

	subttl exit_report
	page
;======================================================================
;,fs
; exit_report
;
; print final statistics screen for verify before exiting.
;
; in:
;
; out:
;
;,fe
;======================================================================
	assume ds:chkdata,es:nothing,ss:nothing
exit_report proc near
	call	docrlf			; skip down two lines
	mov	dx,offset s_vnamstr
	call	printline
	mov	al,[b_check_drive]	; get drive checked
	add	al,'A'			; convert to ascii
	call	putchar			; display the drive
	mov	al,':'
	call	putchar
	mov	al,' '
	call	putchar
	mov	dx,offset s_volname	; get current volume name
	call	printline
	call	docrlf
	call	docrlf			; skip down two lines
	mov	dx,offset s_total_vfiles
	call	printline
	xor	dx,dx
	mov	ax,[w_file_count]	; get visible file count.
	call	dec32out
	call	docrlf
	mov	dx,offset s_total_hfiles
	call	printline
	xor	dx,dx
	mov	ax,[w_hide_count]	; get hidden file count.
	call	dec32out
	call	docrlf
exr010:
	mov	dx,offset s_total_dirs
	call	printline
	xor	dx,dx
	mov	ax,[w_dir_count]	; get "total dirs" count
	call	dec32out		; output it
	call	docrlf
	cmp	[f_dfrag],0		; did they request fragment sta
	je	exr020			; show visible files if no
	mov	dx,offset s_total_frags	; otherwise report non-contigs.
	call	printline
	xor	dx,dx
	mov	ax,[w_frag_count]	; get non-contig file count.
	call	dec32out		; output it on console
	call	docrlf			; with cr lf.

; calculate bytes used by visible files

exr020:
	call	docrlf			; add another blank line
       	mov	dx,offset s_vfile_bytes
	call	printline
	mov	ax,[sector_siz]		; calculate cluster size.
	mov	cl,[cshift]
	shl	ax,cl
	mov	bx,[w_file_clus]
	mul	bx
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al,'k'
	call	putchar
	call	docrlf

; calculate bytes used by hidden files

exr030:
	mov	dx,offset s_hfile_bytes
	call	printline
	mov	ax,[sector_siz]		; calculate cluster size.
	mov	cl,[cshift]
	shl	ax,cl
	mov	bx,[w_hide_clus]
	mul	bx
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al,'k'
	call	putchar
	call	docrlf

; calculate bytes used by directories

exr040:
	mov	dx,offset s_dir_bytes
	call	printline
	mov	ax,[sector_siz]		; calculate cluster size.
	mov	cl,[cshift]
	shl	ax,cl
	mov	bx,[w_dir_clus]
	mul	bx
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al,'k'
	call	putchar
	call	docrlf

; calculate total bytes tied up in bad sectors.

exr050:
	mov	bx,[w_bad_sec_cnt]
	mov	dx,offset s_bad_sects
	call	printline
	mov	ax,[sector_siz]		; calculate cluster size.
	mov	cl,[cshift]
	shl	ax,cl
	mul	bx
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al,'k'
	call	putchar
	call	docrlf

; calculate total bytes available on drive

exr060:
	mov	dx,offset s_avail_bytes
	call	printline
	mov	ax,[sector_siz]		; calculate cluster size.
	mov	cl,[cshift]
	shl	ax,cl
	mov	bx,[w_unall_clus]
	mul	bx
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al,'k'
	call	putchar
	call	docrlf
	call	docrlf

; calculate total bytes on drive

exr070:
	mov	dx,offset s_total_bytes
	call	printline
	mov	ax,[sector_siz]		; calculate cluster size.
	mov	cl,[cshift]
	shl	ax,cl
	mov	bx,[clusters]		; multiply by total number of clusters
	mul	bx			; to get total bytes on drive.
	call	dec32out
	call	bytes_to_kbytes
	call	dec32out
	mov	al,'k'
	call	putchar
	call	docrlf
exr080:
	ret
exit_report endp

end_of_code	label	near

chkcode	ends
	end verify


