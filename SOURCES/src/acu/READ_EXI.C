/*
*****************************************************************************
*
*   MODULE NAME:    Read_existing_options
*
*   TASK NAME:      ACU.EXE
*
*   PROJECT:        PC-MOS Configuration Utility
*
*   CREATION DATE:  5/7/90
*
*   REVISION DATE:  5/7/90
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Opens the specified CONFIG.SYS file and reads any
*                   MOS recognizable options from it to obtain system
*                   configuration information.
*
*
*               (C) Copyright 1990, The Software Link, Inc.
*                       All Rights Reserved
*
*****************************************************************************
*
*   USAGE:      Read_existing_options();
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
* 5/20/92   RSR         Mods for Mos 5.01 and updat501.sys
*****************************************************************************
*
*/
#define FOREVER while(1)

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <malloc.h>
#include <rsa\rsa.h>
#include "acu.h"

#define TILDE   '~'

Read_existing_options()
{
	extern unsigned char	desnow,
                            kb_installed,
                            share_coproc,
                            auto_freemem,
                            EMS_installed,
                            VNA_installed,
                            serial_options,
							CONFIG_changed,
                            maximize_vtype,
                            pipe_EOF_mode[],
                            IONA_installed[],
                            pipe_installed[],
                            mouse_installed,
                            serial_installed,
                            ramdisk_installed,
                            old_config_allocated;

    extern char     memdev_driver[],
                    kb_code[],
                    memdev_opt[],
                    cache_list[],
                    *pipe_names[],
					source_file[],
                    system_path[],
                    country_name[],
					*country_names[],
					*old_config_text[];

    extern unsigned         VNA_int[],
                            cache_unit,
                            last_write,
                            first_write,
                            VNA_ports[],
                            pipe_buf_size[];

	extern int				vtype,
							add_SMP,
							base_SMP,
                            vdt_type,
                            max_tasks,
							total_SMP,
                            pipe_count,
                            cache_size,
							country_code,
                            country_codes[],
                            EMS_buffer_size,
                            ramdisk_buffer_size,
                            MOS5,
                            PATCH410;

	extern long 	EMS_page_frame,
                    FREEMEM_list[][2],
                    ramdisk_page_frame;

    extern struct SERIAL_PARMS  serial_list[];
    extern struct IONA_PARMS    IONA_list[];

    FILE    *fp_source;             /* For reading source file */

    unsigned char   syspath_found = 0;

    char    *cptr,
            *cptr2,
            ext[5],
            dir[65],
            drive[3],
            fname[9],
            *cptr_max,
            *long_line,             /* Use for parsing LONG command lines */
            buffer[134],
            *split_buf[4],          /* Use for splitting lines apart */
            orig_buffer[134];

    int     i,
            j,
            k,
            len,
            i2temp,
            freemem_index = 0,      /* For storing FREEMEM statements */
            max_serial_ports = 0,   /* Set when searching $$SERIAL.SYS line */
            stored_line_index = 0;  /* For storing unknown CONFIG lines */
/*
    Initialization.
*/
    for(i=0; i<4; ++i) {
        split_buf[i] = 0;           /* Init null pointers */
    }
/*
    Allocate memory to hold the old CONFIG.SYS file (the parts we don't
    know) in memory.
*/
    if(!old_config_allocated) {
        for(i=0; i<100; ++i) {
            old_config_text[i] = calloc(1, 81);
            if(!old_config_text[i]) {
                puts("Out of memory allocating CONFIG buffer.");
                return(0);
            }
        }
        old_config_allocated = 1;
    }
/*
    Consider the file "changed" if it hasn't been run through the
    program yet.  This will be cleared if the "CONFIG-INFO" line
    is discovered.
*/
    CONFIG_changed = 1;
    fp_source = fopen(source_file, "r");

	if(!fp_source)
		return(0);		/* A new file will be created */
/*
    Read each line of the configuration file.  Check each line for
    a keyword that is recognizable by MOS and process the line.  If
    the line is not recognized, just copy it to the target file
    unmodified.
*/
    while(get_line(buffer, 133, fp_source)) {
/*
    Handle ;MAX-TASKS parameter.
*/
        if(strstri(buffer, "CONFIG-INFO:")) {
            CONFIG_changed = 0;
            cptr = strstri(buffer, "MAX-TASKS=");
            if(cptr)
                max_tasks = atoi(&cptr[10]);

            cptr = strstri(buffer, "SYSPATH=");
            if(cptr) {
                strcpy(system_path, &cptr[8]);
                syspath_found = 1;
            }

            continue;
        }
/*
    Strip old comment lines put out by this program.
*/
        if(strnicmp(buffer, ";+", 2) == 0)
            continue;
/*
    Keep comments placed by anyone else.
*/
        if(buffer[0] == ';') {                  /* Pass comment lines */
            strcpy(old_config_text[stored_line_index++], buffer);
            continue;
        }

        strcpy(orig_buffer, buffer);            /* Keep original copy */
        squeeze(buffer, ' ');                   /* Remove whitespace */
/*
    Filter all recognizable options.
*/
        if(strnicmp(buffer, "8087=YES" ,8) == 0)
            share_coproc = 1;

/*
    Handle the CACHE statement.
*/
        else if(strnicmp(buffer,"CACHE=",6) == 0) {
            cptr = &buffer[6];

            cache_size = atoi(cptr);            /* Get the cache size */
            if(cache_size <= 0)
                cache_size = 16;
            if(!(cptr = strchr(cptr, ',')))
                continue;
            cptr++;

            cache_unit = atoi(cptr);          /* Get the unit size */
            if(cache_unit <= 0)
                cache_unit = 2;
            if(!(cptr = strchr(cptr, ',')))
                continue;
            cptr++;

            first_write = atoi(cptr);           /* FIRSTW time */
            if(first_write <= 0)
                first_write = 0;
            if(!(cptr = strchr(cptr, ',')))
                continue;
            cptr++;

            last_write = atoi(cptr);            /* LASTW time */
            if(last_write <= 0)
                last_write = 0;
            if(!(cptr = strchr(cptr, ',')))
                continue;
            cptr++;

            if(strlen(cptr)) {
                strcpy(cache_list, cptr);
                squeeze(cache_list, ',');       /* Remove commas */
            }
        }
/*
    Handle the COUNTRY statement.
*/
        else if(strnicmp(buffer, "COUNTRY=", 8) == 0) {
            strcpy(country_name, "* UNKNOWN *");
            country_code = atoi(&buffer[8]);
            for(i=0; country_codes[i] != 0; i++) {
                if(country_code == country_codes[i]) {
                    strcpy(country_name, country_names[i]);
                    break;
                }
            }
        }
/*
    Handle the DESNOW statement.
*/
        else if(strnicmp(buffer, "DESNOW=", 7) == 0) {
            if(strnicmp(&buffer[7], "YES", 3) == 0)
                desnow = 1;
            else
                desnow = 0;
        }
/*
    FREEMEM=NONE
*/
        else if(strcmpi(buffer, "FREEMEM=NONE") == 0)
            auto_freemem = 0;
/*
    FREEMEM= ????
*/
        else if(strnicmp(buffer, "FREEMEM=", 8) == 0) {
/*
    Read the FREEMEM segment specified on this line.
*/
            if(freemem_index <= 4) {
                sscanf(&buffer[8], "%lX,%lX", &FREEMEM_list[freemem_index][0],
                    &FREEMEM_list[freemem_index][1]);
                freemem_index++;
            }
            auto_freemem = 2;
        }
/*
    Handle the MEMDEV statement.  Pick up the system path here if
    not already specified on the "SYSPATH" special variable.
*/
        else if(strnicmp(buffer, "MEMDEV=", 7) == 0) {
/*
    Rake off the option on the MEMDEV statement if it is there.
*/
            cptr = strchr(buffer, '/');
            if(cptr) {
                strncpy(memdev_opt, cptr, 2);
                memdev_opt[2] = '\0';
                *cptr = '\0';           /* Remove the option */
                strupr(memdev_opt);
            }
            cptr = &buffer[7];
            _splitpath(cptr, drive, dir, fname, ext);
            sprintf(memdev_driver, "%s%s", fname, ext);
            strupr(memdev_driver);
/*
    When picking the system path off the MEMDEV statement, _splitpath
    will have left the trailing \ on it.  Take it off the end for
    display.  (When being used to construct filenames it is added
    back at that time).
*/
            if(!syspath_found) {
                sprintf(system_path, "%s%s", drive, dir);
                strupr(system_path);
                len=strlen(system_path);
                if(system_path[len-1] == '\\')
                    system_path[len-1] = '\0';
            }
        }
/*
    Handle the SMPSIZE statement.
*/
		else if(strnicmp(buffer, "SMPSIZE=", 8) == 0) {
            total_SMP = atoi(&buffer[8]);
			base_SMP = 16 + (max_tasks - 1) * 5;
			add_SMP = total_SMP - base_SMP;
			if(add_SMP < 0) {
				total_SMP = base_SMP;
				add_SMP = 0;
			}
		}
/*
    Handle the VTYPE statement.
*/
        else if(strnicmp(buffer, "VTYPE=", 6) == 0) {
            vtype = buffer[6] - '0';
            if(buffer[7] == 'F' || buffer[7] == 'f')
                maximize_vtype = 1;
            else
                maximize_vtype = 0;

            if(vdt_type < 2) {      /* If EGA or VGA, DON'T use VTYPE */
                vtype = 0;
                maximize_vtype = 0;
            }
        }
/*
    Process MOS device drivers.  First - $EMS.SYS
*/
        else if(strnicmp(buffer, "DEVICE=", 7) == 0) {
            if(strstri(buffer, "$EMS.SYS")) {
                cptr = strstri(buffer, "$EMS.SYS");
                cptr += 8;
                    EMS_page_frame = strtol(cptr, &cptr, 16);
                if(EMS_page_frame != 0)
                    EMS_installed = 1;
                else
                    EMS_installed = 0;
            }

/* ================== BEGIN $SERIAL.SYS processing ======================= */
/*
    Check for installation of $SERIAL.SYS.  If the driver is installed,
    but with no options, set the flag to indicate that fact.  If options
    WERE installed, then parse them out of the line, or lines so they
    may be modified and rewritten.
*/
            else if(strstri(buffer, "$SERIAL.SYS") != 0) {
/*
    Combine all continuation lines before checking for options.
*/
                serial_installed = 1;

                long_line = calloc(1, 2048);    /* Max 24 lines * 80 chars */
                if(!long_line) {
                    puts("ACU: Memory allocation error. (READ_EXI.C)\n");
                    exit(1);
                }
                strcpy(long_line, buffer);
/*
    Get any continuation lines.
*/
                while(strchr(buffer, TILDE) != 0) {
                    if(!get_line(buffer, 133, fp_source))
                        buffer[0] = '\0';
                    squeeze(buffer, ' ');
                    strcat(long_line, buffer);
                }

                squeeze(long_line, TILDE);
/*
    Are there any options on the line?
*/
                if(strstri(long_line, "/AD=") == 0) {
                    free(long_line);
                    continue;
                }
/*
    Parse out all options on the long command line for $SERIAL.SYS.
    First, get all the ADDRESS parameters.
*/
                serial_options = 1;
                cptr = long_line;
                for(i=0; i<24; ++i) {
                    cptr = strstri(cptr, "/AD=");
                    if(!cptr)
                        break;
                    cptr += 4;
                    serial_list[i].sp_address = htoi(cptr);
                }
/*
    Find any IB arguments.
*/
                cptr = long_line;
                for(i=0; i<24; ++i) {
                    cptr = strstri(cptr, "IB=");
                    if(!cptr)
                        break;
                    cptr += 3;
                    serial_list[i].sp_IB = atoi(cptr);
                }
/*
    Find any OB arguments.
*/
                cptr = long_line;
                for(i=0; i<24; ++i) {
                    cptr = strstri(cptr, "OB=");
                    if(!cptr)
                        break;
                    cptr += 3;
                    serial_list[i].sp_OB = atoi(cptr);
                }
/*
    Find any HS arguments.
*/
                cptr = long_line;
                for(i=0; i<24; ++i) {
                    cptr = strstri(cptr, "HS=");
                    if(!cptr)
                        break;
                    cptr += 3;
                    serial_list[i].sp_HS = *cptr;
                }
/*
    Find any IN arguments.
*/
                cptr = long_line;
                for(i=0; i<24; ++i) {
                    cptr = strstri(cptr, "IN=");
                    if(!cptr)
                        break;
                    cptr += 3;
                    serial_list[i].sp_IN = atoi(cptr);
                }
/*
    Find any CN arguments.
*/
                cptr = long_line;
                for(i=0; i<24; ++i) {
                    cptr = strstri(cptr, "CN=");
                    if(!cptr)
                        break;
                    cptr += 3;
                    serial_list[i].sp_CN = *cptr;
                }
/*
    Done processing $SERIAL.SYS
*/
                free(long_line);
            }

/* ================== END $SERIAL.SYS processing ========================= */
/*
    Handle MOUSE driver.
*/
            else if(strstri(buffer, "$MOUSE.SYS"))
                mouse_installed = 1;
/*
    Read all $PIPE.SYS lines.
*/
            else if(strstri(buffer, "$PIPE.SYS")) {
                pipe_installed[pipe_count] = 1;

                cptr = strstri(buffer, "/N");
                if(cptr) {
                    pipe_EOF_mode[pipe_count] = 1;
                    *cptr = '\0';
                }
                else
                    pipe_EOF_mode[pipe_count] = 0;

                cptr = strstri(buffer, "$PIPE.SYS") + 9;
                i = index(',', cptr);
                if(i > 8)
                    i = 8;
                if(i == -1) {  /* No comma found - only a device name */
                    strncpy(pipe_names[pipe_count], cptr, 8);
                    pipe_names[pipe_count][8] = '\0';
                    strupr(pipe_names[pipe_count]);
                    ++pipe_count;
                    continue;
                }
                else {  /* Comma found.  Get device name */
                    strncpy(pipe_names[pipe_count], cptr, i);
                    pipe_names[pipe_count][i] = '\0';
                    strupr(pipe_names[pipe_count]);
                }
                cptr = strchr(cptr, ',') + 1;
                pipe_buf_size[pipe_count] = atoi(cptr);
                if(pipe_buf_size[pipe_count] == 0)
                    pipe_buf_size[pipe_count] = 64;

                ++pipe_count;
            }
/*
    Handle $RAMDISK.SYS
*/
            else if(strstri(buffer, "$RAMDISK.SYS")) {
                ramdisk_installed = 1;
                cptr = strstr(buffer, "$RAMDISK.SYS");
                cptr += strlen("$RAMDISK.SYS");
                ramdisk_buffer_size = atoi(cptr);
                if(ramdisk_buffer_size == 0)
                    ramdisk_buffer_size = 64;
                cptr = strchr(buffer, ',');
                if(cptr)
                    sscanf(++cptr, "%lx", &ramdisk_page_frame);
            }
/*
    Handle $KB??.SYS (Keyboard drivers)
*/
            else if(strstri(buffer, "$KB")) {
                kb_installed = 1;
                cptr = strstri(buffer, "$KB");
                strncpy(kb_code, &cptr[3], 2);
                kb_code[3] = '\0';
                strupr(kb_code);
            }
/* 
      Handle patch drivers for 4.10 and 5.01
*/
          else if(strstri(buffer, "UPDAT501")) 
             {
             MOS5=1;
             }
          else if(strstri(buffer, "PATCH410")) 
             {
             PATCH410=1;
             }
   
            
/*
=============================================================================
    The VNA.SYS command line in the CONFIG.SYS file is quite lengthy
    and compilicated.  This section parses the command line and reads
    in all the parameters.  The form of the command line to parse is:

    DEVICE=VNA.SYS /VNA-address,VNA-int,Parallel address, ~
           parallel mode, serial address, serial interrupt, ~
           /AD=nnnn, IB=nnnn, OB=nnnn, HS={N,D,X,P,R}, CN={L,R,T} ~
           /MS=xxxx

    The parse section for this command line does the following:

    1) Chop the line into up to 4 parts, divided by each VNA board.
    2) Parse out the parameters specific to each board.
    3) Parse out the parameters specific to each IONA board.

=============================================================================
*/
            else if(cptr = strstri(buffer, "VNA.SYS")) {
                if(!(cptr = strchr(cptr, '/')))
                    continue;
/*
    Join continuation lines into one long line.
*/
                long_line = calloc(1, 2048);    /* Max 24 lines * 80 chars */
                if(!long_line) {
                    puts("ACU: Memory allocation error. (READ_EXI.C)\n");
                    exit(1);
                }
                strcpy(long_line, buffer);
                strupr(long_line);              /* Do comparisons in UC */
/*
    Get any continuation lines.
*/
                while(strchr(buffer, TILDE) != 0) {
                    if(!get_line(buffer, 133, fp_source))
                        buffer[0] = '\0';
                    squeeze(buffer, ' ');
                    strcat(long_line, buffer);
                }
                squeeze(long_line, TILDE);

                cptr = strchr(long_line, '/');
/*
    Split the command line in up to 4 pieces.
*/
                for(i=0; i<4; ++i) {
                    split_buf[i] = calloc(1, 512);    /* Leave plenty of space */
                    j=0;
                    do {
                        if(*cptr == '\0')
                            break;
                        split_buf[i][j++] = *cptr++;
                        if(*cptr == '/') {
                            if((strncmp(cptr, "/AD=", 4) != 0) &&
                               (strncmp(cptr, "/MS=", 4) != 0))
                               break;
                        }
                    } FOREVER;

                    if(*cptr == '\0')       /* Command line exhausted */
                        break;
                }
                free(long_line);            /* Done with it */
                VNA_installed = 1;
/*
    The lines have been split by VNA board.  Now, decompose each
    individual line.
*/
                for(i=0; i<4; ++i) {
                    if(!split_buf[i])       /* If no line, terminate parse */
                        break;
/*
    VNA board port address.
*/
                    cptr = strchr(split_buf[i], '/');
                    VNA_ports[i] = htoi(++cptr);
/*
    VNA board interrupt level.
*/
                    if(!(cptr = strchr(cptr, ',')))
                        continue;
                    VNA_int[i] = atoi(++cptr);
/*
    IONA board parallel base address.
*/
                    if(!(cptr = strchr(cptr, ',')))
                        continue;
                    IONA_list[i].pp_address = htoi(++cptr);

                    if(IONA_list[i].pp_address != 0)
                        IONA_installed[i] = 1;
/*
    IONA board Parallel port mode.
*/
                    if(!(cptr = strchr(cptr, ',')))
                        continue;
                    IONA_list[i].pp_mode = (*++cptr);
/*
    IONA board Serial port base address.
*/
                    if(!(cptr = strchr(cptr, ',')))
                        continue;
                    IONA_list[i].sp_AD[0] = htoi(++cptr);
                    IONA_list[i].sp_AD[1] = IONA_list[i].sp_AD[0] + 8;
                    IONA_list[i].sp_AD[2] = IONA_list[i].sp_AD[0] + 16;
                    IONA_list[i].sp_AD[3] = IONA_list[i].sp_AD[0] + 24;
/*
    IONA board Interrupt level.
*/
                    if(!(cptr = strchr(cptr, ',')))
                        continue;
                    IONA_list[i].int_level = atoi(++cptr);
/*
    Get the /MS option if present.
*/
                    if(cptr = strstr(cptr, "/MS=")) {
                        cptr += 4;
                        for(j=0; j<4; ++j) {
                            if(*cptr++ == 'Y')
                                IONA_list[i].sp_MS[j] = 1;
                            else
                                IONA_list[i].sp_MS[j] = 0;
                        }
                    }
/*
    Search for the /AD options associated with this IONA board.
*/
                    cptr = split_buf[i];

                    do {
                        cptr = strstr(cptr, "/AD=");
                        if(!cptr)
                            break;
                        cptr_max = strstr(&cptr[1], "/AD=");
                        if(!cptr_max)
                            cptr_max = cptr + strlen(cptr) - 1;

                        i2temp = htoi(&cptr[4]);
                        for(j=0; j<4; ++j) {
                            if(IONA_list[i].sp_AD[j] == i2temp)
                                break;
                        }
                        if(j == 4)
                            break;      /* Bad match.  Abort the parse */

                        if(cptr2 = strstr(cptr, "IB=")) {
                            if(cptr2 < cptr_max)
                                IONA_list[i].sp_IB[j] = atoi(&cptr2[3]);
                        }
                        if(cptr2 = strstr(cptr, "OB=")) {
                            if(cptr2 < cptr_max)
                                IONA_list[i].sp_OB[j] = atoi(&cptr2[3]);
                        }
                        if(cptr2 = strstr(cptr, "HS=")) {
                            if(cptr2 < cptr_max)
                                IONA_list[i].sp_HS[j] = cptr2[3];
                        }
                        if(cptr2 = strstr(cptr, "CN=")) {
                            if(cptr2 < cptr_max)
                                IONA_list[i].sp_CN[j] = cptr2[3];
                        }
                        cptr++;     /* Ready for next one */

                    } FOREVER;

                    free(split_buf[i]);     /* Done with it */
                }

                free(long_line);
            }

/*
    An unknown DEVICE.  Save the line.
*/
            else
                strcpy(old_config_text[stored_line_index++], orig_buffer);
        }
/*
    Don't recognize the option.  Copy it over.
*/
        else
            strcpy(old_config_text[stored_line_index++], orig_buffer);
    }
/*
    The interpretation is complete.  Close file and return.
*/
    fclose(fp_source);
/*
    Rebuild the I/O and memory address map.  Then calculate the
    amount of Extended Memory used by the various options.
*/
    Build_address_map();
    Calculate_memory_usage();
}
