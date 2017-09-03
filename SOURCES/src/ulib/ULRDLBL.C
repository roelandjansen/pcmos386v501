/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulrdlbl.c
 creation date:      12/15/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 12/15/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <stdio.h>
#include <dos.h>
#include <dir.h>
#include <string.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; void ul_read_dsklbl(byte drvnum, byte *lbuf)
; 
; in:	drvnum = drive number (1 for 'A', 2 for 'B', etc.)
;	lbuf -> buffer that is at least 12 chars in size
;
; out:	
;
;,fe
========================================================================*/
void ul_read_dsklbl(byte drvnum, byte *lbuf) {

  struct ffblk ffblk;			// structure for findfirst/next
  word err_stat;			// holds error status
  byte first;
  byte search_spec[8];

  sprintf(search_spec,"%c:\\*.*",drvnum+'A'-1);
  *lbuf = 0;
  first = 1;
  while(1) {
    if(first) {
      err_stat = findfirst(search_spec,&ffblk,8);
      first = 0;
      }     else {
      err_stat = findnext(&ffblk);
      }
    if(err_stat) {
      return;
      }
    if(ffblk.ff_attrib & 8) {
      if(strlen(ffblk.ff_name) > 8) {
        strncpy(lbuf,ffblk.ff_name,8);
        strcpy(&lbuf[8],&ffblk.ff_name[9]);
        }       else {
        strcpy(lbuf,ffblk.ff_name);
        }
      return;
      }
    }
  }

