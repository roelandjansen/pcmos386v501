/*
*****************************************************************************
*
*   MODULE NAME:        Lock_himem_range
*                       Unlock_himem_range
*                       Check_himem_range
*                       Lock_port_range
*                       Unlock_port_range
*                       Check_port_range
*                       Build_address_map
*
*   TASK NAME:          ACU.EXE
*
*   PROJECT:            PC-MOS Auto Configuration Utility
*
*   CREATION DATE:      7/6/90
*
*   REVISION DATE:      7/6/90
*
*   AUTHOR:             B. W. Roeser
*
*   DESCRIPTION:        Routines for keeping track of currently
*                       installed options' use of memory and
*                       port ranges.
*
*
*   Notes:
*
*       1)  These routines manipulate the storage map by incrementing
*           and decrmenting the values.  The reason for this is that
*           certain options like VNA/IONA can map more than one device
*           to the same location, so each map entry is a COUNT of the
*           devices mapped there.  This is to ensure that when a
*           conflicting device is DE-mapped from the list that any
*           other device having placed and entry there is not also
*           marked as removed.
*
*				(C) Copyright 1990, The Software Link, Inc.
*						All Rights Reserved
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
#include "acu.h"

unsigned char   himem_map[384];     /* Each describes a 1K address range */
unsigned char   port_map[1024];     /* Each indicates 1 I/O port */

/*
=============================================================================
Function "Lock_himem_range"

  This function reserves a range of memory addresses in the area 0xA0000
  to 0xFFFFF in the high-memory allocation map.  The use of said map is
  strictly for bounds checking of ACU installed options.

  The status returned is 0 if the range CANNOT be reserved, 1 otherwise.

=============================================================================
*/
int Lock_himem_range(   long address,       /* Start address */
                        unsigned size )     /* Length of region in KB */
{
    int     i,
            index,
            base_index;

    if(address < 0xA0000)
        return(0);
/*
    The range is currently free.  Mark it as allocated.
*/
    index = base_index = (address - 0xA0000) / 0x400;
    for(i=0; i<size; ++i)
        ++himem_map[index++];       /* Mark in use */

    return(1);                      /* Return success */
}
/*
=============================================================================
Function "Unlock_himem_range"

  This function releases the section of high-memory allocated so another
  option may use the area.

  The status returned is 0 for invalid address, or 1 otherwise.

=============================================================================
*/
int Unlock_himem_range( long address,       /* Start address */
                        unsigned size)      /* Length of region in KB */
{
    int     i,
            index;
/*
    Simply free all entries in the specified range.
*/
    if(address < 0xA0000)
        return(0);

    index = (address - 0xA0000) / 0x400;
    for(i=0; i<size; ++i)
        --himem_map[index++];         /* Free the entry */

    return(1);
}
/*
=============================================================================
Function "Check_himem_range"

  This function is called by a routine that wants to check to see if a
  region of high memory has anyone mapped to it.

  Return status:  1 = Memory region is FREE.  0 = Memory region not free.

=============================================================================
*/
int Check_himem_range(  long address,       /* Start address */
                        unsigned size)      /* Length of region in KB */
{
    int     i,
            index,
            base_index;
/*
    First, check the himem map to see if the requested range
    of memory addresses is free.
*/
    if(address < 0xA0000)
        return(0);

    index = base_index = (address - 0xA0000) / 0x400;
    for(i=0; i<size; ++i) {
        if(himem_map[index++] != 0)
            return(0);              /* Can't give you the requested range */
    }

    return(1);                      /* Range is Free. Return success */
}
/*
=============================================================================
Function "Lock_port_range"

  This routine allocates ranges of I/O addresses to options requesting it.
  Status returned:  1 = Requested range locked for your use.  0 = unavailable.

=============================================================================
*/
int Lock_port_range(    unsigned address,       /* Start I/O address */
                        unsigned size )         /* Range in bytes */
{
    int     i,
            index;

    if(address > 0x3FF)
        return(0);

    index = address;
    for(i=0; i<size; ++i)
        ++port_map[index++];
    return(1);
}
/*
=============================================================================
Function "Unlock_port_range"

  This function frees the section of the I/O address map previously
  reserved with "Lock_port_range".

    Status returned:  1 = Region freed.  0 = Address error.

=============================================================================
*/
int Unlock_port_range(  unsigned address,       /* Start I/O address */
                        unsigned size)          /* Range in bytes */
{
    if(address > 0x3FF)
        return(0);

    while(size--)
        --port_map[address++];

    return(1);
}
/*
=============================================================================
Function "Check_port_range"

  This function checks the availability of a specified I/O port address
  range.  Status returned:  1 = available,  0 = Not available.

=============================================================================
*/
int Check_port_range(unsigned address, unsigned size)
{
    int     i,
            index;
/*
    First, determine if there are any entries allocated in the
    requested range.
*/
    if(address > 0x3FF)
        return(0);

    index = address;
    for(i=0; i<size; ++i) {
        if(port_map[index++] != 0)
            return(0);                  /* Can't give you the range */
    }

    return(1);              /* Return success.  Range available */
}
/*
=============================================================================
Function "Build_address_map"

    Called at initialization time, this routine constructs a map of
    memory and I/O address usage by the currently installed options
    so bounds checking may be enforced using the above routines.

=============================================================================
*/
Build_address_map()
{
    extern unsigned char    EMS_installed,
                            VNA_installed,
                            IONA_installed[],
                            ramdisk_installed,
                            serial_installed,
                            serial_options;

    extern unsigned     VNA_ports[];

    extern int      vtype,
                    vdt_type;

    extern long     EMS_page_frame,
                    FREEMEM_list[][2],
                    ramdisk_page_frame;

    extern struct SERIAL_PARMS  serial_list[];  /* Serial port drivers */
    extern struct IONA_PARMS    IONA_list[];

    int     i,
            j;

    unsigned    memory_size;
/*
    Initialize the memory and I/O address maps.
*/
    zap(himem_map, 384, 0);
    zap(port_map, 1024, 0);
/*
    The following addresses are RESERVED.  None of the drivers
    should use them.
*/
    Lock_port_range(0x1F0, 1);
    Lock_port_range(0x270, 1);
    Lock_port_range(0x2F0, 1);
    Lock_port_range(0x300, 1);
    Lock_port_range(0x370, 1);
    Lock_port_range(0x3B0, 1);
    Lock_port_range(0x3C0, 1);
    Lock_port_range(0x3D0, 1);
    Lock_port_range(0x3F0, 1);
/*
    Lock out addresses taken up by the serial port driver.
*/
    if(serial_installed) {
        if(serial_options) {
            for(i=0; i<24; ++i) {
                if(serial_list[i].sp_address != 0)
                    Lock_port_range(serial_list[i].sp_address, 8);
            }
        }
        else {
            Lock_port_range(0x3F8, 8);
            Lock_port_range(0x2F8, 8);
        }
    }
/*
    Lock out addresses taken up by the VNA driver.
*/
    if(VNA_installed) {
        for(i=0; i<4; ++i) {        /* For each VNA board */
            if(VNA_ports[i] != 0) {
                Lock_port_range(VNA_ports[i], 0x10);
                if(IONA_installed[i]) {
                    if(IONA_list[i].pp_address != 0)
                        Lock_port_range(IONA_list[i].pp_address, 4);
                    for(j=0; j<4; ++j) {    /* For each serial port on IONA */
                        if(IONA_list[i].sp_AD[j] != 0)
                            Lock_port_range(IONA_list[i].sp_AD[j], 8);

                    }
                }
            }
        }
    }
/*
    Lock out memory addresses taken by FREEMEM.
*/
    for(i=0; i<5; ++i) {
        if(FREEMEM_list[i][0] != 0) {
            memory_size = (FREEMEM_list[i][1] - FREEMEM_list[i][0]) / 1024;
            Lock_himem_range(FREEMEM_list[i][0], memory_size);
        }
    }
/*
    Lock out memory addresses taken by VTYPE.
*/
    switch(vtype) {
        case 1:
        case 2:
            Lock_himem_range(0xA0000, 64);      /* 64K range locked */
            break;
        case 3:
            Lock_himem_range(0xA0000, 80);
            break;
        case 4:
            Lock_himem_range(0xA0000, 96);
            break;
        case 5:
            Lock_himem_range(0xA0000, 64);
    }
/*
    Lock a 64K range for the EMS driver.
*/
    if(EMS_installed)
        Lock_himem_range(EMS_page_frame, 64);
/*
    Lock a 16K range for the RAMdisk.
*/
    if(ramdisk_installed)
        Lock_himem_range(ramdisk_page_frame, 16);
/*
    Done.
*/
}
