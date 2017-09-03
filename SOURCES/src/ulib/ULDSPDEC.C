/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        uldspdec.c
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

/*======================================================================
;,fs
; void ul_display_decimal(word val, byte x, byte y, byte vidattr, byte width)
;
; display a word's decimal representation using direct video.  the
; number is displayed with leading zero's suppressed and right 
; justified.
;
; in:	val = the value to display
;	x = 0 based column number 
;	y = 0 based row number
;	vidattr = video attribute byte to write with the char
;	width = the width of the field
;
; out:	
;	
;,fe
========================================================================*/
void ul_display_decimal(word val, byte x, byte y, byte vidattr, byte width) {

  byte cnv_buf[17];
  byte len;
  byte adj;
  byte a;

  itoa(val,cnv_buf,10);
  adj = 0;
  len = strlen(cnv_buf);
  if(len < width) {
    adj = width - len;
    }
  for(a=0;a<adj;a++) {
    ul_char2video(x+a,y,vidattr,' ');
    }
  ul_str2video(x+adj,y,vidattr,cnv_buf,0);
  }

