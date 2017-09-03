/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulstr2v.c
 creation date:      04/01/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 04/01/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <dos.h>
#include <string.h>
#include <conio.h>
#include <ctype.h>

#include <asmtypes.h>
#include "ulib.h"

extern dword ul_vidptr;			/* video pointer */

/*======================================================================
;,fs
; void ul_str2video(byte x, byte y, byte vidattr, byte *st, byte transflag)
; 
; write an asciiz string to direct video at the specified coordinates
; using the specified video attribute.
;
; in:	x = 0 based column number
;	y = 0 based row number
;	vidattr = video attribute byte to write with the char
;	st -> the string to display
;	transflag != 0 if leading blanks should use existing attribute
;
;	global: ul_vidptr must be set.  see ul_set_vidptr
;
; out:	
;
;,fe
========================================================================*/
void ul_str2video(byte x, byte y, byte vidattr, byte *st, byte transflag) {


  DOFS(ul_vidptr) = x*2+y*160;
  if(transflag) {
    while(*st == ' ') {
      *ul_vidptr.bptr = *st;
      st++;
      DOFS(ul_vidptr) += 2;
      }
    }
  while(*st) {
    *ul_vidptr.wptr = (vidattr << 8) + *st;
    DOFS(ul_vidptr) += 2;
    st++;
    }
  }

