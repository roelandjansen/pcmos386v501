/*
*****************************************************************************
*
*   MODULE NAME:    Edit_device_list
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  22-May-90
*
*   REVISION DATE:  22-May-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Presents a screen that allows the user to select
*                   which device driver to be added to the CONFIG.SYS
*                   file.
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
#define FOREVER while(1)
#define MARKER  0x10            /* Marks options that have been set-up */
#define PRESS_KEY   ">> Press ANY key to continue <<"

#include <rsa\stdusr.h>
#include <malloc.h>

Edit_device_list()
{
    extern char             memdev_opt[],
                            *pipe_names[];

    extern unsigned char    auto_freemem,
                            kb_installed,
                            EMS_installed,
                            VNA_installed,
                            pipe_installed[],
                            mouse_installed,
                            serial_installed,
                            ramdisk_installed;

    extern int              _$ml_color,
                            pipe_count,
                            pipe_index,
                            _$menu_color;

    char    *header,
            *trailer,
            *menu_header,
            *msg_list[16],
            *pipe_list[26],
            *opt_list[16];

    int     i,
            cpos,
            option;

/*
    Allocate space for the option lists.
*/
    for(i=0; i<16; ++i)
        opt_list[i] = malloc(64);

    for(i=0; i<26; ++i)
        pipe_list[i] = malloc(64);

    pipe_list[25][0] = '\0';
/*
    Display the options for the user to choose from.
*/
    header = " Device Drivers ";
    trailer = " F1=HELP  ESC=EXIT ";
    option = 0;
/*
    Build the second half of the opt_list FIRST, because these
    entries (the help tags) won't changed from pass-to-pass.
*/
    strcpy(opt_list[8], "ED_DEV-EMS-DRIVER");
    strcpy(opt_list[9], "ED_DEV-SERIAL-DRIVER");
    strcpy(opt_list[10], "ED_DEV-MOUSE-DRIVER");
    strcpy(opt_list[11], "ED_DEV-PIPE-DRIVER");
    strcpy(opt_list[12], "ED_DEV-RAMDISK-DRIVER");
    strcpy(opt_list[13], "ED_DEV-KEYBOARD-DRIVER");
    strcpy(opt_list[14], "ED_DEV-VNA-DRIVER");
    opt_list[15][0] = '\0';
/*
    Present the options.
*/
    do {
        if(EMS_installed)
            sprintf(opt_list[0], "%c EMS Driver", MARKER);
        else
            strcpy(opt_list[0], "  EMS Driver");


        if(serial_installed)
            sprintf(opt_list[1], "%c Serial Port Driver", MARKER);
        else {
            mouse_installed = 0;
            strcpy(opt_list[1], "  Serial Port Driver");
        }

        if(mouse_installed)
            sprintf(opt_list[2], "%c Mouse Driver", MARKER);
        else
            strcpy(opt_list[2], "  Mouse Driver");

        if(pipe_count > 0)
            sprintf(opt_list[3], "%c Pipe Driver", MARKER);
        else
            strcpy(opt_list[3], "  Pipe Driver");

        if(ramdisk_installed)
            sprintf(opt_list[4], "%c RAMdisk Driver", MARKER);
        else
            strcpy(opt_list[4], "  RAMdisk Driver");

        if(kb_installed)
            sprintf(opt_list[5], "%c Keyboard Driver", MARKER);
        else
            strcpy(opt_list[5], "  Keyboard Driver");

        if(VNA_installed)
            sprintf(opt_list[6], "%c VNA Driver", MARKER);
        else
            strcpy(opt_list[6], "  VNA Driver");

        opt_list[7][0] = '\0';   /* Terminate the list */
/*
    Get the option from the user.
*/
        option = select_option(0, 7, opt_list, option, header, trailer, RESTORE_VIDEO | HELP_DEFINED);

        if(option == -1)
            break;
/*
    Call the routine specified by the option.
*/
        switch(option) {
            case 0:
                if(auto_freemem == 1)
                    Freemem_conflict_message();
                else {
                    Edit_EMS_parms();
                    option++;
                }
                break;
            case 1:
                Edit_serial_parms();
                option++;
                break;
            case 2:
                if(Edit_mouse_parms())
                    option++;
                break;
            case 3:
                pipe_index = 0;
                do {
                    pipe_count = 0;
                    for(i=0; i<25; ++i) {
                        if(pipe_installed[i]) {
                            pipe_count++;
                            sprintf(pipe_list[i], "%c %s", MARKER, pipe_names[i]);
                        }
                        else
                            sprintf(pipe_list[i], "  %s", pipe_names[i]);
                    }
                    pipe_index = select_option(0, 10, pipe_list, pipe_index,
                        " Which PIPE device? ", "", RESTORE_VIDEO);
                    if(pipe_index == -1)
                        break;
                    Edit_pipe_parms();
                } FOREVER;
                option++;
                break;
            case 4:
                if(auto_freemem == 1)
                    Freemem_conflict_message();
                else {
                    Edit_RAMdisk_parms();
                    option++;
                }
                break;
            case 5:
                Edit_keyboard_driver();
                option++;
                break;
            case 6:
/*
    The VNA routine uses a standard menu, so make sure this
    one is restored on return.
*/
                if(!strcmp(memdev_opt, "/P")) {
                    msg_list[0] = "VNA is not available on a PS/2.";
                    msg_list[1] = " ";
                    msg_list[2] = PRESS_KEY;
                    msg_list[3] = "";
                    USR_message(0, msg_list, WARNING, 0, PAUSE_FOR_KEY);
                    option++;
                    break;
                }

                Edit_VNA_parms();
                USR_menu(1, _$menu_color);
                menu_header = " PC-MOS Configuration ";
                cpos = 101 + (80 - strlen(menu_header)) / 2;
                scr(2, cpos, strlen(menu_header), _$ml_color);
                dputs(menu_header);
                option++;
                break;
        }
        if(option > 6)
            option = 0;

    } FOREVER;
/*
    All done.  Return to main.
*/
    for(i=0; i<16; ++i)
        free(opt_list[i]);

    for(i=0; i<26; ++i)
        free(pipe_list[i]);
}
