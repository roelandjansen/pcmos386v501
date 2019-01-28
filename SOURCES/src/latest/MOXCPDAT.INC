comment ^===============================================================

mjs 01/05/87	removed execcode and execlink variables

sah 05/12/88	add farcall38 variable	($$shell.sys should never do an
		int 38h directly.

mjs 12/02/88	removed extraneous vars for environment management and
		console stack buffer.

rkg 12/05/88	expand size of critical window

rdg 12/16/88	added data items in the copy overlay area for (pathchek)

mjs 06/21/89	added code to manage the $compat$ environment variable.

sah 06/30/89	add variable for critical error handling to correct
		problem created with latest changes in critical handler

sah 07/06/89	add special piece of code fragment which is used to
		jump to the $$shell.sys code segment for int 23 vector

bwr 11/20/90	added new variable, "type_EOF" to manage the special
		case where the user does a type command and specifies
		the append ">>" to the same file.

bwr 12/17/90	added two new variables to the ccopy segment to deal
		with the new code written in moxcpint.asm that performs
		the copy file++,, logic.
		(sourceptr & targptr)

mjs 09/17/92	added targdrv (for lansat/id4f31).
		cleaned up module

=======================================================================^

; standard handles

stdin		equ	0000
stdout		equ	0001
stderr		equ	0002

; dos calls

cretfil		equ	3ch
openfil		equ	3dh
closfil		equ	3eh
readfil		equ	3fh
writfil		equ	40h
lseek		equ	42h
unqfil		equ	5ah
delfil		equ	41h
parsfil		equ	29h
duphndl		equ	45h
forcdup		equ	46h
quit		equ	4ch
getdate		equ	2ah
setdate		equ	2bh
gettime		equ	2ch
settime		equ	2dh
getdrv		equ	19h
setdrv		equ	0eh
getdir		equ	47h
chdir		equ	3bh
mkdir		equ	39h
rmdir		equ	3ah
getver		equ	30h
freemem		equ	49h
modmem		equ	4ah
getmem		equ	48h
getpsp		equ	62h
getret		equ	4dh
fndfrst		equ	4eh
fndnext		equ	4fh
getdta		equ	2fh
setdta		equ	1ah
getkey		equ	0ch
freespc		equ	36h
rename		equ	56h
ioctrl		equ	44h
setvct		equ	25h
getcoun		equ	38h
gsbrk		equ	33h
getverf		equ	54h
setverf		equ	2eh
srchfrs		equ	11h
srchnxt		equ	12h

; misc equs

true		equ	0ffh
false		equ	0
dtaaddr		equ	80h
cr		equ	13
lf		equ	10
eof		equ	1ah
tab		equ	9
bell		equ	7
bs		equ	8
bslash		equ	'\'
fslash		equ	'/'
escape		equ	27

rt		equ	03		; top row
ct		equ	10		; top column
rb		equ	10		; bottom row
cb		equ	69		; bottom column
color		equ	4fh		; white on red color for window

cmdmax		equ	9		; limit for cmdname
ebufmax		equ	80		; limit for extrbuf
inmax		equ	80		; limit for inbuf
outmax		equ	80		; limit for outbuf

; size and offset equ's

lbufsize	equ	128		; size of linebuf and related buffers

blkback		equ	0		; offset of back pointer in block stack
blkdesc		equ	2
blkeflg		equ	3		; offset of bateflg value in block stack
blkline		equ	4		; offset of batline value in block stack
blkecho		equ	8		; offset of batecho  "   "  "     "
blkfor		equ	9		; offset of batforse "  "  "     "
blkparm		equ	11		; offset of batparms string in block stack

blksize		equ	11		; preliminary size of a block, to account
					; for the back pointer, the descriptor,
					; batline, batecho, and batforse

; macros

true?	macro	testflag
	cmp	testflag,true
	endm

resflg	macro	flag
	mov	byte ptr flag,false
	endm

setflg	macro	flag
	mov	byte ptr flag,true
	endm

mos	macro	fn
	mov	ah,fn
	int	21h
	endm

ljcxz	macro	jmpdest 		;; long jumps
	local	lp1,lp2
	jcxz	lp1
	jmp	lp2
lp1:	jmp	jmpdest
lp2:
	endm

lje	macro	jmpdest
	local	ppp1
	jne	ppp1
	jmp	jmpdest
ppp1:
	endm

ljne	macro	jmpdest
	local	ppp1
	je	ppp1
	jmp	jmpdest
ppp1:
	endm

ljz	macro	jmpdest
	local	ppp1
	jnz	ppp1
	jmp	jmpdest
ppp1:
	endm

ljnz	macro	jmpdest
	local	ppp1
	jz	ppp1
	jmp	jmpdest
ppp1:
	endm


ljc	macro	jmpdest
	local	ppp1
	jnc	ppp1
	jmp	jmpdest
ppp1:
	endm

ljnc	macro	jmpdest
	local	ppp1
	jc	ppp1
	jmp	jmpdest
ppp1:
	endm

lja	macro	jmpdest
	local	ppp1
	jbe	ppp1
	jmp	jmpdest
ppp1:
	endm

ljb	macro	jmpdest
	local	ppp1
	jae	ppp1
	jmp	jmpdest
ppp1:
	endm

ljnb	macro	jmpdest
	local	ppp1
	jb	ppp1
	jmp	jmpdest
ppp1:
	endm

; data

dataseg segment at 0

datastart label byte

	org 0100h

; storage for general buffers

; start of keep in this order section
attmpt1		db	80 dup(?)	; attmpt1 and attmpt2 must always be
attmpt2		db	80 dup(?)	; allocated in this order since attmpt2 may
					; be used as a spill over buffer for attmpt1
; end of keep in this order section

cmddrv		db	?		; drive letter from command line
cmdname		db	9 dup(?)	; command name from extrbuf
dchar		db	?		; used as buffer for dispchar
					; parameter block for exec call
execprm		dw	?		; segment address of environment
		dw	?		; offset of command line tail
		dw	?		; segment of command line tail
		dw	?		; offset of fcb1
		dw	?		; segment of fcb1
		dw	?		; offset of fcb2
		dw	?		; segment of fcb2

		db	7 dup(?)	; extension for fcb1
fcb1		db	37 dup(?)	; fcb1
		db	7 dup(?)	; extension for fcb2
fcb2		db	37 dup(?)	; fcb2

extpath		db	64 dup(?)	; path string extracted from environment
extpdr		db	?		; drive letter from extracted path
extrbuf		db	80 dup(?)	; command line copied here from linebuf
					; when it is an external command
flfbuf		db	13 dup(?)	; buffer for fullform subroutine
forsbuf		db	lbufsize dup(?) ; holds the for command and set members

; keep in this order
		dw	?		; storage for requested and returned count
					; for function 0a call
linebuf		db	128 dup(?)	; initial input buffer for commands
; keep in this order


parmlen		db	?		; length of parmbuf, for exec call
parmbuf		db	128 dup(?)	; the parameter line in copied into here
pathstr		db	128 dup(?)	; copy of path from environment
promstr		db	128 dup(?)	; copy of prompt from environment
		db	7 dup(?)	; extension for prsfcb
prsfcb		db	37 dup(?)	; fcb for using parse call

savedir		db	64 dup(?)	; holds original drive\path spec for genpthstr
savename	db	8 dup(?)	; for copy of internal command name
savesi		dw	?		; for si when recycling in command search
usedr1		db	?		; drive letter for first attmept
usedr2		db	?		; drive letter for second attempt
workbuf		db	128 dup(?)	; general work area
dirbuf		db	64 dup(?)	; current directory buffer for dispprompt

; variables for redirection

appflg		db	?		; indicates that >> was used.  append to file.
inbuf		db	80 dup(?)	; file name for input redir spec
incnt		db	?		; length counter for inbuf
origin		db	?		; original psp system handle for stdin
origout		db	?		; original psp system handle for stdout
outbuf		db	80 dup(?)	; file name for output redir spec
outcnt		db	?		; length counter for outbuf
ovrih		dw	?		; handle for input redir spec
ovrin		db	?		; indicates that an input redir spec exists
ovroh		dw	?		; handle for output redir spec
ovrout		db	?		; indicates that an output redir spec exists
inopen		db	?		; true when input file is already open
outopen		db	?		; true when output file is already open

; variables for chaining/piping

chaincnt	db	?		; counter to manage chaining sequence
chainflg	db	?		; indicates that chaining is in effect
pipestat	db	?		; controls i/o redirection sequence
oldpstat	db	?		; previous value of pipestat
pipefile	db	?		; indicates that pipe files exist
pfhandl1	dw	?		; handle of first pipe file
pfhandl2	dw	?		; handle of second pipe file
pfname1		db	80 dup(?)	; string to hold name for first pipe file
pfname2		db	80 dup(?)	; string to hold name for second pipe file

; variables for batch processing

batch		db	?		; indicates a batch file is being processed
batecho		db	?		; indicates the echo state for batch files
batecdf		db	?		; indicates the default echo state
batnest		db	?		; nesting level  0 for first batch file
batend		dw	?		; segment pointer to end of block stack
batchar		db	?		; storage for getbchar subroutine
batlcnt		db	?		; counter for truncation control when writing
					; into linebuf from a batch file
batlptr		dw	?		; point in linebuf to write next char
bateflg		db	?		; indicates that an end of file was found
batline		dd	?		; line pointer of next batch file line to read
batparms	db	128 dup(?)	; holds the strings for %0-%9
battabl		dw	10 dup(?)	; pointers for %0-%9 in batparms
batprme		dw	?		; pntr to original end of batparms (for shift)
batoldnm	db	80 dup(?)	; holds the current batch file name for nesting
bathandl	dw	?		; handle of the batch file
batptr		dw	?		; pointer to either attmpt1 or attmpt2, to
batforse	dw	?		; record of forstke at the start of batch file
errlvl		db	?		; value for errorlevel
nointerr	db	?		; flag to disable internal errorlevel setting
dointerr	db	?		; flag to hold interr data from cmd list
lasterl		db	?		; save for errlvl when recycle to internal
batforca	dw	?		; forstke at the start of +call command
batnonest	db	?		; flag to disable batch file nesting
bat@line	db	?		; flag that an @ sign started the line

; vars for the readbatline procedure

dsttrunc	db	?		; true if the line read in is longer than
					; lbufmax
batlread	db	?		; true if the present buffer is the last
midline		db	?		; true if anther buffer must be read to complete
					; show which one successfully opened the file

; misc variables

attptr		dw	?		; attempt pointer, points to either attmpt1
					; or attmpt2
assumint	db	?		; control flag for command search order
begsi		dw	?		; holds an initial value for pointer si
bkattr		db	?		; background color attribute
cmdaddr		dw	?		; address of internal command
cmdcnt		db	?		; length counter for cmdname
cmdtype		db	?		; indicates type of command being processed
					; 0 internal, 1 external, 2 drive change and
					; 3 'command'
copt		db	?		; indicates a /c was found in the parameter
copyfix1	db	?		; clean up verify setting from copy command
copyfix2	db	?		; clean up copy storage area
copyfix3	db	?		; reset default output class to origclass
copyfix4	db	?		; close the source file
copyfix5	db	?		; delete the source file (full disk error)
trghndl		dw	?		; handle of target for copy command
targdrv		db	?		; 1 based drive number for target (for lansat/id4f31)
signfix1	db	?		; clean up security information
copyseg		dw	?		; segment address of copy storage area
copysize	dw	?		; byte count of storage area
sourceptr	dd	?		; file pointer in "source" file.
targptr  	dd	?		; file pointer in "targ" file.
type_eof	dd	?		; eof point in file being read by type.
cpflg		db	?		; indicates 'command' was entered without a
					; drive\path spec.  treat as external.
cppntr		dw	?		; pointer to drive\path spec for 'command'
directc		db	?		; direction control for the critical error handler
echostat	db	?		; flag to indicate echo status
envaddr		dw	?		; segment address of the master environment
envsize		dw	?		; paragraphs from last envsize command
envpara		dw	?		; paragraphs allocated for the master enviroment
extrcnt		db	?		; counter for extrbuf
fndbat		db	?		; flag to indicate that a bat was found
fndexe		db	?		; flag to indicate that a exe was found
forpchr		db	?		; the char after the 1st % for for in do cmd
forscnt		db	?		; number of set members for for in do cmd
forsbln		db	?		; original length for forsbuf
forsptr		dw	?		; pointer to next set member for for in do cmd
forend		db	?		; flag to indicate that the command just
					; processed was the last of the for set
forstke		dw	?		; segment pointer to the end of the for stack
cforstkl	dw	?		; record of forstke when batch is false

forfspec	db	?		; flag to indicate a global filespec was found
forplen		db	?		; length of the path portion of the global filespec
forpptr		dw	?		; pointer to the path portion of the global filespec
fordta		db	43 dup(?)	; dta for a global filespec's processing
forstop		db	?		; flag to indicate that linebuf should be ignored

ipass		db	?		; controls attempt choice in exec call loop
mlstrt		dw	?		; pointer into linbbuf for command processing
nodot		db	?		; flag for the .dot command
nullparm	db	?		; indicates a null parmbuf (internal commands)

origclass	db	?		; original value of tcbcdft at entry to copy command
pathptr		dw	?		; pointer for parsing pathstr
pluscmd		db	?		; true when the command starts with a + sign
popt		db	?		; indicates a /p was found in the parameter
pspparnt	dw	?		; storage for original psp parent psp segment
pspterm		dd	?		; storage for original psp terminate vector
quotlvl		db	?		; indicates when the data being parsed is
					; within quote marks
savesp		dw	?			; holds stack pointer during exec call
skipproc	db	?		; controls skipping when don't use a period, fail the
					; external search and succeed an internal search
					; used to prevent piping and redirection from being
					; set up twice
specdrv		db	?		; indicates that a drive was specified in
					; the command line
specpath	db	?		; indicates that a path was specified in
					; the command line
srchndl		dw	?		; handle of source, made global for error cleanup
tabcnt		db	?		; +text counter for override when expanding a tab
tempseg		dw	?		; temporary segment pointer for +except/+only
tcbidnum	dw	?		; id number of the current tcb
tcbseg		dw	?		; segment pointer of the current tcb
scboff		dw	?		; offset to scb
scbseg		dw	?		; segment of scb
farcall38	dd	?		; 38 vector from scbfar38
wordten 	dw	10		; constant 10
minsign 	db	'N'		; minus sign flag
d4_parent	dd	?		; holds d4 vector value to use when cleaning up from
					; the basic interpreter at the parent shell level
d4_child	dd	?		; holds the d4 vector value around an exec call from
					; a non-parent level shell (basic interp fix)

; window data for critical-error messages

cursor		dw	?		; saved cursor position
wactive 	db	?		; window active (y is yes, n is no)
scrndata	db	((cb-ct)*(rb-rt)+100) dup (0,0)  ; screen data area
devnum		db	?		; device number of crit err
crit24		db	?		; zero if a parallel port  (not very critical)
crit24al	db	?		; al value use by critical handler
far23hnl	db	5 dup (?)	; jmp ($shell.sys) : int23

; storage for a copy of the mosmiman save buffer for function 0a

save0a		db	519 dup(?)

; start of overlay data area for internal commands
; must manage overlay and size manually

ovlayar  label byte

		dw	512 dup(?)	; reserve 1k bytes for the overlay area

; start of stack area

		db	300 dup('stack')

	even

stacktop  label byte			; top of normal stack

		dw	?

dataend label byte			; the stock environment goes here

dataseg ends

overlay  equ	ovlayar - datastart

cdirs  segment at 0			; data for the dir command

	org  overlay

dwopt		db	?		; indicates that a /w was found in parmbuf
ddopt		db	?		; indicates that a /d was found in parmbuf
dpopt		db	?		; indicates that a /p was found in parmbuf
dsopt		db	?		; indicates that a /s was found in parmbuf
daopt		db	?		; indicates that a /a was found in parmbuf
dcopt		db	?		; indicates that a /c was found in parmbuf
drvnum		db	?		; number of the drive to be used
					; be temporarily overwritten with a 0
dlines		db	?		; line counter when /p is used
dnames		db	?		; line counter when /w and /p is used
dfilecnt	dw	?		; file counter
dtotbytes	dd	?		; total byte counter
maxfiles	dw	?		; file counter for sorting
sorttype	db	?		; type code for sorting, 0 for sort by file
					; name, 1 - by ext, 2 - date/time, 3	- size
nextblk		dw	?		; pointer to table of offsets when using from
					; sorted data
totfiles	dw	?		; count of data blocks left when using from
					; sorted data
didhead		db	?		; true once the column heading has been put up

cdirs ends

ccopys	segment at 0			; data for the copy command

	org  overlay

brf1		db	?		; branch control flag
assumtrg	db	?		; a target is being assumed
ctaopt		db	?		; a /a was found for the target
ctbopt		db	?		; a /b was found for the target
csaopt		db	?		; a /a was found for the source
csbopt		db	?		; a /b was found for the source
specsopt	db	?		; true if a source option (/a or /b) was spec'ed
spectopt	db	?		; true if a target option was spec'ed
cvopt		db	?		; a /v was found
findplus	db	?		; true if a '+' sign was found
trgglbl		db	?		; global spec in the derived target
orgtrggl	db	?		; global spec in the original target
srcglbl		db	?		; global spec in the source
existrg		db	?		; a target exists (and must be closed)
srconce		db	?		; one source has been processed
skipform	db	?		; skip formation of a target name
setskip		db	?		; set the skip flags true
holdfrst	db	?		; indicates hold first name mode
hfmastr		db	?		; indicates when the first file spec is being
					; processed for hold first name mode
hfname		db	12 dup(?)	; buffer for the first fname.ext when in hold
					; first mode
srcpntr		dw	?		; pointer to next source spec
workbuf2	db	80 dup(?)	; general work area #2
cpyptt		db	11 dup(?)	; storage for the expanded wild card pattern
lastread	db	?		; flags last read cycle for a source file
copycnt		dw	?		; count of copied files
movedate	db	?		; true if the source date is to be transferred
set_sysdate	db	?		; true if new date is to be set?
newdate		dw	?		; the new date for the target
newtime		dw	?		; the new time for the target
srcdev		db	?		; true if the source is a device
trgdev		db	?		; true if the target is a device
crettrg		db	?		; true if a target is to be created
ccopt		db	?		; true if a /c option was found
coptcl		db	?		; class letter used with /c (0 if none used)
cdatbuf		db	10 dup(?)	; buffer for func 83
trgbuf		db	80 dup(?)	; copy of target string for func 83
tempname	db	80 dup(?)	; buffer for temp file name for class change
srcentry	db	128 dup (?)	; source entry dta
trgentry	db	128 dup (?)	; target entry dta

ccopys	ends

cerases  segment at 0			; data for the erase command

	org  overlay

evopt		db	?		; indicates that a /v was found in parmbuf
eyopt		db	?		; indicates that a /y was found in parmbuf
edrvnum		db	?		; number of the drive to be used

cerases  ends

crenames  segment at 0			; data for the rename command

	org  overlay

cpttrn		db	11 dup(?)	; storage for the expanded wild card pattern
name1		dw	?		; holds location of file name for 1st parm
name2		dw	?		; holds location of file name for 2nd parm
rspecdrv	db	?		; holds the drive number specified in the
					; first parameter
prm1strt	dw	?		; holds the location of the start of the
					; first parameter
renflgs		db	?		; used as bit flags - see comments in source code
renbuf		db	128 dup(?)	; temp buffer for string work

crenames  ends

ctypes	segment at 0			; data for the type command

	org  overlay

hopt		db	?		; indicates that a /h was found in parmbuf
typehndl	dw	?		; handle for the file being typed
datacnt		dd	?		; counter for right column of display

ctypes	ends

csignons segment at 0			; data for signon command

	org overlay

len1		db	?
parm1		db	4 dup (?),?
len2		db	?
parm2		db	6 dup (?)
trys		db	?		; no of trys for bad password count
savecls		db	?		; save class during get input
soncls		db	3 dup (?)
organsi		db	?		; orignal tcbansi value
	even
hfoff		dw	?		; file pointer high
lfoff		dw	?		; file pointer low
sign23o		dw	?		; orignal signon int 23 vector offset
sign23s		dw	?		; orignal signon int 23 vector offset

csignons ends
