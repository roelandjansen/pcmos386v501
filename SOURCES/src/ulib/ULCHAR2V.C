/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulchar2v.c
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
; void ul_char2video(byte x, byte y, byte vidattr, byte vchar)
; 
; write character at coords x,y using direct video
;
; in:	x = 0 based column number
;	y = 0 based row number
;	vidattr = video attribute byte to write with the char
;	vchar = the character to write
;
;	global: ul_vidptr must be set.  see ul_set_vidptr
;
; out:	
;
;,fe
========================================================================*/
void ul_char2video(byte x, byte y, byte vidattr, byte vchar) {

  DOFS(ul_vidptr) = x*2+y*160;
  *ul_vidptr.wptr = (vidattr << 8) + vchar;
  }

