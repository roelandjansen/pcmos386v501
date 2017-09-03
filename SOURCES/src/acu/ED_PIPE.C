/*
*****************************************************************************
*
*   MODULE NAME:    Edit_pipe_parms
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  08-June-90
*
*   REVISION DATE:  08-June-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Edit $PIPE.SYS parameters
*
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Edit_pipe_parms();
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
*****************************************************************************
*
*/
#define MAX_FIELD   3
#define PRESS_KEY   ">> Press ANY key to continue <<"
#define FOREVER     while(1)
#define HEADER      " PIPE Driver "
#define TRAILER     " F1=HELP  F2=OPTIONS  ESC=EXIT "

#include <stdlib.h>
#include <ctype.h>
#include <rsa\rsa.h>
#include <rsa\stdusr.h>
#include <rsa\keycodes.h>

extern unsigned char    pipe_EOF_mode[],
                        pipe_installed[];

extern char     *pipe_names[],
                *prompt_lines[];

extern unsigned     pipe_buf_size[];

extern int  _$fcolor,
            _$bar_color,
            fmap[][2],
            pipe_count,
            pipe_index,
            prompt_cpos[];

Edit_pipe_parms()
{
    extern unsigned char    CONFIG_changed;

    unsigned char   found;

    char        *header,
                buffer[80],
                *opt_list[11],
                *msg_list[11];

    unsigned    *u2val;

    int         i,
                opt,
                fnum,
                term,
                *video,
                def_opt;
/*
    Initialize.
*/
    u2val = (unsigned *) buffer;

    prompt_lines[0] = "Install Driver? (Y/N): _";
    prompt_lines[1] = "Pipe name: ________";
    prompt_lines[2] = "Buffer size (bytes): _____";
    prompt_lines[3] = "EOF on empty pipe? (Y/N): _";
    prompt_lines[4] = "";

    fmap[0][0] = CH_FIELD;
    fmap[0][1] = 1;
    fmap[1][0] = CH_FIELD;
    fmap[1][1] = 8;
    fmap[2][0] = U2_FIELD;
    fmap[2][1] = 5;
    fmap[3][0] = CH_FIELD;
    fmap[3][1] = 1;
/*
    Draw the dialog box.
*/
    video = save_video_region(101, 2580);
    Draw_edit_box(HEADER, TRAILER, prompt_lines, prompt_cpos);
/*
    Fill-in the fields before editing them.
*/
    for(i=0; i<=MAX_FIELD; ++i)
        Display_pipe_option(i);
/*
    Read each of the fields.
*/
    fnum = 0;
    do {
        term = Read_field(4, prompt_cpos[fnum], fmap[fnum][0], fmap[fnum][1],
                         _$bar_color, buffer);
        if(term == ESC)
            break;
        else if(term == BAD_DATA) {
            Bad_data_message();
            Display_pipe_option(fnum);
        }
        else if(term == NO_DATA) {
            if(pipe_installed[pipe_index])
                Display_pipe_option(fnum++);
            else
                Deny_pipe_options();
        }
        else if(term == FKEY) {
            if(buffer[0] == DOWN)
                if(pipe_installed[pipe_index])
                    Display_pipe_option(fnum++);
                else
                    Deny_pipe_options();
            else if(buffer[0] == UP) {
                if(pipe_installed[pipe_index])
                    Display_pipe_option(fnum--);
                else
                    Deny_pipe_options();
            }
            else if(buffer[0] == F1) {
                switch(fnum) {
                    case 0:
                        display_help("PIPE-INSTALLED", 12);
                        break;
                    case 1:
                        display_help("PIPE-NAME", 12);
                        break;
                    case 2:
                        display_help("PIPE-SIZE", 12);
                        break;
                    case 3:
                        display_help("PIPE-EOF", 12);
                }
            }
            else if(buffer[0] == F2) {
                switch(fnum) {
                    case 0:
                        header = " Install PIPE? ";
                        msg_list[0] = "NO";
                        msg_list[1] = "YES";
                        msg_list[2] = "";
                        def_opt = pipe_installed[pipe_index];
                        opt = select_option(-1, 2, msg_list, def_opt, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            if(pipe_installed[pipe_index] != opt)
                                CONFIG_changed = 1;
                            pipe_installed[pipe_index] = opt;
                        }
                        for(i=0; i<=MAX_FIELD; ++i)
                            Display_pipe_option(i);
                        break;
                    case 3:
                        header = " EOF on Empty pipe? ";
                        msg_list[0] = "NO";
                        msg_list[1] = "YES";
                        msg_list[2] = "";
                        def_opt = pipe_EOF_mode[pipe_index];
                        opt = select_option(-1, 2, msg_list, def_opt, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            if(pipe_EOF_mode[pipe_index] != opt)
                                CONFIG_changed = 1;
                            pipe_EOF_mode[pipe_index] = opt;
                        }
                        break;
                    default:
                        No_option_available();
                }
                Display_pipe_option(fnum);
            }
        }
/*
    Process entered data.
*/
        else if(term == ENTER) {
            switch(fnum) {
                case 0:     /* Install driver? (Y/N) */
                    buffer[0] = toupper(buffer[0]);
                    if(buffer[0] == 'Y') {
                        if(!pipe_installed[pipe_index])
                            CONFIG_changed = 1;
                        pipe_installed[pipe_index] = 1;
                        fnum++;
                    }
                    else {
                        if(pipe_installed[pipe_index])
                            CONFIG_changed = 1;
                        pipe_installed[pipe_index] = 0;
                    }

                    for(i=0; i<=MAX_FIELD; ++i)
                        Display_pipe_option(i);
                    break;

                case 1:     /* Get pipe name */
                    if(!isalpha(buffer[0])) {
                        Bad_data_message();
                        Display_pipe_option(fnum);
                    }
                    else {
                        strupr(buffer);
                        found = 0;
                        for(i=0; i<25; ++i) {   /* Check for duplicate name */
                            if((strcmp(buffer, pipe_names[i]) == 0) && i != pipe_index)
                                found = 1;
                        }
                        if(found) {
                            msg_list[0] = "Duplicate pipe name found! Enter";
                            msg_list[1] = "a name that is unused.";
                            msg_list[2] = " ";
                            msg_list[3] = PRESS_KEY;
                            msg_list[4] = "";
                            USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
                            Display_pipe_option(fnum);
                        }
                        else {
                            if(strcmp(buffer, pipe_names[pipe_index]) != 0)
                                CONFIG_changed = 1;
                            strcpy(pipe_names[pipe_index], buffer);
                            Display_pipe_option(fnum++);
                        }
                    }
                    break;
                case 2:     /* Get pipe buffer size */
                    if(*u2val > 16384) {
                        Bad_data_message();
                        Display_pipe_option(fnum);
                    }
                    else {
                        if(*u2val != pipe_buf_size[pipe_index])
                            CONFIG_changed = 1;
                        pipe_buf_size[pipe_index] = *u2val;
                        Display_pipe_option(fnum++);
                    }
                    break;
                case 3:     /* Pipe EOF mode */
                    buffer[0] = toupper(buffer[0]);
                    if(buffer[0] == 'Y') {
                        if(!pipe_EOF_mode[pipe_index])
                            CONFIG_changed = 1;
                        pipe_EOF_mode[pipe_index] = 1;
                        Display_pipe_option(fnum++);
                    }
                    else {
                        if(pipe_EOF_mode[pipe_index])
                            CONFIG_changed = 1;
                        pipe_EOF_mode[pipe_index] = 0;
                        Display_pipe_option(fnum++);
                    }
                    break;
            }
        }
/*
    Go to the next field.
*/
        if(fnum > MAX_FIELD)
            fnum = 0;
        else if(fnum < 0)
            fnum = MAX_FIELD;

    } FOREVER;

    restore_video_region(101, 2580, video);
}

Display_pipe_option(int fnum)
{
    int     color;

    if(pipe_installed[pipe_index])
        color = _$fcolor;
    else
        color = (_$fcolor & 0xF0) | 0x0C;

    switch(fnum) {
        case 0:
            put_field(1, fmap[0][0], prompt_cpos[0], fmap[0][1], _$fcolor,
                    &"NY"[pipe_installed[pipe_index]]);
            break;
        case 1:
            put_field(1, fmap[1][0], prompt_cpos[1], fmap[1][1], color,
                    pipe_names[pipe_index]);
            break;
        case 2:
            put_field(1, fmap[2][0], prompt_cpos[2], fmap[2][1], color,
                    &pipe_buf_size[pipe_index]);
            break;
        case 3:
            put_field(1, fmap[3][0], prompt_cpos[3], fmap[3][1], color,
                    &"NY"[pipe_EOF_mode[pipe_index]]);
    }
}

Deny_pipe_options()
{
    char    *msg_list[7];

    msg_list[0] = "You must indicate that the pipe driver";
    msg_list[1] = "is to be installed before you will be";
    msg_list[2] = "permitted to modify any of the other";
    msg_list[3] = "pipe driver parameters.";
    msg_list[4] = " ";
    msg_list[5] = PRESS_KEY;
    msg_list[6] = "";
    USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
}
