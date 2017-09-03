/*
*****************************************************************************
*
*   MODULE NAME:    ACU.H
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  29-May-90
*
*   REVISION DATE:  29-May-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Contains Manifest descriptions for data structures
*                   used in ACU.EXE
*
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
*
*****************************************************************************
*
*   USAGE:  #include "acu.h"
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
struct  SERIAL_PARMS {
    unsigned        sp_address;             /* 0 - 8000h */
    unsigned        sp_IB;                  /* Input buffer size */
    unsigned        sp_OB;                  /* Output buffer size */
    unsigned        sp_IN;                  /* Interrupt */
    char            sp_HS;                  /* Handshake mode. */
    char            sp_CN;                  /* L/ocal or R/emote */
};

struct  IONA_PARMS {
    char            pp_mode;            /* Parallel port mode. 'B' */
    unsigned        int_level;          /* Interrupt level */
    unsigned        pp_address;         /* Parallel port address. */
    unsigned        sp_AD[4];           /* 4 serial ports for IONA */
    unsigned        sp_IB[4];           /* Input buffer size */
    unsigned        sp_OB[4];           /* Output buffer size */
    char            sp_HS[4];           /* Handshake mode */
    char            sp_CN[4];           /* Local or Remote */
    unsigned char   sp_MS[4];           /* Enable modem handshake signals? */
};
