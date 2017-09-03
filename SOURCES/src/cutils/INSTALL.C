/*=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        install.c
 task name:          install.exe
 creation date:      4/6/89
 revision date:      05/21/92
 author:             sah/mjs
 description:        pc-mos installation aid.

======================================================================

mjs 03/27/92	complete rewrite and addition of features for mos 5.01

mjs 04/01/92	add code to copy updat501.sys.  it is checked for
		on each diskette that contains a self-extracting .exe.

mjs 05/21/92	modified calls to ul_view() to match new version
		of that function.  enables install to handle large
		read.me files.
		renamed existing config.sys on upgrade or replace.
		write new/simple config.sys for updat501.sys.

=======================================================================*/

#include <ctype.h>
#include <dir.h>
#include <direct.h>
#include <dos.h>
#include <io.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys\types.h>
#include <process.h>

#include "asmtypes.h"
#include "ulib.h"
#include "insasm.h"
#include "vidattr.h"
#include "summary.h"

#define	VIEWFILE_ERROR	0
#define	F10_ERROR	1
#define	BREAK_ERROR 	2
#define	DELETE_MISCMSGS	0
#define	FORMAT_MISCMSGS	1
#define	DRIVE_MISCMSGS	2
#define OLD_MISCMSGS	3
#define RETURN_STYLE	1
#define ABORT_STYLE	2
#define RETURN_ERROR	0
#define ABORT_ERROR	1
#define	MAX_MOS		200
#define	MAX_SEARCH	2000
#define MIN_MOS_SPACE	800l

#define MM_BLANK	0		// the mm_choice group
#define MM_NOCHOICE	'0'
#define MM_NEW		'1'
#define MM_REPLACE	'2'
#define MM_UPGRADE	'3'
#define MM_NEWDUAL	'4'
#define MM_MOS2DUAL	'5'
#define MM_DOS2DUAL	'6'
#define MM_QUIT		'7'

#define MM_LOWEST	'1'		// lowest of the mm_choice group
#define MM_HIGHEST	'7'		// highest of the mm_choice group

#define ZIP_FNAME1	"a:\\mosfiles.exe"
#define ZIP_FNAME2	"a:\\auxfiles.exe"
#define SYS_FNAME	"a:\\$$mos.sys"		// use to detect SYSTEM disk
#define STAGE_FNAME	"install.stg"
#define README_FNAME	"a:\\readme"
#define BEFAFT_FNAME	"a:\\diskdata.txt"	// if change, update msg file
#define AUTO_FNAME	"autoexec.bat"
#define CNFG_FNAME	"config.sys"
#define ACU_FNAME	"acu.bat"
#define PDRVR_FNAME	"a:\\updat501.sys"

#define UPGRADE_ATTRS	(FA_RDONLY | FA_HIDDEN | FA_SYSTEM)
#define SUM_LINLEN	80

#define DT_12		'0'
#define DT_720		'1'
#define DT_360		'2'

// these prototypes are needed so that the (*mm_func[])() array 
// of function pointers can be initialized.

byte process_mm_new(void);
byte process_mm_replace(void);
byte process_mm_upgrade(void);
byte process_mm_newdual(void);
byte process_mm_mos2dual(void);
byte process_mm_dos2dual(void);

byte (*mm_func[])() = {
  process_mm_new,
  process_mm_replace,
  process_mm_upgrade,
  process_mm_newdual,
  process_mm_mos2dual,
  process_mm_dos2dual
  };

//==== general globals

byte	max_drive;		// highest valid drive letter
byte	boot_drive;		// where to put $$mos.sys, etc.
byte	jmp_code;		// byte to control action after hdsetup reboots
byte	main_attr;		// main video attribute
byte	cmd_attr;		// video attribute for command entry
byte	error_attr;		// video attribute for error messages
byte	popup = 1;		// controls f10 action
byte	disktype;		// set to DT_12, DT_720 or DT_360
byte	yes_char;		// get from msg file, u.s. == 'Y'
byte	no_char;		// get from msg file, u.s. == 'N'
byte	suppress_f1 = 1;	// controls getkeys hook action for f1
byte	f1_hook_active = 0;	// controls f1 hooking
byte	f10_hook_active = 0;	// controls f10 hooking
byte	esc_chk = 0;		// controls prompting for the escape key
byte	esc_hook_active = 0;	// controls esc hooking
byte	*global_argv[1];	// needed for the exec function
byte	mm_choice;		// the main menu choice
sum_type *sum_root = NULL;	// root of linked list of summary data

byte	install_del[] = "?:\\install.del";  // drive/path for install.del
byte	mospath[MAXPATH] = "?:\\pcmos";	    // drive/path for system files
byte    *mlg_msg;
byte    *dlg_msg;
byte    *sml_msg;

byte	found_upd501 = 0;	// flags an encounter with updat501.sys

//==== globals for view()

byte	*vmsg1;
byte	*vmsg2;
byte	*file2view;

//==== globals for system replacement functions

byte	*mosfiles[MAX_MOS];
word	mostime[MAX_MOS];
word	mosdate[MAX_MOS];
long	mossize[MAX_MOS];
word	findindex[MAX_SEARCH];
byte	*findpath[MAX_SEARCH];
word	moscount;
word	findcount;


/*===================================================================
=============================================== ERROR HANDING
===================================================================*/

/*======================================================================
;,fs
; FILE *er_fopen(byte *fname, byte *fmode)
; 
; if an error occurs, it is reported and then an exit(1) is done.
;
; in:	fname -> file name string
;	fmode -> file open mode string
;
; out:	retval = file pointer
;
;,fe
========================================================================*/
FILE *er_fopen(byte *fname, byte *fmode) {

  FILE *retval;


  if((retval = fopen(fname,fmode)) == NULL) {
    printf("\n\nError opening file: %s\n",fname);
    exit(1);
    }
  return(retval);
  }

/*======================================================================
;,fs
; void er_fclose(FILE *fptr, byte *fname)
; 
; if an error occurs, it is reported and then an exit(1) is done.
;
; in:	fptr -> file structure
;	fname -> file name string
;
; out:	
;
;,fe
========================================================================*/
void er_fclose(FILE *fptr, byte *fname) {


  if(fclose(fptr) != 0) {
    printf("\n\nError closing file: %s\n",fname);
    exit(1);
    }
  return;
  }

/*======================================================================
;,fs
; void errorwindow(word style, byte *message)
; 
; displays a pop-up error message to the screen.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void errorwindow(word style, byte *message) {

  word pos;
  byte c;
  byte inbuff[2];
  wintype win;
  byte savepopup;
  byte newx;
  byte *msg;
  byte save_esc_chk;

  save_esc_chk = esc_chk;
  esc_chk = 0;
  savepopup = popup;
  popup = 0;				// prevent reentrance
  win = ul_open_window(14,8,68,14,error_attr,error_attr,box_double);
  pos = (55 - strlen(message))/2 + 15;
  ul_str2video(pos,10,error_attr,message,0);
  if(style == ABORT_STYLE) {
    msg = ul_get_msg("ERRORS",ABORT_ERROR);
    ul_str2video(16,12,error_attr,msg,0);
    newx = 16 + strlen(msg);
    ul_set_cursor(newx,12);
    while(1) {
      if(ul_get_string(newx,12,error_attr,inbuff,1,"") == escape) {
        break;
        }
      c = toupper(inbuff[0]);
      if(c == yes_char) {
        ul_cls(7);
        remove(STAGE_FNAME);
        ul_disp_msg(0,0,7,"ABORT",0);
        exit(1);
        }
      if(c == no_char) {
        break;
        }
      else {
        ul_beep();
        }
      }
    }
  else {
    ul_str2video(16,12,error_attr,ul_get_msg("ERRORS",RETURN_ERROR),0);
    ul_eat_key();
    ul_get_key();
    }
  popup = savepopup;
  esc_chk = save_esc_chk;
  ul_close_window(win);
  }

/*======================================================================
;,fs
; void breakhandler(void)
; 
; Main Control-C handler.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void breakhandler(void) {


  signal(SIGINT,SIG_IGN);
  errorwindow(ABORT_STYLE,ul_get_msg("INPUT",BREAK_ERROR));
  signal(SIGINT,breakhandler);
  }

/*===================================================================
=============================================== UTILITY FUNCTIONS
===================================================================*/

/*======================================================================
;,fs
; void er_spawnl(byte *fname, byte *p1)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void er_spawnl(byte *fname, byte *p1) {

  byte msg[81];


  if(spawnl(P_WAIT,fname,global_argv[0],p1,NULL) != 0) {
    ul_cls(7);
    printf("\n%s %s %s\n",ul_get_msg("EXECERR",0),fname,p1);
    perror("Error message ");
    exit(1);
    }
  }

/*======================================================================
;,fs
; void get_summary(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void get_summary(void) {

  FILE *summary;
  char workbuf[SUM_LINLEN];
  sum_type *sptr1;
  sum_type *sptr2;

  er_spawnl("hdsetup","/s");
  summary = er_fopen(SUMMARY_FNAME,"r");
  while(feof(summary) == 0) {
    if((fgets(workbuf,SUM_LINLEN,summary)) == NULL) break;
    if(workbuf[0] == ';' || workbuf[0] == '\n' || workbuf[0] == 0) {
      continue;
      }
    if((sptr1 = (sum_type *)malloc(sizeof(sum_type))) == NULL) {
      printf("memory error\n");
      exit(1);
      }
    sptr1->next = NULL;
    if(sum_root == NULL) {
      sum_root = sptr1;
      }
    else {
      sptr2->next = sptr1;
      }
    sptr2 = sptr1;
    sscanf(workbuf,SUMMARY_RMASK,
    &(sptr1->hdrive),
    &(sptr1->ptnum),
    &(sptr1->ptentry),
    &(sptr1->pttype),
    &(sptr1->drvletter),
    &(sptr1->bootstatus),
    &(sptr1->megs),
    &(sptr1->cylds),
    &(sptr1->startcyld),
    &(sptr1->endcyld),
    &(sptr1->febpb)
    );
    }
  er_fclose(summary,SUMMARY_FNAME);
  }

/*======================================================================
;,fs
; byte any_mlg(byte prisec)
; 
; in:	prisec = 0 if should look for mlg-p
;	prisec != 0 if should look for mlg-s
;
; out:	
;
;,fe
========================================================================*/
byte any_mlg(byte prisec) {

  sum_type *sptr1;

  for(sptr1=sum_root;sptr1!=NULL;sptr1=sptr1->next) {
    if(strncmp(sptr1->pttype,mlg_msg,3) == 0) {
      if(prisec == 0) {
        if(sptr1->ptentry == 0) {
          return(1);
          }
        }
      else {
        if(sptr1->ptentry != 0) {
          return(1);
          }
        }
      }
    }
  return(0);
  }

/*======================================================================
;,fs
; void any_boot_drives(byte seconly, byte *result)
; 
; NOTE: presumes the buffer will be large enough for worst case
;
; in:	seconly = 0 if should look for primary or secondary partitions
;	seconly != 0 if should only look for secondary
;	result -> buffer for drive letters
;
; out:	
;
;,fe
========================================================================*/
void any_boot_drives(byte seconly, byte *result) {

  sum_type *sptr1;

  for(sptr1=sum_root;sptr1!=NULL;sptr1=sptr1->next) {
    if(sptr1->hdrive == 0 && sptr1->ptnum == 0) {
      if(strncmp(sptr1->pttype,sml_msg,3) == 0 || strncmp(sptr1->pttype,dlg_msg,3) == 0) {
        if(seconly) {
          if(sptr1->ptentry != 0) {
            *(result++) = sptr1->drvletter;
            }
          }
        else {
          *(result++) = sptr1->drvletter;
          }
        }
      }
    }
  *result = 0;
  }

/*======================================================================
;,fs
; void write_befaft(FILE *befaft_file, sum_type *sptr1, byte drive_letter)
;
; write out a line of data to the before/after configuation report file.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void write_befaft(FILE *befaft_file, sum_type *sptr1, byte drive_letter) {


  fprintf(befaft_file,
  "  %c      %d   %s    %c    %5d %5d %5d %5d\n",
  drive_letter,
  ((sptr1->hdrive)+1),
  sptr1->pttype,
  sptr1->bootstatus,
  sptr1->megs,
  sptr1->cylds,
  sptr1->startcyld,
  sptr1->endcyld
  );
  }

/*======================================================================
;,fs
; void before_report(void)
;
; generate the "before" half of the the before/after configuation 
; report file.
;
; in:	
;
; out:	retval = 0 if no error
;
;,fe
========================================================================*/
void before_report(void) {

  sum_type *sptr1;
  byte drive_letter = 'C';
  FILE *befaft_file;
  byte found;

  befaft_file = er_fopen(BEFAFT_FNAME,"w");
  fprintf(befaft_file,"\n\n%s\n\n",ul_get_msg("BEFAFT1",0));
  fprintf(befaft_file,"%s\n",ul_get_msg("BEFAFT1",3));
  fprintf(befaft_file,"%s\n",ul_get_msg("BEFAFT1",4));
  fprintf(befaft_file,"%s\n",ul_get_msg("BEFAFT1",5));

  // locate primary of first hard drive

  found = 0;
  for(sptr1=sum_root;sptr1!=NULL;sptr1=sptr1->next) {
    if(sptr1->hdrive == 0 && sptr1->ptnum == 0 && sptr1->ptentry == 0) {
      write_befaft(befaft_file,sptr1,drive_letter++);
      found = 1;
      break;
      }
    }
  if(found == 0) {
    fprintf(befaft_file,"%s\n",ul_get_msg("BEFAFT1",1));
    er_fclose(befaft_file,BEFAFT_FNAME);
    return;
    }

  // check for secondary partitions on first hard drive

  for(sptr1=sum_root;sptr1!=NULL;sptr1=sptr1->next) {
    if(sptr1->hdrive == 0 && sptr1->ptnum == 0 && sptr1->ptentry != 0) {
      write_befaft(befaft_file,sptr1,drive_letter++);
      }
    }

  // locate primary of second hard drive

  for(sptr1=sum_root;sptr1!=NULL;sptr1=sptr1->next) {
    if(sptr1->hdrive == 1 && sptr1->ptnum == 0 && sptr1->ptentry == 0) {
      write_befaft(befaft_file,sptr1,drive_letter++);
      break;
      }
    }

  // check for secondary partitions on second hard drive

  for(sptr1=sum_root;sptr1!=NULL;sptr1=sptr1->next) {
    if(sptr1->hdrive == 1 && sptr1->ptnum == 0 && sptr1->ptentry != 0) {
      write_befaft(befaft_file,sptr1,drive_letter++);
      }
    }
  er_fclose(befaft_file,BEFAFT_FNAME);
  return;
  }

/*======================================================================
;,fs
; void after_report(void)
;
; generate the "after" half of the the before/after configuation 
; report file.
;
; in:	
;
; out:	retval = 0 if no error
;
;,fe
========================================================================*/
void after_report(void) {

  sum_type *sptr1;
  FILE *befaft_file;
  byte found;


  befaft_file = er_fopen(BEFAFT_FNAME,"a");
  fprintf(befaft_file,"\n-------------\n\n");
  fprintf(befaft_file,"%s\n\n",ul_get_msg("BEFAFT1",2));
  fprintf(befaft_file,"%s\n",ul_get_msg("BEFAFT1",3));
  fprintf(befaft_file,"%s\n",ul_get_msg("BEFAFT1",4));
  fprintf(befaft_file,"%s\n",ul_get_msg("BEFAFT1",5));

  // locate primary of first hard drive

  found = 0;
  for(sptr1=sum_root;sptr1!=NULL;sptr1=sptr1->next) {
    if(sptr1->hdrive == 0 && sptr1->ptnum == 0 && sptr1->ptentry == 0) {
      found = 1;
      break;
      }
    }
  if(found == 0) {
    fprintf(befaft_file,"%s\n",ul_get_msg("BEFAFT1",1));
    er_fclose(befaft_file,BEFAFT_FNAME);
    return;
    }

  // print partition data

  for(sptr1=sum_root;sptr1!=NULL;sptr1=sptr1->next) {
    write_befaft(befaft_file,sptr1,sptr1->drvletter);
    }
  er_fclose(befaft_file,BEFAFT_FNAME);
  return;
  }

/*======================================================================
;,fs
; void viewfile(byte *fname))
; 
; view readme or help file
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void viewfile(byte *fname) {

  wintype win;
  byte retval;
  byte save_esc_chk;

  win = ul_open_window(0,0,79,24,7,7,box_none);
  save_esc_chk = esc_chk;
  esc_chk = 0;
  retval = ul_view(fname,vmsg1,vmsg2,main_attr);
  esc_chk = save_esc_chk;
  if(retval) {
    errorwindow(RETURN_STYLE,ul_get_msg("INPUT",VIEWFILE_ERROR));
    }
  ul_close_window(win);
  }

/*======================================================================
;,fs
; byte hook_func(byte key)
;
; hook function for ul_get_key.  provides hot-key support for f1/help
; and f10/abort. 
;
; in:	key = the key that ul_get_key is broadcasting
;
; out:	retval = 1 if this hook_func absorbs the keystroke
;	retval = 0 if ul_get_key should return the keystroke
;
;,fe
========================================================================*/
byte hook_func(byte key) {

  byte esc_retval;
  byte esc_x;
  byte esc_y;
  wintype win;


  switch(key) {
  case f1:
    if(suppress_f1) {
      ul_beep();
      return(1);
      }
    if(f1_hook_active == 0) {
      f1_hook_active = 1;
      if(file2view != NULL) {
        viewfile(file2view);
        }
      f1_hook_active = 0;
      }
    return(1);

  case f10:
    if(f10_hook_active == 0) {
      f10_hook_active = 1;
      if(popup) {
        errorwindow(ABORT_STYLE,ul_get_msg("INPUT",F10_ERROR));
        }
      f10_hook_active = 0;
      }
    return(1);

  case escape:
    esc_retval = 0;
    if(esc_chk) {
      if(esc_hook_active == 0) {
        esc_hook_active = 1;
        win = ul_open_window(14,8,68,14,error_attr,error_attr,box_double);
        ul_disp_msg(16,10,error_attr,"ESCVERIFY",0);
        ul_get_xy(&esc_x,&esc_y);
        if(ul_get_choice(esc_x,esc_y,error_attr,yes_char,no_char) != yes_char) {
          esc_retval = 1;
          }
        ul_close_window(win);
        esc_hook_active = 0;
        }
      }
    return(esc_retval);

  default:
    return(0);
    }
  }

/*======================================================================
;,fs
; byte init_msg_ptrs(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
byte init_msg_ptrs(void) {

  byte *temp_ptr;


  // init globals for view()

  if((vmsg1 = ul_get_msg("VIEW1",0)) == NULL) return(1);
  if((vmsg2 = ul_get_msg("VIEW2",0)) == NULL) return(1);

  // init yes_char and no_char

  if((temp_ptr = ul_get_msg("YESNOCHARS",0)) == NULL) return(1);
  yes_char = *temp_ptr;
  no_char = *(temp_ptr+1);

  // init msg string pointer for summary analysis logic

  if((mlg_msg = ul_get_msg("MISCTAG",0)) == NULL) return(1);
  if((dlg_msg = ul_get_msg("MISCTAG",1)) == NULL) return(1);
  if((sml_msg = ul_get_msg("MISCTAG",2)) == NULL) return(1);

  return(0);
  }

/*======================================================================
;,fs
; void domainscreen(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void domainscreen(void) {


  ul_cls(main_attr);
  ul_draw_box(0,0,79,24,main_attr,box_double);
  ul_draw_hbar(0,3,79,main_attr,box_double);
  ul_draw_hbar(0,22,79,main_attr,box_double);
  ul_fill_box(1,4,78,21,main_attr,0xb1);
  ul_disp_msg(1,1,main_attr,"TITLE",0);
  ul_str2video(1,2,main_attr,"          (c) Copyright 1992 The Software Link, Incorporated",0);  /* @@XLAT */
  ul_disp_msg(2,23,main_attr,"HELP1",0);
  }

/*======================================================================
;,fs
; void prep_display(void)
; 
; Display correct view area depending on state of install.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void prep_display(void) {


  ul_clr_box(4,5,75,20,main_attr);
  ul_draw_box(4,5,75,20,main_attr,box_double);
  ul_draw_hbar(4,7,75,main_attr,box_double);
  switch(mm_choice) {
  case MM_NOCHOICE:
    ul_disp_msg(6,6,main_attr,"OPT_FIRST",0);
    break;

  case MM_NEW:
    ul_disp_msg(6,6,main_attr,"OPT_NEW",0);
    break;

  case MM_REPLACE:
    ul_disp_msg(6,6,main_attr,"OPT_REPLACE",0);
    break;

  case MM_NEWDUAL:
    ul_disp_msg(6,6,main_attr,"OPT_DUAL",0);
    break;

  case MM_UPGRADE:
    ul_disp_msg(6,6,main_attr,"OPT_UPGRADE",0);
    break;

  case MM_MOS2DUAL:
    ul_disp_msg(6,6,main_attr,"OPT_MOS2DUAL",0);
    break;

  case MM_DOS2DUAL:
    ul_disp_msg(6,6,main_attr,"OPT_DOS2DUAL",0);
    break;
    }
  }

/*======================================================================
;,fs
; byte prompt_for_yesno(byte *msg_tag, byte vattr)
; 
; in:	msg_tag -> the message tag for the verification prompt
;	vattr = the video attribute to use
;
; out:	retval = yes_char, no_char or escape
;
;,fe
========================================================================*/
byte prompt_for_yesno(byte *msg_tag, byte vattr) {

  byte x;
  byte y;


  prep_display();
  ul_disp_msg(8,8,vattr,msg_tag,0);
  ul_get_xy(&x,&y);
  return(ul_get_choice(x,y,vattr,yes_char,no_char));
  }

/*======================================================================
;,fs
; byte report_pause(byte *msg_tag, byte vattr)
; 
; in:	msg_tag -> the message tag for the verification prompt
;	vattr = the video attribute to use
;
; out:	retval = the entered keystroke
;
;,fe
========================================================================*/
byte report_pause(byte *msg_tag, byte vattr) {


  prep_display();
  ul_disp_msg(8,8,vattr,msg_tag,0);
  ul_eat_key();
  return(ul_get_key());
  }


/*===================================================================
===================================== SYSTEM REPLACEMENT FUNCTIONS
===================================================================*/

/*======================================================================
;,fs
; void dummymosfile(byte *dummy_str)
; 
; add dummy entries to the reference list to check for old
; mos files (e.g. hdsetup.com, ??port.com).  the recorded filesize
; of 0 bytes is used later as a flag to indicate that a match
; with one of these dummy reference entries is due to an old file
; rather than a duplicate file.
;
; in:	dummy_str -> filename to add to reference list
;
; out:	
;
;,fe
========================================================================*/
void dummymosfile(byte *dummy_str) {


  mostime[moscount] = 0;
  mosdate[moscount] = 0;
  mossize[moscount] = 0;

  //!!!! add error checking to strdup() call

  mosfiles[moscount++] = strdup(dummy_str);
  }

/*======================================================================
;,fs
; void initmosfile(struct ffblk *mosarea)
; 
; initialize mos system file data structure for searches.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void initmosfile(struct ffblk *mosarea) {


  mostime[moscount] = mosarea->ff_ftime;
  mosdate[moscount] = mosarea->ff_fdate;
  mossize[moscount] = mosarea->ff_fsize;

  //!!!! add error checking to strdup() call

  mosfiles[moscount++] = strdup(mosarea->ff_name);
  }

/*======================================================================
;,fs
; void initsearch(void)
; 
; initialize search and replace code, read all ystem files and
; store information into internal data structures.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void initsearch(void) {

  struct ffblk searcharea;


  moscount = 0;
  findcount = 0;

  // collect all files in current directory.

  if(!findfirst("*.*",&searcharea,FA_NORMAL)) {
    initmosfile(&searcharea);
    while((!findnext(&searcharea)) && (moscount < MAX_SEARCH)) {
      initmosfile(&searcharea);
      }
    }

  // add dummy records to the reference list for those files that
  // no longer exist in mos 5.01.  if any old copies of these files
  // exist in any other directories/drives, we want them in the
  // report file.

  dummymosfile("HDSETUP.COM");
  dummymosfile("IMPORT.COM");
  dummymosfile("EXPORT.COM");
  }

/*======================================================================
;,fs
; void endsearch(void)
; 
; free up data structures used during search.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void endsearch(void) {

  word i;


  for(i=0; i<moscount; ++i) {
    if(mosfiles[i]) {
      free(mosfiles[i]);
      }
    }
  for(i=0; i<findcount; ++i) {
    if(findpath[i]) {
      free(findpath[i]);
      }
    }
  }

/*======================================================================
;,fs
; void checkupgrade(struct ffblk *searcharea, byte *path)
; 
; check current file against all mos files stored in internal data
; structures by initsearch.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void checkupgrade(struct ffblk *searcharea, byte *path) {

  word i;
  byte datsiz_diff;


  for(i=0;i<moscount;i++) {
    datsiz_diff = 1;
    if(mostime[i] == searcharea->ff_ftime) {
      if(mosdate[i] == searcharea->ff_fdate) {
        if(mossize[i] == searcharea->ff_fsize) {
          datsiz_diff = 0;
          }
        }
      }
    if(strcmp(mosfiles[i],searcharea->ff_name) == 0 && datsiz_diff) {
      findindex[findcount] = i;

      //!!!! add error checking to strdup() call

      findpath[findcount++] = strdup(path);
      }
    }
  }

/*======================================================================
;,fs
; void tracetree(byte *path)
; 
; searches path for mos files which are not current with files stored
; in mos directory and recursively call directory within path being
; passed.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void tracetree(byte *path) {

  byte dopath[65];
  byte workpath[65];
  struct ffblk dirsearch;
  struct ffblk filesearch;


  strcpy(dopath,path);
  strcat(dopath,"\\*.*");

  // first thing is to recursively call all directories.

  if(!findfirst(dopath,&dirsearch,FA_DIREC)) {
    if((dirsearch.ff_name[0] != '.') && ((dirsearch.ff_attrib & FA_DIREC) == FA_DIREC)) {
      strcpy(workpath,path);
      strcat(workpath,"\\");
      strcat(workpath,dirsearch.ff_name);
      tracetree(workpath);
      }
    while(!findnext(&dirsearch)) {
      if((dirsearch.ff_name[0] != '.') && ((dirsearch.ff_attrib & FA_DIREC) == FA_DIREC)) {
        strcpy(workpath,path);
        strcat(workpath,"\\");
        strcat(workpath,dirsearch.ff_name);
        tracetree(workpath);
        }
      }
    }

  // then check all files in the current directory.

  if(!findfirst(dopath,&filesearch,FA_NORMAL)) {
    checkupgrade(&filesearch,path);
    while(!findnext(&filesearch)) {
      checkupgrade(&filesearch,path);
      }
    }
  }

/*======================================================================
;,fs
; void searchfiles(void)
; 
; detect and search all drives on system.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void searchfiles(void) {

  byte i;
  byte rootpath[3];


  rootpath[0] = 'C';
  rootpath[1] = ':';
  rootpath[2] = 0;
  for(i=0;i<(setdisk(getdisk())-2);i++) {
    tracetree(rootpath);
    rootpath[0]++;
    }
  }

/*======================================================================
;,fs
; word findmosfiles(void)
; 
; check if any mos files are found on disk.  return 0 if none, otherwise
; the number found.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
word findmosfiles(void) {

  word i;
  FILE *fh;
  byte *lead_msg;


  if(mosfiles) {

    // perform search of disk drives.  
    // if any files found, write list to install.del.

    searchfiles();
    if(findcount) {
      fh = er_fopen(install_del,"w+");
      for(i=0;i<findcount;i++) {

        // a size of 0 is used as a flag to know when a match was
        // found with one of the dummy files "hdsetup.com", "??port.com"

        if(mossize[findindex[i]] != 0) {
          lead_msg = ul_get_msg("MISCMSGS",DELETE_MISCMSGS);
          }
        else {
          lead_msg = ul_get_msg("MISCMSGS",OLD_MISCMSGS);
          }
        fprintf(fh,"%s %s\\%s\n",lead_msg,findpath[i],mosfiles[findindex[i]]);

        }
      er_fclose(fh,install_del);
      }
    return(findcount);
    }
  else {
    return(0);
    }
  }

/*===================================================================
======================================= MAIN MENU HELPER FUNCTIONS
===================================================================*/


/*======================================================================
;,fs
; word checkspace(byte drv)
;
; check space on specified drive to see if mos can fit.
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
word checkspace(byte drv) {

  unsigned dx;
  long x;
  struct dfree dr;


  dx = (unsigned)(drv - 'A'+ 1);
  getdfree(dx,&dr);
  x = (long)dr.df_avail * (long)dr.df_sclus;
  x *= (long)dr.df_bsec;
  x = x / 1024l;
  if(x > MIN_MOS_SPACE) {
    return(1);
    }
  else {
    return(0);
    }
  }

/*======================================================================
;,fs
; void write_stagefile(void)
; 
; write current stage information to stage file, so that the next time the
; program is executed, it can be resumed in the same place.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void write_stagefile(void) {

  FILE *fp;


  fp = er_fopen(STAGE_FNAME,"wb");
  fprintf(fp,"%c %c %c",
  jmp_code,
  mm_choice,
  disktype);
  er_fclose(fp,STAGE_FNAME);
  }

/*======================================================================
;,fs
; word read_stagefile(void)
; 
; retreive stage and mm_choice type from stagefile.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
word read_stagefile(void) {

  FILE 	*fp;


  fp = er_fopen(STAGE_FNAME, "rb");
  fscanf(fp,"%c %c %c",
  &jmp_code,
  &mm_choice,
  &disktype);
  er_fclose(fp,STAGE_FNAME);
  return(1);
  }

/*======================================================================
;,fs
; byte exec_hdsetup(byte *swparm, byte msg_tag, byte vattr, byte local_jmp_code)
; 
; in:	switch -> string containing hdsetup parameter switch
;	msg_tag -> the message tag for the verification prompt
;	vattr = the video attribute to use
;	local_jmp_code = byte to control action after hdsetup reboots
;
; out:	retval = escape if no or escape was entered at initial prompt
;	retval = no_char if returning due to exec error
;
;,fe
========================================================================*/
byte exec_hdsetup(byte *swparm, byte *msg_tag, byte vattr, byte local_jmp_code) {

  byte response;


  response = prompt_for_yesno(msg_tag,vattr);
  if(response != yes_char)  {
    return(escape);
    }
  prep_display();
  ul_disp_msg(8,8,main_attr,"WAIT",0);
  jmp_code = local_jmp_code;
  write_stagefile();
  er_spawnl("hdsetup",swparm);

  // should reboot after hdsetup, must be error

  domainscreen();
  remove(STAGE_FNAME);
  return(no_char);
  }

/*======================================================================
;,fs
; byte format_drives(byte start_drv)
; 
; in:	start_drv = letter of first drive to prompt for
;
;   global:	max_drive = highest valid drive letter
;
; out:	
;
;,fe
========================================================================*/
byte format_drives(byte start_drv) {

  byte fdrive;
  byte response;
  byte x;
  byte y;
  byte last;
  byte msg[60];


  for(fdrive=start_drv;fdrive<=max_drive;fdrive++) {
    prep_display();
    last = ul_disp_msg(8,8,main_attr,"FORMAT",0);
    sprintf(msg,ul_get_msg("MISCMSGS",FORMAT_MISCMSGS),fdrive);
    y = 9 + last;
    ul_str2video(8,y,main_attr,msg,0);
    x = 8 + strlen(msg);
    response = ul_get_choice(x,y,main_attr,yes_char,no_char);
    if(response == escape)  {
      return(escape);
      }
    if(response == yes_char) {
      ul_clr_box(2,23,77,23,main_attr);
      sprintf(msg,"%c:",fdrive);
      vidattr = main_attr;
      setint21();
      atexit(resetint21);
      prep_display();
      ul_set_cursor(8,8);
      er_spawnl("format",msg);
      resetint21();
      ul_disp_msg(2,23,main_attr,"HELP2",0);
      }
    }
  return(yes_char);
  }

/*======================================================================
;,fs
; byte get_boot_drv(byte *valid_drvs)
; 
; in:	valid_drvs -> string of valid drive letters
;
; out:	retval = yes_char if ok
;	retval = escape if should return to main menu
;
;    global:	boot_drv = the chosen drive letter (uppercase)
;
;,fe
========================================================================*/
byte get_boot_drv(byte *valid_drvs) {

  byte msg[80];
  byte inbuff[2];
  byte x;
  byte y;
  byte last;
  byte i;
  byte *mptr;


  prep_display();
  if(strlen(valid_drvs) > 1) {
    mptr = msg;
    for(i=0;i<strlen(valid_drvs);i++) {
      *(mptr++) = valid_drvs[i];
      *(mptr++) = ':';
      *(mptr++) = ',';
      *(mptr++) = ' ';
      }
    *(mptr-2) = 0;
    while(1) {
      last = ul_disp_msg(8,8,main_attr,"DRIVECHOICE1",0);
      ul_str2video(8,last+9,main_attr,msg,0);
      ul_disp_msg(8,last+11,main_attr,"DRIVECHOICE2",0);
      ul_get_xy(&x,&y);
      if(ul_get_string(x,y,main_attr,inbuff,1,"") == escape) {
        return(escape);
        }
      boot_drive = toupper(inbuff[0]);
      if(strchr(valid_drvs,boot_drive) == NULL) {
        if(report_pause("BADDRIVE",main_attr) == escape) {
          return(escape);
          }
        continue;
        }
      break;
      }
    }
  else {
    boot_drive = valid_drvs[0];
    last = ul_disp_msg(8,8,main_attr,"ONEBOOT1",0);
    ul_char2video(8,last+9,main_attr,boot_drive);
    ul_char2video(9,last+9,main_attr,':');
    ul_disp_msg(8,last+11,main_attr,"ONEBOOT2",0);
    ul_eat_key();
    if(ul_get_key() == escape) {
      return(escape);
      }
    }
  if(!checkspace(boot_drive)) {
    report_pause("SPACE",main_attr);
    return(escape);
    }
  prep_display();
  ul_disp_msg(8,8,main_attr,"MSYS",0);
  sprintf(msg,"%c:",boot_drive);
  er_spawnl("msys",msg);
  return(yes_char);
  }


/*======================================================================
;,fs
; byte process_mospath(void)
; 
; produces a normalized drive/path string
; which always starts with drive letter, colon, leading
; backslash and then the path string.  a trailing backslash
; is never used.
;
; in:	
;
;    global:	mospath = drive and path for system files
;		boot_drv = the chosen drive letter (uppercase)
;
; out:	retval = 0 if ok
;	retval = 1 if invalid path
;
;    global:	mospath = drive and path for system files
;
;,fe
========================================================================*/
byte process_mospath(void) {

  byte drive_letter[MAXDRIVE];
  byte path[MAXPATH];
  byte fname[MAXFILE];
  byte ext[MAXEXT];
  byte temp_path[MAXPATH];
  byte i;


  fnsplit(mospath,drive_letter,path,fname,ext);
  if(drive_letter[0] == 0) {
    drive_letter[0] = boot_drive;
    drive_letter[1] = ':';
    drive_letter[2] = 0;
    }

  // compensate for the behavior of fnsplit.

  strcat(path,fname);
  fname[0] = 0;
  strcat(path,ext);
  ext[0] = 0;
  if(path[0] != '\\' && path[0] != 0) {
    strcpy(temp_path,path);
    path[0] = '\\';
    path[1] = 0;
    strcat(path,temp_path);
    }

  // trim any trailing blanks

  i = strlen(path) - 1;
  while(path[i] == ' ') {
    path[i] = 0;
    i--;
    }

  // check for a valid path entry

  if(path[0] == 0) {
    return(1);
    }
  if(path[0] == '\\' && path[1] == '.') {
    return(1);
    }
  if(strchr(path,' ') != NULL) {
    return(1);
    }

  // form the final path string, removing the ending backslash
  // that fnmerge will put on.

  fnmerge(mospath,drive_letter,path,fname,ext);
  i = strlen(mospath);
  if(i > 3) {
    mospath[i-1] = 0;
    }
  return(0);
  }

/*======================================================================
;,fs
; byte get_new_drv_path(byte *valid_drvs)
; 
; in:	valid_drvs -> string of valid drive letters
;
; out:	retval = yes_char if ok
;	retval = escape if should return to main menu
;
;    global:	boot_drv = the chosen drive letter (uppercase)
;		mospath = the drive/path for mos files (uppercase)
;
;,fe
========================================================================*/
byte get_new_drv_path(byte *valid_drvs) {

  byte retcode;
  byte response;
  byte x;
  byte y;
  byte last;
  byte *trunc_ptr;
  byte failure;


  while(1) {
    retcode = get_boot_drv(valid_drvs);
    if(retcode == escape) {
      return(escape);
      }
    mospath[0] = boot_drive;
    response = prompt_for_yesno("PCMOS",main_attr);
    if(response == escape)  {
      return(escape);
      }
    if(response == no_char) {
      ul_disp_msg(8,8,main_attr,"PATH",0);
      ul_draw_box(7,16,72,18,7,box_double);
      if(ul_get_string(8,17,cmd_attr,mospath,64,":._- \\") == escape) {
        return(escape);
        }
      if(process_mospath() == 1) {
        if(report_pause("BADPATH",main_attr) == escape) {
          return(escape);
          }
        continue;
        }
      prep_display();
      last = ul_disp_msg(8,8,main_attr,"VERPATH1",0);
      y = 9 + last;
      ul_str2video(8,y,main_attr,mospath,0);
      ul_disp_msg(8,y+2,main_attr,"VERPATH2",0);
      ul_get_xy(&x,&y);
      response = ul_get_choice(x,y,main_attr,yes_char,no_char);
      if(response == escape)  {
        return(escape);
        }
      if(response == no_char) {
        continue;
        }
      }

    // now, if the path doesn't already exist, build it, stepping
    // through the component sections one at a time.

    if(access(mospath,0) != 0) {
      failure = 0;
      trunc_ptr = &mospath[3];
      while((trunc_ptr = strchr(trunc_ptr,'\\')) != NULL) {
        *trunc_ptr = 0;
        if(access(mospath,0) != 0) {
          if(mkdir(mospath)) {
            failure = 1;
            break;
            }
          }
        *trunc_ptr = '\\';
        trunc_ptr++;
        }
      if(failure || mkdir(mospath)) {
        if(report_pause("BADPATH",main_attr) == escape) {
          return(escape);
          }
        continue;
        }
      break;
      }
    else {

      // when the directory does already exist, double-check
      // with the user before proceeding.

      response = prompt_for_yesno("ALREADY",main_attr);
      if(response == escape)  {
        return(escape);
        }
      if(response == yes_char) {
        break;
        }
      }
    }
  return(yes_char);
  }

/*======================================================================
;,fs
; byte prompt_for_disk(byte *msg1, byte *msg2, byte *zipname)
; 
; make them put in the system diskette
;
; in:	
;
; out:	retval = yes_char if ok
;	retval = escape if should return to main menu
;
;,fe
========================================================================*/
byte prompt_for_disk(byte *msg1, byte *msg2, byte *zipname) {


  if(report_pause(msg1,main_attr) == escape) {
    return(escape);
    }
  while(1) {
    if(access(zipname,0) != 0) {
      if(report_pause(msg2,main_attr) == escape) {
        return(escape);
        }
      continue;
      }
    break;
    }
  return(yes_char);
  }

/*======================================================================
;,fs
; void chk_for_patch(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void chk_for_patch(void) {

  byte cmd1[40];
  byte cmd2[40];

  if(access(PDRVR_FNAME,0) == 0) {
    sprintf(cmd1,"%c:\\command ",boot_drive);
    sprintf(cmd2,"/c copy %s . >nul",PDRVR_FNAME);
    er_spawnl(cmd1,cmd2);
    found_upd501 = 1;
    }
  }

/*======================================================================
;,fs
; byte copy_files(byte makebat, byte chkdup)
; 
; in:	makebat = 1 if should write autoexec.bat and acu.bat
;	chkdup = 1 if should check for duplicate mos files (upgrade)
;
;    global:	boot_drv = the chosen drive letter (uppercase)
;		mospath = the drive/path for mos files (uppercase)
;
; out:	retval = yes_char if ok
;	retval = escape if should return to main menu
;
;,fe
========================================================================*/
byte copy_files(byte makebat, byte chkdup) {

  byte response;
  byte drive_letter[MAXDRIVE];
  byte path[MAXPATH];
  byte fname[MAXFILE];
  byte ext[MAXEXT];
  FILE *fp;
  byte cmd[40];
  byte parm[40];
  word trial_ext;
  byte cfg_buf[20];		// holds new name of existing config.sys
  byte cfg_x;
  byte cfg_y;


  setdisk(boot_drive - 'A');
  chdir("\\");

  // if current disk != system disk, prompt for it

  if(access(SYS_FNAME,0) != 0) {
    if(prompt_for_disk("DISKS","NOTSYS",SYS_FNAME) == escape) {
      return(escape);
      }
    }

  // transfer $$mos.sys, $$shell.sys and command.com

  prep_display();
  ul_disp_msg(8,8,main_attr,"COPYS",0);
  er_spawnl("a:\\command","/c copy a:\\$$*.sys . >nul");
  er_spawnl("a:\\command","/c copy a:\\command.com . >nul");
  if(makebat) {

    // create autoexec.bat

    fp = er_fopen(AUTO_FNAME,"w");
    fprintf(fp,"BATECHO OFF\n");
    fprintf(fp,"PATH=%s\n",mospath);
    er_fclose(fp,AUTO_FNAME);

    // create acu.bat

    fnsplit(mospath,drive_letter,path,fname,ext);
    fp = er_fopen(ACU_FNAME, "w");
    fprintf(fp,"BATECHO OFF\n");
    fprintf(fp,"echo Loading Auto Configuration Utility. Please wait...\n");
    fprintf(fp,"%c:\n",drive_letter[0]);
    fprintf(fp,"CD %s%s%s\n", path, fname, ext);
    fprintf(fp,"ACU\n");
    fprintf(fp,"CD \\");
    er_fclose(fp,ACU_FNAME);
    }
  setdisk(mospath[0] - 'A');
  chdir(mospath);
  sprintf(cmd,"%c:\\command",boot_drive);

  // time to explode the first .exe file

  if(disktype == DT_360) {
    if(prompt_for_disk("DISK1","NOTAUX",ZIP_FNAME1) == escape) {
      return(escape);
      }
    prep_display();
    ul_disp_msg(8,8,main_attr,"COPY1",0);
    }
  chk_for_patch();
  sprintf(parm,"/c %s -o . > NUL",ZIP_FNAME1);
  er_spawnl(cmd,parm);

  // time to explode the second .exe file

  if(disktype == DT_360) {
    if(prompt_for_disk("DISK2","NOTAUX2",ZIP_FNAME2) == escape) {
      return(escape);
      }
    prep_display();
    ul_disp_msg(8,8,main_attr,"COPY2",0);
    chk_for_patch();
    }
  else {
    if(disktype == DT_720) {
      if(prompt_for_disk("DISK1","NOTAUX",ZIP_FNAME2) == escape) {
        return(escape);
        }
      prep_display();
      ul_disp_msg(8,8,main_attr,"COPY1",0);
      chk_for_patch();
      }
    }
  sprintf(parm,"/c %s -o . > NUL",ZIP_FNAME2);
  er_spawnl(cmd,parm);

  // check for duplicate files

  if(chkdup) {
    prep_display();
    ul_disp_msg(8,8,main_attr,"SEARCH",0);
    initsearch();
    install_del[0] = boot_drive;
    if(findmosfiles()) {
      response = prompt_for_yesno("DELVIEW",main_attr);
      if(response == yes_char)  {
        viewfile(install_del);
        }
      }
    endsearch();
    }
  setdisk(boot_drive - 'A');
  chdir("\\");

  // make sure the mos boot drive doesn't have a left-over 
  // config.sys.  if updat501.sys was found, write a one-line
  // config.sys to get that driver loaded.

  switch(mm_choice) {
  case MM_UPGRADE :
  case MM_REPLACE :
    if(access(CNFG_FNAME,0) == 0) {

      // with a root directory limited to 512 files, this loop
      // shouldn't have to bomb-out.

      trial_ext = 1;
      while(trial_ext < 1000) {
        sprintf(cfg_buf,"CONFIG.%03d",trial_ext);
        if(access(cfg_buf,0) != 0) {
          break;
          }
        trial_ext++;
        }
      rename(CNFG_FNAME,cfg_buf);
      prep_display();
      ul_disp_msg(8,8,main_attr,"CFGCHNG1",0);
      ul_get_xy(&cfg_x,&cfg_y);
      ul_str2video(cfg_x,cfg_y,main_attr,cfg_buf,0);
      ul_disp_msg(8,13,main_attr,"CFGCHNG2",0);
      ul_eat_key();
      ul_get_key();
      }

    // flowing through on purpose

  case MM_NEW :
  case MM_NEWDUAL :
    if(found_upd501) {
      fp = er_fopen(CNFG_FNAME,"w");
      fprintf(fp,"device=%s\\updat501.sys\n",mospath);
      er_fclose(fp,CNFG_FNAME);
      }
    }

  // generate the final half of the partition configuration report
  // and present it in the file browser

  if(disktype != DT_12) {
    if(prompt_for_disk("DISKS","NOTSYS",SYS_FNAME) == escape) {
      return(escape);
      }
    }
  prep_display();
  ul_disp_msg(8,8,main_attr,"REPORT2",0);
  after_report();
  report_pause("REPORT3",main_attr);
  viewfile(BEFAFT_FNAME);

  // offer to browse the readme file

  prep_display();
  file2view = README_FNAME;
  popup = 0;
  suppress_f1 = 0;
  esc_chk = 0;
  report_pause("SIGNOFF",main_attr);
  return(yes_char);
  }

/*======================================================================
;,fs
; void process_mlg(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void process_mlg(void) {

  byte response;

  // check the summary databased for any mlg-s partitions

  if(any_mlg(1)) {
    remove(STAGE_FNAME);
    response = prompt_for_yesno("MLG_S",main_attr);
    if(response != yes_char)  {
      ul_cls(7);
      ul_set_cursor(0,0);
      exit(0);
      }
    prep_display();
    ul_disp_msg(8,8,main_attr,"WAIT",0);
    er_spawnl("hdsetup","/k");

    // should reboot after hdsetup, must be error

    exit(1);
    }

  // check the summary databased for any mlg-p partitions

  if(any_mlg(0)) {
    remove(STAGE_FNAME);
    response = prompt_for_yesno("MLG_P",main_attr);
    if(response != yes_char)  {
      ul_cls(7);
      ul_set_cursor(0,0);
      exit(0);
      }
    prep_display();
    ul_disp_msg(8,8,main_attr,"WAIT",0);
    er_spawnl("hdsetup","/c");

    // should reboot after hdsetup, must be error

    exit(1);
    }
  }

/*======================================================================
;,fs
; void update_help_line(byte *msg_tag)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void update_help_line(byte *msg_tag) {


  ul_clr_box(2,23,77,23,main_attr);
  ul_disp_msg(2,23,main_attr,msg_tag,0);
  }

/*===================================================================
======================================= MAIN MENU CHOICE FUNCTIONS
===================================================================*/

/*======================================================================
;,fs
; byte process_mm_new(void)
; 
; in:	
;
;   global:	jmp_code = byte to control action after hdsetup reboots
;
; out:	retval = yes_char when done
;	retval = escape when should recycle to main menu
;
;,fe
========================================================================*/
byte process_mm_new(void) {

  byte valid_drvs[25];


  if(jmp_code == 0) {
    if(prompt_for_yesno("DESCRIBE_NEW",main_attr) != yes_char)  {
      return(escape);
      }
    exec_hdsetup("/n","DELETEALL",main_attr,1);
    return(escape);
    }
  if(format_drives('C') == escape) {
    return(escape);
    }
  any_boot_drives(0,valid_drvs);
  if(valid_drvs[0] == 0) {
    report_pause("NEEDBOOT",main_attr);
    return(escape);
    }
  if(get_new_drv_path(valid_drvs) == escape) {
    return(escape);
    }

  // transfer the files

  return(copy_files(1,0));
  }

/*======================================================================
;,fs
; byte process_mm_replace(void)
; 
; in:	
;
;   global:	jmp_code = byte to control action after hdsetup reboots
;
; out:	retval = yes_char when done
;	retval = escape when should recycle to main menu
;
;,fe
========================================================================*/
byte process_mm_replace(void) {

  byte retcode;

  if(prompt_for_yesno("DESCRIBE_REPLACE",main_attr) != yes_char) {
    return(escape);
    }

  // drive C: is the only valid drive for a replacement of dos with mos

  if(get_new_drv_path("C") == escape) {
    return(escape);
    }

  // transfer the files

  retcode = copy_files(1,0);
  if(retcode != escape) {
    report_pause("REPLACE",main_attr);
    }
  return(retcode);

  }

/*======================================================================
;,fs
; byte process_mm_upgrade(void)
; 
; in:	
;
;   global:	jmp_code = byte to control action after hdsetup reboots
;
; out:	retval = yes_char when done
;	retval = escape when should recycle to main menu
;
;,fe
========================================================================*/
byte process_mm_upgrade(void) {

  byte valid_drvs[25];
  byte retcode;
  byte pathok;
  byte *tptr;


  // tell'em what's about to happen

  if(prompt_for_yesno("DESCRIBE_UPGRADE",main_attr) != yes_char) {
    return(escape);
    }

  // get boot drive and path

  any_boot_drives(0,valid_drvs);
  if(valid_drvs[0] == 0) {
    report_pause("NEEDBOOT",main_attr);
    return(escape);
    }
  pathok = 0;
  while(pathok == 0) {
    retcode = get_boot_drv(valid_drvs);
    if(retcode == escape) {
      return(escape);
      }
    while(1) {
      ul_disp_msg(8,8,main_attr,"UPATH",0);
      ul_draw_box(7,16,72,18,7,box_double);
      if(ul_get_string(8,17,cmd_attr,mospath,64,":._- \\") == escape) {
        return(escape);
        }
      if(mospath[1] != ':') {
        if(report_pause("NEEDDRV",main_attr) == escape) {
          return(escape);
          }
        continue;
        }
      if(mospath[0] == 'A') {
        if(report_pause("NOADRV",main_attr) == escape) {
          return(escape);
          }
        continue;
        }
      if(access(mospath,0) == 0) {
        pathok = 1;
        break;
        }
      if(report_pause("PATH_NON_EXISTANT",main_attr) == escape) {
        return(escape);
        }
      }
    }

  // at this point:
  //  boot_drv = the boot drive letter (uppercase)
  //  mospath = the drive and path for the system files

  tptr = strchr(mospath,0);
  if(*(tptr-1) != '\\') {
    strcat(mospath,"\\");
    }
  strcat(mospath,"*.*");
  if(ul_any_files(mospath,UPGRADE_ATTRS) == 0) {
    if(prompt_for_yesno("UPD_KILL",main_attr) != yes_char) {
      return(escape);
      }
    if(ul_remove_files(mospath,UPGRADE_ATTRS) != 0) {
      report_pause("UPD_KILL_E",main_attr);
      return(escape);
      }
    }
  *tptr = 0;

  // transfer the files

  return(copy_files(0,1));
  }

/*======================================================================
;,fs
; byte process_mm_newdual(void)
; 
; in:	
;
;   global:	jmp_code = byte to control action after hdsetup reboots
;
; out:	retval = yes_char when done
;	retval = escape when should recycle to main menu
;
;,fe
========================================================================*/
byte process_mm_newdual(void) {

  byte valid_drvs[25];
  byte retcode;

  if(jmp_code == 0) {
    if(prompt_for_yesno("DESCRIBE_DUAL",main_attr) != yes_char) {
      return(escape);
      }
    if(prompt_for_yesno("DESCRIBE_DUAL2",main_attr) != yes_char) {
      return(escape);
      }
    exec_hdsetup("/d","DELETEALL",main_attr,1);
    return(escape);
    }
  any_boot_drives(1,valid_drvs);
  if(valid_drvs[0] == 0) {
    report_pause("NEEDSEC2",main_attr);
    return(escape);
    }
  if(format_drives('D') == escape) {
    return(escape);
    }
  if(get_new_drv_path(valid_drvs) == escape) {
    return(escape);
    }

  // transfer the files

  return(copy_files(1,0));
  }

/*======================================================================
;,fs
; byte process_mm_mos2dual(void)
; 
; in:	
;
;   global:	jmp_code = byte to control action after hdsetup reboots
;
; out:	retval = yes_char when done
;	retval = escape when should recycle to main menu
;
;,fe
========================================================================*/
byte process_mm_mos2dual(void) {


  report_pause("DESCRIBE_MOS2DUAL",main_attr);
  return(escape);
  }

/*======================================================================
;,fs
; byte process_mm_dos2dual(void)
; 
; in:	
;
;   global:	jmp_code = byte to control action after hdsetup reboots
;
; out:	retval = yes_char when done
;	retval = escape when should recycle to main menu
;
;,fe
========================================================================*/
byte process_mm_dos2dual(void) {

  byte valid_drvs[25];


  report_pause("DESCRIBE_DOS2DUAL",main_attr);
  return(escape);
  }

/*======================================================================
;,fs
; void main_menu(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void main_menu(void) {

  byte x;
  byte y;
  byte inbuff[2];

  while(1) {
    if(mm_choice == MM_NOCHOICE) {
      prep_display();
      esc_chk = 0;
      update_help_line("HELP1");
      ul_disp_msg(8,8,main_attr,"MAINMENU",0);
      ul_get_xy(&x,&y);
      while(1) {
        if(ul_get_string(x,y,main_attr,inbuff,1,"") == escape) {
          mm_choice = MM_QUIT;
          }
        else {
          mm_choice = inbuff[0];
          }
        if(mm_choice == MM_QUIT) {
          update_help_line("HELP1");
          return;
          }
        if(mm_choice < MM_LOWEST || mm_choice > MM_HIGHEST) {
          ul_beep();
          continue;
          }
        break;
        }
      }
    prep_display();
    esc_chk = 1;
    update_help_line("HELP2");
    if((*mm_func[mm_choice-'1'])() == yes_char) {
      break;
      }
    mm_choice = MM_NOCHOICE;
    jmp_code = 0;
    }
  }

/*===================================================================
========================================================= MAIN
===================================================================*/

/*======================================================================
;,fs
; int main(int argc, char *argv[])
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
int main(int argc, char *argv[]) {

  word i;
  byte *env_ptr;
  struct REGPACK reg;
  word mos_ver;
  byte retcode;


  printf("Analyzing existing partition structure, Please wait.\n"); /* @@XLAT */
  global_argv[0] = argv[0];

  // init video

  ul_set_vidptr(0,25,80);		
  if(ul_get_vidseg() == 0xb000) {
    main_attr = 0x07;
    cmd_attr = 0x0f;
    error_attr = 0x0f;
    }
  else {
    main_attr = MAIN_ATTR_DEFAULT;
    cmd_attr = CMD_ATTR_DEFAULT;
    error_attr = ERROR_ATTR_DEFAULT;
    }

  // init keyboard hook for f1 and f10

  ul_set_gkhook(hook_func);

  // init control-c handler

  signal(SIGINT,breakhandler);		

  // init message system

  switch(ul_init_msg("install.msg"))	 {
  case 0:
    break;

  case ul_msg_er_memory:
    puts("Error: Insufficient memory for message file");  /* @@XLAT */
    exit(1);

  case ul_msg_er_invf:
    puts("Error: Message file format is invalid");  /* @@XLAT */
    exit(1);

  case ul_msg_er_open:
    puts(
    "Error: Message file open failure\n"			/* @@XLAT */
    "The file INSTALL.MSG must reside\n"			/* @@XLAT */
    "within the same directory as INSTALL.EXE\n"		/* @@XLAT */
    );
    exit(1);

  default:
    puts("Error: Unknown error processing message file");  /* @@XLAT */
    exit(1);
    }
  if(init_msg_ptrs()) {
    puts("Error: Data missing within message file");  /* @@XLAT */
    exit(1);
    }

  // check for mos

  reg.r_ax = 0x3000;
  reg.r_bx = 0x3000;
  reg.r_cx = 0x3000;
  reg.r_dx = 0x3000;
  intr(0x21,&reg);
  mos_ver = reg.r_ax;
  reg.r_ax = 0x3000;
  reg.r_bx = 0;
  intr(0x21,&reg);
  if(reg.r_ax == mos_ver) {
    ul_cls(7);
    ul_disp_msg(0,0,7,"ONDOS",0);
    exit(1);
    }
  env_ptr = getenv("COMSPEC");
  if(!strstr(env_ptr,"A:\\")) {
    ul_cls(7);
    ul_disp_msg(0,0,7,"ERRORB",0);
    exit(1);
    }
  max_drive = setdisk(getdisk()) + 'A' - 1;

  // make hdsetup generate a summary file.

  get_summary();		

  // display main menu and check for stagefile

  domainscreen();
  if(access(STAGE_FNAME,0) == 0) {
    read_stagefile();
    remove(STAGE_FNAME);
    }
  else {
    if(access(ZIP_FNAME1,0) == 0) {
      if(access(ZIP_FNAME2,0) == 0) {
        disktype = DT_12;
        }
      else {
        disktype = DT_720;
        }
      }
    else {
      disktype = DT_360;
      }

    // ask them if this is the first time.  if it is,
    // generate the initial partition configuration report

    retcode = prompt_for_yesno("REPORT0",main_attr);
    if(retcode == escape) {
      ul_cls(7);
      ul_set_cursor(0,0);
      exit(0);
      }
    prep_display();
    if(retcode == yes_char) {
      ul_disp_msg(8,8,main_attr,"REPORT1",0);
      before_report();
      }
    else {

      // if they say no, not the first time, but there's no file
      // already, generate one.

      if(access(BEFAFT_FNAME,0) != 0) {
        ul_disp_msg(8,8,main_attr,"REPORT1",0);
        before_report();
        }
      }

    // convert any existing mlg partitions

    mm_choice = MM_BLANK;
    process_mlg();

    // issue general backup warning

    if(prompt_for_yesno("BACKUP",main_attr) != yes_char)  {
      ul_cls(7);
      ul_set_cursor(0,0);
      exit(0);
      }
    mm_choice = MM_NOCHOICE;
    jmp_code = 0;
    }

  main_menu();

  ul_cls(main_attr);
  switch(mm_choice) {

  case MM_QUIT:
    ul_cls(7);
    ul_disp_msg(0,0,7,"ABORT",0);
    exit(0);

  case MM_NEW:
  case MM_REPLACE:
    ul_disp_msg(0,0,main_attr,"DONE1",0);
    break;

  case MM_UPGRADE:
    ul_disp_msg(0,0,main_attr,"DONE1",0);
    ul_eat_key();
    ul_get_key();
    ul_cls(main_attr);
    ul_disp_msg(0,0,main_attr,"DONE3",0);
    break;

  case MM_NEWDUAL:
    ul_disp_msg(0,0,main_attr,"DONE",0);
    break;

    }
  ul_eat_key();
  ul_get_key();
  ul_cls(7);
  ul_disp_msg(0,0,7,"DONE2",0);
  return(0);
  }

/*

alternate ending logic for the above line:

ul_disp_msg(0,0,7,"DONE2",0);


if(mm_choice == MM_UPGRADE || mm_choice == MM_REPLACE) {

  // for upgrade and replace, make sure the boot drive is the 
  // current drive and then exec acu so a config.sys with 
  // updat501.sys is for-sure made.

  setdisk(boot_drive - 'A');
  chdir(mospath);
  execl("acu",global_argv[0],NULL);

  }
else {
  ul_disp_msg(0,0,7,"DONE2",0);
  }

*/

