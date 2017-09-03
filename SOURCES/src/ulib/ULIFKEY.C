/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulifkey.c
 creation date:      04/01/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 04/01/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <conio.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; byte ul_if_key(void)
; 
;
; in:	
;
; out:	retval != 0 if a key, else retval = 0
;
;,fe
========================================================================*/
byte ul_if_key(void) {

  return(kbhit());
  }

