#include <stdio.h>
#include <malloc.h>
#include <stdlib.h>
#include <ctype.h>
#include <dos.h>
#include <signal.h>
#include <rsa\keycodes.h>
/*
*****************************************************************************
*
*   Module name:        main
*
*   Task name:          ED.EXE
*
*   Creation date:      12/26/86
*
*   Revision date:      5/24/90
*
*   Author:             Stuart Warren
*
*   Description:        PC-MOS generic text editing utility
*
*
*               (C) Copyright 1990, The Software Link Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      ED filename
*
*   Notes:
*
*       1) Build ED.EXE using ED.C and applications library RSACLIB.LIB
*          as follows:
*
*           cl -c -AL ed.c
*           link ed,,,rsaclib
*
*****************************************************************************
*                           >> Revision Log <<
*
* Date      Prog    Description of Revision
* ----      ----    -----------------------
* 10/22/87  JSM     Fixed problems with deleting characters on line
*                   25, creating extra lines in visual mode, killing
*                   lines which don't end in carriage returns, and
*                   assigning function key values which muck up the
*                   display routines.
*
* 10/28/87  JSM     Replaced calls to getch() with calls to inkey()
*                   since getch() calls int 16h/1 and inkey() calls
*                   int 16h/0.  Also fixed call to ungetc().
*
* 1/29/89   RKG     Accept foreign characters.  Function keys mapped
*                   to graphics characters.  This allows foreign
*                   language characters to be entered and keystroke
*                   storage only stores one character even if a
*                   special function key.
*
* 11/26/89  SAH     Converted to format compatible with Microsoft C
*                   version 5.10 and sped up screen handling and
*                   cursor positioning.
*
* 3/13/90   BWR     Code cleanup and performance enhancements.  Several
*                   routines written in assembler are unecessary and
*                   have been removed.
*
*                   1) Inkey rewritten to return standard keycodes and
*                   Extended keycodes as defined by IBM standard. Routine
*                   is now Read_key instead.
*
*                   2) All MASM routines in EDASM.ASM have been converted
*                   to C routines and are now part of ED.C.
*
*                       ***ED.C is still undergoing changes, but is stable
*                       and operational.  More changes (below) will be made
*                       later.
*
*
*   Note:
*
*   Among the performance enhancements needed:
*
*   1) Allow the file's lines to be more than 80 characters long.  Instead
*   of wrapping them, let them go off the right-hand side of the screen and
*   provide the ability to move the edit window over there.
*
* 3/28/90   BWR     Marked messages for foreign language translation.
*
* 4/25/90   BWR     Continuing enhancement.  Problem with search/replace
*                   function corrected.
*
* 5/3/90    BWR     ED is now built in LARGE model of Microsoft C and
*                   links to RSA Custom Software C library package
*                   (LARGE_C.LIB)
*
* 5/24/90   BWR     Fixed problem with entering into the visual-edit
*                   mode multiple times.  Program was not keeping
*                   track of current line properly, causing weird
*                   effects when trying to edit what was thought to
*                   be the current line.  Numerous other "bugs" fixed.
*
*****************************************************************************
*/
#define FOREVER     while(1)

#define LINE_LEN    132     /* max length of strings */
#define STAT_LEN     2      /* status line length */
#define SCR_WIDTH   80      /* max screen width */
#define SCR_LEN     24      /* max screen length */
#define TXT_LEN     (SCR_LEN-STAT_LEN)     /* max lines of text */
#define MAX_STK      6      /* command param stack depth */
#define MAX_KEY     10      /* maximum number of function keys */
/*
+-----------------------------------------------------------------------------
|   The following definitions correspond to the values returned by
|   InputKey().
+-----------------------------------------------------------------------------
*/
#define TRUE      1
#define FALSE     0
/*
+-----------------------------------------------------------------------------
|   All structure definitions follow.
+-----------------------------------------------------------------------------
*/
struct tpb {                    /* text pointer block       */
    struct tpb *prev;           /* pointer to previous line tpb */
    struct tpb *next;           /* pointer to next line tpb     */
    char lf;                    /* linefeed flag            */
    char text[LINE_LEN+1];      /* Text line */
};

struct tpb *first;          /* static first line structure */
struct tpb *last;           /* static last line structure */
struct tpb *current;        /* current line TPB */
struct tpb *topline;        /* pointer to top line displayed */
struct tpb *tmp;            /* temporary tpb pointer */


FILE    *fp_in;             /* input file stream */
FILE    *fp_out;            /* output file stream */
FILE    *fp_keys;           /* output file for keyboard save */
char    *ptr;               /* generic chr pointer */
char    cmd_buf[LINE_LEN+1];/* command buffer */
char    buffer[LINE_LEN+1]; /* text buffer */
char    work_buf[256];      /* Work buffer */
char    inpname[65];        /* input filename */
char    outname[65];        /* output filename */
char    fkey[MAX_KEY];      /* function key translation table */
char    srch[LINE_LEN+1];
char    rep[LINE_LEN+1];
char    yesmsg[] = "Yes   "; /* @@XLATN */
char    nomsg[] =  "No    "; /* @@XLATN */
unsigned char    key1;
unsigned char    key2;

int stack[MAX_STK];         /* stack storage area */
int visual;                 /* visual editing mode */
int insert;                 /* insert flag */
int changed;                /* changed flag - TRUE if  changed */
int lchanged;               /* line changed flag - TRUE if  changed */
int lines;                  /* current number of lines */
int cline;                  /* current line number */
int numbers;                /* number lines flag */
int row = 1;                /* current row */
int col = 1;                /* current col */
int tline;                  /* current top line number */
int ltline;                 /* last top line number */
int stkptr;                 /* stack pointer */
int question;               /* verify search params */
int tmpline;                /* last line number after select_line() */
int tmplf;                  /* temp lf flag */
int dirty;                  /* screen dirty flag */
int capture;                /* keyboard capture flag. */
int execute;                /* capture buffer execute flat */
int tab_size = 8;           /* Size of tab stops */

int save_execute=99;
int save_capture=99;
int save_insert=99;
/*
+-----------------------------------------------------------------------
| TopOfDoc() - Return TRUE if current line is the First line
| EndOfDoc() - Return TRUE if current line is the last line
+-----------------------------------------------------------------------
*/
#define TopOfDoc    (current->prev == first)
#define EndOfDoc    (current->next == last)
/*
+-----------------------------------------------------------------------
|   ED.C - Generic DOS-like editor program.
+-----------------------------------------------------------------------
|
|       Standard Commands
|
|   C - Copies lines        Q - Quit editing
|   D - Delete lines        R - Replace text
|   E - End editing         S - Search text
|   I - Insert lines        W - Write text
|   L - List lines          F - change output filename
|   M - Move lines          V - Visual editing mode
|
+-----------------------------------------------------------------------
*/
main(argc, argv)

int     argc;
char    *argv[];
{
    int     loop,i;

    if(argc < 2) {
        puts("Usage: ED [/V] [/T=n] filename  (Version 4.51)");
        exit(1);
    }
/*
    Get TAB size from environment, set default values, etc.
*/
    Initialize();

    for(i=1; i<argc; ++i) {
        if(!strcmpi(argv[i], "/V"))
            visual = TRUE;
        else if(!strnicmp(argv[i], "/T=", 3)) {
            tab_size = atoi(&argv[i][3]);
            if(!tab_size) {
                printf("ED.EXE: Invalid parameter on /T option.\n");
                exit(1);
            }
        }
        else {
            strcpy(inpname, argv[i]);
            strcpy(outname, argv[i]);
            strupr(inpname);
            strupr(outname);
        }
    }

    scr(0,0,0,7);
    puts("PC-MOS Text Editor (Version 4.50)"); /* @@XLATN */
    puts("Copyright (C) 1987-1990, The Software Link, Inc."); /* @@XLATN */
    puts("All Rights Reserved.\n"); /* @@XLATN */
    printf("Loading %s. Please wait.... ", inpname); /* @@XLATN */
/*
    Read initial part of file.
*/
    File_open();
    scr(0,0,0,7);
    status_line();
    tline = 1;

    if(visual == TRUE) {
        question = FALSE;
        changed |= visual_edit();
    }
    else {
        if (lines > 0)
        v_display(tline);   /* display initial text */
    }

    locate(1,1);
    loop = TRUE;
    while (loop) {
        zap(buffer, LINE_LEN+1, '\0');
        top_line();
        if (edit_line())
        loop = Process_command();
    }
    cls(1,1,25,80);
    locate(1,1);
    exit(0);
}
/*
+-----------------------------------------------------------------------
|   Process_command() - Parse user's command string and perform cmds.
+-----------------------------------------------------------------------
*/
int Process_command()
{
    int i,j,k,x,y,z;
    char rkey;

    i = 0;
    visual = FALSE;
    question = FALSE;
    strcpy(cmd_buf,buffer);
    if (strlen(cmd_buf) > 0) {
        while (cmd_buf[i] != '\0') {
            switch(toupper(cmd_buf[i])) {

                case ' ' :  /* skip all spaces quickly (opt) */
                    break;

                case '?' :  /* select verified search */
                    question = !question;
                    break;

                case 'A' :  /* assign fkey values */
                    assign_fkey();
                    v_display(cline);   /* re-display current text screen */
                    break;

                case 'C' :  /* Copy lines */
                    changed |= copy_line();
                    stkptr = 0;
                    break;

                case 'D' :  /* Delete block of lines */
                    changed |= delete_block();
                    break;

                case 'E' :  /* End editing */
                    if (changed) {      /* if file has changed */
                        if (file_write())   /* and it write OK */
                        return(FALSE);  /* return exit OK */
                    } else {            /* otherwise */
                        return(FALSE);      /* return if no changes made */
                    }
                    break;

                case 'F' :  /* Specify filename */
                    i++;    /* step past 'F' char */
                    j=0;    /* set outname pointer */
                    while (cmd_buf[i] != ' ' && cmd_buf[i] != ',' &&
                            cmd_buf[i] != '\0') {
                        outname[j++] = cmd_buf[i++];
                        outname[j]='\0';
                    }
                    status_line();      /* re-display output filename */
                    changed = TRUE;     /* force a write on exit */
                    break;


                case 'H' :  /* command mode help */
                    c_help_screen();
                    break;

                case 'I' :  /* Insert lines */
                    if (stkptr == 1)    /* if pushed param */
                    cline = xrange(pop_stack());
/*
    Remember original line number
*/
                    zap(buffer, LINE_LEN+1, '\0');
                    top_line();
                    printls(2,1,"Insert Line   ");/* @@XLAT */
                    if (edit_line()) {
                        if (cline > lines + 1)
                        cline = lines + 1;
                        if (select_line(cline, TRUE))
                        current = tmp;
                        changed |= insert_line();
                        ++cline;        /* move down to next line */
                        current->lf = TRUE;   /* assert LF */
                    }
                    stkptr = 0;
                    status_line();  /* redraw status line */
                    break;

                case 'L' :  /* List lines on screen */
                    if (stkptr == 0)
                        tline = cline;
                    else {
                        tline = pop_stack();
                        if (tline < 1)
                            tline = 1;
                        if (tline > lines)
                            tline = lines-1;
                    }
                    v_display(tline);
                    cline = tline;
                    select_line(cline, FALSE);
                    current = tmp;
                    row = col = 1;
                    stkptr = 0;
                    break;

                case 'M' :  /* Move lines */
                    changed |= move_line();
                    break;

                case 'P' :  /* print current text file to printer */
                    print_doc();
                    break;

                case 'Q' :  /* Quit editing */
                    if (changed) {
                        printls(1,1,"Save changes? (Y/N/ESC): ");/* @@XLATN */
                        rkey = Prompt();
                        if (rkey == *yesmsg) {
                            if (file_write())
                                return(FALSE);
                        }
                        else if (rkey == ESC)
                            return(TRUE);
                        else
                            return(FALSE);
                    }
                    else
                        return(FALSE);

                    break;

                case 'R' :  /* Replace lines */
                    changed |= search_line(TRUE);
                    break;

                case 'S' :  /* search text */
                    search_line(FALSE);
                    break;

                case 'W' :  /* write lines to file */
                    if (file_write())
                        changed = FALSE;
                    break;

                case 'V' :  /* enable visual text editing */
                    changed |= visual_edit();   /* do visual editing */
                    break;

                case 'X' :  /* Execute contents of key file */
                    if (capture){   /* are we in capture mode? */
                        capture = FALSE;    /* disable capture mode */
                        fclose(fp_keys);    /* close input file */
                    }
                    if (fp_keys = fopen("ED.KEY","r+b")) {
                        execute = TRUE; /* enable execute mode */
                        changed |= visual_edit();   /* enter visual mode */
                    }
                    break;

                case '0' :  /* parse number from command line */
                case '1' :  /* push on command LIFO stack*/
                case '2' :
                case '3' :
                case '4' :
                case '5' :
                case '6' :
                case '7' :
                case '8' :
                case '9' :
                    i = get_num(i);
                    break;

                case '.' :  /* indicate current line */
                    strcpy(buffer,current->text);
                    if (edit_line()) {
                        strcpy(current->text,buffer);
                        changed = TRUE;
                    }
                    stkptr = 0;
                    break;

                case ';' :  /* Skip rest of line after ; (opt) */
                    zap(buffer, LINE_LEN+1, '\0');
                    stkptr = 0;
                    break;

                default :
                    break;

            }
            i++;
        }
        if (stkptr == 1) {   /* if there is another number on stack */
            cline = pop_stack();    /* then perform edit on line and */
            if (cline < 1)
            cline = 1;
            if (cline > lines)
            cline = lines-1;
            if (select_line(cline, FALSE)) {
                strcpy(buffer,tmp->text);
                if (edit_line()) {   /* leave cline with current line */
                    strcpy(tmp->text,buffer);
                    changed = TRUE;
                }
            }
        }
    }
    stkptr = 0;
    return(TRUE);
}

/*
+-----------------------------------------------------------------------
|   visual_edit() - Perform visual editing.
+-----------------------------------------------------------------------
|   Escape key ends visual mode.
|
|   Commands:
|
|   ^A - Assign Fkeys                   ^W - Write file to disk
|   BKSPCE - Backspace (destructive)    ^Y - Delete current line
|   TAB -                               ESC - exit visual mode
|   ^L - Locate line (n)                RIGHT - Move cursor right
|   RETURN -                            LEFT - Move cursor left
|   ^P - Print document                 HOME - Move cursor to SOL
|   ^Q - Display Help Screen            END - Move cursor to EOL
|   ^R - Replace string fn              UP - Move cursor up one line
|   ^S - Search for string              DOWN - Move cursor down line
|   PgUp - Skip backward 1 page         ^PgUp - Move to top of file
|   PgDn - Skip forward 1 page          ^PgDn - Move to end of file
|   Delete - Delete char at cursor      Insert - Toggle insert mode
|
+-----------------------------------------------------------------------
*/
int visual_edit()
{
    int i, j, k, l;
    int ret;
    struct  tpb *new,*n;

    ret = FALSE;
    visual = TRUE;      /* indicate visual editing mode */
/* BWR */
/*    current = first->next;    /* start with first line */

    if ((first->next == last->prev && !strlen(first->next->text)) ||
            (first->next == last && last->prev == first)) {
        new = (struct tpb *) calloc(1,sizeof(struct tpb));
        first->next = new;
        new->prev = first;
        new->next = last;
        last->prev = new;
        current = new;
        current->lf = FALSE ;
        lines=1;
    }
    v_display(tline);       /* display first page of text */

    while (visual) {
        top_line();                 /* display top status line */
        locate(row+STAT_LEN,col);  /* locate cursor on active line */
        InputKey();                 /* get a key from consle */
        locate(row+STAT_LEN,col);  /* locate cursor on active line */
/*
    Handle function keys entered.
*/
        if(key1 == FKEY) {
            switch(key2) {
                case RIGHT:
                    if (col < SCR_WIDTH)
                        col++;
                    break;
                case LEFT:
                    if (col > 1)
                        col--;
                    break;
                case HOME:
                    col = 1;
                    break;
                case END:
                    col = strlen(current->text)+1;
                    break;
                case UP:
                    up_line();
                    break;
                case DOWN:
                    down_line(FALSE);
                    break;
                case PGUP:
                    if (tline > TXT_LEN) {
                        cline -= TXT_LEN;
                        tline -= TXT_LEN;
                    }
                    else {
                        cline = 1;
                        row = 1;
                        tline = 1;
                    }
                    v_display(tline);
                    select_line(cline, FALSE);
                    current = tmp;
                    break;
                case PGDN:
                    if(lines <= TXT_LEN) {     /* if short file */
                        row = lines;
                        cline = row;
                    }
                    else {                      /* if we must scroll screen */
                        if((tline + TXT_LEN) <= lines) {    /* full screen */
                            tline += TXT_LEN;
                            cline += TXT_LEN;
                            v_display(tline);
                            cline = range(cline);
                            if (row - 1 + cline > lines)
                                row = lines - tline + 1;
                        }
                        else {      /* until we get to bottom of file */
                            cline = lines;
                            row = lines - tline + 1;
                        }
                    }
                    select_line(cline, FALSE);
                    current = tmp;
                    break;
                case CTRL_PGUP:
                    cline = tline = row = col = 1;
                    v_display(tline);
                    select_line(cline, FALSE);
                    current = tmp;
                    break;
                case CTRL_PGDN:
                    if(lines < TXT_LEN) {
                        tline = 1;          /* set top line counter */
                        row = cline = lines;    /* set current line * row */
                        col = 1;            /* set col */
                    }
                    else {
                        cline = lines;                  /* move to last line */
                        tline = lines - TXT_LEN + 1;    /* set top line ctr */
                        row = TXT_LEN;      /* set row number to last row */
                        col = 1;
                    }
                    v_display(tline);       /* display screen */
                    select_line(cline, FALSE);  /* set new current line */
                    current = tmp;          /* set current pointer */
                    break;
                case INS:
                    insert = !insert;
                    top_line();
                    break;
                case DEL:
                    if(strlen(current->text) >= col) {
                        n = current->next;
                        ret |= delete_char(row,col-1,current);
                        if (dirty)
                            p_display();
                    }
                    break;
/*
    If the user pressed one of the function keys, enter the
    character assigned to that key if defined.
*/
                case F1:
                case F2:
                case F3:
                case F4:
                case F5:
                case F6:
                case F7:
                case F8:
                case F9:
                case F10:
                    key2 = key2 - F1;       /* then map key to 0..9 */
                    if(fkey[key2])          /* if fkey is defined */
                        key2 = fkey[key2];  /* then return its value */
                    else
                        break;
/*
    If the key was defined, enter it into the text line as defined.
*/
                    if(insert) {
                        ret |= insert_char(row,key2,col-1,current);
                        if (dirty)
                            p_display();    /* do partial display */
                    }
                    else {
/* BWR 2/18/91 */
/*
** If the function key character was entered beyond the current end-of-line
** while in overlay mode, blank fill the line before entereing the text.
*/
                        l = strlen(current->text);
                        if(col > l) {
                            for(j=l; j<col-1; j++)
                                current->text[j] = ' ';
                        }
/* BWR 2/18/91 */
                        current->text[col-1] = key2;
                        locate(row+STAT_LEN,col);
                        putchar(key2);
                        ret = TRUE;
                    }
                    if (col < LINE_LEN) {   /* wrap cursor if at end. */
                        col++;
                    }
                    else {
                        col = 1;
                        down_line(TRUE);
                    }
            } /* End SWITCH */
        } /* End IF */
/*
    Non function keys.
*/
        else {
            switch(key1) {
                case CTRL_A:    /* ^A assign value to fkeys */
                    assign_fkey();
                    v_display(tline);
                    break;

                case CTRL_D:    /* ^D - Duplicate current line */
                    new = (struct tpb *) calloc(1,sizeof(struct tpb));
                    if (new) {
                        new->lf = current->lf || (current->next != last);
                        strcpy(new->text,current->text);
                        current->next->prev = new;
                        new->next = current->next;
                        current->next = new;
                        new->prev = current;
                        current->lf = TRUE;
                        lines++;
                        ret = TRUE;
                        p_display();
                    }
                    else {
                        beep();
                        printls(1,1,"Error: Out of memory!           ");/* @@XLATN */
                        wait_for_key(&key1, &key2);
                    }
                    break;

                case BS:
                    if (col > 1) {
                        col--;
                        ret |= delete_char(row,col-1,current);
                        if (dirty)
                            v_display(cline);
                    }
                    break;

                case TAB:
                    if (col < 72) {
                        if (insert) {
                            i = col + tab_size;
                            i -= (i-1) % tab_size;
                            if (i < LINE_LEN) {
                                for (j=col;j<i;j++)
                                    ret |= insert_char(row,' ',j-1,current);
                                if (dirty)
                                p_display();
                                col = i;
                            }
                        }
                        else {
                            col = col + tab_size;
                            col -= (col-1) % tab_size;
                        }
                    }
                    break;

                case CTRL_L:        /* ^L - Jump to Line number z */
                    printls(2,1,"Enter line number:     ");/* @@XLATN */
                    zap(buffer, LINE_LEN+1, '\0');
                    edit_line();
                    j = atoi(buffer);   /* convert it to integer */
                    if(j > 0) {         /* if number is greater than zero */
                        if(j > lines)   /* if past end of text */
                            j = lines;  /* then default to end of text */
                        v_display(j);   /* display text screen */
                        cline = j;      /* assign current line */
                        row = col = 1;  /* home edit cursor */
                        select_line(cline, FALSE); /* make this line current */
                        current = tmp;
                    }
                    status_line();      /* re-display the status line */
                    break;

                case ENTER:     /* return key */
                    if(insert)  /* if insert==true; then split line */
                        ret |= split_line(col);
                    down_line(TRUE);

                    col = 1;
                    break;

                case CTRL_N:        /* ^N - Split line at current cursor loc */
                    ret |= split_line(col);
                    break;

                case CTRL_O:        /* ^O - Output all keystrokes to key file */
                    if(!execute) {     /* are we in execute mode? */
                        if(capture) {   /* are we in capture mode? */
                            fclose(fp_keys);    /* close keystroke file */
                            capture = FALSE;    /* disable capture mode */
                        }
                        else {      /* create capture file */
                            if((fp_keys = fopen("ED.KEY","w+b")) != NULL)
                            capture = TRUE; /* enable capture mode */
                        }
                    }
                    break;

                case CTRL_P:        /* ^P - Print document to list device */
                    print_doc();
                    break;

                case CTRL_Q:        /* ^Q - Help screen */
                    help_screen();
                    break;

                case CTRL_R:        /* ^R - Search and replace function */
                    push_stack(cline);  /* start at current line */
                    question = TRUE;
                    ret |= search_line(TRUE);
                    question = FALSE;
                    break;

                case CTRL_S:        /* ^S - Search for occurence */
                    push_stack(cline);  /* start at current line */
                    question = TRUE;
                    search_line(FALSE);
                    question = FALSE;
                    break;

                case CTRL_W:        /* ^W - write file to output file */
                    if (file_write())
                    ret = FALSE ;
                    break;

                case CTRL_X:        /* ^X - Execute contents of key file */
                    if (capture) {  /* if capture is on the disable it */
                        fclose(fp_keys);    /* close capture file */
                        capture = FALSE;    /* disable capture mode */
                    }
                    execute = (fp_keys = fopen("ED.KEY","r+b")) != NULL;
                    /* open the key file & enable execution */
                    break;

                case CTRL_Y:        /* ^Y - delete current line */
                    if(current->next == last) { /* are we last line? */
                        if(lines == 1) {        /* only 1 line in file? */
                            zap(current->text, LINE_LEN+1, '\0');
                            col = 1;
                            cls(STAT_LEN+row,1,25,80);
                            current->lf = FALSE;
                        }
                        else {      /* delete last line */
                            new = current;
                            current->prev->next = current->next;
                            current->next->prev = current->prev;
                            current = current->prev;
                            free(new);
                            if (row > 1)
                            --row ;
                            --lines;
                            --cline;
                            p_display();
                        }
                    }
                    else {      /* if not last line delete current line. */
                        new = current;
                        current->prev->next = current->next;
                        current->next->prev = current->prev;
                        current = current->next;
                        free(new);
                        lines--;
                        p_display();
                    }
                    ret = TRUE; /* the file has been changed    */
                    break;

                case ESC:   /* escape key - Exit visual mode */
                    visual = FALSE;     /* exit loop */
                    break;

                default:
                    if (col > strlen(current->text))
                        for(j=strlen(current->text); j<col-1; j++)
                            current->text[j] = ' ';

                    if(isprint(key1)) {     /* if it's a valid keystroke */
                        if(insert) {
                            ret |= insert_char(row,key1,col-1,current);
                            if (dirty)
                                p_display();    /* do partial display */
                        }
                        else {
                            current->text[col-1] = key1;
                            locate(row+STAT_LEN,col);
                            putchar(key1);
                            ret = TRUE;
                        }
                        if (col < LINE_LEN) {   /* wrap cursor if at end. */
                            col++;
                        }
                        else {
                            col = 1;
                            down_line(TRUE);
                        }
                    }
                    break;
            } /* End SWITCH */
        }
    } /* End while(visual) */

    status_line();      /* re-display top status line */
    v_display(tline);   /* re-display screen */
    return(ret);
}               /* end of visual edit mode */

/*
+-----------------------------------------------------------------------
|   down_line(z) - Move cursor down one line, scroll screen if needed.
+-----------------------------------------------------------------------
|
|   if (f) is true then allow down_line to add a line as it goes down.
|   Otherwise stop at bottom of file.
|
+-----------------------------------------------------------------------
*/
down_line(f)
int f;
{
    struct tpb *new;
    int i;

    if (cline >= lines && f) { /* if at EOF and flag is true */
        new = (struct tpb *) calloc(1,sizeof(struct tpb));
        if (new) {
            last->prev->lf = TRUE;
            new->lf = FALSE;
            new->prev = last->prev;
            new->next = last;
            last->prev->next = new;
            last->prev = new;
            lines++;
        } else {
            beep();
            printls(1,1,"Out of memory error!    ");/* @@XLATN */
            wait_for_key(&key1, &key2);
        }
    }
    if (cline < lines) {
        cline++;
        if (row < TXT_LEN) {
            row++;          /* increment current row */
            current = current->next;
        } else {
            tline++;            /* inc top line */
            scroll_up(STAT_LEN+1,1,SCR_LEN,SCR_WIDTH);
            select_line(cline, FALSE);
            printls(TXT_LEN+STAT_LEN,1,tmp->text);
            current = current->next;
        }
    }
}

/*
+-----------------------------------------------------------------------
|   up_line() - Move cursor up one line, scroll screen if needed.
+-----------------------------------------------------------------------
*/
up_line()
{
    if (row > 1) {
        cline--;        /* decrement current line */
        row--;          /* decrement current row */
        current = current->prev;
    } else {
        if (tline > 1) {    /* if we have scrolled down */
            tline--;        /* dec top line */
            cline--;        /* dec current line counter */
            scroll_down(3,1,24,80);
            select_line(cline, FALSE);
            printls(1+STAT_LEN,1,tmp->text);
            current = current->prev;
        }
    }
}

/*
+-----------------------------------------------------------------------
|   v_display(l) display current screen with l being top line
+-----------------------------------------------------------------------
|
|   This function handles the screen display of text. It is used both
|   by command line editor as well as the visual editing mode.
|   The display mode is determined by the (visual) flag.
|   while (visual) = FALSE lines are numbered and are truncated.
|
|   l = line number to be first line on screen.
|
+-----------------------------------------------------------------------+*/
v_display(l)
int l;
{
    int i;
    struct tpb *s,*t;

    t = tmp;                /* preserve tmp value */
    if (lines > 0) {            /* display only if there are lines */
        if (select_line(l, FALSE)) {
            s = topline = tmp;
            tline = l;          /* save current top line number */
            for (i=1;i<=TXT_LEN;i++) {
                if (s->next) {
                    cls(i+STAT_LEN,1,i+STAT_LEN,80);
                    if (visual) {
                        printls(i+STAT_LEN,1,s->text);
                    }
                    else if (s->next != last || s->lf || strlen(s->text)) {
                        locate(i+STAT_LEN,1);       /* position cursor */
                        printf("%-5d ",l++);
                        printls(i+STAT_LEN, 6, s->text);
                    }
                    s = s->next;
                }
                else {
                    cls(i+STAT_LEN,1,25,80);
                    break;      /* exit display loop on EOF */
                }
            }
        }
    }
    else {        /* blank the screen */
        cls(1+STAT_LEN,1,24,80) ;
    }
    cls(25,1,25,80);
    dirty = FALSE;  /* clear dirty flag */
    tmp = t;        /* restore tmp value */
}

/*
+-----------------------------------------------------------------------
|   p_display() - display partial screen update.
+-----------------------------------------------------------------------
|
|   Display partial screen, from current cursor line down.
|
+-----------------------------------------------------------------------
*/
p_display()
{
    int i;
    struct tpb *s;

    if (select_line(cline, FALSE)) {
        s = tmp;
        for (i=row;i<SCR_LEN;i++) {
            cls(i+STAT_LEN,1,i+STAT_LEN,80);
            printls(i+STAT_LEN,1,s->text);
            if (s->next->next) {
                s = s->next;
            }
            else {
                cls(i+STAT_LEN+1,1,25,80);
                break;      /* exit display loop on EOF */
            }
        }
    }
    cls(25,1,25,80);
    dirty = FALSE;      /* clear dirty flag */
}

/*
+-----------------------------------------------------------------------
|   File_open() - Open & read input file.
+-----------------------------------------------------------------------
|
|     Open the file passed in from the command line.  If the file does
|   not exist, create it.  If the file DOES exist, then read as much
|   data into memory as it will hold.  If a line is longer than 80
|   characters, then set LF flag FALSE, otherwise strip LF from string
|   and set LF flag TRUE.
|
|     Return FALSE if unable to read or create file.
|
+-----------------------------------------------------------------------
*/
int File_open()
{
    struct  tpb *new;

    lines = 0;
    fp_in = fopen(inpname, "r");
/*
    If the file couldn't be opened, edit an empty buffer.
*/
    if(!fp_in) {                            /* Create a new file? */
        cline = 0;
        new = (struct tpb *) calloc(1,sizeof(struct tpb));
        if (new) {
            new->prev = first;
            new->next = last;
            first->next = new;
            last->prev = new;
        }
        else {
            beep();
            cls(1,1,24,80);
            printls(1,1,"Out of memory error!    ");/* @@XLATN */
            exit(1);
        }
    }
    else {
        while(get_line(buffer, LINE_LEN+1, fp_in)) {
            new = (struct tpb *) calloc(1, sizeof(struct tpb));
            if(!new) {
                beep();
                cls(1,1,24,80);
                printls(1,1,"File too large to edit."); /* @@XLATN */
                exit(1);
            }
            new->lf = FALSE;    /* REDUNDANT now */

            convert_tabs(buffer, work_buf, LINE_LEN+1, tab_size);
            if(strlen(work_buf) > LINE_LEN) {
                beep();
                scr(0,0,0,7);
                printf("Line longer than %d characters in file.",LINE_LEN);
                exit(1);
            }
            strcpy(new->text, work_buf);
/*
    Add the new record to the linked-list.
*/
            new->prev = last->prev;     /* add record to memory structure */
            new->prev->next = new;
            new->next = last;
            last->prev = new;
            lines++;
        }
        fclose(fp_in);
    }
    current = first->next;  /* set first line pointer as current */
    cline = 1;
    return(TRUE);   /* report file opened or created ok */
}
/*
+-----------------------------------------------------------------------
|   file_write() - write all lines from mem to output file.
+-----------------------------------------------------------------------
|
|   This function will write out file from memory to the output file
|   without closing the file. This allows the user to perform read and
|   write operations to edit a file larger than memory would allow.
|   Free any memory allocated to tpb and string space while writing the
|   output file to avoid re-tracing the chain.
|
+-----------------------------------------------------------------------
*/
int file_write()
{
    int i;
    char bakname[66] ;          /* backup file name     */
    int changed;                /* true if backup file made */

    cls(1,1,1,80);
    printls(1,1,"Writing output file:   ");/* @@XLATN */
    locate(1,22);
    printf("%s",outname);
    changed = file_backup(outname, bakname);
    if ((fp_out = fopen(outname,"w")) != NULL) {
        tmp = first->next;
        for (i=1; i<=lines; i++) {
            if(tmp->text[0] == '\n')
                fprintf(fp_out, "%s", tmp->text);
            else
                fprintf(fp_out, "%s\n", tmp->text);

            tmp = tmp->next;
        }
        fclose(fp_out);
        stkptr = 0;
        cls(1,1,1,80);
        return(TRUE);
    } else {
        cls(1,1,1,80);      /* clear command line */
        printls(1, 1,"Output filename:   ");/* @@XLATN */
        printls(1,19,outname);
        printls(2, 1,"Error opening output file!          ");/* @@XLATN */
        if (changed) {
            rename(bakname, outname);   /* restore state of backup */
        }
        wait_for_key(&key1, &key2);
        status_line();
        return(FALSE);
    }
}

/*
+-----------------------------------------------------------------------
|   file_backup(outname, bakname) - make backup copy of output file.
+-----------------------------------------------------------------------
|
|   This function will determine if a file with the same name as the
|   output file exists.  If the output file already exists, a .bak
|   file name is concocted, the old .bak file (if any) is deleted, and
|   the old output file is renamed to the .bak file.
|
+-----------------------------------------------------------------------
*/
int file_backup(outname, bakname)
char outname[];
char bakname[] ;            /* backup file name     */
{
    FILE *fp_out;          /* descriptor for output file   */
    int retval;             /* return value from function   */

    retval = FALSE;
    if (fp_out = fopen(outname, "r+b")) {  /* output file exist?   */
        fclose(fp_out);
        name_backup(outname, bakname);      /* make backup name */
        unlink(bakname);            /* kill old backups */
        rename(outname, bakname);       /* old output is backup */
        retval = TRUE;              /* we changed the name  */
    }
    return(retval);
}

/*
+-----------------------------------------------------------------------
|   name_backup() - make backup name from output file name
+-----------------------------------------------------------------------
|
|   This function takes an output file name and creates a backup file
|   name from it.
|
+-----------------------------------------------------------------------
*/
int name_backup(outname, bakname)
char outname[];
char bakname[] ;            /* backup file name     */
{
    register char *t, *s, *d;       /* pointers for name copying    */
    char *end;              /* end of file name     */

    for(t=outname; *t; ++t);        /* find end of list */
    end = t;
    for ( ; t > outname && *t != '.' && *t != '\\' && *t != '/'; --t);
    /* find beginning of extension  */
    if (*t == '.')
        end = t;
    for (s = outname, d = bakname; s < end; *d++ = *s++);
/*
    Copy output name to backup name.
*/
    strcpy(d, ".bak");      /* add .bak extension       */
}


/*
+-----------------------------------------------------------------------
|   push_stack(n) - put (N) on stack
+-----------------------------------------------------------------------
|
|   Store (n) in command param stack.
|
+-----------------------------------------------------------------------
*/
int push_stack(n)
int n;
{
    stack[stkptr++] = n;
}

/*
+-----------------------------------------------------------------------
|   pop_stack() - return current value on stack.
+-----------------------------------------------------------------------
|
|   Return value previously pushed on the command param stack.
|   Return zero upon stack underflow.
|
+-----------------------------------------------------------------------
*/
int pop_stack()
{
    if (stkptr > 0)
        return(stack[--stkptr]);
    else
        return(cline);

}

/*
+-----------------------------------------------------------------------
|   get_num() - parse number from command line.
+-----------------------------------------------------------------------
*/
int get_num(i)
int i;
{
    char numbuf[20];

    int numptr = 0,
        loop = TRUE;

    zap(numbuf, 20, '\0');

    while (loop) {
        if (cmd_buf[i] > 47 && cmd_buf[i] < 58)
            numbuf[numptr++] = cmd_buf[i++];
        else
            loop = FALSE;   /* exit loop on non-numeric char */
    }
    push_stack(atoi(numbuf));   /* push number onto command stack */
    return(i-1);        /* return current command pointer */

}

/*
+-----------------------------------------------------------------------
|   insert_char(c) - Insert (c) into current->text[col] and shift txt >
+-----------------------------------------------------------------------
|
|   This function will insert a character in the current line at col
|   position and shift all text right. If this forces the line to wrap
|   then it either wraps the line or creates a new line and wraps the
|   overflow into the new line.
|
|   r = current screen row number.
|   c = character to insert.
|   o = number of characters from left to place to insert char.
|   l = TPB structure to string to insert char into text buffer.
|
+-----------------------------------------------------------------------
*/
int insert_char(r,c,o,l)
int r,c,o;
struct tpb *l;
{
    struct tpb *new;
    int a,i;
    int ret;

    ret = FALSE;
    a = strlen(l->text);
    if (a < LINE_LEN) { /* if line is less than linelen then insert char */
        for (a=LINE_LEN; a>o; l->text[a--]=l->text[a-1]);
        l->text[o] = c;
        if (r > 0 && r <= TXT_LEN)
        printls(r+STAT_LEN,1,l->text);
        ret = TRUE;
    } else {        /* otherwise split line and then insert char */
        if (l->lf) {    /* if it's the end of the chain */
            new = (struct tpb *) calloc(1,sizeof(struct tpb));
            if (new) {
                new->text[0] = l->text[LINE_LEN-1];
                for (a=LINE_LEN; a>o; l->text[a--]=l->text[a-1]);
                l->text[LINE_LEN] = '\0';
                l->text[o] = c;
                new->prev = l;
                new->next = l->next;
                l->next = new;
                new->next->prev = new;
                l->lf = TRUE;
                new->lf = TRUE;
                dirty = TRUE;
                ret = TRUE;
                lines++;
            } else {
                beep();
                printls(1,1,"Out of memory error!    ");/* @@XLATN */
                wait_for_key(&key1, &key2);
            }
        } else {
            ret |= insert_char(r+1,l->text[LINE_LEN-1],0,l->next);
            for (a=LINE_LEN; a>o; l->text[a--]=l->text[a-1]);
            l->text[LINE_LEN] = '\0';
            l->text[o] = c;
            if (r > 0 && r < TXT_LEN)
            printls(r+STAT_LEN,1,l->text);
        }
    }
    return(ret);
}

/*
+-----------------------------------------------------------------------
|   delete_char(r,o,l) - Delete character from memory structure.
+-----------------------------------------------------------------------
|
|   Delete a character from the passed (l) structure at offset (o).
|   If this deletion causes a wrapped line to be shifted left then
|   this function will recurse on itself until all lines are shifted.
|   r = row of line to locate output. if > 0 then print line.
|   o = offset of current location to delete character.
|   l = temporary pointer to text param block.
|
+-----------------------------------------------------------------------
*/
int delete_char(r,o,l)
int o;
struct tpb *l;
{
    int     i;
    int     len;
    int     ret;

    len = strlen(l->text);
    if(len == 0)
        return(0);

    if(o > len-1)
        return(0);

    ret = l->text[o];
    strcpy(&l->text[o], &l->text[o+1]);     /* Shift left over character */
    if (r > 0 && r <= TXT_LEN) {
        len = strlen(l->text);
        cls(r+STAT_LEN, len+1, r+STAT_LEN, len+1);
        printls(r+STAT_LEN,1,l->text);
    }
    return(ret);
}

/*
+-----------------------------------------------------------------------
|   copy_line() - Copy line(s) to destination
+-----------------------------------------------------------------------
|
|   This function copies lines from one line to others.
|   x must be less than or equal to y and z must be outside x thru y!
|
|   n C     copy current line to line n.
|   z y x C copy from line x thru line y to line z.
|
+-----------------------------------------------------------------------
*/
int copy_line()
{
    struct tpb *s;
    struct tpb *d;
    struct tpb *new;
    int i,loop,x,y,z;
    int ret;


    ret = FALSE;
    switch (stkptr) {       /* load vars from stack */

        case 1 :
            z = y = cline;  /* default start & thru to current line */
            x = xrange(pop_stack()); /* set start param from stack*/
            loop = TRUE;
            break;

        case 3 :        /* if "x y z C" command */
            x = xrange(pop_stack());    /* get dest param */
            y = range(pop_stack());    /* get thru param */
            z = range(pop_stack());    /* get start param */
            loop = TRUE;
            break;

        default :       /* if wrong number of params */
            beep();
            printls(1,1,"Error: invalid number of parameters in copy command.");/* @@XLATN */
            wait_for_key(&key1, &key2);
            stkptr = 0;     /* ignore the rest of params */
            loop = FALSE;
            return(ret);
    }

    if (loop) {
        if (x > z && x <= y) {  /* check for nested copy */
            beep();
            printls(1,1,"Error: Cannot copy inside source block.");/* @@XLATN */
            wait_for_key(&key1, &key2);
            return(ret);
        }
        if ((y >= z)) {
            if (select_line(x, TRUE)) {     /* set destination pointer */
                d = tmp;
                if (select_line(z, FALSE)) {        /* set start pointer */
                    s = tmp;
                    for (i=z; i<=y; i++) {  /* loop thru iteration count */
                        new = (struct tpb *) calloc(1,sizeof(struct tpb));
                        if (new != NULL) {
                            strcpy(new->text,s->text);
                            ret = TRUE;
                            new->next = d;
                            new->prev = d->prev;
                            d->prev = new;
                            new->prev->next = new;
                            new->prev->lf = TRUE;
                            new->lf = s->lf || (new->next != last);
                            s = s->next;    /* update source pointer */
                            lines++;        /* increment total line count */
                        } else {
                            beep();
                            printls(1,1,"Out of memory error!    ");/* @@XLATN */
                            wait_for_key(&key1, &key2);
                            break;      /* abort on alloc error */
                        }
                    }
                } else {
                    beep();
                }
            } else {
                beep();
            }
        } else {
            beep();
            printls(1,1,"Error: First number must be less than or equal to second number. ");/* @@XLATN */
            wait_for_key(&key1, &key2);
        }
    } else
    beep();
    return(ret);
}

/*
+-----------------------------------------------------------------------
|   move_line() - move line(s) to destination
+-----------------------------------------------------------------------
|
|   This function moves lines from one line to others.
|
|   n M     move current line to line n.
|   x y z M move from line x thru line y to line z.
|
+-----------------------------------------------------------------------
*/
int move_line()
{
    int i,loop,x,y,z;
    int ret;
    struct tpb *s;
    struct tpb *d;
    struct tpb *n;

    ret = FALSE;
    switch (stkptr) {       /* load vars from stack */

        case 1 :
            y = z = cline;  /* default start & thru to current line */
            x = xrange(pop_stack());    /* set dest to param */
            loop = (x != z);    /* don't do anything if dest == start */
            break;

        case 3 :
            x = xrange(pop_stack());    /* get dest param */
            y = range(pop_stack());    /* get thru param */
            z = range(pop_stack());    /* get start param */
            loop = (x != z);        /* if really moving things */
            break;

        default :       /* if wrong number of params */
            beep();
            printls(1,1,"Error: invalid number of parameters in move command.  ");/* @@XLATN */
            wait_for_key(&key1, &key2);
            stkptr = 0;     /* ignore the rest of params */
            loop = FALSE;
            break;
    }
    
   
    if (loop) {
        if (x >= z && x <= y) { /* check for nested copy */
            beep();
            printls(1,1,"Error: Cannot move inside source block.");/* @@XLATN */
            wait_for_key(&key1, &key2);
            return(ret);
        }
        if (z <= y) {
            if (select_line(x, TRUE)) {     /* set destination pointer */
                d = tmp;
                if (select_line(z, FALSE)) {        /* set start pointer */
                    s = tmp;
                    ret |= (x != y || y != z);  /* determine if a change */
                    for (i=z; i<=y; i++) {  /* loop thru iteration count */
                        s->prev->next = s->next;/* remove record from source */
                        s->next->prev = s->prev;
                        n = s->next;        /* preserve next record to move */
                        s->next = d->prev->next;/* insert into destination */
                        d->prev->next = s;
                        s->prev = d->prev;
                        d->prev = s;
                        s->lf |= (d->next != last);
                        s = n;          /* update next record to move */
                    }
                } else
                beep();
            } else
            beep();
        } else {
            beep();         /* warn user if bad arguments */
            printls(1,1,"Error: First number must be less than or equal to second number. ");/* @@XLATN */
            wait_for_key(&key1, &key2);
        }
    }
    return(ret);
}

/*
+-----------------------------------------------------------------------
|   split_line(c) - Split (current) line at location (c) to next line
+-----------------------------------------------------------------------
|
|   This function splits the current line and at the current cursor
|   position (c).
|   current is to be used as the current line to be split.
|   The remainder to be placed on the newly created following line.
|
+-----------------------------------------------------------------------
*/
split_line(c)
int c;
{
    int x,y,z,ret;
    struct tpb *new;

    new = (struct tpb *) calloc(1,sizeof(struct tpb));
    if (new) {
        z = strlen(current->text);  /* get line length */
        for (y=0,x=c-1;x<z;new->text[y++]=current->text[x++]);  /* copy part to new line */
        for (x=c-1;x<z;current->text[x++]='\0');    /* null out moved part */
        new->prev = current;        /* set backwards pointer */
        new->next = current->next;  /* set forwards pointer */
        current->next = new;        /* set prev fwd pointer */
        new->next->prev = new;      /* set next prev pointer */
        new->lf = current->lf || (new->next != last);
        /* maybe assert linefeed on new line */
        current->lf = TRUE;     /* assert linefeed on current line */
        lines++;            /* adjust line counter */
        ret = TRUE;
    } else {
        beep();
        printls(1,1,"Out of memory error!    ");/* @@XLATN */
        wait_for_key(&key1, &key2);
        ret = 0;
    }
    p_display();            /* re-display screen */
    return(ret);
}

beep()      /* beep console beeper */
{

    putchar(7);

}

int range(i)    /* return (i) always between 1..lines */
int i;
{

    if (i > lines)
    return(lines);
    if (i < 1)
    return(1);
    return(i);

}

int xrange(i)   /* return (i) always between 1..lines + 1 */
int i;
{
    if (i > lines + 1)
    return(lines + 1);
    if (i < 1)
    return(1);
    return(i);
}

/*
+-----------------------------------------------------------------------
|   insert_line(f) - Insert a line of text into the memory structure.
+-----------------------------------------------------------------------
|
|   This function inserts a text string into the twll structure. The
|   text string is found in buffer[]. Increment line counter.
|   Line is inserted at current line, forcing the current line down
|   one line.
|
|   return TRUE if allocation is successful else return FALSE
|
+-----------------------------------------------------------------------
*/
int insert_line(f)
int f;
{
    struct tpb *new;

    new = (struct tpb *) calloc(1,sizeof(struct tpb));
    if (new != NULL) {
        strcpy(new->text, buffer);      /* copy contents of buffer */
        if (tmp == first->next) {   /* if inserting before first line */
            new->next = tmp;
            new->prev = first;
            first->next = new;
            tmp->prev = new;
        } else {
            new->next = tmp;
            new->prev = tmp->prev;
            tmp->prev = new;
            new->prev->next = new;
            new->prev->lf = TRUE;
        }
        new->lf = TRUE;
        current = new;              /* make new line current */
        lines++;                /* increment total line count */
        return(TRUE);
    } else {
        beep();
        printls(1,1,"Out of memory error!    ");/* @@XLATN */
        wait_for_key(&key1, &key2);
        return(FALSE);
    }
}


/*
+-----------------------------------------------------------------------
|   delete_block() - Delete a block of lines from memory.
+-----------------------------------------------------------------------
*/
int delete_block()
{
    int x,y,z;
    int ret;

    ret = FALSE;
    switch (stkptr) {

        case 0 :
            ret |= delete_line(cline);
            break;

        case 1 :
            ret |= delete_line(range(pop_stack()));
            break;

        case 2 :
            x = range(pop_stack());
            y = range(pop_stack());
            for (z=y; z<=x; z++)
                ret |= delete_line(y);
            break;

        default :
            beep();
            printls(1,1,"Error: invalid number of parameters in delete command.");/* @@XLATN */
            wait_for_key(&key1, &key2);
            break;
    }
    stkptr = 0;
    return(ret);
}

/*
+-----------------------------------------------------------------------
|   delete_line() - Delete line of text in memory structure.
+-----------------------------------------------------------------------
|
|   This function deletes a line of text from the twll structure. It
|   also frees the allocated space & decrements line counter.
|
|   Return TRUE if delete is successful.
|
+-----------------------------------------------------------------------
*/
int delete_line(z)
int z;
{
    if (z <= lines && select_line(z, FALSE)) {
        strcpy(buffer,tmp->text);   /* leave text in buffer */
        tmp->prev->next = tmp->next;
        tmp->next->prev = tmp->prev;
        tmp->prev->lf |= (tmp->next != last);
        free(tmp);          /* deallocate the memory block */
        lines--;            /* decrement line counter */
        return(TRUE);           /* report success */
    } else {
        return(FALSE);
    }
}

/*
+-----------------------------------------------------------------------
|   select_line(x, end) - Find line x and point current to it.
+-----------------------------------------------------------------------
|
|   This function scans from the top of the linked list to the bottom
|   or until (x) records are passed. It leaves tmp pointing at the
|   record (x). tmpline = (x). Otherwise it returns(FALSE).
|   If the end parameter is TRUE, allows selection of the line after
|   the last line in the file.
|
+-----------------------------------------------------------------------
*/
int select_line(x, end)
int x;
int end;
{
    int i;

    tmp = first;
    if (end) {          /* allow selection of last + 1 line */
        for (i=0; i<x; i++) {   /* scan for start line */
            if (tmp->next == NULL) {
                return(FALSE);  /* return if end of list */
            } else {
                tmp = tmp->next;    /* otherwise point to next record */
            }   
        }
    } else {            /* don't allow selection of last + 1 line */
        for (i=0; i<x; i++) {   /* scan for start line */
            if (tmp->next->next == NULL)
                return(FALSE);  /* return if end of list */
            else
                tmp = tmp->next;    /* otherwise point to next record */
        }
    }
    tmpline = x;        /* set current line number */
    return(TRUE);       /* return successful */
}

/*
+-----------------------------------------------------------------------
|   Print_doc() - Print document to output device
+-----------------------------------------------------------------------
|
|   This function outputs the current text file to the output device
|   The environment variable (LSTDEV) is used to change the printer
|   device name. This may be used to re-route the output of this
|   program to a disk file or a network printer device.
|
+-----------------------------------------------------------------------
*/
int Print_doc()
{
    FILE *print;
    int e,i,loop,p,s;
    char *c,prtname[65],*getenv();

    switch (stkptr) {

        case 0 :
            s = 1;
            e = lines;
            stkptr = 0;
            loop = TRUE;
            break;

        case 1 :
            s = pop_stack();        /* get start range param */
            e = lines;          /* assume eof for end range param */
            stkptr = 0;
            loop = TRUE;
            break;

        case 2 :
            e = pop_stack();    /* get end range param */
            s = pop_stack();    /* get start range param */
            stkptr = 0;
            loop = TRUE;
            break;

        default :       /* bad number of params */
            beep();
            stkptr = 0;
            loop = FALSE;
            break;
    }

    if (loop) {
        if (e > lines)
        e = lines;
        if (s < 1)
        s = 1;
        c = getenv("LSTDEV");       /* check for printer name */
        if (c == NULL)
        strcpy(prtname,"PRN");   /* assume default printer */
        else
        strcpy(prtname,c);      /* get user printer name */
        if ((print = fopen(prtname,"w")) != NULL) {
            select_line(s, FALSE);
            printls(2,1,"Printing...");/* @@XLATN */
            p = 1;
            for (i=s;i<=e;i++) {
                fprintf(print,"%s\n",tmp->text);
                if (++p > 60) {         /* time for a page feed? */
                    fprintf(print,"\f");    /* eject page */
                    p = 1;          /* reset line counter */
                }
/*
    Did the user press <ESC> to interrupt the print?
*/
                if(inkey(&key1, &key2)) {    /* Keystroke entered? */
                    if(key1 == ESC) {
                        fprintf(print,"\f");    /* eject page */
                        status_line();      /* redraw status line */
                        fclose(print);      /* close output device */
                        return;         /* abort print */
                    }
                }
/*
    No, continue.
*/
                if (tmp->next)
                    tmp = tmp->next;        /* point to next line */
                else
                    break;          /* or abort listing on EOF */
            }
        }
        fprintf(print,"\f");    /* eject page */
        status_line();
        fclose(print);
    }
}

/*
+-----------------------------------------------------------------------
|   Initialize() - Initialize any buffers or variables used in edlin
+-----------------------------------------------------------------------
|
|   Initialize all variables and pointers to their default values.
|   Two tpb's are allocated as static pointers to the start and end
|   of the linked list. First->next points to the first element and
|   last->prev points to the last element. This process eliminates the
|   special case processing in the insert and delete line functions.
|
|   Open default key definition file and if found then define the keys
|   otherwise initialize the fkey array to NULL (undefined).
|
+-----------------------------------------------------------------------
*/
Initialize()
{
    int     i;
    FILE    *fp;
    char    *env_ptr;

    env_ptr = getenv("TABS");
    if(env_ptr)
        tab_size = atoi(env_ptr);

    signal(SIGINT, SIG_IGN);        /* Kill CTRL-C */

    changed = FALSE;
    lines = 0;                  /* initialize the line counter */
    visual = FALSE;             /* disable visual edit mode. */
    question = FALSE;           /* disable S/R verify mode */
    first = (struct tpb *) calloc(1,sizeof(struct tpb));
    last  = (struct tpb *) calloc(1,sizeof(struct tpb));
    first->prev = NULL;
    first->next = last;
    last->prev = first;
    last->next = NULL;
    cline = 1;
    tline = 1;
    ltline = 1;
    insert = TRUE;
    zap(fkey, MAX_KEY, '\0');       /* Initialize F-KEY table */
    zap(srch, sizeof(srch), '\0');
    zap(rep, sizeof(rep), '\0');

    fp = fopen("DEFKEYS.ED", "rb");
    if(fp) {
        for(i=0; i<MAX_KEY; ++i)
            fkey[i]=getc(fp);
        fclose(fp);
    }
    else
        zap(fkey, MAX_KEY, '\0');
}
/*
+-----------------------------------------------------------------------
|   status_line() - display top line of visual mode screen.
+-----------------------------------------------------------------------
*/
status_line()
{
    if (!execute)
    {
        printls(2,1,"อออ File ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ"); /* @@XLAT */
        locate(2, 10);
        cprintf("%s ", outname);
    }
}

/*
+-----------------------------------------------------------------------
|   top_line() - display top line of visual mode screen.
+-----------------------------------------------------------------------
|
|   This function displays the top status line of the screen completely
|   with insert status if needed.
|
+-----------------------------------------------------------------------
*/
top_line()
{
/*****************************
    int     full_update;

    full_update=0;

    if (execute != save_execute)
    {
        save_execute=execute;
        full_update=1;
    }

    if (capture != save_capture)
    {
        save_capture=capture;
        full_update=1;
    }

    if (insert != save_insert)
    {
        save_insert=insert;
        full_update=1;
    }
*********************************************/
/***************
    if (full_update)
    {
*****************/
    if(!execute)
        cls(01,01,01,80);

    if (capture)
        printls(2,60,"อ CAPTURE อ");/* @@XLAT */
    else if (execute)
        printls(2,60,"อ EXECUTE อ");/* @@XLAT */
    else
        printls(2,60,"อออออออออออ");

    if (insert)
        printls(2,70,"อ INSERT อ");/* @@XLAT */
    else
        printls(2,70,"ออออออออออ");

/***    }  *****/

    if (visual)
    {
        locate(2,41);
        printf(" ROW=%d COL=%d อออออ",cline,col);/* @@XLAT */
    }
    else
    {
        locate(2,47);
        printf(" CL=%d ",cline);
    }
}

/*
+-----------------------------------------------------------------------
|   help_screen() - display help screen on console.
+-----------------------------------------------------------------------
|
|   Display help screen to instruct user of available options.
|
+-----------------------------------------------------------------------
*/
help_screen()
{
    cls(STAT_LEN+1,01,25,80);
    locate(3,30);
    printls( 3,30,"Command Summary ");/* @@XLATN */
    printls( 5, 1,"<-    - Move left one column.         ->    - Move right one column.         ");/* @@XLAT */
    printls( 6, 1,"Up    - Move up one row.              Down  - Move down one row.             ");/* @@XLAT */
    printls( 7, 1,"PgUp  - Move up one screen.          ^PgUp - Move up to first screen.        ");/* @@XLAT */
    printls( 8, 1,"PgDn  - Move down one screen.        ^PgDn - Move to last screen.            ");/* @@XLAT */
    printls( 9, 1,"Home  - Move cursor to left column.   End  - Move cursor to last column.     ");/* @@XLAT */
    printls(10, 1,"Ins   - Toggle insert mode.           Del  - Delete current character.       ");/* @@XLAT */
    printls(11, 1,"Esc   - Exit visual mode.         ");/* @@XLAT */
    printls(12, 1,"^A    - Assign function key values.  ^D    - Duplicate current line.         ");/* @@XLAT */
    printls(13, 1,"^L    - Jump to specific line.       ^N    - Split line at cursor.           ");/* @@XLAT */
    printls(14, 1,"^O    - Toggle keystroke capture.    ^P    - Print entire document.          ");/* @@XLAT */
    printls(15, 1,"^Q    - Print help screen.           ^R    - Search text & replace text.     ");/* @@XLAT */
    printls(16, 1,"^W    - Write file and continue.     ^S    - Search text.                    ");/* @@XLAT */
    printls(17, 1,"^X    - Execute captured keystrokes. ^Y    - Delete current line.            ");/* @@XLAT */
    printls(19,20,"Press any key to return to Editor:                ");/* @@XLAT */
    locate(19,75);
    wait_for_key(&key1, &key2);
    v_display(tline);
}

/*
+-----------------------------------------------------------------------
|   c_help_screen() - display command mode help screen on console.
+-----------------------------------------------------------------------
|
|   Display help screen to instruct user of available options.
|
+-----------------------------------------------------------------------
*/
c_help_screen()
{

    cls(STAT_LEN+1,01,25,80);
    locate(3,30);
    printls( 3,30,"Command Mode Summary          ");/* @@XLAT */
    printls( 5, 1,"A - ASSIGN:            A - Assigns characters to function keys for visual mode. ");/* @@XLAT */
    printls( 6, 1,"C - COPY:         {fl}dC - Copies from first line number (f) to last line (l).  ");/* @@XLAT */
    printls( 7, 1,"                           to location before destination line number (d).      ");/* @@XLAT */
    printls( 8, 1,"D - DELETE:        {f}lD - Deletes from first line number (f) to last line (l). ");/* @@XLAT */
    printls( 9, 1,"E - END:               E - Ends editing session and saves edited file to disk.  ");/* @@XLAT */
    printls(10, 1,"F - FILENAME:  Ffilename - Assigns new names (filename) for output.             ");/* @@XLAT */
    printls(11, 1,"H - HELP:              H - Displays help for Command Mode Commands.             ");/* @@XLAT */
    printls(12, 1,"I - INSERT:         {n}I - Inserts a line of text before line number (n).       ");/* @@XLAT */
    printls(13, 1,"L - LIST:           {n}L - Displays text in a file starting from line (n).      ");/* @@XLAT */
    printls(14, 1,"M - MOVE:         {fl}dM - Moves first line number (f) through last line (l).   ");/* @@XLAT */
    printls(15, 1,"                           to line before destination line line number (d).     ");/* @@XLAT */
    printls(16, 1,"P - PRINT:       {{f}l}P - Sends entire file from line number (f) or range of   ");/* @@XLAT */
    printls(17, 1,"                           lines from first line (f) to last (l) to printer.    ");/* @@XLAT */
    printls(18, 1,"Q - QUIT:              Q - Ends editing session with option to save changes.    ");/* @@XLAT */
    printls(19, 1,"R - REPLACE:  {{{f}l}?}R - Replaces existing text with new text in range from   ");/* @@XLAT */
    printls(20, 1,"                           first line (f) to last (l) with selection option (?).");/* @@XLAT */
    printls(21, 1,"S - SEARCH:   {{{f}l}?}S - Searches for a text in range from first (f) to last  ");/* @@XLAT */
    printls(22, 1,"                           line (l) with option (?) to continue search.         ");/* @@XLAT */
    printls(23, 1,"W - WRITE:             W - Allows you to save a file and continue editing.      ");/* @@XLAT */
    printls(25,20,"Press any key to return to Editor:                ");/* @@XLAT */
    locate(25,75);
    wait_for_key(&key1, &key2);
    v_display(tline);

}
/*
+-----------------------------------------------------------------------
|   assign_fkey() - assign a character to a function key
+-----------------------------------------------------------------------
|
|
|   This function displays a menu and allows the user to position the
|   cursor over a single character and assign that value to the F key
|   If the value is NULL then the Fkey is considered undefined.
|
+-----------------------------------------------------------------------
*/
assign_fkey()
{
    int     keychange, loop, x, y, z;
    int     tmp;
    FILE    *d;

    keychange = FALSE;
    cls(STAT_LEN+1,1,25,80);
    locate(STAT_LEN+1, 30);
/*
    Paint the top of the box.
*/
    cprintf("ษ");
    ffill(stdout, 'อ', 36);
    cprintf("ป");
    printls(STAT_LEN+ 2,30,"บ    0 1 2 3 4 5 6 7 8 9 A B C D E F บ");
/*
    Paint the body of the box with keycodes.
*/
    for(x=0;x<16;x++) {
        locate(STAT_LEN+x+3, 30);
        cprintf("บ");
        ffill(stdout, ' ', 36);
        cprintf("บ");
        locate(STAT_LEN+x+3,32);
        cprintf("%-2X ",x*16);
        for (y=0;y<16;y++) {
            locate(STAT_LEN+x+3,35+(y*2));
            tmp = (x * 16) + y;
            if ((tmp == '\n') || (tmp == '\r') || (tmp == '\b') ||
                (tmp == '\7'))
            tmp = ' ';      
            putchar(tmp);
        }
    }
    locate(STAT_LEN+19, 30);
    cprintf("ศ");
    ffill(stdout, 'อ', 36);
    cprintf("ผ");

    printls(STAT_LEN+20,10,"Locate the cursor over the character to assign to the key and                ");/* @@XLAT */
    printls(STAT_LEN+21,10,"press the function key. To un-define a function key, move the                " );/* @@XLAT */
    printls(STAT_LEN+22,10,"cursor at the top left corner and press the function key.                    ");/* @@XLAT */
    loop = TRUE;
    x = 0;
    y = 0;
    dfkeys(0);
    while(loop) {
        locate(x+STAT_LEN+3,(y*2)+35);
        wait_for_key(&key1, &key2);

        if(key1 == FKEY) {
            switch(key2) {
                case HOME:
                    x = y = 0;
                    break;
                case END:
                    x = y = 15;
                    break;
                case UP:
                    if(x > 0)
                        x--;
                    break;
                case DOWN:
                    if(x < 15)
                        x++;
                    break;
                case LEFT:
                    if(y > 0)
                        y--;
                    break;
                case RIGHT:
                    if(y < 15)
                        y++;
                    break;
                case F1:
                case F2:
                case F3:
                case F4:
                case F5:
                case F6:
                case F7:
                case F8:
                case F9:
                case F10:
                    key2 = key2 - F1;
                    tmp = (x*16) + y;
                    if ((tmp == '\n') || (tmp == '\r') || (tmp == '\b') ||
                            (tmp == '\7'))
                        tmp = 0;        /* can't display these  */
                    fkey[key2] = tmp;
                    dfkeys(key2+1);
                    keychange = TRUE;
                    break;
            } /* End switch */
        } /* End if */
/*
    Anything but a function key.
*/
        else {
            if(key1 == ESC)
                loop = FALSE;
        }
    } /* End While */

    if (keychange) {
        if ((d = fopen("DEFKEYS.ED","w")) != NULL) {
            for (x=0;x<MAX_KEY;putc(fkey[x++],d));
            fclose(d);
        }
    }
    cls(3,1,25,80);
}

/*
+-----------------------------------------------------------------------
|   dfkeys(f) - Display function keys definitions
+-----------------------------------------------------------------------
|
|   Display function keys on screen.
|
|   f = 0   display all function keys definitions
|   f > 0
|   f < 13  display only function key (f+1).
|
+-----------------------------------------------------------------------
*/
dfkeys(f)
int f;
{
    int z;

    if (f>0 && f<13) {
        locate(STAT_LEN+2+f,10);
        if (fkey[f-1]) {
            cls(STAT_LEN+2+f,1,STAT_LEN+2+f,27);
            printf("F%-2d = ",f);
            locate(STAT_LEN+2+f,16);
/*          chrout(fkey[f-1]); */
            putchar(fkey[f-1]);
        } else {
            printf("F%-2d = Undefined  ",f); /* @@XLAT */
        }
    } else {
        for (z=0;z<MAX_KEY;z++) {
            locate(STAT_LEN+3+z,10);
            if (fkey[z])
            printf("F%-2d = %c        ",z+1,fkey[z]);
            else
            printf("F%-2d = Undefined",z+1); /* @@XLAT */
        }
    }
}

/*
+-----------------------------------------------------------------------
|   search_line()
+-----------------------------------------------------------------------
|
|   This function returns the current line set to the next location of
|   passed parameter.
|
|   f = TRUE if replace is to be performed.
|
+-----------------------------------------------------------------------
*/
int search_line(f)
int f;
{

    int cl,i,j,k,l,loop,m,n,r,x,y,z;
    int slen, rlen, line, replace, key;
    int ret;

    cl = cline;             /* preserve current line number */
    ret = FALSE;            /* assume no change to file */
    switch(stkptr) {

        case 0 :            /* do whole file print */
            x = 1;
            y = lines;
            loop = TRUE;
            break;

        case 1 :            /* print from n to end of file */
            x = pop_stack();
            y = lines;
            loop = TRUE;
            break;

        case 2 :            /* print from x to y in file */
            y = pop_stack();
            x = pop_stack();
            loop = TRUE;
            break;

        default :           /* abort on any other params */
            beep();
            loop = FALSE;
            stkptr = 0;
            break;
    }

    if (loop) {
        zap(buffer, LINE_LEN+1, '\0');

        if (!f)
            strcpy(buffer,srch);

        printls(2,1,"Search for:อออออออออออออออออออออออออออออออออออออออออออออ");/* @@XLAT */

        if (!edit_line()) {
            status_line();
            return(ret);    /* abort on escape key */
        }
        if (strlen(buffer) < 1) {
            status_line();
            return(ret);    /* abort on null search string */
        }
        strcpy(srch, buffer);

        if (f) {
            zap(buffer, LINE_LEN+1, '\0');

            printls(2,1,"Replace with:ออออ");/* @@XLAT */
            if (!edit_line()) {
                status_line();
                return(ret);
            }
            strcpy(rep,buffer);
        }
        slen = strlen(srch);
        rlen = strlen(rep);
        select_line(x, FALSE);
        printls(2,1,"Searching ออออออออ");/* @@XLAT */
        for (line=x; line<=y; line++) {
            m = (strlen(tmp->text)-slen) + 1;
            for (j=0; j<m; j++) {
                if (strncmp(tmp->text+j,srch,slen) == 0) {  /* we found it */
                    current = tmp;
                    cline = line;       /* set current line to this line */
                    row = 1;            /* set top line */
                    col = j+1;
                    if (f) {            /* if replace is true */
                        if (question) {     /* if user verify is true */
                            printls(2,1,"Found: Change it? Y/N  ");/* @@XLAT */
                            v_display(line);
                            if (visual)
                                locate(STAT_LEN+1,j+1);
                            else
                                locate(STAT_LEN+1,j+5);

                            key = Prompt();         /* Prompt for Y/N/ESC */
                            if (key != *yesmsg) {
                                if (key == 27) {    /* user abort */
                                    status_line();
                                    return(ret);
                                }
                                replace = FALSE;
                            } else {
                                replace = TRUE; /* user verified - replace */
                            }           /* end of question */
                        } else {
                            replace = TRUE;
                        }
                        if (replace) {
                            for(x=0; x<slen; x++)
                                delete_char(-25,j,tmp);
                            for(x=rlen-1; x>=0; x--)
                                ret |= insert_char(-25,rep[x],j,tmp);
                        }
                    }
                    else {        /* otherwise search only  */
                        if (question) {
                            printls(2,1,"Found: Find it again?  Y/N   ");/* @@XLATN */
                            v_display(line);
                            if (visual)
                                locate(STAT_LEN+1,j+1);
                            else
                                locate(STAT_LEN+1,j+6);
                            
                            key = Prompt();
                            if (key != *yesmsg) {
                                status_line();
                                return(ret);
                            }
                        } else  {   /* if no question, then stop on first */
                            v_display(line);    /* display screen */
                            status_line();  /* and status line */
                            row = 1;        /* adjust coordinates */
                            col = j;
                            return(ret);    /* and return */
                        }
                    }
                }
            }
            if (tmp->next)
            tmp = tmp->next;
        }
        cline = cl; /* restore previous current line */
        v_display(tline); /* re-display screen */
        status_line();  /* and status line */
    }
    return(ret);
}           /* end of search line function */

/*
+-----------------------------------------------------------------------
|   edit_line() - Edit a text line off-screen.
+-----------------------------------------------------------------------
|
|   Edit text line in (buffer) area.
|   Attempt to use function keys if they can be used!
|   Function returns TRUE if line was entered without ESC key press.
|   This function is designed to be used with re-directed input if
|   desired and function keys are not used in that case.
|   Special function keys are supported with console input.
|
|   ^S Move left character      ^D Move right character
|   ^G Delete character         ^Y Delete whole line
|   ^V Toggle Insert mode
|   Esc Abort input         Enter accept and end input.
|
|   ***************** Special Function Keys *******************
|   HOME    Move cursor to first char of line
|   END     Move cursor to last character of line
|   Insert  Toggle insert mode
|   Delete  Delete character at cursor
|   LeftArrow Move cursor left one character
|   RightArrow Move cursor right one character.
|   Function keys input their defined values (if defined)
|
+-----------------------------------------------------------------------
*/
int edit_line()
{
    int     loop,
            col,
            i, j, k, l, s, t;

    char    key1, key2;

    l = strlen(buffer);         /* get length of screen */
    cls(1,1,1,80);
    printls(1,1,buffer);
    col = 0;
    loop = TRUE;
    while(loop) {
        locate(1,col+1);    /* position the cursor */
        wait_for_key(&key1, &key2);
/*
    Process function keys.
*/
        if(key1 == FKEY) {
            switch (key2) {
                case HOME:
                    col = 0;
                    break;
                case LEFT:
                    if(col > 0)
                        col--;
                    break;
                case RIGHT:
                    if(col < strlen(buffer))
                        col++;
                    break;
                case END:
                    col = strlen(buffer);
                    break;
                case INS:
                    insert = !insert;
                    if (insert)
                        printls(2,70,"อ INSERT อ");/* @@XLAT */
                    else
                        printls(2,70,"ออออออออออ");
                    break;
                case DEL:
                    for(j=col; j<LINE_LEN; ++j)
                        buffer[j] = buffer[j+1];
                    cls(1,1,1,80);
                    printls(1,1,buffer);
                    break;
            } /* End SWITCH */
        }
/*
    Non F keys.
*/
        else {
            switch (key1) {
                case CTRL_S:
                    if(col > 0)
                        col--;
                    break;
                case CTRL_D:
                    if(col < strlen(buffer))
                        col++;
                    break;
                case CTRL_G:
                    for(j=col; j<sizeof(buffer); j++)
                        buffer[j] = buffer[j+1];
                    cls(1,1,1,80);
                    printls(1,1,buffer);
                    break;
                case  BS:
                    if (col > 0) {
                        for(t=col-1; t<strlen(buffer); t++)
                            buffer[t] = buffer[t+1];
                        locate(1,1);
                        col--;
                        cls(1,1,1,80);
                        printls(1,1,buffer);
                    }
                    break;
                case TAB:
                    if (col < SCR_WIDTH-8) {
                        if (insert) {
                            k = (col+8) & ~7;
                            if (k < LINE_LEN) {
                                for (j=col;j<k;j++)
                                    for(l=LINE_LEN; l>col; l--)
                                        buffer[l] = buffer[l-1];
                                col = k;
                            }
                        }
                        else {
                            col = (col + 8) & ~7;   /* compute next tab stop */
                        }
                    }
                    break;
                case ENTER:
                    loop = FALSE;
                    break;
                case CTRL_Y:    /* Delete contents of buffer */
                    zap(buffer, LINE_LEN+1, '\0');
                    cls(1,1,1,80);
                    col = 0;
                    break;
                case ESC:
                    return(FALSE);
                default:
                    if(isprint(key1)) {
                        if (insert) {
                            for(i=LINE_LEN; i>col; i--)
                                buffer[i] = buffer[i-1];
                            printls(1,1,buffer);
                        }
                        if (col < LINE_LEN) {
                            locate(1,col+1); /* put cursor in proper place */
                            buffer[col++] = key1;
                            putchar(key1);
                        }
                    }
                    break;
            } /* End SWITCH */
        } /* End ELSE */
        if (col > 79)
            col = 79;
    } /* End WHILE */

    return(TRUE);
}

/*
+-----------------------------------------------------------------------
| int InputKey() - Return keystyroke from file or console
+-----------------------------------------------------------------------
|
|   This function returns translated input from the console or file
|   depending on whether the [execute] flag is set or not.
|
|   [execute] If true then read a byte from "ed.key" and return it.
|   [capture] If true the read a byte from console and write it to
|           the "ed.key" file and also return the key to caller.
|
+-----------------------------------------------------------------------
*/
int InputKey()
{
    if (execute) {
        key1 = fgetc(fp_keys);
        key2 = fgetc(fp_keys);
        if (feof(fp_keys)) {    /* are we at the end of fp_keys? */
            execute = FALSE;    /* disable execution mode */
            fclose(fp_keys);    /* close keystroke input file */
            top_line();         /* redisplay top line */
        }
        return;
    }
    else {
        wait_for_key(&key1, &key2);
/*
    If in capture mode, write the keystroke combo out to the file.
*/
        if (capture) {
            fputc(key1, fp_keys);
            fputc(key2, fp_keys);
        }
    }
}

printls(row,col,str)
int row, col;
char *str;
{
    locate(row, col);
    cprintf("%s", str);
}

locate(row, col)

int     row, col;
{
    union REGS  regs;

    regs.h.ah = 2;
    regs.x.bx = 0;
    regs.h.dh = row - 1;
    regs.h.dl = col - 1;
    int86(0x10, &regs, &regs);
}

cls(ulh_row, ulh_col, lrh_row, lrh_col)

int     ulh_row, ulh_col, lrh_row, lrh_col;
{
    union REGS  regs;

    regs.x.ax = 0x600;
    regs.h.ch = ulh_row - 1;
    regs.h.cl = ulh_col - 1;
    regs.h.dh = lrh_row - 1;
    regs.h.dl = lrh_col - 1;
    regs.h.bh = 7;
    int86(0x10, &regs, &regs);
}

scroll_up(ulh_row, ulh_col, lrh_row, lrh_col)

int     ulh_row, ulh_col, lrh_row, lrh_col;
{
    union REGS  regs;

    regs.x.ax = 0x601;
    regs.h.ch = ulh_row - 1;
    regs.h.cl = ulh_col - 1;
    regs.h.dh = lrh_row - 1;
    regs.h.dl = lrh_col - 1;
    regs.h.bh = 7;
    int86(0x10, &regs, &regs);
}

scroll_down(ulh_row, ulh_col, lrh_row, lrh_col)

int     ulh_row, ulh_col, lrh_row, lrh_col;
{
    union REGS  regs;

    regs.x.ax = 0x701;
    regs.h.ch = ulh_row - 1;
    regs.h.cl = ulh_col - 1;
    regs.h.dh = lrh_row - 1;
    regs.h.dl = lrh_col - 1;
    regs.h.bh = 7;
    int86(0x10, &regs, &regs);
}

int Prompt()
{
    char    key1, key2;

    do {
        wait_for_key(&key1, &key2);
        key1 = toupper(key1);
        if(key1 == ESC || key1 == *yesmsg || key1 == *nomsg)
            break;
    } FOREVER;

    return(key1);
}
