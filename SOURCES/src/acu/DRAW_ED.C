/*
*****************************************************************************
*
*   MODULE NAME:    Draw_edit_box
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  6/27/90
*
*   REVISION DATE:  6/27/90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Using an input list of prompt lines, draws a
*                   standard box for use in editing various stuff
*                   for ACU.
*
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*	USAGE:			
*
*	PARAMETERS:
*
* NAME			TYPE	USAGE		DESCRIPTION
* ----			----	-----		-----------
*
*****************************************************************************
*							>> REVISION LOG <<
*
* DATE		PROG		DESCRIPTION OF REVISION
* ----		----		-----------------------
*
*****************************************************************************
*
*/
#include <stdlib.h>

Draw_edit_box(  char *header,               /* Box header text */
                char *trailer,              /* Box trailer text */
                char *prompt_lines[],       /* Background text prompts */
                int  prompt_cpos[] )       /* Returned CPOS for each field */
{
    extern int  _$bcolor,
                _$fcolor,
                _$hcolor,
                _$tcolor;

    int     i,
            cpos,
            box_cpos,
            box_size,
            box_width,
            box_length;

    box_width = max(strlen(header), strlen(trailer));

    for(i=0; strlen(prompt_lines[i]); ++i)
        box_width = max(box_width, strlen(prompt_lines[i]));

    box_width += 4;
    box_length = i + 2;
    box_size = (box_length)*100 + box_width;
    box_cpos = ((25-box_length)/2)*100 + (80-box_width)/2;
/*
    Calculate the box position and the position of each data entry
    field.
*/
    cpos = box_cpos + 102;
    for(i=0; strlen(prompt_lines[i]); ++i) {
        prompt_cpos[i] = cpos + index('_', prompt_lines[i]);
        cpos += 100;
    }
/*
    Draw the box and paint the background text.
*/
    draw_box(box_cpos, 1, box_size, _$bcolor, _$fcolor);
    cpos = box_cpos + 102;
    for(i=0; i<(box_length-2); ++i) {
        put_cpos(cpos);
        dputs(prompt_lines[i]);
        cpos += 100;
    }

    cpos = box_cpos + (box_width - strlen(header)) / 2;
    scr(2, cpos, strlen(header), _$hcolor);
    dputs(header);

    cpos = box_cpos + (box_length-1)*100 + (box_width - strlen(trailer)) / 2;
    scr(2, cpos, strlen(trailer), _$tcolor);
    dputs(trailer);
}
