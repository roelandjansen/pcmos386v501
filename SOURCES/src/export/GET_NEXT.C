/*
*****************************************************************************
*
*   MODULE NAME:    Get_next_disk
*
*   TASK NAME:      EXPORT.EXE
*
*   PROJECT:        PC-MOS backup / restore utilities
*
*   CREATION DATE:  1/23/91
*
*   REVISION DATE:  1/23/91
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
*   USAGE:          count = Get_next_disk(count);
*
*   PARAMETERS:
*
* NAME          TYPE    USAGE       DESCRIPTION
* ----          ----    -----       -----------
* count         int     I/O         Input is the number of diskettes
*                                   already written.  Output is the
*                                   number incremented by 1.
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
#include <stdio.h>

static char     buffer[80];

Get_next_disk(int count)
{
    extern unsigned char    A_flag;         /* Append to disk */
    extern char             target_arg[];
    extern int              target_drive;

    char    DTA_buffer[48];

    printf("\nPlease insert archive disk # %d in drive %s.\n",++count, target_arg); /* @@XLATN */
    printf("Press the ENTER key when ready ....");  /* @@XLATN */
    gets(buffer);
    printf("\n");
/*
**  Unless the user specified /A (append mode), destroy anything on
**  the target diskette.
*/
    read_DTA(DTA_buffer, 48);

    if(!A_flag) {
        printf("Preparing diskette in %s ... ", target_arg);    /* @@XLATN */
        Initialize_drive(target_drive);
        printf("diskette cleared.\n");  /* @@XLATN */
    }
/*
**  Write diskette VOLUME label on the target drive.
*/
    sprintf(buffer, "EX-I%04d", count);
    set_volume_label(target_drive, buffer);
/*
**  Return the new disk count.
*/
    write_DTA(DTA_buffer, 48);
    return(count);
}
