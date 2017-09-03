;-----------------------------------------------------------------------;
; MOSREGS.INC - define locations of application's saved registers       ;
;									;
; the saved registers for the current partition are accessed using the	;
; labels below.  the parentheses mean you can override the type 	;
; attribute if you need to						;
;									;
; these can be used as if they were memory locations			;
;									;
;	mov	ax,[TBP]						;
;	mov	[TBP],ax						;
;									;
; are both valid instructions which do what you would think whenever	;
; the registers are set up in their default configuration (i.e. SS	;
; is pointing to the TCB for the current partition and BP has the value ;
; which was set by MOSSAVER)						;
;-----------------------------------------------------------------------;

	subttl	macros for defining reentrant procedures with local variables
	page
	
;-----------------------------------------------------------------------;
; define something named debug to check for stack overflow at runtime	;
;-----------------------------------------------------------------------;
if1
	%out	* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	%out	*							*
endif
;	ifdef	bugerror
	if	0 eq 1
	if1
	%out	* debug option for run-time stack overflow check is ON	*
	endif

; open a procedure frame (allocate local variables checking for stack overflow)
lproc	macro	name
	local	dbg1
public	name			;; public for Periscope if debug on
name	proc	near
	push	bp		;; save "standard" bp
	mov	bp,sp
	sub	bp,lt&name		;; allocate room for variables
	cmp	bp,offset tcbminstk+128 ;; leaving enough room for
	jae	dbg1			;; misc. interrupt handling (64 words)
;; this is a stack overflow error
	callmos1 bugerror
	db	'01 &name',0
dbg1:
	xchg	bp,sp
	push	bp		;; save stack pointer before allocation
lsize = 0
	endm

	else

	if1
	%out	* debug option for run-time stack overflow check is OFF *
	endif
; open a procedure frame (allocate local variables, don't check stack overflow)
lproc	macro	name
name	proc	near
	push	bp		;; save "standard" bp
	mov	bp,sp
	db	83h,0ech,lt&name ; sub sp,lt&name
	push	bp		;; save stack pointer before allocation
lsize = 0
	endm

	endif
if1
	%out	*							*
	%out	* * * * * * * * * * * * * * * * * * * * * * * * * * * * *
endif

