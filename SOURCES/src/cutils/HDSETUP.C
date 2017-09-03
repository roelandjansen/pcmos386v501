/*=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        hdsetup.c
 task name:          hdsetup.exe
 creation date:      12/16/91
 revision date:      05/21/92
 author:             mjs
 description:        pc-mos partitioning utility

======================================================================

mjs 03/27/92	dlg mods: created this module.

mjs 04/01/92	make sure that a '-' is displayed for the drive
		letter for partition type OTH.

mjs 04/09/92	correct write_tree.  once the first extended partition
		node has been processed, must use pptr1->prE[1].ExtPR 
		to check the next node rather than 
		pptr1->prE[ext_ndx].ExtPR.

mjs 04/16/92	corrected my 04/01 fix.  always assigning a '-' to
		origdriveletter in drvltrs_work() was causing a
		crash when write_tree() tried to exec msys/m.

mjs 05/21/92	modified calls to ul_view() to match new version
		of that function.  enables install to handle large
		read.me files.
		modified the "OTH" string written to the summary
		file for proper columnar alignment.

=======================================================================
*/

#include <stdio.h>
#include <mem.h>
#include <dos.h>
#include <conio.h>
#include <string.h>
#include <stdlib.h>
#include <process.h>

#include "asmtypes.h"
#include "dskstruc.h"
#include "ulib.h"
#include "vidattr.h"
#include "summary.h"

byte *c = "(c) Copyright 1992 The Software Link, Incorporated";  /* @@XLAT */

//=========================================================
// the pr_type record (pr for partition record) contains data specific
// to each sector containing a PT

struct prec {
  byte prExt;			// != 0 if this is an extended parition 
  byte prTblNum;		// 0 based partition table number
  struct prec1 {
    pe_type PT;			// copy of PT data 
    byte MLG;			// flags MLG type partitions 
    byte NeedMSYS;		// for mlg->dlg conversion 
    byte DriveLetter;		// the assigned drive letter 
    byte OrigDriveLetter;	// the initially assigned drive letter 
    struct prec *ExtPR;	 	// ptr to next node when PTC == 5 
    } prE[4];			// one pr1_type record per PT 
  };

typedef struct prec pr_type;


//=========================================================
// the dm_type record (dm for delete mlg-s) contains data 
// needed to automatically replace each deleted mlg-s partition
// with an extended partition (part of the hdsetup/k logic).

struct dmrec {
  byte dmDriveLetter;		// the assigned drive letter 
  word dmCylds;			// total # of cylinders 
  };

typedef struct dmrec dm_type;


//=========================================================
// the dr_type record (pr for drive record) contains data specific to
// each hard drive

struct drec {
  byte drDriveNum;		// 0 based drive number 
  word drHeads;			// total # of heads 
  word drSPT;			// sectors per track 
  word drCylds;			// total # of cylinders 
  pr_type *drPR;		// ptr to 1st pr_type 
  struct drec *drNext;		// ptr to next drive record 
  };

typedef struct drec dr_type;


//=========================================================
// the lr_type record (lr for list record) contains data specific to
// each displayable list entry

struct lrec {
  pr_type *lrHomeNode;		// the corresponding partition node 
  byte lrHomeNdx;		// the corresponding partition entry 
  word lrMegs;			// value for the megs column 
  word lrCylds;			// value for the cylds column 
  word lrStart;			// value for the start column 
  word lrEnd;			// value for the end column 
  struct lrec *lrPrev;		// ptr to next list record 
  struct lrec *lrNext;		// ptr to next list record 
  };

typedef struct lrec lr_type;

//=========================================================
// global data 

#include "mbrbuf.inc"		/* mbr sector buffer - from genmbr.exe */


#define SUG_MEGS_MAX 3		// suggested max for secondary partitions
#define HELP_FNAME "hdsetup.hlp"
#define MSYS_FNAME "msys.com"
#define MSG_FNAME "hdsetup.msg"
#define MSYS_SIGNATURE "MSYS/M"
#define MSYS_SIGLEN 6
#define START_LETTER 'C'	// starting hard drive letter



union REGS regs; struct SREGS sregs;

// globals for video display

byte main_attr;
byte cmd_attr;
byte error_attr;
byte inverse_attr;

// globals for list management

dr_type	*Root_dr = NULL;	// root of list of dr_type nodes
lr_type	*Root_lr;		// root of list of lr_type nodes
lr_type	*BRoot_lr;		// backwards root of list of lr_type nodes
lr_type *top_lr;		// ptr to list record at top of display
lr_type *bot_lr;		// ptr to list record at bottom of display

// globals for sector buffers

byte	sct_buf[512];		// sector buffer
byte	sct_buf2[512];		// sector buffer

// global message string pointers 

byte 	*unalloc_msg;
byte    *mlg_msg;
byte    *dlg_msg;
byte    *sml_msg;
byte	*oth_msg;
byte    *dashe_msg;
byte    *dashs_msg;
byte    *dashp_msg;
byte    *dasho_msg;
byte    *newpri_msg;
byte    *newext_msg;
byte    *newsec_msg;
byte    *large_msg;
byte	yes_char;		// get from msg file, u.s. == 'Y'
byte	no_char;		// get from msg file, u.s. == 'N'
byte	begin_char;		// get from msg file, u.s. == 'B'
byte	end_char;		// get from msg file, u.s. == 'E'
byte	*chng_msg0;		// Memory data:
byte	*chng_msg1;		// Disk data:
byte	*chng_msg2;		// Unchanged
byte	*chng_msg3;		// Changed
byte	*insdisk_tag;

// other globals

byte	assign_letter = START_LETTER;	// used by drvltrs_work()
byte	hard_drives;		// the number of hard drivers (0, 1 or 2)
byte	drive_num = 0;		// the currently selected drive number
byte	f1_hook_active = 0;
byte	home_path[81];		// build home path in here
byte	msys_file[81];		// use to check for msys/m
byte	msg_file[81];		// use to find hdsetup.msg
byte	found_msysm = 0;	// flags availability of msys/m
byte	dup_drvltr;		// makes drvltrs_work set origdriveletters
word	dos_version;
word	mos_version;
byte	*global_argv[1];
byte	takeout_key = 0;
byte	takein_key;
byte	derive_lr = 1;		// signals that a new lr_type list be made
byte	changed_memory = 0;	// != 0 when the database is changed
byte	changed_disk = 0;	// != 0 when the disk is changed
byte	d_switch = 0;		// /d for dual
byte	n_switch = 0;		// /n for new
byte	s_switch = 0;		// /s to generate summary file
byte	c_switch = 0;		// /c to convert mlg -> dlg
byte	k_switch = 0;		// /k to delete mlg-s
byte	no_switches = 1;	// == 0 when any switch is used
FILE	*sum_file;		// used by /s logic to write summary file
byte	validate_ptc_once = 0;	// flag for validate_ptc() calling
byte	no_ext;			// set if no ext partitions for edit drive
word	new_megs;
word	new_cylds;
word	new_megs_max;
word	new_cylds_max;


// setting b0 within cmd_disp_state will insure a difference 
// between cmd_disp_state and new_disp_state the first 
// time disp_cmd_box() is called

word	cmd_disp_state = 1;	// holds current command display state flags


//========== globals that probably should be locals

word	t1;
word	t2;
byte	p1;
byte	p2;
byte	p3;
word	bs;
word	bs2;
word	es;
word	es2;
word	bc;
word	bc2;
word	ec;
word	ec2;
word	tbs;
word	tbc;
word	tes;
word	tec;


// globals for edit point management 

dr_type *edit_dr;		// ptr to drive currently being edited
lr_type *edit_lr;		// ptr to list record currently being edited
byte    edit_line = 0;		// list area relative line number for the edit line
byte    edit_cylds = 0;		// == 0 if cursor is in megs, != 0 for cylds
word    edit_megs_max;		// max megs value possible for current edit line
word    edit_cylds_max;		// max cylds value possible for current edit line
pr_type *edit_pr;		// shorthand for edit_lr->lrHomeNode
byte    edit_pndx;		// shorthand for edit_lr->lrHomeNdx
pr_type *edit_pr_hold = NULL;	// ptr to pr_type record that is to be the edit point
byte    edit_pndx_hold;		// index associated with edit_pr_hold
pr_type *edit_mbrpt;		// ptr to mbr's pt for the edit drive

// values for find_first_fit_gap() and find_largest_gap()

#define FIND_PRI 0
#define FIND_EXT 1
#define FIND_SEC 2

// display format info

// line 4 is for column heading text
// line 5 is for column heading underbars
// lines 6 through 14 are the list area.  
// lines 16 through 23 are for text and prompts 

#define L_DRV_COL   4			// x coord for drive letter 
#define L_BOOT_COL  L_DRV_COL+6		// x coord for boot indicator 
#define L_TYPE_COL  L_BOOT_COL+5	// x coord for partition type 
#define L_MEGS_COL  L_TYPE_COL+7	// x coord for megs 
#define L_CYLDS_COL L_MEGS_COL+7	// x coord for total cylinders 
#define L_START_COL L_CYLDS_COL+7	// x coord for starting cylinder 
#define L_END_COL   L_START_COL+7	// x coord for ending cylinder 

#define L_MEGS_WIDTH 5
#define L_CYLDS_WIDTH 5
#define L_START_WIDTH 5
#define L_END_WIDTH 5

#define LIST_TOP  6		// y coord for top line of list area 
#define LIST_LINES  9		// # of lines in list area 

// data used to scroll the list area and manage the edit line

#define LIST_XL L_DRV_COL
#define LIST_XR (L_END_COL+L_END_WIDTH)

#define MORE_X (LIST_XR+1)
#define MORE_Y1 LIST_TOP
#define MORE_Y2 (LIST_TOP+LIST_LINES-1)

#define MEGS_X_CURSOR (L_MEGS_COL+L_MEGS_WIDTH-1)
#define CYLDS_X_CURSOR (L_CYLDS_COL+L_CYLDS_WIDTH-1)

// coords/strings used to manage the command window

byte *cmdl1 = "F1             F3             F5             F7             F9             ";

#define L1_X	3
#define L1_Y	22

byte *cmdl2 = "F2             F4             F6             F8            F10             ";

#define L2_X	3
#define L2_Y	23

#define F1_X	6
#define F1_Y	22
#define F1_FLAG  0x0002
#define F2_X	6
#define F2_Y	23
#define F2_FLAG  0x0004
#define F3_X	21
#define F3_Y	22
#define F3_FLAG  0x0008
#define F4_X	21
#define F4_Y	23
#define F4_FLAG  0x0010
#define F5_X	36
#define F5_Y	22
#define F5_FLAG  0x0020
#define F6_X	36
#define F6_Y	23
#define F6_FLAG  0x0040
#define F7_X	51
#define F7_Y	22
#define F7_FLAG  0x0080
#define F8_X	51
#define F8_Y	23
#define F8_FLAG  0x0100
#define F9_X	66
#define F9_Y	22
#define F9_FLAG  0x0200
#define F10_X	66
#define F10_Y	23
#define F10_FLAG 0x0400

byte *f1_str;
byte *f1_strx;
byte *f2_str;
byte *f2_strx;
byte *f3_str;
byte *f3_strx;
byte *f4_str;
byte *f4_strx;
byte *f5_str;
byte *f5_strx;
byte *f6_str;
byte *f6_strx;
byte *f7_str;
byte *f7_strx;
byte *f8_str;
byte *f8_strx;
byte *f9_str;
byte *f9_strx;
byte *f10_str;
byte *f10_strx;

// coords/strings used to manage the status window

// for the "Mode:" line

#define ST_MOD_X  52
#define ST_MOD_Y  5
byte st_mod_x2;

byte *st_mod;
byte *st_mod_a;
byte *st_mod_b;
byte *st_mod_c;
byte *st_mod_d;
byte *st_mod_e;
byte *st_mod_f;
byte *st_mod_g;
byte *st_mod_h;

// for the "ESC" line

#define ST_ESC_X  52
#define ST_ESC_Y  6
byte st_esc_x2;

byte *st_esc;
byte *st_esc_a;
byte *st_esc_b;
byte *st_esc_c;
byte *st_esc_d;
byte *st_esc_e;

// for the keyboard action notes

#define ST_KYA_X  52
#define ST_KYA_Y  7
#define ST_KYB_X  52
#define ST_KYB_Y  8
#define ST_KYC_X  52
#define ST_KYC_Y  9
#define ST_KYD_X  52
#define ST_KYD_Y  10

byte *st_kya;
byte *st_kyb;
byte *st_kyc;
byte *st_kyd;

// for the "Drive x of x" line

#define ST_DRV_X   52
#define ST_DRV_Y   4

byte *st_drv_a;
byte *st_drv_b;
byte *st_drv_format;

// for the "changes" lines

#define ST_CHNG_X1 52
#define ST_CHNG_X2 66
#define ST_CHNG_Y1 13
#define ST_CHNG_Y2 14

// state values for display_state()

enum dstates {
  st_ceneng,
  st_ceneg,
  st_cee,
  st_subpm,
  st_addpm,
  st_delpm,
  st_dplpm,
  st_addpri,
  st_addext,
  st_addsec,
  st_exit,
  st_chwarn,
  st_secwarn,
  st_mlg2dlg,
  st_exit2,
  st_prdlal,
  st_prdlmlgs
  };

// coords/strings used to manage the new entry/prompts window

#define NEW_LINE 17
#define PM_LINE 17

#define EPW_XL 1
#define EPW_YT 16
#define EPW_XR 78
#define EPW_YB 20

#define MAX_POS_Y 16

// globals for ul_view()

byte *vmsg1;
byte *vmsg2;
byte help_file[81];

// error code values for report_error()

enum recodes {
  errcode_insuficmem, errcode_diskread, errcode_diskwrite, 
  errcode_data1, errcode_data2, errcode_data3, errcode_data4, 
  errcode_data5, errcode_data6, errcode_badcylnum, 
  errcode_execmsys};

// globals for lead-through logic

#define LT_NULL		0
#define LT_NSWITCH	1
#define LT_DSWITCH	2

byte	lead_through = LT_NULL;
byte	lead_stage = 0;

//=========================================================
//========================== APPLICATION SPECIFIC FUNCTIONS
//=========================================================

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

  win = ul_open_window(0,0,79,24,7,7,box_none);
  if(ul_view(fname,vmsg1,vmsg2,main_attr)) {
    ul_disp_msg(1,12,error_attr,"VIEWERR",1);
    ul_eat_key();
    ul_get_key();
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

  switch(key) {
  case f1:
    if(f1_hook_active == 0) {
      f1_hook_active = 1;
      viewfile(help_file);
      f1_hook_active = 0;
      }
    return(1);

  default:
    return(0);
    }
  }

/*======================================================================
;,fs
; void clr_prompt_win(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void clr_prompt_win(void) {

  ul_clr_box(EPW_XL,EPW_YT,EPW_XR,EPW_YB,main_attr);
  }

/*======================================================================
;,fs
; void blank_line(byte x, byte y, byte vidattr, byte len)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void blank_line(byte x, byte y, byte vidattr, byte len) {

  ul_clr_box(x,y,x+len-1,y,vidattr);
  }

/*======================================================================
;,fs
; byte get_int(byte x, byte y, byte w, byte atr, word *val, word max, byte *xset, byte sc)
; 
; in:	
;
;	sc = starting keystroke (0 if none)
;
; out:	retval = 1 if value error on entry
;	else retval = the keystroke which caused the exit
;
;,fe
========================================================================*/
byte get_int(byte x, byte y, byte w, byte atr, word *val, word max, byte *xset, byte sc) {

  byte key;
  byte once;
  word hold_val;
  dword test_val;

  if(*val > max) {
    ul_beep();
    return(1);
    }
  once = 0;
  if((sc >= '0' || sc <= '9') && (sc - '0') <= max) {
    *val = 0;
    once = 1;
    }
  while(1) {
    ul_display_decimal(*val,x,y,atr,w);
    if(sc != 0) {
      key = sc;
      sc = 0;
      }
    else {
      key = ul_get_key();
      }
    switch(key) {

    case '0' :
    case '1' :
    case '2' :
    case '3' :
    case '4' :
    case '5' :
    case '6' :
    case '7' :
    case '8' :
    case '9' :
      if(once == 0) {
        *val = 0;
        once = 1;
        }
      hold_val = *val;
      test_val.li = *val;
      test_val.li *= 10;
      test_val.li += key - '0';
      if(test_val.h[1] != 0 || test_val.h[0] > max) {
        ul_beep();
        *val = hold_val;
        }
      else {
        *val = test_val.h[0];
        }
      break;

    case backspace :
      *val = *val / 10;
      once = 1;
      break;

    default :
      if(key != 0 && strchr(xset,key) != NULL) {
        return(key);
        }
      ul_beep();
      }
    }
  }

/*======================================================================
;,fs
; void report_error(enum recodes errcode)
;
; in:	
;
; out:	
;	
;,fe
========================================================================*/
void report_error(enum recodes errcode) {

  char *leadmsg;

  ul_cls(7);
  leadmsg = ul_get_msg("ERRORTAGS",0);
  ul_str2video(0,12,main_attr,leadmsg,0);
  ul_str2video(strlen(leadmsg),12,main_attr,ul_get_msg("ERRORTAGS",errcode+1),0);
  ul_set_cursor(0,14);
  }

/*======================================================================
;,fs
; void display_stats(enum dstates state)
;
; in:	
;
; out:	
;	
;,fe
========================================================================*/
void display_stats(enum dstates state) {

  byte ky_bits;
  byte xmsg[81];
  byte i;
  byte j;

  ul_clr_box(51,4,78,14,main_attr);
  ul_str2video(ST_MOD_X,ST_MOD_Y,main_attr,st_mod,0);
  if(edit_dr == Root_dr) {
    i = '1';
    }
  else {
    i = '2';
    }
  if(Root_dr->drNext == NULL) {
    j = '1';
    }
  else {
    j = '2';
    }
  sprintf(xmsg,st_drv_format,st_drv_a,i,st_drv_b,j);
  ul_str2video(ST_DRV_X,ST_DRV_Y,main_attr,xmsg,0);

  ul_str2video(ST_CHNG_X1,ST_CHNG_Y1,main_attr,chng_msg0,0);
  if(changed_memory) {
    ul_str2video(ST_CHNG_X2,ST_CHNG_Y1,inverse_attr,chng_msg3,0);
    }
  else {
    ul_str2video(ST_CHNG_X2,ST_CHNG_Y1,main_attr,chng_msg2,0);
    }
  ul_str2video(ST_CHNG_X1,ST_CHNG_Y2,main_attr,chng_msg1,0);
  if(changed_disk) {
    ul_str2video(ST_CHNG_X2,ST_CHNG_Y2,inverse_attr,chng_msg3,0);
    }
  else {
    ul_str2video(ST_CHNG_X2,ST_CHNG_Y2,main_attr,chng_msg2,0);
    }

  ul_str2video(ST_ESC_X,ST_ESC_Y,main_attr,st_esc,0);
  ky_bits = 0;
  switch(state) {
  case st_ceneng :		/* cell editing, non-entry mode, non-gap */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_a,0);
    ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_e,0);
    if(edit_pr != NULL && edit_pr->prE[edit_pndx].MLG == 1) {
      ky_bits = 0x03;
      }
    else {
      ky_bits = 0x07;
      }
    break;

  case st_ceneg :		/* cell editing, non-entry mode, gap */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_a,0);
    ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_e,0);
    ky_bits = 0x03;
    break;

  case st_cee :		/* cell editing, entry mode */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_b,0);
    ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_b,0);
    ky_bits = 0x0f;
    break;

  case st_subpm :		/* subtract prompt */
  case st_addpm :		/* add prompt */
  case st_delpm :		/* delete prompt */
  case st_chwarn :		/* change warning prompt */
  case st_secwarn :		/* add/edit secondary prompt */
  case st_mlg2dlg :		/* convert mlg->dlg prompt */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_b,0);
    ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_b,0);
    ky_bits = 0x00;
    break;

  case st_dplpm :		/* delete pri last prompt */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_b,0);
    ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_c,0);
    ky_bits = 0x00;
    break;

  case st_addpri :		/* add primary partition */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_c,0);
    if(lead_through == LT_NULL) {
      ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_d,0);
      }
    ky_bits = 0x0e;
    break;

  case st_addext :		/* add extended partition */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_d,0);
    ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_d,0);
    ky_bits = 0x0e;
    break;

  case st_addsec :		/* add secondary partition */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_e,0);
    if(lead_through == LT_NULL) {
      ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_d,0);
      }
    ky_bits = 0x0e;
    break;

  case st_exit :		/* at exit prompt */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_f,0);
    ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_a,0);
    ky_bits = 0x00;
    break;

  case st_exit2 :		/* at reboot prompt */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_f,0);
    ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_e,0);
    ky_bits = 0x00;
    break;

  case st_prdlal:		/* at prompt for auto delete all */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_g,0);
    ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_e,0);
    ky_bits = 0x00;
    break;

  case st_prdlmlgs:		/* at prompt for auto delete all mlg-s */
    ul_str2video(st_mod_x2,ST_MOD_Y,main_attr,st_mod_h,0);
    ul_str2video(st_esc_x2,ST_ESC_Y,main_attr,st_esc_e,0);
    ky_bits = 0x00;
    break;

    }

  if(ky_bits & 0x01) ul_str2video(ST_KYA_X,ST_KYA_Y,main_attr,st_kya,0);
  if(ky_bits & 0x02) ul_str2video(ST_KYB_X,ST_KYB_Y,main_attr,st_kyb,0);
  if(ky_bits & 0x04) ul_str2video(ST_KYC_X,ST_KYC_Y,main_attr,st_kyc,0);
  if(ky_bits & 0x08) ul_str2video(ST_KYD_X,ST_KYD_Y,main_attr,st_kyd,0);
  }

/*======================================================================
;,fs
; void display_cmd_box(word new_disp_state)
; 
; display the command menu and status info in the lower part of the 
; screen.
;
; in:	
;
; out:	
;	
;,fe
========================================================================*/
void display_cmd_box(word new_disp_state) {

  if(new_disp_state == cmd_disp_state) return;
  ul_str2video(L1_X,L1_Y,main_attr,cmdl1,0);
  ul_str2video(L2_X,L2_Y,main_attr,cmdl2,0);
  if(new_disp_state & F1_FLAG) {
    ul_str2video(F1_X,F1_Y,main_attr,f1_str,0);
    }
  else {
    ul_str2video(F1_X,F1_Y,main_attr,f1_strx,0);
    }
  if(new_disp_state & F2_FLAG) {
    ul_str2video(F2_X,F2_Y,main_attr,f2_str,0);
    }
  else {
    ul_str2video(F2_X,F2_Y,main_attr,f2_strx,0);
    }
  if(new_disp_state & F3_FLAG) {
    ul_str2video(F3_X,F3_Y,main_attr,f3_str,0);
    }
  else {
    ul_str2video(F3_X,F3_Y,main_attr,f3_strx,0);
    }
  if(new_disp_state & F4_FLAG) {
    ul_str2video(F4_X,F4_Y,main_attr,f4_str,0);
    }
  else {
    ul_str2video(F4_X,F4_Y,main_attr,f4_strx,0);
    }
  if(new_disp_state & F5_FLAG) {
    ul_str2video(F5_X,F5_Y,main_attr,f5_str,0);
    }
  else {
    ul_str2video(F5_X,F5_Y,main_attr,f5_strx,0);
    }
  if(new_disp_state & F6_FLAG) {
    ul_str2video(F6_X,F6_Y,main_attr,f6_str,0);
    }
  else {
    ul_str2video(F6_X,F6_Y,main_attr,f6_strx,0);
    }
  if(new_disp_state & F7_FLAG) {
    ul_str2video(F7_X,F7_Y,main_attr,f7_str,0);
    }
  else {
    ul_str2video(F7_X,F7_Y,main_attr,f7_strx,0);
    }
  if(new_disp_state & F9_FLAG) {
    ul_str2video(F9_X,F9_Y,main_attr,f9_str,0);
    }
  else {
    ul_str2video(F9_X,F9_Y,main_attr,f9_strx,0);
    }
  if(new_disp_state & F10_FLAG) {
    ul_str2video(F10_X,F10_Y,main_attr,f10_str,0);
    }
  else {
    ul_str2video(F10_X,F10_Y,main_attr,f10_strx,0);
    }
  cmd_disp_state = new_disp_state;
  }

/*======================================================================
;,fs
; byte read_sector(byte drv, byte head, byte sect, byte cyld, byte *bufofs)
; 
; read a sector
;
; in:	drv = the hard drive number (0x80, 0x81)
;	head = the int13 head number
;	sect = the int13 sector number
;	cyld = the int13 cylinder number
;	addr = the _DS based offset of the sector buffer
;
; out:	none
;	
;,fe
========================================================================*/
byte read_sector(byte drv, byte head, byte sect, byte cyld, byte *bufofs) {

  byte retries;

  retries = 3;
  while(1) {
    regs.x.ax = 0x0201;			/* read 1 sector */
    regs.h.cl = sect;
    regs.h.ch = cyld;
    regs.h.dl = drv;
    regs.h.dh = head;
    regs.x.bx = (word)bufofs;
    sregs.es = _DS;
    int86x(0x13,&regs,&regs,&sregs);
    if(!regs.x.cflag) {
      return(0);
      }
    else {
      retries--;
      if(retries == 0) {
        return(1);
        }
      regs.x.ax = 0;
      int86x(0x13,&regs,&regs,&sregs);	/* reset drive */
      }
    }
  }

/*======================================================================
;,fs
; byte write_sector(byte drv, byte head, byte sect, byte cyld, byte *bufofs)
; 
; write a sector
;
; in:	drv = the hard drive number (0x80, 0x81)
;	sect = the int13 sector number
;	cyld = the int13 cylinder number
;	addr = the _DS based offset of the sector buffer
;
; out:	none
;	
;,fe
========================================================================*/
byte write_sector(byte drv, byte head, byte sect, byte cyld, byte *bufofs) {

  byte retries;


  retries = 3;
  while(1) {
    regs.x.ax = 0x0301;			/* read 1 sector */
    regs.h.cl = sect;
    regs.h.ch = cyld;
    regs.h.dl = drv;
    regs.h.dh = head;
    regs.x.bx = (word)bufofs;
    sregs.es = _DS;
    int86x(0x13,&regs,&regs,&sregs);
    if(!regs.x.cflag) {
      return(0);
      }
    else {
      retries--;
      if(retries == 0) {
        return(1);
        }
      regs.x.ax = 0;
      int86x(0x13,&regs,&regs,&sregs);	/* reset drive */
      }
    }
  }

/*======================================================================
;,fs
; void set_pe_data(pr_type *pr, byte p_ndx, word begsect, word begcyld, word endsect, word endcyld)
; 
; convert word values for starting and ending cylinders and sectors
; to the compressed format for partition entries (e.g. where bits 8 and 9
; of the cylinder number are tucked into bits 6 and 7 of the sector
; number).
;
; note: the calculations done here involve intentional truncation 
; from word to byte
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void set_pe_data(pr_type *pr, byte p_ndx, word begsect, word begcyld, word endsect, word endcyld) {

  pr->prE[p_ndx].PT.peBeginSector = begsect + (word)((begcyld & 0x0300) >> 2);
  pr->prE[p_ndx].PT.peBeginCylinder = begcyld;
  pr->prE[p_ndx].PT.peEndSector = endsect + (word)((endcyld & 0x0300) >> 2);
  pr->prE[p_ndx].PT.peEndCylinder = endcyld;
  }

/*======================================================================
;,fs
; void get_pe_data(pr_type *pr, byte p_ndx, word *begsect, word *begcyld, word *endsect, word *endcyld)
;
; convert the partition entry values for starting and ending cylinders
; and sectors from their compressed format to normalized word values.
;
; in:	pr -> pr_type record
;	p_ndx = partition table index
;	begsect -> word to receive beginning sector #
;	begcyld -> word to receive beginning cylinder #
;	endsect -> word to receive ending sector #
;	endcyld -> word to receive ending cylinder #
;
; out:	*begsect = beginning sector #
;	*begcyld = beginning cylinder #
;	*endsect = ending sector #
;	*endcyld = ending cylinder #
;
;,fe
========================================================================*/
void get_pe_data(pr_type *pr, byte p_ndx, word *begsect, word *begcyld, word *endsect, word *endcyld) {

  *begsect = pr->prE[p_ndx].PT.peBeginSector & 0x3f;
  *begcyld = pr->prE[p_ndx].PT.peBeginCylinder + 
  ((pr->prE[p_ndx].PT.peBeginSector & 0xc0) << 2);
  *endsect = pr->prE[p_ndx].PT.peEndSector & 0x3f;
  *endcyld = pr->prE[p_ndx].PT.peEndCylinder + 
  ((pr->prE[p_ndx].PT.peEndSector & 0xc0) << 2);
  }

/*======================================================================
;,fs
; word cylds2megs(dr_type *dr, word cylds)
;
; megs = (bps * spt * heads * cylds) / (1024 * 1024)
; (the bps of 512 cancels with part of the denominator)
;
; note: any partial amount of cylinders are truncated by the integer
; division and ignored.  therefore, 10.000 megs will be displayed as 10
; as will an actual value of 10.999 megs.  
; 
; the one exception to this convention is when the calculation produces
; a value less than 1.  in this case, the return value of megs is
; rounded up to 1.  this is because entering a megs value of 0 must
; always mean to delete the partition.
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
word cylds2megs(dr_type *dr, word cylds) {

  dword d1;
  word megs;

  d1.li = dr->drSPT;
  d1.li *= dr->drHeads;		/* calc sectors per cylinder */
  d1.li *= cylds;		/* calc total sectors */
  megs = d1.li / 2048;		/* megs = total sectors / sectors per meg */
  if(megs == 0) {
    megs = 1;
    }
  return(megs);
  }

/*======================================================================
;,fs
; word megs2cylds(dr_type *dr, word megs, word max_cylds)
;
; this function calculates and returns the maximum number of cylinders 
; which produces a megs value equal to or less than the supplied value.
; 
; the max_cylds value is used as a limiting factor.  max_cylds is the
; maximum number of cylinders which are available.  if all of them can
; be used and not be over the megs value, then that max cylinder value
; is returned.
; 
; quirk: if (heads * spt) > 2048, the drive has more than 1M per
; cylinder in this case, there will be certain meg values which won't
; correspond directly to a certain number of cylinders.
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
word megs2cylds(dr_type *dr, word megs, word max_cylds) {

  dword d1;
  dword d2;


  if(megs == 0) return(0);

  /* calc # of cylinders (with truncating integer division) for the
  next higher megs value */

  d1.li = megs + 1;
  d1.li *= 2048;
  d2.li = dr->drHeads;
  d2.li *= dr->drSPT;
  d1.li /= d2.li;

  /* due to the truncation of integer division, the current value of
  d1 may be the highest number of cylinders which will fit into the
  megs value.  in some cases, it will be necessary to decrement this
  value by 1. */

  if(cylds2megs(dr,d1.h[0]) != megs) {
    d1.h[0]--;
    }

  /* limit the return value by the maximum # of available cylinders. */

  if(d1.h[0] > max_cylds) {
    return(max_cylds);
    }
  else {
    return(d1.h[0]);
    }
  }

/*======================================================================
;,fs
; byte derive_PTC(dr_type *dr, word cylds)
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
byte derive_PTC(dr_type *dr, word cylds) {

  dword d1;
  word bpk_data_sct;
  word bpk_clusters;

  d1.li = dr->drSPT;
  d1.li *= dr->drHeads;		/* calc sectors per cylinder */
  d1.li *= cylds;		/* calc total sectors */
  if(d1.h[1]) return(PTCdlg);

  /* ballpark data sectors = total sectors - directory sectors (32) -
  boot sector (1).  ballpark clusters = ballpark data sectors / spc.
  presuming an spc of 8 for the case where this is a partition which
  needs a 12 bit fat.  if this results in a cluster count above
  the limit for a 12 bit fat, use a 16 bit fat. */

  bpk_data_sct = d1.h[0] - 33;	
  bpk_clusters = bpk_data_sct / 8;
  if(bpk_clusters > (4096-10)) return(PTCsm16);
  return(PTCsm12);
  }

/*======================================================================
;,fs
; word derive_maxsml(dr_type *dr)
;
; derive the maximum # of cylinders for a partition which will
; still produce a SML type partition.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
word derive_maxsml(dr_type *dr) {

  dword d1;
  dword d2;

  d1.li = dr->drSPT;
  d1.li *= dr->drHeads;		/* calc sectors per cylinder */
  d2.li = 0xffffl;
  return(d2.li / d1.li);
  }

/*======================================================================
;,fs
; byte build_tree(void)
; 
; read and record the partition table sectors 
;
; in:	
;
; out:	retval != 0 if error, else == 0
;	this function reports its own errors
;	
;,fe
========================================================================*/
byte build_tree(void) {

  dword xptr;
  byte machid;
  pr_type *pr;
  pr_type *pr_prev;
  dp_type device_parms;
  dr_type *dr;
  byte dv_num;
  word e_head;
  word e_sect;
  word e_cyld;
  bt_type *btptr;
  pe_type *peptr;
  byte table_num;
  word temp_cylds;
  word temp_heads;
  word temp_spt;

  hard_drives = 0;
  SETDWORD(xptr,0xf000,0xfffe);
  machid = *xptr.bptr;
  if(machid == 0xfc || machid == 0xf8 || machid == 0xfa) {
    regs.h.ah = 8;
    regs.h.dl = 0x80;			/* first hard drive */
    int86x(0x13,&regs,&regs,&sregs);
    if((regs.x.flags & 1) == 0)	/* if carry not set */ {
      hard_drives = regs.h.dl;
      if(hard_drives > 2)		/* not setup for > 2 */ {
        hard_drives = 2;
        }
      temp_cylds = regs.h.cl & 0xc0;
      temp_cylds = temp_cylds << 2;
      temp_cylds += regs.h.ch + 1;
      temp_heads = regs.h.dh + 1;
      temp_spt = regs.h.cl & 0x3f;
      }
    }
  else {

    /* not on an at, use extended i/o crtl call to get device info. 
    note: the # of cylinders returned by this call is only for the current
    partition whereas the value returned from i13f08 is for the entire drive.
    also, this call doesn't work with dos before version 3.3. */

    regs.x.ax = 0x440d;
    regs.h.bl = 3;			/* 3 for first hard disk */
    regs.x.cx = 0x0860;
    regs.x.dx = (word)&device_parms;
    sregs.ds = _DS;
    int86x(0x21,&regs,&regs,&sregs);
    if((regs.x.flags & 1) == 0)	/* if carry not set */ {
      hard_drives = 1;
      temp_cylds = device_parms.dpCylinders;
      temp_heads = device_parms.dpHeads;
      temp_spt = 0x17;
      }
    }
  if(hard_drives == 0) {
    return(0);
    }

  /* allocate and init a dr_type record for the first hard drive */

  if((dr = (dr_type *) malloc(sizeof(dr_type))) == NULL) {
    report_error(errcode_insuficmem);
    exit(1);
    }
  Root_dr = dr;
  dr->drNext = NULL;
  dr->drPR = NULL;
  dr->drHeads = temp_heads;
  dr->drSPT = temp_spt;
  dr->drCylds = temp_cylds;
  dr->drDriveNum = 0;

  /* allocate and init a dr_type record for the second hard drive */

  if(hard_drives == 2) {
    if((dr = (dr_type *) malloc(sizeof(dr_type))) == NULL) {
      report_error(errcode_insuficmem);
      return(1);
      }
    Root_dr->drNext = dr;
    dr->drNext = NULL;
    dr->drPR = NULL;

    /*  read data for second drive.
    can use int13 since don't recog > 1 drive on a non-at machine. */

    regs.h.ah = 8;
    regs.h.dl = 0x81;			/* second hard drive */
    int86x(0x13,&regs,&regs,&sregs);

    if(regs.x.flags & 1) {
      report_error(errcode_diskread);
      return(1);
      }
    dr->drCylds = regs.h.cl & 0xc0;
    dr->drCylds = dr->drCylds<< 2;
    dr->drCylds += regs.h.ch + 1;
    dr->drHeads = regs.h.dh + 1;
    dr->drSPT = regs.h.cl & 0x3f;
    dr->drDriveNum = 1;
    }

  /* for each drive, check for existing partition tables */

  dv_num = 0x80;
  dr = Root_dr;
  while(dr != NULL) {
    table_num = 0;

    /* allocate and link in the first pr_type record */

    if((pr = (pr_type *) malloc(sizeof(pr_type))) == NULL) {
      report_error(errcode_insuficmem);
      return(1);
      }
    dr->drPR = pr;

    /* init its fields to null, just in case there is no partition info */

    pr->prExt = 0;
    pr->prTblNum = table_num++;
    for(t1=0;t1<4;t1++) {
      memset(&(pr->prE[t1].PT),0,16);
      pr->prE[t1].MLG = 0;
      pr->prE[t1].NeedMSYS = 0;
      pr->prE[t1].ExtPR = NULL;
      }

    /* check for a master partition table at h0, s1, c0  */

    if(read_sector(dv_num,0,1,0,sct_buf) != 0) {
      report_error(errcode_diskread);
      return(1);
      }
    if(sct_buf[510] == 0x55 && sct_buf[511] == 0xaa) {
      for(t1=0;t1<4;t1++) {
        memcpy(&(pr->prE[t1].PT),(sct_buf+0x1be+(t1*16)),16);

        /* when the ptc is 4, must check for MLG by reading the pbr,
        verifying it and seeing if the high byte of the btFATsecs field
        is non-zero. */

        if(pr->prE[t1].PT.peFileSystem == PTCsm16) {
          if(read_sector(dv_num,pr->prE[t1].PT.peBeginHead,pr->prE[t1].PT.peBeginSector,pr->prE[t1].PT.peBeginCylinder,sct_buf2) != 0) {
            report_error(errcode_diskread);
            return(1);
            }
          if(sct_buf2[510] == 0x55 && sct_buf2[511] == 0xaa) {
            (word)btptr = (word)&sct_buf2;
            if(btptr->btFATsecs > 255) {
              pr->prE[t1].MLG = 1;
              }
            }
          }
        }

      /* check for an extended partition */

      t2 = 0xff;
      for(t1=0;t1<4;t1++) {
        if(pr->prE[t1].PT.peFileSystem == PTCext) {
          e_head = pr->prE[t1].PT.peBeginHead;
          e_sect = pr->prE[t1].PT.peBeginSector;
          e_cyld = pr->prE[t1].PT.peBeginCylinder;
          t2 = t1;
          break;
          }
        }

      /* trace the extended chain, allocating and filling out a pr_type
      record for each partition sector. */

      (word)peptr = (word)&sct_buf + 0x1be;
      pr_prev = NULL;			/* used as a signal below */
      while(t2 != 0xff) {

        /* to accommodate fdisk's method of deleteing a volume within
        its extended partition, must read each sector in the chain and
        first test to see if it is 'live' -- if its first pte has a
        ptc other than 0. */

        if(read_sector(dv_num,e_head,e_sect,e_cyld,sct_buf) != 0) {
          report_error(errcode_diskread);
          return(1);
          }
        if(peptr->peFileSystem != PTCnil) {
          pr_prev = pr;
          if((pr = (pr_type *) malloc(sizeof(pr_type))) == NULL) {
            report_error(errcode_insuficmem);
            return(1);
            }
          pr_prev->prE[t2].ExtPR = pr;
          pr->prExt = 1;
          pr->prTblNum = table_num++;
          pr->prE[0].MLG = 0;
          pr->prE[1].MLG = 0;
          pr->prE[2].MLG = 0;
          pr->prE[3].MLG = 0;
          memcpy(&(pr->prE[0].PT),(sct_buf+0x1be),16);
          memcpy(&(pr->prE[1].PT),(sct_buf+0x1be+16),16);
          pr->prE[2].PT.peFileSystem = 0;
          pr->prE[3].PT.peFileSystem = 0;
          pr->prE[1].ExtPR = NULL;
          }
        t2 = 1;
        if((peptr+1)->peFileSystem == PTCext) {
          e_head = (peptr+1)->peBeginHead;
          e_sect = (peptr+1)->peBeginSector;
          e_cyld = (peptr+1)->peBeginCylinder;
          }
        else {
          t2 = 0xff;
          }
        }

      /* if no 'live' extended partitions were found, must clear the 
      pte within the mbr. */

      if(t1 != 4 && pr_prev == NULL) {
        pr->prE[t1].PT.peFileSystem = PTCnil;
        }
      }
    dv_num++;
    dr = dr->drNext;
    }
  return(0);
  }

/*======================================================================
;,fs
; byte trace_tree(byte (*work_func)(dr_type *dr, pr_type *pr, byte pnum), 
;	sdr_type *strt_dr)
;
; template for a work function for use with trace_tree()
;
;   byte work_func(dr_type *dr, pr_type *pr, byte pnum)
;
; a work function called by trace_tree() is passed pointers to the
; drive node and partition node and the index number for the prE[] 
; array.  normally, a work function should return with a 0 value to let
; the tracing continue.  if a work function detects an error, it can
; return a non-zero value to cause trace_tree() to stop tracing.  the
; return value from trace_tree() will then be non-zero.
;
; in:	work_func -> the function to be called as the tree is traced
;	sdr_ptr == NULL if all hard drives should be processed
;	sdr_ptr != NULL means only process the hard drive corresponding
;		   to the record which strt_dr points to
;	uses the following global data:
;	 Root_dr
;
; out:	none
;	
;,fe
========================================================================*/
byte trace_tree(byte (*work_func)(dr_type *dr, pr_type *pr, byte pnum), dr_type *sdr_ptr) {

  byte x;
  byte retval;
  pr_type *er_ptr;
  dr_type *dr_ptr;
  byte pval;


  /* for each hard drive to be processed, call the work function with 
  the first partition in the master boot record.  */

  if(sdr_ptr == NULL) {
    dr_ptr = Root_dr;
    }
  else {
    dr_ptr = sdr_ptr;
    }
  while(dr_ptr != NULL) {
    if(dr_ptr->drPR->prE[0].PT.peFileSystem != PTCnil) {
      if((retval = (work_func)(dr_ptr,dr_ptr->drPR,0)) != 0) {
        return(retval);
        }
      }
    if(sdr_ptr == NULL) {
      dr_ptr = dr_ptr->drNext;
      }
    else {
      dr_ptr = NULL;
      }
    }

  /* on the next pass, for each hard drive to be processed, look for 
  extended paritions, tracing down each chain.  presumes the extended 
  partition chain has a valid format (e.g. PT entry 0 points to the PBR) */

  if(sdr_ptr == NULL) {
    dr_ptr = Root_dr;
    }
  else {
    dr_ptr = sdr_ptr;
    }
  while(dr_ptr != NULL) {
    for(x=1;x<4;x++) {
      if(dr_ptr->drPR->prE[x].PT.peFileSystem == PTCext) {
        er_ptr = dr_ptr->drPR->prE[x].ExtPR;
        while(er_ptr != NULL) {
          if((retval = (work_func)(dr_ptr,er_ptr,0)) != 0) {
            return(retval);
            }
          er_ptr = er_ptr->prE[1].ExtPR;
          }
        }
      }
    if(sdr_ptr == NULL) {
      dr_ptr = dr_ptr->drNext;
      }
    else {
      dr_ptr = NULL;
      }
    }

  /* now go back and trace secondary partitions made by mos
  as well as foreign partitions -- basically any partition entry where
  the PTC isn't 0 or 5. */

  if(sdr_ptr == NULL) {
    dr_ptr = Root_dr;
    }
  else {
    dr_ptr = sdr_ptr;
    }
  while(dr_ptr != NULL) {
    for(x=1;x<4;x++) {
      pval = dr_ptr->drPR->prE[x].PT.peFileSystem;
      if(pval != PTCext && pval != PTCnil) {
        if((retval = (work_func)(dr_ptr,dr_ptr->drPR,x)) != 0) {
          return(retval);
          }
        }
      }
    if(sdr_ptr == NULL) {
      dr_ptr = dr_ptr->drNext;
      }
    else {
      dr_ptr = NULL;
      }
    }
  return(0);
  }

/*======================================================================
;,fs
; byte drvltrs_work(dr_type *dr, pr_type *pr, byte p_ndx)
;
; this function is designed to be a work function for trace_tree().
; it is used to assign drive letters to the pr_type records.
;
; if the dup_drvltr flag is set, the origdriveletter field is also
; set.
;
; in:	dr -> the dr_type record
;	pr -> the pr_type record
;	p_ndx = the index to the prE[] array
;	uses the following global data:
;	 assign_letter
;
;   global:	dup_drvltr
;
; out:	retval = 0 to continue tracing, != 0 to stop
;	assign_letter will hold the next available letter.
;	
;,fe
========================================================================*/
byte drvltrs_work(dr_type *dr, pr_type *pr, byte p_ndx) {

  byte pval;

  if(p_ndx > 3) return(0);		/* ignore gap records */
  pr->prE[p_ndx].DriveLetter = '-';	// in case its OTH
  pval = pr->prE[p_ndx].PT.peFileSystem;
  if(pval == PTCsm12 || pval == PTCsm16 || pval == PTCdlg) {
    if(assign_letter == 'Z' + 1) {
      return(1);
      }
    pr->prE[p_ndx].DriveLetter = assign_letter;
    if(dup_drvltr) {
      pr->prE[p_ndx].OrigDriveLetter = assign_letter;
      }
    assign_letter++;
    }
  return(0);
  }

/*======================================================================
;,fs
; byte insert_lr_node(lr_type *lr)
;
; in:	
;
; out:	
;	
;,fe
========================================================================*/
byte insert_lr_node(lr_type *lr) {

  lr_type *lr_scan;
  lr_type *lr_last;


  if(Root_lr == NULL) {
    Root_lr = lr;
    BRoot_lr = lr;
    lr->lrPrev = NULL;
    lr->lrNext = NULL;
    }
  else {
    if(lr->lrStart < Root_lr->lrStart) {
      lr->lrPrev = NULL;
      Root_lr->lrPrev = lr;
      lr->lrNext = Root_lr;
      Root_lr = lr;
      }
    else {
      lr_last = NULL;
      lr_scan = Root_lr;
      while(lr_scan != NULL) {
        if(lr->lrStart < lr_scan->lrStart) {
          lr->lrNext = lr_scan;
          lr->lrPrev = lr_last;
          lr_scan->lrPrev = lr;
          lr_last->lrNext = lr;
          break;
          }
        lr_last = lr_scan;
        lr_scan = lr_scan->lrNext;
        }
      if(lr_scan == NULL) {
        lr_last->lrNext = lr;
        lr->lrPrev = lr_last;
        lr->lrNext = NULL;
        BRoot_lr = lr;
        }
      }
    }
  return(0);
  }

/*======================================================================
;,fs
; word derive_cyld_data(pr_type *pr, byte p_ndx, word *strtc, word *endc)
;
; in:	pr -> the pr_type record
;	p_ndx = the index to the prE[] array
;	strtc -> word to receive starting cylinder #
;	endc -> word to receive ending cylinder #
;
; out:	retval = # of cylinders for the partition
;	*strtc = starting cylinder
;	*endc = ending cylinder
;
;,fe
========================================================================*/
word derive_cyld_data(pr_type *pr, byte p_ndx, word *strtc, word *endc) {

  word junk1;
  word junk2;

  get_pe_data(pr,p_ndx,&junk1,strtc,&junk2,endc);
  return(*endc - *strtc + 1);
  }

/*======================================================================
;,fs
; word derive_cylds(pr_type *pr, byte p_ndx)
;
; in:	pr -> the pr_type record
;	p_ndx = the index to the prE[] array
;
; out:	retval = # of cylinders for the partition
;	
;,fe
========================================================================*/
word derive_cylds(pr_type *pr, byte p_ndx) {

  word junk1;
  word junk2;

  return(derive_cyld_data(pr,p_ndx,&junk1,&junk2));
  }

/*======================================================================
;,fs
; byte gen_lr_list_work(dr_type *dr, pr_type *pr, byte p_ndx)
;
; this function is designed to be a work function for trace_tree().
; it is used to generate the initial list of lr_type records
;
; in:	dr -> the dr_type record
;	pr -> the pr_type record
;	p_ndx = the index to the prE[] array
;	uses the following global data:
;	 Root_lr
;
; out:	retval = 0 to continue tracing, != 0 to stop
;	
;,fe
========================================================================*/
byte gen_lr_list_work(dr_type *dr, pr_type *pr, byte p_ndx) {

  lr_type *lr;


  if((lr = (lr_type *) malloc(sizeof(lr_type))) == NULL) {
    return(1);
    }
  lr->lrHomeNode = pr;
  lr->lrHomeNdx = p_ndx;
  lr->lrCylds = derive_cyld_data(pr,p_ndx,&(lr->lrStart),&(lr->lrEnd));
  lr->lrMegs = cylds2megs(dr,lr->lrCylds);
  return(insert_lr_node(lr));
  }

/*======================================================================
;,fs
; byte *get_dash_msg(pr_type *pr, byte p_ndx)
;
; in:	
;
; out:	
;	
;,fe
========================================================================*/
byte *get_dash_msg(pr_type *pr, byte p_ndx) {

  byte pval;

  pval = pr->prE[p_ndx].PT.peFileSystem;
  if(pr->prExt) {
    return(dashe_msg);
    }
  else {
    if(pval == PTCsm12 || pval == PTCsm16 || pval == PTCdlg) {
      if(p_ndx != 0) {
        return(dashs_msg);
        }
      else {
        return(dashp_msg);
        }
      }
    }
  return(dasho_msg);
  }

/*======================================================================
;,fs
; byte gen_summary_work(dr_type *dr, pr_type *pr, byte p_ndx)
;
; this function is designed to be a work function for trace_tree().
; it is used to generate the partition summary report (hdsetup /s)
;
; in:	dr -> the dr_type record
;	pr -> the pr_type record
;	p_ndx = the index to the prE[] array
;	uses the following global data:
;	 Root_lr
;
; out:	retval = 0 to continue tracing, != 0 to stop
;	
;,fe
========================================================================*/
byte gen_summary_work(dr_type *dr, pr_type *pr, byte p_ndx) {

  byte pttype[6];
  word megs;
  word cylds;
  byte febpb;
  word strtc;
  word endc;
  byte bootstat;


  if(pr->prE[p_ndx].MLG) {
    strcpy(pttype,mlg_msg);
    }
  else {
    switch(pr->prE[p_ndx].PT.peFileSystem) {
    case PTCsm12:
    case PTCsm16:
      strcpy(pttype,sml_msg);
      break;

    case PTCdlg:
      strcpy(pttype,dlg_msg);
      break;

    default:
      strcpy(pttype,oth_msg);
      }
    }
  strcat(pttype,get_dash_msg(pr,p_ndx));
  cylds = derive_cyld_data(pr,p_ndx,&strtc,&endc);
  megs = cylds2megs(dr,cylds);

  bootstat = 'x';
  if(dr->drDriveNum == 0) {
    if(pr->prExt == 0) {
      bootstat = (pr->prE[p_ndx].PT.peBootable ? 'Y':'N');
      }
    }

  febpb = 'N';			//!!!!!!!!!!!!

  fprintf(sum_file,SUMMARY_WMASK,
  dr->drDriveNum,
  pr->prTblNum,
  p_ndx,
  pttype,
  pr->prE[p_ndx].DriveLetter,
  bootstat,
  megs,
  cylds,
  strtc,
  endc,
  febpb
  );
  return(0);
  }

/*======================================================================
;,fs
; byte gen_gaps(dr_type *dr)
;
; a gap record in the lr_type list is identified by the lrHomeNode
; being NULL.  In addition, the lrHomeNdx field holds 0 if the
; gap is not adjacent to any extended partition, 1 if adjacent and
; 2 if it is between extended partitions.
;
; in:	
;
; out:	retval = 1 means insufficient memory
;	retval = 2 means improper cylinder numbering
;	
;,fe
========================================================================*/
byte gen_gaps(dr_type *dr) {

  lr_type *lr1;
  lr_type *lr2;
  word last_end;
  word diff_cylds;
  byte hit;
  byte first_pass;


  /* check for the one-big-gap case */

  if(Root_lr == NULL) {
    if((lr1 = (lr_type *) malloc(sizeof(lr_type))) == NULL) {
      return(1);
      }
    lr1->lrHomeNode = NULL;		/* indicate a gap */
    lr1->lrHomeNdx = 0;
    lr1->lrCylds = dr->drCylds;
    lr1->lrStart = 0;
    lr1->lrMegs = cylds2megs(dr,lr1->lrCylds);
    lr1->lrEnd = dr->drCylds - 1;
    if(insert_lr_node(lr1)) return(2);
    return(0);
    }

  /* step through the list looking for gaps */

  while(1) {
    lr1 = Root_lr;
    last_end = 0;
    first_pass = 1;
    hit = 0;
    while(lr1 != NULL) {
      diff_cylds = lr1->lrStart - last_end;
      if(!first_pass) {
        diff_cylds--;
        }
      if(diff_cylds > 0) {
        lr2 = lr1;
        if((lr1 = (lr_type *) malloc(sizeof(lr_type))) == NULL) {
          return(1);
          }
        lr1->lrHomeNode = NULL;		/* indicate a gap */
        lr1->lrHomeNdx = 0;
        if(!first_pass) {
          if(lr2->lrHomeNode->prExt) {
            lr1->lrHomeNdx = 1;
            if(lr2->lrPrev->lrHomeNode->prExt) {
              lr1->lrHomeNdx = 2;
              }
            }
          else {
            if(lr2->lrPrev->lrHomeNode->prExt) {
              lr1->lrHomeNdx = 1;
              }
            }
          }
        lr1->lrCylds = diff_cylds;
        lr1->lrStart = last_end;
        lr1->lrMegs = cylds2megs(dr,lr1->lrCylds);
        if(!first_pass) {
          lr1->lrStart += 1;
          }
        lr1->lrEnd = lr1->lrStart + diff_cylds - 1;
        if(insert_lr_node(lr1)) return(2);
        hit = 1;
        break;
        }
      last_end = lr1->lrEnd; 
      first_pass = 0;
      lr1 = lr1->lrNext;
      }
    if(hit == 0) break;
    }

  /* check for a gap at the end */

  if(BRoot_lr->lrEnd < (dr->drCylds - 1)) {
    diff_cylds = dr->drCylds - BRoot_lr->lrEnd - 1;
    if((lr1 = (lr_type *) malloc(sizeof(lr_type))) == NULL) {
      return(1);
      }
    lr1->lrHomeNode = NULL;		/* indicate a gap */
    lr1->lrHomeNdx = 0;
    if(BRoot_lr->lrHomeNode->prExt) {
      lr1->lrHomeNdx = 1;
      }
    lr1->lrCylds = diff_cylds;
    lr1->lrStart = BRoot_lr->lrEnd + 1;
    lr1->lrEnd = lr1->lrStart + diff_cylds - 1;
    lr1->lrMegs = cylds2megs(dr,lr1->lrCylds);
    if(insert_lr_node(lr1)) return(2);
    }
  return(0);
  }

/*======================================================================
;,fs
; void display_lr_data(lr_type *lr, byte list_count)
;
; in:	
;
; out:	
;	
;,fe
========================================================================*/
void display_lr_data(lr_type *lr, byte list_count) {

  byte tchar;
  byte tchar2;
  byte *tptr;
  byte pval;
  pr_type *pr;
  byte p_ndx;
  byte y;
  byte type_str[6];

  y = LIST_TOP + list_count;
  pr = lr->lrHomeNode;
  p_ndx = lr->lrHomeNdx;
  if(pr == NULL)			/* if a gap */ {
    ul_str2video(L_DRV_COL,y,main_attr,unalloc_msg,0);
    ul_display_decimal(lr->lrMegs,L_MEGS_COL,y,main_attr,L_MEGS_WIDTH);
    ul_display_decimal(lr->lrCylds,L_CYLDS_COL,y,main_attr,L_CYLDS_WIDTH);
    ul_display_decimal(lr->lrStart,L_START_COL,y,main_attr,L_START_WIDTH);
    ul_display_decimal(lr->lrEnd,L_END_COL,y,main_attr,L_END_WIDTH);
    }
  else {

    /* display drive letter */

    if(pr->prE[p_ndx].DriveLetter) {
      ul_char2video(L_DRV_COL,y,main_attr,pr->prE[p_ndx].DriveLetter);
      ul_char2video(L_DRV_COL+1,y,main_attr,':');
      }
    else {
      ul_char2video(L_DRV_COL,y,main_attr,'-');
      ul_char2video(L_DRV_COL+1,y,main_attr,'-');
      }

    /* display bootable indicator */

    tchar2 = ' ';
    if(pr->prExt || drive_num != 0) {
      tchar = 'x';
      }
    else {
      if(pr->prE[p_ndx].PT.peBootable) {
        tchar = yes_char;
        tchar2 = p_ndx + '1';
        }
      else {
        tchar = no_char;
        }
      }
    ul_char2video(L_BOOT_COL,y,main_attr,tchar);
    ul_char2video(L_BOOT_COL+2,y,main_attr,tchar2);

    /* display partition type */

    pval = pr->prE[p_ndx].PT.peFileSystem;
    if(pr->prE[p_ndx].MLG) {
      strcpy(type_str,mlg_msg);
      }
    else if(pval == PTCsm12 || pval == PTCsm16) {
      strcpy(type_str,sml_msg);
      }
    else if(pval == PTCdlg) {
      strcpy(type_str,dlg_msg);
      }
    else {
      strcpy(type_str,oth_msg);
      }
    strcat(type_str,get_dash_msg(pr,p_ndx));
    ul_str2video(L_TYPE_COL,y,main_attr,type_str,0);
    /* display megs, cylds, start, end */

    ul_display_decimal(lr->lrMegs,L_MEGS_COL,y,main_attr,L_MEGS_WIDTH);
    ul_display_decimal(lr->lrCylds,L_CYLDS_COL,y,main_attr,L_CYLDS_WIDTH);
    ul_display_decimal(lr->lrStart,L_START_COL,y,main_attr,L_START_WIDTH);
    ul_display_decimal(lr->lrEnd,L_END_COL,y,main_attr,L_END_WIDTH);
    }
  list_count++;
  }

/*======================================================================
;,fs
; void update_more(void)
;
; in:	
;
; out:	
;	
;,fe
========================================================================*/
void update_more(void) {

  if(top_lr == Root_lr) {
    ul_char2video(MORE_X,MORE_Y1,main_attr,' ');
    }
  else {
    ul_char2video(MORE_X,MORE_Y1,main_attr,24);	// up arrow
    }
  if(bot_lr == BRoot_lr) {
    ul_char2video(MORE_X,MORE_Y2,main_attr,' ');
    }
  else {
    ul_char2video(MORE_X,MORE_Y2,main_attr,25);	// down arrow
    }
  }

/*======================================================================
;,fs
; void do_uparrow(void)
;
; in:	
;
; out:	
;	
;,fe
========================================================================*/
void do_uparrow(void) {

  ul_set_attr(LIST_XL,LIST_TOP+edit_line,LIST_XR,main_attr);
  if(edit_lr == top_lr) {
    if(top_lr == Root_lr) {
      ul_beep();
      return;
      }
    else {
      edit_lr = edit_lr->lrPrev;
      top_lr = top_lr->lrPrev;
      bot_lr = bot_lr->lrPrev;
      ul_scroll_lines_down(LIST_XL,LIST_TOP,LIST_XR,(LIST_TOP+LIST_LINES-1),main_attr);
      display_lr_data(top_lr,0);
      }
    }
  else {
    edit_lr = edit_lr->lrPrev;
    edit_line--;
    }
  edit_pr = edit_lr->lrHomeNode;
  edit_pndx = edit_lr->lrHomeNdx;
  }

/*======================================================================
;,fs
; void do_downarrow(void)
;
; in:	
;
; out:	
;	
;,fe
========================================================================*/
void do_downarrow(void) {


  ul_set_attr(LIST_XL,LIST_TOP+edit_line,LIST_XR,main_attr);
  if(edit_lr == bot_lr) {
    if(bot_lr == BRoot_lr) {
      ul_beep();
      return;
      }
    else {
      edit_lr = edit_lr->lrNext;
      top_lr = top_lr->lrNext;
      bot_lr = bot_lr->lrNext;
      ul_scroll_lines_up(LIST_XL,LIST_TOP,LIST_XR,(LIST_TOP+LIST_LINES-1),main_attr);
      display_lr_data(bot_lr,LIST_LINES-1);
      }
    }
  else {
    edit_lr = edit_lr->lrNext;
    edit_line++;
    }
  edit_pr = edit_lr->lrHomeNode;
  edit_pndx = edit_lr->lrHomeNdx;
  }

/*======================================================================
;,fs
; byte qualify_method(lr_type *lr, byte method)
;
; in:	
;	 
; out:	
;
;,fe
========================================================================*/
byte qualify_method(lr_type *lr, byte method) {

  byte ok;

  /* qualify the gap based on the specified method */

  ok = 0;
  if(method == FIND_SEC) {
    if(lr->lrHomeNdx == 0 || lr->lrHomeNdx == 1) {
      ok = 1;
      }
    }
  else {
    if(method == FIND_EXT) {
      if(lr->lrHomeNdx == 1 || lr->lrHomeNdx == 2) {
        ok = 1;
        }
      }
    else {
      ok = 1;				/* must be FIND_PRI */
      }
    }
  return(ok);
  }

/*======================================================================
;,fs
; lr_type *find_largest_gap(byte method)
;
; find the gap record within the lr_type list which has the largest 
; number of cylinders - qualified by the specified method:
; FIND_PRI, FIND_SEC or FIND_EXT.
; 
; in:	uses the following global data:
;	 Root_lr
;	 
; out:	retval == NULL if no gaps
;	else retval -> the corresponding lr_type record
;
;,fe
========================================================================*/
lr_type *find_largest_gap(byte method) {

  lr_type *lr1;
  lr_type *lr2;
  word largest;

  largest = 0; 
  lr1 = Root_lr;
  lr2 = NULL;
  while(lr1 != NULL) {
    if(lr1->lrHomeNode == NULL && qualify_method(lr1,method)) {
      if(lr1->lrCylds > largest) {
        largest = lr1->lrCylds;
        lr2 = lr1;
        }
      }
    lr1 = lr1->lrNext;
    }
  return(lr2);
  }

/*======================================================================
;,fs
; lr_type *find_first_fit_gap(word minsize, byte method)
;
; find the first gap record within the lr_type list which contains
; at least as many cylinders as the specified value.
; 
; in:	
;	uses the following global data:
;	 Root_lr
;	 
; out:	retval == NULL if gap which will satisfy the need
;	else retval -> the corresponding lr_type record
;
;,fe
========================================================================*/
lr_type *find_first_fit_gap(word minsize, byte method) {

  lr_type *lr;

  lr = Root_lr;
  while(1) {
    if(lr->lrHomeNode == NULL && qualify_method(lr,method)) {
      if(lr->lrCylds >= minsize) {
        return(lr);
        }
      }
    lr = lr->lrNext;
    if(lr == NULL) {
      return(NULL);
      }
    }
  }

/*======================================================================
;,fs
; void update_no_ext(pr_type *prptr)
;
; update the no_ext flag to indicate if any extended partitions exist
; 
; in:	prptr -> the mbr pt to inspect
;
; out:	
;   global:	no_ext set if no extended partitions in the prptr table
;
;,fe
========================================================================*/
void update_no_ext(pr_type *prptr) {

  byte t1;


  no_ext = 1;
  for(t1=1;t1<4;t1++) {
    if(prptr->prE[t1].PT.peFileSystem == PTCext) {
      no_ext = 0;
      }
    }
  }

/*======================================================================
;,fs
; void update_cmd_box(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void update_cmd_box(void) {

  byte x1;
  lr_type *lptr1;
  byte pval;
  word t1;


  t1 = F1_FLAG;
  if(hard_drives == 2) {
    t1 |= F2_FLAG;
    }
  if(assign_letter <= 'Z') {
    if(edit_mbrpt->prE[0].PT.peFileSystem == 0) {
      t1 |= F3_FLAG;
      }
    else {
      p1 = edit_mbrpt->prE[1].PT.peFileSystem;
      p2 = edit_mbrpt->prE[2].PT.peFileSystem;
      p3 = edit_mbrpt->prE[3].PT.peFileSystem;

      /* to add a secondary, must be on first hard drive, have a free 
      slot and a qualifying gap */

      if(drive_num == 0) {
        if(p1 == 0 || p2 == 0 || p3 == 0) {
          if(find_largest_gap(FIND_SEC) != NULL) {
            t1 |= F5_FLAG;
            }
          }
        }

      /* to add an extended, if none, need free slot and any gap.  if any
      extended already, need a qualifying gap. */

      if(no_ext) {
        if((p1 == 0 || p2 == 0 || p3 == 0) && find_largest_gap(FIND_PRI) != NULL) {
          t1 |= F4_FLAG;
          }
        }
      else {
        if(find_largest_gap(FIND_EXT) != NULL) {
          t1 |= F4_FLAG;
          }
        }
      }
    }

  // checking for edit_pr == edit_mbrpt will exclude any extended
  // partitions.

  if(edit_pr == edit_mbrpt && edit_pr->prE[edit_pndx].MLG == 0) {
    pval = edit_pr->prE[edit_pndx].PT.peFileSystem;
    if((pval == PTCsm12 || pval == PTCsm16 || pval == PTCdlg) && drive_num == 0) {
      t1 |= F6_FLAG;
      }
    }

  // enable f7 (delete) whenever the current edit point is not a gap.
  // for the primary partition, only support deletion when it is
  // the only partition.

  if(edit_pr != NULL) {
    x1 = 1;
    if(edit_pr == edit_mbrpt && edit_pndx == 0) {
      x1 = 0;
      lptr1 = Root_lr;
      while(lptr1 != NULL) {
        if(lptr1->lrHomeNode != NULL) {
          x1++;
          }
        lptr1 = lptr1->lrNext;
        }
      }
    if(x1 == 1) {
      t1 |= F7_FLAG;
      }
    }

  // enable f9 (delete all) whenever it's not in the case 
  // that the only thing that exists is a gap.

  if(!(top_lr == bot_lr && top_lr->lrHomeNode == NULL)) {
    t1 |= F9_FLAG;
    }

  // enable f10, (mlg->dlg) when the current edit point is MLG-p

  if(edit_pr != NULL && edit_pr->prE[edit_pndx].MLG && edit_pndx == 0) {
    t1 |= F10_FLAG;
    }
  display_cmd_box(t1);
  }

/*======================================================================
;,fs
; byte enter_new(byte *new_msg, word initial_cylds, word initial_megs)
; 
; in:	uses the following global data:
;	 new_megs
;	 new_megs_max
;	 new_cylds
;	 new_cylds_max
;
; out:	retval = escape to abort the entry
;	retval = enter to register a new value
;		  data returned in new_megs or new_cylds.
;		  use the state of edit_cylds to determine which.
;
;,fe
========================================================================*/
byte enter_new(byte *new_msg, word initial_cylds, word initial_megs) {

  byte retcode;
  byte exit_str[10];
  word e_max;
  byte e_x;
  byte e_w;
  word *e_data;

  while(1)  {
    new_megs = initial_megs;
    new_cylds = initial_cylds;
    ul_str2video(L_DRV_COL,NEW_LINE,main_attr,new_msg,0);
    ul_display_decimal(new_megs,L_MEGS_COL,NEW_LINE,main_attr,L_MEGS_WIDTH);
    ul_display_decimal(new_cylds,L_CYLDS_COL,NEW_LINE,main_attr,L_CYLDS_WIDTH);
    ul_str2video(L_START_COL,NEW_LINE,main_attr,"-------------",0);
    ul_set_attr(LIST_XL,NEW_LINE,LIST_XR,inverse_attr);
    ul_set_cursor((edit_cylds ? CYLDS_X_CURSOR : MEGS_X_CURSOR),NEW_LINE);
    if(edit_cylds) {
      e_max = new_cylds_max;
      e_x = L_CYLDS_COL;
      e_w = L_CYLDS_WIDTH;
      e_data = &new_cylds;
      exit_str[0] = left_arrow;
      }
    else {
      e_max = new_megs_max;
      e_x = L_MEGS_COL;
      e_w = L_MEGS_WIDTH;
      e_data = &new_megs;
      exit_str[0] = right_arrow;
      }
    exit_str[1] = escape;
    exit_str[2] = enter;
    exit_str[3] = 0;
    retcode = get_int(e_x,NEW_LINE,e_w,main_attr,e_data,e_max,exit_str,0);
    if(retcode == escape || retcode == enter)  {
      break;
      }
    if(retcode == left_arrow) {
      edit_cylds = 0;
      new_cylds = initial_cylds;
      }
    if(retcode == right_arrow) {
      edit_cylds = 1;
      new_megs = initial_megs;
      }
    }
  return(retcode);
  }

/*======================================================================
;,fs
; void show_max_possible(word max_megs, word max_cylds)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void show_max_possible(word max_megs, word max_cylds) {

  blank_line(1,MAX_POS_Y,main_attr,40);
  ul_str2video(1,MAX_POS_Y,main_attr,large_msg,1);
  if(max_megs != 0) {
    ul_display_decimal(max_megs,L_MEGS_COL,MAX_POS_Y,main_attr,5);
    }
  else {
    ul_char2video(L_MEGS_COL+L_MEGS_WIDTH-1,MAX_POS_Y,main_attr,'-');
    }
  if(max_cylds != 0) {
    ul_display_decimal(max_cylds,L_CYLDS_COL,MAX_POS_Y,main_attr,5);
    }
  else {
    ul_char2video(L_CYLDS_COL+L_CYLDS_WIDTH-1,MAX_POS_Y,main_attr,'-');
    }
  }

/*======================================================================
;,fs
; void del_lr_list(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void del_lr_list(void) {

  lr_type *lptr1;
  lr_type *lptr2;


  /* deallocate any existing lr_type list */

  if(Root_lr != NULL) {
    lptr1 = Root_lr;
    while(lptr1 != NULL) {
      lptr2 = lptr1;
      lptr1 = lptr1->lrNext;
      free(lptr2);
      }
    Root_lr = NULL;
    }
  }

/*======================================================================
;,fs
; void gen_lr_list(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void gen_lr_list(void) {

  byte retval;
  byte lcnt;
  lr_type *lptr1;


  /* traverse all partitions/all drives in the tree to assign drive letters */

  assign_letter = START_LETTER;
  trace_tree(&drvltrs_work,NULL);

  /* deallocate any existing lr_type list */

  del_lr_list();

  /* generate the lr_type list for the current hard drive */

  if(trace_tree(&gen_lr_list_work,edit_dr)) {
    report_error(errcode_insuficmem);
    exit(1);
    }

  /* process the lr_type list for gaps */

  retval = gen_gaps(edit_dr);
  if(retval == 1) {
    report_error(errcode_insuficmem);
    exit(1);
    }
  if(retval == 2) {
    report_error(errcode_badcylnum);
    exit(1);
    }

  /* derive the new values for edit_lr, edit_pr, edit_pndx and top_lr */

  if(edit_pr_hold == NULL) {
    top_lr = Root_lr;
    edit_lr = Root_lr;
    }
  else {
    lptr1 = Root_lr;
    if(edit_line == 0xff) {

      /* when edit_line is set to ff, means that a new value must be
      established for it. */

      t1 = 1;
      while(1) {
        if(lptr1->lrHomeNode == edit_pr_hold && lptr1->lrHomeNdx == edit_pndx_hold) {
          break;
          }
        t1++;
        lptr1 = lptr1->lrNext;
        }
      edit_lr = lptr1;
      top_lr = Root_lr;
      if(t1 <= LIST_LINES) {
        edit_line = t1 - 1;
        }
      else {
        edit_line = LIST_LINES - 1;
        t1 -= LIST_LINES;
        for(t2=0;t2<t1;t2++) {
          top_lr = top_lr->lrNext;
          }
        }
      }
    else {
      while(1) {
        if(lptr1->lrHomeNode == edit_pr_hold && lptr1->lrHomeNdx == edit_pndx_hold) {
          edit_lr = lptr1;
          t1 = edit_line;
          while(1) {
            top_lr = lptr1;
            if(t1 == 0) break;
            t1--;
            lptr1 = lptr1->lrPrev;

            /* handle the case where a gap preceding the edit line was
            deleted due to an increase of the edit line's allocation */

            if(lptr1 == NULL) {
              edit_line--;
              break;
              }
            }

          /* adjust top_lr back by one if the new display list would have
          a blank bottom line when it shouldn't.  this is done by counting
          the number of displayable lines and comparing to the number of
          lines in the display area. */

          t1 = 0;
          lptr1 = top_lr;
          while(lptr1 != NULL) {
            t1++;
            lptr1 = lptr1->lrNext;
            }
          if(t1 < LIST_LINES && top_lr->lrPrev != NULL) {
            top_lr = top_lr->lrPrev;
            edit_line++;
            }
          break;
          }
        lptr1 = lptr1->lrNext;
        if(lptr1 == NULL) {
          top_lr = Root_lr;
          edit_lr = Root_lr;
          break;
          }
        }
      }
    edit_pr_hold = NULL;
    }
  edit_pr = edit_lr->lrHomeNode;
  edit_pndx = edit_lr->lrHomeNdx;

  // derive bot_lr

  lcnt = 0;
  lptr1 = top_lr;
  bot_lr = lptr1;
  while(lptr1 != NULL) {
    lcnt++;
    bot_lr = lptr1;
    if(lcnt == LIST_LINES) break;
    lptr1 = lptr1->lrNext;
    }
  }

/*======================================================================
;,fs
; void display_lr_list(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void display_lr_list(void) {

  byte lcnt;
  lr_type *lptr1;


  /* display the lr_type list */

  ul_clr_box(1,6,49,14,main_attr);
  lcnt = 0;
  lptr1 = top_lr;
  while(lptr1 != NULL) {
    display_lr_data(lptr1,lcnt);
    lcnt++;
    if(lcnt == LIST_LINES) break;
    lptr1 = lptr1->lrNext;
    }
  update_more();
  }

/*======================================================================
;,fs
; byte is_secondary(lr_type *lr)
; 
; in:	lr -> lr_type record for the partition
;
; out:	retval = 1 if the partition is a secondary one
;
;,fe
========================================================================*/
byte is_secondary(lr_type *lr) {

  byte pndx;
  byte pval;

  pndx = lr->lrHomeNdx;
  pval = lr->lrHomeNode->prE[pndx].PT.peFileSystem;
  return((pval == PTCsm12 || pval == PTCsm16 || pval == PTCdlg) && pndx != 0);
  }

/*======================================================================
;,fs
; void update_max(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void update_max(void) {

  word max_small_cylds;

  edit_megs_max = 0;
  edit_cylds_max = 0;
  if(edit_pr != NULL) {
    edit_cylds_max = edit_lr->lrCylds;
    if(edit_lr->lrPrev != NULL) {
      if(edit_lr->lrPrev->lrHomeNode == NULL) {
        edit_cylds_max += edit_lr->lrPrev->lrCylds;
        }
      }
    if(edit_lr->lrNext != NULL) {
      if(edit_lr->lrNext->lrHomeNode == NULL) {
        edit_cylds_max += edit_lr->lrNext->lrCylds;
        }
      }

    // if the edit line is for a secondary partition and
    // the max cylds would produce a large volume, must limit it

    if(is_secondary(edit_lr)) {
      max_small_cylds = derive_maxsml(edit_dr);
      if(edit_cylds_max > max_small_cylds) {
        edit_cylds_max = max_small_cylds;
        }
      }

    // calc the max megs for the max cylds

    edit_megs_max = cylds2megs(edit_dr,edit_cylds_max);
    }
  show_max_possible(edit_megs_max,edit_cylds_max);
  }

/*======================================================================
;,fs
; byte check_pbr(pr_type *pr, byte nx, byte drv)
; 
; check for a partition boot record which contains the wrong total
; sector count but is otherwise valid.  if found, blank out the
; partition boot record.  this is necessary to prevent format from
; acting on the wrong information.
; 
; note: uses sct_buf
; 
; in:	
;
; out:	retval != 0 if error
;	error message will have been displayed
;
;,fe
========================================================================*/
byte check_pbr(pr_type *pr, byte nx, byte drv) {

  bt_type *btptr;
  dword d1;
  word not_pbr;

  // if the partition has already been recognized as mlg, its pbr
  // must be ok.  a valid pbr is required for mlg recognition.

  if(pr->prE[nx].MLG) {
    return(0);
    }
  if(read_sector(0x80+drv,pr->prE[nx].PT.peBeginHead,pr->prE[nx].PT.peBeginSector,pr->prE[nx].PT.peBeginCylinder,sct_buf) != 0) {
    report_error(errcode_insuficmem);
    return(1);
    }
  not_pbr = 0;
  d1.li = 0;
  if(sct_buf[510] == 0x55 && sct_buf[511] == 0xaa) {
    (word)btptr = (word)&sct_buf;
    if(btptr->btSectors != 0) {
      d1.h[0] = btptr->btSectors;
      }
    else {
      if(btptr->btBootSignature == 0x29) {
        d1.li = btptr->btHugeSectors.li;
        }
      }
    }
  else {
    not_pbr = 1;
    }
  if(not_pbr || d1.li != pr->prE[nx].PT.peSectors.li) {
    memset(&sct_buf,0xf6,512);
    if(write_sector(0x80+drv,pr->prE[nx].PT.peBeginHead,pr->prE[nx].PT.peBeginSector,pr->prE[nx].PT.peBeginCylinder,sct_buf) != 0) {
      report_error(errcode_diskwrite);
      return(1);
      }
    }
  return(0);
  }

/*======================================================================
;,fs
; byte write_tree(void)
; 
; in:	
;
; out:	retval != 0 if error
;	error message will have been reported.
;
;,fe
========================================================================*/
byte write_tree(void) {

  byte ext_ndx;
  dword tsct;
  dword spcyl;
  byte msg[10];
  byte pval;
  dr_type *dptr1;
  pr_type *pptr1;
  pr_type *pptr2;
  dword rel_secs;


  changed_disk = 1;
  ext_ndx = 0xff;
  dptr1 = Root_dr;
  drive_num = 0;
  while(dptr1 != NULL) {
    pptr1 = dptr1->drPR;
    spcyl.li = dptr1->drSPT * dptr1->drHeads;

    /* insure the partition table is fresh (needed when processing
    the second drive, where the first drive had more partition table
    entries). */

    memset(&mbr_buf[0x1be],0,16*4);

    /* process the ptes 0-3 within mbr */

    for(t1=0;t1<4;t1++) {

      if(pptr1->prE[t1].PT.peFileSystem == PTCnil) {
        continue;
        }

      /* set beginning head and sector number */

      get_pe_data(pptr1,t1,&bs,&bc,&es,&ec);
      pptr1->prE[t1].PT.peBeginHead = 0;
      if(t1 == 0) {
        pptr1->prE[t1].PT.peBeginHead = 1;
        }
      bs = 1;
      if(pptr1->prE[t1].PT.peFileSystem != PTCext) {

        /* set ending head and sector number */

        pptr1->prE[t1].PT.peEndHead = dptr1->drHeads - 1;
        es = dptr1->drSPT;

        /* calc total sectors value */

        tsct.li = spcyl.li * (ec - bc + 1);
        if(t1 == 0) {
          tsct.li -= dptr1->drSPT;
          }
        pptr1->prE[t1].PT.peSectors.li = tsct.li;
        }
      else {

        /* for the root entry of a chain of extended partitions, record
        the pte number for later and calc the beginning cylinder number. */

        ext_ndx = t1;
        bc = pptr1->prE[t1].ExtPR->prE[0].PT.peBeginCylinder + 
        ((pptr1->prE[t1].ExtPR->prE[0].PT.peBeginSector & 0xc0) << 2);

        /* to appease fdisk, must locate the ending cyld of the last
        extended partition and write it into the ending cyld field of
        each PTCext entry (along with the ending head and sector).
        */

        pptr2 = pptr1->prE[ext_ndx].ExtPR;
        while(pptr2->prE[1].ExtPR != NULL) {
          pptr2 = pptr2->prE[1].ExtPR;
          }
        get_pe_data(pptr2,0,&bs2,&bc2,&es2,&ec);
        es = dptr1->drSPT;
        pptr1->prE[t1].PT.peEndHead = dptr1->drHeads - 1;

        /* also to appease fdisk */

        pptr1->prE[t1].PT.peStartSector.li = rel_secs.li;
        tsct.li = spcyl.li * (ec - bc + 1);
        pptr1->prE[t1].PT.peSectors.li = tsct.li;
        }

      /* derive relative sectors value */

      pptr1->prE[t1].PT.peStartSector.li = 
      (spcyl.li * bc) + (pptr1->prE[t1].PT.peBeginHead * dptr1->drSPT);

      /* copy pt data to mbr buffer */

      set_pe_data(pptr1,t1,bs,bc,es,ec);
      memcpy((mbr_buf+0x1be+t1*16),&(pptr1->prE[t1].PT),16);
      }

    /* write the mbr buffer to disk */

    if(write_sector(0x80+drive_num,0,1,0,mbr_buf) != 0) {
      report_error(errcode_diskwrite);
      return(1);
      }

    /* go back through each dos type partition.  if the needmsys flag
    is not set, check for a partition boot record which contains the 
    wrong total sector count but is otherwise valid.  if found, blank 
    out the partition boot record.  this is necessary to prevent format 
    from acting on the wrong information.
    for partitions where the needmsys flag is set, exec msys/m. */

    for(t1=0;t1<4;t1++) {
      if(pptr1->prE[t1].NeedMSYS == 0) {
        pval = pptr1->prE[t1].PT.peFileSystem;
        if(pval == PTCsm12 || pval == PTCsm16 || pval == PTCdlg) {
          if(check_pbr(pptr1,t1,drive_num) != 0) {
            return(1);
            }
          }
        }
      else {
        sprintf(msg,"%c: /m",pptr1->prE[t1].OrigDriveLetter);
        if(spawnl(P_WAIT,"msys",global_argv[0],msg,NULL) != 0) {
          report_error(errcode_execmsys);
          exit(1);
          }
        }
      }

    /* process any extended partitions chains */

    if(ext_ndx != 0xff) {
      pptr1 = pptr1->prE[ext_ndx].ExtPR;
      rel_secs.li = 0;
      while(pptr1 != NULL) {

        /* prepare a blank sector buffer */

        memset(&sct_buf,0,512);
        sct_buf[510] = 0x55;
        sct_buf[511] = 0xaa;

        /* set beginning and ending head and sector numbers */

        get_pe_data(pptr1,0,&bs,&bc,&es,&ec);
        pptr1->prE[0].PT.peBeginHead = 1;
        bs = 1;
        pptr1->prE[0].PT.peEndHead = dptr1->drHeads - 1;
        es = dptr1->drSPT;

        /* derive relative sectors value */

        pptr1->prE[0].PT.peStartSector.li = dptr1->drSPT;

        /* calc total sectors value */

        tsct.li = dptr1->drSPT;
        tsct.li *= dptr1->drHeads;
        tsct.li *= (ec - bc + 1);
        tsct.li -= dptr1->drSPT;
        pptr1->prE[0].PT.peSectors.li = tsct.li;
        rel_secs.li += (tsct.li + dptr1->drSPT);
        set_pe_data(pptr1,0,bs,bc,es,ec);

        /* if not the last extended partition in the chain, prepare
        the linkage entry in this partition table. */

        if(pptr1->prE[1].ExtPR != NULL) {
          pptr1->prE[1].PT.peFileSystem = PTCext;
          get_pe_data(pptr1,1,&bs,&bc,&es,&ec);
          pptr1->prE[1].PT.peBeginHead = 0;
          bs = 1;
          bc = pptr1->prE[1].ExtPR->prE[0].PT.peBeginCylinder + 
          ((pptr1->prE[1].ExtPR->prE[0].PT.peBeginSector & 0xc0) << 2);
          ec = pptr1->prE[1].ExtPR->prE[0].PT.peEndCylinder + 
          ((pptr1->prE[1].ExtPR->prE[0].PT.peEndSector & 0xc0) << 2);
          es = dptr1->drSPT;
          pptr1->prE[1].PT.peEndHead = dptr1->drHeads - 1;
          pptr1->prE[1].PT.peStartSector.li = rel_secs.li;
          tsct.li = dptr1->drSPT;
          tsct.li *= dptr1->drHeads;
          tsct.li *= (ec - bc + 1);
          pptr1->prE[1].PT.peSectors.li = tsct.li;
          set_pe_data(pptr1,1,bs,bc,es,ec);
          }
        else {
          memset(&(pptr1->prE[1].PT),0,16);
          }
        memset(&(pptr1->prE[2].PT),0,16);
        memset(&(pptr1->prE[3].PT),0,16);

        /* transfer the data to the sector buffer */

        memcpy(sct_buf+0x1be,&(pptr1->prE[0].PT),16);
        memcpy(sct_buf+0x1be+16,&(pptr1->prE[1].PT),16);

        /* write the sector buffer to disk */

        if(write_sector(0x80+drive_num,0,pptr1->prE[0].PT.peBeginSector,pptr1->prE[0].PT.peBeginCylinder,sct_buf) != 0) {
          report_error(errcode_diskwrite);
          return(1);
          }

        /* don't let format be confused by a left-over pbr. */

        if(check_pbr(pptr1,0,drive_num) != 0) {
          return(1);
          }
        pptr1 = pptr1->prE[1].ExtPR;
        }
      }
    dptr1 = dptr1->drNext;
    drive_num = 1;
    }
  return(0);
  }

/*======================================================================
;,fs
; void reboot(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void reboot(void) {

  byte *mmname = "$$MEMDEV";
  dword memptr;

  regs.x.ax = 0x3d02;
  regs.x.dx = (word)mmname;
  sregs.ds = _SS;
  intdosx(&regs,&regs,&sregs);
  if(regs.x.cflag == 0) {
    regs.x.bx = regs.x.ax;
    regs.x.ax = 0x4400;
    intdosx(&regs,&regs,&sregs);
    regs.h.dh = 0;
    regs.h.dl |= 0x20;
    regs.x.ax = 0x4401;
    intdosx(&regs,&regs,&sregs);
    regs.h.ah = 0x3f;
    regs.x.cx = 4;
    regs.x.dx = (word)&memptr;
    intdosx(&regs,&regs,&sregs);
    regs.h.ah = 0x3e;
    intdosx(&regs,&regs,&sregs);
    memptr.li = *memptr.lptr;
    }
  else {
    memptr.h[a_seg] = 0xf000;
    memptr.h[a_ofs] = 0xfff0;
    }
  _AH = 0;
  (memptr.ffptrv)();
  }

/*======================================================================
;,fs
; byte prompt_for_choice(byte stat_code, byte *msg_tag, byte ch1, byte ch2)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
byte prompt_for_choice(byte stat_code, byte *msg_tag, byte ch1, byte ch2) {

  byte t;
  byte x;
  byte y;

  display_stats(stat_code);
  display_cmd_box(F1_FLAG);
  clr_prompt_win();
  ul_disp_msg(1,PM_LINE,cmd_attr,msg_tag,1);
  ul_get_xy(&x,&y);
  t = ul_get_choice(x,y,cmd_attr,ch1,ch2);
  clr_prompt_win();
  return(t);
  }

/*======================================================================
;,fs
; void write_and_boot(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void write_and_boot(void) {


  clr_prompt_win();
  ul_disp_msg(1,PM_LINE,main_attr,"WRITING",0);
  if(write_tree() != 0) {
    exit(1);
    }
  clr_prompt_win();
  display_stats(st_exit2);
  ul_disp_msg(1,PM_LINE,cmd_attr,insdisk_tag,1);
  ul_eat_key();
  ul_get_key();
  ul_clr_box(0,0,79,24,7);
  reboot();
  }

/*======================================================================
;,fs
; void do_exit(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void do_exit(void) {

  byte prompt_char;

  prompt_char = no_char;
  if(changed_memory) {
    if(d_switch) {
      if(prompt_for_choice(st_exit,"D_PROMPT3",yes_char,no_char) != yes_char) {
        return;
        }
      }

    /* alert the user that changes have been made */

    ul_set_attr(LIST_XL,LIST_TOP+edit_line,LIST_XR,main_attr);
    prompt_char = prompt_for_choice(st_exit,"WRCHNG",yes_char,no_char);
    if(prompt_char == yes_char) {
      write_and_boot();
      }
    }
  if(prompt_char == no_char) {
    ul_clr_box(0,0,79,24,7);
    ul_set_cursor(0,0);
    exit(0);
    }
  }

/*======================================================================
;,fs
; void compress_mbrpt(pr_type *pr, byte nx)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void compress_mbrpt(pr_type *pr, byte nx) {

  byte n1;

  if(nx < 3) {
    n1 = nx;
    while(n1 < 3) {
      memcpy(&(pr->prE[n1]),&(pr->prE[n1+1]),sizeof(struct prec1));
      n1++;
      }
    memset(&(pr->prE[3]),0,sizeof(struct prec1));
    }
  else {
    memset(&(pr->prE[nx]),0,sizeof(struct prec1));
    }
  }

/*======================================================================
;,fs
; void insure_ext_sync(void)
; 
; make sure the beginning cylinder data within the mbr pt entry for
; the first extended partition matches the data for that partition.
; the insertion sort logic within add_secondary needs this match.
; the beginning head data doesn't need to be maintained for this
; process.  its maintenance is left for write_tree().
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void insure_ext_sync(void) {

  word t2;

  /* if the mbr's pt contains an extended partition entry, copy */

  for(t2=1;t2<4;t2++) {
    if(edit_mbrpt->prE[t2].ExtPR != NULL) {
      edit_mbrpt->prE[t2].PT.peBeginCylinder = 
      edit_mbrpt->prE[t2].ExtPR->prE[0].PT.peBeginCylinder;
      edit_mbrpt->prE[t2].PT.peBeginSector = 
      edit_mbrpt->prE[t2].ExtPR->prE[0].PT.peBeginSector;
      break;
      }
    }
  }

/*======================================================================
;,fs
; byte delete_partition(void);
; 
; in:	
;
; out:	retval = yes_char if the deletion was done
;	else retval = escape
;
;,fe
========================================================================*/
byte delete_partition(void) {

  byte prompt_char;
  byte t1;
  pr_type *pptr1;

  prompt_char = prompt_for_choice(st_delpm,"DELPART",yes_char,no_char);
  if(prompt_char != yes_char) {
    return(escape);
    }
  prompt_char = prompt_for_choice(st_delpm,"ALLDATA",yes_char,no_char);
  if(prompt_char != yes_char) {
    return(escape);
    }
  if(edit_pr->prExt == 0) {
    compress_mbrpt(edit_pr,edit_pndx);
    }
  else			/* extended */ {

    /* locate the parent node.  within mbr's pt, could be in 
    pte 1, 2 or 3.  further down a chain, should be only in pte 1. */

    t1 = 1;
    pptr1 = edit_mbrpt;
    while(1) {
      if(pptr1->prE[t1].ExtPR != NULL) break;
      t1++;
      if(t1 == 4) {
        report_error(errcode_data1);
        exit(1);
        }
      }

    /* see if the node to be deleted is the first extended partition.
    if yes, and it's the only one, don't leave the PTC at 5. */

    if(pptr1->prE[t1].ExtPR == edit_pr) {
      pptr1->prE[t1].ExtPR = pptr1->prE[t1].ExtPR->prE[1].ExtPR;
      if(pptr1->prE[t1].ExtPR == NULL) {
        compress_mbrpt(pptr1,t1);
        }
      }
    else {

      /* when not the first extended partition, 
      must trace the chain. */

      pptr1 = pptr1->prE[t1].ExtPR;

      while(pptr1->prE[1].ExtPR != edit_pr) {
        pptr1 = pptr1->prE[1].ExtPR;
        if(pptr1 == NULL) {
          report_error(errcode_data2);
          exit(1);
          }
        }

      /* at this point, pptr1 points to the parent node of the 
      node to be deleted. */

      pptr1->prE[1].ExtPR = pptr1->prE[1].ExtPR->prE[1].ExtPR;
      if(pptr1->prE[1].ExtPR == NULL) {
        pptr1->prE[1].PT.peFileSystem = PTCnil;
        }
      free(edit_pr);
      }
    }
  edit_pr_hold = NULL;
  edit_line = 0;
  changed_memory = 1;
  derive_lr = 1;		
  return(yes_char); 
  }

/*======================================================================
;,fs
; void delete_all_guts(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void delete_all_guts(void) {

  byte t1;
  pr_type *pptr1;
  pr_type *pptr2;
  pr_type *pptr3;


  pptr1 = edit_mbrpt;
  for(t1=0;t1<4;t1++) {
    pptr2 = pptr1->prE[t1].ExtPR;
    pptr1->prE[t1].ExtPR = NULL;
    while(pptr2 != NULL) {
      pptr3 = pptr2->prE[1].ExtPR;
      free(pptr2);
      pptr2 = pptr3;
      }
    memset(&(pptr1->prE[t1].PT),0,16);
    }
  edit_pr_hold = NULL;
  edit_line = 0;
  changed_memory = 1;
  derive_lr = 1;		
  }

/*======================================================================
;,fs
; byte delete_all(void)
; 
; in:	
;
; out:	retval = yes_char if the deletion was done
;	else retval = escape
;
;,fe
========================================================================*/
byte delete_all(void) {

  byte prompt_char;

  prompt_char = prompt_for_choice(st_delpm,"DELALLPART",yes_char,no_char);
  if(prompt_char != yes_char) {
    return(escape);
    }
  prompt_char = prompt_for_choice(st_delpm,"ALLALLDATA",yes_char,no_char);
  if(prompt_char != yes_char) {
    return(escape);
    }
  delete_all_guts();
  return(yes_char); 
  }

/*======================================================================
;,fs
; byte max_sml_chk(word *newcyldvar)
; 
; use this function for the case where 32M is entered.  if the max
; cylds for a sml partition happen to match with the current value
; at *newcyldvar then nothing happens.  otherwise, the user is
; prompted: "Do you actually want a maximally sized SML partition?".
; if they answer no, the word at *newcyldvar is not changed (the
; rounded up # of cylinders will be used.  
;
; in:	newcyldvar -> word that holds new cylinders just entered
;   global:	edit_dr -> dr_type record for drive info
;		yes_char = 'Y' or foreign equiv
;		no_char = 'N' or foreign equiv
;
; out:	retcode = choice pressed (yes_char, no_char or escape)
;	  word at *newcyldvar is updated if yes_char 
;
;,fe
========================================================================*/
byte max_sml_chk(word *newcyldvar) {

  word max_sml_cylds;
  byte choice;


  max_sml_cylds = derive_maxsml(edit_dr);
  if(*newcyldvar != max_sml_cylds) {
    choice = prompt_for_choice(st_addpri,"MAXSML",yes_char,no_char);
    if(choice == yes_char) {
      *newcyldvar = max_sml_cylds;
      }
    }
  return(choice);
  }

/*======================================================================
;,fs
; void update_cell(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void update_cell(void) {

  byte exit_str[10];
  word e_max;
  byte e_x;
  byte e_w;
  word e_save;
  word *e_data;
  byte prompt_char;
  byte pval;
  byte retcode;
  word orig_cylds;
  lr_type *lptr1;
  word leading_gap_cylds;
  word trailing_gap_cylds;
  byte delta_dir;
  word delta_cylds;


  display_stats(st_cee);
  display_cmd_box(F1_FLAG);
  if(edit_cylds) {
    e_save = edit_lr->lrCylds;
    e_max = edit_cylds_max;
    e_x = L_CYLDS_COL;
    e_w = L_CYLDS_WIDTH;
    e_data = &(edit_lr->lrCylds);
    exit_str[0] = left_arrow;
    }
  else {
    e_save = edit_lr->lrMegs;
    e_max = edit_megs_max;
    e_x = L_MEGS_COL;
    e_w = L_MEGS_WIDTH;
    e_data = &(edit_lr->lrMegs);
    exit_str[0] = right_arrow;
    }
  exit_str[1] = up_arrow;
  exit_str[2] = down_arrow;
  exit_str[3] = escape;
  exit_str[4] = enter;
  exit_str[5] = 0;
  retcode = get_int(e_x,(LIST_TOP+edit_line),e_w,main_attr,e_data,e_max,exit_str,takein_key);
  if(retcode != enter) {
    if(edit_cylds) {
      edit_lr->lrCylds = e_save;
      }
    else {
      edit_lr->lrMegs = e_save;
      }
    if(retcode == escape) {
      retcode = 0;
      }
    takeout_key = retcode;
    return;
    }
  takeout_key = 0;

  /* update the tree database from the new entry and then set the
  derive_lr flag to make the top of loop logic regenerate a new
  display list. */

  if(edit_cylds) {
    new_cylds = edit_lr->lrCylds;
    orig_cylds = e_save;
    }
  else {
    new_cylds = megs2cylds(edit_dr,edit_lr->lrMegs,edit_cylds_max);
    orig_cylds = edit_lr->lrCylds;
    if(is_secondary(edit_lr) == 0) {
      if(edit_lr->lrMegs == 32) {
        if(max_sml_chk(&new_cylds) == escape) {
          if(edit_cylds) {
            edit_lr->lrCylds = e_save;
            }
          else {
            edit_lr->lrMegs = e_save;
            }
          if(retcode == escape) {
            retcode = 0;
            }
          takeout_key = retcode;
          return;
          }
        }
      }
    }

  /* note: if new_cylds == orig_cylds, delta_cylds will end up 0 and
  the state of delta_dir doesn't matter. */

  if(orig_cylds > new_cylds) {
    delta_dir = 0;			/* signal a decrease */
    delta_cylds = orig_cylds - new_cylds;
    }
  else {
    delta_dir = 1;			/* signal an increase */
    delta_cylds = new_cylds - orig_cylds;
    }
  if(!delta_cylds) {
    return;
    }
  get_pe_data(edit_pr,edit_pndx,&bs,&bc,&es,&ec);
  if(delta_dir)		/*========== increasing */ {

    // for a secondary partition, caution before accepting a change

    if(is_secondary(edit_lr)) {
      prompt_char = prompt_for_choice(st_secwarn,"SECNOTE",yes_char,no_char);
      if(prompt_char != yes_char) {
        if(edit_cylds) {
          edit_lr->lrCylds = e_save;
          }
        else {
          edit_lr->lrMegs = e_save;
          }
        return;
        }
      }

    // make sure the user knows the consequences of a change

    prompt_char = prompt_for_choice(st_chwarn,"SIZECHNG",yes_char,no_char);
    if(prompt_char != yes_char) {
      if(edit_cylds) {
        edit_lr->lrCylds = e_save;
        }
      else {
        edit_lr->lrMegs = e_save;
        }
      return;
      }
    leading_gap_cylds = 0;
    trailing_gap_cylds = 0;
    if(edit_lr->lrPrev != NULL && edit_lr->lrPrev->lrHomeNode == NULL) {
      leading_gap_cylds = edit_lr->lrPrev->lrCylds;
      }
    if(edit_lr->lrNext != NULL && edit_lr->lrNext->lrHomeNode == NULL) {
      trailing_gap_cylds = edit_lr->lrNext->lrCylds;
      }
    if(leading_gap_cylds && trailing_gap_cylds) {
      if(delta_cylds == (leading_gap_cylds + trailing_gap_cylds)) {
        bc -= leading_gap_cylds;
        ec += trailing_gap_cylds;
        }
      else {
        prompt_char = prompt_for_choice(st_addpm,"ADDBEGEND",begin_char,end_char);
        if(prompt_char == escape) {
          if(edit_cylds) {
            edit_lr->lrCylds = e_save;
            }
          else {
            edit_lr->lrMegs = e_save;
            }
          return;
          }
        if(prompt_char == begin_char) {
          if(delta_cylds <= leading_gap_cylds) {
            bc -= delta_cylds;
            }
          else {
            bc -= leading_gap_cylds;
            ec += (delta_cylds - leading_gap_cylds);
            }
          }
        else			/* picked trailing */ {
          if(delta_cylds <= trailing_gap_cylds) {
            ec += delta_cylds;
            }
          else {
            ec += trailing_gap_cylds;
            bc -= (delta_cylds - trailing_gap_cylds);
            }
          }
        }
      }
    else				/* only leading or trailing but not both */ {
      if(leading_gap_cylds) {
        bc -= delta_cylds;
        }
      else				/* must be a trailing gap */ {
        ec += delta_cylds;
        }
      }
    edit_pr_hold = edit_pr;
    edit_pndx_hold = edit_pndx;

    }
  else			/*========== decreasing */ {

    if(delta_cylds == orig_cylds) {

      /* decreasing to 0 -- prepare to delete a partition.
      if the edit line is the primary partition, only permit its
      deletion if it is the only partition. */

      t1 = 1;
      if(edit_pr == edit_mbrpt && edit_pndx == 0) {
        t2 = 0;
        lptr1 = Root_lr;
        while(lptr1 != NULL) {
          if(lptr1->lrHomeNode != NULL) {
            t2++;
            }
          lptr1 = lptr1->lrNext;
          }

        // if other partitions exist besides the primary, tell the
        // user that they can't delete the primary now

        if(t2 > 1) {
          display_stats(st_dplpm);
          display_cmd_box(F1_FLAG);
          clr_prompt_win();
          ul_disp_msg(1,PM_LINE,error_attr,"PRILAST",1);
          ul_eat_key();
          ul_get_key();
          clr_prompt_win();
          t1 = 0;
          if(edit_cylds) {
            edit_lr->lrCylds = e_save;
            }
          else {
            edit_lr->lrMegs = e_save;
            }
          return;
          }
        }

      // if get here and t1 is still != 0, must be ok to delete
      // the partition.

      if(t1) {
        if(delete_partition() == escape) {
          if(edit_cylds) {
            edit_lr->lrCylds = e_save;
            }
          else {
            edit_lr->lrMegs = e_save;
            }
          }
        }
      return;
      }

    // decreasing, but not to 0

    // for a secondary partition, caution before accepting a change

    if(is_secondary(edit_lr)) {
      prompt_char = prompt_for_choice(st_secwarn,"SECNOTE",yes_char,no_char);
      if(prompt_char != yes_char) {
        if(edit_cylds) {
          edit_lr->lrCylds = e_save;
          }
        else {
          edit_lr->lrMegs = e_save;
          }
        return;
        }
      }

    // make sure the user knows the consequences of a change

    prompt_char = prompt_for_choice(st_chwarn,"SIZECHNG",yes_char,no_char);
    if(prompt_char != yes_char) {
      if(edit_cylds) {
        edit_lr->lrCylds = e_save;
        }
      else {
        edit_lr->lrMegs = e_save;
        }
      return;
      }
    if(edit_pr == edit_mbrpt && edit_pndx == 0) {

      /* for primary partition, always delete from the end */

      prompt_char = end_char;
      }
    else {

      /* prompt for leading or trailing gap (e.g. which gap 
      to increase). */

      prompt_char = prompt_for_choice(st_subpm,"SUBBEGEND",begin_char,end_char);
      }
    if(prompt_char == escape) {
      if(edit_cylds) {
        edit_lr->lrCylds = e_save;
        }
      else {
        edit_lr->lrMegs = e_save;
        }
      return;
      }
    if(prompt_char == begin_char) {
      bc += delta_cylds;
      }
    else {
      ec -= delta_cylds;
      }
    edit_pr_hold = edit_pr;
    edit_pndx_hold = edit_pndx;
    }

  // if get to this point, an adjustment was made and needs to
  // be reflecting by updating the pr_type record and
  // flagging the derivation of a new lr_type list.

  set_pe_data(edit_pr,edit_pndx,bs,bc,es,ec);
  pval = edit_pr->prE[edit_pndx].PT.peFileSystem;
  if(pval == PTCsm12 || pval == PTCsm16 || pval == PTCdlg) {
    edit_pr->prE[edit_pndx].PT.peFileSystem = derive_PTC(edit_dr,(ec-bc+1));
    }
  changed_memory = 1;
  derive_lr = 1;		
  }

/*======================================================================
;,fs
; void force_d1(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void force_d1(void) {


  edit_dr = Root_dr;		// switch to drive 1
  drive_num = 0;
  edit_mbrpt = edit_dr->drPR;
  edit_line = 0;
  edit_pr_hold = NULL;
  derive_lr = 1;
  }

/*======================================================================
;,fs
; void force_d2(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void force_d2(void) {


  edit_dr = Root_dr->drNext;	// switch to drive 2
  drive_num = 1;
  edit_mbrpt = edit_dr->drPR;
  edit_line = 0;
  edit_pr_hold = NULL;
  derive_lr = 1;
  }

/*======================================================================
;,fs
; void toggle_drive(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void toggle_drive(void) {


  if(edit_dr == Root_dr) {
    force_d2();
    }
  else {
    force_d1();
    }
  }

/*======================================================================
;,fs
; void add_primary(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void add_primary(void) {

  lr_type *lgap_ptr;
  word ini_cylds;
  word ini_megs;

  lgap_ptr = find_largest_gap(FIND_PRI);
  new_cylds_max = lgap_ptr->lrCylds;
  new_megs_max = lgap_ptr->lrMegs;
  ul_set_attr(LIST_XL,LIST_TOP+edit_line,LIST_XR,main_attr);
  ul_set_cursor(0,24);
  display_cmd_box(F1_FLAG);
  clr_prompt_win();
  display_stats(st_addpri);
  ini_cylds = new_cylds_max;
  ini_megs = new_megs_max;
  switch(lead_through) {
  case LT_NSWITCH:
    ul_disp_msg(1,PM_LINE,cmd_attr,"N_PROMPT1",1);
    ini_cylds = 0;
    ini_megs = 0;
    break;

  case LT_DSWITCH:
    ul_disp_msg(1,PM_LINE,cmd_attr,"D_PROMPT1",1);

    // NOTE: the following presumes more than 3 megs are available.
    // this should be safe since all partitions were just deleted.

    new_cylds_max -= megs2cylds(edit_dr,3,new_cylds_max);
    new_megs_max = cylds2megs(edit_dr,new_cylds_max);
    ini_cylds = 0;
    ini_megs = 0;
    break;
    }
  show_max_possible(new_megs_max,new_cylds_max);

  /* prompt for the value */

  while(1) {
    if(enter_new(newpri_msg,ini_cylds,ini_megs) != escape) {
      if(!edit_cylds) {
        new_cylds = megs2cylds(edit_dr,new_megs,new_cylds_max);
        if(new_megs == 32) {
          if(max_sml_chk(&new_cylds) == escape) {
            new_cylds = 0;
            }
          }
        }
      if(new_cylds != 0) {

        /* update the tree based on the response */

        edit_mbrpt->prExt = 0;
        set_pe_data(edit_mbrpt,0,1,0,edit_dr->drSPT,new_cylds-1);
        edit_mbrpt->prE[0].PT.peFileSystem = derive_PTC(edit_dr,new_cylds);
        edit_mbrpt->prE[0].PT.peBootable = 0;
        if(drive_num == 0) {
          edit_mbrpt->prE[0].PT.peBootable = 0x80;
          }
        edit_mbrpt->prE[0].MLG = 0;
        edit_mbrpt->prE[0].NeedMSYS = 0;
        edit_mbrpt->prE[0].DriveLetter = 0;
        edit_mbrpt->prE[0].ExtPR = NULL;
        edit_pr_hold = edit_mbrpt;
        edit_pndx_hold = 0;
        edit_line = 0xff;
        changed_memory = 1;
        derive_lr = 1;		
        break;
        }
      }
    if(lead_through == LT_NULL) {
      break;
      }
    }
  clr_prompt_win();
  }

/*======================================================================
;,fs
; void add_ext_helper1(void)
; 
; in:	
;   global:	no_ext
;
; out:	
;   global:	new_cylds_max
;		new_megs_max
;
;,fe
========================================================================*/
void add_ext_helper1(void) {

  lr_type *lgap_ptr;


  if(no_ext) {
    lgap_ptr = find_largest_gap(FIND_PRI);
    }
  else {
    lgap_ptr = find_largest_gap(FIND_EXT);
    }
  new_cylds_max = lgap_ptr->lrCylds;
  new_megs_max = lgap_ptr->lrMegs;
  }

/*======================================================================
;,fs
; pr_type *ext_helper2(pr_type *prptr, dr_type *drptr)
; 
; in:	
;   global:	no_ext
;		new_cylds
;
; out:	retval -> the new pr_type node
;
;,fe
========================================================================*/
pr_type *ext_helper2(pr_type *prptr, dr_type *drptr) {

  pr_type *pptr1;
  pr_type *pptr2;
  pr_type *pptr3;
  lr_type *lptr1;
  word bc;
  word bc2;
  word ec;
  word t1;
  word t2;

  if((pptr1 = (pr_type *) malloc(sizeof(pr_type))) == NULL) {
    report_error(errcode_insuficmem);
    exit(1);
    }
  pptr1->prExt = 1;
  if(no_ext) {
    lptr1 = find_largest_gap(FIND_PRI);
    }
  else {
    lptr1 = find_first_fit_gap(new_cylds,FIND_EXT);
    }
  if(lptr1 == NULL) {
    report_error(errcode_data3);
    exit(1);
    }
  bc = lptr1->lrStart;
  ec = lptr1->lrStart+new_cylds-1;
  set_pe_data(pptr1,0,1,bc,drptr->drSPT,ec);
  pptr1->prE[0].PT.peFileSystem = derive_PTC(drptr,new_cylds);
  pptr1->prE[0].PT.peBootable = 0;
  pptr1->prE[0].MLG = 0;
  pptr1->prE[0].NeedMSYS = 0;
  pptr1->prE[0].DriveLetter = 0;
  pptr1->prE[0].ExtPR = NULL;
  for(t1=1;t1<4;t1++) {
    pptr1->prE[t1].PT.peBootable = 0;
    pptr1->prE[t1].PT.peFileSystem = PTCnil;
    pptr1->prE[t1].ExtPR = NULL;
    }

  /* see if the mbr's pt already contains an extended partition
  entry. */

  t1 = 0;
  for(t2=1;t2<4;t2++) {
    if(prptr->prE[t2].ExtPR != NULL) {
      t1 = 1;
      break;
      }
    }
  if(t1) {

    /* insert the new node into the existing chain - based on the
    starting cylinder value. */

    pptr3 = prptr;
    pptr2 = pptr3->prE[t2].ExtPR;
    while(pptr2 != NULL) {
      bc2 = pptr2->prE[0].PT.peBeginCylinder + 
      ((pptr2->prE[0].PT.peBeginSector & 0xc0) << 2);
      if(bc < bc2) {
        pptr1->prE[1].ExtPR = pptr2;
        pptr1->prE[1].PT.peFileSystem = PTCext;
        pptr3->prE[t2].ExtPR = pptr1;
        t1 = 0;				/* signal insertion was done */
        break;
        }
      pptr2 = pptr2->prE[1].ExtPR;
      pptr3 = pptr3->prE[t2].ExtPR;
      t2 = 1;
      }

    /* if t1 didn't get cleared, the new node belongs at the end of 
    the current list. */

    if(t1) {
      pptr3->prE[1].ExtPR = pptr1;
      }
    }
  else {

    /* find a free pte in the mbr's pt to establish an extended entry */

    t1 = 1;
    while(prptr->prE[t1].PT.peFileSystem != PTCnil) {
      t1++;
      if(t1 == 4) {
        report_error(errcode_data4);
        exit(1);
        }
      }
    prptr->prE[t1].PT.peFileSystem = PTCext;
    prptr->prE[t1].ExtPR = pptr1;
    }
  return(pptr1);
  }

/*======================================================================
;,fs
; void add_extended(void)
; 
; in:	
;   global:	no_ext
;
; out:	
;
;,fe
========================================================================*/
void add_extended(void) {

  byte retcode;

  add_ext_helper1();
  ul_set_attr(LIST_XL,LIST_TOP+edit_line,LIST_XR,main_attr);
  ul_set_cursor(0,24);
  display_cmd_box(F1_FLAG);
  clr_prompt_win();
  show_max_possible(new_megs_max,new_cylds_max);
  display_stats(st_addext);

  // prompt for the value and update the tree based on the response

  if(enter_new(newext_msg,new_cylds_max,new_megs_max) != escape) {
    if(!edit_cylds) {
      new_cylds = megs2cylds(edit_dr,new_megs,new_cylds_max);
      if(new_megs == 32) {
        if(max_sml_chk(&new_cylds) == escape) {
          new_cylds = 0;
          }
        }
      }
    if(new_cylds != 0) {
      edit_pr_hold = ext_helper2(edit_mbrpt,edit_dr);
      edit_pndx_hold = 0;
      edit_line = 0xff;
      changed_memory = 1;
      derive_lr = 1;		
      }
    }
  clr_prompt_win();
  }

/*======================================================================
;,fs
; void add_secondary(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void add_secondary(void) {

  word max_small_cylds;
  word i_m;
  word i_c;
  byte retcode;
  lr_type *lptr1;
  lr_type *lgap_ptr;


  // put up cautionary note about secondary partitions 

  if(lead_through == LT_NULL) {
    if(prompt_for_choice(st_secwarn,"SECNOTE",yes_char,no_char) != yes_char) {
      return;
      }
    }

  // calc max possible values

  lgap_ptr = find_largest_gap(FIND_SEC);
  new_cylds_max = lgap_ptr->lrCylds;
  new_megs_max = lgap_ptr->lrMegs;

  // if the max cylds would produce a large volume, must limit it

  max_small_cylds = derive_maxsml(edit_dr);
  if(new_cylds_max > max_small_cylds) {
    new_cylds_max = max_small_cylds;
    new_megs_max = cylds2megs(edit_dr,new_cylds_max);
    }
  ul_set_attr(LIST_XL,LIST_TOP+edit_line,LIST_XR,main_attr);
  ul_set_cursor(0,24);
  display_cmd_box(F1_FLAG);
  clr_prompt_win();
  show_max_possible(new_megs_max,new_cylds_max);
  display_stats(st_addsec);

  // now, setup the initial megs value to be the suggested max
  // (unless the max possible values are smaller).

  i_m = SUG_MEGS_MAX;
  i_c = megs2cylds(edit_dr,SUG_MEGS_MAX,0xffff);
  if(i_c > new_cylds_max) {
    i_m = new_megs_max;
    i_c = new_cylds_max;
    }
  if(lead_through == LT_DSWITCH) {
    ul_disp_msg(1,PM_LINE,cmd_attr,"D_PROMPT2",1);
    }

  /* prompt for the value */

  while(1) {
    retcode = enter_new(newsec_msg,i_c,i_m);
    if(lead_through == LT_NULL || retcode != escape) {
      break;
      }
    }

  /* update the tree based on the response */

  if(retcode != escape) {
    if(!edit_cylds) {
      new_cylds = megs2cylds(edit_dr,new_megs,new_cylds_max);
      }
    if(new_cylds != 0) {

      insure_ext_sync();

      /* find a free pte in the mbr's pt to establish a secondary entry */

      t1 = 1;
      while(edit_mbrpt->prE[t1].PT.peFileSystem != PTCnil) {
        t1++;
        if(t1 == 4) {
          report_error(errcode_data5);
          exit(1);
          }
        }
      t1--;

      /* at this point, t1 is the highest pt entry in use.  now find the
      first gap of cylinders which will serve the need. */

      lptr1 = find_first_fit_gap(new_cylds,FIND_SEC);
      if(lptr1 == NULL) {
        report_error(errcode_data6);
        exit(1);
        }
      bc = lptr1->lrStart;
      ec = lptr1->lrStart+new_cylds-1;

      /* insert the new entry into the pt, maintaining order. */

      if(t1 != 0) {
        get_pe_data(edit_mbrpt,t1,&tbs,&tbc,&tes,&tec);
        if(tbc > bc) {
          while(1) {
            memcpy(&(edit_mbrpt->prE[t1+1]),&(edit_mbrpt->prE[t1]),sizeof(struct prec1));
            t1--;
            get_pe_data(edit_mbrpt,t1,&tbs,&tbc,&tes,&tec);
            if(t1 == 0 || tbc < bc) {
              break;
              }
            }
          }
        }
      t1++;
      set_pe_data(edit_mbrpt,t1,1,bc,edit_dr->drSPT,ec);
      edit_mbrpt->prE[t1].PT.peFileSystem = derive_PTC(edit_dr,new_cylds);
      edit_mbrpt->prE[t1].PT.peBootable = 0;
      if(lead_through == LT_DSWITCH) {
        edit_mbrpt->prE[t1].PT.peBootable = 0x80;
        }
      edit_mbrpt->prE[t1].MLG = 0;
      edit_mbrpt->prE[t1].NeedMSYS = 0;
      edit_mbrpt->prE[t1].DriveLetter = 0;
      edit_mbrpt->prE[t1].ExtPR = NULL;
      edit_pr_hold = edit_mbrpt;
      edit_pndx_hold = t1;
      edit_line = 0xff;
      changed_memory = 1;
      derive_lr = 1;		
      }
    }
  clr_prompt_win();
  }

/*======================================================================
;,fs
; void toggle_boot(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void toggle_boot(void) {

  if(edit_pr->prE[edit_pndx].PT.peBootable) {
    edit_pr->prE[edit_pndx].PT.peBootable = 0;
    }
  else {
    edit_pr->prE[edit_pndx].PT.peBootable = 0x80;
    }
  display_lr_data(edit_lr,edit_line);
  changed_memory = 1;
  }

/*======================================================================
;,fs
; void mlg2dlg(dr_type *cv_dr, lr_type *cv_lr)
; 
; in:	cv_dr -> the dr_type record for the partition
;	cv_lr -> the lr_type record for the partition
;
; out:	
;
;,fe
========================================================================*/
void mlg2dlg(dr_type *cv_dr, lr_type *cv_lr) {

  byte ndx;
  byte prompt_char;

  if(found_msysm) {
    prompt_char = prompt_for_choice(st_mlg2dlg,"MLG2DLG",yes_char,no_char);
    if(prompt_char == yes_char) {
      ndx = cv_lr->lrHomeNdx;
      cv_lr->lrHomeNode->prE[ndx].PT.peFileSystem = derive_PTC(cv_dr,cv_lr->lrCylds);
      cv_lr->lrHomeNode->prE[ndx].NeedMSYS = 1;
      cv_lr->lrHomeNode->prE[ndx].MLG = 0;
      changed_memory = 1;
      derive_lr = 1;
      }
    }
  else {
    clr_prompt_win();
    ul_disp_msg(1,PM_LINE,cmd_attr,"NOMSYSM",1);
    ul_eat_key();
    ul_get_key();
    clr_prompt_win();
    }
  }

/*======================================================================
;,fs
; void process_keys(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void process_keys(void) {


  if(takeout_key) {
    takein_key = takeout_key;
    takeout_key = 0;
    }
  else {
    if(lead_through == LT_NSWITCH) {
      switch(lead_stage++) {
      case 0:
        takein_key = f3;
        break;

      case 1:
        ul_disp_msg(1,PM_LINE,cmd_attr,"LT_FINAL",1);
        lead_through = LT_NULL;
        break;
        }
      }
    if(lead_through == LT_DSWITCH) {
      switch(lead_stage++) {
      case 0:
        takein_key = f3;
        break;

      case 1:
        takein_key = f5;
        break;

      case 2:
        ul_disp_msg(1,PM_LINE,cmd_attr,"LT_FINAL",1);
        lead_through = LT_NULL;
        break;
        }
      }
    if(lead_through == LT_NULL) {
      takein_key = ul_get_key();
      }
    }
  switch(takein_key) {
  case escape :
    do_exit();
    break;

  case up_arrow :
    do_uparrow();
    update_more();
    break;

  case down_arrow :
    do_downarrow();
    update_more();
    break;

  case left_arrow :
    edit_cylds = 0;
    break;

  case right_arrow :
    edit_cylds = 1;
    break;

  case '0' :
  case '1' :
  case '2' :
  case '3' :
  case '4' :
  case '5' :
  case '6' :
  case '7' :
  case '8' :
  case '9' :
  case backspace:

    // only call update_cell() if not a gap and not mlg

    if(edit_pr == NULL || edit_pr->prE[edit_pndx].MLG) {
      ul_beep();
      }
    else {
      update_cell();
      display_lr_data(edit_lr,edit_line);
      }
    break;

  case f2 :				/* switch drives */
    if((cmd_disp_state & F2_FLAG) == 0) {
      ul_beep();
      }
    else {
      toggle_drive();
      }
    break;

  case f3 :				/* add primary */
    if((cmd_disp_state & F3_FLAG) == 0) {
      ul_beep();
      }
    else {
      add_primary();
      }
    break;

  case f4 :				/* add extended */
    if((cmd_disp_state & F4_FLAG) == 0) {
      ul_beep();
      }
    else {
      add_extended();
      }
    break;

  case f5 :				/* add secondary */
    if((cmd_disp_state & F5_FLAG) == 0) {
      ul_beep();
      }
    else {
      add_secondary();
      }
    break;

  case f6 :				/* toggle boot status */
    if((cmd_disp_state & F6_FLAG) == 0) {
      ul_beep();
      }
    else {
      toggle_boot();
      }
    break;

  case f7 :				/* delete current partition */
    if((cmd_disp_state & F7_FLAG) == 0) {
      ul_beep();
      }
    else {
      delete_partition();
      }
    break;

  case f9 :				/* delete all */
    if((cmd_disp_state & F9_FLAG) == 0) {
      ul_beep();
      }
    else {
      delete_all();
      }
    break;

  case f10 :				/* toggle boot status */
    if((cmd_disp_state & F10_FLAG) == 0) {
      ul_beep();
      }
    else {
      mlg2dlg(edit_dr,edit_lr);
      }
    break;

  default :
    ul_beep();
    }
  }

/*======================================================================
;,fs
; void prep_display(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void prep_display(void) {


  ul_draw_box(0,0,79,24,main_attr,box_double);
  ul_draw_hbar(0,3,79,main_attr,box_double);
  ul_draw_hbar(0,15,79,main_attr,box_double);
  ul_draw_hbar(0,21,79,main_attr,box_double);
  ul_draw_vbar(50,3,15,main_attr,box_double);
  ul_disp_msg(1,1,main_attr,"TITLE",0);
  ul_disp_msg(1,4,main_attr,"HEADINGS",0);
  }

/*======================================================================
;,fs
; byte validate_ptc(void)
; 
; in:	
;
; out:	retval != 0 if should update lr list display and change-status
;
;,fe
========================================================================*/
byte validate_ptc(void) {

  dr_type *drptr;
  pr_type *prptr;
  byte ndx;
  byte cptc;			// current ptc value
  byte dptc;			// derived ptc value
  byte x;
  byte y;
  byte chng;


  chng = 0;
  drptr = Root_dr;
  while(drptr != NULL) {
    prptr = drptr->drPR;
    for(ndx=0;ndx<4;ndx++) {
      if(prptr->prE[ndx].MLG == 0) {
        cptc = prptr->prE[ndx].PT.peFileSystem;
        if(cptc == PTCsm12 || cptc == PTCsm16 || cptc == PTCdlg) {
          dptc = derive_PTC(drptr,derive_cylds(prptr,ndx));
          if(dptc != cptc) {
            prptr->prE[ndx].PT.peFileSystem = dptc;
            changed_memory = 1;
            derive_lr = 1;
            chng = 1;
            clr_prompt_win();
            ul_disp_msg(1,PM_LINE,cmd_attr,"PTCFIX",1);
            ul_get_xy(&x,&y);
            ul_char2video(x+1,y,cmd_attr,prptr->prE[ndx].DriveLetter);
            ul_char2video(x+2,y,cmd_attr,':');
            ul_disp_msg(1,PM_LINE+2,cmd_attr,"PTCFIX2",1);
            ul_eat_key();
            ul_get_key();
            }
          }
        }
      }
    drptr = drptr->drNext;
    }
  if(chng) {
    clr_prompt_win();
    }
  return(chng);
  }

/*======================================================================
;,fs
; void manual_mode(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void manual_mode(void) {


  prep_display();
  while(1) {
    if(derive_lr) {

      // if changes have been made (where derive_lr was set), generate
      // and display a new lr_type list.

      gen_lr_list();
      display_lr_list();
      derive_lr = 0;
      }

    // update the no_ext flag to indicate if any extended partitions exist

    update_no_ext(edit_mbrpt);

    // update the command display window

    update_cmd_box();

    // highlight the edit line

    ul_set_attr(LIST_XL,LIST_TOP+edit_line,LIST_XR,inverse_attr);
    ul_set_cursor((edit_cylds ? CYLDS_X_CURSOR : MEGS_X_CURSOR),(LIST_TOP+edit_line));

    // update information window

    if(edit_pr == NULL) {
      display_stats(st_ceneg);
      }
    else {
      display_stats(st_ceneng);
      }

    // on first pass, validate the ptc codes (to correct for d5 setup)

    if(validate_ptc_once == 0) {
      validate_ptc_once = 1;
      if(validate_ptc()) {
        continue;
        }
      }

    // update display of maximum possible values for the edit line

    update_max();

    // main character entry processing logic

    process_keys();

    }
  }

/*======================================================================
;,fs
; byte prompt_review(byte *msg_tag, byte stat_code)
; 
; in:	
;
; out:	retval = escape if escape was pressed at prompt
;	retval = yes_char if that key was pressed at the prompt
;	retval = no_char if that key was pressed at the prompt
;	retval = 0 if there are no partitions to delete
;
;,fe
========================================================================*/
byte prompt_review(byte *msg_tag, byte stat_code) {

  byte t1;
  byte x;
  byte y;
  byte choice;
  byte key;
  byte any_partitions;

  any_partitions = 0;
  t1 = F1_FLAG;
  if(hard_drives == 2) {
    t1 |= F2_FLAG;
    force_d2();
    gen_lr_list();
    if(!(top_lr == bot_lr && top_lr->lrHomeNode == NULL)) {
      any_partitions = 1;
      }
    }
  force_d1();
  gen_lr_list();
  if(!(top_lr == bot_lr && top_lr->lrHomeNode == NULL)) {
    any_partitions = 1;
    }
  if(any_partitions == 0) {
    return(0);
    }
  prep_display();
  display_lr_list();
  display_cmd_box(t1);			// update the command display window
  ul_disp_msg(1,PM_LINE-1,cmd_attr,msg_tag,1);
  ul_get_xy(&x,&y);
  choice = 0;
  while(1) {
    if(derive_lr) {

      // if changes have been made (where derive_lr was set), generate
      // and display a new lr_type list.

      gen_lr_list();
      display_lr_list();
      derive_lr = 0;
      }

    // highlight the edit line
    // and update the information window

    display_stats(stat_code);
    ul_set_attr(LIST_XL,LIST_TOP+edit_line,LIST_XR,inverse_attr);
    key = toupper(ul_get_key());
    switch(key) {
    case escape:
      return(escape);

    case up_arrow:
      do_uparrow();
      update_more();
      break;

    case down_arrow:
      do_downarrow();
      update_more();
      break;

    case f2 :				/* switch drives */
      if((cmd_disp_state & F2_FLAG) == 0) {
        ul_beep();
        }
      else {
        toggle_drive();
        }
      break;

    case enter:
      if(choice != 0) {
        if(choice == no_char) {
          return(no_char);
          }
        else {
          return(yes_char);
          }
        }
      else {
        ul_beep();
        }
      break;

    default:
      if(key == yes_char || key == no_char) {
        ul_char2video(x,y,cmd_attr,key);
        choice = key;
        }
      else {
        ul_beep();
        }
      }
    }
  }


//=========================================================
//================================ INITIALIZATION FUNCTIONS
//=========================================================

/*======================================================================
;,fs
; void parse_switches(int argc, char *argv[])
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void parse_switches(int argc, char *argv[]) {

  byte failure;


  failure = 0;
  if(argc == 1) {
    return;
    }
  if(argc > 2 || strlen(argv[1]) > 2 || argv[1][0] != '/') {
    failure = 1;
    }
  if(!failure) {
    switch(argv[1][1]) {
    case 'd':
    case 'D':
      d_switch = 1;
      no_switches = 0;
      break;

    case 'n':
    case 'N':
      n_switch = 1;
      no_switches = 0;
      break;

    case 's':
    case 'S':
      s_switch = 1;
      no_switches = 0;
      break;

    case 'c':
    case 'C':
      c_switch = 1;
      no_switches = 0;
      break;

    case 'k':
    case 'K':
      k_switch = 1;
      no_switches = 0;
      break;

    default:
      failure = 1;
      }
    }
  if(failure) {
    puts("Error: Invalid switch parameter");  /* @@XLAT */
    exit(1);
    }
  }

/*======================================================================
;,fs
; void init_video(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void init_video(void) {

  ul_set_vidptr(0,25,80);
  if(ul_get_vidseg() == 0xb000) {
    main_attr = 0x07;
    cmd_attr = 0x7f;
    error_attr = 0x7f;
    inverse_attr = 0x70;
    }
  else {
    main_attr = MAIN_ATTR_DEFAULT;
    cmd_attr = CMD_ATTR_DEFAULT;
    error_attr = ERROR_ATTR_DEFAULT;
    inverse_attr = INVERSE_ATTR_DEFAULT;
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

  // init other display globals

  if((vmsg1 = ul_get_msg("VIEW1",0)) == NULL) return(1);
  if((vmsg2 = ul_get_msg("VIEW2",0)) == NULL) return(1);

  if((f1_str = ul_get_msg("FKEYTAGS",0)) == NULL) return(1);
  if((f1_strx = ul_get_msg("FKEYTAGS",1)) == NULL) return(1);
  if((f2_str = ul_get_msg("FKEYTAGS",2)) == NULL) return(1);
  if((f2_strx = ul_get_msg("FKEYTAGS",3)) == NULL) return(1);
  if((f3_str = ul_get_msg("FKEYTAGS",4)) == NULL) return(1);
  if((f3_strx = ul_get_msg("FKEYTAGS",5)) == NULL) return(1);
  if((f4_str = ul_get_msg("FKEYTAGS",6)) == NULL) return(1);
  if((f4_strx = ul_get_msg("FKEYTAGS",7)) == NULL) return(1);
  if((f5_str = ul_get_msg("FKEYTAGS",8)) == NULL) return(1);
  if((f5_strx = ul_get_msg("FKEYTAGS",9)) == NULL) return(1);
  if((f6_str = ul_get_msg("FKEYTAGS",10)) == NULL) return(1);
  if((f6_strx = ul_get_msg("FKEYTAGS",11)) == NULL) return(1);
  if((f7_str = ul_get_msg("FKEYTAGS",12)) == NULL) return(1);
  if((f7_strx = ul_get_msg("FKEYTAGS",13)) == NULL) return(1);
  if((f8_str = ul_get_msg("FKEYTAGS",14)) == NULL) return(1);
  if((f8_strx = ul_get_msg("FKEYTAGS",15)) == NULL) return(1);
  if((f9_str = ul_get_msg("FKEYTAGS",16)) == NULL) return(1);
  if((f9_strx = ul_get_msg("FKEYTAGS",17)) == NULL) return(1);
  if((f10_str = ul_get_msg("FKEYTAGS",18)) == NULL) return(1);
  if((f10_strx = ul_get_msg("FKEYTAGS",19)) == NULL) return(1);

  if((st_mod = ul_get_msg("MODETAGS",0)) == NULL) return(1);
  if((st_mod_a = ul_get_msg("MODETAGS",1)) == NULL) return(1);
  if((st_mod_b = ul_get_msg("MODETAGS",2)) == NULL) return(1);
  if((st_mod_c = ul_get_msg("MODETAGS",3)) == NULL) return(1);
  if((st_mod_d = ul_get_msg("MODETAGS",4)) == NULL) return(1);
  if((st_mod_e = ul_get_msg("MODETAGS",5)) == NULL) return(1);
  if((st_mod_f = ul_get_msg("MODETAGS",6)) == NULL) return(1);
  if((st_mod_g = ul_get_msg("MODETAGS",7)) == NULL) return(1);
  if((st_mod_h = ul_get_msg("MODETAGS",8)) == NULL) return(1);
  st_mod_x2 = ST_MOD_X + strlen(st_mod);

  if((st_esc = ul_get_msg("ESCTAGS",0)) == NULL) return(1);
  if((st_esc_a = ul_get_msg("ESCTAGS",1)) == NULL) return(1);
  if((st_esc_b = ul_get_msg("ESCTAGS",2)) == NULL) return(1);
  if((st_esc_c = ul_get_msg("ESCTAGS",3)) == NULL) return(1);
  if((st_esc_d = ul_get_msg("ESCTAGS",4)) == NULL) return(1);
  if((st_esc_e = ul_get_msg("ESCTAGS",5)) == NULL) return(1);
  st_esc_x2 = ST_ESC_X + strlen(st_esc);

  if((st_kya = ul_get_msg("KEYATAGS",0)) == NULL) return(1);
  if((st_kyb = ul_get_msg("KEYATAGS",1)) == NULL) return(1);
  if((st_kyc = ul_get_msg("KEYATAGS",2)) == NULL) return(1);
  if((st_kyd = ul_get_msg("KEYATAGS",3)) == NULL) return(1);
  *st_kya = 24;
  *(st_kya+2) = 25;
  *st_kyb = 27;
  *(st_kyb+2) = 26;

  if((st_drv_a = ul_get_msg("DRVXOFX",0)) == NULL) return(1);
  if((st_drv_b = ul_get_msg("DRVXOFX",1)) == NULL) return(1);
  if((st_drv_format = ul_get_msg("DRVXOFX",2)) == NULL) return(1);

  if((unalloc_msg = ul_get_msg("MISCTAG",0)) == NULL) return(1);
  if((mlg_msg = ul_get_msg("MISCTAG",1)) == NULL) return(1);
  if((dlg_msg = ul_get_msg("MISCTAG",2)) == NULL) return(1);
  if((sml_msg = ul_get_msg("MISCTAG",3)) == NULL) return(1);
  if((oth_msg = ul_get_msg("MISCTAG",4)) == NULL) return(1);
  if((dashe_msg = ul_get_msg("MISCTAG",5)) == NULL) return(1);
  if((dashs_msg = ul_get_msg("MISCTAG",6)) == NULL) return(1);
  if((dashp_msg = ul_get_msg("MISCTAG",7)) == NULL) return(1);
  dasho_msg = "  ";

  if((newpri_msg = ul_get_msg("MISCTAG",8)) == NULL) return(1);
  if((newext_msg = ul_get_msg("MISCTAG",9)) == NULL) return(1);
  if((newsec_msg = ul_get_msg("MISCTAG",10)) == NULL) return(1);

  if((large_msg = ul_get_msg("LARGETAG",0)) == NULL) return(1);

  if((temp_ptr = ul_get_msg("YESNOCHARS",0)) == NULL) return(1);
  yes_char = *temp_ptr;
  no_char = *(temp_ptr+1);

  if((temp_ptr = ul_get_msg("BEGENDCHARS",0)) == NULL) return(1);
  begin_char = *temp_ptr;
  end_char = *(temp_ptr+1);

  chng_msg0 = ul_get_msg("CHNGSTAT",0);	//
  chng_msg1 = ul_get_msg("CHNGSTAT",1); //
  chng_msg2 = ul_get_msg("CHNGSTAT",2); //
  chng_msg3 = ul_get_msg("CHNGSTAT",3); //

  if(no_switches) {
    insdisk_tag = "INSDISK2";
    }
  else {
    insdisk_tag = "INSDISK1";
    }

  return(0);
  }

/*======================================================================
;,fs
; void init_msg_system(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void init_msg_system(void) {


  switch(ul_init_msg(msg_file)) {
  case 0:
    break;

  case ul_msg_er_memory:
    puts("Error: Insufficient memory for message file");  /* @@XLAT */
    exit(1);

  case ul_msg_er_invf:
    puts("Error: Message file format is invalid");  /* @@XLAT */
    exit(1);

  case ul_msg_er_open:
    printf(
    "Error: Message file open failure\n"			/* @@XLAT */
    "The files HDSETUP.MSG and HDSETUP.HLP must reside\n"	/* @@XLAT */
    "within the same directory as HDSETUP.EXE\n"		/* @@XLAT */
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
  }

/*======================================================================
;,fs
; void check_mosdos(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void check_mosdos(void) {


  // check for mos/dos.  ok to run under any dos or under mos 5.01 or newer.
  // the mlg->dlg conversion logic would have problems with an older
  // version of mos.

  regs.x.ax = 0x3000;
  regs.x.bx = 0x3000;
  regs.x.cx = 0x3000;
  regs.x.dx = 0x3000;
  int86x(0x21,&regs,&regs,&sregs);
  mos_version = regs.x.ax;
  regs.x.ax = 0x3000;
  regs.x.bx = 0;
  int86x(0x21,&regs,&regs,&sregs);
  dos_version = regs.x.ax;
  if(dos_version != mos_version) {
    if((mos_version & 0xff) < 5) {
      puts("Error: Must be run under MOS 5.01");  /* @@XLAT */
      exit(1);
      }
    }
  }

/*======================================================================
;,fs
; void check_msys(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void check_msysm(void) {

  byte *temp_ptr;
  FILE *source;


  // check for msys/m in the home directory

  if((temp_ptr = malloc(512)) == NULL) {
    puts("Error: Insufficient memory");  /* @@XLAT */
    exit(1);
    }
  if((source = fopen(msys_file,"rb")) != NULL) {
    if(fread(temp_ptr,512,1,source) == 1) {
      if(strncmp(temp_ptr+3,MSYS_SIGNATURE,MSYS_SIGLEN) == 0) {
        found_msysm = 1;
        }
      }
    }
  free(temp_ptr);
  fclose(source);
  }

/*======================================================================
;,fs
; void mlgs2ext(pr_type *prptr, dr_type *drptr)
; 
; for the hdsetup /k logic.  delete mlg-s partitions and try to
; replace them with extended.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
void mlgs2ext(pr_type *prptr, dr_type *drptr) {

  byte dm_ndx;
  byte x;
  byte y;
  byte t1;
  byte more_ext_possible;
  byte p;
  dm_type dm_array[3];
  pr_type *pr1;


  dm_ndx = 0;
  for(t1=1;t1<4;t1++) {
    if(prptr->prE[t1].MLG) {

      // record the partition data in the dm_type array

      dm_array[dm_ndx].dmDriveLetter = prptr->prE[t1].DriveLetter;
      dm_array[dm_ndx].dmCylds = derive_cylds(prptr,t1);
      dm_ndx++;

      // delete the partition

      compress_mbrpt(prptr,t1);
      changed_memory = 1;
      }
    }

  // update the display after the deletions

  gen_lr_list();
  display_lr_list();
  display_cmd_box(F1_FLAG);
  display_stats(st_prdlmlgs);

  // if any mlg-s partitions were deleted, try to add extended
  // partitions in their place.

  for(t1=0;t1<dm_ndx;t1++) {

    /* to add an extended, if none, need free slot and any gap.  if any
    extended already, need a qualifying gap. */

    update_no_ext(prptr);
    more_ext_possible = 0;
    if(no_ext) {
      p = prptr->prE[1].PT.peFileSystem;
      p |= prptr->prE[2].PT.peFileSystem;
      p |= prptr->prE[3].PT.peFileSystem;
      if(p == 0 && find_largest_gap(FIND_PRI) != NULL) {
        more_ext_possible = 1;
        }
      }
    else {
      if(find_largest_gap(FIND_EXT) != NULL) {
        more_ext_possible = 1;
        }
      }

    // then, the gap must not be less that the number of cylinders 
    // that were in the deceased mlg-s partition.

    if(more_ext_possible) {
      add_ext_helper1();
      if(new_cylds_max < dm_array[t1].dmCylds) {
        more_ext_possible = 0;
        }
      }

    // if get here and more_ext_possible is true, can call 
    // ext_helper2() to create the extended partition.

    if(more_ext_possible) {
      new_cylds = dm_array[t1].dmCylds;
      pr1 = ext_helper2(prptr,drptr);
      assign_letter = START_LETTER;
      trace_tree(&drvltrs_work,NULL);

      // update the display after each addition

      gen_lr_list();
      display_lr_list();
      display_cmd_box(F1_FLAG);
      display_stats(st_prdlmlgs);

      // report the old and new drive letters

      ul_disp_msg(1,PM_LINE,cmd_attr,"MLGS2EXT1",0);
      ul_get_xy(&x,&y);
      ul_char2video(x,y,cmd_attr,' ');
      ul_char2video(x+1,y,cmd_attr,dm_array[t1].dmDriveLetter);
      ul_disp_msg(x+2,PM_LINE,cmd_attr,"MLGS2EXT2",0);
      ul_disp_msg(1,PM_LINE+1,cmd_attr,"MLGS2EXT2A",0);
      ul_get_xy(&x,&y);
      ul_char2video(x,y,cmd_attr,' ');
      ul_char2video(x+1,y,cmd_attr,pr1->prE[0].DriveLetter);
      ul_char2video(x+2,y,cmd_attr,':');
      ul_get_xy(&x,&y);
      ul_disp_msg(1,y+2,cmd_attr,"MLGS2EXT3",0);
      ul_eat_key();
      ul_get_key();

      }
    else {

      // report that the partition could not be automatically replaced

      ul_disp_msg(1,PM_LINE,cmd_attr,"MLGS2EXT1",0);
      ul_get_xy(&x,&y);
      ul_char2video(x+1,y,cmd_attr,dm_array[t1].dmDriveLetter);
      ul_disp_msg(x+2,PM_LINE,cmd_attr,"MLGS2EXT4",0);
      ul_disp_msg(1,PM_LINE+1,cmd_attr,"MLGS2EXT4A",0);
      ul_eat_key();
      ul_get_key();
      }
    }
  }

//=========================================================
//======================================= MAIN FUNCTION
//=========================================================

int main(int argc, char *argv[]) {

  byte retcode;


  global_argv[0] = argv[0];		// needed by spawn

  // prepare the filename strings with homepath

  strcpy(home_path,argv[0]);
  *(strrchr(home_path,'\\')+1) = 0;
  strcpy(help_file,home_path);
  strcat(help_file,HELP_FNAME);
  strcpy(msg_file,home_path);
  strcat(msg_file,MSG_FNAME);
  strcpy(msys_file,home_path);
  strcat(msys_file,MSYS_FNAME);

  parse_switches(argc,argv);		// parse parameter switches
  if(s_switch == 0) {
    init_video();			// init video
    ul_clr_box(0,0,79,24,main_attr);
    ul_set_cursor(0,0);
    printf("Reading disk information, Please wait.\n");	/* @@XLAT */
    ul_set_gkhook(hook_func);		// init keyboard hook for f1
    }
  init_msg_system();			// init message system
  check_msysm();			// check for msys/m
  check_mosdos();			// check dos/mos versions

  // build the database of disk information

  if(build_tree()) {
    exit(1);
    }
  edit_dr = Root_dr;
  edit_mbrpt = edit_dr->drPR;

  // assign the origdriveletter field within each pr_type record

  dup_drvltr = 1;
  assign_letter = START_LETTER;
  trace_tree(&drvltrs_work,NULL);
  dup_drvltr = 0;

  // when parameter switches were used, manual mode

  if(no_switches) {
    manual_mode();	// note -- will never return from manual_mode()
    }

  // the /n switch is for install new mos system

  if(n_switch) {
    retcode = prompt_review("PD_PROMPT",st_prdlal);
    if(retcode == escape || retcode == no_char) {
      exit(0);
      }
    if(retcode != 0) {
      if(hard_drives == 2) {
        force_d2();
        delete_all_guts();		// delete partitions on drive 2
        force_d1();
        }
      delete_all_guts();		// delete partitions on drive 1
      }
    lead_through = LT_NSWITCH;
    manual_mode();	// note -- will never return from manual_mode()
    }

  // the /d switch is for install new dual dos/mos system

  if(d_switch) {
    retcode = prompt_review("PD_PROMPT",st_prdlal);
    if(retcode == escape || retcode == no_char) {
      exit(0);
      }
    if(retcode != 0) {
      if(hard_drives == 2) {
        force_d2();
        delete_all_guts();		// delete partitions on drive 2
        force_d1();
        }
      delete_all_guts();		// delete partitions on drive 1
      }
    lead_through = LT_DSWITCH;
    manual_mode();	// note -- will never return from manual_mode()
    }

  // the /s switch is to produce a summary report file

  if(s_switch) {
    if((sum_file = fopen(SUMMARY_FNAME,"w")) == NULL) {
      printf("\n\nError creating summary file\n");
      exit(1);
      }
    fprintf(sum_file,
    "; hard  pt  pt     pt    drive  boot               start end   false\n"
    "; drive num entry  type  letter status megs  cylds cyld  cyld  ebpb\n"
    "; ===== === ===== ====== ====== ====== ===== ===== ===== ===== =====\n"
    );
    trace_tree(&gen_summary_work,NULL);
    fclose(sum_file);
    exit(0);
    }

  // the /k switch is to delete all mlg-s partitions

  if(k_switch) {
    if(prompt_review("MLGSDEL",st_prdlmlgs) != yes_char) {
      ul_cls(main_attr);
      exit(0);
      }
    clr_prompt_win();
    changed_memory = 0;
    force_d1();
    mlgs2ext(Root_dr->drPR,Root_dr);
    if(Root_dr->drNext != NULL) {
      force_d2();
      mlgs2ext(Root_dr->drNext->drPR,Root_dr->drNext);
      }
    if(changed_memory) {
      gen_lr_list();
      display_lr_list();
      write_and_boot();
      }
    ul_cls(main_attr);
    exit(0);
    }

  // the /c switch is to convert all mlg-p partitions

  if(c_switch) {
    if(prompt_review("MLG2DLG",st_prdlmlgs) != yes_char) {
      ul_cls(main_attr);
      exit(0);
      }
    changed_memory = 0;
    if(found_msysm) {
      if(hard_drives == 2) {
        force_d2();
        gen_lr_list();
        if(edit_pr->prE[0].MLG) {
          changed_memory = 1;
          edit_pr->prE[0].PT.peFileSystem = derive_PTC(edit_dr,edit_lr->lrCylds);
          edit_pr->prE[0].NeedMSYS = 1;
          edit_pr->prE[0].MLG = 0;
          }
        force_d1();
        }
      gen_lr_list();
      if(edit_pr->prE[0].MLG) {
        changed_memory = 1;
        edit_pr->prE[0].PT.peFileSystem = derive_PTC(edit_dr,edit_lr->lrCylds);
        edit_pr->prE[0].NeedMSYS = 1;
        edit_pr->prE[0].MLG = 0;
        }
      }
    if(changed_memory) {
      gen_lr_list();
      display_lr_list();
      write_and_boot();
      }
    ul_cls(main_attr);
    exit(0);
    }
  return(0);
  }


