/*
*****************************************************************************
*
*   MODULE NAME:    Edit_freemem
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  17-May-90
*
*   REVISION DATE:  17-May-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Allows the user to edit the FREEMEM statements.
*
*               (C) Copyright 1990, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:          
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
#define PRESS_KEY   ">> Press ANY key to continue <<"
#define BOX_CPOS    1140
#define FIRST_FIELD 1342
#define BOX_SIZE    823
#define FOREVER     while (1)

#include <rsa\rsa.h>
#include <rsa\keycodes.h>
#include <rsa\stdusr.h>

Edit_freemem()
{
    extern unsigned long    FREEMEM_list[][2];

    extern unsigned char    auto_freemem,
                            EMS_installed,
                            CONFIG_changed,
                            ramdisk_installed;

    extern int      _$bcolor,
                    _$fcolor,
                    _$hcolor,
                    _$tcolor,
                    _$bar_color,
                    EMS_buffer_size,
                    ramdisk_buffer_size;

    char    key1,
            key2,
            *header,
            *trailer,
            buffer[81],
            *msg_list[10],
            *opt_list[10],
            display_buf[81];


    int     i,
            opt,
            cpos,
            term,
            *video,
            fm_row,
            fm_col,
            option,
            field_num,
            error_flag,
            header_color,
            freemem_changed = 0;

    long    len,
            *i4val,
            f_list[5][2];


    i4val = (unsigned long *) buffer;
    option = auto_freemem;
    video = save_video_region(101, 2580);

    header = " FREEMEM Mode ";
    opt_list[0] = "NONE";
    opt_list[1] = "AUTOMATIC";
    opt_list[2] = "MANUAL";
    opt_list[3] = "";

    option = select_option(-1, 3, opt_list, option, header, "", 0);
/*
    If the user selects AUTO or presses ESC, then MOS will figure
    out the FREEMEM.  He needs do no more.
*/
    switch(option) {
        case -1:
            restore_video_region(101, 2580, video);
            return;
        case 0:
            auto_freemem = 0;
            restore_video_region(101, 2580, video);
            return;
        case 1:
            msg_list[0] = "If FREEMEM is set to be";
            msg_list[1] = "automatically calculated";
            msg_list[2] = "by MOS, then the EMS driver";
            msg_list[3] = "and the RAMdisk driver will";
            msg_list[4] = "be disabled.";
            msg_list[5] = " ";
            msg_list[6] = "Press 'Y' if this is OK or";
            msg_list[7] = "any other key to cancel.";
            msg_list[8] = "";
            USR_message(0, msg_list, WARNING, 0, ERRMSG_KEEP);
            cursor_off();
            while(!inkey(&key1, &key2));
            USR_clear_message();
            cursor_on();
            if(key1 == 'Y' || key1 == 'y') {
                EMS_installed = 0;
                EMS_buffer_size = 0;
                ramdisk_installed = 0;
                ramdisk_buffer_size = 0;
                Calculate_memory_usage();
                Build_address_map();
                auto_freemem = 1;
            }
            restore_video_region(101, 2580, video);
            return;
    }
/*
    If the option was 2, then we fell through the switch to allow
    editing of the FREEMEM ranges.
*/
    header = " FREEMEM AREAS ";
    trailer = " F1=HELP ";

    draw_box(BOX_CPOS, 1, BOX_SIZE, _$bcolor, _$fcolor);
    scr(2, BOX_CPOS+4, strlen(header), _$hcolor);
    dputs(header);
    put_cpos(BOX_CPOS+101);
    dputs(" Start   End    Size");
    scr(2, BOX_CPOS+707, strlen(trailer), _$tcolor);
    dputs(trailer);
/*
    Copy the FREEMEM list values from the global map to a local workspace
    and display them.  Also, mark all the memory ranges presently owned
    by the FREEMEM_list as free so that during a subsequent range check,
    the FREEMEM list won't collide with itself!
*/
    cpos = FIRST_FIELD;
    for(i=0; i<5; ++i) {
        f_list[i][0] = FREEMEM_list[i][0];
        f_list[i][1] = FREEMEM_list[i][1];
        len = (f_list[i][1] - f_list[i][0]) / 1024;
        Unlock_himem_range(f_list[i][0], len);      /* Free in list */
        put_cpos(cpos);
        sprintf(display_buf, "%05lX  %05lX", f_list[i][0], f_list[i][1]);
        dputs(display_buf);
        scr(2, cpos+14, 5, _$fcolor);
        sprintf(display_buf, "%3d K", len);
        dputs(display_buf);
        cpos += 100;
    }
/*
    The box is drawn.  Read the next field.
*/
    cpos = FIRST_FIELD;
    field_num = 0;
    fm_row = fm_col = 0;

    do {
        put_cpos(cpos);
        term = Read_field(4, 0, 9, 5, _$bar_color, buffer);
/*
    If the user pressed ESC, check all the values to make sure
    they're legitimate.
*/
        if(term == ESC) {
            if(!freemem_changed)        /* If no changes, exit right away */
                break;

            header = " Save FREEMEM list? ";
            opt_list[0] = "NO";
            opt_list[1] = "YES";
            opt_list[2] = "";
            opt = select_option(-1, 2, opt_list, 1, header, "", RESTORE_VIDEO);
            if(opt == -1)
                continue;       /* Don't leave screen */
            if(opt == 0)
                break;          /* Leave without saving changes */
/*
    The user wants to save changes.  Do range checking.
*/
            error_flag = 0;

            for(i=0; i<5; ++i) {
                if(f_list[i][0] == 0 && f_list[i][1] == 0)
                    continue;

                len = (f_list[i][1] - f_list[i][0]) / 1024;

                if(f_list[i][0] < 0xA0000 || f_list[i][1] < 0xA0000)
                    error_flag = 1;
                else if(len < 0)
                    error_flag = 1;
                else {
                    if(!Check_himem_range(f_list[i][0], len))
                    error_flag = 2;
                }
            }

            if(error_flag == 0) {       /* Save changes. */
                CONFIG_changed = 1;
                for(i=0; i<5; ++i) {
                    FREEMEM_list[i][0] = f_list[i][0];
                    FREEMEM_list[i][1] = f_list[i][1];
                }
                break;
            }
            else if(error_flag == 1) {
                msg_list[0] = "One or more of the FREEMEM ranges";
                msg_list[1] = "specified is incorrect.  Please";
                msg_list[2] = "double-check all the values entered";
                msg_list[3] = "into the list. (Note that all ranges";
                msg_list[4] = "must be specified at or above the";
                msg_list[5] = "memory address of A0000 (hex).";
                msg_list[6] = " ";
                msg_list[7] = PRESS_KEY;
                msg_list[8] = "";
                USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
                continue;
            }
            else if(error_flag == 2) {
                msg_list[0] = "One or more of the FREEMEM ranges";
                msg_list[1] = "specified is in conflict with the";
                msg_list[2] = "memory address requirments of one";
                msg_list[3] = "or more of the other PC-MOS device";
                msg_list[4] = "drivers or options.  Please check";
                msg_list[5] = "your ranges carefully and try to";
                msg_list[6] = "save them again.";
                msg_list[7] = " ";
                msg_list[8] = PRESS_KEY;
                msg_list[9] = "";
                USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
                continue;
            }
        }
        else if(term == FKEY) {
/*
    Repaint current field before processing the function key.
*/
            scr(2, cpos, 5, _$fcolor);
            sprintf(display_buf, "%05lX", f_list[fm_row][fm_col]);
            dputs(display_buf);

            if(buffer[0] == F1)
                display_help("FREEMEM-EDIT", 12);

            else if(buffer[0] == RIGHT) {
                if(++field_num > 9)
                    field_num = 0;
            }
            else if(buffer[0] == LEFT) {
                if(--field_num < 0)
                    field_num = 9;
            }
            else if(buffer[0] == DOWN) {
                field_num += 2;
                if(field_num > 9)
                    field_num -= 2;
            }
            else if(buffer[0] == UP) {
                field_num -= 2;
                if(field_num < 0)
                    field_num += 2;
            }
            else
                continue;
        }
        else if(term == NO_DATA) {
/*
    Repaint the field just left in case he typed something that
    cleared it, then changed his mind.
*/
            scr(2, cpos, 5, _$fcolor);
            sprintf(display_buf, "%05lX", f_list[fm_row][fm_col]);
            dputs(display_buf);

            if(++field_num > 9)         /* Move to next field */
                field_num = 0;
        }
        else if(term == BAD_DATA) {
            Bad_data_message();
        }
        else {
            if(*i4val < 0xA0000 || *i4val > 0xF0000) {
                Bad_data_message();
            }
            else {
                freemem_changed = 1;
                f_list[fm_row][fm_col] = *i4val;
                scr(2, cpos, 5, _$fcolor);
                sprintf(display_buf, "%05lX", f_list[fm_row][fm_col]);
                dputs(display_buf);
                len = (f_list[fm_row][1] - f_list[fm_row][0]) / 1024;
                cpos = FIRST_FIELD + fm_row*100 + 14;

                if(len >= 0) {
                    sprintf(display_buf, "%3d K", len);
                    scr(2, cpos, 5, _$fcolor);
                }
                else {
                    sprintf(display_buf, "*****");
                    scr(2, cpos, 5, (_$fcolor & 0xF0) | 0x0C);
                }
                dputs(display_buf);

                if(++field_num > 9)         /* Move to next field */
                    field_num = 0;
            }
        }
/*
    Calculate the new cursor position and repaint the field we're
    about to read before reading there.
*/
        fm_row = field_num / 2;
        fm_col = field_num % 2;
        cpos = FIRST_FIELD + fm_row*100 + fm_col*7;
        scr(2, cpos, 5, _$fcolor);
        sprintf(display_buf, "%05lX", f_list[fm_row][fm_col]);
        dputs(display_buf);
    } FOREVER;
/*
    Reserve the space taken by the FREEMEM list so other apps won't
    try to use the space.
*/
    auto_freemem = 1;       /* Default AUTO */

    for(i=0; i<5; ++i) {
        if(FREEMEM_list[i][0] != 0) {
            auto_freemem = 2;       /* Set to MANUAL */
            len = (FREEMEM_list[i][1] - FREEMEM_list[i][0]) / 1024;
            Lock_himem_range(FREEMEM_list[i][0], len);
        }
    }
/*
    All done editing.  Return to option list.
*/
    restore_video_region(101, 2580, video);
    return(auto_freemem);
}
