/*
*****************************************************************************
*
*   MODULE NAME:    Edit_keyboard_driver
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  11-June-90
*
*   REVISION DATE:  11-June-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Lets the user install a keyboard driver of his choice.
*
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Edit_keyboard_driver();
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
#include <rsa\stdusr.h>

Edit_keyboard_driver()
{
    extern unsigned char    kb_installed,
                            CONFIG_changed;

    extern char             kb_code[];

    char    *country_list[34],
            *keyboard_codes[17];

    int     i,
            option,
            def_opt;
/*
    Initialize option list.
*/
    country_list[0] = "United States";
    country_list[1] = "Belgium";
    country_list[2] = "Canada (French)";
    country_list[3] = "Denmark";
    country_list[4] = "France";
    country_list[5] = "Germany";
    country_list[6] = "Italy";
    country_list[7] = "Latin America";
    country_list[8] = "Netherlands";
    country_list[9] = "Norway";
    country_list[10] = "Portugal";
    country_list[11] = "Switzerland (French)";
    country_list[12] = "Switzerland (German)";
    country_list[13] = "Spain";
    country_list[14] = "Sweden";
    country_list[15] = "United Kingdom";
    country_list[16] = "";
    for(i=17; i<33; ++i)
        country_list[i] = "ED_KEYB-DESCRIPTION";
    country_list[33] = "";

    keyboard_codes[0] = "US";
    keyboard_codes[1] = "BE";
    keyboard_codes[2] = "CF";
    keyboard_codes[3] = "DK";
    keyboard_codes[4] = "FR";
    keyboard_codes[5] = "GR";
    keyboard_codes[6] = "IT";
    keyboard_codes[7] = "LA";
    keyboard_codes[8] = "NL";
    keyboard_codes[9] = "NO";
    keyboard_codes[10] = "PO";
    keyboard_codes[11] = "SF";
    keyboard_codes[12] = "SG";
    keyboard_codes[13] = "SP";
    keyboard_codes[14] = "SV";
    keyboard_codes[15] = "UK";
    keyboard_codes[16] = "";
/*
    Present the menu.
*/
    for(i=0; i<16; ++i) {
        if(strcmpi(keyboard_codes[i], kb_code) == 0) {
            def_opt = i;
            break;
        }
    }

    option = select_option(0, 8, country_list, def_opt, " Keyboard Driver ", "", RESTORE_VIDEO | HELP_DEFINED);

    if(option == -1)        /* No choice made */
        return;

    strcpy(kb_code, keyboard_codes[option]);        /* Get keyboard code */

    if(option == 0)                                 /* Default to US? */
        kb_installed = 0;
    else
        kb_installed = 1;

    if(option != def_opt)                           /* Any change? */
        CONFIG_changed = 1;
}
