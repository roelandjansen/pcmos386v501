/*
*****************************************************************************
*
*   Module name:        main
*
*   Task name:          COMPFILE.EXE
*
*   Creation date:      1/31/90
*
*   Revision date:      8/17/90
*
*   Author:             B. W. Roeser
*
*   Description:        File Comparision Utility
*
*
*               (C) Copyright 1990, The Software Link Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:          COMPFILE  filespec  filespec
*
*****************************************************************************
*                           >> Revision Log <<
*
* Date      Prog        Description of Revision
* ----      ----        -----------------------
* 1/31/90   BWR         Rewrite.
*
* 3/26/90   BWR         Added foreign language translation markers
*                       to message lines.
*
* 8/17/90   BWR         Now returns error code indicating number of
*                       files that failed to compare.  Final version
*                       for MOS 4.10 release.
*
*****************************************************************************
*
*/
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>

char        source_arg[65];         /* Input name of source file */
char        target_arg[65];         /* Input name of target file */

char        source_template[65];
char        source_file[65];
char        target_template[65];
char        target_file[65];

char        source_drive[3];
char        source_dir[65];
char        source_fname[13];
char        source_ext[5];

char        target_drive[3];
char        target_dir[65];
char        target_fname[13];
char        target_ext[5];

char        filename[13];
int         attrib;

int         status;
int         fail_count = 0;         /* Number of file compares that failed */

unsigned    source_attrib;
unsigned    target_attrib;

char        group_compare = 0;
char        source_DTA[48];         /* For "find_next_file" */

int         compare_count = 0;

main(argc, argv)

int     argc;
char    *argv[];
{
    char    *cpy;

    cpy = "PC-MOS File Comparison Utility (Version 4.10)"; /* @@XLATN */
    puts(cpy);
    puts("(C) Copyright 1990, The Software Link, Inc.");
    puts("All Rights Reserved.\n");

    switch(argc) {
        case 1:
            printf("Enter name of first file: "); /* @@XLATN */
            gets(source_arg);
            if(!strlen(source_arg))
                exit(0);
            printf("Enter name of target file: "); /* @@XLATN */
            gets(target_arg);
            if(!strlen(target_arg))
                exit(0);
            puts("");
            break;
        case 3:
            strcpy(source_arg, argv[1]);
            strcpy(target_arg, argv[2]);
            break;
        default:
            puts("Usage: COMPFILE filespec filespec"); /* @@XLATN */
            exit(1);
    }
    strupr(source_arg);
    strupr(target_arg);
/*
    If the source name has wildcards in it, or it is a directory,
    a file search will be done.
*/
    if(strchr(source_arg, '?') || strchr(source_arg, '*'))
        group_compare = 1;
    else if(!get_file_attributes(source_arg, &source_attrib)) {
        if(source_attrib & 0x10) {
            group_compare = 1;
            strcat(source_arg, "\\*.*");
        }
        else
            group_compare = 0;
    }
    else {
        printf("** Unable to open source file \"%s\" **\n"      /* @@XLATN */
            , source_arg);
        exit(1);
    }

    _splitpath(source_arg, source_drive, source_dir, source_fname, source_ext);
    _splitpath(target_arg, target_drive, target_dir, target_fname, target_ext);
/*
    Make a source directory template.
*/
    strcpy(source_template, source_drive);
    strcat(source_template, source_dir);
/*
*****************************************************************************
* GROUP file compare.
*
*    In a group file compare, the input source filename is passed through
*   the "find_first_file" sequence and all files matching that original
*   name are compared.
*
*****************************************************************************
*/
    if(group_compare) {
        if(!find_first_file(source_arg, filename, &attrib)) {
            printf("** No files found for \"%s\" **\n", /* @@XLATN */
                 source_arg);
            exit(1);
        }
/*
    If the first file is a volume label, ignore it and continue
    the search.
*/
        if((attrib & 0x08) == 0) {
            if(strcmp(filename, ".") != 0 && strcmp(filename, "..") != 0) {
                strcpy(source_file, source_template);
                strcat(source_file, filename);
                if(Make_target_file_name()) {
                    if(Compare_files(source_file, target_file) != 0)
                        fail_count++;
                }
            }
        }

        while(find_next_file(filename, &attrib)) {
            if(strcmp(filename, ".") != 0 && strcmp(filename, "..") != 0) {
                strcpy(source_file, source_template);
                strcat(source_file, filename);
                if(Make_target_file_name()) {
                    if(Compare_files(source_file, target_file) != 0)
                        fail_count++;
                }
            }
        }

        if(!compare_count) {
            puts("\n>> No files found to compare. <<"); /* @@XLATN */
            exit(1);
        }
        else
            exit(fail_count);
    }
/*
******************************************************************************
* SINGLE file compare.
*
*   For single file compares, the target name must be resolvable
*   to a single file pathname.
*
******************************************************************************
*/
    else {
        strcpy(source_file, source_arg);
        if(Make_target_file_name()) {
            status = Compare_files(source_file, target_file);
            switch(status) {
                case 0:
                    exit(0);
                case 1:
                case 2:
                case 3:
                    exit(1);
                case 4:
                    exit(2);
            }
        }
    }
}
/*
******************************************************************************
*/
Make_target_file_name()
{
    char    filename[13];
/*
------------------------------------------------------------------------------
    Handle special cases for the target:

        "\"     Target file in root directory, current drive.
        "d:"    Target file in CURRENT directory on specified drive.
        "d:\"   Target file in ROOT directory on specified drive.
------------------------------------------------------------------------------
*/
    _splitpath(source_file, source_drive, source_dir, source_fname, source_ext);

    if(
        (!strcmp(target_arg, "\\")) ||
        (strlen(target_arg) == 2 && target_arg[1] == ':') ||
        (strlen(target_arg) == 3 && target_arg[1] == ':' &&
            target_arg[2] == '\\')
      ) {
        strcpy(target_file, target_arg);
        strcat(target_file, source_fname);
        strcat(target_file, source_ext);
    }
    else 
        strcpy(target_file, target_arg);
/*
    If the target file has a '*' in the main file name or the extension,
    replace it with the main file or extension of the source name.
*/
    _splitpath(target_file, target_drive, target_dir, target_fname, target_ext);
    if(strchr(target_fname, '*'))
        strcpy(target_fname, source_fname);
    if(strchr(target_ext, '*'))
        strcpy(target_ext, source_ext);
    sprintf(target_file, "%s%s%s%s", target_drive, target_dir, target_fname,
                                     target_ext);
    read_DTA(source_DTA, 48);
    status = find_first_file(target_file, filename, &target_attrib);
    write_DTA(source_DTA, 48);
    if(!status) {
        printf("** Could not open \"%s\" **\n", target_file); /* @@XLATN */
        return(0);
    }
    sprintf(target_file, "%s%s%s", target_drive, target_dir, filename);

    if(target_attrib & 0x10) {
        strcat(target_file, "\\");
        strcat(target_file, source_fname);
        strcat(target_file, source_ext);
        if(access(target_file, 0) != 0) {
            printf("** Could not open \"%s\" **\n", target_file); /* @@XLATN */
            return(0);
        }
    }

    return(1);
}
/*
******************************************************************************
Function Compare_files()

  Compares the two files submitted.  Returns the following status:

    0 = Success.
    1 = Tried to compare file with itself.
    2 = Could not open first file.
    3 = Could not open 2nd file.
    4 = The two files failed the compare.

******************************************************************************
*/
#define     BUF_SIZE    24 * 1024       /* 24K buffer for reading files */

unsigned char   source_buffer[BUF_SIZE], target_buffer[BUF_SIZE];

Compare_files(source_file, target_file)

char    *source_file;
char    *target_file;
{
    FILE    *fp_source, *fp_target;
    char    *cptr;
    char    first_mismatch = 1;
    long    base_offset;

    int     i;
    int     compare_success = 1;
    int     source_bytes_read;
    int     target_bytes_read;
    int     compare_len;

    if(strcmpi(source_file, target_file) == 0) {
        printf("** Cannot compare \"%s\" with itself. **\n", /* @@XLATN */
            source_file);
        return(1);
    }

    fp_source = fopen(source_file, "rb");
    if(!fp_source) {
        printf("** Could not open \"%s\" **\n", source_file); /* @@XLATN */
        return(2);
    }

    fp_target = fopen(target_file, "rb");
    if(!fp_target) {
        printf("** Could not open \"%s\" **\n", target_file); /* @@XLATN */
        return(3);
    }
    puts("--------------------------------------------------------");
    printf("Comparing %s to %s\n\n", source_file, target_file); /* @@XLATN */
/*
    The two files are open.  Fill the source buffer, then the target
    buffer, then do the compares.
*/
    base_offset = 0;
    while(!feof(fp_source) && !feof(fp_target)) {
        source_bytes_read = fread(source_buffer, sizeof(char), BUF_SIZE, 
            fp_source);
        target_bytes_read = fread(target_buffer, sizeof(char), BUF_SIZE,
            fp_target);
        
        compare_len = min(source_bytes_read, target_bytes_read);
/*
    Look through the buffers, comparing them.
*/
        for(i=0; i<compare_len; ++i) {
            if(source_buffer[i] != target_buffer[i]) {
                compare_success = 0;
                if(first_mismatch) {
                    puts(" OFFSET      FILE 1     FILE 2"); /* @@XLATN */
                    puts(" ------      ------     ------");
                    first_mismatch = 0;
                }
                printf("%08lx:    %02X ", base_offset+i, source_buffer[i]);
                if(isprint(source_buffer[i]))
                    printf("'%c'     ", source_buffer[i]);
                else
                    printf("'.'     ", source_buffer[i]);

                printf("%02X ",target_buffer[i]);

                if(isprint(target_buffer[i]))
                    printf("'%c'\n", target_buffer[i]);
                else
                    printf("'.'\n", target_buffer[i]);
            }
        }

        base_offset += BUF_SIZE;
    }

    if(compare_success)
        puts("The files compared OK."); /* @@XLATN */
    else
        puts("");

    if(source_bytes_read < target_bytes_read)
        printf("\n>> Warning: %s is longer than %s <<\n", /* @@XLATN */
            target_file, source_file);
    else if(target_bytes_read < source_bytes_read)
        printf("\n>> Warning: %s is longer than %s <<\n", /* @@XLATN */
            source_file, target_file);
        
    fclose(fp_source);
    fclose(fp_target);

    puts("--------------------------------------------------------");

    compare_count++;
    if(compare_success)
        return(0);
    else
        return(4);
}
