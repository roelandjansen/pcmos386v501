/**********************************************************************
*
*     MODULE NAME:        RSA.H
*
*     TASK NAME:          none
*
*     MODULE REVISED:     1/15/91
*
*     PROJECT:            Baseline utilities
*
*     PROGRAMMER:         B. W. Roeser
*
*     CREATION DATE:      3/28/89
*
*
*       (C) Copyright 1989-1991 - Bruce W. Roeser
*                   All Rights Reserved
*
*---------------------------------------------------------------------
*
* MODULE FUNCTION:      Header file containing definitions for routines
*                   in RSA libraries (SMALL_C and LARGE_C)
*
*---------------------------------------------------------------------
*
*                         >> REVISION LOG <<
*
* REV DATE  PROG    DESCRIPTION OF THIS REVISION
* --------  ----    ----------------------------
* 7/12/90   BWR     Final code inspection for release 1.0 of RSA Custom
*                   Software User Interface Library. (RSACLIB)
*                   All library routines are now prototyped in this
*                   header file.
*
* 7/20/90   BWR     New routine, "setup_i24()" added to library.
*
* 8/2/90    BWR     Function USR_message now returns a value.
*
* 9/11/90   BWR     Added prototypes for Expanded Memory Manager
*                   functions as well as standard manifests and
*                   typedefs.
*
* 1/14/91   BWR     Added definitions for routines "compress_file" and
*                   "expand_file".
*
* 1/15/91   BWR     Code cleanup.
*
**********************************************************************
*
*/

/************ COMMENTED OUT !

#ifndef FILE
#define FILE struct _iobuf
#endif

#define _iobuf FILE

*****************************/
/* #define FOREVER while(1) */
#define TRUE    -1
#define FALSE   0

typedef unsigned char   BOOL;
typedef unsigned char   BYTE;
typedef unsigned        WORD;
typedef unsigned long   DWORD;
/*
    Function prototypes.

struct FILE        *da_open(char *, char *, int);
*/
long        get_file_size(char *);
long        segment_to_absolute(long);

unsigned    get_video_address();
unsigned    hash(char *);

int         compress_file(char *, char *, int);
int         conred(char *, int, int, int);
int         convert_to_mono(int);
int         copy_file(char *, char *);
int         count_matching_files(char *);
/*int         da_close(struct FILE *);
int         da_read(struct FILE *, void *, unsigned);
int         da_write(struct FILE *, void *, unsigned);*/
int         display_help(char *, int);
int         expand_file(char *, char *, int);
int         get_string(char *, int, int);
int         htoi(char *);
int         index(char, char *);
int         is_color_video();
int         rdcpos();
int         read_mouse(int, int *, int *, int *);
int         readed(int, int, int, int, int, void *);
int         restore_video_region(int, int, void *);
int         select_option(int, int, char **, int, char *, char *, unsigned char);
int         USR_connect(char *, char *);
int         USR_menu(int, int);
int         USR_message(int, char **, int, int, int);
int         USR_read(int, void *, int, int);
int         USR_write(int, void *, int, int);

void far    *absolute_to_segment(long);
void far    *normalize_address(unsigned unsigned);
void        center(char *, unsigned);
void        convert_tabs(char *, char *, int, int);
void        cursor_off();
void        cursor_on();
void        delay(int);
void        display_copyright(char *);
void        dputs(char *);
void        draw_box(int, int, int, int, int);
void        dump_buffer_to_screen(void *, int);
/*void        ffill(struct FILE *, char, unsigned);*/
void        gtime(int *);
void        input(char *, char *);
void        just(char *, int, int);
void        put_cpos(int);
void        put_field(int, int, int, int, int, void *);
void        putscr(void *, int);
void        read_DTA(void *, int);
void        *save_video_region(int, int);
void        scr(int, int, int, int);
void        scroll(int, int, int, unsigned, int);
void        set_standard_colors();
void        setup_i24();
void        squeeze(char *, int);
void        squeezen(char *, int, int);
void        strip_leading_blanks(char *);
void        strip_trailing_blanks(char *);
void        update_time_and_date();
void        USR_clear(int);
void        USR_clear_message( void );
void        USR_disconnect();
void        wait_for_key(char *, char *);
void        write_DTA(void *, int);
void        zap(void *, unsigned, char);

char        *strstri(char *, char *);
/*char        *get_line(char *, int, struct FILE *);*/
/*
    Expanded Memory Manager function prototypes.
*/
int     EMM_present(void);                  /* EMM_PRES.C */
int     EMM_status(void);                   /* EMM_40.C */
void far *EMM_get_page_frame(void);         /* EMM_41.C */
int     EMM_get_page_count(int *, int *);   /* EMM_42.C */
int     EMM_allocate_pages(int, int*);      /* EMM_43.C */
int     EMM_map_page(int, int, int);        /* EMM_44.C */
int     EMM_free_pages(int);                /* EMM_45.C */
int     EMM_get_version(int *);             /* EMM_46.C */
int     EMM_save_page_map(int);             /* EMM_47.C */
int     EMM_restore_page_map(int);          /* EMM_48.C */
int     EMM_get_handle_count(int *);        /* EMM_4B.C */
int     EMM_get_handle_pages(int, int*);    /* EMM_4C.C */
int     EMM_get_handle_map(int *, void *);  /* EMM_4D.C */
int     EMM_get_page_map(void *);           /* EMM_4E.C  - F: 4E00 */
int     EMM_set_page_map(void *);           /* EMM_4E.C  - F: 4E01 */
int     EMM_get_set_page_map(void *, void *); /* EMM_4E.C - F: 4E02 */
int     EMM_get_page_map_size(int *);       /* EMM_4E.C  - F: 4E03 */
