/*
*****************************************************************************
*
*   MODULE NAME:    Get_next_disk
*
*   TASK NAME:      IMPORT.EXE
*
*   PROJECT:        PC-MOS Utilities
*
*   CREATION DATE:  2/5/91
*
*   REVISION DATE:  2/5/91
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Asks the user to insert the next diskette and
*                   awaits a keystroke.
*
*
*               (C) Copyright 1991, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:          count = Get_next_disk(count, label);
*
*   PARAMETERS:
*
* NAME          TYPE    USAGE       DESCRIPTION
* ----          ----    -----       -----------
* count         int     I/O         Input is the number of diskettes
*                                   already written.  Output is the
*                                   number incremented by 1.
*
* label         char*   Input       Disk label placed here.
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
#include <stdlib.h>
#include <rsa\rsa.h>

#define FOREVER while(1)

extern int      source_drive;

static char     buffer[80];

Get_next_disk(int count, char *label)
{
    extern int  source_drive;

    char    drive;

    int     seq_number;

    drive = source_drive + 'A' - 1;
    ++count;

    do {
        printf("\nPlease insert archive disk # %d in drive %c.\n",count, drive);    /* @@XLATN */
        printf("Press the ENTER key when ready ....");  /* @@XLATN */
        gets(buffer);
        printf("\n");
/*
**  Get the volume label from the drive and make sure it's the correct
**  one.
*/
        get_volume_label(source_drive, label);
        seq_number = atoi(&label[4]);
        if(seq_number != count)
            printf("\n** Incorrect archive disk in drive %c **\n\n", drive);    /* @@XLATN */
        else
            break;
    } FOREVER;
/*
**  Return the new disk count.
*/
    return(count);
}
