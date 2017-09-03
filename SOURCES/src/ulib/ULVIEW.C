/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulview.c
 creation date:      04/01/92
 revision date:      05/21/92
 author:             mjs
 description:        ulib module

======================================================================

mjs 04/01/92	created this module

mjs 05/21/92	reworked to support large files and tab expansion

=======================================================================
*/

#include <stdlib.h>
#include <dos.h>
#include <mem.h>
#include <string.h>
#include <stdio.h>

#include <asmtypes.h>
#include "ulib.h"

extern byte ul_vidrows;

//==== display line tracking vars and constants

// TOT_LNS_REC is the total number of lines that can be recorded
// in memory at a time.

#define TOT_LNS_REC 400

// HYST_FCTR is the file loading hysteresis factor.  it must 
// always be less than TOT_LNS_REC.

#define HYST_FCTR 80

// FLS_BYTES is the forward load shift byte count -- the number 
// of bytes to be shifted back towards the front of the tracking 
// array for a forward load.

#define FLS_BYTES ((TOT_LNS_REC-HYST_FCTR)*sizeof(word *))

// FL_START is the tracking array element to start loading into
// for a forward load.

#define FL_START (TOT_LNS_REC-HYST_FCTR)


static word top_ln_dsp;		// line # of top line displayed
static word bot_ln_dsp;		// line # of bottom line displayed
static word tot_lns_dsp;	// # of text lines on screen
static word tot_lns_scrn;	// # of lines on screen -- total
static byte top_text_coord;	// y coord of top text line
static byte bot_text_coord;	// y coord of bottom text line

//==== file buffer tracking vars

static FILE *fh;		// file pointer
static byte buffer[ul_max_view_cols+2];  // +1 for newline, +1 for ending 0
static byte **ln_array;		// base of line tracking array
static word frst_ln_rec;	// line # of first line recorded in array
static word last_ln_rec;	// line # of last line recorded
				//  (not based on actual lines)
static word actual_last_ln;	// line # of last line in file
				//  (will be updated when read eof)
static byte eof_flag;		// used by last_load()

//==== misc vars

static byte getset[] = {home, end, up_arrow, down_arrow, pgup, pgdn, escape, 0};

#define TBUFLEN ul_max_view_cols+1
static byte tabbuf[TBUFLEN];

//==== file offset cache vars and constants

#define CACHE_MAX_ELE 50
#define CACHE_MARGIN 300

struct cac_type {
  word line;
  long offset;
  } cache[CACHE_MAX_ELE];

word cache_elements;


/*======================================================================
; static void disp_line(byte x, byte y, byte vattr, byte *str, byte tt)
; 
; in:	
;
; out:	
;
========================================================================*/
static void disp_line(byte x, byte y, byte vattr, byte *str, byte tt) {

  strcpy(tabbuf,str);
  ul_expand_tabs(tabbuf,8,TBUFLEN);
  ul_str2video(x,y,vattr,tabbuf,tt);
  }

/*======================================================================
; static void put_cache(word cur_line)
; 
; in:	
;
; out:	
;
========================================================================*/
static void put_cache(word cur_line) {

  word x;


  if(cache_elements == CACHE_MAX_ELE) {
    return;
    }
  for(x=0;x<cache_elements;x++) {
    if(cur_line <= cache[x].line + CACHE_MARGIN) {
      return;
      }
    }
  cache_elements++;
  cache[cache_elements-1].line = cur_line;
  cache[cache_elements-1].offset = ftell(fh);
  }

/*======================================================================
; static word get_cache(word target)
;
; find the cache element that has a file line number less that the
; target but is closest to it.
; 
; in:	
;
; out:	
;
========================================================================*/
static word get_cache(word target) {

  word lowest_diff;
  word lowest_ele;
  word actual_diff;
  word x;

  lowest_diff = 0xffff;
  for(x=0;x<cache_elements;x++) {
    if(cache[x].line <= target) {
      actual_diff = target - cache[x].line;
      if(actual_diff < lowest_diff) {
        lowest_diff = actual_diff;
        lowest_ele = x;
        }
      }
    }
  if(lowest_diff == 0xffff) {
    fseek(fh,0L,SEEK_SET);
    return(1);
    }
  else {
    fseek(fh,cache[lowest_ele].offset,SEEK_SET);
    return(cache[lowest_ele].line);
    }
  }

/*======================================================================
; static void free_lines(void)
; 
; in:	
;
; out:	
;
========================================================================*/
static void free_lines(void) {

  word x;


  for(x=0;x<TOT_LNS_REC;x++) {
    if(ln_array[x] != NULL) {
      free(ln_array[x]);
      ln_array[x] = NULL;
      }
    }
  }

/*======================================================================
; static byte readline(void)
; 
; in:	
;
; out:	retval = 0 if ok to proceed, good line from file
;	retval = 1 if found eof
;
========================================================================*/
static byte readline(void) {

  word i;
  char xbuff[20];


  // if encounter eof, return 1

  if(fgets(buffer,ul_max_view_cols+1,fh) == NULL) {
    return(1);
    }
  i = strlen(buffer)-1;
  if(buffer[i] == '\n') {
    buffer[i] = 0;
    return(0);
    }

  // when find a long line, read and discard the remainder

  while(1) {
    if(fgets(xbuff,20,fh) == NULL) {
      return(0);
      }
    if(xbuff[strlen(xbuff)-1] == '\n') {
      return(0);
      }
    }
  }

/*======================================================================
; static byte forward_load(void)
; 
; in:	
;
; out:	
;
========================================================================*/
static byte forward_load(void) {

  word x;


  // free the pointers in the first section

  for(x=0;x<HYST_FCTR;x++) {
    free(ln_array[x]);
    ln_array[x] = NULL;
    }

  // move the remainder of the pointers to the front of the array.
  // and mark the pointers in that leftover area as free.

  movmem(&ln_array[HYST_FCTR],&ln_array[0],FLS_BYTES);
  for(x=0;x<HYST_FCTR;x++) {
    ln_array[FL_START+x] = NULL;
    }

  // determine the line number of the first line that will be 
  // read and report it to put_cache.

  put_cache(last_ln_rec+1);

  // update tracking data

  frst_ln_rec += HYST_FCTR;
  last_ln_rec += HYST_FCTR;

  // read HYST_FCTR more lines from the file, allocating storage for
  // them with strdup() and recording their pointers in the 
  // tracking array starting at record FL_START.

  for(x=0;x<HYST_FCTR;x++) {
    if(readline() == 1) {

      // if encounter eof before all lines can be read, update the
      // actual_last_ln variable.

      actual_last_ln = frst_ln_rec + FL_START + x - 1;
      eof_flag = 1;
      break;
      }

    // allocate storage for the line and record its pointer
    // in the tracking array.

    if((ln_array[FL_START+x] = strdup(buffer)) == NULL) {
      return(1);
      }
    }
  return(0);
  }

/*======================================================================
; static byte reverse_load(void)
; 
; in:	
;
; out:	
;
========================================================================*/
static byte reverse_load(void) {

  word x;
  word skip_cnt;
  word backstep;


  // free all records

  free_lines();

  // update tracking data

  if(frst_ln_rec <= HYST_FCTR) {
    frst_ln_rec = 1;
    }
  else {
    frst_ln_rec -= HYST_FCTR;
    }
  last_ln_rec -= HYST_FCTR;

  // read the line number/file offset cache to determine
  // the best point to start reading the file.

  skip_cnt = frst_ln_rec - get_cache(frst_ln_rec);

  // read recs_to_load more lines from the file, allocating 
  // storage for them with strdup() and recording their pointers 
  // in the tracking array starting at record 0.

  backstep = 0;
  for(x=0;x<TOT_LNS_REC;x++) {
    if(backstep) {
      x--;
      backstep = 0;
      }
    if(readline() == 1) {

      // if encounter eof within this function, must be error.

      return(1);
      }

    // skip any lines required to get to the line number
    // described in frst_ln_rec.

    if(skip_cnt > 0) {
      skip_cnt--;
      backstep = 1;
      continue;
      }

    // allocate storage for the line and record its pointer
    // in the tracking array.

    if((ln_array[x] = strdup(buffer)) == NULL) {
      return(1);
      }
    }
  return(0);
  }

/*======================================================================
; static byte first_load(void)
; 
; in:	
;
; out:	
;
========================================================================*/
static byte first_load(void) {

  word x;


  // free all records

  free_lines();

  // read up to TOT_LNS_REC lines from the file, allocating 
  // storage for them with strdup() and recording their pointers 
  // in the tracking array starting at record 0.

  fseek(fh,0L,SEEK_SET);
  for(x=0;x<TOT_LNS_REC;x++) {
    if(readline() == 1) {

      // if encounter eof before all lines can be read, update the
      // actual_last_ln variable.

      actual_last_ln = x;
      break;
      }

    // allocate storage for the line and record its pointer
    // in the tracking array.

    if((ln_array[x] = strdup(buffer)) == NULL) {
      return(1);
      }
    }
  if(actual_last_ln == 0) {
    return(1);
    }
  frst_ln_rec = 1;
  last_ln_rec = TOT_LNS_REC;
  return(0);
  }

/*======================================================================
; static byte last_load(void)
; 
; in:	
;
; out:	
;
========================================================================*/
static byte last_load(void) {

  byte retval;


  eof_flag = 0;
  while(eof_flag == 0) {
    if((retval = forward_load()) != 0) {
      return(retval);
      }
    }
  return(0);
  }

/*======================================================================
; static void clean_up(void)
; 
; in:	
;
; out:	
;
========================================================================*/
static void clean_up(void) {


  free_lines();
  free(ln_array);
  fclose(fh);
  }

/*======================================================================
;,fs
; byte ul_view(byte *fname, byte *msg1, byte *msg2, byte vattr)
; 
; present a file for browsing.  up and down arrows scroll a line
; at a time.  pgup and pgdn scroll a screenful at a time.  home and
; end take you to the start and end of the document.
; allocates an array of character pointers and allocates
; a heap block with strdup() for each line read in from the file.
; press escape to exit.
; shifts file tracking array contents to handle large files.
; adjusts to the number of display lines recorded in ul_vidrows
; (see ul_set_vidptr()).
; reports the name of the file being viewed at the top of the screen.
; two caller-supplied information lines are displayed at the bottom.
;
; in:	fname -> name of file to be loaded and browsed
;	msg1 -> first caller-supplied string to display at bottom
;	msg2 -> second caller-supplied string to display at bottom
;	vidattr = video attribute byte to write with the char
;
; out:	retval != 0 if error, else retval = 0
;
;,fe
========================================================================*/
byte ul_view(byte *fname, byte *msg1, byte *msg2, byte vattr) {

  word x;
  byte refresh;
  word strt_ndx;
  word actual_disp_lines;
  byte retval;


  // init global vars afresh

  actual_last_ln = 0xffff;
  cache_elements = 0;

  // allocate and init the tracking array

  if((ln_array = (byte **)malloc(TOT_LNS_REC*sizeof(byte *))) == NULL) {
    return(1);
    }
  for(x=0;x<TOT_LNS_REC;x++) {
    ln_array[x] = NULL;
    }

  // set up the viewing screen.

  tot_lns_scrn = ul_vidrows;
  tot_lns_dsp = tot_lns_scrn - 5;
  top_ln_dsp = 1;
  top_text_coord = 2;
  bot_text_coord = tot_lns_scrn - 4;
  ul_set_cursor(79,24);
  ul_cls(vattr);
  disp_line(4,0,vattr,fname,0);
  for(x=0;x<80;x++) {
    ul_char2video(x,1,vattr,0xcd);
    ul_char2video(x,tot_lns_scrn-3,vattr,0xcd);
    }
  disp_line(0,tot_lns_scrn-2,vattr,msg1,0);
  disp_line(0,tot_lns_scrn-1,vattr,msg2,0);

  if((fh = fopen(fname,"r")) == NULL) {
    return(1);
    }
  if(first_load() != 0) {
    return(1);
    }

  // while it's true that actual_last_ln could not actaully
  // be set at this time, if it's not lower than tot_ln_dsp
  // by now, it never will be (or TOT_LNS_REC is puny!)

  actual_disp_lines = tot_lns_dsp;
  if(actual_last_ln < actual_disp_lines) {
    actual_disp_lines = actual_last_ln;
    }

  // present the first screenful and react to keyboard input

  refresh = 1;
  while(1) {
    if(refresh) {
      ul_clr_box(0,top_text_coord,79,bot_text_coord,vattr);
      strt_ndx = top_ln_dsp - frst_ln_rec;
      for(x=0;x<actual_disp_lines;x++) {
        disp_line(0,top_text_coord+x,vattr,ln_array[strt_ndx+x],0);
        }
      bot_ln_dsp = top_ln_dsp + tot_lns_dsp - 1;
      refresh = 0;
      }
    switch(ul_get_key_set(getset)) {

    case home:
      if(frst_ln_rec > 1) {
        if((retval = first_load()) != 0) {
          clean_up();
          return(retval);
          }
        }
      top_ln_dsp = 1;
      refresh = 1;
      break;

    case end:
      if(actual_disp_lines != actual_last_ln) {
        if(actual_last_ln > last_ln_rec) {
          if((retval = last_load()) != 0) {
            clean_up();
            return(retval);
            }
          }
        top_ln_dsp = actual_last_ln - tot_lns_dsp + 1;
        refresh = 1;
        }
      break;

    case up_arrow:
      if(top_ln_dsp != 1) {
        top_ln_dsp--;
        bot_ln_dsp--;
        ul_scroll_lines_down(0,top_text_coord,79,bot_text_coord,vattr);
        if(top_ln_dsp < frst_ln_rec) {
          if((retval = reverse_load()) != 0) {
            clean_up();
            return(retval);
            }
          ul_eat_key();
          }
        x = top_ln_dsp - frst_ln_rec;
        disp_line(0,top_text_coord,vattr,ln_array[x],0);
        }
      break;

    case down_arrow:
      if(bot_ln_dsp < actual_last_ln) {
        top_ln_dsp++;
        bot_ln_dsp++;
        ul_scroll_lines_up(0,top_text_coord,79,bot_text_coord,vattr);
        if(bot_ln_dsp > last_ln_rec) {
          if((retval = forward_load()) != 0) {
            clean_up();
            return(retval);
            }
          }
        x = top_ln_dsp - frst_ln_rec + tot_lns_dsp - 1;
        disp_line(0,bot_text_coord,vattr,ln_array[x],0);
        }
      break;

    case pgup:
      if(top_ln_dsp > tot_lns_dsp) {
        top_ln_dsp -= tot_lns_dsp;
        }
      else {
        top_ln_dsp = 1;
        }
      if(top_ln_dsp < frst_ln_rec) {
        if((retval = reverse_load()) != 0) {
          clean_up();
          return(retval);
          }
        ul_eat_key();
        }
      refresh = 1;
      break;

    case pgdn:
      if(bot_ln_dsp < actual_last_ln) {

        // try advancing a whole page amount

        x = bot_ln_dsp + tot_lns_dsp;
        if(x <= actual_last_ln) {
          top_ln_dsp += tot_lns_dsp;
          }
        else {

          // if advancing by a whole page is too much, 
          // go for a partial page.

          top_ln_dsp = actual_last_ln - tot_lns_dsp + 1;
          x = top_ln_dsp + tot_lns_dsp;
          }
        if(x > last_ln_rec) {
          if((retval = forward_load()) != 0) {
            clean_up();
            return(retval);
            }
          }
        refresh = 1;
        }
      break;

    case escape:
      clean_up();
      return(0);
      }
    }
  }
