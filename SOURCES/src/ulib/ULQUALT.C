/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulqualt.c
 creation date:      12/17/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 12/17/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <dos.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; byte ul_qualify_template(byte *n1, byte *n2)
; 
; in:	n1 -> reference template
;	n2 -> template to qualify
;
; out:	retval = 1 if n2 is encompassed by n1
;	else retval = 0
;
;,fe
========================================================================*/
byte ul_qualify_template(byte *n1, byte *n2) {

  byte i;

  for(i=0;i<11;i++) {
    if(n1[i] != '?') {
      if(n1[i] != n2[i]) {
        return(0);
        }
      }
    }
  return(1);
  }
