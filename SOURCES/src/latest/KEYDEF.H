/*
*****************************************************************************
*
*	Module name:		KEYDEF.H
*
*	Task name:			none
*
*	Creation date:		11/20/89
*
*	Revision date:		11/20/89
*
*	Author:				S. Hyde / B. W. Roeser
*
*	Description:		Common keystroke value manifests
*
*
*				(C) Copyright 1989, The Software Link Inc.
*						All Rights Reserved
*
*****************************************************************************
*							>> Revision Log <<
*
* Date		Prog		Description of Revision
* ----		----		-----------------------
* 11/20/89	BWR			Removed MODEM.COM specific variable definitions
*						from the file and placed directly in MODEM.C.  This
*						header may now be used for any C module that makes
*						use of function key codes, etc.
*
*****************************************************************************
*
*/
#define ESC 0x1b
#define ENTER 0xD
#define F1  0x3b	/* codes for the function keys */
#define F2  0x3c
#define F3  0x3d
#define F4  0x3e
#define F5  0x3f
#define F6  0x40
#define F7  0x41
#define F8  0x42
#define F9  0x43
#define F10 0x44

#define	BELL 7

#define HOME  0x47	/* codes for the keypad */
#define UP    0x48
#define PGUP  0x49
#define LEFT  0x4b
#define RIGHT 0x4d
#define END   0x4f
#define DOWN  0x50
#define PGDN  0x51
#define INS   0x52
#define DEL   0x53
