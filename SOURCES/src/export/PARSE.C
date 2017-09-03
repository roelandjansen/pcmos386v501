/*
*****************************************************************************
*
*   MODULE NAME:        Parse_command_line
*
*   TASK NAME:          EXPORT.EXE
*
*   PROJECT:            PC-MOS Utilities
*
*   CREATION DATE:      1/8/91
*
*   REVISION DATE:      1/8/91
*
*   AUTHOR:             B. W. Roeser
*
*   DESCRIPTION:        Interprets command line options.
*
*
*               (C) Copyright 1991, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Parse_command_line(int argc, char **argv)
*
*   PARAMETERS:
*
* NAME          USAGE       DESCRIPTION
* ----          -----       -----------
* argc          input       Number of command line arguments.
* argv          input       Pointer to command line.
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
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <rsa\rsa.h>

extern unsigned char        A_flag,
                            S_flag,
                            M_flag,
                            Q_flag,
                            D_flag;

extern char     yes[],
                source_arg[],
                target_arg[];

extern int      target_drive,
                start_date[];

Parse_command_line(int argc, char **argv)
{
    unsigned char   fatal_error = 0;

    char    drive[3], dir[65], fname[9], ext[5];    /* Use w/_splitpath */

    char    *cptr,
            ans[10],
            buffer[81],         /* General purpose use */
            cmd_tail[128];

    int     i;

/*
    Initialize.
*/
    source_arg[0] = '\0';       /* Initially nothing */
    target_arg[0] = '\0';
    cmd_tail[0] = '\0';

    if(argc == 1) {
        Display_usage();
        Terminate(1);
    }
/*
    Scan all command-line arguments.  First look for all switched
    arguments.
*/
    for(i=1; i<argc; ++i) {
        if(!strcmp(argv[i], "/?")) {                /* User wants help? */
            display_usage();
            Terminate(1);
        }

        strcat(cmd_tail, argv[i]);

        if(argv[i][0] == '/') {
            strcpy(buffer, argv[i]);
            strupr(buffer);
            if(buffer[1] != 'Q' && buffer[1] != 'A' && buffer[1] != 'D'
              && buffer[1] != 'M' && buffer[1] != 'S') {
                printf("EXPORT: Unknown option [ %s ]\n", buffer);  /* @@XLATN */
                Terminate(1);
            }
        }
        else {
            if(!strlen(source_arg)) {
                strcpy(source_arg, argv[i]);
                strupr(source_arg);
                cptr = strchr(source_arg, '/');
                if(cptr)
                    *cptr = '\0';
            }
            else if(!strlen(target_arg)) {
                strcpy(target_arg, argv[i]);
                strupr(target_arg);
                cptr = strchr(target_arg, '/');
                if(cptr)
                    *cptr = '\0';
            }
            else {
                puts("IMPORT: Unknown command-line parameter.");    /* @@XLATN */
                Terminate(1);
            } /* End IF */
        } /* End IF */
    }
/*
**  Get command line options.
*/
    strupr(cmd_tail);

    if(strstr(cmd_tail, "/A"))
        A_flag = 1;

    if(strstr(cmd_tail, "/M"))
        M_flag = 1;

    if(strstr(cmd_tail, "/S"))
        S_flag = 1;

    if(cptr = strstr(cmd_tail, "/D")) {
        cptr += 2;
        if(*cptr != ':') {
            Syntax_error("/D option");
            Terminate(1);
        }
        cptr++;
        start_date[1] = atoi(cptr);
        cptr = strchr(cptr, '-');
        if(start_date[1] < 1 || start_date[1] > 12 || !cptr) {
            Syntax_error("/D option");
            Terminate(1);
        }
        start_date[2] = atoi(++cptr);
        cptr = strchr(cptr, '-');
        if(start_date[2] < 1 || start_date[2] > 31 || !cptr) {
            Syntax_error("/D option");
            Terminate(1);
        }
        start_date[0] = atoi(++cptr);
        D_flag = 1;
    }
/*
**  If the /Q option was specified, all other options are cancelled.
**  Get command line parameters manually.
*/
    if(strstr(cmd_tail, "/Q")) {
        Q_flag = 1;
        A_flag = 0;
        D_flag = 0;
        M_flag = 0;
        S_flag = 0;
        zap(start_date, 14, 0);
        source_arg[0] = '\0';
        target_arg[0] = '\0';
    }
/*
============================================================================
    End of argument processing.

    Now, was the /Q flag set indicating manual input of options?
============================================================================
*/
    if(Q_flag) {
        puts(">> Enter options manually <<\n"); /* @@XLATN */
/*
    Verify input at the time the user does it.
*/
        printf("Enter source path: ");  /* @@XLATN */
        gets(source_arg);
        strupr(source_arg);

        do {
            printf("Enter target drive: "); /* @@XLATN */
            gets(target_arg);
            strupr(target_arg);
            if(!isalpha(target_arg[0]) || target_arg[1] != ':' ||
              strlen(target_arg) > 2)
                puts("Invalid drive specified.");   /* @@XLATN */
            else
                break;
        } FOREVER;

        printf("Archive subdirectories? (Y/N): ");  /* @@XLATN */
        gets(ans);
        strupr(ans);
        if(ans[0] == yes[0])
            S_flag = 1;
        else
            S_flag = 0;

        do {
            printf("Enter file selection option:\n\n"); /* @@XLATN */
            printf("A - Back up ALL files in path.\n"); /* @@XLATN */
            printf("M - Files modified since last back up.\n"); /* @@XLATN */
            printf("D - Files modified after a specific date.\n\n");    /* @@XLATN */
            printf("Enter option: ");   /* @@XLATN */
            gets(ans);
            ans[0] = toupper(ans[0]);
            if(strlen(ans) > 1)
                ans[0] = '?';           /* Force error trap below */
            switch(ans[0]) {
                case 'M':
                    M_flag = 1;
                    break;
                case 'D':
                    printf("\nEnter date. (MM/DD/YY): ");   /* @@XLATN */
                    scanf("%d/%d/%d", &start_date[1], &start_date[2], &start_date[0]);
                    break;
                case 'A':
                    break;
                default:
                    puts("*** Invalid option. Try again. ***"); /* @@XLATN */
                    continue;
            }
            break;
        } FOREVER;
/*
**  Does the user want to append to data on the diskette?
*/
        do {
            printf("Enter (O) to overwrite diskette or (A) to append to it: "); /* @@XLATN */
            gets(ans);
            ans[0] = toupper(ans[0]);
            switch(ans[0]) {
                case 'O':
                    A_flag = 0;
                    break;
                case 'A':
                    A_flag = 1;
                    break;
                default:
                    puts("*** Invalid option. Try again. ***"); /* @@XLATN */
                    continue;
            }
            break;
        } FOREVER;
    } /* End test on Q_flag */
/*
    Check validity of command line options.  (They will have already
    been checked if the user entered them manually.
*/
    fatal_error = 0;

    if(!isalpha(target_arg[0]) || target_arg[1] != ':' ||
      strlen(target_arg) > 2) {
        puts("EXPORT: Target must be a drive ONLY. (Ex. A:)");  /* @@XLATN */
        fatal_error = 1;
    }
    else
        target_drive = target_arg[0] - 'A' + 1;

    if(fatal_error) {
        puts("\nEXPORT: Due to errors, cannot continue.");  /* @@XLATN */
        puts("          EXPORT terminated.");   /* @@XLATN */
        Terminate(1);
    }
}

Display_usage()
{
	 puts("PC-MOS File Archiving Utility v5.01 (920331)");   /* @@XLATN */
	 puts("(C) Copyright 1990-1992 The Software Link, Inc.");
    puts("All Rights Reserved Worldwide.\n");

    puts("Usage:  EXPORT d:[path] d: [/S] [/D:mm-dd-yy] [/M] [/Q] [/A] [/?]\n"); /* @@XLATN */
    puts("        d:[path]     - File or directory to be archived."); /* @@XLATN */
    puts("        d:           - Destination drive to accept archive."); /* @@XLATN */
    puts("        /S           - Include sub-directories in archive."); /* @@XLATN */
    puts("        /D:mm-dd-yy  - Archive all files AFTER this date"); /* @@XLATN */
    puts("                       otherwise archive all files."); /* @@XLATN */
    puts("        /M           - Archive only updated files."); /* @@XLATN */
    puts("        /A           - Append to existing files on diskette."); /* @@XLATN */
    puts("        /Q           - Query for options, ignore command line."); /* @@XLATN */
    puts("        /?           - This HELP page.\n"); /* @@XLATN */
}

Syntax_error(char *str)
{
    printf("EXPORT: Syntax error in %s\n", str);    /* @@XLATN */
    puts("Use EXPORT /? for HELP.");    /* @@XLATN */
}
