/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulsetatr.c
 creation date:      04/01/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 04/01/92	created this module

=======================================================================
*/

#include <stdlib.h>

#include <asmtypes.h>
#include "ulib.h"

extern dword ul_vidptr;			/* video pointer */

/*======================================================================
;,fs
; void ul_set_attr(byte xl, byte y, byte xr, byte vidattr)
; 
; modify the attribute byte for a certain range of a certain row
; on the video display.
; does direct video writing.
;
; in:	xl = 0 based column number of left edge
;	y = 0 based row number of the row to operate on
;	xr = 0 based column number of right edge
;	vidattr = video attribute byte to write with the char
;
;	global: ul_vidptr must be set.  see ul_set_vidptr
;
; out:	
;	
;,fe
========================================================================*/
void ul_set_attr(byte xl, byte y, byte xr, byte vidattr) {

  byte a;
  word colcnt;
  dword vptr;

  colcnt = xr-xl+1;		/* # of columns involved */
  DSEG(vptr) = DSEG(ul_vidptr);
  DOFS(vptr) = (xl*2+y*160)+1;	/* start at the first attribute */
  for(a=0;a<colcnt;a++) {
    *vptr.bptr = vidattr;
    vptr.wptr++;
    }
  }

