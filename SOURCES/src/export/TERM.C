/*
*****************************************************************************
*
*   MODULE NAME:    Terminate
*
*   TASK NAME:      EXPORT.EXE
*
*   PROJECT:        PC-MOS Utilities
*
*   CREATION DATE:  2/8/91
*
*   REVISION DATE:  2/8/91
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Restores TCB info, then exits.
*
*
*               (C) Copyright 1991, The Software Link, Inc.
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
Terminate(int status)
{
    if(is_MOS())
        restore_TCB_data();
    exit(status);
}
