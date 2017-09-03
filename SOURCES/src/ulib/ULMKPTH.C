/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulmkpth.c
 creation date:      12/15/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 12/15/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <dos.h>
#include <io.h>
#include <dir.h>
#include <string.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; word ul_makepath(byte *path)
;
; path must be in full form, starting with "d:\"
; 
; in:	path -> string naming path to build
;
; out:	retval = 0 if ok, != 0 if error
;
;,fe
========================================================================*/
word ul_makepath(byte *path) {

  byte *trunc_ptr;
  byte *last_pos;
  byte end_slash;

  if(path[3] == 0) {
    return(0);
    }
  last_pos = strchr(path,0)-1;
  end_slash = 0;
  if(*last_pos == '\\') {
    end_slash = 1;
    *last_pos = 0;
    }

  // if the path doesn't already exist, build it, stepping
  // through the component sections one at a time.

  if(access(path,0) != 0) {
    trunc_ptr = &path[3];
    while((trunc_ptr = strchr(trunc_ptr,'\\')) != NULL) {
      *trunc_ptr = 0;
      if(access(path,0) != 0) {
        if(mkdir(path)) {
          return(1);
          }
        }
      *trunc_ptr = '\\';
      trunc_ptr++;
      }
    if(mkdir(path)) {
      return(1);
      }
    }
  if(end_slash) {
    *last_pos = '\\';
    }
  return(0);
  }
