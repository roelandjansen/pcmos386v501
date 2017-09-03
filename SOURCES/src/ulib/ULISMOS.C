/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulismos.c
 creation date:      12/15/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 12/15/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <dos.h>

#include <asmtypes.h>
#include "ulib.h"

static union REGS regs;

/*======================================================================
;,fs
; word ul_ismos(void)
; 
; in:	
;
; out:	retval != 0 if running under mos
;
;,fe
========================================================================*/
word ul_ismos(void) {

  word mos_ver;

  regs.x.ax = 0x3000;
  regs.x.bx = 0x3000;
  regs.x.cx = 0x3000;
  regs.x.dx = 0x3000;
  intdos(&regs,&regs);
  mos_ver = regs.x.ax;
  regs.x.ax = 0x3000;
  regs.x.bx = 0;
  intdos(&regs,&regs);
  return(!(regs.x.ax == mos_ver));
  }
