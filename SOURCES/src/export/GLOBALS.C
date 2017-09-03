/*
*****************************************************************************
*
*   MODULE NAME:        globals
*
*   TASK NAME:          EXPORT.EXE
*
*   PROJECT:            PC-MOS utilities
*
*   CREATION DATE:      1/8/91
*
*   REVISION DATE:      1/8/91
*
*   AUTHOR:             B. W. Roeser
*
*   DESCRIPTION:        Contains all global variables used by
*                       EXPORT.EXE
*
*
*               (C) Copyright 1991, The Software Link, Inc.
*                       All Rights Reserved
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
unsigned char   A_flag = 0;     /* Append to data existing on disk */
unsigned char   S_flag = 0;     /* Archive sub directories? */
unsigned char   M_flag = 0;     /* Copy only modified files? */
unsigned char   Q_flag = 0;     /* Get parameters manually? */
unsigned char   D_flag = 0;     /* Archiving files after a date? */

unsigned char   cvalue;         /* Compression value, reset for each file */

char        yes[] = "Yes";      /* @@XLATN */
char        no[] = "No";        /* @@XLATN */
char        source_arg[65];     /* Source path argument */
char        target_arg[65];     /* Target drive argument */
int         target_drive;       /* Numeric drive assignment. 1=A, 2=B */
int         disk_count;         /* Number of disks backed up so far */

int         start_date[7] = {0,0,0,0,0,0,0};    /* Archive after date */
