#ifndef asmtypes
#include "asmtypes.h"
#endif

#define box_none	0
#define box_single	1
#define box_double	2

#define ul_msg_max_lines	25
#define	ul_msg_max_tags		100

#define ul_msg_er_memory	101	// out of far heap
#define ul_msg_er_invf		102	// invalid message file
#define ul_msg_er_open		103	// file open error

#define ul_max_view_cols 80

/*==== conversion values for extended keystrokes */

#define escape		0x1b
#define enter		0x0d
#define tab		0x9
#define backspace	0x8
#define spacebar	0x20
#define f1		0x3b + 0x80
#define f2		0x3c + 0x80
#define f3		0x3d + 0x80
#define f4		0x3e + 0x80
#define f5		0x3f + 0x80
#define f6		0x40 + 0x80
#define f7		0x41 + 0x80
#define f8		0x42 + 0x80
#define f9		0x43 + 0x80
#define f10		0x44 + 0x80
#define up_arrow	0x48 + 0x80
#define down_arrow	0x50 + 0x80
#define left_arrow	0x4b + 0x80
#define right_arrow	0x4d + 0x80
#define home		0x47 + 0x80
#define end		0x4f + 0x80
#define pgup		0x49 + 0x80
#define pgdn		0x51 + 0x80
#define ins		0x52 + 0x80
#define del		0x53 + 0x80
#define gray_minus	0x4a + 0x80
#define gray_plus	0x4e + 0x80

typedef struct _twin {
	int xl;
	int yt;
	int xr;
	int yb;
	int x_coord;
	int y_coord;
	char far *winptr;
	} twin;

typedef twin far *wintype;


// direct video display functions

void ul_set_vidptr(word vid_seg, word rows, word cols);
word ul_get_vidseg(void);
void ul_char2video(byte x, byte y, byte vidattr, byte vchar);
void ul_str2video(byte x, byte y, byte vidattr, byte *st, byte transflag);
void ul_clr_box(byte xl, byte yt, byte xr, byte yb, byte vidattr);
void ul_cls(byte vidattr);
void ul_draw_box(byte xl, byte yt, byte xr, byte yb, byte vidattr, byte boxtype);
void ul_draw_hbar(byte xl, byte y, byte xr, byte vidattr, byte boxtype);
void ul_draw_vbar(byte x, byte yt, byte yb, byte vidattr, byte boxtype);
void ul_scroll_lines_up(byte xl, byte yt, byte xr, byte yb, byte vidattr);
void ul_scroll_lines_down(byte xl, byte yt, byte xr, byte yb, byte vidattr);
void ul_set_attr(byte xl, byte y, byte xr, byte vidattr);
void ul_fill_box(byte xl, byte yt, byte xr, byte yb, byte vidattr, byte fillchar);

// number display

void ul_display_decimal(word val, byte x, byte y, byte vidattr, byte width);

// cursor control

void ul_set_cursor(byte x, byte y);
word ul_get_cursor(void);
void ul_get_xy(byte *xptr, byte *yptr);

// window management

void ul_save_window(int x, int y, int xm, int ym, void far *saveptr);
void ul_restore_window(int x, int y, int xm, int ym, void far *saveptr);
wintype ul_open_window(byte xl,byte yt,byte xr,byte yb,byte vattr1,byte vattr2,byte boxtype);
void ul_close_window(wintype win);

// file viewing

byte ul_view(byte *fname, byte *msg1, byte *msg2, byte vattr);

// keyboard input functions

byte ul_get_key(void);
byte ul_if_key(void);
void ul_eat_key(void);
byte ul_get_key_set(byte *xset);
void ul_set_gkhook(byte (*new_filter_func)());
byte ul_get_string(byte x, byte y, byte vattr, byte string[], word count, byte *allowed_punc);
byte ul_get_choice(byte x, byte y, byte vidattr, byte ch1, byte ch2);

// message functions

byte ul_init_msg(byte *fname);
byte *ul_get_msg(byte *scan, word line_index);
byte ul_get_msgcnt(byte *scan);
word ul_disp_msg(word x, word y, byte vidattr, byte *srchtag, byte tranflag);

// directory tracing functions

typedef struct fspec_data {
 byte *search_spec;
 byte search_attr;
 word (*work_func)(byte *, byte *, byte);
 } fspc_type;

word ul_trace_dir(byte *dpbuf, fspc_type *fsptr);
word ul_trace_dirl(byte *dpbuf, fspc_type *fsptr);
word ul_walk_tree(byte *dpbuf, byte *fspec, word (*work_func)(byte *, byte *, byte));

// misc functions

void ul_beep(void);
byte ul_any_files(byte *filespec, byte search_attr);
byte ul_remove_files(byte *filespec, byte search_attr);
byte ul_expand_tabs(byte *eptr, byte ts, word maxlen);
long ul_getfilesize(byte *file_name);
word ul_ismos(void);
word ul_makepath(byte *path);
void ul_write_dsklbl(byte drvltr, byte *lbl);
void ul_read_dsklbl(byte drvnum, byte *lbuf);
byte ul_form_template(byte *filespec, byte *template);
byte ul_qualify_template(byte *n1, byte *n2);


