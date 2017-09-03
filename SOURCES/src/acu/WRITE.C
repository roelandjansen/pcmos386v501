/*
*****************************************************************************
*
*   MODULE NAME:    Write_configuration
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Auto Configuration Utility
*
*   CREATION DATE:  14-May-90
*
*   REVISION DATE:  14-May-90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Writes the new configuration file.
*
*
*               (C) Copyright 1990, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Write_configuration();
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
* 9/26/91   RSR         Modification for EMS 4.0 driver
* 5/20/92   RSR         Mos for MOS 5.01 and updat501.sys
*****************************************************************************
*
*/
#define PRESS_KEY   ">> Press ANY key to continue <<"

#include <stdio.h>
#include <rsa\rsa.h>
#include <rsa\stdusr.h>
#include "acu.h"

Write_configuration()
{
    extern unsigned char    desnow,
                            kb_installed,
                            share_coproc,
                            auto_freemem,
                            share_coproc,
                            EMS_installed,
                            VNA_installed,
                            serial_options,
                            pipe_EOF_mode[],
                            pipe_installed[],
                            IONA_installed[],
                            maximize_vtype,
                            mouse_installed,
                            maximize_freemem,
                            serial_installed,
                            ramdisk_installed;

    extern char     memdev_driver[],
                    kb_code[],
                    cache_list[],
                    memdev_opt[],
                    *pipe_names[],
                    system_path[],
                    source_file[],
                    backup_file[],
                    country_name[],
                    *old_config_text[];


    extern unsigned     VNA_int[],
                        cache_unit,
                        last_write,
                        VNA_ports[],
                        first_write,
                        pipe_buf_size[];

    extern int      vtype,
                    total_SMP,
                    max_tasks,
                    cache_size,
                    country_code,
                    EMS_buffer_size,
                    ramdisk_buffer_size,
                    MOS5,
                    PATCH410;

    extern long     EMS_page_frame,
                    FREEMEM_list[][2],
                    ramdisk_page_frame;

    extern struct SERIAL_PARMS  serial_list[];
    extern struct IONA_PARMS    IONA_list[];

    int     i,
            j,
            index,
            time_buf[7];

    char    *cptr,
            buffer[81],
            *msg_list[11];

    FILE    *fp;
/*
    Rename the source file to a backup name, and write to the
    original file.
*/
    remove(backup_file);
    rename(source_file, backup_file);

    fp = fopen(source_file, "w");       /* Create new version */
/*
    Write a header in the new CONFIG.SYS file.
*/
    gtime(time_buf);
    fprintf(fp, ";+");
    ffill(fp, '+', 77);
    fprintf(fp, "\n");
    fprintf(fp, ";+ This configuration file created by TSL Auto ");
    fprintf(fp, "Configuration Utility.\n");
    fprintf(fp, ";+ Do NOT remove or modify this file heading.\n");
    fprintf(fp, ";+ Built: %2d/%02d/%02d @ %2d:%02d:%02d\n;+\n", time_buf[1],
        time_buf[2], time_buf[0] % 100, time_buf[3], time_buf[4],
        time_buf[5]);
    fprintf(fp, ";+ CONFIG-INFO: MAX-TASKS=%d\n", max_tasks);
    fprintf(fp, ";+ CONFIG-INFO: SYSPATH=%s\n", system_path);
    fprintf(fp, ";+");
    ffill(fp, '+', 77);
    fprintf(fp, "\n");
/*
    Begin writing configuration information.
*/
    if(strcmpi(memdev_driver, "NONE") != 0) {
        if(strcmpi(memdev_opt, "NO") != 0)
            fprintf(fp, "MEMDEV=%s\\%s %s\n", system_path, memdev_driver, memdev_opt);
        else
            fprintf(fp, "MEMDEV=%s\\%s\n", system_path, memdev_driver);
    }
/*
   Update501.sys

*/ 
     fprintf(fp, "device=%s\\UPDAT501.SYS\n", system_path);
    
/*
    VTYPE.
*/
    if(vtype != 0) {
        if(maximize_vtype)
            fprintf(fp, "VTYPE=%dF\n", vtype);
        else
            fprintf(fp, "VTYPE=%d\n", vtype);
    }
/*
    FREEMEM.
*/
    switch(auto_freemem) {
        case 0:
            fprintf(fp, "FREEMEM=NONE\n");
            break;
        case 2:
            for(i=0; i<5; ++i) {
                if(FREEMEM_list[i][0] != 0)
                    fprintf(fp, "FREEMEM=%lX,%lX\n",
                                 FREEMEM_list[i][0], FREEMEM_list[i][1]);
            }
    }
/*
    CACHE.
*/
    if(strcmpi(cache_list, "ALL") == 0)
        fprintf(fp, "CACHE=%d,%d,%d,%d\n", cache_size, cache_unit,
            first_write, last_write);
    else {
        fprintf(fp, "CACHE=%d,%d,%d,%d", cache_size, cache_unit,
            first_write, last_write);
        squeeze(cache_list, ',');
        cptr = cache_list;
        while(*cptr)
            fprintf(fp, ",%c", *cptr++);
        fprintf(fp, "\n");
    }
/*
    8087=YES.
*/
    if(share_coproc)
        fprintf(fp, "8087=YES\n");
/*
    Write SMP size.
*/
    Calculate_SMPSIZE();
    fprintf(fp, "SMPSIZE=%d\n", total_SMP);
/*
    COUNTRY.
*/
    if(country_code != 1)
        fprintf(fp, "COUNTRY=%d  ;(%s)\n", country_code, country_name);
/*
    $EMS.SYS

    if(EMS_installed && EMS_buffer_size != 0)
        fprintf(fp, "DEVICE=%s\\$EMS.SYS %dK, %05lX\n", system_path,
                EMS_buffer_size, EMS_page_frame);
*/

    if(EMS_installed)
        fprintf(fp, "DEVICE=%s\\$EMS.SYS %05lX\n", system_path,
                EMS_page_frame);

/*
    $SERIAL.SYS
*/
    if(serial_installed && !serial_options)
        fprintf(fp, "DEVICE=%s\\$SERIAL.SYS\n", system_path);
/*
    Write out option list on $SERIAL.SYS
*/
    else if(serial_installed && serial_options) {
        fprintf(fp, "DEVICE=%s\\$SERIAL.SYS ", system_path);
        for(i=0; i<24; ++i) {
            if(serial_list[i].sp_address == 0)
                continue;
/*
    Write out the options for each port.
*/
            fprintf(fp, " ~\n/AD=%04X", serial_list[i].sp_address);
            fprintf(fp, ", IB=%u", serial_list[i].sp_IB);
            fprintf(fp, ", OB=%u", serial_list[i].sp_OB);
            fprintf(fp, ", HS=%c", serial_list[i].sp_HS);
            if(serial_list[i].sp_IN != 0)
                fprintf(fp, ", IN=%d", serial_list[i].sp_IN);
            if(serial_list[i].sp_CN != 'N')
                fprintf(fp, ", CN=%c", serial_list[i].sp_CN);
        }
        fprintf(fp, "\n");
    }
/*
    $MOUSE.SYS.
*/
    if(mouse_installed)
        fprintf(fp, "DEVICE=%s\\$MOUSE.SYS\n", system_path);
/*
    $PIPE.SYS.
*/
    for(i=0; i<25; ++i) {
        if(pipe_installed[i]) {
            fprintf(fp, "DEVICE=%s\\$PIPE.SYS %s", system_path, pipe_names[i]);
            if(pipe_buf_size[i] != 64)
                fprintf(fp, ", %d", pipe_buf_size[i]);
            if(pipe_EOF_mode[i])
                fprintf(fp, " /N");

            fprintf(fp, "\n");
        }
    }
/*
    $RAMDISK.SYS
*/
    if(ramdisk_installed) {
        if(ramdisk_page_frame != 0xB4000)
            fprintf(fp, "DEVICE=%s\\$RAMDISK.SYS %dK, %lX\n", system_path,
                ramdisk_buffer_size, ramdisk_page_frame);
        else
            fprintf(fp, "DEVICE=%s\\$RAMDISK.SYS %dK\n", system_path,
                ramdisk_buffer_size);
    }
/*
    Keyboard driver.
*/
    if(kb_installed)
        fprintf(fp, "DEVICE=%s\\$KB%s.SYS\n", system_path, kb_code);
/*
    VNA driver.
*/
    if(VNA_installed) {
        fprintf(fp, "DEVICE=%s\\VNA.SYS ", system_path);

        for(i=0; i<4; ++i) {            /* For each VNA board */
            if(VNA_ports[i] != 0) {     /* VNA installed ? */
                fprintf(fp, " /%X, %d", VNA_ports[i], VNA_int[i]);
                if(IONA_installed[i]) {     /* IONA installed this VNA? */
                    fprintf(fp, ", %X", IONA_list[i].pp_address);
                    fprintf(fp, ", B");     /* Banked mode parallel */
                    fprintf(fp, ", %X", IONA_list[i].sp_AD[0]);
                    fprintf(fp, ", %d ", IONA_list[i].int_level);
                    fprintf(fp, "~\n/AD=%X, IB=%d, OB=%d, HS=%c, CN=%c",
                        IONA_list[i].sp_AD[0], IONA_list[i].sp_IB[0],
                        IONA_list[i].sp_OB[0], IONA_list[i].sp_HS[0],
                        IONA_list[i].sp_CN[0]);
                    fprintf(fp, " /MS=");
                    for(j=0; j<4; ++j) {
                        if(IONA_list[i].sp_MS[j])
                            fprintf(fp, "Y");
                        else
                            fprintf(fp, "N");
                    }
                }
            }
        }
        fprintf(fp, "\n");
    }
/*
    Write out the lines we didn't modify.
*/
    for(index=0; index<100; ++index) {
        if(strlen(old_config_text[index]) == 0)
            break;
        fprintf(fp, "%s\n", old_config_text[index]);
    }
/*
    Close the configuration file and return to caller.
*/
    fclose(fp);

    msg_list[0] = "Save Complete.  System options";
    msg_list[1] = "have been written to the file";
    sprintf(buffer,"\"%s\".", source_file);
    msg_list[2] = buffer;
    msg_list[3] = " ";
    msg_list[4] = PRESS_KEY;
    msg_list[5] = "";
    USR_message(0, msg_list, NOTE, 0, PAUSE_FOR_KEY);
}
