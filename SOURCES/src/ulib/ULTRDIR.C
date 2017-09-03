/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        
 creation date:      12/10/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 12/10/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <dos.h>
#include <dir.h>
#include <string.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; word ul_trace_dir(byte *dpbuf, fspc_type *fsptr)
;
; this function is the effectively the same as ul_trace_dirl() except
; that no list is built of the filenames found.  this function is for
; the case where the activity of the work function includes the building
; of a list -- such that using ul_trace_dirl() would involve a
; waste of time and memory.
;
; see ul_trace_dirl() for other usage notes.
;
;,fe
========================================================================*/
word ul_trace_dir(byte *dpbuf, fspc_type *fsptr) {

  byte *orig_end;			// ptr to original end of dpbuf
  byte *trunc_ptr;			// used to maintain wbuf
  struct ffblk ffblk;			// structure for findfirst/next
  word err_stat;			// holds error status


  // record the original ending point of the string in the
  // drive/path buffer.  then make sure it ends with a backslash
  // (unless it's a null string -- for the current directory).

  orig_end = (byte *)strchr(dpbuf,0);
  trunc_ptr = orig_end;
  if(orig_end != dpbuf) {
    if(*(trunc_ptr-1) != '\\') {
      *trunc_ptr = '\\';
      trunc_ptr++;
      *trunc_ptr = 0;
      }
    }
  strcat(dpbuf,(fsptr->search_spec));

  // find each target file and call the work function

  while(1) {
    if(trunc_ptr != NULL) {
      err_stat = findfirst(dpbuf,&ffblk,fsptr->search_attr);
      *trunc_ptr = 0;
      trunc_ptr = NULL;
      }     
    else {
      err_stat = findnext(&ffblk);
      }
    if(err_stat != 0) {
      if(_doserrno == 0x12) {
        break;
        }       
      else {
        *orig_end = 0;
        return(2);
        }
      }

    // for each file found, call the work function with a
    // pointer to dpbuf, the found name and its attribute.

    if((*(fsptr->work_func))(dpbuf,ffblk.ff_name,ffblk.ff_attrib) != 0) {
      *orig_end = 0;
      return(4);
      }
    }
  *orig_end = 0;
  return(0);
  }
