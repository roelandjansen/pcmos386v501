	page	80,132

	include	executor.pub

	page

RS_PGM  equ     1               ; set if program segment allocated
RS_ENV  equ     2               ; set if environment allocated
RS_TRM  equ     4               ; set if terminate vector changed
RS_OPEN equ     16              ; set if filename is open

;	error codes returned to caller in ax

inv_func equ    01h
out_mem  equ    08h
inv_env  equ    0ah

	if	-1			; don't generate publics

userax	equ	word ptr [bp+00]
useral	equ	byte ptr [bp+00]
userah	equ	byte ptr [bp+01]
usercx	equ	word ptr [bp+02]
usersi	equ	word ptr [bp+04]
userdi	equ	word ptr [bp+06]
userbp	equ	word ptr [bp+08]
userdxds equ	dword ptr [bp+10]
userdx	equ	word ptr [bp+10]
userds	equ	word ptr [bp+12]
userbxes equ	dword ptr [bp+14]
userbx	equ	word ptr [bp+14]
useres	equ	word ptr [bp+16]
usersp	equ	word ptr [bp+18]
userss	equ	word ptr [bp+20]

svuscx		equ	word ptr  [bp-2]
svusdx		equ	word ptr  [bp-4]
parentpsp 	equ	word ptr  [bp-6]   ; segment of parent psp
envseg    	equ	word ptr  [bp-8]   ; Segment address of environment block
pgmseg    	equ	word ptr  [bp-10]  ; Segment address of program block
psize     	equ	word ptr  [bp-12]  ; paragraph length of load module (com or exe)
bsize     	equ	dword ptr [bp-16]  ; byte length of load module (com or exe)
lsz       	equ	dword ptr [bp-20]  ; current size to be loaded
lofs      	equ	word ptr  [bp-22]  ; current load offset
lseg      	equ	word ptr  [bp-24]  ; current load segment
flhdl     	equ	word ptr  [bp-26]  ; File handle save space
reloc     	equ	word ptr  [bp-28]  ; Relocation factor for func 3
adjust    	equ	word ptr  [bp-30]  ; Load location adjustment factor
mempara   	equ	word ptr  [bp-32]  ; size of memory in paragraphs
ReturnAX  	equ	word ptr  [bp-34]  ; value return in AX back to application
rsflags   	equ	byte ptr  [bp-36]  ; resources which must be returned
exeheader	equ	word ptr  [bp-64]  ; 28 bytes for exe header
reloitems	equ	word ptr  [bp-96]  ; 32 bytes for relocation items

RELOSIZE	equ	32		; nbr bytes in reloitems

stackbeg	equ	word ptr  [bp-98]  ; sp set to here after stack switch

	endif

	extrn	vrfyproc:dword
	extrn	execint21:dword

	page
cgroup	group	mainseg

mainseg	segment	word public
	assume	cs:cgroup,ds:nothing

;	This logic is entered via a near or far jump.  The stack and 
;	registers are as they were at entry to the int21 function 4b, 
;	with the following exceptions:
;
;	Interrupts are enabled;
;	ES, DS, and Flags are undefined;
;	the application's ES and DS are pushed onto the stack.

executor label   near
	public	executor

	pop	ds			; recover ds, es
	pop	es
	mov	cs:[stuserss],ss	; save caller's ss, sp
	mov	cs:[stusersp],sp

	push	es			; put regs on user stack
	push	ds
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax

	push	cs			; perform stack switch
	cli
	pop	ss
	mov	sp,offset stusersp
	sti

	push	es			; now put regs on our stack
	push	bx			; put bx,es together
	push	ds
	push	dx			; put dx,ds together
	push	bp
	push	di
	push	si
	push	cx
	push	ax
	mov	bp,sp

	lea	sp,[stackbeg]		; reserve stack frame for us
	jmp	short dfhexe1

invfunc:
	mov 	[userax],inv_func    	; error code for invalid func
invopen:
fundonstc:
	lds	si,dword ptr [usersp]
	or	byte ptr ds:[si+4],01h	; set carry
	jmp	fundondq1
dfhexe1:
	cmp	[useral],3		; pass invalid function reqs
	ja	invfunc			; back to dos
	cmp	[useral],2
	je	invfunc		

	xor	ax,ax
	mov	[pgmseg],ax		; clear exec working vars
	mov	[envseg],ax
	mov	[rsflags],al	

	mov	ah,51H 			; get psp segment
	int	21h
	mov	parentpsp,bx		; save parent psp
	mov	ax,3d20h		; Open for read, deny write share mode
	lds	dx,[userdxds]
	call	exint21
	jnc	fileok
	mov	[useral],al		; nothing to undo if open fails
	mov	[userah],0		; so just return error
	jmp	invopen	     		
fileok:
	or	rsflags,rs_open
	mov	[flhdl],ax		; save file handle
	cmp	[useral],3
	jne	fun4bx3d	

	les	bx,[userbxes]
	mov	ax,es:[bx]  		; overlay load segment 
	mov	[pgmseg],ax	
	mov	ax,es:[bx+2]
	mov	[reloc],ax		; overlay relocation factor
	jmp	fun4bx3a	

;	Determine environment size

fun4bx3d:				
	cld
	les	bx,[userbxes]
	mov	bx,es:[bx]	; Get pointer to environment
	or	bx,bx		; Should they inherit the parent's?
	jnz	fun4B1		; No
	mov	es,parentpsp	; get parent psp
	mov	bx,es:[2ch]	; env segment
fun4B1:
	mov	es,bx		; Point to env.
	xor	di,di		; Scan env. from start for end marker (00)
	xor	al,al
	mov	cx,8000H	; Scan up to 32K
fun4B1a:
	repne 	scasb		; Scan for 0
	je	fun4b2a 	; Found end of this string
	mov	ax,INV_ENV
	jmp	fun4berr
fun4B2a:
	scasb			; Is this a word of 0? (end of env.)
	jne	fun4B1a 	; Only single 0, continue scan
	add	di,2		; Point past additional string counter
	mov	si,di		; Save length of passed env.

;	Now add 'load path string' size to env. size

	mov	bx,di		; Save size of env. in bytes
	push	es		; Save env. pointer

	les	di,[userdxds]
	mov	dx,di
	xor	al,al
	mov	cx,100		; Go over max. for the hell of it (max=64)
	repne 	scasb		; Find end of string
	pop	es		; Get env. pointer back
	sub	di,dx		; Calc length of load path
	add	bx,di		; BX= total env. size in bytes

;	Allocate space for environment

	add	bx,0fH		; Round up to next seg
	shr	bx,1		; Calc # para's needed
	shr	bx,1
	shr	bx,1
	shr	bx,1
	mov	ah,48H
	int	21h
	jc	fun4bw1e

;	Now Copy environment to newly allocated block

	or	[rsflags],RS_ENV	; Environment allocated OK
	mov	cx,es			; DS=ES
	mov	ds,cx
	mov	es,ax			; Point to env. block
	push	di			; Save size of 'load path string'
	mov	cx,si			; Get size of env.
	xor	si,si
	xor	di,di
	rep 	movsb			; Move env.

	lds	si,[userdxds]
	pop	cx			; Get size of string
	mov	word ptr es:[di-2],1	; Set additional string count
	rep 	movsb			; Move 'load path string'
	mov	[envseg],es		; Save pointer to env. block

;	Allocate initial working space for program and create PSP

	mov	ah,48h			; we will try to allocate all memory
	mov	bx,-1
	int	21h
	cmp	bx,12h
	jb	fun4bw1e
	mov	ah,48H			; Allocate space
	int	21h
	jnc	fun4bw1
fun4bw1e:
	jmp	fun4berr		; Error

fun4bw1:
	mov	[mempara],bx		; save memory size
	or	[rsflags],RS_PGM	; program block allocated
	push	ax
	lds	bx,dword ptr [usersp]	;
	lds	dx,ds:[bx]		; ds:dx -> return address
	mov	ax,2522h		; set terminate address
	int	21h
	pop	ax
	or	[rsflags],RS_TRM
	mov	[pgmseg],ax		; Save block pointer for program
	mov	dx,ax			; Create new PSP here
	mov	ah,55h

	call	exint21
	mov	bx,parentpsp		; so now we must reset
	mov	ah,50H 			;   current psp back
	int	21h

	call	setmcb
fun4bx3a:
	mov	bx,[flhdl]
	mov	ds,[pgmseg]		; Get pointer to memory block
	mov	dx,100H 		; Load just after MB prefix
	cmp	[useral],3		; use offset 0 for func 3
	jne	fun4bx3g
	xor	dx,dx
fun4bx3g:
	mov	cx,2			; Read 1st word to check for EXE
	mov	ah,3fH			; Read file
	push	dx
	call	exint21
	pop	dx
	jc	fun4bw1e
	xchg	dx,bx
	cmp	word ptr ds:[bx],5a4dH	; Is this an EXE file?
	xchg	dx,bx
	jne	$+5
	jmp	fun4bEXE		; Do EXE processing

;	Now processing a COM file

	mov	ax,4202H		; Determine file size for load
	xor	cx,cx
	xor	dx,dx
	call	exint21
	jc	fun4bw1e
	mov	word ptr [bsize],ax
	mov	word ptr [bsize+2],dx	; byte length of file
	mov	cx,4
fun4b1c:
	shr	dx,1
	rcr	ax,1
	loop	fun4b1c
	mov	[psize],ax		; paragraph length of file
	mov	bx,[flhdl]
	mov	ax,4200H		; Reset file pointer to beginning
	xor     cx,cx
	xor	dx,dx
	call	exint21
	mov	ax,[psize]
	cmp	[useral], 3		; skip if OVERLAY
	je	fun4b2			; skip memory check too
	add	ax,10h
fun4b1d:
	mov	si,[mempara]		; get size of memory in paragraphs
	cmp	ax,si			; file too large for this block?
	jbe	fun4b2			; No, its ok for loading
	mov	ax,out_mem
	jmp	fun4berr		; Too large
fun4b2:

;	Read in COM file at PSP:100H

	mov	ax,[pgmseg]
	mov	[lseg],ax
	mov	[lofs],100h
	cmp	[useral],3
	jne	fun4b2x
	mov	[lofs], 0
fun4b2x:
	mov	ax,word ptr [bsize]
	mov	word ptr [lsz],ax
	mov	ax,word ptr [bsize+2]
	mov	word ptr [lsz+2],ax
f4bcla:
	mov	[svusdx],ds
	mov	dx,[lofs]
	mov	ax,dx
	and	dx,0fh
	mov	cl,4
	shr	ax,cl
	add	ax,[lseg]
	mov	ds,ax
	mov	cx,-512 		; at most 64K - 512 bytes at a time
	cmp	word ptr [lsz+2],0
	jne	f4bclb			; ne if > 64K left to read
	cmp	cx,word ptr [lsz]
	jbe	f4bclb			; be if 64K - 1 to 64K - 512 left read
	mov	cx,word ptr [lsz]	; else read what's there
f4bclb:
	mov	[svuscx],cx
	mov	ah,3fH
	call	exint21
	mov	dx,[svuscx]		; dx = amt supposed to have been read
	mov	ds,[svusdx]
	jc	f4bclc
	jcxz	f4bclc			; unforeseen err during EXEC if 0 read
	cmp	dx,cx
	je	f4bcld	
f4bclc:
	jmp	fun4berr
f4bcld:
	sub	word ptr [lsz],cx	; new length to be loaded according
	sbb	word ptr [lsz+2],0	;   to amount actually read
	add	word ptr [lofs],cx	; carry not possible
	mov	ax,word ptr [lsz]
	or	ax,word ptr [lsz+2]
	jnz	f4bcla
	and	[rsflags],NOT RS_OPEN	; clear open flag
	mov	bx,[flhdl]		; file handle
	mov	ah,3eH			; Close file
	call	exint21
	jc	f4bclc

	cmp	[useral],3		; if loading overlay
	jne	$+5			
	jmp	fun4bx3b		; then done - get out
	push	si
	call	fun4bPSP		; Init values in PSP
	pop	si
	cmp	[useral],1		; Is this a load and setup only?
	je	fun4B4

;	Set registers and enter loaded program
;	BX:CX with file size

	call	setdtapsp		; set default dta & current psp

	mov	bx,word ptr [bsize+2]
	mov	cx,word ptr [bsize]
	mov	ax,[pgmseg]		; Get pointer to PSP
	mov	dx,[ReturnAX]		; get return value for valid drive specifiers
	xor	di,di
	xor	bp,bp
	mov	es,ax
	mov	ds,ax

	cmp	si,1000H		; Is MB <64k?
	jae	f4bsk0
	shl	si,1
	shl	si,1
	shl	si,1
	shl	si,1
	cli
	mov	sp,si
	xor	si,si			; Init for task
	jmp	short f4bsk1
f4bsk0:
	cli
	mov	sp,0
f4bsk1:
	mov	ss,ax
	sti
	push	bp			; Set RETurn to INT 20H in top of stack
	push	ax			; New CS
	mov	ax,100H
	push	ax			; New IP
	mov	ax,dx			; set return value for valid drive
	xor	dx,dx			; specifiers
	retf				; Enter loaded COM file

fun4B4:					; don't execute

	les	di,[userbxes]
	add	di,0eH			; Point to storage for SS:SP and CS:IP
	xor	ax,ax			; SP
	cmp	si,1000H		; Is MB <64k?
	jae	f4bskok
	shl	si,1
	shl	si,1
	shl	si,1
	shl	si,1
	mov	ax,si
f4bskok:
	xor	si,si			; Init for task
	dec	ax
	dec	ax
	push	ax
	stosw				; SP
	mov	ax,[pgmseg]		; SS
	stosw
	mov	ax,100H 		; IP
	stosw
	mov	ax,[pgmseg]		; CS
	stosw
	mov	es,[pgmseg]
	pop	di
	cmp	word ptr [bsize+2],0	; is file > 65534 bytes?
	ja	fun4b4a 		; if bigger
	cmp	word ptr [bsize],0FFFEh
	ja	fun4b4a 		; if bigger
	xor	ax,ax
	stosw				; Set 0 RETurn address in stack
fun4b4a:
	call	setdtapsp		; set default dta & current psp
	mov 	[userax],bx		; ret ax pointing to psp
fundonclc:
	lds	si,dword ptr [usersp]
	and	byte ptr ds:[si+4],0feh	; clear carry
	jmp	fundondq1
fun4bEXE: 				; Do EXE processing

;-----------------------------------------------------------------------;
; Process EXE files here
;-----------------------------------------------------------------------;

	push	ss
	pop	ds
	lea	dx,[exeheader+2]
	mov	cx,1ah
	mov	bx,[flhdl]
	mov	ah,3fH			; Read file
	call	exint21
	jnc	$+5
	jmp	fun4berr

;	now calculate size base on exe header

	mov	ax,[exeheader+4] 	  ; file size in 512-byte pages
	mov	cl,5			  ; including exe header
	shl	ax,cl			  ; adjust it so that it is paragraphs
	sub	ax,word ptr [exeheader+8] ; subtract header size
	mov	[psize],ax
	mov	cx,4
	xor	dx,dx
m4xx:					; convert to bytes
	shl	ax,1
	rcl	dx,1
	loop	m4xx
	mov	word ptr [bsize],ax	; store for later file loading
	mov	word ptr [bsize+2],dx
m4bnhead:
	mov	ax,[psize]		; get program paragraphs
	cmp	[useral],3		; load overlay?
	jne	$+5
	jmp	fun4bx3c

	mov	dx,[exeheader+0ch] 	; MaxAlloc
	cmp	dx,[exeheader+0ah] 	; MinAlloc
	ja	f4bmma		   	; MaxAlloc > MinAlloc (as it should be)
	mov	dx,[exeheader+0ah]
	mov	[exeheader+0ch],dx
	jne	f4bmma			; MaxAlloc < MinAlloc (? replace w/ MinAlloc)
	or	dx,dx
	jz	f4bmmc			; MaxAlloc = MinAlloc = 0 allocate all
f4bmma:
	add	ax,dx			; Include MaxAlloc value
	jc	f4bmmc
f4bmmb:
	add	ax,10h			; add in room for PSP
	jnc	f4bmmd
f4bmmc:
	mov	ax,-1
f4bmmd:

;	check to see if we should allocate space just in 
;	case file is an EXEPack File
	
	push	es
	cmp	word ptr [pgmseg],0fffh 	; check if start seg < 1000h
	jb	f4bmmd0				
	jmp	f4bepdn 			; skip the 1 block case
f4bmmd0:
	cmp	word ptr [exeheader+6],0
	jne	f4bepdn 			; skip if not zero
	cmp	word ptr [exeheader+16h],0	; check cs
	jne	f4bx0				; always do it if non-zero
	cmp	word ptr [exeheader+14h],0	; check ip
	je	f4bepdn 			; skip if zero
f4bx0:

;	allocate space so that we don't get pack file corrupt message

	push	ax
	mov	es,[pgmseg]
	mov	ah,49h
	int	21h
	and	[rsflags],NOT RS_PGM	; program block not allocated
	mov	bx,0fffh		
	sub	bx,[envseg]
	mov	es,[envseg]
	mov	ah,4ah
	int	21h
	jc	f4boutmem
	mov	bx,12h
	mov	ah,48h
	int	21h
	jnc	f4bx2
f4boutmem:
	mov	ax, out_mem
	jmp	fun4berr
f4bx2:
	or	[rsflags],RS_PGM	; program block allocated	
	push	cx
	push	si
	push	di
	mov	ds,[pgmseg]
	mov	es,ax
	mov	cx,90h
	xor	si,si
	xor	di,di
	rep	movsw
	pop	di
	pop	si
	pop	cx
	pop	ax
f4bepdn:	
	pop	es

;	Continue with Exec

	push	es			; Save work area pointer
	mov	es,[pgmseg]		; PSP MB address
	mov	bx,ax			; Expand MB to max
	mov	ah,4aH			; SetBlock to maximum size (returns error)
	push	bx
	int	21h
	jnc	f4bexemx		; Maximum value OK
	pop	ax			; throw away max request
	pop	es			; Address work area
	push	es
	mov	ax,[psize]		; Now try load size+MinAlloc
	add	ax,word ptr [exeheader+0ah]	; MinAlloc
	jc	f4bmme
	add	ax,10h
	jnc	f4bmmf
f4bmme:
	mov	ax,-1
f4bmmf:
	cmp	bx,ax			; Is block large enough for min memory
	pop	ax
	jb	f4boutmem
	push	ax
	mov	es,[pgmseg]
	mov	ah,4aH			; Allocate largest block available
	push	bx
	int	21h
f4bexemx:
	call	setmcb
	pop	bx
	pop	es			; Work area address

;	compute start paragraph to load file

	mov	ax,[pgmseg]
	mov	[adjust],0010h		; load is directly after psp
	add	ax,10h			; load = pspseg + psp length if MaxAlloc <> 0
	cmp	word ptr [exeheader+0ch],0	; MaxAlloc=0?
	jne	f4baa
	cmp	word ptr [exeheader+0ah],0	; MinAlloc=0?
	jne	f4baa
	mov	ax,[pgmseg]		; else load at top of allocated region
	add	ax,bx
	sub	ax,[psize]

;	calculate adjustment factor for load
;	in this case load is up high and psp is down low 

	mov	bx,ax
	sub	bx,[pgmseg]
	mov	[adjust],bx
	jmp	short f4baa
fun4bx3c:
	mov	ax,[pgmseg]		; entry for func 3
f4baa:
	mov	[lseg],ax
	mov	[lofs],0		; always start at offset 0
	mov	ax,word ptr [bsize]	; load size of file in bytes
	mov	word ptr [lsz],ax
	mov	ax,word ptr [bsize+2]
	mov	word ptr [lsz+2],ax
	mov	dx,[exeheader+8]	; get header size
	mov	cl,4
	shl	dx,cl			; Calc # bytes
	mov	bx,[flhdl]		; File handle
	mov	ax,4200H		; Position file pointer to load module
	xor	cx,cx			;   (past header portion of file)
	call	exint21
	jc	f4blc
f4bla:

;	load the file up to 64K-512 bytes at a time

	mov	dx,[lofs]
	mov	ax,dx
	and	dx,0fh
	mov	cl,4
	shr	ax,cl
	add	ax,[lseg]
	mov	[lofs],dx		; store normalized lseg:lofs
	mov	[lseg],ax
	mov	ds,ax
	mov	cx,-512 		; at most 64K - 512 bytes at a time
	cmp	word ptr [lsz+2],0
	jne	f4blb			; ne if > 64K left to read
	cmp	cx,word ptr [lsz]
	jbe	f4blb			; be if 64K - 1 to 64K - 512 left read
	mov	cx,word ptr [lsz]	; else read what's there
f4blb:
	push	cx
	mov	ah,3fH
	call	exint21
	pop	dx			; dx = amount to have been read
	jc	f4blc
	mov	cx,ax			; actual length was returned in ax
	jcxz	f4blc			; unforeseen error during EXEC if 0
	cmp	dx,cx
	je	f4bld			; unf error if not all requested read
	jmp	short f4bldone		; header is wrong
f4blc:
	jmp	fun4berr
f4bld:
	sub	word ptr [lsz],cx	; new length to be loaded according
	sbb	word ptr [lsz+2],0	;   to amount actually read
	add	word ptr [lofs],cx	; carry not possible
	mov	ax,word ptr [lsz]
	or	ax,word ptr [lsz+2]
	jnz	f4bla
f4bldone:

;	Perform file relocation

	mov	ax,4200h		; position to relocation items
	xor	cx,cx
	mov	dx,[exeheader+18h]
	call	exint21
	jc	f4blc

	mov	dx,[pgmseg]
	add	dx,[adjust]		; Point past PSP (DX=start segment)
					; or in high memory if exe file desires
	cmp	[useral],3
	jne	fun4bx3f
	mov	dx,[reloc]		; func #3 - use relocation factor
fun4bx3f:
	mov	si,RELOSIZE		; offset within reloitems
	mov	cx,[exeheader+6]	; number of entries
	jcxz	f4brelx

;	Relocation loop

f4brel:

	cmp	si,RELOSIZE		; check if end of buffer
	jb	f4brel3

;	We have determined that the current EXE header entry is no longer
;	inside the currently allcoated SMP 512 byte block so we must now 
;	read the next 512 byte section and continue processing.

	push	bx
	push	cx
	push	dx

	push	ss
	pop	ds
	lea	dx,[reloitems]
	mov	cx,RELOSIZE		; make that RELOSIZE bytes!
	mov	ah,3fH			; Read file
	call	exint21

f4brelerr:
	pop	dx
	pop	cx
	pop	bx
	jnc	f4brel1
	jmp	fun4berr
f4brel1:
	xor	si,si			; si indexes reloitems

;
;	Adjust Relocation entry
;

f4brel3:

	mov	ax,[si+reloitems+2]	; segment value
	mov	di,[si+reloitems]	; offset value
	add	ax,dx			; Calc file offset
	mov	es,ax

	add	es:[di],dx		; Make relocation adjustment
	add	si,4			; Point to next entry
	loop	f4brel			; Continue through all entries

;	End of Relocation Loop

f4brelx:

	mov	ah,3eH			; Close file
	call	exint21
	jnc	$+5
	jmp	fun4berr
	and	[rsflags],NOT RS_OPEN	; clear open flags
	cmp	[useral],3
	jne	fun4bx3h
	jmp	fun4bx3b		; if func #3 - done, get out
fun4bx3h:
	push	dx			; Save 'Start Segment' value
	call	fun4bPSP		; Init values in PSP
	pop	dx
	cmp	[useral],1		; Is this a load and setup only?
	jne	fun4bya 		; No, run program

	les	di,[userbxes]
	add	di,0eH			; Point to storage for SS:SP and CS:IP
	mov	ax,[exeheader+10h]	; get sp value
	sub	ax,2
	stosw				; SP
	mov	ax,[exeheader+0eh]	; get ss
	add	ax,dx			; relocation adjustment to SS
	stosw				; SS
	mov	ax,[exeheader+14h]	; get ip
	stosw				; IP
	mov	ax,[exeheader+16h]	; get cs
	add	ax,dx			; Make adjustment
	stosw				; CS
	mov	es,[pgmseg]

	call	setdtapsp		; set default dta & current psp

	mov	[userax],es
	jmp	fundonclc
fun4bya:

;	Init registers and enter the application

	mov	ax,[exeheader+0eh]	; get ss value
	add	ax,dx			; Make relocation adjustment
	mov	bx,[exeheader+10h]	; get sp value

	push	ax
	push	bx
	push	dx
	call	setdtapsp		; set default dta & current psp
	pop	dx
	pop	bx
	mov	ax,[ReturnAX]		; get return ax

	push	ss
	pop	ds

	cli				; By convention
	pop	ss
	mov	sp,bx
	sti

	mov	bx,ds:[exeheader+16h]	; get cs
	add	bx,dx			; Make adjustment
	mov	cx,ds:[exeheader+14h]	; get ip
	xchg	ax,cx
	mov	dx,es			; Point to PSP
	mov	ds,dx			; appears that DOS has dx as PSP value!

	push	bx			; User App's segment
	push	ax			; User App's offset
	mov	ax,cx			; note that cx will contain			
	mov	bx,cx			; return value for valid drives	
	xor	cx,cx			
	retf

fun4bx3b:
	jmp	fundonclc

fun4berr:
	mov	[userax],ax		; save init error code

	test	[rsflags],RS_ENV	; environment returned?
	jz	f4berr3
	mov	es,[envseg]		; deallocate environment block
	mov	ah,49h
	int	21h
	jc	fun4bcrt
	and	[rsflags],NOT RS_ENV
f4berr3:
	test	[rsflags],RS_TRM
	jz	f4berr4 		; if no program block
	mov	es,[pgmseg]		; Get program block pointer
	lds	dx,es:[0ah]		; old terminate vector
	mov	ax,2522h		; restore the old vector
	int	21h
	jc	fun4bcrt		; if error, crash
	and	[rsflags],NOT RS_TRM
f4berr4:
	test	[rsflags],RS_PGM	; was a program block allocated?
	jz	f4berr16	
	mov	es,[pgmseg]		; deallocate program block
	mov	ah,49H		
	int	21h
	jc	fun4bcrt
	and	[rsflags],NOT RS_PGM
f4berr16:
	test	[rsflags],RS_OPEN 	; was program file open
	jz	f4berrend
	mov	bx,[flhdl]		; get handle	
	mov	ah,3eh
	call	exint21
	jnc	f4berrend	
fun4bcrt:
	mov	[userax],ax
f4berrend:
	jmp	fundonstc

setdtapsp	proc	near
	push	es
	mov	ax,[pgmseg]		; Get pointer to PSP
	push	ds
	mov	dx,80h			; Set default dta
	mov	ds,ax	
	mov	ah,1ah
	int	21h
	mov	ah,50h
	mov	bx,ds
	int	21h
	pop	ds

;	This MUST be done after ALL int 21's

	push	ds
	mov	ds,parentpsp
	mov	ax,[userss]
	mov	ds:[30h],ax		; save ss:sp in parent psp
	mov	ax,[usersp]		; DOS expects regs on stack
	sub	ax,9*2			; es,ds,bp,di,si,dx,cx,bx,ax
	mov	ds:[2eh],ax
	pop	ds		       
	pop	es
	ret
setdtapsp	endp

setmcb	proc	near
	push	es
	push	dx
	mov	dx,[pgmseg]		; Pgm is the owner
	mov	ax,[envseg]		; Point to MB
	dec	ax			; Point to MB prefix
	mov	es,ax			; Address prefix
	mov	es:[1],dx		; Set owner PSP address in env. MB
	mov	ax,[pgmseg]
	dec	ax
	mov	es,ax
	mov	es:[1],dx		; Set owner PSP address in PSP MB
	pop	es
	pop	dx
	ret
setmcb	endp

;-----------------------------------------------------------------------;
; This routine will load the PSP with the correct values		;
;-----------------------------------------------------------------------;
fun4bPSP proc	near

	push	ds

	lds	si,[userbxes]
	lds	si,[si+2]		; Get pointer to command line
	mov	es,[pgmseg]

;	Init command line at 80H

	mov	di,80h
	mov	cx,128
	rep 	movsb

	mov	si,es
	dec	si
	mov	ds,si			; pointer to memory block
	mov	si,ds:[3]		; size of block for program
	add	si,[pgmseg]		; start of program block
	mov	es:[2],si		; end of allocation field in PSP

;	compute if needed new PSP function call to 0:C0

	mov	ax, ds:[3]		; size of memory block in paragraphs
	cmp	ax, 0fffh	
	jae	f4bskip
	sub	ax, 10h 		; remove 10h paragraphs for PSP
	push	ax
	mov	cl, 4
	shl	ax, cl			; save offset in bytes
	mov	es:[6], ax 
	pop	ax
	neg	ax
	add	ax, 0ch 		; segment + 16*offset = 0:c0
	mov	es:[8], ax
f4bskip:

;	Set FCBs in PSP and validate drives

	lds	si,[userbxes]
	lds	si,[si+6]		; Get pointer to 1st FCB
        call    ff_chk
        jz      f4bskip2
	mov	di,5Ch
	mov	cx,6
	rep 	movsw
f4bskip2:
	lds	si,[userbxes]
	lds	si,[si+0aH]		; Get pointer to 2nd FCB
        call    ff_chk
        jz      f4bskip3
	mov	di,6Ch
	mov	cx,6
	rep 	movsw
f4bskip3:
	mov	ax,cs
	mov	ds,ax
	xor	cx,cx
	call	[vrfyproc]
	mov	[ReturnAX],cx		; save return value

	mov	ax,[envseg]		; Set env. pointer in PSP
	mov	es:[2ch],ax		; 2Ch

	mov	ax,[usersp]		; save caller's SS:SP in PSP
	mov	es:[2eh],ax		; at offset 2e-31
	mov	ax,[userss]
	mov	es:[30h],ax	
	pop	ds
	ret
fun4bPSP endp

;	if ds == ffff and si == ffff, return zr

ff_chk	proc	near
        push    ax
        push    bx
        mov     ax,ds
        mov     bx,si
        add     bx,1
        adc     ax,0
        or      ax,bx
        pop     bx
        pop     ax
        ret
ff_chk	endp

exint21	proc	near
	pushf
	cli
	call	dword ptr cs:[execint21]
	ret
exint21	endp

fundondq1 label	near
	mov	sp,bp
	pop	ax
	pop	cx
	pop	si
	pop	di
	pop	bp
	pop	dx
	pop	ds
	pop	bx
	pop	es

	cli
	mov	ss,cs:[stuserss]
	mov	sp,cs:[stusersp]
	sti
	iret

;	Private Stack for Executor

	even
	dw	64 dup(-1)		; extra stack space
	dw	49 dup(-1)		; stack frame for our scratch areas
	dw	 9 dup(-1)		; stack frame for caller's registers
stusersp dw	-1
stuserss dw	-1

;	End of Stack Area

progend	label	near
	public	progend

mainseg ends

	end
