/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulgetkst.c
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
#include <ctype.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; byte ul_get_key_set(byte *xset)
; 
; wait until a keystroke is pressed which is within the specified
; set of characters, beeping for other characters.
; the keystroke is not echoed to the screen.  
; extended keycodes are converted to single byte values above 0x80
; (by ul_get_key).
; alpha keys are internally converted to uppercase.
; see the defined values in ulib.h.
;
; in:	
;
; out:	the keycode of the key that was pressed
;
;,fe
========================================================================*/
byte ul_get_key_set(byte *xset) {

  byte key;

  while(1) {
    key = toupper(ul_get_key());
    if(key != 0 && strchr(xset,key) != NULL) {
      return(key);
      }
    ul_beep();
    }
  }

