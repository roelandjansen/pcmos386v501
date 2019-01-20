/*
*****************************************************************************
*
*   MODULE NAME:    Decompress_file
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
*   DESCRIPTION:    Performs the read-decompress cycle of the specified
*                   file to be imported.
*
*
*               (C) Copyright 1991, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      status = Decompress_file(source_file, target_file);
*
*   PARAMETERS:
*
* NAME          TYPE    USAGE       DESCRIPTION
* ----          ----    -----       -----------
* status        int     output      Returned as follows:
*                                   0 = File was decompressed OK.
*                                   1 = Memory allocation error.
*                                   2 = File error.
*                                   3 = Disk changed during
*                                       decompression.  Must restart
*                                       the find-first-file sequence.
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
#define     BUF_SIZE    24*1024

#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <io.h>
#include <malloc.h>
#include <ctype.h>
#include <rsa\rsa.h>

#define FOREVER while(1)

extern char     yes[],
                O_flag,
                disk_label[];

extern int      disk_count;

static void     Get_more_data(void);
static int      Continue_to_next_disk(char *);

static unsigned char    *inbuff, *outbuff;

static int  ib_index, ob_index;
static int  in_handle, out_handle;
static int  bytes_left;

static long total_bytes,
            file_size;

Decompress_file(char *infile, char *outfile)
{
    char            buffer[81];             /* General purpose use */
    char            signature[10];

    unsigned char   value = 0;              /* Initial value */
    unsigned char   spec_buf[10];
    unsigned char   bflag;

    int     return_stat;
    int     i, byte_count;
    int     file_date[7];

    unsigned    a_stat;
    unsigned    time_stamp;
    unsigned    date_stamp;
    unsigned    count;
    unsigned    uc_count;
    unsigned    com_count;
    unsigned    file_attrib;
/*
**  Does the output file already exist?
*/
    a_stat = access(outfile, 0);

    if(!O_flag && a_stat == 0) {
        printf("\nWarning: The output file \"%s\" already exists.\n", outfile); /* @@XLATN */
        printf("Do you want to overwrite it? (Y/N): "); /* @@XLATN */
        gets(buffer);
        strupr(buffer);
        if(buffer[0] != yes[0]) {
            printf("Import of %s aborted.\n", infile);  /* @@XLATN */
            return(0);
        }
    }
    printf("Importing %s\n", infile);   /* @@XLATN */
/*
**  If the output file already existed, make SURE we get rid of it,
**  even if the R/O bit is set.
*/
    if(a_stat == 0) {
        set_file_attributes(outfile, 0);        /* Turn off all attributes */
        remove(outfile);                        /* Delete the file */
    }
/*
**  Open the files.
*/
    in_handle = open(infile, O_BINARY | O_RDONLY);
    if(in_handle == -1) {
        printf("Could not open \"%s\"\n", infile);  /* @@XLATN */
        return(2);
    }

    out_handle = open(outfile, O_CREAT | O_BINARY | O_RDWR, S_IREAD | S_IWRITE);
    if(out_handle == -1) {
        printf("Could not open \"%s\"\n", outfile); /* @@XLATN */
        close(in_handle);
        return(2);
    }
/*
**  Get the security info from the file and turn off the break flag
**  while copying the file.
*/
    if(is_MOS()) {
        if(get_file_specs(infile, spec_buf) != 0)
            printf("IMPORT: Failed to get file info for %s\n", infile); /* @@XLATN */
        bflag = get_break_flag();
        set_break_flag(0);
    }
/*
**  Read the input file and begin to decompress it.
*/
    zap(signature, 3, '\0');
    read(in_handle, signature, 2);
    if(strcmp(signature, "Xf") != 0) {
        printf("The file \"%s\" was NOT exported.\n", infile);  /* @@XLATN */
        close(in_handle);
        close(out_handle);
        if(is_MOS()) {
            restore_TCB_data();
            set_break_flag(bflag);
        }
        return(2);
    }
/*
**  Get the rest of the header stuff.
*/
    file_attrib = 0;
    read(in_handle, (char *) &file_attrib, 1);
    read(in_handle, (char *) &time_stamp, 2);
    read(in_handle, (char *) &date_stamp, 2);
    read(in_handle, (char *) &file_size, 4);
    read(in_handle, buffer, 13);    /* Get and dispose of filename */
/*
**  Convert the time/date stamps to usable form.
*/
    file_date[0] = ((date_stamp & 0xFE00) >> 9) + 1980;
    file_date[1] = (date_stamp & 0x01E0) >> 5;
    file_date[2] = date_stamp & 0x001F;
    file_date[3] = (time_stamp & 0xF800) >> 11;
    file_date[4] = (time_stamp & 0x07E0) >> 5;
    file_date[5] = (time_stamp & 0x001F) << 1;
/*
**  Allocate buffer space.
*/
    inbuff = malloc(BUF_SIZE + 1024);
    if(!inbuff) {
        puts("IMPORT: Memory allocation failure. (inbuff)");    /* @@XLATN */
        Terminate(1);
    }

    outbuff = malloc(BUF_SIZE + 1024);   /* Leave a little extra room */
    if(!outbuff) {
        puts("IMPORT: Memory allocation failure (outbuff)");    /* @@XLATN */
        Terminate(1);
    }

    ob_index = 0;
    total_bytes = 0;
/*
**  Read the first file chunk.
*/
    return_stat = 0;
    bytes_left = 0;
    Get_more_data();
/*
**   Decompress from inbuff until outbuff is full, then dump
**  outbuff.
*/
    do {
        if(bytes_left < 2) {
            Get_more_data();
            if(bytes_left < 2) {
                if((total_bytes+ob_index) < file_size) {
                    if(Continue_to_next_disk(infile) != 0) {
                        close(out_handle);
                        free(inbuff);
                        free(outbuff);
                        if(is_MOS()) {
                            restore_TCB_data();
                            set_break_flag(bflag);
                        }
                        return(2);
                    }
                    Get_more_data();
                    return_stat = 3;
                    continue;
                }
                else {
                    if(ob_index > 0) {
                        write(out_handle, (char *) outbuff, ob_index);
                        total_bytes += ob_index;
                    }
                }
                break;
            }
        }
        uc_count = inbuff[ib_index++];
        com_count = inbuff[ib_index++];
        bytes_left -= 2;
/*
**  A change of compression byte?  If so, set to the new value.
*/
        if(uc_count == 0xFF) {
            value = com_count;
            continue;
        }
/*
**  No change of compression byte.  Unpack the uncompressed data, then
**  enter the compressed data if any.
*/
        if(uc_count > 0) {                  /* Any uncompressed data? */
            if(uc_count > bytes_left) {
                Get_more_data();
                if(uc_count > bytes_left) {
                    if(Continue_to_next_disk(infile) != 0) {
                        close(out_handle);
                        free(inbuff);
                        free(outbuff);
                        if(is_MOS()) {
                            restore_TCB_data();
                            set_break_flag(bflag);
                        }
                        return(2);
                    }
                    Get_more_data();
                    return_stat = 3;
                }
            }
            memcpy(&outbuff[ob_index], &inbuff[ib_index], uc_count);
            ib_index += uc_count;
            ob_index += uc_count;
            bytes_left -= uc_count;
        }
/*
**  Write the compressed bytes.
*/
        for(i=0; i<com_count; ++i)
            outbuff[ob_index++] = value;

        if(ob_index >= BUF_SIZE) {
            write(out_handle, (char *) outbuff, ob_index);
            total_bytes += ob_index;
            ob_index = 0;
        }
    } FOREVER;

    close(in_handle);
    close(out_handle);
    free(inbuff);
    free(outbuff);
/*
**  Before finishing up, write the file attributes and time stamp to
**  the new file.
*/
    set_file_date(outfile, file_date);
    set_file_attributes(outfile, file_attrib);
    if(is_MOS()) {
        restore_TCB_data();
        set_break_flag(bflag);
    }
    return(return_stat);
}
/*
===========================================================================
Function Get_more_data

  Called when more data is needed from the input file.
===========================================================================
*/
void Get_more_data()
{
    int     i;
/*
**  Slide the data left in the input buffer and append the new data
**  to the end of it.
*/
    if(bytes_left != 0) {
        for(i=0; i<bytes_left; ++i)
            inbuff[i] = inbuff[ib_index++];
    }
    ib_index = 0;

    bytes_left += read(in_handle, (char *) &inbuff[bytes_left], BUF_SIZE);
}

/*
===========================================================================
Function Continue_to_next_disk()

  Called when at end-of-file on import file before the decompression is
  complete.

===========================================================================
*/
Continue_to_next_disk(char *infile)
{
    close(in_handle);
    disk_count = Get_next_disk(disk_count, disk_label);
    in_handle = open(infile, O_BINARY | O_RDONLY);
    if(in_handle == -1) {
        printf("Could not open \"%s\"\n", infile);  /* @@XLATN */
        return(1);
    }
    printf("\nContinuing import of %s\n", infile);  /* @@XLATN */
    return(0);
}
