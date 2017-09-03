/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulclrbox.c
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
; void ul_clr_box(byte xl, byte yt, byte xr, byte yb, byte vidattr)
; 
; clear a rectangular region of the screen, using direct video
;
; in:	xl = 0 based column number of left edge
;	yt = 0 based row number of top edge
;	xr = 0 based column number of right edge
;	yb = 0 based row number of bottom edge
;	vidattr = video attribute byte to write with the char
;
;	global: ul_vidptr must be set.  see ul_set_vidptr
;
; out:	
;
;,fe
========================================================================*/
void ul_clr_box(byte xl, byte yt, byte xr, byte yb, byte vidattr) {

  word cols;
  word lines;
  word x;
  word t;
  word vofs_hold;
  word fill;

  if(xl > xr || yt > yb) return;
  cols = xr - xl + 1;
  lines = yb - yt + 1;
  vofs_hold = DOFS(ul_vidptr);
  DOFS(ul_vidptr) = xl*2+yt*160;
  fill = (vidattr << 8) + ' ';
  for(x=0;x<lines;x++) {
    for(t=0;t<cols;t++) {
      *(ul_vidptr.wptr+t) = fill;
      }
    DOFS(ul_vidptr) += 160;
    }
  DOFS(ul_vidptr) = vofs_hold;
  }

