/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulformt.c
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
#include <mem.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; byte ul_form_template(byte *filespec, byte *template)
; 
; call int21 function 29 to parse a filespec into normalized form.
;
; NOTE: this function makes use of an INT21 function call.
; use of this function within a TSR or device driver requires care.
;
; in:	filespec -> fname.ext (with wildcards)
;	template -> 11 byte buffer for resulting template
;
; out:	retval = 0 if no error and no wildcard characters
;	 buffer at *template = parsed version of non-wild filespec
;	retval = 1 if no error and wildcard characters found
;	 buffer at *template = parsed version wildcard type filespec
;	retval = 0xff if error 
;	 buffer at *template = undefined
;
;,fe
========================================================================*/
byte ul_form_template(byte *filespec, byte *template) {

  union REGS regs; struct SREGS sregs;
  byte fcb[37];

  memset(fcb,0,37);
  regs.x.ax = 0x2903;
  regs.x.si = (word) filespec;
  sregs.ds = _DS;
  regs.x.di = (word) &fcb[0];
  sregs.es = _DS;
  int86x(0x21,&regs,&regs,&sregs);
  memcpy(template,&fcb[1],11);
  return(regs.h.al);
  }


