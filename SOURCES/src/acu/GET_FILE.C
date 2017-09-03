/*
*****************************************************************************
*
*   MODULE NAME:    Get_filename
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  18-May-90
*
*   REVISION DATE:  18-May-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Presents a menu for the user to type in the
*                   name of the file.
*
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
#define FOREVER     while (1)
#define BOX_WIDTH   55
#define BOX_LENGTH  9
#define BOX_CPOS    1015

#include <stdio.h>
#include <stdlib.h>
#include <rsa\rsa.h>
#include <rsa\stdusr.h>
#include <rsa\keycodes.h>

Get_filename()
{
    extern char     target_drive,
                    source_file[],
                    backup_file[];

    extern int      _$bcolor,
                    _$fcolor,
                    _$hcolor,
                    _$tcolor,
                    _$bar_color,
                    _$menu_color,
                    _$ml_color;

    FILE    *fp;

    char    *header,
            *trailer,
            buffer[81],
            drive[3],
            dir[65],
            fname[9],
            ext[5],
            *msg_list[10];

    int     cpos,
            term,
            attrib,
            *video,
            box_cpos,
            box_size;
/*
    Place a prompt-box on the screen and allow the user to enter
    the pathname of the configuration file he wants edited.
*/
    header = " PC-MOS Configuration ";
    trailer = " Press ESC to EXIT ";

    box_size = BOX_LENGTH*100 + BOX_WIDTH;
    box_cpos = ((25 - BOX_LENGTH) / 2) * 100 + (80 - BOX_WIDTH) / 2;
    video = save_video_region(101, 2580);
    draw_box(box_cpos, 1, box_size, _$bcolor, _$fcolor);
    cpos = box_cpos + (BOX_WIDTH - strlen(header)) / 2;
    put_field(1, CH_FIELD, cpos, strlen(header), _$hcolor, header);
    cpos = box_cpos + (BOX_LENGTH-1)*100 + (BOX_WIDTH - strlen(trailer)) / 2;
    put_field(1, CH_FIELD, cpos, strlen(trailer), _$tcolor, trailer);

    put_cpos(box_cpos + 102);
    dputs("  The PC-MOS configuration information will be");
    put_cpos(box_cpos + 202);
    dputs("placed in the file named below.  If you wish to");
    put_cpos(box_cpos + 302);
    dputs("change the name, please type the new name in and");
    put_cpos(box_cpos + 402);
    dputs("press the ENTER key.  If the current name is OK");
    put_cpos(box_cpos + 502);
    dputs("simply press the ENTER key to accept it.");
    put_cpos(box_cpos + 702);
    dputs("Filename: ");

get_input:
    sprintf(source_file, "%c:\\CONFIG.SYS", target_drive);
    put_field(1, CH_FIELD, box_cpos+712, 40, _$bar_color, source_file);

    do {
        term = Read_field(4, box_cpos+712, 1, 40, _$bar_color, buffer);
/*
    User want to quit?
*/
        if(term == ESC) {
            restore_video_region(101, 2580, video);
            return(0);
        }
/*
    Keep source file as is?
*/
        else if(term == NO_DATA)
            break;
/*
    User entered a source file name.
*/
        else if(term == ENTER) {

            if(access(buffer, 0) == 0) {
                strcpy(source_file, buffer);
                strupr(source_file);
                break;
            }
            else {
                fp = fopen(buffer, "w");
                if(!fp) {
                    msg_list[0] = "Unable to open or create a file";
                    msg_list[1] = "with the name you specified.";
                    msg_list[2] = "Please try another.";
                    msg_list[3] = " ";
                    msg_list[4] = ">> Press ANY key to continue <<";
                    msg_list[5] = "";
                    USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
                    put_field(1, CH_FIELD, box_cpos+712, 40, _$bar_color, source_file);
                    continue;
                }
                fclose(fp);
                remove(buffer);
                strcpy(source_file, buffer);
                strupr(source_file);
                break;
            }
        }
    } FOREVER;
/*
    If the filename specified is a directory name, then
    don't allow him to edit it.
*/
    if(!get_file_attributes(source_file, &attrib)) {
        if((attrib & 0x10) != 0) {
            msg_list[0] = "   Cannot edit a directory!";
            msg_list[1] = " ";
            msg_list[2] = ">> Press ANY key to continue <<";
            msg_list[3] = "";
            USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
            goto get_input;
        }
    }
/*
    Construct the name of the backup file from the source filename.
*/
    _splitpath(source_file, drive, dir, fname, ext);
    sprintf(backup_file, "%s%s%s.BAK", drive, dir, fname);
/*
    Ready to go to the main menu.
*/
    restore_video_region(101, 2580, video);
    return(1);
}
