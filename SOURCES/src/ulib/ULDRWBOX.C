/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        uldrwbox.c
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
; void ul_draw_box(byte xl, byte yt, byte xr, byte yb, byte vidattr, byte boxtype)
; 
; draw a rectangular box on the screen, using direct video
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
void ul_draw_box(byte xl, byte yt, byte xr, byte yb, byte vidattr, byte boxtype) {

  word cols;
  word lines;
  byte x;
  byte y;
  byte h_line;
  byte v_line;
  byte tl_corner;
  byte tr_corner;
  byte bl_corner;
  byte br_corner;

  if(boxtype == box_none || xl > xr || yt > yb) return;
  cols = xr - xl - 1;
  lines = yb - yt - 1;
  switch(boxtype) {
  case box_single :
    h_line = 196;
    v_line = 179;
    tl_corner = 218;
    tr_corner = 191;
    bl_corner = 192;
    br_corner = 217;
    break;
  case box_double :
    h_line = 205;
    v_line = 186;
    tl_corner = 201;
    tr_corner = 187;
    bl_corner = 200;
    br_corner = 188;
    break;
    }
  for(x=xl+1;x<xl+1+cols;x++) {
    ul_char2video(x,yt,vidattr,h_line);
    ul_char2video(x,yb,vidattr,h_line);
    }
  for(y=yt+1;y<yt+1+lines;y++) {
    ul_char2video(xl,y,vidattr,v_line);
    ul_char2video(xr,y,vidattr,v_line);
    }
  ul_char2video(xl,yt,vidattr,tl_corner);
  ul_char2video(xr,yt,vidattr,tr_corner);
  ul_char2video(xl,yb,vidattr,bl_corner);
  ul_char2video(xr,yb,vidattr,br_corner);
  }

