/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulcls.c
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

extern byte ul_vidrows;		// # of display columns
extern byte ul_vidcols;		// # of display columns

/*======================================================================
;,fs
; void ul_cls(byte vidattr)
; 
; clear the screen using the specified attribute.  the rows and columns
; value specified in the ul_set_vidptr call are used.
;
; in:	vidattr = video attribute byte to write with the char
;
;	global: ul_vidrows & ul_vidcols must be set.  see ul_set_vidptr
;
; out:	
;
;,fe
========================================================================*/
void ul_cls(byte vidattr) {

  ul_clr_box(0,0,ul_vidcols-1,ul_vidrows-1,vidattr);
  }

