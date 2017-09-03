/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulgetxy.c
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

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; void ul_get_xy(byte *xptr, byte *yptr)
; 
; in:	xptr -> byte var for x coord
;	yptr -> byte var for y coord
;
; out:	x coord and y coord values are assigned
;
;,fe
========================================================================*/
void ul_get_xy(byte *xptr, byte *yptr) {

  word cursor;

  cursor = ul_get_cursor();
  *xptr = cursor & 0xff;
  *yptr = cursor >> 8;
  }


