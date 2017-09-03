/*
*****************************************************************************
*
*   MODULE NAME:    Edit_video_options
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
*   DESCRIPTION:    Presents Video Display information for the user to
*                   edit.
*
*               (C) Copyright 1990, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Edit_video_options();
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
#define HEADER      " Video Configuration "
#define TRAILER     " F1=HELP  F2=OPTIONS  ESC=EXIT "
#define PRESS_KEY   ">> Press ANY key to continue <<"

#include <stdlib.h>
#include <rsa\rsa.h>
#include <rsa\stdusr.h>
#include <rsa\keycodes.h>

extern unsigned char    CONFIG_changed,
                        maximize_vtype;

extern char     *prompt_lines[];

extern int      vtype,
                add_SMP,
                _$fcolor,
                vdt_type,
                _$bar_color,
                prompt_cpos[],
                fmap[][2];

Edit_video_options()
{
    unsigned char       found,      /* General purpose flag */
                        range_error;

    char    *header,
            buffer[21],
            *msg_list[23],
            *opt_list[23];

    int     i,
            opt,
            cpos,
            fnum,
            term,
            i2temp,
            *i2val,
            *video,
            def_opt;

/*
    Initialize.
*/
    i2val = (int *) buffer;

    if(vdt_type < 2) {          /* Never on EGA or VGA */
        if(maximize_vtype)      /* If read from CONFIG.SYS */
            CONFIG_changed = 1;
        maximize_vtype = 0;
    }
/*
    Free the area occupied by the current vtype.
*/
    switch(vtype) {
        case 1:
        case 2:
            Unlock_himem_range(0xA0000, 64);      /* 64K range locked */
            break;
        case 3:
            Unlock_himem_range(0xA0000, 80);
            break;
        case 4:
            Unlock_himem_range(0xA0000, 96);
            break;
        case 5:
            Unlock_himem_range(0xA0000, 64);
    }


    video = save_video_region(101, 2580);

    fmap[0][0] = I2_FIELD;
    fmap[0][1] = 1;
    fmap[1][0] = CH_FIELD;
    fmap[1][1] = 1;
/*
    Draw a box on the screen with the specified options.
*/
    prompt_lines[0] = "Console display type (VTYPE): _";
    prompt_lines[1] = "Fill foreground task to maximum? (Y/N): _";
    prompt_lines[2] = "";

    Draw_edit_box(HEADER, TRAILER, prompt_lines, prompt_cpos);
/*
    Get keyboard input.
*/
    fnum = 0;
    for(i=0; i<2; ++i)
        Display_video_option(i);

    do {
        term = Read_field(4, prompt_cpos[fnum], fmap[fnum][0], fmap[fnum][1],
            _$bar_color, buffer);

        if(term == ESC)
            break;
        else if(term == NO_DATA)
            Display_video_option(fnum++);
        else if(term == FKEY) {
            if(buffer[0] == DOWN)
                Display_video_option(fnum++);
            else if(buffer[0] == UP)
                Display_video_option(fnum--);
            else if(buffer[0] == F1) {
                switch (fnum) {
                    case 0:
                        display_help("VTYPE", 12);
                        break;
                    case 1:
                        display_help("VTYPE-FILL", 12);
                        break;
                }
            }
            else if(buffer[0] == F2) {

                Display_video_option(fnum);    /* Clears color bar */
/*
    Present list of options.
*/
                switch (fnum) {
                    case 0:
                        header =      " Video Display Type ";
                        opt_list[0] = " 0  ** No VTYPE ** ";
                        opt_list[1] = " 1  A0000-B0000  16K (MDA/CGA)";
                        opt_list[2] = " 2  A0000-B0000   4K (MDA/CGA)";
                        opt_list[3] = " 3  A0000-B4000  16K (CGA)";
                        opt_list[4] = " 4  A0000-B8000  16K (CGA)";
                        opt_list[5] = " 5  A0000-B0000  32K (Herc/MDA/VNA)";
                        opt_list[6] = "";
                        opt = select_option(-1, 6, opt_list, vtype, header, "", RESTORE_VIDEO);

                        if(opt != -1) {
                            if(opt != 0 && vdt_type < 2) {
                                msg_list[0] = "VTYPE MUST be specified as";
                                msg_list[1] = "0 on a VGA or EGA display.";
                                msg_list[2] = " ";
                                msg_list[3] = PRESS_KEY;
                                msg_list[4] = "";
                                USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
                                break;
                            }

                            range_error = 0;
                            i2temp = atoi(opt_list[opt]);
                            switch(i2temp) {
                                case 1:
                                case 2:
                                    if(!Check_himem_range(0xA0000, 64))
                                        range_error = 1;
                                    break;
                                case 3:
                                    if(!Check_himem_range(0xA0000, 80))
                                        range_error = 1;
                                    break;
                                case 4:
                                    if(!Check_himem_range(0xA0000, 96))
                                        range_error = 1;
                                    break;
                                case 5:
                                    if(!Check_himem_range(0xA0000, 64))
                                        range_error = 1;
                            }

                            if(range_error) {
                                Bad_memory_address_message();
                                break;
                            }
                            if(i2temp != vtype) {
                                CONFIG_changed = 1;
                                vtype = i2temp;
                            }
                        }
                        break;
                    case 1:
                        if(vdt_type < 2) {
                            Deny_vtype_max();
                            break;
                        }

                        if(vtype == 0) {
                            msg_list[0] = "VTYPE must be specified first.";
                            msg_list[1] = " ";
                            msg_list[2] = PRESS_KEY;
                            msg_list[3] = "";
                            USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
                            break;
                        }

                        header = " Max Foreground? ";
                        opt_list[0] = "NO";
                        opt_list[1] = "YES";
                        opt_list[2] = "";
                        opt = select_option(-1, 2, opt_list, maximize_vtype, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            if(maximize_vtype != opt)
                                CONFIG_changed = 1;
                            maximize_vtype = opt;
                        }
                        break;
                }
                Display_video_option(fnum);
            }
        }
        else if(term == ENTER) {
            switch(fnum) {
                case 0:
                    if(*i2val < 0 || *i2val > 5) {
                        Bad_option_message();
                        Display_video_option(fnum);
                    }
                    else {
                        range_error = 0;
                        switch(*i2val) {
                            case 1:
                            case 2:
                                if(!Check_himem_range(0xA0000, 64))
                                    range_error = 1;
                                break;
                            case 3:
                                if(!Check_himem_range(0xA0000, 80))
                                    range_error = 1;
                                break;
                            case 4:
                                if(!Check_himem_range(0xA0000, 96))
                                    range_error = 1;
                                break;
                            case 5:
                                if(!Check_himem_range(0xA0000, 64))
                                    range_error = 1;
                        }
                        if(range_error) {
                            Bad_memory_address_message();
                            Display_video_option(fnum);
                            break;
                        }

                        if(vtype != *i2val) {
                            CONFIG_changed = 1;
                            vtype = *i2val;
                        }
                        Display_video_option(fnum++);
                    }
                    break;
                case 1:
                    if(vdt_type < 2) {          /* Never on EGA or VGA */
                        Deny_vtype_max();
                        Display_video_option(fnum);
                        break;
                    }

                    buffer[0] = toupper(buffer[0]);
                    if(buffer[0] == 'Y') {
                        if(vtype == 0) {
                            msg_list[0] = "VTYPE must be specified first.";
                            msg_list[1] = " ";
                            msg_list[2] = PRESS_KEY;
                            msg_list[3] = "";
                            USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
                        }
                        else {
                            if(maximize_vtype == 0)
                                CONFIG_changed = 1;
                            maximize_vtype = 1;
                        }
                    }
                    else {
                        if(maximize_vtype != 0)
                            CONFIG_changed = 1;
                        maximize_vtype = 0;
                    }
                    Display_video_option(fnum++);
                    break;
            }
        }

        if(fnum > 1)
            fnum = 0;
        else if(fnum < 0)
            fnum = 1;

    } FOREVER;
/*
    Done editing options.
*/
    switch(vtype) {
        case 1:
        case 2:
            Lock_himem_range(0xA0000, 64);      /* 64K range locked */
            break;
        case 3:
            Lock_himem_range(0xA0000, 80);
            break;
        case 4:
            Lock_himem_range(0xA0000, 96);
            break;
        case 5:
            Lock_himem_range(0xA0000, 64);
    }

    restore_video_region(101, 2580, video);
}

Display_video_option(int i)
{
    int     color;


    switch(i) {
        case 0:
            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], _$fcolor, &vtype);
            break;
        case 1:
            if(vdt_type < 2)
                color = (_$fcolor & 0xF0) | 0x0C;
            else
                color = _$fcolor;

            put_field(1, fmap[i][0], prompt_cpos[i], fmap[i][1], color, &"NY"[maximize_vtype]);
    }
}

Deny_vtype_max()
{
    char *msg_list[6];

    msg_list[0] = "This option is not available";
    msg_list[1] = "for system consoles using EGA";
    msg_list[2] = "or VGA display systems.";
    msg_list[3] = " ";
    msg_list[4] = PRESS_KEY;
    msg_list[5] = "";
    USR_message(-1, msg_list, WARNING, 0, PAUSE_FOR_KEY);
}
