/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        uldrwhbr.c
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
; void ul_draw_hbar(byte xl, byte y, byte xr, byte vidattr, byte boxtype)
; 
; draw a horizontal line within a box, with T type connectors at each end
;
; in:	xl = 0 based column number of left edge
;	y = 0 based row number in which to draw the bar
;	xr = 0 based column number of right edge
;	vidattr = video attribute byte to write with the char
;	boxtype = numeric code for type of box.  see ulib.h
;
; out:	
;
;,fe
========================================================================*/
void ul_draw_hbar(byte xl, byte y, byte xr, byte vidattr, byte boxtype) {

  word cols;
  byte x;
  byte h_line;
  byte l_side;
  byte r_side;

  if(xl > xr) return;
  cols = xr - xl - 1;
  switch(boxtype) {
  case box_single :
    h_line = 196;
    l_side = 195;
    r_side = 180;
    break;
  case box_double :
    h_line = 205;
    l_side = 204;
    r_side = 185;
    break;
    }
  for(x=xl+1;x<xl+1+cols;x++) {
    ul_char2video(x,y,vidattr,h_line);
    }
  ul_char2video(xl,y,vidattr,l_side);
  ul_char2video(xr,y,vidattr,r_side);
  }

