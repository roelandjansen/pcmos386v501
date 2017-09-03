/*
*****************************************************************************
*
*   MODULE NAME:    Output_file
*
*   TASK NAME:      EXPORT.EXE
*
*   PROJECT:        PC-MOS Utilities
*
*   CREATION DATE:  1/25/91
*
*   REVISION DATE:  1/25/91
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Compresses and writes the specified file to the
*                   target drive.
*
*
*               (C) Copyright 1991, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      status = Output_file(input_file);
*
*   PARAMETERS:
*
* NAME          TYPE    USAGE       DESCRIPTION
* ----          ----    -----       -----------
* status        int     output      Returned as follows:
*                                   0 = OK.  File has been output.
*                                   1 = File not output because it
*                                       did not meet date requirements.
*
* input_file    char*   input       Full pathname of file to be placed
*                                   on target drive.
*
*****************************************************************************
*                           >> REVISION LOG <<
*
* DATE      PROG        DESCRIPTION OF REVISION
* ----      ----        -----------------------
* 03/31/92	SAH			Bug corrects for 14th disk, increase peformance
*							   with larger buffer
*
*****************************************************************************
*
*/
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <io.h>
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <rsa\rsa.h>
#include <errno.h>

#define BUF_SIZE    24 * 1024
#define DISK_CHUNK  16

static  char    signature[] = "Xf";			
static  char    filename[13];
static  char    DTA_buffer[48];

static  int     file_date[7];

static unsigned file_attrib;
static unsigned time_stamp;
static unsigned date_stamp;

static long     file_size;

Output_file(char *input_file)
{
    extern char     target_arg[];

    extern unsigned char    D_flag,
                            M_flag;

    extern int      start_date[];

    static char     drive[3], dir[65], fname[9], ext[5];
    static char     output_path[65];
    static char     output_file[65];

    int     l;
    int     status;
/*
**  Save the DTA.
*/
    read_DTA(DTA_buffer, 48);
/*
**  Get initial information about the input file.
*/
    get_file_date(input_file, file_date);
    date_stamp = ((file_date[0] - 1980) << 9) + (file_date[1] << 5) + file_date[2];
    time_stamp = (file_date[3] << 11) + (file_date[4] << 5) + (file_date[5] >> 1);
    get_file_attributes(input_file, &file_attrib);
    file_size = get_file_size(input_file);
/*
**  If the user specified to backup only files that were modified
**  (I.E. the archive bit is set) then check to see if this file
**  qualifies to be backed up.
*/
    if(M_flag && (file_attrib & 0x20) == 0) {
        write_DTA(DTA_buffer, 48);
        return(1);
    }

    file_attrib &= 0xDF;                            /* Clear archive bit */

    printf("Exporting: %s\n", input_file);  /* @@XLATN */
    _splitpath(input_file, drive, dir, fname, ext);

    strcpy(filename, fname);
    strcat(filename, ext);
/*
**  Next, using the pathname of the file input, construct the
**  pathname of the output file.  Then, before trying to copy
**  it over, make sure the path directory exists on the target
**  drive.
*/
    sprintf(output_file, "%s%s%s%s", target_arg, dir, fname, ext);

    if(strlen(dir) > 0) {
        strcpy(output_path, target_arg);
        strcat(output_path, dir);
        makepath(output_path);
    }
    else
        output_path[0] = '\0';
/*
**  Did the user ask to output only files past a certain date?
*/
    if(D_flag) {
        if( file_date[0] >= start_date[0] &&
          file_date[1] >= start_date[1] &&
          file_date[2] >= start_date[2] ) {
            Write_output_file(input_file, output_file, output_path);
        }
        else {
            write_DTA(DTA_buffer, 48);
            return(1);
        }
    }
    else
        Write_output_file(input_file, output_file, output_path);
/*
**  The file was output successfully.
*/
    write_DTA(DTA_buffer, 48);
    return(0);
}

/*
============================================================================
Function Write_output_file:

  Compresses and writes the specified input file to the target file.

============================================================================
*/
Write_output_file(char *infile, char *outfile, char *disk_path)
{
    extern unsigned char    cvalue;     /* Compression value */

    extern char     target_arg[];
    extern int      disk_count,
                    target_drive;

    unsigned char   bflag,
                    spec_buffer[10],
                    *inbuff,
                    *outbuff;


    int             space_free;

    unsigned        temp,
                    byte_count,
                    comp_count;

    int            in_handle,
                   out_handle;

/*
**  Load the TCB with the security class of this file before writing
**  it. (If under MOS that is).
*/
    if(is_MOS()) {
        get_file_specs(infile, spec_buffer);
        bflag = get_break_flag();
        set_break_flag(0);
    }
/*
**  Allocate buffer space.
*/
    inbuff = malloc(BUF_SIZE);
    outbuff = malloc(BUF_SIZE + 1024);       /* Give overflow room */
/*
**  Open the two files.
*/
    out_handle = open(outfile, O_CREAT | O_BINARY | O_RDWR, S_IREAD | S_IWRITE);
    in_handle = open(infile, O_BINARY | O_RDONLY);
/*
**  Write the file date into the header.
*/
    write(out_handle, signature, 2);                /* Write EXPORT signature */
    write(out_handle, (char *) &file_attrib, 1);    /* File attributes */
    write(out_handle, (char *) &time_stamp, 2);     /* Time stamp of file */
    write(out_handle, (char *) &date_stamp, 2);     /* Date stamp of file */
    write(out_handle, (char *) &file_size, 4);      /* File length (bytes) */
    write(out_handle, filename, 13);                /* File name */
/*
**  Read, compress and write the file.
*/
    cvalue = 0;

    do {
        byte_count = read(in_handle, inbuff, BUF_SIZE);
        if(byte_count == 0)
            break;
        comp_count = Compress_data(inbuff, outbuff, byte_count);
        space_free = diskfree(target_drive);
        if(space_free < DISK_CHUNK) {
            close(out_handle);
            disk_count = Get_next_disk(disk_count);
            printf("Continuing export of: %s\n", outfile);  /* @@XLATN */
            if(strlen(disk_path) > 0)
                makepath(disk_path);
            out_handle = open(outfile, O_CREAT | O_BINARY | O_RDWR, S_IREAD | S_IWRITE);
        }
        write(out_handle, outbuff, comp_count);
    } FOREVER;

    close(in_handle);
    close(out_handle);
/*
**  Restore the TCB file class to the default.
*/
    if(is_MOS()) {
        restore_TCB_data();
        set_break_flag(bflag);
    }
/*
**  Clear the archive bit in the input file.
*/
    set_file_attributes(infile, file_attrib);

    free(inbuff);
    free(outbuff);
    return(0);
}
