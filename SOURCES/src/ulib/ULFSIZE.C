/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulfsize.c
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
#include <stdio.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; long ul_getfilesize(byte *file_name)
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
long ul_getfilesize(byte *file_name) {

  FILE *fp;
  long file_length;

  if(access(file_name,0)) {
    return(0);				// file doesn't exist
    }
  fp = fopen(file_name,"rb");		// open in binary mode
  fseek(fp,0l,SEEK_END);
  file_length = ftell(fp);
  fclose(fp);
  return(file_length);
  }
