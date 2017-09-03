/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulbeep.c
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
; void ul_beep(void)
; 
; make the speaker beep
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void ul_beep(void) {

  byte t;

  sound(440);
  delay(30);
  nosound();
  }

