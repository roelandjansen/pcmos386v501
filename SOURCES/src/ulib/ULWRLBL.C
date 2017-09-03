/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulwrlbl.c
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
#include <string.h>

#include <asmtypes.h>
#include "ulib.h"

/*======================================================================
;,fs
; void ul_write_dsklbl(byte drv, byte *lbl)
; 
; in:	drv = drive number (1 for 'A', 2 for 'B', etc.)
;	lbl -> string containing new label name
;
; out:	
;
;,fe
========================================================================*/
void ul_write_dsklbl(byte drv, byte *lbl) {

  byte FCB[44];
  byte fname[16];
  union REGS regs;
  struct SREGS segregs;

  memset(FCB,0,44);
  FCB[0] = 0xff;
  FCB[6] = 8;
  FCB[7] = drv;
  strncpy(&FCB[8],"???????????",11);
  regs.h.ah = 0x13;
  regs.x.dx = (unsigned)FCB;
  segregs.ds = _DS;
  int86x(0x21,&regs,&regs,&segregs);
  fname[0] = drv + 'A' - 1;
  fname[1] = ':';
  fname[2] = '\\';
  if(strlen(lbl) > 8) {
    strncpy(&fname[3],lbl,8);
    fname[11] = '.';
    fname[12] = 0;
    strcat(fname,&lbl[8]);
    }   else {
    strcpy(&fname[3],lbl);
    }
  regs.h.ah = 0x3c;
  regs.x.cx = 8;
  regs.x.dx = (word)fname;
  segregs.ds = _DS;
  int86x(0x21,&regs,&regs,&segregs);
  regs.x.bx = regs.x.ax;
  regs.h.ah = 0x3e;
  int86x(0x21,&regs,&regs,&segregs);
  }

