/*
*****************************************************************************
*
*   FILE:   SHELL.C - Contains routines written to intercept User
*                     Interface routines and provide system-wide
*                     function key control for ACU.
*
*   MODULE NAMES:   Read_field
*                   Read_USR_field
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  7/6/90
*
*   REVISION DATE:  7/6/90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    These routines provide the means by which global
*                   function key interception may be achieved.  This
*                   is being done, at this point, to provide a
*                   program wide entry to the system status screen.  No
*                   matter where the user is in the program he is able,
*                   using the appropriate function key, to summon the
*                   system status screen.
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*   USAGE:
*
*       term = Read_field(func, cpos, fldtyp, fldlen, attr, buffer);
*       term = Read_USR_field(field_id, buffer, clear, attrib);
*
*   The arguments to these routines are identical to those passed to
*   RSA library routines "Read_field" and "USR_read".  These routines
*   simply pass the call onto the library and then check for any
*   program-wide function keys pressed before returning the normal
*   result.
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
#define     FOREVER     while(1)

#include <rsa\rsa.h>
#include <rsa\stdusr.h>
#include <rsa\keycodes.h>

int Read_field( int func,
                int cpos,
                int fldtyp,
                int fldlen,
                int attrib,
                char *buffer )
{
    int     term;

    do {
        term = readed(func, cpos, fldtyp, fldlen, attrib, buffer);

        if(term == FKEY && buffer[0] == F3)
            Status_window();
        else
            break;

    } FOREVER;

    return(term);
}

int Read_USR_field( int field_id,
                    char *buffer,
                    int clear,
                    int attrib )
{
    int     term;

    do {
        term = USR_read(field_id, buffer, clear, attrib);

        if(term == FKEY && buffer[0] == F3)
            Status_window();
        else
            break;

    } FOREVER;

    return(term);
}
