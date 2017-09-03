PAGE 90, 132
;
;****************************************************************************
;
;       MODULE NAME:    get_freemem
;
;       TASK NAME:      ACU.EXE
;
;       PROJECT:        PC-MOS Auto Configuration Utility
;
;       CREATION DATE:  14-June-90
;
;       REVISION DATE:  14-June-90
;
;       AUTHOR:         Martin Stitt
;
;       DESCRIPTION:    Obtains a map of FREEMEM areas by interrogating
;                       the system for them.
;
;
;		(C) Copyright 1990, The Software Link Inc.
;			All Rights Reserved
;
;****************************************************************************
;
;       USAGE:          get_freemem(map);
;
;	PARAMETERS:	
;
; NAME          TYPE            USAGE   DESCRIPTION
; ----          ----            -----   -----------
; map           int[5][2]       input   Array to place freemem entries into.
;
; Note: Search the c000 to f000 range for free memory blocks and
;       automatically skip over vna footprint at cc00 if found.
;
;****************************************************************************
;			>> Revision Log <<
;
; DATE		PROG	DESCRIPTION OF REVISION
; ----		----	-----------------------
;
;****************************************************************************
_text   segment word    public  'code'
        assume  cs:_text, ds:nothing, es:nothing

PUBLIC  _get_freemem

_get_freemem    proc    far

	push	bp
        mov     bp, sp
	push	si
	push	di
	push	ds
	push	es
        mov     bx, 0C000h               ;Start search here.
	cld
        lds     si, [bp+6]               ;Set-up pointer to caller's array.
        mov     cx, 5*2
        xor     ax, ax                   ;Clear the array.
	push	ds
	pop	es
        mov     di, si
	rep	stosw
fnf1:
        cmp     bx, 0CC00h               ; skip cc00 to cd00 if vna
	jne	fnf1a
      	call	check_vna_rom
	jz	fnf1a
        mov     [si+2], 0cd00h
	jmp	fnf8
fnf1a:
        mov     es, bx                   ; next 4k block
        mov     ax, 00ffh                ; init
        mov     cx, 1000h                ; scan 4k
        xor     di, di
fnf3:
        add     ah, es:[di]              ; calc checksum
        and     al, es:[di]
	inc	di			; check 4k
	loop 	fnf3

; at this point, if al == 0, the 4k block is most likely code.
; do a second checksum to double check.

        cmp     al, 0
	jnz	fnf5 
        xor     di, di                   ; init for loop 2
        xor     al, al                   ; init "        "
        xor     dl, dl
        mov     cx, 1000h                ; scan 4k
fnf6:
        add     al, es:[di]              ; calc checksum
        or      dl, es:[di]
	inc	di			; check 4k
	loop 	fnf6

; if the 2nd checksum matches the 1st and the
; block isn't all 0's, must be rom'ed code.

        cmp     al, ah
	jnz	fnf5 
        cmp     dl, 0
        jnz     fnf8
fnf5:

; at this point, doesn't look like rom'ed code.  in the case of
; a 4k block full of 0's, if its write protected shadow ram, it
; will fail the following test - so we'll use that area.

        mov     word ptr es:[0], 1234h   ; put in test value for ram
        cmp     word ptr es:[0], 1234h   ; is it there?
	jz	fnf8 
        cmp     [si+2], bx               ; is this a continuation?
	jz	fnf9 
        cmp     word ptr [si+2], 0       ; is this the 1st block found?
	jz	fnf10 
        add     si, 4                    ; set next pointer
        mov     ax, [bp+6]
        add     ax, 6*4                  ; is si pointing to the 6th entry?
        cmp     si, ax                   ; (only 5 entries allowed in table)
	jz	fnf2 
fnf10:
        mov     [si], bx                 ; no, start of new block
fnf9:
	inc	bh			; next 4k
        mov     [si+2], bx               ; set end of block address
	dec	bh
fnf8:
	inc	bh			; next 4k block
        cmp     bh, 0f0h                 ; end of usable range?
	je	fnf2
	jmp	fnf1 
fnf2:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	ret

_get_freemem    endp

crmsg	equ	$
y = 0
	irpc	x,<(c) Copyright 1987 The Software Link Incorporated >
	db	('&x' xor 0abh)-y
y = y + 1
	endm
	irpc	x,<All rights reserved worldwide.>
	db	('&x' xor 0abh)-y
y = y + 1
	endm
crend	equ	$
crlen	equ	crend-crmsg

;- check_vna_rom -------------------------------------------------------
; entry parms:	none
; exit parms:	nz if vna, else zr
;-----------------------------------------------------------------------
check_vna_rom   proc    near

	push	ax
	push	bx
	push	cx
	push	si
	push	di
	push    ds
	push	es
        mov     cx, cs
        mov     es, cx
        mov     di, offset crmsg
        mov     si, 0cc0h
        mov     cl, 4
        shl     si, cl
        mov     ds, si
	cld
        mov     cx, offset crend
        sub     cx, di
        xor     bh, bh
        xor     si, si
regs1:
	lodsb
        xor     al, 0abh
        sub     al, crlen
        add     al, cl
        sub     al, es:[di]
	inc	di
        or      bh, al
	loop	regs1
        xor     ax, ax                   ; assume vna rom not found
        or      bh, bh                   ; if bh is zero than copyright is ok
	jnz	isvna
	inc	ax
isvna:
	or	ax,ax			; set nz if vna
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret

check_vna_rom   endp

_text           ends
                end
