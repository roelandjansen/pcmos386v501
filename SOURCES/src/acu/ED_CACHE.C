/*
*****************************************************************************
*
*   MODULE NAME:    Edit_cache_options
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  6/27/90
*
*   REVISION DATE:  6/27/90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Presents Disk caching options for the user to edit.
*
*               (C) Copyright 1990, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Edit_cache_options();
*
*   PARAMETERS:
*
* NAME          TYPE    USAGE       DESCRIPTION
* ----          ----    -----       -----------
*
*****************************************************************************
*                           >> REVISION LOG <<
*
* DATE      PROG        DESCRIPTION OF REVISION
* ----      ----        -----------------------
*
*****************************************************************************
*
*/
#define FOREVER     while(1)
#define HEADER      " Disk Caching "
#define TRAILER     " F1=HELP  F2=OPTIONS  ESC=EXIT "
#define PRESS_KEY   ">> Press ANY key to continue <<"

#include <stdlib.h>
#include <ctype.h>
#include <malloc.h>
#include <rsa\rsa.h>
#include <rsa\stdusr.h>
#include <rsa\keycodes.h>

extern unsigned char    CONFIG_changed;

extern char         cache_list[],
                    *prompt_lines[];

extern unsigned     cache_unit,
                    last_write,
                    first_write;

extern int      _$fcolor,
                fmap[][2],
                cache_size,
                _$bar_color,
                ext_mem_free,
                ext_mem_used,
                prompt_cpos[];

Edit_cache_options()
{
    unsigned char       found;      /* General purpose flag */

    char    *header,
            buffer[31],
            *msg_list[23],
            *opt_list[23],
            *opt_text[51];

    int     i,
            j,
            len,
            opt,
            cpos,
            fnum,
            term,
            i2temp,
            *i2val,
            *video,
            def_opt;
/*
    Initialize variables.  Back-out the memory used by the cache if set.
*/
    i2val = (int *) buffer;

    if(cache_size == 0 && ext_mem_free == 0) {
        msg_list[0] = "Cannot install a CACHE.";
        msg_list[1] = "No Extended Memory free.";
        msg_list[2] = " ";
        msg_list[3] = PRESS_KEY;
        msg_list[4] = "";
        USR_message(-1, msg_list, WARNING, 0, PAUSE_FOR_KEY);
        return;
    }

    ext_mem_used -= cache_size;
    ext_mem_free += cache_size;

    for(i=0; i<51; ++i)
        opt_text[i] = malloc(64);

    video = save_video_region(101, 2580);

    fmap[0][0] = U2_FIELD;
    fmap[0][1] = 5;
    fmap[1][0] = CH_FIELD;
    fmap[1][1] = 15;
    fmap[2][0] = U2_FIELD;      /* To avoid negative entries only */
    fmap[2][1] = 2;
    fmap[3][0] = U2_FIELD;
    fmap[3][1] = 4;
    fmap[4][0] = U2_FIELD;
    fmap[4][1] = 4;
/*
    Draw a box on the screen with the specified options.
*/
    prompt_lines[0] = "Cache size (KB): _____";
    prompt_lines[1] = "Drives cached: _______________";
    prompt_lines[2] = "Cache unit size (KB): __";
    prompt_lines[3] = "First write time (sec): ____";
    prompt_lines[4] = "Last write time (sec): ____";
    prompt_lines[5] = "";

    Draw_edit_box(HEADER, TRAILER, prompt_lines, prompt_cpos);
    fnum = 0;
    for(i=0; i<5; ++i)
        Display_cache_option(i);
/*
    Get keyboard input.
*/
    do {
        term = Read_field(4, prompt_cpos[fnum], fmap[fnum][0], fmap[fnum][1],
            _$bar_color, buffer);

        if(term == ESC)
            break;
        else if(term == NO_DATA) {
            if(cache_size > 0)
                Display_cache_option(fnum++);
            else
                Display_cache_option(fnum);     /* Don't move on */
        }
        else if(term == FKEY) {
            if(buffer[0] == DOWN) {
                if(cache_size == 0)
                    Deny_cache_options();
                else
                    Display_cache_option(fnum++);
            }
            else if(buffer[0] == UP) {
                if(cache_size == 0)
                    Deny_cache_options();
                else
                    Display_cache_option(fnum--);
            }
            else if(buffer[0] == F1) {
                switch (fnum) {
                    case 0:
                        display_help("CACHE-SIZE", 12);
                        break;
                    case 1:
                        display_help("CACHE-LIST", 12);
                        break;
                    case 2:
                        display_help("CACHE-UNIT", 12);
                        break;
                    case 3:
                        display_help("FIRSTW", 12);
                        break;
                    case 4:
                        display_help("LASTW", 12);
                }
            }
            else if(buffer[0] == F2) {

                Display_cache_option(fnum);    /* Clears color bar */
/*
    Present list of options.
*/
                switch (fnum) {
                    case 0:
                        header = " Cache size ";
                        def_opt = 0;
                        for(i=0; i<50; ++i) {
                            if(i == 0) {
                                sprintf(opt_text[i], "*** No Cache ***");
                                continue;
                            }
                            i2temp = 128 * i;
                            if(i2temp > ext_mem_free)
                                break;
                            sprintf(opt_text[i], "%5d KB", i2temp);
                            if(cache_size == i2temp)
                                def_opt = i;
                        }
                        opt_text[i][0] = '\0';

                        opt = select_option(-1, 8, opt_text, def_opt, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            i2temp = opt * 128;
                            if(i2temp > ext_mem_free)
                                Not_enough_memory_message();
                            else {
                                if(i2temp != cache_size) {
                                    CONFIG_changed = 1;
                                    cache_size = i2temp;
                                }
                            }
                            for(i=0; i<5; ++i)
                                Display_cache_option(i);
                        }
                        break;
                    case 1:
                        header = " Drives to cache ";
                        opt_list[0] = "ALL Drives";
                        opt_list[1] = "C";
                        opt_list[2] = "C,D";
                        opt_list[3] = "C,D,E";
                        opt_list[4] = "C,D,E,F";
                        opt_list[5] = "";
                        opt = select_option(-1, 5, opt_list, 0, header, "", RESTORE_VIDEO);
                        if(opt == -1)
                            break;
                        else if(opt == 0)
                            strcpy(cache_list, "ALL");
                        else {
                            strcpy(cache_list, opt_list[opt]);
                            squeeze(cache_list, ',');
                        }
                        CONFIG_changed = 1;
                        break;      /* No options available here */
                    case 2:
                        header = " Cache unit size ";
                        opt_list[0] = "2 KB";
                        opt_list[1] = "4 KB";
                        opt_list[2] = "6 KB";
                        opt_list[3] = "8 KB";
                        opt_list[4] = "";
                        opt = select_option(-1, 4, opt_list, 0, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            cache_unit = (opt + 1) * 2;
                            CONFIG_changed = 1;
                        }
                        break;
                    case 3:
                        header = " FIRST write time ";
                        opt_list[0] = " 0 sec.";
                        opt_list[1] = " 2 sec.";
                        opt_list[2] = " 4 sec.";
                        opt_list[3] = " 6 sec.";
                        opt_list[4] = " 8 sec.";
                        opt_list[5] = "10 sec.";
                        opt_list[6] = "12 sec.";
                        opt_list[7] = "14 sec.";
                        opt_list[8] = "16 sec.";
                        opt_list[9] = "18 sec.";
                        opt_list[10] = "20 sec.";
                        opt_list[11] = "";
                        opt = select_option(-1, 5, opt_list, 0, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            first_write = atoi(opt_list[opt]);
                            CONFIG_changed = 1;
                        }
                        break;
                    case 4:
                        header = " LAST write time ";
                        opt_list[0] = " 0 sec.";
                        opt_list[1] = " 2 sec.";
                        opt_list[2] = " 4 sec.";
                        opt_list[3] = " 6 sec.";
                        opt_list[4] = " 8 sec.";
                        opt_list[5] = "10 sec.";
                        opt_list[6] = "12 sec.";
                        opt_list[7] = "14 sec.";
                        opt_list[8] = "16 sec.";
                        opt_list[9] = "18 sec.";
                        opt_list[10] = "20 sec.";
                        opt_list[11] = "";
                        opt = select_option(-1, 5, opt_list, 0, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            last_write = atoi(opt_list[opt]);
                            CONFIG_changed = 1;
                        }
                        break;
                }
                Display_cache_option(fnum);
            }
        }
        else if(term == ENTER) {
            switch(fnum) {
                case 0:
                    if(*i2val > ext_mem_free) {
                        Not_enough_memory_message();
                        break;
                    }

                    if(cache_size != *i2val) {
                        CONFIG_changed = 1;
                        cache_size = *i2val;
                    }

                    for(i=0; i<5; ++i)
                        Display_cache_option(i);

                    if(cache_size != 0)
                        fnum++;
                    break;
                case 1:
                    strupr(buffer);
                    squeeze(buffer, ',');
                    len = strlen(buffer);
                    if(len == 0) {
                        Display_cache_option(fnum);
                        break;
                    }
/*
    Did the user specify "ALL"?
*/
                    if(!strcmp(buffer, "ALL")) {
                        if(strcmpi(cache_list, buffer) != 0)
                            CONFIG_changed = 1;
                        strcpy(cache_list, buffer);
                        Display_cache_option(fnum++);
                        break;
                    }
/*
    Check for non-alpha names of drives entered in the cache list.
*/
                    found = 0;
                    for(i=0; i<len; ++i) {
                        if(!isalpha(buffer[i]))
                            found = 1;
                    }
                    if(found) {
                        Bad_data_message();
                        Display_cache_option(fnum);
                        break;
                    }
/*
    Check for duplicate drives entered in the cache list.
*/
                    found = 0;
                    for(i=0; i<len; ++i) {
                        for(j=0; j<len; ++j) {
                            if(j == i)
                                continue;
                            if(buffer[j] == buffer[i])
                                found = 1;
                        }
                    }
                    if(found) {
                        msg_list[0] = "A duplicate drive specification";
                        msg_list[1] = "was entered into the cache list.";
                        msg_list[2] = "Please re-enter the list.";
                        msg_list[3] = " ";
                        msg_list[4] = PRESS_KEY;
                        msg_list[5] = "";
                        USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
                        Display_cache_option(fnum);
                        break;
                    }
/*
    The cache list entered is OK.
*/
                    strcpy(cache_list, buffer);
                    Display_cache_option(fnum++);
                    CONFIG_changed = 1;
                    break;
                case 2:
                    cache_unit = *i2val;
                    Display_cache_option(fnum++);
                    CONFIG_changed = 1;
                    break;
                case 3:
                    first_write = *i2val;
                    Display_cache_option(fnum++);
                    CONFIG_changed = 1;
                    break;
                case 4:
                    last_write = *i2val;
                    Display_cache_option(fnum++);
                    CONFIG_changed = 1;
            }
        }

        if(fnum > 4)
            fnum = 0;
        else if(fnum < 0)
            fnum = 4;

    } FOREVER;
/*
    Done editing options.  Restore video options and add the
    size of the cache into the amount of memory used.
*/
    ext_mem_used += cache_size;
    ext_mem_free -= cache_size;

    restore_video_region(101, 2580, video);

    for(i=0; i<51; ++i)
        free(opt_text[i]);
}

Display_cache_option(int i)
{
    int     color;

    if(cache_size != 0)
        color = _$fcolor;
    else
        color = (_$fcolor & 0xF0) | 0x0C;

    switch(i) {
        case 0:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], _$fcolor, &cache_size);
            break;
        case 1:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], color, cache_list);
            break;
        case 2:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], color, &cache_unit);
            break;
        case 3:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], color, &first_write);
            break;
        case 4:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], color, &last_write);
            break;
    }
}

Deny_cache_options()
{
    char    *msg_list[10];

    msg_list[0] = "The size of the cache must be defined";
    msg_list[1] = "before any other of the cache options";
    msg_list[2] = "may be modified.";
    msg_list[3] = " ";
    msg_list[4] = PRESS_KEY;
    msg_list[5] = "";
    USR_message(510, msg_list, ERROR, 0, PAUSE_FOR_KEY);
}
