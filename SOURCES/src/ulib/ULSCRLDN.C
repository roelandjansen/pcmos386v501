/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulscrldn.c
 creation date:      04/01/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 04/01/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <string.h>

#include <asmtypes.h>
#include "ulib.h"

extern dword ul_vidptr;			/* video pointer */

/*======================================================================
;,fs
; void ul_scroll_lines_down(byte xl, byte yt, byte xr, byte yb, byte vidattr)
;
; scroll the lines within a rectangular region of the screen down
; by one row.
; does direct video writing.
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
void ul_scroll_lines_down(byte xl, byte yt, byte xr, byte yb, byte vidattr) {

  byte a;
  word srcofs;
  word dstofs;
  word cpycnt;
  dword vptr;
  word blankword;

  blankword = vidattr << 8 + 0x20;
  cpycnt = (xr-xl+1)*2;		/* # of bytes in range of columns */
  srcofs = xl*2+(yb-1)*160;
  dstofs = xl*2+yb*160;

  /* copy box line n-1 to n, n-2 to n-1, etc. */

  for(a=0;a<(yb-yt);a++) {
    movedata(DSEG(ul_vidptr),srcofs,DSEG(ul_vidptr),dstofs,cpycnt);
    srcofs -= 160;
    dstofs -= 160;
    }

  /* blank the top line */

  DSEG(vptr) = DSEG(ul_vidptr);
  DOFS(vptr) = xl*2+yt*160;
  for(a=0;a<(cpycnt/2);a++) {
    *vptr.wptr = blankword;
    vptr.wptr++;
    }
  }

