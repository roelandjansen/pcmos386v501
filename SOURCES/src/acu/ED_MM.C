/*
*****************************************************************************
*
*   MODULE NAME:    Edit_mm_options
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  6/22/90
*
*   REVISION DATE:  6/22/90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Presents Memory Management information for
*                   the user to edit.
*
*
*               (C) Copyright 1990, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Edit_mm_options();
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
#define MAX_FIELD   2
#define FOREVER     while(1)
#define HEADER      " Memory Management "
#define TRAILER     " F1=HELP  F2=OPTIONS  ESC=EXIT "
#define PRESS_KEY   ">> Press ANY key to continue <<"

#include <stdlib.h>
#include <rsa\rsa.h>
#include <rsa\stdusr.h>
#include <rsa\keycodes.h>

extern unsigned char    auto_freemem,
                        CONFIG_changed,
                        memdev_installed;

extern char     memdev_driver[],
                memdev_opt[],
                *memdev_list[],
                *prompt_lines[];

extern int      _$fcolor,
                fmap[][2],
                _$bar_color,
                prompt_cpos[];

Edit_mm_options()
{
    unsigned char       found;

    char    *header,
            buffer[21],
            *msg_list[23],
            *opt_list[23];

    int     i,
            opt,
            fnum,
            term,
            *i2val,
            *video,
            def_opt;
/*
    Initialize.
*/
    i2val = (int *) buffer;

    if(!strcmpi(memdev_driver, "NONE") || !strcmpi(memdev_driver, "$286N.SYS"))
        memdev_installed = 0;
    else
        memdev_installed = 1;

    fmap[0][0] = CH_FIELD;
    fmap[0][1] = 12;
    fmap[1][0] = CH_FIELD;
    fmap[1][1] = 2;
    fmap[2][0] = CH_FIELD;
    fmap[2][1] = 6;
/*
    Draw a box on the screen with the specified options.
*/
    video = save_video_region(101, 2580);
    prompt_lines[0] = "MEMDEV Driver: ____________";
    prompt_lines[1] = "MEMDEV Option: __";
    prompt_lines[2] = "FREEMEM Mode: ______";
    prompt_lines[3] = "";
    Draw_edit_box(HEADER, TRAILER, prompt_lines, prompt_cpos);
/*
    Get keyboard input.
*/
    fnum = 0;
    for(i=0; i<=MAX_FIELD; ++i)
        Display_mm_option(i);

    do {
        term = Read_field(4, prompt_cpos[fnum], fmap[fnum][0], fmap[fnum][1],
            _$bar_color, buffer);

        if(term == ESC)
            break;
        else if(term == NO_DATA)
            if(memdev_installed)
                Display_mm_option(fnum++);
            else
                Display_mm_option(fnum);    /* Don't move on */
        else if(term == FKEY) {
            if(buffer[0] == DOWN) {
                if(!memdev_installed) {
                    Deny_mm_options();
                    Display_mm_option(fnum);
                }
                else
                    Display_mm_option(fnum++);
            }
            else if(buffer[0] == UP) {
                if(!memdev_installed) {
                    Deny_mm_options();
                    Display_mm_option(fnum);
                }
                else
                    Display_mm_option(fnum--);
            }
            else if(buffer[0] == F1) {
                switch (fnum) {
                    case 0:
                        display_help("MEMDEV", 12);
                        break;
                    case 1:
                        display_help("MEMDEV-OPT", 12);
                        break;
                    case 2:
                        display_help("FREEMEM", 12);
                        break;
                }
            }
            else if(buffer[0] == F2) {

                Display_mm_option(fnum);    /* Clears color bar */
/*
    Present list of options.
*/
                switch (fnum) {
                    case 0:
                        def_opt = 0;
                        header = " MEMDEV Drivers ";
                        while(strlen(memdev_list[def_opt])) {
                            if(strcmpi(memdev_driver, memdev_list[def_opt]) == 0)
                                break;
                            def_opt++;
                        }
                        if(strlen(memdev_list[def_opt]) == 0)
                            def_opt = 0;
                        opt = select_option(-1, 5, memdev_list, def_opt,
                                                    header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            strcpy(memdev_driver, memdev_list[opt]);
                            CONFIG_changed = 1;
                        }

                        if(!strcmpi(memdev_driver, "NONE") || !strcmpi(memdev_driver, "$286N.SYS")) {
                            memdev_installed = 0;
                            strcpy(memdev_opt, "NO");
                            auto_freemem = 0;
                        }
                        else
                            memdev_installed = 1;

                        for(i=0; i<=MAX_FIELD; ++i)
                            Display_mm_option(i);

                        break;

                    case 1:
                        if(strlen(memdev_opt) != 0) {
                            if(!strcmpi(memdev_opt, "/C"))
                                def_opt = 1;
                            else if(!strcmpi(memdev_opt, "/P"))
                                def_opt = 2;
                            else if(!strcmpi(memdev_opt, "/E"))
                                def_opt = 3;
                            else if(!strcmpi(memdev_opt, "/X"))
                                def_opt = 4;
                            else if(!strcmpi(memdev_opt, "/M"))
                                def_opt = 5;
                            else
                                def_opt = 0;
                        }
                        header = " MEMDEV Options ";
                        opt_list[0] = " * None *";
                        opt_list[1] = "/C Compaq 386/20e";
                        opt_list[2] = "/P IBM PS/2 Model 50, 60 or 80";
                        opt_list[3] = "/E System with Emulex Hard Drive";
                        opt_list[4] = "/X IBM XT Personal Computer";
                        opt_list[5] = "/M System with SCSI or ESDI drive";
                        opt_list[6] = "";
                        opt = select_option(-1, 6, opt_list, def_opt,
                                                    header, "", RESTORE_VIDEO);
                        if(opt == 0) {
                            strcpy(memdev_opt, "NO");
                            CONFIG_changed = 1;
                        }
                        else if(opt != -1) {
                            memdev_opt[0] = '/';
                            memdev_opt[1] = " CPEXM"[opt];
                            memdev_opt[2] = '\0';
                            CONFIG_changed = 1;
                        }
                        break;
                    case 2:
                        Edit_freemem();
                }
                Display_mm_option(fnum);
            }
        }
        else if(term == ENTER) {
            switch(fnum) {
                case 0:
                    strupr(buffer);
                    found = 0;
                    for(i=0; strlen(memdev_list[i]); ++i) {
                        if(!strcmp(buffer, memdev_list[i]))
                            found = 1;
                    }
                    if(found) {
                        strcpy(memdev_driver, buffer);
                        CONFIG_changed = 1;
                        if(!strcmpi(memdev_driver, "NONE") || !strcmpi(memdev_driver, "$286N.SYS")) {
                            memdev_installed = 0;
                            strcpy(memdev_opt, "NO");
                            auto_freemem = 0;
                        }
                        else
                            memdev_installed = 1;

                        for(i=0; i<=MAX_FIELD; ++i)
                            Display_mm_option(i);

                        if(memdev_installed)
                            fnum++;
                    }
                    else {
                        Bad_option_message();
                        Display_mm_option(fnum);
                    }

                    break;
                case 1:
                    strupr(buffer);
                    if(buffer[0] == '/' && strchr("CPEXM", buffer[1]) ||
                                        !strcmp(buffer, "NO")) {
                        strcpy(memdev_opt, buffer);
                        Display_mm_option(fnum++);
                        CONFIG_changed = 1;
                    }
                    else {
                        Bad_option_message();
                        Display_mm_option(fnum);
                    }
                    break;
                case 2:
                    strupr(buffer);
                    found = 1;
                    if(!strcmp(buffer, "NONE"))
                        auto_freemem = 0;
                    else if(!strcmp(buffer, "AUTO"))
                        auto_freemem = 1;
                    else if(!strcmp(buffer, "MANUAL"))
                        auto_freemem = 2;
                    else {
                        found = 0;
                        Bad_option_message();
                        Display_mm_option(fnum);
                    }
                    if(found)
                        Display_mm_option(fnum++);
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

Display_mm_option(int i)
{
    int     color;

    if(memdev_installed)
        color = _$fcolor;
    else
        color = (_$fcolor & 0xF0) | 0xC;

    switch(i) {
        case 0:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], _$fcolor, memdev_driver);
            break;
        case 1:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], color, memdev_opt);
            break;
        case 2:
            scr(2, prompt_cpos[i], fmap[i][1], color);
            switch(auto_freemem) {
                case 0:
                    dputs("NONE");
                    break;
                case 1:
                    dputs("AUTO");
                    break;
                case 2:
                    dputs("MANUAL");
            }
    }
}

Deny_mm_options()
{
    char    *msg_list[6];

    msg_list[0] = "No memory management has been";
    msg_list[1] = "installed.  Cannot set other";
    msg_list[2] = "options.";
    msg_list[3] = " ";
    msg_list[4] = PRESS_KEY;
    msg_list[5] = "";
    USR_message(-1, msg_list, WARNING, 0, PAUSE_FOR_KEY);
}
