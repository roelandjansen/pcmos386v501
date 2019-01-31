/*
*****************************************************************************
*
*   Module name:        main
*
*   Task name:          HELPGEN.EXE
*
*   Creation date:      9/10/89
*
*   Revision date:      3/11/91
*
*   Author:             B. W. Roeser
*
*   Description:        Creates the index file HELP.NDX and the text
*                       file HELP.TXT used by the HELP.EXE program.
*
*   Notes:
*
*       Newline characters on all messages are on separate lines to
*   facilitate foreign language translation.
*
*               (C) Copyright 1990, The Software Link Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*                           >> Revision Log <<
*
* Date      Prog        Description of Revision
* ----      ----        -----------------------
* 3/9/90    BWR         Code cleaned up, reformatted and prepared for
*                       foreign language translation.
*
* 3/11/91   BWR         Majority of code rewritten for new help program
*                       being developed.
*
*****************************************************************************
*
*/
#include <stdio.h>
#include <rsa\rsa.h>

#define LINE_LEN    133
#define TAG_LEN     15

char    *cptr,
        tag[TAG_LEN+1],
        linebuff[LINE_LEN];

int     cpos,
        size;

unsigned    *wptr,
            offset_low,
            offset_high;


unsigned long   offset;

FILE    *fp_text,           /* File pointer for text file 'HELP.TXT' */
        *fp_source,         /* File pointer for source file 'HELP.SRC' */
        *fp_ndx;            /* File pointer for index file 'HELP.NDX' */

main()
{
    display_copyright("PC-MOS Help Menu conversion utility");   /* @@XLATN */
    Open_files();
    Process_help();
    Close_files();
}
/*
**  Open the files HELP.SRC, HELP.TXT and HELP.NDX.
*/
Open_files()
{
    if(!(fp_source = fopen("HELP.SRC", "r"))) {
        puts("HELPGEN: Cannot open HELP.SRC."); /* @@XLATN */
        puts("\n");
        exit(1);
    }

    if(!(fp_text = fopen("HELP.TXT", "w"))) {
        puts("HELPGEN: Cannot create HELP.TXT."); /* @@XLATN */
        puts("\n");
        exit(1);
    }

    if(!(fp_ndx = fopen("HELP.NDX", "wb"))) {
        puts("HELPGEN: Cannot create HELP.NDX."); /* @@XLATN */
        puts("\n");
        exit(1);
    }
}
/*
**  Process help file.
*/
Process_help()
{
    char    *msg;
/*
**  Search for the first tag entry in the help source file.
*/
    while(get_line(linebuff, LINE_LEN, fp_source)) {
        if (linebuff[0] == ';')
            break;
    }
/*
**  Was one found?  If not, exit with an error message.
*/
    if (linebuff[0] != ';') {
        puts("HELPGEN: No valid help tags found in HELP.SRC");  /* @@XLATN */
        exit(1);
    }
/*
**  A tag record was found.  Initialize counters and begin processing
**  the text records.
*/
    Save_tag();
    size = 0;
    offset = 0;
/*
**  Read all lines of text from the help source file.  Upon
**  discovering a help tag, dump the accumulator values to the
**  index file.
*/
    printf("Processing help tag: ");    /* @@XLATN */
    cpos = rdcpos();

    while(get_line(linebuff,LINE_LEN,fp_source)) {
        if (linebuff[0] == ';') {           /* if this is a new tag */
            Dump_index_record();            /* process the tag */
            size = 0;
            continue;                       /* and skip text processing */
        }
        size += fprintf(fp_text, "%s\n", linebuff);
        size++;                         /* addition byte for 'CR' character */
    }
/*
**  Write the final tag record to the index file.
*/
    linebuff[0] = '\0';
    Dump_index_record();

    cpos -= (cpos % 100);
    cpos++;
    put_cpos(cpos);
    ffill(stdout, ' ', 80);
    put_cpos(cpos);
    puts("Helpfile generation complete.");      /* @@XLATN */
}

Save_tag()
{
    if(strlen(linebuff) > TAG_LEN+1) {
        printf("\n");
        printf("WARNING: Text tag is longer than 15 characters.\n"); /* @@XLATN */
        printf("         Text tag = %s\n\n", &linebuff[1]); /* @@XLATN */
        linebuff[TAG_LEN-1] = '\0';  /* Truncate the line */
    }
    strcpy(tag, &linebuff[1]);
}
/*
**  Dump the tag to the index file along with the offset and
**  length of the help record.
*/
Dump_index_record()
{
    int i;
/*
**  Prepare the tag for the index file.
*/
    i = strlen(tag) - 1;
    while (i++ < TAG_LEN-1)
        tag[i] = ' ';
    tag[TAG_LEN] = '\0';
/*
**  Display the help tag that we're working on.
*/
    put_cpos(cpos);
    dputs(tag);
/*
**  Write the tag to the index file.
*/
    for(i=0; i<TAG_LEN; ++i)
        putc(tag[i], fp_ndx);
/*
**  Write out the record's offset and length.  (In HIGH/LOW order to
**  maintain compatiblity with the PASCAL version.
*/
    wptr = (unsigned *) &offset;
    putw(wptr[1], fp_ndx);
    putw(wptr[0], fp_ndx);
    putw(size, fp_ndx);
/*
    Modify the offset by the new record size.
*/
    offset += size;
    Save_tag();                 /* copy tag into record */
}


Close_files()          /* close the files */
{
    fclose(fp_source);
    fclose(fp_text);
    fclose(fp_ndx);
}
