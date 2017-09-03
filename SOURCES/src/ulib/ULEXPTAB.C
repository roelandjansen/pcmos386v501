/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulexptab.c
 creation date:      05/21/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 05/21/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <dos.h>
#include <string.h>
#include <mem.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; byte ul_expand_tabs(byte *eptr, byte ts, word maxlen)
; 
; in:	eptr -> buffer containing string to process
;	ts = tab size
;	maxlen = total length of buffer
;
; out:	retval != 0 if truncation occured
;
;,fe
========================================================================*/
byte ul_expand_tabs(byte *eptr, byte ts, word maxlen) {

  word col;
  word add_blanks;
  word x;
  word avail_cols;
  word tail_len;
  word lacking;
  byte retval = 0;

  x = strlen(eptr) + 1;
  if(x > maxlen) {
    return(1);
    }
  avail_cols = maxlen - x;

  col = 1;
  while(*eptr != 0) {
    if(*eptr == 9) {
      *eptr = ' ';
      eptr++;
      add_blanks = ts - ((col - 1) % ts) - 1;
      if(add_blanks == 0) {
        col++;
        continue;
        }

      // check for truncation cases.

      tail_len = strlen(eptr);
      if(add_blanks > avail_cols) {
        lacking = add_blanks - avail_cols;
        if(lacking < tail_len) {
          tail_len -= lacking;
          }
        else {
          lacking -= tail_len;
          tail_len = 0;
          add_blanks -= lacking;
          }
        avail_cols = 0;
        retval = 1;
        }
      else {
        avail_cols -= add_blanks;
        }

      // if any tail exists, move it

      if(tail_len) {
        movmem(eptr,(eptr+add_blanks),tail_len);
        }

      // write in the blanks, insure proper termination
      // and update the column counter.

      for(x=0;x<add_blanks;x++) {
        *(eptr++) = ' ';
        }
      *(eptr+tail_len) = 0;
      col += add_blanks + 1;

      }
    else {
      eptr++;
      col++;
      }
    }
  return(retval);
  }


