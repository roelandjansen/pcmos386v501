/*
*****************************************************************************
*
*   MODULE NAME:    Edit_EMS_driver
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  24-May-90
*
*   REVISION DATE:  24-May-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Editing of $EMS.SYS parameters.
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
* 9/26/91   RSR         Modification for EMS 4.0 driver
*****************************************************************************
*
*/
#define HEADER      " EMS Driver "
#define TRAILER     " F1=HELP  F2=OPTIONS  ESC=EXIT "
#define FOREVER     while (1)
#define PRESS_KEY   ">> Press ANY key to continue <<"

#include <malloc.h>
#include <stdlib.h>
#include <ctype.h>
#include <rsa\rsa.h>
#include <rsa\keycodes.h>
#include <rsa\stdusr.h>
/*
    Externals.
*/
extern unsigned char    EMS_installed;

extern char             *prompt_lines[];

extern int      _$fcolor,
                fmap[][2],
                _$bar_color,
                ext_mem_free,
                ext_mem_used,
                prompt_cpos[],
               EMS_buffer_size;

extern long             EMS_page_frame;

Edit_EMS_parms()
{
    extern unsigned char    CONFIG_changed;

    void    *junk;

    unsigned char       found;

    char    *header,
            buffer[20],
            *opt_list[11],
            *msg_list[11],
            *opt_text[51];      /* For building option list with sprintf */

    int     i,
            max,
            opt,
            term,
            fnum,
            *video,
            i2temp,
            *i2val,
            def_opt;

    long    *i4val,
            temp_long;
/*
    Initialization.
*/
    i2val = (int *) buffer;
    i4val = (long *) buffer;

    if(EMS_installed)
        Unlock_himem_range(EMS_page_frame, 64);     /* Free the memory section */
/*
    Any EMS page frames available?
*/
    found = 0;
    for(temp_long = 0xC0000; temp_long <= 0xE0000; temp_long += 0x4000) {
        if(Check_himem_range(temp_long, 64) != 0) {
            found = 1;
            break;
        }
    }
    if(!found) {
        msg_list[0] = "You have included the default";
        msg_list[1] = "location of the EMS driver ";
        msg_list[2] = "(E0000 to F0000) in your FREEMEM";
        msg_list[3] = "area.";
        msg_list[4] = " ";
        msg_list[5] = "You must first remove those ";
        msg_list[6] = "addresses from the FREEMEM area";
        msg_list[7] = "in order to load the EMS driver.";
        msg_list[8] = " ";
        msg_list[9] = PRESS_KEY;
        msg_list[10] = "";
        USR_message(-1, msg_list, WARNING, 0, PAUSE_FOR_KEY);
        return;
    }

/*    if(EMS_buffer_size == 0 && ext_mem_free == 0) {
        msg_list[0] = "Cannot install EMS driver.";
        msg_list[1] = "No free Extended Memory.";
        msg_list[2] = " ";
        msg_list[3] = PRESS_KEY;
        msg_list[4] = "";
        USR_message(0, msg_list, WARNING, 0, PAUSE_FOR_KEY);
        return;
    }

    ext_mem_used -= EMS_buffer_size;
    ext_mem_free += EMS_buffer_size;
*/
/*
    Allocate space to build a list of available page frames.
*/
        msg_list[0] = "       ****IMPORTANT****";
        msg_list[1] = "You must manualy enter the ";
        msg_list[2] = "MOSADM EMSLIMIT sizeK command";
        msg_list[3] = "in each task that needs EMS.";
        msg_list[4] = " ";
        msg_list[5] = PRESS_KEY;
        msg_list[6] = "";
        USR_message(0, msg_list, WARNING, 0, PAUSE_FOR_KEY);

    for(i=0; i<51; ++i)
        opt_text[i] = malloc(64);

    video = save_video_region(101, 2580);

    fmap[0][0] = CH_FIELD;
    fmap[0][1] = 1;
    fmap[1][0] = HL_FIELD;
    fmap[1][1] = 5;

    prompt_lines[0] = "Install Driver? (Y/N): _";
  /*  prompt_lines[1] = "Memory size (KB): ____"; */
    prompt_lines[1] = "Buffer address (Hex): _____";
    prompt_lines[2] = "";

    Draw_edit_box(HEADER, TRAILER, prompt_lines, prompt_cpos);
/*
    Display the current status of EMS in the box.
*/
    for(i=0; i<2; ++i)
    Display_EMS_option(i);
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
                switch(fnum) {
                    case 0:
                        display_help("EMS-ON", 12);
                        break;
                    case 1:
                        display_help("EMS-PAGE-FRAME", 12);
                        break;

                }
            }
            else if(buffer[0] == F2) {
                switch (fnum) {
                    case 0:
                        header = " Install EMS Driver? ";
                        opt_list[0] = "NO";
                        opt_list[1] = "YES";
                        opt_list[2] = "";
                        opt = select_option(-1, 2, opt_list, EMS_installed, header, "", RESTORE_VIDEO);
                        if(opt == -1)
                            break;
                        EMS_installed = opt;
                        CONFIG_changed = 1;
/*
    Find first free EMS page frame.
*/
                        if(Check_himem_range(0xE0000, 64) != 0)
                            EMS_page_frame = 0xE0000;
                        else {
                            for(temp_long = 0xC0000; temp_long <= 0xE0000; temp_long += 0x4000) {
                                if(Check_himem_range(temp_long, 64) != 0) {
                                    EMS_page_frame = temp_long;
                                    break;
                                }
                            }
                        }

                        for(i=0; i<2; ++i)
                            Display_EMS_option(i);
                        break;
                    case 1:
                        header = " Available EMS page frames ";
                        temp_long = 0xC0000;
                        for(i=0; temp_long <= 0xE0000; temp_long += 0x4000) {
                            if(Check_himem_range(temp_long, 64) != 0)
                                sprintf(opt_text[i++], "%05lX h", temp_long);
                        }
                        opt_text[i][0] = '\0';
                        max = i;

                        def_opt = 0;
                        for(i=0; i<max; ++i) {
                            if(EMS_page_frame == strtol(opt_text[i], &junk, 16)) {
                                def_opt = i;
                                break;
                            }
                        }
                        opt = select_option(-1, max, opt_text, def_opt, header, "", RESTORE_VIDEO);
                        if(opt == -1)
                            break;
                        EMS_page_frame = strtol(opt_text[opt], &junk, 16);
                        CONFIG_changed = 1;
                        Display_EMS_option(fnum);
                }
            }
            else if(buffer[0] == DOWN) {
                if(EMS_installed)
                    Display_EMS_option(fnum++);
                else
                    Deny_EMS_options();
            }
            else if(buffer[0] == UP) {
                if(EMS_installed)
                    Display_EMS_option(fnum--);
                else
                    Deny_EMS_options();
            }
        }
        else if(term == NO_DATA) {
            if(EMS_installed)
                Display_EMS_option(fnum++);
            else
                Display_EMS_option(fnum);   /* Don't move on */
        }
        else if(term == ENTER) {
            switch(fnum) {
                case 0:
                    buffer[0] = toupper(buffer[0]);
                    if(buffer[0] == 'Y') {
/*
    Find first free EMS page frame.
*/
                        if(Check_himem_range(0xE0000, 64) != 0)
                            EMS_page_frame = 0xE0000;
                        else {
                            for(temp_long = 0xC0000; temp_long <= 0xE0000; temp_long += 0x4000) {
                                if(Check_himem_range(temp_long, 64) != 0) {
                                    EMS_page_frame = temp_long;
                                    break;
                                }
                            }
                        }
                        if(!EMS_installed)
                            CONFIG_changed = 1;
                        EMS_installed = 1;
                    }
                    else {
                        if(EMS_installed)
                            CONFIG_changed = 1;
                        EMS_installed = 0;
                    }
                    for(i=0; i<2; ++i)
                        Display_EMS_option(i);
                    if(EMS_installed)
                        fnum++;
                    break;
                case 1:
                /*
                    if(*i2val > ext_mem_free) {
                        Not_enough_memory_message();
                        Display_EMS_option(fnum);
                        break;
                    }
                    *i2val &= 0xFFF0;
                    if(EMS_buffer_size != *i2val) {
                        CONFIG_changed = 1;
                        EMS_buffer_size = *i2val;
                    }
                    Display_EMS_option(fnum++);
                    break;
                  */
                case 2:
                    if(Check_himem_range(*i4val, 64) == 0) {
                        Bad_memory_address_message();
                        Display_EMS_option(fnum);
                        break;
                    }
/*
    The page frame is OK.
*/
                    if(EMS_page_frame != *i4val)
                        CONFIG_changed = 1;
                    EMS_page_frame = *i4val;
                    Display_EMS_option(fnum++);
                    break;
            }
        }

        if(fnum > 1)
            fnum = 0;
        else if(fnum < 0)
            fnum = 1;

    } FOREVER;

/*    if(EMS_buffer_size == 0)
        EMS_installed = 0;
*/
    for(i=0; i<51; ++i)
        free(opt_text[i]);

    if(EMS_installed) {
        Lock_himem_range(EMS_page_frame, 64);
/*        ext_mem_free -= EMS_buffer_size;
        ext_mem_used += EMS_buffer_size;
*/
    }
    else {
        EMS_page_frame = 0;
/*        EMS_buffer_size = 0; */
    }

    restore_video_region(101, 2580, video);
}
/*
=============================================================================
Function  Display_EMS_option

  This function paints the fields in the EMS data box.

=============================================================================
*/
Display_EMS_option(int fnum)
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
            put_field(1, fmap[fnum][0], prompt_cpos[fnum], fmap[fnum][1], color, &EMS_page_frame);
            break;

    }
}

Deny_EMS_options()
{
    char    *msg_list[7];

    msg_list[0] = "You must indicate that the EMS driver";
    msg_list[1] = "is to be installed before you will be";
    msg_list[2] = "permitted to modify any of the other";
    msg_list[3] = "EMS driver parameters.";
    msg_list[4] = " ";
    msg_list[5] = PRESS_KEY;
    msg_list[6] = "";
    USR_message(510, msg_list, ERROR, 0, PAUSE_FOR_KEY);
}
