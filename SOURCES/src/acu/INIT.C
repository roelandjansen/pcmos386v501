/*
*****************************************************************************
*
*   MODULE NAME:    Initialize
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  5/4/90
*
*   REVISION DATE:  8/17/90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Initialization of global data
*
*
*               (C) Copyright 1990, The Software Link, Inc.
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
* 8/17/90   BWR         Default directory now PCMOS instead of PC-MOS
*                       to conform with INSTALL.EXE
*
*****************************************************************************
*
*/
#define ALPHA   "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

#include <dos.h>
#include <stdlib.h>
#include <malloc.h>
#include "acu.h"

Initialize(int argc, char **argv)
{
    extern unsigned char    diags_active,
                            auto_freemem,
                            VNA_installed,
                            maximize_vtype,
                            coproc_present,
                            pipe_EOF_mode[],
                            IONA_installed[],
                            pipe_installed[],
                            memdev_installed;

    extern char     memdev_driver[],
                    *pipe_names[],
                    target_drive,
                    max_target_drive,
                    cache_list[],
                    memdev_opt[],
                    system_path[],
                    country_name[],
                    *country_names[];


    extern unsigned     VNA_int[],
                        cache_unit,
                        last_write,
                        VNA_ports[],
                        first_write,
                        pipe_buf_size[];

    extern int      vtype,
                    add_SMP,
                    max_IRQ,
                    base_SMP,
                    vdt_type,
                    max_tasks,
                    total_SMP,
                    cache_size,
                    time_slice,
                    pipe_count,
                    pipe_index,
                    ext_mem_free,
                    ext_mem_size,
                    ext_mem_used,
                    country_code,
                    machine_type,
                    base_mem_size,
                    total_mem_size,
                    country_codes[],
                    EMS_buffer_size;

    extern long     FREEMEM_list[][2];

    extern struct SERIAL_PARMS  serial_list[];
    extern struct IONA_PARMS    IONA_list[];

    unsigned        freemem_segs[5][2];

    char            filename[65],
                    pathname[65];

    int             i,
                    j,
                    attrib,
                    drive_count;

    union REGS      inregs, outregs;
/*
    Redirect Int 24 to a local routine.
*/
    setup_i24();
/*
    Did user specify diagnostic mode?
*/
    if(argc > 1 && !strcmpi(argv[1], "/D"))
        diags_active = 1;
    else
        diags_active = 0;
/*
    Find out which hard drives in the system are available.
*/
    drive_count = 0;
    for(i=3; i<=26; ++i) {
        inregs.x.ax = 0x4409;       /* IOCTL block device Local or Remote? */
        inregs.h.bl = i;
        intdos(&inregs, &outregs);
        if(outregs.x.cflag != 0)
            break;
        if(outregs.x.dx & 0x1000)   /* Network drive? */
            break;
        drive_count++;              /* Another available drive */
    }
    max_target_drive = 'C' + drive_count - 1;
/*
    Compute a likely target drive based on the first hard drive that has
    $$MOS.SYS located on it.
*/
    target_drive = 'C';
    for(i=0; i<drive_count; ++i) {
        sprintf(filename, "%c:\\$$MOS.SYS", ('C'+i));
        if(access(filename, 0) == 0) {
            target_drive = 'C' + i;
            break;
        }
    }
/*
    Initialize serial port list for $SERIAL.SYS.
*/
    for(i=0; i<24; ++i) {
        zap(serial_list[i], sizeof(struct SERIAL_PARMS), 0);
        serial_list[i].sp_IB = 64;
        serial_list[i].sp_OB = 16;
        serial_list[i].sp_HS = 'P';
        serial_list[i].sp_CN = 'L';
    }
/*
    Initialize PIPE stuff.
*/
    pipe_index = 0;
    pipe_count = 0;

    for(i=0; i<25; ++i) {
        pipe_installed[i] = 0;
        pipe_names[i] = malloc(9);
        sprintf(pipe_names[i], "PIPE%d", i+1);
        pipe_buf_size[i] = 64;
        pipe_EOF_mode[i] = 0;
    }
    pipe_names[25] = malloc(9);
    pipe_names[25][0] = '\0';        /* End of list */
/*
    Initialize VNA and IONA stuff.
*/
    VNA_installed = 0;
    for(i=0; i<4; ++i) {
        VNA_ports[i] = 0;
        VNA_int[i] = 0;
        IONA_installed[i] = 0;
        IONA_list[i].pp_mode = 'N';     /* For NON-Banked */
        IONA_list[i].pp_address = 0;
        IONA_list[i].int_level = 0;
        for(j=0; j<4; ++j) {
            IONA_list[i].sp_AD[j] = 0;
            IONA_list[i].sp_IB[j] = 16;
            IONA_list[i].sp_OB[j] = 16;
            IONA_list[i].sp_HS[j] = 'P';
            IONA_list[i].sp_CN[j] = 'L';
            IONA_list[i].sp_MS[j] = 0;
        }
    }
/*
    First get the base system configuration.
*/
    machine_type = CPU_type();

    if(machine_type < 2)                /* Get CPU configuration */
        max_IRQ = 7;
    else
        max_IRQ = 15;

    int86(0x11, &inregs, &outregs);
    if(outregs.x.ax & 0x0002)
        coproc_present = 1;
    else
        coproc_present = 0;

    if(machine_type >= 2) {                 /* For AT & above, get Extended */
        base_mem_size = CMOS_base_memsize();
        ext_mem_size = CMOS_ext_memsize();
    }
    else {
        int86(0x12, &inregs, &outregs);
        base_mem_size = outregs.x.ax;
        ext_mem_size = 0;
    }
    ext_mem_used = 0;                       /* Initially none used */
    ext_mem_free = ext_mem_size;            /* Initially all free */

    total_mem_size = base_mem_size + ext_mem_size;
/*
    Initialize CONFIG.SYS options before reading the file for it's
    overrides.
*/
    switch(machine_type) {
        case 0:
        case 1:
            strcpy(memdev_driver, "NONE");
            break;
        case 2:
            strcpy(memdev_driver, "$286N.SYS");
            break;
        case 3:
        case 4:
            strcpy(memdev_driver, "$386.SYS");
            break;
    }

    if(!strcmpi(memdev_driver, "NONE") || !strcmpi(memdev_driver, "$286N.SYS"))
        memdev_installed = 0;
    else
        memdev_installed = 1;

    strcpy(memdev_opt, "NO");       /* No memdev options */
    strcpy(cache_list, "C");        /* Default to drive C cache */
    cache_size = 64;                /* Default size is 64K */
    cache_unit = 2;                 /* Default unit size is 2K */
    first_write = 0;                /* Default is OFF */
    last_write = 0;                 /* Default is OFF */
    country_code = 1;               /* US */
    strcpy(country_name, "United States");      /* US */
    auto_freemem = 0;               /* FREEMEM NONE unless specified */
/*
    Calculate FREEMEM segments, then convert to absolute addresses.
    If user puts in manual mode, these will have already been
    calculated for him.
*/
/*
ÚÄÄÄÄÄÄÄÄÄÄ Function get_freemem is not reliable, removed for now. ÄÄÄÄÄÄÄÄÄ¿
³   get_freemem(freemem_segs);                                              ³
³   for(i=0; i<5; ++i) {                                                    ³
³       FREEMEM_list[i][0] = (long) freemem_segs[i][0] << 4;                ³
³       FREEMEM_list[i][1] = (long) freemem_segs[i][1] << 4;                ³
³   }                                                                       ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/
    time_slice = 1;                 /* Time slice defaults to 1/18 sec */
    vdt_type = get_video_type();    /* What display are we on? */
    vtype = 0;                      /* Default NO VTYPE */
    maximize_vtype = 0;             /* Default NO 'F' on VTYPE */
    max_tasks = 1;                  /* Default to 1 task in system */
    strcpy(system_path, "C:\\PCMOS");  /* Location of system files */
	base_SMP = 16;
	add_SMP = 0;
    total_SMP = 16;
/*
    Find the first drive containing $$MOS.SYS.  Set this as the
    system drive.
*/
    for(i=2; i<26; ++i) {
        sprintf(pathname, "%c:\\$$MOS.SYS", ALPHA[i]);
        if(access(pathname, 0) == 0) {
            sprintf(system_path, "%c:\\PCMOS", ALPHA[i]);
            break;
        }
    }
/*
    Build memory and I/O map.  Also calculate present memory usage.
*/
    Build_address_map();
    Calculate_memory_usage();
    return(1);
}
