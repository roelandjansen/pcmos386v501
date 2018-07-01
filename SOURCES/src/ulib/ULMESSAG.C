/*
;,fs
;******** $.
;,fe
=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        ulmessage.c
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
#include <stdio.h>
#ifdef __BORLANDC__
#include <malloc.h>
#endif
#include <string.h>

#include <asmtypes.h>
#include "ulib.h"

#define getmsgtag	1
#define getmsgcount	2
#define getmsglines	3

typedef struct _msgtype {
    byte *tag;
    word  count;
    byte *msglines[ul_msg_max_lines];
    } msgtype;

typedef msgtype far *msgptr;

static msgptr msgtags[ul_msg_max_tags];
static word tagcount;

/*======================================================================
; static word ul_storetag(byte *buf, word tag_index)
; 
; verify that the buffer contains a tag in the correct format.
;
; in:	buf -> the string to process
;	tag_index = array index for tag tracking
;
; out:	retval = 0 if line is not a tag, 1 if it is, >100 if error
;
========================================================================*/
static word ul_storetag(byte *buf, word tag_index) {

  byte temp[80];
  byte *s,*t;

  s = temp;
  t = buf;
  while(((*t) == ' ') || ((*t) == '\x09')) {
    t++;
    }
  if((*t) == '[') {
    t++;
    while(((*t) != ' ') && ((*t) != '\x09') && ((*t) != ']')) {
      (*s++) = (*t++);
      }
    (*s) = '\0';
#ifdef __BORLANDC__
    if((msgtags[tag_index] = _fmalloc(sizeof(msgtype))) == NULL) {
#else
    if((msgtags[tag_index] = malloc(sizeof(msgtype))) == NULL) {
#endif
      return(ul_msg_er_memory);
      }
    if((msgtags[tag_index]->tag = strdup(temp)) == NULL) {
      return(ul_msg_er_memory);
      }
    }
  else  {
    if(((*t) == NULL) || ((*t) == '\n')) {
      return(0);
      }
    else {
      return(ul_msg_er_memory);
      }
    }
  return(1);
  }

/*======================================================================
; static word ul_store_line(byte *buf, word tag_index, word pos)
; 
; stores buffer contents into message database.
;
; in:	buf -> string to be stored
;	tag_index = array index for tag tracking
;	pos = index for the line (must have already been verified)
;
; out:	retval = 0 if ok, >100 if error
;
========================================================================*/
static word ul_store_line(byte *buf, word tag_index, word pos) {

  byte *s;
  byte *t;

  s = buf;
  if((t = malloc(strlen(buf)+1)) == NULL) {
    return(ul_msg_er_memory);
    }
  msgtags[tag_index]->msglines[pos] = t;
  while(((*s) != '\n') && ((*s) != NULL)) {
    (*t++) = (*s++);
    }
  (*t) = NULL;
  return(0);
  }

/*======================================================================
; static word ul_nextitem(FILE *handle, word tag_index)
; 
; retrieve next message item and store in the message database.
;
; in:	handle -> file structure
;	tag_index = array index for tag tracking
;
; out:	retval = 0 if ok, = 1 if eof, >100 if error
;
========================================================================*/
static word ul_nextitem(FILE *handle, word tag_index) {

  byte buf[80];
  word current,stage;
  word size;
  word rtval;

  current = 0;
  size = 100;
  stage = getmsgtag;
  while(1) {
    if(((fgets(buf,80,handle)) == NULL) && (feof(handle))) {
      if(stage == getmsgtag) {
        return(1);
        }
      else {
        return(ul_msg_er_invf);
        }
      }
    else {
      switch (stage) {

      case getmsgtag :
        if((rtval = ul_storetag(buf,tag_index)) > 100) {
          return(rtval);
          }
        if(rtval == 1) {
          stage++;
          }
        break;

      case getmsgcount :
        size = atoi(buf);
        msgtags[tag_index]->count = size;
        stage++;
        break;

      case getmsglines :

        // add error checking for current !!!!!!!!!!!!!!

        if((rtval = ul_store_line(buf,tag_index,current)) != 0) {
          return(rtval);
          }
        current++;
        break;
        }
      if(current == size) {
        return(0);
        }
      }
    }
  }

/*======================================================================
;,fs
; byte ul_init_msg(byte *fname)
; 
; initialize message system.
;
; in:	fname -> name of file to load into message database
;
; out:	retval = 0 if ok, >100 if error
;
;,fe
========================================================================*/
byte ul_init_msg(byte *fname) {

  FILE *fh;
  word tag_index;
  word rtval;

  if((fh = fopen(fname,"r")) == NULL) {
    return(ul_msg_er_open);
    }
  else {
    tag_index = 0;
    while(1) {
      if((rtval = ul_nextitem(fh,tag_index)) == 1) {
        break;
        }
      if(rtval > 100) {
        return(rtval);
        }
      tag_index++;
      }
    tagcount = tag_index;
    fclose(fh);
    }
  return(0);
  }

/*======================================================================
;,fs
; byte *ul_get_msg(byte *scan, word line_index)
; 
; retrieve a message based on the input tag.
;
; in:	srchtag -> tag string to search for
;	line_index = the line number within the message (0 based)
;
; out:	retval = null if not found
;	else, retval -> the located string
;
;,fe
========================================================================*/
byte *ul_get_msg(byte *scan, word line_index) {

  word i;

  i = 0;
  while(i<tagcount) {
    if(!strcmp(scan,msgtags[i]->tag)) {
      return(msgtags[i]->msglines[line_index]);
      }
    else {
      i++;
      }
    }
  return(NULL);
  }

/*======================================================================
;,fs
; byte ul_get_msgcnt(byte *scan)
; 
; retrieve the number of messages based on the input tag.
;
; in:	srchtag -> tag string to search for
;
; out:	retval = 0 if not found
;	else, retval = the number of message lines
;
;,fe
========================================================================*/
byte ul_get_msgcnt(byte *scan) {

  word i;

  i = 0;
  while(i<tagcount) {
    if(!strcmp(scan,msgtags[i]->tag)) {
      return(msgtags[i]->count);
      }
    else {
      i++;
      }
    }
  return(0);
  }

/*======================================================================
;,fs
; word ul_disp_msg(word x, word y, byte vidattr, byte *srchtag, byte tranflag)
; 
; display a message based on input message tag.  the cursor is
; left positioned after the last character of the last line, just
; as if a non-direct video method had been used.
;
; in:	x = 0 based column number
;	y = 0 based row number
;	vidattr = video attribute byte to write with the char
;	srchtag -> tag string to search for
;	transflag != 0 if leading blanks should use existing attribute
;
; out:	retval = 0 if not found
;	else retval = # of lines in the group
;
;,fe
========================================================================*/
word ul_disp_msg(word x, word y, byte vidattr, byte *srchtag, byte tranflag) {

  word i,count;

  i= 0;
  while(i<tagcount) {
    if(!strcmp(srchtag,msgtags[i]->tag)) {
      for(count=0;count<msgtags[i]->count;count++) {
        ul_str2video(x,y+count,vidattr,msgtags[i]->msglines[count],tranflag);
        }
      ul_set_cursor(x+strlen(msgtags[i]->msglines[count-1]),y+count-1);
      return(msgtags[i]->count);
      }
    else {
      i++;
      }
    }
  return(0);
  }

