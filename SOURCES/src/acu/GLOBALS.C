/*
*****************************************************************************
*
*   MODULE NAME:    globals
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Configuration Utility
*
*   CREATION DATE:  4-May-90
*
*   REVISION DATE:  4-May-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Global Variables
*
*
*               (C) Copyright 1990, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*                           >> REVISION LOG <<
*
* DATE      PROG        DESCRIPTION OF REVISION
* ----      ----        -----------------------
* 5/20/92   RSR         Mods for MOS 5.01 and updat501.sys
*****************************************************************************
*
*/
#include "acu.h"
/*
    System Configuration stuff.
*/
int             machine_type;           /* Type of processor in machine */
int             max_IRQ;                /* Highest IRQ level */
unsigned char   coproc_present;         /* Coprocessor resident? */

int             ext_mem_free,           /* Amount of free extended memory */
                ext_mem_size,           /* Total amount of extended memory */
                ext_mem_used,           /* Amount of extended memory used */
                base_mem_size,          /* Base memory size */
                total_mem_size;         /* Sum of Base and Extended */
/*
    Modifyable data.
*/
char            *memdev_list[] = {  "NONE", "$286N.SYS", "$GIZMO.SYS",
                                    "$CHARGE.SYS", "$386.SYS", "" };

unsigned char   memdev_installed = 0;   /* Set if NOT NONE or $286N.SYS */
char            memdev_driver[13];      /* Name of memory mgmt driver */
char            memdev_opt[3];          /* Option on MEMDEV driver */

unsigned char   share_coproc = 0;       /* 1 = Yes, 0 = No */
/*
    Disk caching stuff.
*/
int             cache_size;             /* In KB */
unsigned        cache_unit;             /* Cache piece size */
unsigned        first_write;            /* Seconds to hold in cache */
unsigned        last_write;             /* Time since last write */
char            cache_list[27];         /* List of drives cached */

int             country_code;           /* Country code. USA=1 */
char            country_name[21];       /* Name of country */
unsigned char   desnow;                 /* 1 = Yes, 2 = No */
unsigned char   auto_freemem;           /* 1 = Build freemem, 0 = don't */
int             time_slice;             /* Time slice for tasks */
/*
    Video state.
*/
int             vdt_type;               /* Installed video type */
int             vtype;                  /* VTYPE setting */
unsigned char   maximize_vtype;         /* 1 = add 'F', 0 = don't */

int             max_tasks;              /* Max tasks expected to run */
int             base_SMP;               /* Base amount read-in */
int             add_SMP;                /* Additional K to SMP */
int             total_SMP;              /* Size to allocate to SMP */
int             MOS5;                   /* For Updat501.sys */
int             PATCH410;               /* for patch410.sys */

/*
    EMS driver info.
*/
unsigned char   EMS_installed = 0;      /* EMS driver installed */
int             EMS_buffer_size = 0;    /* EMS buffer space. */
long            EMS_page_frame = 0;     /* Page frame */
/*
    Serial driver info.
*/
unsigned char       serial_installed = 0;   /* 0=NO, 1=YES */
unsigned char       serial_options = 0;     /* 0=NO, 1=YES */
struct SERIAL_PARMS serial_list[24];        /* Parameters for each port */
/*
    Mouse driver info.
*/
unsigned char   mouse_installed = 0;    /* Mouse driver installed */
/*
    Pipe driver info.
*/
int             pipe_count = 0;         /* Number of pipes installed */
int             pipe_index = 0;         /* Index into pipe list */
unsigned char   pipe_installed[25];     /* Pipe driver installed */
char            *pipe_names[26];         /* Up to 25 pipe names, last NULL */
unsigned        pipe_buf_size[25];
unsigned char   pipe_EOF_mode[25];
/*
    RAMdisk parameters.
*/
unsigned char   ramdisk_installed = 0;      /* Ramdisk driver installed */
int             ramdisk_buffer_size = 0;    /* Size, in KB of drive */
long            ramdisk_page_frame = 0xB4000;   /* Paging area */
/*
    Keyboard driver.
*/
unsigned char   kb_installed = 0;       /* Keyboard driver installed */
char            kb_code[] = "US";       /* Keyboard name */
/*
    VNA driver info.
*/
unsigned char       VNA_installed = 0;      /* VNA driver installed */
unsigned            VNA_ports[4];           /* VNA port addresses */
unsigned            VNA_int[4];             /* VNA interrupt levels */
unsigned char       IONA_installed[4];      /* IONA installed this VNA? */
struct IONA_PARMS   IONA_list[4];           /* One for each VNA board */
/*
    Other Globals.
*/
char            source_file[65];        /* File to be configured */
char            backup_file[65];        /* Renamed source file */
unsigned char   CONFIG_changed;         /* Changes made? */
unsigned char   diags_active;           /* In diagnostic mode? */

char    *country_names[] =  {   "United States",
                                "Australia",
                                "Belgium",
                                "Canada",
                                "Denmark",
                                "Finland",
                                "France",
                                "Germany",
                                "Italy",
                                "Israel",
                                "Middle East",
                                "Netherlands",
                                "Norway",
                                "Portugal",
                                "Spain",
                                "Sweden",
                                "Switzerland",
                                "United Kingdom",
                                "" };

int     country_codes[] =   {1, 61, 32, 2, 45, 358, 33, 49, 39, 972,
                             785, 81, 47, 351, 34, 46, 41, 44, 0};

unsigned char   old_config_allocated = 0;
char            *old_config_text[100];      /* For holding old CONFIG.SYS */

long   FREEMEM_list[5][2] = {   0, 0,   /* Up to 5 FREEMEM segments */
                                0, 0,
                                0, 0,
                                0, 0,
                                0, 0 };
/*
    Dialog box stuff.
*/
char    *prompt_lines[20];      /* I/O lines */
int     prompt_cpos[20];        /* Cursor positions of input fields */
int     fmap[20][2];            /* Type and length of input fields */
/*
    Installation stuff.
*/
char            max_target_drive = 'C'; /* Max drive to work with */
char            target_drive = 'C';     /* Drive to place system files */
char            system_path[65];        /* Where all drivers are */
