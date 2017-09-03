/*
*****************************************************************************
*
*   MODULE NAME:        Compress_data
*
*   TASK NAME:          EXPORT.EXE
*
*   PROJECT:            MOS Utilities
*
*   CREATION DATE:      1/31/91
*
*   REVISION DATE:      1/31/91
*
*   AUTHOR:             B. W. Roeser
*
*   DESCRIPTION:        "Compresses" the repeated strings in an
*                       input buffer.
*
*
*               (C) Copyright 1991, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:          
*
*   PARAMETERS:
*
* NAME          TYPE    USAGE       DESCRIPTION
* ----          ----    -----       -----------
*
*****************************************************************************
*                           >> REVISION LOG <<
*
* DATE      PROG        DESCRIPTION OF REVISION
* ----      ----        -----------------------
* 2/7/91    BWR         Converted to old EXPORT encoding method for
*                       compatibility with old EXPORT.
*
*****************************************************************************
*
*/
#include <string.h>

extern unsigned char    cvalue;

static unsigned char    local_buffer[300];

Compress_data(unsigned char *inbuff, unsigned char *outbuff, int len)
{
    static int      Count_repeats();

    int     max;
    int     ib_index, ob_index, lb_index;
    int     count;
    int     diff_count;

    ib_index = ob_index = lb_index = 0;
    diff_count = 0;
    max = len-1;

    ib_index = 0;
    while(ib_index < max) {
        if(inbuff[ib_index] != inbuff[ib_index+1]) {
            local_buffer[lb_index++] = inbuff[ib_index++];
            diff_count++;
            if(diff_count == 254) {
                diff_count = 0;
                outbuff[ob_index++] = 254;      /* Uncompressed data */
                outbuff[ob_index++] = 0;        /* Compressed data */
                memcpy(&outbuff[ob_index], local_buffer, 254);
                ob_index += 254;
                lb_index = 0;
            }
        }
/*
**  At least two bytes are the same.  Make sure there are at least
**  4 before dumping the local buffer and setting up a control
**  word.
*/
        else {
            count = Count_repeats(inbuff, ib_index, len);
            if(count >= 3) {
                count++;                                /* Now # of bytes */
                if(cvalue != inbuff[ib_index]) {
                    cvalue = inbuff[ib_index];
                    outbuff[ob_index++] = 0xFF;         /* Control */
                    outbuff[ob_index++] = cvalue;       /* New comp byte */
                }
                outbuff[ob_index++] = diff_count;       /* Uncompressed */
                outbuff[ob_index++] = count;            /* Compressed bytes */
                ib_index += count;
                if(diff_count > 0) {
                    memcpy(&outbuff[ob_index], local_buffer, diff_count);
                    ob_index += diff_count;
                    lb_index = 0;
                    diff_count = 0;
                }
            }
            else {
                local_buffer[lb_index++] = inbuff[ib_index++];
                diff_count++;
                if(diff_count == 254) {
                    diff_count = 0;
                    outbuff[ob_index++] = 254;
                    outbuff[ob_index++] = 0;
                    memcpy(&outbuff[ob_index], local_buffer, 254);
                    ob_index += 254;
                    lb_index = 0;
                }
            }
        } /* endif */
    } /* End WHILE */
/*
**  If any of the local buffer is left, dump it out.  If not, then
**  handle the last byte.
*/
    if(diff_count > 0) {
        outbuff[ob_index++] = diff_count;
        outbuff[ob_index++] = 0;
        memcpy(&outbuff[ob_index], local_buffer, diff_count);
        ob_index += diff_count;
    }
/*
**  Was there a straggler byte?
*/
    if(ib_index == max) {
        outbuff[ob_index++] = 1;
        outbuff[ob_index++] = 0;
        outbuff[ob_index++] = inbuff[max];
    }
/*
**  All done.  Return the size of the output buffer.
*/
    return(ob_index);
}
/*
============================================================================
Function Count_repeats

  Taking the input buffer and index and counts the number of repeats
  found at that offset.

============================================================================
*/
Count_repeats(const char *buffer, const int offset, const int len)
{
    int     i,
            count = 0;

    register char   test_byte;

    if(offset >= len)
        return(0);

    test_byte = buffer[offset];

    for(i=offset+1; i<len; ++i) {
        if(buffer[i] == test_byte) {
            if(++count == 253)                  /* Max in CTRL word */
                return(count);
        }
        else
            return(count);
    }

    return(count);
}
