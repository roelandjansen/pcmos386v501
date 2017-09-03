/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        
 creation date:      04/01/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 04/01/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <stdio.h>
#include <dos.h>
#include <dir.h>
#include <string.h>

#include <asmtypes.h>
#include "ulib.h"


typedef struct ffblk DTA;

#define DTABYTES sizeof(DTA)

typedef struct dtatrack {
 byte dta[DTABYTES];		// saves copy of dta record
 byte *track;			// saves copy of tracking pointer
 } StackRecord;

#define MAXDT 40 
static StackRecord DTstack[MAXDT]; // stack for nested levels of dta/track info
static word DTstkp = 0;		// the stack pointer

/*======================================================================
;,fs
; static word pushDT(DTA *d, byte *trk)
; 
; push the dta and tracking pointer on the stack.
;
; in:	d -> the DTA structure to save on the stack
;	trk = the tracking pointer to save
;
; out:	retval != 0 if directory structure too deep for stack
;
;,fe
========================================================================*/
static word pushDT(DTA *d, byte *trk) {

  if(DTstkp == MAXDT) {
    return(1);
    }
  memmove(&DTstack[DTstkp].dta,(byte *)d,DTABYTES);
  DTstack[DTstkp].track = trk;
  DTstkp++;
  return(0);
  }

/*======================================================================
;,fs
; static void popDT(DTA *d, byte **trk)
;
; pop a previsouly saved dta and tracking pointer from the stack.
; 
; in:	d -> the DTA structure to restore to
;	trk -> the tracking pointer to restore
;
; out:	
;
;,fe
========================================================================*/
static void popDT(DTA *d, byte **trk) {

  DTstkp--;
  memmove((char *)d,&DTstack[DTstkp].dta,DTABYTES);
  *trk = DTstack[DTstkp].track;
  }

/*======================================================================
;,fs
; static void add_stars(byte **tptr)
; 
; add "\*.*" onto the end of a string.
;
; in:	tptr -> a character pointer that should be pointing to
;		the end of a drive/path string.
;
; out:	*tptr (the character pointer at tptr) will be decremented
;	when the original string ends with a backslash.
;
;,fe
========================================================================*/
static void add_stars(byte **tptr) {

  if(*((*tptr)-1) != '\\')  {
    **tptr = '\\';
    strcpy((*tptr)+1,"*.*");
    }   else {
    strcpy((*tptr),"*.*");
    (*tptr)--;
    }
  }

/*======================================================================
;,fs
; word ul_walk_tree(byte *dpbuf, byte *fspec, word (*work_func)(byte *, byte *, byte))
; 
; find each file within the specified directory and all child
; directories, calling a work function for each.
;
; in:	dpbuf -> a buffer containing the drive and path where the
;		 search is to start.  this buffer must include 
;		 expansion room for the longest possible 
;		 d:\path\fname.ext string.
;
;	work_func -> the work function that will be called for
;		 each file found.
;
;		 it must be declared as follows:
;
;		   word process_file(byte *path, byte *fname, byte attr)
;
;		 this function will be passed a pointer to the
;		 drive/path/ string, a ptr to the fname.ext string
;		 and the attribute of that file.
;		 the work function will not be called for direcotry entries.
;
; out:	retval = 0 if no error, else != 0
;
;,fe
========================================================================*/
word ul_walk_tree(byte *dpbuf, byte *fspec, word (*work_func)(byte *, byte *, byte)) {

  byte *trunc_ptr;			// used to maintain wbuf
  DTA ffblk;				// structure for findfirst/next
  word err_stat;			// holds error status
  byte first;
  byte norm1[12];
  byte norm2[13];
  byte skip;

  ul_form_template(fspec,norm1);

  // record the original ending point of the string in the
  // drive/path buffer.  then make sure it ends with a backslash
  // (unless it's a null string -- for the current directory).

  trunc_ptr = (byte *)strchr(dpbuf,0);
  if(trunc_ptr == dpbuf)  {
    return(1);
    }
  add_stars(&trunc_ptr);
  first = 1;
  while(1)  {
    if(first)  {
      err_stat = findfirst(dpbuf,&ffblk,0x10);
      first = 0;
      }     else  {
      err_stat = findnext(&ffblk);
      }
    if(err_stat != 0)  {
      if(_doserrno == 0x12)  {
        if(DTstkp) {
          popDT(&ffblk,&trunc_ptr);
          continue;
          }         else {
          break;
          }
        }       else  {
        return(1);
        }
      }

    // when a directory entry is found (skipping . and ..) it's time
    // to nest deeper.

    if(ffblk.ff_attrib & 0x10) {
      if(ffblk.ff_name[0] == '.') {
        continue;
        }

      // add the found name onto the drive/path string, taking advantage
      // of the backslash that add_stars() will have put at trunc_ptr.

      strcpy(trunc_ptr+1,ffblk.ff_name);
      if(pushDT(&ffblk,trunc_ptr)) {
        return(1);
        }
      trunc_ptr = (byte *)strchr(dpbuf,0);
      add_stars(&trunc_ptr);
      first = 1;
      continue;
      }     else {

      // for each file found, see if it passes the filter spec.

      ul_form_template(ffblk.ff_name,norm2);
      if(ul_qualify_template(norm1,norm2) == 0) {
        continue;
        }

      // call the work function with the d:\path\ string, the found 
      // name, and its attribute.

      *(trunc_ptr+1) = 0;
      if((*(work_func))(dpbuf,ffblk.ff_name,ffblk.ff_attrib) != 0)  {
        return(1);
        }
      }
    }
  return(0);
  }
