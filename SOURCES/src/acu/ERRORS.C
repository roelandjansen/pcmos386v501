/*
*****************************************************************************
*
*   MODULE NAME:    No_option_available
*                   Bad_data_message
*                   Bad_option_message
*                   Bad_IO_address_message
*                   Bad_memory_address_message
*                   Not_enough_memory_message
*                   Freemem_conflict_message
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  6/29/90
*
*   REVISION DATE:  6/29/90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    General purpose error message routines.
*
*
*               (C) Copyright 1990, The Software Link, Inc.
*                           All Rights Reserved
*
*****************************************************************************
*
*       USAGE:
*
*       PARAMETERS:
*
* NAME          TYPE    USAGE           DESCRIPTION
* ----          ----    -----           -----------
*
*****************************************************************************
*                           >> REVISION LOG <<
*
* DATE      PROG    DESCRIPTION OF REVISION
* ----      ----    -----------------------
*
*****************************************************************************
*
*/
#define PRESS_KEY   ">> Press ANY key to continue <<";

#include <rsa\rsa.h>
#include <rsa\stdusr.h>

void No_option_available()
{
    char *msg_list[6];

    msg_list[0] = "No options are available for";
    msg_list[1] = "this field.  Press HELP key";
    msg_list[2] = "for more information.";
    msg_list[3] = " ";
    msg_list[4] = PRESS_KEY;
    msg_list[5] = "";
    USR_message(-1, msg_list, NOTE, 0, PAUSE_FOR_KEY);
}

void Bad_data_message()
{
    char *msg_list[8];

    msg_list[0] = "Your entry is out-of-range";
    msg_list[1] = "for the field or there was";
    msg_list[2] = "a bad character in the data.";
    msg_list[3] = "Re-enter the data or press";
    msg_list[4] = "the HELP or OPTIONS key.";
    msg_list[5] = " ";
    msg_list[6] = PRESS_KEY;
    msg_list[7] = "";
    USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
}

void Bad_option_message()
{
    char *msg_list[7];

    msg_list[0] = "The option selected is invalid.";
    msg_list[1] = "Press the HELP or OPTIONS key";
    msg_list[2] = "for information on the correct";
    msg_list[3] = "options for this field.";
    msg_list[4] = " ";
    msg_list[5] = PRESS_KEY;
    msg_list[6] = "";
    USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
}

void Bad_IO_address_message()
{
    char *msg_list[5];

    msg_list[0] = "That I/O address is invalid or";
    msg_list[1] = "alread in use.";
    msg_list[2] = " ";
    msg_list[3] = PRESS_KEY;
    msg_list[4] = "";
    USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
}

void Bad_memory_address_message()
{
    char *msg_list[5];

    msg_list[0] = "That memory address is invalid or";
    msg_list[1] = "already in use.";
    msg_list[2] = " ";
    msg_list[3] = PRESS_KEY;
    msg_list[4] = "";
    USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
}

void Not_enough_memory_message()
{
    extern int      ext_mem_free;

    char buffer[82];
    char *msg_list[8];

    sprintf(buffer, "Memory left = %5d KB.", ext_mem_free);

    msg_list[0] = "There is not enough Extended";
    msg_list[1] = "Memory left for a buffer of";
    msg_list[2] = "that size.";
    msg_list[3] = " ";
    msg_list[4] = buffer;
    msg_list[5] = " ";
    msg_list[6] = PRESS_KEY;
    msg_list[7] = "";
    USR_message(-1, msg_list, ERROR, 0, PAUSE_FOR_KEY);
}

void Freemem_conflict_message()
{
    char    *msg_list[12];

    msg_list[0] = "Unable to install this driver";
    msg_list[1] = "because the FREEMEM option";
    msg_list[2] = "is set to AUTO, which may";
    msg_list[3] = "cause an address conflict.";
    msg_list[4] = " ";
    msg_list[5] = "Change the FREEMEM option";
    msg_list[6] = "to MANUAL and don't include";
    msg_list[7] = "the default driver location";
    msg_list[8] = "in your FREEMEM area.";
    msg_list[9] = " ";
    msg_list[10] = PRESS_KEY;
    msg_list[11] = "";
    USR_message(0, msg_list, WARNING, 0, PAUSE_FOR_KEY);
}
