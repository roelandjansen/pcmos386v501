/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulfilbox.c
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

/*======================================================================
;,fs
; void ul_fill_box(byte xl, byte yt, byte xr, byte yb, byte vidattr, byte fillchar)
; 
; fill a rectangular box on the screen, using direct video
;
; in:	xl = 0 based column number of left edge
;	yt = 0 based row number of top edge
;	xr = 0 based column number of right edge
;	yb = 0 based row number of bottom edge
;	vidattr = video attribute byte to write with the char
;	boxtype = numeric code for type of box.  see ulib.h
;
; out:	
;
;,fe
========================================================================*/
void ul_fill_box(byte xl, byte yt, byte xr, byte yb, byte vidattr, byte fillchar) {

  word cols;
  word lines;
  byte x;
  byte y;

  if(xl > xr || yt > yb) return;
  cols = xr - xl + 1;
  lines = yb - yt + 1;
  for(y=yt;y<yt+lines;y++) {
    for(x=xl;x<xl+cols;x++) {
      ul_char2video(x,y,vidattr,fillchar);
      }
    }
  }

