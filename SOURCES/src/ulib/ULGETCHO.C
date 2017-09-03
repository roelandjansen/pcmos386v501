/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulgetcho.c
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
#include <ctype.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; byte ul_get_choice(byte x, byte y, byte vidattr, byte ch1, byte ch2)
; 
; prompt for a binary choice, either character ch1 or character ch2
; (or escape).  the enter key must be pressed to register the choice.
; ul_get_string() is used so the key pressed will be displayed and
; the user can backspace over their choice before finally pressing
; the enter key.  toupper is used on the character entered.
;
; in:	x = 0 based column number
;	y = 0 based row number
;	vidattr = video attribute byte to write with the char
;	ch1 = the first character possibility
;	ch2 = the second character possibility
;
; out:	retval = ch1, ch2 or escape
;
;,fe
========================================================================*/
byte ul_get_choice(byte x, byte y, byte vidattr, byte ch1, byte ch2) {

  byte t;
  byte inbuff[2];

  while(1) {
    if((ul_get_string(x,y,vidattr,inbuff,1,"")) == escape) {
      return(escape);
      }
    t = toupper(inbuff[0]);
    if(t != ch1 && t != ch2) {
      ul_beep();
      }
    else {
      return(t);
      }
    }
  }


