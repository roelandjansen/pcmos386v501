/*
*****************************************************************************
*
*   MODULE NAME:    Terminate
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Configuration Utility
*
*   CREATION DATE:  8-May-90
*
*   REVISION DATE:  8-May-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    If no changes made terminates the program.
*
*
*               (C) Copyright 1990, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      status = Terminate();
*
*   PARAMETERS:
*
* NAME          TYPE    USAGE       DESCRIPTION
* ----          ----    -----       -----------
* status        int     output      Returned 0 if termination aborted.
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
#define FOREVER while(1)

#include <ctype.h>
#include <rsa\rsa.h>
#include <rsa\keycodes.h>

Terminate()
{
    extern unsigned char    CONFIG_changed;

    extern int      _$bcolor,
                    _$fcolor,
                    _$hcolor;

    char    *video_buffer;
    char    key1, key2;
    int     save_cpos;

    if(CONFIG_changed) {
        save_cpos = rdcpos();
		video_buffer = save_video_region(1025, 534);
        draw_box(1025, 1, 432, _$bcolor, _$fcolor);
        scr(2, 1033, 15, _$hcolor);
        dputs(" >> Warning << ");
		put_cpos(1127);
        dputs(" Do you want to save the new");
		put_cpos(1227);
        dputs(" configuration file? (Y/N): ");
		put_cpos(1254);
        do {
            while(!inkey(&key1, &key2))
                update_time_and_date();
            if(key1 == ESC)
                break;
            key1 = toupper(key1);
            if(key1 != 'Y' && key1 != 'N')
                continue;
            dputchar(key1);
            break;
        } FOREVER;

		restore_video_region(1025, 534, video_buffer);
        if(key1 == ESC)
            return(0);
        else if(key1 == 'Y')
            Write_configuration();
    }
/*
    He wants to quit.
*/
    USR_disconnect();
    scr(0,0,0,7);
    exit(1);
}
