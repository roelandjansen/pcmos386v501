/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulgetstr.c
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
#include <mem.h>
#include <ctype.h>
#include <string.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; byte ul_get_string(byte x, byte y, byte vattr, byte string[], word count, byte *allowed_punc)
; 
; prompt the user for a string.
;
; in:	x = starting x coordinate for input field
;	y = y coordinate for input field
;	vattr = video attribute for display of characters entered
;	string[] -> array for characters entered
;	count = size of the string[] array
;	allowed_punc -> list of allowed non-alphanumeric chars
;
; out:	retval = terminating key: [enter, escape]
;
;,fe
========================================================================*/
byte ul_get_string(byte x, byte y, byte vattr, byte string[], word count, byte *allowed_punc) {

  byte c;
  word pos;

  ul_eat_key();
  memset(string,0,count);
  ul_clr_box(x,y,x+count-1,y,vattr);
  pos = 0;
  while(1) {
    ul_set_cursor(x+pos,y);
    c = ul_get_key();
    switch(c) {
    case backspace:
      if(pos) {
        pos--;
        string[pos] = 0;
        ul_char2video(x+pos,y,vattr,' ');
        }
      else {
        ul_beep();
        }
      break;

    case enter:
      if(string[0] == 0) {
        ul_beep();
        break;
        }
      else {
        return(enter);
        }

    case escape:
      return(escape);

    default:
      if((c != '\r') && (c != '\n')) {
        if(pos == count) {
          ul_beep();
          }
        else {
          if(isalnum(c)) {
            c = toupper(c);
            ul_char2video(x+pos,y,vattr,c);
            string[pos++] = c;
            }
          else {
            if(strchr(allowed_punc,c) != NULL) {
              ul_char2video(x+pos,y,vattr,c);
              string[pos++] = c;
              }
            else {
              ul_beep();
              }
            }
          }
        }
      }
    }
  }

