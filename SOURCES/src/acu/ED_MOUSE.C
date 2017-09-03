/*
*****************************************************************************
*
*   MODULE NAME:    Edit_mouse_parms
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  1-June-90
*
*   REVISION DATE:  1-June-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Allows user to install the $MOUSE.SYS driver.
*
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      status = Edit_mouse_parms();
*
*	PARAMETERS:
*
* NAME			TYPE	USAGE		DESCRIPTION
* ----			----	-----		-----------
* status        int     output      Returned non-zero if the edit was
*                                   successful.
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
#include <rsa\stdusr.h>

Edit_mouse_parms()
{
    extern unsigned char    CONFIG_changed,
                            mouse_installed,
                            serial_installed;

    char        *header,
                *msg_list[20];

    int         option;

    if(!serial_installed) {
        msg_list[0] = "The Serial Port Driver ($SERIAL.SYS)";
        msg_list[1] = "MUST be installed prior to installing";
        msg_list[2] = "the mouse driver.";
        msg_list[3] = " ";
        msg_list[4] = "  >> Press ANY key to continue <<";
        msg_list[5] = "";
        USR_message(0, msg_list, WARNING, 0, PAUSE_FOR_KEY);
        return(0);
    }
/*
    Paint a box asking the user if he wants the mouse installed.
*/
    header = " Install MOUSE? ";
    msg_list[0] = "NO";
    msg_list[1] = "YES";
    msg_list[2] = "";
    option = select_option(0, 2, msg_list, 0, header, "", RESTORE_VIDEO);
/*
    Did status change?
*/
    if(option != mouse_installed)
        CONFIG_changed = 1;

    mouse_installed = option;
    return(1);
}
