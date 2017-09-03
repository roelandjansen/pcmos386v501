/*
*****************************************************************************
*
*   MODULE NAME:    Edit_serial_options();
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utilities
*
*   CREATION DATE:  01-June-90
*
*   REVISION DATE:  01-June-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Displays a window that the user can use to edit
*                   the option list for $SERIAL.SYS
*
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Edit_serial_options();
*
*	PARAMETERS:
*
* NAME			TYPE	USAGE		DESCRIPTION
* ----			----	-----		-----------
*
*****************************************************************************
*							>> REVISION LOG <<
*
* DATE		PROG		DESCRIPTION OF REVISION
* ----		----		-----------------------
*
*   NOTE:
*       The arrays "prompt_lines" , "prompt_cpos" and "fmap" are duplicated
*       locally in this routine because the external versions of those
*       arrays are in use by Edit_serial_parms, which calls this routine.
*
*****************************************************************************
*
*/
#include <ctype.h>
#include <string.h>
#include <rsa\keycodes.h>
#include <rsa\stdusr.h>
#include <rsa\rsa.h>
#include "acu.h"

#define FOREVER     while(1)
#define HEADER      " Serial Driver Options "
#define TRAILER     " F1=HELP  F2=OPTIONS  ESC=EXIT "
#define PRESS_KEY   ">> Press ANY key to continue <<"
#define MAX_FIELD   6

extern struct SERIAL_PARMS  serial_list[];

extern unsigned char    CONFIG_changed;

extern int      _$fcolor,
                _$bar_color;

Edit_serial_options()
{
    unsigned char   found;          /* General purpose flag */

    char    *header,
            buffer[80],
            *opt_list[20],
            *msg_list[20],
            *prompt_lines[8];

    unsigned    *u2val;

    int     i,
            opt,
            cpos,
            fnum,
            term,
            *video,
            *i2val,
            i2temp,
            def_opt,
            fmap[7][2],
            port_index,
            prompt_cpos[7];
/*
    Describe dialog box fields types and lengths.
*/
    fmap[0][0] = I2_FIELD;
    fmap[0][1] = 2;
    fmap[1][0] = HX_FIELD;
    fmap[1][1] = 4;
    fmap[2][0] = U2_FIELD;
    fmap[2][1] = 5;
    fmap[3][0] = U2_FIELD;
    fmap[3][1] = 5;
    fmap[4][0] = CH_FIELD;
    fmap[4][1] = 1;
    fmap[5][0] = I2_FIELD;
    fmap[5][1] = 1;
    fmap[6][0] = CH_FIELD;
    fmap[6][1] = 1;
/*
    Box background data.
*/
    prompt_lines[0] = "Serial Port #: __";
    prompt_lines[1] = "Port Address: ___";
    prompt_lines[2] = "Input buffer size (bytes): _____";
    prompt_lines[3] = "Output buffer size (bytes): _____";
    prompt_lines[4] = "Handshaking Mode: _";
    prompt_lines[5] = "Interrupt Level: _";
    prompt_lines[6] = "Terminal Mode: _";
    prompt_lines[7] = "";
/*
    Other inits.
*/
    i2val = (int *) buffer;
    u2val = (unsigned *) buffer;

    video = save_video_region(101, 2580);
    Draw_edit_box(HEADER, TRAILER, prompt_lines, prompt_cpos);
/*
    Read user input.
*/
    port_index = 0;
    fnum = 0;
    for(i=0; i<=MAX_FIELD; ++i)
        Display_serial_option(port_index, i, prompt_cpos, fmap);

    do {
        term = Read_field(4, prompt_cpos[fnum], fmap[fnum][0], fmap[fnum][1], _$bar_color, buffer);
/*
    If the user pressed the ESC key, he wants to exit.  Before allowing
    him to, though, make sure that all the serial port interrupt levels
    of active ports arein the correct range.
*/
        if(term == ESC) {
            found = 0;
            for(i=0; i<24; ++i) {
                if(serial_list[i].sp_address != 0 &&
                    (serial_list[i].sp_IN < 2 || serial_list[i].sp_IN > 7))
                    found = 1;
            }
/*
    If no problems make good his <ESCape>
*/
            if(!found)
                break;

            msg_list[0] = "  One  or  more  of  the  serial";
            msg_list[1] = "ports you have configured has an";
            msg_list[2] = "incorrect  interrupt  level set.";
            msg_list[3] = "Please   correct   the   problem";
            msg_list[4] = "before  attempting to  exit this";
            msg_list[5] = "screen.";
            msg_list[6] = " ";
            msg_list[7] = PRESS_KEY;
            msg_list[8] = "";
            USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
            continue;
        }
		else if(term == NO_DATA)
            Display_serial_option(port_index, fnum++, prompt_cpos, fmap);
        else if(term == BAD_DATA) {
            Bad_data_message();
            Display_serial_option(port_index, fnum, prompt_cpos, fmap);
        }
        else if(term == FKEY) {
            if(buffer[0] == F1) {
                switch(fnum) {
                    case 0:
                        display_help("SERIAL-PORT-#", 12);
                        break;
                    case 1:
                        display_help("SERIAL-PORT-ADDRESS", 12);
                        break;
                    case 2:
                        display_help("SERIAL-PORT-IB", 12);
                        break;
                    case 3:
                        display_help("SERIAL-PORT-OB", 12);
                        break;
                    case 4:
                        display_help("SERIAL-PORT-HS", 12);
                        break;
                    case 5:
                        display_help("SERIAL-PORT-IN", 12);
                        break;
                    case 6:
                        display_help("SERIAL-PORT-CN", 12);
                }
            }
            else if(buffer[0] == F2) {
                switch(fnum) {
                case 4:
                    header = " Handshaking Mode ";
                    opt_list[0] = "N - None";
                    opt_list[1] = "D - DTR (Data Terminal Ready)";
                    opt_list[2] = "X - XON/XOFF";
                    opt_list[3] = "P - XPC (Receiver Controlled)";
                    opt_list[4] = "R - DTR, XPC and RTS";
                    opt_list[5] = "";
                    def_opt = 0;
                    for(i=0; i<5; ++i) {
                        if(serial_list[port_index].sp_HS == opt_list[i][0]) {
                            def_opt = i;
                            break;
                        }
                    }
                    opt = select_option(-1, 5, opt_list, def_opt, header, "", RESTORE_VIDEO);
                    if(opt != -1) {
                        if(opt_list[opt][0] != serial_list[port_index].sp_HS)
                            CONFIG_changed = 1;
                        serial_list[port_index].sp_HS = opt_list[opt][0];
                    }
                    break;
                case 5:
                    header = " Interrupt Level ";
                    opt_list[0] = "IRQ2";
                    opt_list[1] = "IRQ3";
                    opt_list[2] = "IRQ4";
                    opt_list[3] = "IRQ5";
                    opt_list[4] = "IRQ6 (Caution!)";
                    opt_list[5] = "IRQ7";
                    opt_list[6] = "";
                    def_opt = serial_list[port_index].sp_IN - 2;
                    if(def_opt < 0)
                        def_opt = 0;
                    opt = select_option(-1, 6, opt_list, def_opt, header, "", RESTORE_VIDEO);
                    if(opt != -1) {
                        i2temp = opt + 2;
                        if(i2temp != serial_list[port_index].sp_IN) {
                            serial_list[port_index].sp_IN = i2temp;
                            CONFIG_changed = 1;
                        }
                    }
                    break;
                case 6:
                    header = " Terminal Mode ";
                    opt_list[0] = "N - None";
                    opt_list[1] = "L - Local";
                    opt_list[2] = "R - Remote";
                    opt_list[3] = "T - Remote w/task restart";
                    opt_list[4] = "";
                    def_opt = 0;
                    for(i=0; i<4; ++i) {
                        if(serial_list[port_index].sp_CN == opt_list[i][0]) {
                            def_opt = i;
                            break;
                        }
                    }
                    opt = select_option(-1, 4, opt_list, def_opt, header, "", RESTORE_VIDEO);
                    if(opt != -1) {
                        if(opt_list[opt][0] != serial_list[port_index].sp_CN)
                            CONFIG_changed = 1;
                        serial_list[port_index].sp_CN = opt_list[opt][0];
                    }
                    break;
                default:
                    No_option_available();
                }
                Display_serial_option(port_index, fnum, prompt_cpos, fmap);
            }
            else if(buffer[0] == UP)
                Display_serial_option(port_index, fnum--, prompt_cpos, fmap);
            else if(buffer[0] == DOWN)
                Display_serial_option(port_index, fnum++, prompt_cpos, fmap);
            else if(buffer[0] == PGUP) {
                if(++port_index > 23)
                    port_index = 0;
                for(i=0; i<=MAX_FIELD; ++i)
                    Display_serial_option(port_index, i, prompt_cpos, fmap);
            }
            else if(buffer[0] == PGDN) {
                if(--port_index < 0)
                    port_index = 23;
                for(i=0; i<=MAX_FIELD; ++i)
                    Display_serial_option(port_index, i, prompt_cpos, fmap);
            }
        }
        else if(term == ENTER) {
/*
    Data entered with the ENTER key pressed.  Process it.
*/
            if(fnum != 0)          /* First field only selects port */
                CONFIG_changed = 1;

            switch(fnum) {
                case 0:
                    if(*i2val < 1 || *i2val > 24) {
                        Bad_option_message();
                        Display_serial_option(port_index, fnum, prompt_cpos, fmap);
                    }
                    else {
                        port_index = *i2val - 1;
                        for(i=0; i<=MAX_FIELD; ++i)
                            Display_serial_option(port_index, i, prompt_cpos, fmap);
                        fnum++;
                    }
                    break;
                case 1:
                    if(serial_list[port_index].sp_address != 0)
                        Unlock_port_range(serial_list[port_index].sp_address, 8);

                    if(*u2val > 0x8000) {
                        Bad_data_message();
                        Display_serial_option(port_index, fnum, prompt_cpos, fmap);
                    }
/*
    Note that the port range is check for 0-0x3FFh.  PC's only use
    the first 10 address lines, so even though the serial port address
    for this driver can sit up to address 0x8000, that address will only
    be effective for the lower 10 bits.  Some serial port boards use this
    method to 'stack' serial ports one on top of the other.
*/
                    else if(!Check_port_range((*u2val & 0x3FF), 8)) {
                        Bad_IO_address_message();
                        Display_serial_option(port_index, fnum, prompt_cpos, fmap);
                    }
                    else {
                        serial_list[port_index].sp_address = *i2val;
                        if(serial_list[port_index].sp_address != 0)
                            Lock_port_range(serial_list[port_index].sp_address, 8);
                        Display_serial_option(port_index, fnum++, prompt_cpos, fmap);
                    }
                    break;
                case 2:
                    if(*u2val < 32) {
                        Bad_data_message();
                        Display_serial_option(port_index, fnum, prompt_cpos, fmap);
                    }
                    else {
                        serial_list[port_index].sp_IB = *u2val;
                        Display_serial_option(port_index, fnum++, prompt_cpos, fmap);
                    }
                    break;
                case 3:
                    if(*u2val < 16) {
                        Bad_data_message();
                        Display_serial_option(port_index, fnum, prompt_cpos, fmap);
                    }
                    else {
                        serial_list[port_index].sp_OB = *u2val;
                        Display_serial_option(port_index, fnum++, prompt_cpos, fmap);
                    }
                    break;
                case 4:
                    buffer[0] = toupper(buffer[0]);
                    if(!strchr("NDXPR", buffer[0])) {
                        Bad_option_message();
                        Display_serial_option(port_index, fnum, prompt_cpos, fmap);
                    }
                    else {
                        serial_list[port_index].sp_HS = buffer[0];
                        Display_serial_option(port_index, fnum++, prompt_cpos, fmap);
                    }
                    break;
                case 5:
                    if(*i2val < 2 || *i2val > 7) {
                        Bad_option_message();
                        Display_serial_option(port_index, fnum, prompt_cpos, fmap);
                    }
                    else {
                        serial_list[port_index].sp_IN = *i2val;

                        if(*i2val == 6) {
                            msg_list[0] = "The chosen interrupt may cause";
                            msg_list[1] = "conflicts with your floppy drive";
                            msg_list[2] = "controller.  Reset this value";
                            msg_list[3] = "if you're not absolutely sure";
                            msg_list[4] = "that it is correct!";
                            msg_list[5] = " ";
                            msg_list[6] = PRESS_KEY;
                            msg_list[7] = "";
                            USR_message(-1, msg_list, WARNING, 0, PAUSE_FOR_KEY);
                            Display_serial_option(port_index, fnum, prompt_cpos, fmap);
                        }
                        else
                            Display_serial_option(port_index, fnum++, prompt_cpos, fmap);
                    }
                    break;
                case 6:
                    buffer[0] = toupper(buffer[0]);
                    if(!strchr("NLRT", buffer[0])) {
                        Bad_option_message();
                        Display_serial_option(port_index, fnum, prompt_cpos, fmap);
                    }
                    else {
                        serial_list[port_index].sp_CN = buffer[0];
                        Display_serial_option(port_index, fnum++, prompt_cpos, fmap);
                    }
                    break;
            } /* End switch */
        }
/*
    Go to next field.
*/
        if(fnum > MAX_FIELD)
            fnum = 0;
        else if(fnum < 0)
            fnum = MAX_FIELD;

    } FOREVER;

    restore_video_region(101, 2580, video);
}
/*
---------------  Function Display_serial_option ---------------------------
*/
Display_serial_option(int index, int fnum, int prompt_cpos[], int fmap[][2])
{
    switch(fnum) {
        case 0:
            index++;
            put_field(1, fmap[fnum][0], prompt_cpos[fnum], fmap[fnum][1], _$fcolor, &index);
            break;
        case 1:
            put_field(1, fmap[fnum][0], prompt_cpos[fnum], fmap[fnum][1], _$fcolor, &serial_list[index].sp_address);
            break;
        case 2:
            put_field(1, fmap[fnum][0], prompt_cpos[fnum], fmap[fnum][1], _$fcolor, &serial_list[index].sp_IB);
            break;
        case 3:
            put_field(1, fmap[fnum][0], prompt_cpos[fnum], fmap[fnum][1], _$fcolor, &serial_list[index].sp_OB);
			break;
        case 4:
            put_field(1, fmap[fnum][0], prompt_cpos[fnum], fmap[fnum][1], _$fcolor, &serial_list[index].sp_HS);
			break;
        case 5:
            put_field(1, fmap[fnum][0], prompt_cpos[fnum], fmap[fnum][1], _$fcolor, &serial_list[index].sp_IN);
			break;
        case 6:
            put_field(1, fmap[fnum][0], prompt_cpos[fnum], fmap[fnum][1], _$fcolor, &serial_list[index].sp_CN);
	}
}
