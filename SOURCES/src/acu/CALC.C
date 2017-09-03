/*
*****************************************************************************
*
*   MODULE NAME:    Calculate_SMPSIZE
*                   Calculate_memory_usage
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  16-May-90
*
*   REVISION DATE:  16-May-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Calculates the current size of the SMP from
*                   current parameters, IF the SMP size hasn't been
*                   read in from the configuration file.
*
*
*               (C) Copyright 1990, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Calculate_SMPSIZE();
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
Calculate_SMPSIZE()
{
    extern int          add_SMP,
                        base_SMP,
                        total_SMP,
                        max_tasks;

    base_SMP = 32 + (max_tasks * 5);
    total_SMP = base_SMP + add_SMP;
}

Calculate_memory_usage()
{
    extern int          cache_size,
                        ext_mem_free,
                        ext_mem_size,
                        ext_mem_used,
                        EMS_buffer_size,
                        ramdisk_buffer_size;
/*
    Only perform the usage calculation if extended memory
    exists.
*/
    if(ext_mem_size != 0) {
        ext_mem_used = cache_size + EMS_buffer_size + ramdisk_buffer_size;
        ext_mem_free = ext_mem_size - ext_mem_used;
    }
}
