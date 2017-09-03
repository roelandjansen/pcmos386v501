/*
*****************************************************************************
*
*   MODULE NAME:    Edit_RAMdisk_parms
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  11-June-90
*
*   REVISION DATE:  11-June-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Allows the user to install the MOS driver $RAMDISK.SYS
*
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*   USAGE:  Edit_RAMdisk_parms();
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
#define PRESS_KEY   ">> Press ANY key to continue <<"
#define HEADER  " RAMdisk Driver "
#define TRAILER " F1=HELP  F2=OPTIONS  ESC=EXIT "
#define FOREVER     while (1)
#define MAX_FIELD   2

#include <ctype.h>
#include <stdlib.h>
#include <malloc.h>
#include <rsa\rsa.h>
#include <rsa\keycodes.h>
#include <rsa\stdusr.h>
/*
    Externals.
*/
extern long             ramdisk_page_frame;

extern unsigned char    CONFIG_changed,
                        ramdisk_installed;

extern char             *prompt_lines[];

extern int      _$fcolor,
                fmap[][2],
                _$bar_color,
                ext_mem_free,
                ext_mem_used,
                prompt_cpos[],
                ramdisk_buffer_size;

Edit_RAMdisk_parms()
{
    long    *u4val,
            u4temp;

    int     i,
            opt,
            fnum,
            term,
            *i2val,
            i2temp,
            *video,
            def_opt;

    char    *junk,
            *header,
            buffer[20],
            *opt_list[20],
            *opt_text[51],
            *msg_list[20];
/*
    Initialization.
*/
    i2val = (int *) buffer;
    u4val = (long *) buffer;
/*
    If the ramdisk is installed, just unlock the memory range in case
    the user wants to change it.  If the driver is NOT installed, then
    attempt to find a suitable default for the page frame.
*/
    if(ramdisk_installed)
        Unlock_himem_range(ramdisk_page_frame, 4);
    else {
/*
    Driver not installed. Starting with the address 0xB4000,
    find a free page frame.
*/
        ramdisk_page_frame = 0;

        for(u4temp=0xB4000; u4temp<=0xDF000; u4temp+=0x1000) {
            if(Check_himem_range(u4temp, 4)) {
                ramdisk_page_frame = u4temp;
                break;
            }
        }
    }
/*
    If no page-frame was found, don't even let him try to install
    the driver.
*/
    if(ramdisk_page_frame == 0) {
        msg_list[0] = "You have included the default";
        msg_list[1] = "location of the RAMDISK driver";
        msg_list[2] = "(B4000 to B8000) in your FREEMEM";
        msg_list[3] = "area.";
        msg_list[4] = " ";
        msg_list[5] = "You must first remove those";
        msg_list[6] = "addresses from the FREEMEM area in";
        msg_list[7] = "order to load the RAMDISK driver.";
        msg_list[8] = " ";
        msg_list[9] = PRESS_KEY;
        msg_list[10] = "";
        USR_message(0, msg_list, WARNING, 0, PAUSE_FOR_KEY);
        return;
    }

    if(ramdisk_buffer_size == 0 && ext_mem_free == 0) {
        msg_list[0] = "Cannot install RAMDisk driver.";
        msg_list[1] = "No free Extended Memory.";
        msg_list[2] = " ";
        msg_list[3] = PRESS_KEY;
        msg_list[4] = "";
        USR_message(0, msg_list, WARNING, 0, PAUSE_FOR_KEY);
        return;
    }

    ext_mem_free += ramdisk_buffer_size;
    ext_mem_used -= ramdisk_buffer_size;

    for(i=0; i<51; ++i)
        opt_text[i] = malloc(21);

    prompt_lines[0] = "Install driver? (Y/N): _";
    prompt_lines[1] = "Memory size (KB): _____";
    prompt_lines[2] = "Buffer address (hex): _____";
    prompt_lines[3] = "";

    fmap[0][0] = CH_FIELD;
    fmap[0][1] = 1;
    fmap[1][0] = U2_FIELD;
    fmap[1][1] = 5;
    fmap[2][0] = HL_FIELD;
    fmap[2][1] = 5;

    video = save_video_region(101, 2580);
    Draw_edit_box(HEADER, TRAILER, prompt_lines, prompt_cpos);

    for(i=0; i<=MAX_FIELD; ++i)
        Display_RAMdisk_option(i);
/*
    Read the fields.
*/
    fnum = 0;
    do {
        term = Read_field(4, prompt_cpos[fnum], fmap[fnum][0], fmap[fnum][1], _$bar_color, buffer);

        if(term == ESC)
            break;
        else if(term == NO_DATA) {
            if(ramdisk_installed)
                Display_RAMdisk_option(fnum++);
            else
                Deny_RAMdisk_options();
        }
        else if(term == FKEY) {
            if(buffer[0] == UP) {
                if(ramdisk_installed)
                    Display_RAMdisk_option(fnum--);
                else
                    Deny_RAMdisk_options();
            }
            else if(buffer[0] == DOWN) {
                if(ramdisk_installed)
                    Display_RAMdisk_option(fnum++);
                else
                    Deny_RAMdisk_options();
            }
            else if(buffer[0] == F1) {
                switch (fnum) {
                    case 0:
                        display_help("RAMDRIVE-INSTALLED", 12);
                        break;
                    case 1:
                        display_help("RAMDRIVE-SIZE", 12);
                        break;
                    case 2:
                        display_help("RAMDRIVE-ADDRESS", 12);
                }
            }
            else if(buffer[0] == F2) {
                switch(fnum) {
                    case 0:
                        header = " Install driver? ";
                        opt_list[0] = "NO";
                        opt_list[1] = "YES";
                        opt_list[2] = "";
                        opt = select_option(-1, 2, opt_list,
                                ramdisk_installed, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            if(ramdisk_installed != opt)
                                CONFIG_changed = 1;
                            ramdisk_installed = opt;
                            for(i=0; i<=MAX_FIELD; ++i)
                                Display_RAMdisk_option(i);
                        }
                        break;
                    case 1:
                        header = " RAMdisk size ";
                        def_opt = 0;
                        for(i=0; i<50; ++i) {
                            i2temp = i * 128;
                            if(i2temp > ext_mem_free)
                                break;
                            sprintf(opt_text[i], "%5d KB", i2temp);
                            if(i2temp == ramdisk_buffer_size)
                                def_opt = i;
                        }
                        opt_text[i][0] = '\0';
                        opt = select_option(-1, 8, opt_text, def_opt, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            i2temp = opt * 128;
                            if(i2temp != ramdisk_buffer_size) {
                                CONFIG_changed = 1;
                                ramdisk_buffer_size = i2temp;
                            }
                        }
                        Display_RAMdisk_option(fnum);
                        break;
                    case 2:
                        header = " Buffer address ";
                        for(i=0, u4temp = 0xB4000; u4temp <= 0xDF000; ++i, u4temp+=0x1000) {
                            if(Check_himem_range(u4temp, 4))
                                sprintf(opt_text[i], "%05lX", u4temp);
                            else
                                sprintf(opt_text[i], "%05lX (in use)", u4temp);
                        }
                        opt_text[i][0] = '\0';

                        def_opt = 0;
                        for(i=0; strlen(opt_text[i]); ++i) {
                            if(ramdisk_page_frame == strtol(opt_text[i], &junk, 16))
                                def_opt = i;
                        }
                        opt = select_option(-1, 8, opt_text, def_opt, header, "", RESTORE_VIDEO);
                        if(opt != -1) {
                            u4temp = strtol(opt_text[opt], &junk, 16);
                            if(!Check_himem_range(u4temp, 4))
                                Bad_memory_address_message();
                            else {
                                if(u4temp != ramdisk_page_frame) {
                                    CONFIG_changed = 1;
                                    ramdisk_page_frame = u4temp;
                                }
                            }
                            Display_RAMdisk_option(fnum);
                        }
                        break;
                }
            }
        }
        else if(term == ENTER) {
            switch(fnum) {
                case 0:
                    buffer[0] = toupper(buffer[0]);
                    if(buffer[0] == 'Y') {
                        if(!ramdisk_installed)
                            CONFIG_changed = 1;
                        ramdisk_installed = 1;
                        fnum++;
                    }
                    else {
                        if(ramdisk_installed)
                            CONFIG_changed = 1;
                        ramdisk_installed = 0;
                    }
                    for(i=0; i<=MAX_FIELD; ++i)
                        Display_RAMdisk_option(i);
                    break;
                case 1:
                    if(*i2val > ext_mem_free) {
                        Not_enough_memory_message();
                        Display_RAMdisk_option(fnum);
                    }
                    else {
                        if(ramdisk_buffer_size != *i2val) {
                            CONFIG_changed = 1;
                            ramdisk_buffer_size = *i2val;
                        }
                        Display_RAMdisk_option(fnum++);
                    }
                    break;
                case 2:
                    *u4val &= 0xFF000;
                    if(!Check_himem_range(*u4val, 4))
                        Bad_memory_address_message();
                    else
                        ramdisk_page_frame = *u4val;

                    Display_RAMdisk_option(fnum++);
            }
        }


        if(fnum > MAX_FIELD)
            fnum = 0;
        else if(fnum < 0)
            fnum = MAX_FIELD;

    } FOREVER;

exit:
    if(ramdisk_buffer_size == 0)
        ramdisk_installed = 0;

    if(ramdisk_installed) {
        Lock_himem_range(ramdisk_page_frame, 4);
        ext_mem_free -= ramdisk_buffer_size;
        ext_mem_used += ramdisk_buffer_size;
    }
    else
        ramdisk_buffer_size = 0;

    for(i=0; i<51; ++i)
        free(opt_text[i]);

    restore_video_region(101, 2580, video);
}
/*
=============================================================================
    The following function displays RAMdisk data in the box.
=============================================================================
*/
Display_RAMdisk_option(int fnum)
{
    int     color;

    if(ramdisk_installed)
        color = _$fcolor;
    else
        color = (_$fcolor & 0xF0) | 0x0C;

    switch(fnum) {
        case 0:
            put_field(1, fmap[0][0], prompt_cpos[0], fmap[0][1], _$fcolor, &"NY"[ramdisk_installed]);
            break;
        case 1:
            put_field(1, fmap[1][0], prompt_cpos[1], fmap[1][1], color, &ramdisk_buffer_size);
            break;
        case 2:
            put_field(1, fmap[2][0], prompt_cpos[2], fmap[2][1], color, &ramdisk_page_frame);
    }
}

Deny_RAMdisk_options()
{
    char    *msg_list[7];

    msg_list[0] = "You  must  indicate that the RAMdisk";
    msg_list[1] = "is to be installed before you will be";
    msg_list[2] = "permitted to modify any of the other";
    msg_list[3] = "driver parameters.";
    msg_list[4] = " ";
    msg_list[5] = PRESS_KEY;
    msg_list[6] = "";
    USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
}
