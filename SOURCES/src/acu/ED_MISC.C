/*
*****************************************************************************
*
*   MODULE NAME:    Edit_misc_options
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  6/28/90
*
*   REVISION DATE:  6/28/90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Allows user to edit miscellaneous MOS configuration
*                   options.
*
*               (C) Copyright 1990, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Edit_misc_options();
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
#define MAX_FIELD   4
#define FOREVER     while(1)
#define HEADER      " Miscellaneous Options "
#define TRAILER     " F1=HELP  F2=OPTIONS  ESC=EXIT "
#define PRESS_KEY   ">> Press ANY key to continue <<"

#include <stdlib.h>
#include <ctype.h>
#include <rsa\rsa.h>
#include <rsa\stdusr.h>
#include <rsa\keycodes.h>

extern unsigned char    share_coproc,
                        coproc_present,
                        CONFIG_changed;

extern char         system_path[],
                    country_name[],
                    *prompt_lines[],
                    *country_names[];

extern int      add_SMP,
                _$fcolor,
                fmap[][2],
                max_tasks,
                _$bar_color,
                country_code,
                prompt_cpos[],
                country_codes[];

Edit_misc_options()
{
    unsigned char       found;      /* General purpose flag */

    char    *header,
            buffer[31],
            *msg_list[23],
            *opt_list[23];

    int     i,
            j,
            len,
            opt,
            cpos,
            fnum,
            term,
            *i2val,
            *video,
            def_opt;
/*
    Initialize.
*/
    i2val = (int *) buffer;

    video = save_video_region(101, 2580);

    fmap[0][0] = CH_FIELD;
    fmap[0][1] = 1;
    fmap[1][0] = I2_FIELD;
    fmap[1][1] = 3;
    fmap[2][0] = I2_FIELD;
    fmap[2][1] = 2;
    fmap[3][0] = I2_FIELD;
    fmap[3][1] = 3;
    fmap[4][0] = CH_FIELD;
    fmap[4][1] = 30;
/*
    Draw a box on the screen with the specified options.
*/
    prompt_lines[0] = "Share Coprocessor? (Y/N): _";
    prompt_lines[1] = "Country code: ___";
    prompt_lines[2] = "Expected # of tasks: __";
    prompt_lines[3] = "Additional SMP (KB): ___";
    prompt_lines[4] = "System path: ______________________________";
    prompt_lines[5] = "";

    Draw_edit_box(HEADER, TRAILER, prompt_lines, prompt_cpos);
/*
    Get keyboard input.
*/
    fnum = 0;
    for(i=0; i<=MAX_FIELD; ++i)
        Display_misc_option(i);

    do {
        term = Read_field(4, prompt_cpos[fnum], fmap[fnum][0], fmap[fnum][1],
            _$bar_color, buffer);

        if(term == ESC)
            break;
        else if(term == NO_DATA)
            Display_misc_option(fnum++);
        else if(term == FKEY) {
            if(buffer[0] == DOWN)
                Display_misc_option(fnum++);
            else if(buffer[0] == UP)
                Display_misc_option(fnum--);
            else if(buffer[0] == F1) {
                switch (fnum) {
                    case 0:
                        display_help("8087=YES", 12);
                        break;
                    case 1:
                        display_help("COUNTRY", 12);
                        break;
                    case 2:
                        display_help("ACTIVE-TASKS", 12);
                        break;
                    case 3:
                        display_help("ADD-SMP", 12);
                        break;
                    case 4:
                        display_help("SYSTEM-PATH", 12);
                        break;
                }
            }
            else if(buffer[0] == F2) {

                Display_misc_option(fnum);    /* Clears color bar */
/*
    Present list of options.
*/
                switch (fnum) {
                    case 0:
                        if(!coproc_present) {
                            msg_list[0] = "There is no math coprocessor in";
                            msg_list[1] = "your system.  This option cannot";
                            msg_list[2] = "be set.";
                            msg_list[3] = " ";
                            msg_list[4] = PRESS_KEY;
                            msg_list[5] = "";
                            USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
                            Display_misc_option(fnum);
                            break;
                        }
                        header = " Share Coprocessor? ";
                        opt_list[0] = "NO";
                        opt_list[1] = "YES";
                        opt_list[2] = "";
                        opt = select_option(830, 2, opt_list, share_coproc, header, "", RESTORE_VIDEO);
                        if(opt == -1)
                            break;
                        if(opt != share_coproc)
                            CONFIG_changed = 1;
                        share_coproc = opt;
                        Display_misc_option(fnum);
                        break;
                    case 1:
                        def_opt = 0;
                        for(i=0; country_codes[i] != 0; ++i) {
                            if(country_code == country_codes[i]) {
                                def_opt = i;
                                break;
                            }
                        }
                        header = " Country ";
                        opt = select_option(-1, 10, country_names, def_opt, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            if(country_code != country_codes[opt]) {
                                CONFIG_changed = 1;
                                country_code = country_codes[opt];
                                strcpy(country_name, country_names[opt]);
                            }
                        }
                        Display_misc_option(fnum);
                        break;
                    case 2:
                        switch(max_tasks) {
                            case 1:
                                def_opt = 0;
                                break;
                            case 5:
                                def_opt = 1;
                                break;
                            case 12:
                                def_opt = 2;
                                break;
                            case 25:
                                def_opt = 3;
                                break;
                            default:
                                def_opt = 0;
                        }
                        header = " Expected # of Tasks ";
                        opt_list[0] = "1 task";
                        opt_list[1] = "5 tasks";
                        opt_list[2] = "12 tasks";
                        opt_list[3] = "25 tasks";
                        opt_list[4] = "";
                        opt = select_option(-1, 4, opt_list, def_opt, header, "", RESTORE_VIDEO);
                        if(opt == -1)
                            break;
                        max_tasks = atoi(opt_list[opt]);
                        CONFIG_changed = 1;
                        Display_misc_option(fnum);
                        break;
                    case 3:
                        header = " Additional SMP ";
                        opt_list[0] = "  0 KB";
                        opt_list[1] = " 16 KB";
                        opt_list[2] = " 32 KB";
                        opt_list[3] = " 48 KB";
                        opt_list[4] = " 64 KB";
                        opt_list[5] = " 80 KB";
                        opt_list[6] = " 96 KB";
                        opt_list[7] = "112 KB";
                        opt_list[8] = "128 KB";
                        opt_list[9] = "";
                        opt = select_option(-1, 9, opt_list, 0, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            add_SMP = opt * 16;
                            CONFIG_changed = 1;
                        }
                        Display_misc_option(fnum);
                        break;
                    case 4:
                        No_option_available();
                }
            }
        }
        else if(term == ENTER) {
            switch(fnum) {
                case 0:
                    if(!coproc_present) {
                        msg_list[0] = "There is no math coprocessor in";
                        msg_list[1] = "your system.  This option cannot";
                        msg_list[2] = "be set.";
                        msg_list[3] = " ";
                        msg_list[4] = PRESS_KEY;
                        msg_list[5] = "";
                        USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
                        Display_misc_option(fnum);
                        break;
                    }
                    buffer[0] = toupper(buffer[0]);
                    if(buffer[0] == 'Y')
                        share_coproc = 1;
                    else
                        share_coproc = 0;

                    CONFIG_changed = 1;
                    Display_misc_option(fnum++);
                    break;
                case 1:
                    found = 0;
                    for(i=0; country_codes[i] != 0; ++i) {
                        if(*i2val == country_codes[i]) {
                            found = 1;
                            CONFIG_changed = 1;
                            country_code = country_codes[i];
                            strcpy(country_name, country_names[i]);
                            break;
                        }
                    }
                    if(!found)
                        Bad_option_message();

                    Display_misc_option(fnum);
                    break;
                case 2:
                    if(*i2val < 1) {
                        Bad_data_message();
                        Display_misc_option(fnum);
                        break;
                    }
                    max_tasks = *i2val;
                    CONFIG_changed = 1;
                    Display_misc_option(fnum++);
                    break;
                case 3:
                    if(*i2val > 256) {
                        Bad_data_message();
                        Display_misc_option(fnum);
                    }
                    else {
                        if(*i2val != add_SMP) {
                            CONFIG_changed = 1;
                            add_SMP = *i2val;
                        }
                        Display_misc_option(fnum++);
                    }
                    break;
                case 4:
                    strupr(buffer);
                    if(access(buffer, 0) != 0) {
                        msg_list[0] = "That path does not exist.";
                        msg_list[1] = " ";
                        msg_list[2] = PRESS_KEY;
                        msg_list[3] = "";
                        USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
                        Display_misc_option(fnum);
                        break;
                    }
                    strcpy(system_path, buffer);
                    Display_misc_option(fnum++);
            }
        }

        if(fnum > MAX_FIELD)
            fnum = 0;
        else if(fnum < 0)
            fnum = MAX_FIELD;

    } FOREVER;
/*
    Done editing options.
*/
    restore_video_region(101, 2580, video);
}

Display_misc_option(int i)
{
    int     color;

    switch(i) {
        case 0:
            if(coproc_present)
                color = _$fcolor;
            else
                color = (_$fcolor & 0xF0) | 0x0C;

            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], color, &"NY"[share_coproc]);
            break;
        case 1:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], _$fcolor, &country_code);
            break;
        case 2:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], _$fcolor, &max_tasks);
            break;
        case 3:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], _$fcolor, &add_SMP);
            break;
        case 4:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], _$fcolor, system_path);
    }
}
