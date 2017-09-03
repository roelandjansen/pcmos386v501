/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        uleatkey.c
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
; void ul_eat_key(void)
; 
; flush any keys in the type-ahead buffer.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void ul_eat_key(void) {

  byte t;

  while(ul_if_key()) {
    t = ul_get_key();
    }
  }

