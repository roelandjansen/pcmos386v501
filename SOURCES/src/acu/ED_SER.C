/*
*****************************************************************************
*
*   MODULE NAME:    Edit_serial_parms
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  30-May-90
*
*   REVISION DATE:  30-May-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Provides the interface for the user of ACU to
*                   edit the command-line parameters for the $SERIAL.SYS
*                   driver.
*
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*   USAGE:  Edit_serial_parms();
*
*****************************************************************************
*							>> REVISION LOG <<
*
* DATE		PROG		DESCRIPTION OF REVISION
* ----		----		-----------------------
*
*****************************************************************************
*
*/
#define MAX_FIELD   1
#define HEADER  " Serial Port Driver "
#define TRAILER " F1=HELP  F2=OPTIONS  ESC=EXIT "
#define FOREVER while(1)
#define PRESS_KEY   ">> Press ANY key to continue <<"

#include <ctype.h>
#include <rsa\keycodes.h>
#include <rsa\stdusr.h>
#include <rsa\rsa.h>
#include "acu.h"

extern unsigned char    CONFIG_changed,
                        serial_options,
                        serial_installed;

extern char             *prompt_lines[];

extern int              _$fcolor,
                        _$bar_color,
                        prompt_cpos[];

extern struct SERIAL_PARMS  serial_list[];

Edit_serial_parms()
{


    int     i,
            opt,
            fnum,
            term,
            def_opt,
            *video;

    char    *header,
            buffer[10],
            *opt_list[23],
            *msg_list[23];
/*
    Free all entries in the I/O map taken by these options, temporarily.
    (To avoid collision if user tries to reassign same values).
*/
    if(serial_installed) {
        if(serial_options) {
            for(i=0; i<24; ++i) {
                if(serial_list[i].sp_address != 0)
                    Unlock_port_range(serial_list[i].sp_address, 8);
            }
        }
        else {
            Unlock_port_range(0x3F8, 8);
            Unlock_port_range(0x2F8, 8);
        }
    }

    video = save_video_region(101, 2580);

    prompt_lines[0] = "Install $SERIAL.SYS? (Y/N): _";
    prompt_lines[1] = "Use Advanced Options? (Y/N): _";
    prompt_lines[2] = "";

    Draw_edit_box(HEADER, TRAILER, prompt_lines, prompt_cpos);

    for(i=0; i<=MAX_FIELD; ++i)
        Display_serial_switch(i);
/*
    Ask the user if he wants $SERIAL.SYS installed.
*/
    fnum = 0;
    do {
        term = Read_field(4, prompt_cpos[fnum], 1, 1, _$bar_color, buffer);

        if(term == ESC)
            break;

        else if(term == FKEY) {
            if(buffer[0] == DOWN) {
                if(fnum == 0) {
                    if(serial_installed) {
                        Display_serial_switch(fnum);
                        fnum = 1;
                    }
                    else
                        Deny_advanced_serial();
                }
                else {
                    if(serial_options)
                        Edit_serial_options();
                    Display_serial_switch(fnum);
                    fnum = 1;
                }
            }
            else if(buffer[0] == UP) {
                if(fnum == 0) {
                    if(serial_options)
                        Edit_serial_options();
                    Display_serial_switch(fnum);
                    fnum = 1;
                }
                else {
                    if(serial_installed) {
                        Display_serial_switch(fnum);
                        fnum = 0;
                    }
                    else
                        Deny_advanced_serial();
                }
            }
            else if(buffer[0] == F1) {
                switch(fnum) {
                    case 0:
                        display_help("SERIAL-PORT-DRIVER", 12);
                        break;
                    case 1:
                        display_help("SERIAL-PORT-OPTIONS", 12);
                }
            }
            else if(buffer[0] == F2) {
                switch(fnum) {
                    case 0:
                        header = " Install Driver? ";
                        opt_list[0] = "NO";
                        opt_list[1] = "YES";
                        opt_list[2] = "";
                        if(serial_installed != 0)
                            def_opt = 1;
                        else
                            def_opt = 0;
                        opt = select_option(-1, 2, opt_list, def_opt, header, "", RESTORE_VIDEO);
                        if(opt == -1)
                            break;
                        serial_installed = opt;
                        CONFIG_changed = 1;
                        Display_serial_switch(0);
                        Display_serial_switch(1);
                        break;
                    case 1:
                        header = " Use Advanced Options? ";
                        opt_list[0] = "NO";
                        opt_list[1] = "YES";
                        opt_list[2] = "";
                        opt = select_option(-1, 2, opt_list, serial_options, header, "", RESTORE_VIDEO);
                        if(opt == -1)
                            break;
                        else if(opt == 0)
                            serial_options = 0;
                        else {
                            serial_options = 1;
                            Edit_serial_options();
                        }
                        CONFIG_changed = 1;
                        Display_serial_switch(fnum);
                }
            }
        }
        else if(term == NO_DATA) {
            if(fnum == 0) {
                if(serial_installed)
                    Display_serial_switch(fnum++);
                else
                    Display_serial_switch(fnum);    /* Don't move on */
            }
            else {
                if(serial_options)
                    Edit_serial_options();
                Display_serial_switch(fnum++);
            }
        }
        else if(term == ENTER) {
            buffer[0] = toupper(buffer[0]);

            switch(fnum) {
                case 0:
                    if(buffer[0] == 'Y')
                        serial_installed = 1;
                    else
                        serial_installed = 0;
                    CONFIG_changed = 1;
                    Display_serial_switch(0);
                    Display_serial_switch(1);
                    if(serial_installed)
                        fnum++;
                    break;
                case 1:
                    if(buffer[0] == 'Y') {
                        serial_options = 1;
                        Edit_serial_options();
                    }
                    else
                        serial_options = 0;
                    CONFIG_changed = 1;
                    Display_serial_switch(fnum++);
            }
        }

        if(fnum > 1)
            fnum = 0;
        else if(fnum < 0)
            fnum = 1;

    } FOREVER;
/*
    Update the address map.
*/
    if(serial_installed) {
        if(serial_options) {
            for(i=0; i<24; ++i) {
                if(serial_list[i].sp_address != 0)
                    Lock_port_range(serial_list[i].sp_address, 8);
            }
        }
        else {
            Lock_port_range(0x3F8, 8);
            Lock_port_range(0x2F8, 8);
        }
    }
/*
    Return to calling routine.
*/
    restore_video_region(101, 2580, video);
}

Display_serial_switch(int fnum)
{
    int     color;

    switch(fnum) {
        case 0:
            put_field(1, CH_FIELD, prompt_cpos[0], 1, _$fcolor, &"NY"[serial_installed]);
            break;
        case 1:
            if(serial_installed)
                color = _$fcolor;
            else
                color = (_$fcolor & 0xF0) | 0x0C;

            put_field(1, CH_FIELD, prompt_cpos[1], 1, color, &"NY"[serial_options]);
    }
}

Deny_advanced_serial()
{
    char *msg_list[10];

    msg_list[0] = "Please indicate that the Serial";
    msg_list[1] = "Driver is to be installed before";
    msg_list[2] = "attempting to use the advanced";
    msg_list[3] = "options.";
    msg_list[4] = " ";
    msg_list[5] = PRESS_KEY;
    msg_list[6] = "";
    USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
}
