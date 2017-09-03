/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulsetcur.c
 creation date:      04/01/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 04/01/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <dos.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; void ul_set_cursor(byte x, byte y)
; 
; set the cursor to the specified coordinates.
; uses i10f02.
;
; in:	x = 0 based column number
;	y = 0 based row number
;
; out:	
;
;,fe
========================================================================*/
void ul_set_cursor(byte x, byte y) {

  union REGS regs; struct SREGS sregs;

  regs.h.ah = 0x02;
  regs.h.bh = 0;
  regs.h.dl = x;
  regs.h.dh = y;
  int86(0x10,&regs,&regs);
  }

