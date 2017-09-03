/*
*****************************************************************************
*
*   MODULE NAME:    Initialize_drive
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
*   DESCRIPTION:    Completely destroys the file structure of the
*                   selected drive.
*
*
*               (C) Copyright 1991, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      status = Initialize_drive(drive);
*
*   PARAMETERS:
*
* NAME          TYPE    USAGE       DESCRIPTION
* ----          ----    -----       -----------
* status        int     output      Returned 0 for success.
* drive         int     input       Drive to be initialized.
*                                   (1=A, 2=B, etc.)
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
#include <dos.h>

static char             FCB[37];
static union REGS       inregs, outregs;
static struct SREGS     segregs;

static void     Kill_directory(char*, char*);

Initialize_drive(int drive)
{
    char    filename[13];
    char    current_path[65];

    int     attrib,
            current_drive;
/*
**  Set up our FCB.
*/
    FCB[0] = drive;
    strcpy(&FCB[1], "???????????");
    zap(&FCB[12], 25, 0);
/*
**  First, get the current drive, then change to the selected drive.
*/
    inregs.h.ah = 0x19;
    intdos(&inregs, &outregs);
    current_drive = outregs.h.al;
/*
**  Change to the selected drive.
*/
    inregs.h.ah = 0x0E;
    inregs.h.dl = drive-1;
    intdos(&inregs, &outregs);
    if(outregs.x.cflag)
        return(-1);
/*
**  Change to the root directory.
*/
    chdir("\\");
/*
**  Delete all files in this directory.
*/
    inregs.h.ah = 0x13;
    inregs.x.dx = (unsigned) FCB;
    segread(&segregs);
    int86x(0x21, &inregs, &outregs, &segregs);
/*
**  Now, search for all directories and walk down into them.
*/
    get_current_path(current_path);

    if(find_first_file("*.*", filename, &attrib)) {
        do {
            if(attrib & 0x10)
                Kill_directory(current_path, filename);
        } while(find_next_file(filename, &attrib));
    }
/*
**  Return to the original drive and exit.
*/
    inregs.h.ah = 0x0E;
    inregs.h.dl = current_drive;
    intdos(&inregs, &outregs);
    if(outregs.x.cflag)
        return(-1);

    return(0);
}

void Kill_directory(char *parent, char *dir_name)
{
    char    DTA_buffer[48];
    char    current_path[65];
    char    filename[13];

    int     attrib;

    read_DTA(DTA_buffer, 48);

    chdir(dir_name);
/*
**  Delete all files in this directory.
*/
    inregs.h.ah = 0x13;
    inregs.x.dx = (unsigned) FCB;
    segread(&segregs);
    int86x(0x21, &inregs, &outregs, &segregs);
/*
**  Now, search for all directories and walk down into them.
*/
    get_current_path(current_path);

    if(find_first_file("*.*", filename, &attrib)) {
        if(!strcmp(filename, "."))
            find_next_file(filename, &attrib);      /* Pass ".." */

        while(find_next_file(filename, &attrib)) {
            if(attrib & 0x10)
                Kill_directory(current_path, filename);
        }
    }
/*
**  The directory has been wiped out.  Return to the parent and remove
**  the directory.
*/
    chdir(parent);
    rmdir(dir_name);
    write_DTA(DTA_buffer, 48);
}
