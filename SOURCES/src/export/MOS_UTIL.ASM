PAGE 90, 132
;
;****************************************************************************
;
;       MODULE NAME:    MOS_UTIL - Utility routines for MOS utility
;                       programs.
;
;       TASK NAME:      IMPORT.EXE / EXPORT.EXE and others
;
;       PROJECT:        PC-MOS Utilities
;
;       CREATION DATE:  2/8/91
;
;       REVISION DATE:  2/8/91
;
;       AUTHOR:         B. W. Roeser
;
;       DESCRIPTION:    Utility routines for MOS specific kinds of
;                       things for the IMPORT utility.
;
;
;               (C) Copyright 1991, The Software Link Inc.
;                       All Rights Reserved
;
;****************************************************************************
;
;       USAGE:
;
;               void save_TCB_data();
;               void restore_TCB_data();
;               int get_file_specs(char *path, void *buffer);
;               int get_break_flag();
;               void set_break_flag(int);
;
; Notes:
;
;       1) The functions Save_TCB_data and Restore_TCB_data presently
;          only manipulate the default file creation class.
;
;       2) Get_file_specs returns a 10-byte value to buffer.  This
;          value is structured as follows:
;
;               struct file_spec {
;                       char            reserved;       /* Reserved byte */
;                       char            file_class;
;                       char            userid[4];
;                       unsigned        create_time;
;                       unsigned        create_date;
;               }
;
;
;****************************************************************************
;                       >> Revision Log <<
;
; DATE          PROG    DESCRIPTION OF REVISION
; ----          ----    -----------------------
; 03/31/92	SAH     replace RSA lib function _set_volume_label
;****************************************************************************
;
TCB             segment at      01234h
INCLUDE         mostcb.inc
TCB             ends

ifdef   LARGE
PATH    equ     [bp+6]
BUFFER  equ     [bp+10]

mos_util_text   segment word    'code'
                assume  cs:mos_util_text, ds:nothing, es:nothing
else
PATH    equ     [bp+4]
BUFFER  equ     [bp+6]

_text   segment word    public  'code'
        assume  cs:_text, ds:nothing, es:nothing
endif

        PUBLIC  _Save_TCB_data, _Restore_TCB_data, _Get_file_specs
        PUBLIC  _Get_break_flag, _Set_break_flag
	PUBLIC  _Set_Volume_Label

_default_class  db      ?
_TCB_seg        dw      0
;
;  This routine saves TCB variables that need to be restored upon
;  termination of IMPORT.EXE
;
ifdef   LARGE
_save_TCB_data          proc    far
else
_save_TCB_data          proc    near
endif

        push    bp
        push    es
        push    si

        cmp     _TCB_seg, 0
        jne     @F
        mov     ah, 4
        mov     bx, -1
        int     0D4h
        mov     _TCB_seg, es
@@:
        mov     es, _TCB_seg
        assume  es:TCB
        mov     al, TCBCDFT
        mov     _default_class, al

        assume  es:NOTHING
        pop     si
        pop     es
        pop     bp
        ret

_save_TCB_data  endp

ifdef   LARGE
_get_file_specs         proc    far
else
_get_file_specs         proc    near
endif

        push    bp
        mov     bp, sp
ifdef   LARGE
        push    ds
endif
        push    es
        push    si

        cmp     _TCB_seg, 0
        jne     @F
        mov     ax, -1          ;Return non-zero (error) status.
        jmp short GFS_exit
@@:
        mov     ax, 0300h       ;Get file creation/security data.
ifdef   LARGE
        lds     dx, PATH
        les     bx, BUFFER
else
        mov     dx, PATH        ;DS:DX => pathname
        mov     bx, ds
        mov     es, bx
        mov     bx, BUFFER      ;ES:BX => file data.
endif
        int     0D4h
        mov     ax, -1          ;Return error on carry.
        jc      GFS_exit
        assume  es:TCB
        mov     es, _TCB_seg
        mov     al, ds:[bx+1]   ;Get the class.
        mov     TCBCDFT, al     ;Place in the TCB.
        xor     ax, ax          ;Return success.

GFS_exit:
        assume  es:NOTHING
        pop     si
        pop     es
ifdef   LARGE
        pop     ds
endif
        pop     bp
        ret

_get_file_specs         endp
;
;=========================================================================
;
ifdef   LARGE
_restore_TCB_data       proc    far
else
_restore_TCB_data       proc    near
endif

        push    bp
        push    es
        push    si

        cmp     _TCB_seg, 0
        jne     @F
        stc
        jmp short RTD_exit
@@:
        mov     es, _TCB_seg
        assume  es:TCB
        mov     al, _default_class
        mov     TCBCDFT, al

RTD_exit:
        assume  es:NOTHING
        pop     si
        pop     es
        pop     bp
        ret

_restore_TCB_data  endp
;
;========================================================================
;
ifdef   LARGE
FLAG    equ     [bp+6]

_set_break_flag         proc    far
else
FLAG    equ     [bp+4]

_set_break_flag         proc    near
endif

        push    bp
        mov     bp, sp

        mov     ax, 3301h
        mov     dl, FLAG        ;Break flag on.
        and     dl, 01h         ;Make sure it's just 1
        int     21h

        pop     bp
        ret

_set_break_flag         endp

ifdef   LARGE
_get_break_flag         proc    far
else
_get_break_flag         proc    near
endif

        mov     ax, 3300h
        int     21h
        xor     ah, ah
        mov     al, dl
        ret

_get_break_flag         endp


filename	db	'?:\'
fname		db	13 dup (0)
delfcb		db	0ffh			; extended fcb
		db	5 dup (0)
		db	8
drvfcb		db	?
		db	'????????'
		db	'???'
		dw	?
		dw	?
		db	4 dup (?)
		dw	?
		dw	?
		db	8 dup (?)
		db	?
		db	4 dup (?)

;
; Set_Volume_label
;
; This is a replace for one of the functions in RSASMALL.LIB
; Unfortunately we don't have the source to this libarary and
; Bruce is gone! and the function in the library has a bug, it
; does not close the handle it opens up.  The following is
; a replacement for this function which was disable from the object
; module.
;

_set_volume_label	proc	near
	push	bp
	mov	bp,sp
	push	ds
	push	es
	push	si
	push	di

	cld
	mov	ax,[bp+04]		; get drive
	or	al,al
	jnz	sv1			; is it default????
	mov	ah,19h
	int	21h			; get default drive
	inc	al
sv1:
	mov	cs:[drvfcb],al	
	dec	al
	add	al,'A'
	mov	cs:[filename],al
	mov	si,[bp+06]		; get offset to volume name
	mov	ax,cs
	mov	es,ax
	mov	di,offset fname
	xor	cx,cx
sv2:
	lodsb
	inc	cx
	cmp	cx,9
	jne	sv3
	mov	byte ptr es:[di],'.'
	inc	di
	xor	cx,cx
sv3:
	stosb	   			; store charater in buffer
	or	al,al
	jnz	sv2
	mov	ax,cs
	mov	ds,ax
	mov	ah,13h
	mov	dx,offset delfcb
	int	21h
	mov	ah,3ch
	mov	cx,8
	mov	dx,offset filename
	int	21h
	jc	sverror
;
; must close the file handle bruce!!!!!!!
;
	mov	bx,ax
	mov	ah,3eh			; close the handle
	int	21h			
	xor	ax,ax
	jmp	short svexit
;
sverror:
	mov	ax,2			; he return 2 if error
svexit:

	pop	di
	pop	si
	pop	es
	pop	ds
	pop	bp
	ret
_set_volume_label endp

ifdef   LARGE
mos_util_text   ends
else
_text   ends
endif
        end
