/*
*****************************************************************************
*
*   MODULE NAME:    Edit_???????
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:
*
*   REVISION DATE:
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    This routine is the template from which all standard
*                   dialog boxes are build for ACU.EXE.
*
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*	USAGE:			
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
#define MAX_FIELD   2
#define HEADER      " ????????? "
#define TRAILER     " F1=HELP  F2=OPTIONS  ESC=EXIT "
#define FOREVER     while (1)
#define PRESS_KEY   ">> Press ANY key to continue <<"

#include <stdlib.h>
#include <ctype.h>
#include <rsa\rsa.h>
#include <rsa\keycodes.h>
#include <rsa\stdusr.h>
/*
    Externals.
*/
extern char             *prompt_lines[];

extern int      _$fcolor,
                fmap[][2],
                _$bar_color,
                prompt_cpos[];

Edit_???_options()
{
    extern unsigned char    CONFIG_changed;

    char    *header,
            buffer[20],
            *opt_list[23],
            *msg_list[23];

    int     i,
            opt,
            term,
            fnum,
            *video,
            *i2val,
            def_opt;

    long    *i4val;
/*
    Initialization.
*/
    i2val = (int *) buffer;
    i4val = (long *) buffer;

    video = save_video_region(101, 2580);

    fmap[0][0] = CH_FIELD;
    fmap[0][1] = 1;
/* Etc..... */

    prompt_lines[0] = "Install Driver? (Y/N): _";
    prompt_lines[1] = "Memory size (KB): ____";
    prompt_lines[2] = "Buffer address (Hex): _____";
    prompt_lines[3] = "";

    Draw_edit_box(HEADER, TRAILER, prompt_lines, prompt_cpos);
/*
    Display the current status of EMS in the box.
*/
    for(i=0; i<=MAX_FIELD; ++i)
        Display_???_option(i);
/*
    Read the fields.
*/
    fnum = 0;
    do {
        term = Read_field(4, prompt_cpos[fnum], fmap[fnum][0], fmap[fnum][1],
                _$bar_color, buffer);

        if(term == ESC)
            break;
        else if(term == FKEY) {
            if(buffer[0] == F1) {
                cursor_off();
                switch(fnum) {
                    case 0:
                    case 1:
                    case 2:
                        break;
                }
                cursor_on();
            }
            else if(buffer[0] == F2) {
                switch (fnum) {
                    case 0:
                    case 1:
                    case 2:
                        break;
                }
            }
            else if(buffer[0] == DOWN) {
                Display_???_option(fnum++);
            }
            else if(buffer[0] == UP) {
                Display_???_option(fnum--);
            }
        }
        else if(term == NO_DATA) {
            Display_???_option(fnum++);
        }
        else if(term == ENTER) {
            switch(fnum) {
                case 0:
                case 1:
                case 2:
                    break;
            }
        }

        if(fnum > MAX_FIELD)
            fnum = 0;
        else if(fnum < 0)
            fnum = MAX_FIELD;

    } FOREVER;

    if(EMS_buffer_size == 0)
        EMS_installed = 0;

    restore_video_region(101, 2580, video);
}
/*
=============================================================================
Function  Display_???_option
=============================================================================
*/
Display_???_option(int fnum)
{
    int     color;

    if(EMS_installed)
        color = _$fcolor;
    else
        color = (_$fcolor & 0xF0) | 0x0C;

    switch(fnum) {
        case 0:
            put_field(1, fmap[fnum][0], prompt_cpos[fnum], fmap[fnum][1], color, &"NY"[EMS_installed]);
            break;
        case 1:
            put_field(1, fmap[fnum][0], prompt_cpos[fnum], fmap[fnum][1], color, &EMS_buffer_size);
            break;
        case 2:
            put_field(1, fmap[fnum][0], prompt_cpos[fnum], fmap[fnum][1], color, &EMS_page_frame);
            break;
    }
}
