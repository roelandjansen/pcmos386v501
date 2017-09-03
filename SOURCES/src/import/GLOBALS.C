/*
*****************************************************************************
*
*   MODULE NAME:    globals
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
*   DESCRIPTION:    Global variables for IMPORT.EXE
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
char    yes[] = "Yes";          /* @@XLATN */
char    no[] = "No";            /* @@XLATN */

char    cpath[65];              /* Current path */
char    source_path[65];        /* Source argument */
char    target_path[65];        /* Target argument */
char    disk_label[13];         /* Current diskette label */

unsigned char   O_flag = 0;     /* Overwrite exising files */
unsigned char   Q_flag = 0;     /* Get options at runtime */
unsigned char   S_flag = 0;     /* Recover nested subdirectories */

int     disk_count = 0;         /* Number of disks read in */
int     source_drive;           /* 1=A, 2=B, etc. */
