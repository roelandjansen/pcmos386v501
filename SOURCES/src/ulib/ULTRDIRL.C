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
jts 06/30/18	added code to allow build under bcc or tcc

=======================================================================
*/

#include <stdlib.h>
#include <dos.h>
#include <dir.h>
#include <string.h>

#ifdef __BORLANDC__
#include <malloc.h>
#endif

#include <asmtypes.h>
#include "ulib.h"

//==== internal data structure

typedef struct fname_type {
 struct fname_type *next;
 byte fname[13];
 byte attr;
 } fntype;

/*======================================================================
; static void free_lptr_list(fntype *fptr)
;
; in:	fptr -> root of fntype list
;
; out:	
;
========================================================================*/
static void free_lptr_list(fntype *fptr) {

  fntype *fptr2;
  fntype *fptr3;

  fptr2 = fptr;
  while(fptr2 != NULL) {
    fptr3 = fptr2;
    fptr2 = fptr2->next;
    free(fptr3);
    }
  }

/*======================================================================
;,fs
; word ul_trace_dirl(byte *dpbuf, fspc_type *fsptr)
;
; findfirst() and findnext() are used to build a list of target files
; in memory.  then, a work function is called for each name in the
; list.  the work function is user-supplied.  it is not part
; of this library.  if the work function detects an error, it
; should report it an return a non-zero value. this function must be of
; the form:
;
; word process_file(byte *dpstr, byte *fname, byte attr);
;
; where:
;	dpstr -> the drive/path portion of the search specification
;	fname -> the filename.ext of the found file
;	attr = the attribute of the found file
;
; the use of the name "process_file" is merely an example.  since the
; name of the work function must be passed in to this function 
; through the fspc_type structure, any valid function name may be used.
;
; a list of files is built ahead of time is to prevent changes in 
; the disk directory from causing redundant processing.
; such changes could occur due to the actions of process_file().
;
; IMPORTANT NOTE ON DPBUF:
;
; the dpbuf buffer must contain enough additional storage space for the
; longest possible fname.ext type of search specification.  this would
; be a string of the form "????????.???", which requires 13 characters
; including the terminating 0.  also, if the dpbuf string does not end
; with a backslash, one will be added so, given that the string in
; dpbuf will already have a terminator, there must always be 13 free
; bytes at the end of this buffer.
; 
;
; in:	fsptr -> a filled out fspc_type type of structure
;	dpbuf -> a buffer containing the drive/path portion
;		  of the search specification.  SEE NOTE ABOVE.
; 
; out:	retval = 0 means no error
;	retval = 1 means insufficient memory for file list
;	retval = 2 means an error from findfirst/findnext 
;		    other than no more files
;	retval = 4 means a != 0 return from the process function
;
;,fe
========================================================================*/
word ul_trace_dirl(byte *dpbuf, fspc_type *fsptr) {

  byte *orig_end;			// ptr to original end of dpbuf
  byte *trunc_ptr;			// used to maintain wbuf
  struct ffblk ffblk;			// structure for findfirst/next
  word err_stat;			// holds error status
  fntype *root_lptr = NULL;		// root of the heap list of fnames
  fntype *lptr = NULL;			// used to build heap list
  fntype *last_lptr;			// used to build heap list


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
  strcat(dpbuf,fsptr->search_spec);

  // find each target file and record its name in the list

  while(1) {

    if(root_lptr == NULL) {
      err_stat = findfirst(dpbuf,&ffblk,fsptr->search_attr);
      }     
    else {
      err_stat = findnext(&ffblk);
      }
    if(err_stat != 0) {
      if(_doserrno == 0x12) {
        break;
        }       
    else {
        free_lptr_list(root_lptr);
        *orig_end = 0;
        return(2);
        }
      }

    // allocate a node from the heap and fill in the data

    last_lptr = lptr;
    if((lptr = (fntype *)malloc(sizeof(fntype))) == NULL) {
      free_lptr_list(root_lptr);
      *orig_end = 0;
      return(1);
      }
    lptr->next = NULL;
    strcpy(lptr->fname,ffblk.ff_name);
    lptr->attr = ffblk.ff_attrib;
    if(last_lptr == NULL) {
      root_lptr = lptr;
      }     
    else {
      last_lptr->next = lptr;
      }
    }
  if(root_lptr == NULL) {
    *orig_end = 0;
    return(0);
    }

  // restore dpbuf and then for each found name in the list,
  // call the work function with a pointer to dpbuf, the found 
  // name and its attribute.

  *trunc_ptr = 0;
  lptr = root_lptr;
  while(lptr != NULL) {
    if((*(fsptr->work_func))(dpbuf,lptr->fname,lptr->attr) != 0) {
      free_lptr_list(root_lptr);
      *orig_end = 0;
      return(4);
      }
    lptr = lptr->next;
    }
  free_lptr_list(root_lptr);
  *orig_end = 0;
  return(0);
  }
