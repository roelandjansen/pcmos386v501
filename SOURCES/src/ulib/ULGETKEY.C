/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulgetkey.c
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

static byte (*filter_hook)(byte) = NULL;

/*======================================================================
;,fs
; void ul_set_gkhook(byte (*new_filter_func)(byte))
; 
; establishes a filter function for ul_get_key().  useful for 
; hot-key support.
;
; in:	new_filter_func -> filter function
;
; out:	
;
;,fe
========================================================================*/
void ul_set_gkhook(byte (*new_filter_func)(byte)) {

  filter_hook = new_filter_func;
  }

/*======================================================================
;,fs
; byte ul_get_key(void)
; 
; wait until a keystroke is pressed.  
; the keystroke is not echoed to the screen.  
; extended keycodes are converted to single byte values above 0x80.  
; see the defined values in ulib.h.
;
; in:	
;
; out:	the keycode of the key that was pressed
;
;,fe
========================================================================*/
byte ul_get_key(void) {

  byte t;

  while(1) {
    t = getch();
    if(t == 0) {
      t = getch();
      if(t >= 0x80) {
        t = 0;
        }
      else {
        t += 0x80;
        }
      }
    if(filter_hook == NULL) {
      break;
      }
    else {
      if((*filter_hook)(t) == 0) {
        break;
        }
      }
    }
  return(t);
  }

