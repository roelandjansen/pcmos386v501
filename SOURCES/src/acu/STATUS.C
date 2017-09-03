/*
*****************************************************************************
*
*   MODULE NAME:    Status_window
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  7/6/90
*
*   REVISION DATE:  7/6/90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Displays a screen containing the current
*                   system status and memory allocation so that a
*                   user of ACU may see where he stands at any time.
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Status_window()
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
#include <malloc.h>
#include <stdlib.h>
#include <rsa\rsa.h>
#include <rsa\stdusr.h>

Status_window()
{
    extern unsigned     EMS_buffer_size,
                        ramdisk_buffer_size;

    extern int          _$fcolor,
                        _$bcolor,
                        _$hcolor,
                        _$tcolor,
                        cache_size,
                        ext_mem_free,
                        ext_mem_size,
                        ext_mem_used;

    int     i,
            cpos,
            *video,
            box_cpos,
            box_size,
            box_width;

    char    key1,
            key2,
            *header,
            *trailer,
            *msg_list[10];

    for(i=0; i<10; ++i)
        msg_list[i] = malloc(64);

    header = " System Status ";
    trailer = " >> Press ANY key to continue << ";

    sprintf(msg_list[0], "Total Extended Memory .. %5d KB", ext_mem_size);
    sprintf(msg_list[1], "Extended Memory used ... %5d KB", ext_mem_used);
    sprintf(msg_list[2], "Extended Memory free ... %5d KB", ext_mem_free);
    msg_list[3][0] = '\0';


    box_width = max(strlen(header), strlen(trailer));

    for(i=0; i<3; ++i)
        box_width = max(box_width, strlen(msg_list[i]));

    box_width += 4;
    box_size = 500 + box_width;
    box_cpos = 202;                     /* Put box in upper left */
    video = save_video_region(box_cpos, box_size+102);

    draw_box(box_cpos, 1, box_size, _$bcolor, _$fcolor);

    cpos = box_cpos + (box_width - strlen(header)) / 2;
    scr(2, cpos, strlen(header), _$hcolor);
    dputs(header);

    cpos = box_cpos + 400 + (box_width - strlen(trailer)) / 2;
    scr(2, cpos, strlen(trailer), _$tcolor);
    dputs(trailer);

    cpos = box_cpos + 102;
    for(i=0; strlen(msg_list[i]); ++i) {
        put_cpos(cpos);
        dputs(msg_list[i]);
        cpos += 100;
    }

    cursor_off();
    while(!inkey(&key1, &key2));
    cursor_on();

    restore_video_region(box_cpos, box_size+102, video);

    for(i=0; i<10; ++i)
        free(msg_list[i]);
}
