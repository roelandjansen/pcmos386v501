/*
*****************************************************************************
*
*   MODULE NAME:    Edit_MOS_configuration
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
*   DESCRIPTION:    Main editing routine for all CONFIG.SYS options except
*                   the "DEVICE=" lines.
*
*
*               (C) Copyright 1990, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Edit_MOS_configuration();
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
#define FOREVER while(1)
#define HEADER  " MOS Configuration "
#define TRAILER " F1=HELP  ESC=EXIT "

#include <rsa\stdusr.h>
#include <rsa\rsa.h>

Edit_MOS_configuration()
{
    extern int      vdt_type;

    char        *opt_list[10];

    int         option = 0;
/*
    Display a list of options for the user to choose from.
*/
    do {
        opt_list[0] = "Memory Management";
        opt_list[1] = "Video Configuration";
        opt_list[2] = "Disk Caching";
        opt_list[3] = "Miscellaneous";
        opt_list[4] = "";
        opt_list[5] = "ED_MOS-MEMORY-MGMT";
        opt_list[6] = "ED_MOS-VIDEO-CONFIG";
        opt_list[7] = "ED_MOS-DISK-CACHE";
        opt_list[8] = "ED_MOS-MISC";
        opt_list[9] = "";

        option = select_option(0, 4, opt_list, option, HEADER, TRAILER, RESTORE_VIDEO | HELP_DEFINED);

        if(option == -1)
            break;
/*
    Call the appropriate routine.
*/
        switch(option) {
            case 0:
                Edit_mm_options();
                ++option;
                break;
            case 1:
                Edit_video_options();
                ++option;
                break;
            case 2:
                Edit_cache_options();
                ++option;
                break;
            case 3:
                Edit_misc_options();
                ++option;
        }
/*
    Move to the next option.
*/
        if(option > 3)
            option = 0;

    } FOREVER;
}
