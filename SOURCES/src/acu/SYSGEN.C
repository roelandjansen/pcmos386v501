/*
*****************************************************************************
*
*   MODULE NAME:    System_generation
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  7/9/90
*
*   REVISION DATE:  7/9/90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Configuration section main routine.
*
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      System_generation();
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
#include <rsa\rsa.h>
#include <rsa\stdusr.h>

#define FOREVER while(1)

System_generation()
{
    extern unsigned char    CONFIG_changed;

    char    *header,
            *msg_list[10],
            *opt_list[10],
            *menu_box_header,
            *menu_box_trailer,
            *menu_text[10];

    int     opt,
            status,
            def_opt;
/*
    Get the filename from the user.
*/
    if(!Get_filename())
        return;
/*
    Get any options already declared in the specified
    configuration file.
*/
	Read_existing_options();
/*
    Present the main option menu.
*/
    def_opt = opt = 0;
    menu_box_header = " Configuration Menu ";
    menu_box_trailer = " F1=HELP  ESC=EXIT ";
    menu_text[0] = "Edit MOS Parameters";
    menu_text[1] = "Edit Device Drivers";
    menu_text[2] = "Save Changes and Exit";
    menu_text[3] = "Abandon Changes and Exit";
    menu_text[4] = "";
    menu_text[5] = "SYSGEN-EDIT-MOS";
    menu_text[6] = "SYSGEN-EDIT-DEVICES";
    menu_text[7] = "SYSGEN-SAVE-EXIT";
    menu_text[8] = "SYSGEN-ABANDON-EXIT";
    menu_text[9] = "";

    do {

        opt = select_option(0, 4, menu_text, def_opt, menu_box_header, menu_box_trailer, RESTORE_VIDEO | HELP_DEFINED);

        if(opt == -1) {
            if(CONFIG_changed) {
                header = " Save Changes to Configuration? ";
                opt_list[0] = "NO";
                opt_list[1] = "YES";
                opt_list[2] = "";
                opt = select_option(0, 2, opt_list, 1, header, "", RESTORE_VIDEO);
                if(opt == -1) {
                    opt = def_opt;
                    continue;
                }
                if(opt == 1)
                    Write_configuration();
            }
            break;
        }
/*
    Display the current set-up on the screen, then go read the configuration
    options from the user.
*/
        switch(opt) {
            case 0:
                Edit_MOS_configuration();
                break;
            case 1:
                Edit_device_list();
                break;
            case 2:
                Write_configuration();
                return;
            case 3:
                CONFIG_changed = 0;
                return;
        }
        if(++opt > 3)
            opt = 0;
        def_opt = opt;

    } FOREVER;
}
