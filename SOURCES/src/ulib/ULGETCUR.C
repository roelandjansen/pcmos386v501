/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulgetcur.c
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
; word ul_get_cursor(void)
; 
; get the cursor coordinates.
; uses i10f03.
;
; in:	
;
; out:	retval high byte = y coordinate
;	retval low byte = x coordinate
;
;,fe
========================================================================*/
word ul_get_cursor(void) {

  union REGS regs; struct SREGS sregs;

  regs.h.ah = 3;
  regs.h.bh = 0;
  int86(0x10,&regs,&regs);
  return((regs.h.dh << 8) + regs.h.dl);
  }

