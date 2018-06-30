/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulremfil.c
 creation date:      04/01/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 04/01/92	created this module
jts 06/30/18	added code to allow build under bcc or tcc

=======================================================================
*/

#include <stdlib.h>
#include <dos.h>
#include <dir.h>
#include <io.h>
#include <string.h>

#include <asmtypes.h>
#include "ulib.h"

#ifndef __BORLANDC__
#ifndef FA_NORMAL
#define FA_NORMAL 0x00			// normal file type
#endif
#endif
/*======================================================================
;,fs
; byte ul_remove_files(byte *filespec, byte search_attr)
; 
; in:	filespec -> file specification string (e.g. "c:\\xyz\\abc*.*")
;	search_attr = attribute, using FA_NORMAL, FA_RDONLY, etc.
;
; out:	retval = 0 if successful
;	retval = 1 if an error occured
;
;,fe
========================================================================*/
byte ul_remove_files(byte *filespec, byte search_attr) {

  word first;				// controls findfirst/next calls
  word err_stat;			// holds error status
  struct ffblk ffblk;			// for findfirst/next
  byte drvstr[MAXDRIVE];		// for fnsplit
  byte pathstr[MAXDIR];			// for fnsplit
  byte fnamestr[MAXFILE];		// for fnsplit
  byte extstr[MAXEXT];			// for fnsplit
  byte wbuf[MAXPATH];			// holds d:\path filespec portion
  byte *trunc_ptr;			// used to maintain wbuf
  word attr;				// each file's attribute

  fnsplit(filespec,drvstr,pathstr,fnamestr,extstr);
  strcpy(wbuf,drvstr);
  strcat(wbuf,pathstr);
  trunc_ptr = strchr(wbuf,0);
  first = 1;
  while(1) {
    if(first) {
      err_stat = findfirst(filespec,&ffblk,search_attr);
      first = 0;
      }
    else {
      err_stat = findnext(&ffblk);
      }
    if(err_stat != 0) {
      if(_doserrno == 0x12) {
        return(0);
        }
      else {
        return(1);
        }
      }
    strcat(wbuf,ffblk.ff_name);
    if(search_attr != FA_NORMAL) {
      attr = _chmod(wbuf,0);
      if(attr == 0xffff) {
        return(1);
        }
      if(attr & search_attr) {
        attr = _chmod(wbuf,1,FA_NORMAL);
        if(attr == 0xffff) {
          return(1);
          }
        }
      }
    if(remove(wbuf) != 0) {
      return(1);
      }
    *trunc_ptr = 0;
    }
  }

