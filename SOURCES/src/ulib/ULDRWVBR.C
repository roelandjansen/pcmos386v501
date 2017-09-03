/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        uldrwvbr.c
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
; void ul_draw_vbar(byte x, byte yt, byte yb, byte vidattr, byte boxtype)
;
; draw a vertical line within a box, with T type connectors at each end
; 
; in:	x = 0 based column number in which to draw the bar
;	yt = 0 based row number of top edge
;	xb = 0 based row number of bottom edge
;	vidattr = video attribute byte to write with the char
;	boxtype = numeric code for type of box.  see ulib.h
;
; out:	
;
;,fe
========================================================================*/
void ul_draw_vbar(byte x, byte yt, byte yb, byte vidattr, byte boxtype) {

  word lines;
  byte y;
  byte v_line;
  byte t_end;
  byte b_end;

  if(yt > yb) return;
  lines = yb - yt - 1;
  switch(boxtype) {
  case box_single :
    v_line = 179;
    t_end = 194;
    b_end = 193;
    break;
  case box_double :
    v_line = 186;
    t_end = 203;
    b_end = 202;
    break;
    }
  for(y=yt+1;y<yt+1+lines;y++) {
    ul_char2video(x,y,vidattr,v_line);
    }
  ul_char2video(x,yt,vidattr,t_end);
  ul_char2video(x,yb,vidattr,b_end);
  }

