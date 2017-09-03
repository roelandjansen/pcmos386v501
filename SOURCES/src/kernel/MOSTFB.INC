comment ^==============================================================

mjs 12/16/91	dlg mods: added tfb6ccom, a byte flag to support the
		auto-commit feature of i21f6c.

======================================================================^

tfb segment at 0babeh

;-------------------------- tfb prefix ------------------------------;

		db	?	; reserved
tfbtype		db	?	; 'F' to indicate tfb
		db	6 dup(?) ; reserved
tfbntcb		dw	?	; address of next tfb for this tcb
tfbptcb		dw	?	; address of previous tfb for this tcb
tfbtcb		dw	?	; address of owner tcb
		db	2 dup(?) ; reserved

;------------------------ end of prefix -----------------------------;

tfbngfb		dw	?	; address of next tfb for this gfb
tfbpgfb		dw	?	; address of previous tfb for this gfb
tfbgfb		dw	?	; address of gfb
tfbpsp		dw	?	; address of psp for owner process within task
tfbhdl		dw	?	; file handle used by this tcb for this file
tfbacc		db	?	; access granted to tcb
tfbalow		db	?	; access allowed to other tcb'S
tfblvl		db	?	; access allowed this tfb for this class

;following defined for files - else don't care

tfbpos		dd	?	; offset in file of current position
tfbclus		dw	?	; current cluster (last accessed)
tfbrccur	dw	?	; current cluster relative num within file

;following defined for devices and stream files

tfbioctl	db	?	; ioctl flag as defined by ioctl function
				; bit 7 = 1 if is device
				;     6 = 1 if eof was encountered on input
				;     5 = 1 if binary mode (else ascii)
				;     4 = reserved
				;     3 = is clock device
				;     2 = is null device
				;     1 = is standard output
				;     0 = is standard input
tfb@xof		db	?	; nz => xof encountered
tfbopen		db	?	; open count for tfb (dups + children)
tfbfnh		dw	?	; handle during current function call
tfb6ccom	db	?	; auto-commit flag set by i21f6c
tfblen		equ	$-tfb
tfb ends
