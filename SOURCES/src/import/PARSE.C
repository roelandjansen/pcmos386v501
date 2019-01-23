/*
*****************************************************************************
*
*   MODULE NAME:    Parse_command_line
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
*   DESCRIPTION:    Parses the input command line.
*
*
*               (C) Copyright 1991, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Parse_command_line(int argc, char **argv);
*
*   PARAMETERS:
*
* NAME          TYPE    USAGE       DESCRIPTION
* ----          ----    -----       -----------
* argc          int     input       # of command line parms.
* argv          char**  input       Command line parm list.
*
*****************************************************************************
*                           >> REVISION LOG <<
*
* DATE      PROG        DESCRIPTION OF REVISION
* ----      ----        -----------------------
* 03/31/92	SAH		   Change to match export
*****************************************************************************
*
*/
#include <dos.h>
#include <string.h>
#include <rsa\rsa.h>
#include <rsa\keycodes.h>

#define FOREVER while(1)

extern char     yes[],
                cpath[],
                source_path[],
                target_path[];

extern unsigned char    O_flag, Q_flag, S_flag;

extern int      source_drive;


static void     Get_user_options();             /* Local to this source */
static void     Display_usage();

Parse_command_line(int argc, char **argv)
{
    union REGS      inregs, outregs;
    struct SREGS    segregs;

    char    drive[3], dir[65], fname[9], ext[5];
    char    cmd_tail[134];
    char    buffer[134];
    char    *cptr;

    int     i;

    unsigned    attrib;

    source_path[0] = '\0';
    target_path[0] = '\0';
    cmd_tail[0] = '\0';

    if(argc == 1) {
        Display_usage();
        Terminate(1);
    }

    for(i=1; i<argc; ++i) {
        if(!strcmp(argv[i], "/?")) {
            Display_usage();
            Terminate(1);
        }
        strcat(cmd_tail, argv[i]);                /* Accumulate arguments */

        if(argv[i][0] == '/') {
            strcpy(buffer, argv[i]);
            strupr(buffer);
            if(buffer[1] != 'Q' && buffer[1] != 'S' && buffer[1] != 'O') {
                printf("IMPORT: Unknown option [ %s ]\n", buffer);  /* @@XLATN */
                Terminate(1);
            }
        }
        else {		 
            if(!strlen(source_path)) {
                strcpy(source_path, argv[i]);
                strupr(source_path);
                cptr = strchr(source_path, '/');
                if(cptr)
                    *cptr = '\0';
            }
            else if(!strlen(target_path)) {
                strcpy(target_path, argv[i]);
                strupr(target_path);
                cptr = strchr(target_path, '/');
                if(cptr)
                    *cptr = '\0';
            }
            else {
                puts("IMPORT: Unknown command-line parameter.");    /* @@XLATN */
                Terminate(1);
            } /* End IF */
        } /* End IF */
    } /* End-for */
/*
**  Parse out the command line options.
*/
    strupr(cmd_tail);

    if(strstr(cmd_tail, "/O"))
        O_flag = 1;

    if(strstr(cmd_tail, "/S"))
        S_flag = 1;
/*
**  If /Q is present, then all other options are canceled.  The user
**  wants them input manually.
*/
    if(strstr(cmd_tail, "/Q")) {
        Q_flag = 1;
        O_flag = 0;
        S_flag = 0;
    }
/*
**  The command-line scan is done.  Was the /Q flag specified?
*/
    if(Q_flag)
        Get_user_options();

    if(!strlen(source_path)) {
        printf("IMPORT: No source specified.\n");   /* @@XLATN */
        Terminate(1);
    }
/*
**  Check the source specification.
*/
    _splitpath(source_path, drive, dir, fname, ext);
    if(drive[0] < 'A' || drive[0] > 'Z') {
        puts("IMPORT: Invalid drive specification in source path.");    /* @@XLATN */
        Terminate(1);
    }
    source_drive = drive[0] - 'A' + 1;
/*
**  Check the target path.
*/
    if(!strlen(target_path))
        get_current_path(target_path);
/*
**  Check the target path for wildcards.  If there are any, exit with
**  an error.
*/
    if(strchr(target_path, '*') || strchr(target_path, '?')) {
        puts("IMPORT: Target path cannot contain wildcards.");  /* @@XLATN */
        puts("        It must be a directory name.");   /* @@XLATN */
        Terminate(1);
    }
/*
**  Make sure that the target path either doesn't exist or if it does,
**  make sure that it is a directory.
*/
    _splitpath(target_path, drive, dir, fname, ext);
    if(strlen(fname) != 0 || strcmp(dir, "\\") != 0) {
        if(get_file_attributes(target_path, &attrib) == 0) {
            if((attrib & 0x10) == 0) {
                puts("IMPORT: Target path MUST be a directory.");   /* @@XLATN */
                Terminate(1);
            }
        }
    }
}
/*
============================================================================
Function Get_user_options()

  The user asked, with the /Q option, for the program to get the parameters
  from him manually.

============================================================================
*/
void Get_user_options()
{
    char    ans[10];

    puts(">> Enter options manually <<\n"); /* @@XLATN */

    do {
        printf("Enter SOURCE file or directory name: ");    /* @@XLATN */
        gets(source_path);
        strupr(source_path);
        if(strlen(source_path) != 0)
            break;
    } FOREVER;

    printf("Enter TARGET path: ");  /* @@XLATN */
    gets(target_path);
    strupr(target_path);

    printf("Do you want to be warned if an IMPORT file is going to\n"); /* @@XLATN */
    printf("overwrite an existing file? (Y/N): ");  /* @@XLATN */
    gets(ans);
    strupr(ans);
    if(ans[0] == yes[0])
        O_flag = 1;
    else
        O_flag = 0;

    printf("Do you want nested subdirectories restored? (Y/N): ");  /* @@XLATN */
    gets(ans);
    strupr(ans);
    if(ans[0] == yes[0])
        S_flag = 1;
    else
        S_flag = 0;
}
/*
============================================================================
Function Display_usage()

  Show the user how to use the IMPORT command.

============================================================================
*/
void Display_usage()
{
	 puts("PC-MOS File Restore Utility v5.01 (920331)");   /* @@XLATN */
	 puts("(C) Copyright 1990-1992 The Software Link, Inc.");
    puts("All Rights Reserved Worldwide.\n");

    puts("Usage:  IMPORT d:[path] d:[path] [/O] [/Q] [/S] [/?]\n"); /* @@XLATN */
    puts("        d:[path]     - File or directory to be restored."); /* @@XLATN */
    puts("        d:[path]     - Destination path to restore to."); /* @@XLATN */
    puts("        /O           - Overwrite files if already existing."); /* @@XLATN */
    puts("        /Q           - Query for options, ignore command line."); /* @@XLATN */
    puts("        /S           - Restore nested subdirectories."); /* @@XLATN */
    puts("        /?           - This HELP page.\n"); /* @@XLATN */
}
