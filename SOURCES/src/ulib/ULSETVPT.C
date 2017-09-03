/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulsetvpt.c
 creation date:      04/01/92
 revision date:      
 author:             mjs
 description:        ulib module

======================================================================

mjs 04/01/92	created this module

=======================================================================
*/

#include <stdlib.h>
#include <dos.h>
#include <string.h>
#include <conio.h>
#include <ctype.h>

#include <asmtypes.h>
#include "ulib.h"

dword ul_vidptr;			// video memory pointer
byte ul_vidrows;			// # of display rows
byte ul_vidcols;			// # of display columns

/*======================================================================
;,fs
; void ul_set_vidptr(word vid_seg, word rows, word cols)
; 
; assign the video buffer segment address to the internal variable
; named ul_vidptr.
;
; in:	vid_seg = 0 if the segment of ul_vidptr should be set based
;	 on the video mode (40:49 of 7 means b000, else b800)
;	vid_seg != 0 if ul_vidptr's segment should be set to vid_seg
;	rows = # of display rows
;	cols = # of display columns
;
; out:	
;
;,fe
========================================================================*/
void ul_set_vidptr(word vid_seg, word rows, word cols) {

  dword vptr;

  ul_vidrows = rows;
  ul_vidcols = cols;
  DOFS(ul_vidptr) = 0;
  if(vid_seg == 0) {
    SETDWORD(vptr,0x40,0x49);
    DSEG(ul_vidptr) = 0xb800;
    if(*vptr.bptr == 7) {
      DSEG(ul_vidptr) = 0xb000;
      }
    }
  else {
    DSEG(ul_vidptr) = vid_seg;
    }
  }

/*======================================================================
;,fs
; word ul_get_vidseg(void)
; 
; return the current segment fro ul_vidptr.
;
; in:	
;
; out:	retval = segment portion of ul_vidptr
;
;,fe
========================================================================*/
word ul_get_vidseg(void) {

  return(DSEG(ul_vidptr));
  }
