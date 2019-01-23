/*
*****************************************************************************
*
*   MODULE NAME:    main
*
*   TASK NAME:      IMPORT.EXE
*
*   PROJECT:        PC-MOS Utilities
*
*   CREATION DATE:  2/5/91
*
*   REVISION DATE:  2/5/91
*
*   AUTHOR:         B. W. Roeser
*
*   DESCRIPTION:    Restores files previously backed up by MOS's
*                   EXPORT utility.
*
*
*               (C) Copyright 1991, The Software Link, Inc.
*                       All Rights Reserved
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
#include <string.h>
#include <stdlib.h>
#include <rsa\rsa.h>

#define FOREVER while(1)

extern char     source_path[],
                target_path[];

static char     drive[3], dir[65], fname[9], ext[5];
static char     DTA_buffer[48];

main(int argc, char **argv)
{

    extern int      disk_count,
                    source_drive;

    extern char     disk_label[];

    extern unsigned char    S_flag;

    char        filename[13];
    char        last_filename[13];
    char        pathname[65];
    char        source_file[65], target_file[65];
    char        tree_root[65];

    unsigned char   disk_changed;

    int         l;
    int         found;
    int         status;
    int         import_count=0;

    unsigned    attrib;

    setup_i24();

    disk_count = 0;

    if(is_MOS())
        save_TCB_data();

    Parse_command_line(argc, argv);
/*
**  The user wants to IMPORT recursively into directories.
*/
    if(S_flag) {
/*
**  If the source path ended with a \, then append a wildcard
**  to it.
*/
        if(!strchr(source_path, '*') && !strchr(source_path, '?')) {
            l = strlen(source_path);
            if(source_path[l-1] == '\\')
                strcat(source_path, "*.*");
            else
                strcat(source_path, "\\*.*");
        }
/*
**  Guarantee that the target path ends with a \.  Then create the target
**  path's directory.
*/
        _splitpath(target_path, drive, dir, fname, ext);
        if(strlen(fname) != 0)
            strcat(target_path, "\\");

        if(makepath(target_path) != 0) {
            printf("IMPORT: Could not create target path %s\n", target_path);   /* @@XLATN */
            Terminate(1);
        }
/*
**  Establish the starting point on the floppy based on the input
**  source path.
*/
        do {
            disk_count = Get_next_disk(disk_count, disk_label);
            found = Establish_starting_file(source_path, filename, &attrib);
            if(found) {
                strcpy(last_filename, filename);
                break;
            }
            if(disk_label[3] == 'L') {
                puts("IMPORT: No files found to import.");  /* @@XLATN */
                Terminate(1);
            }
        } FOREVER;

        disk_changed = 0;
/*
**   While there are still files existing on the source drive.
*/
        while(found) {
            read_DTA(DTA_buffer, 48);
            _splitpath(source_path, drive, dir, fname, ext);
/*
**  Is the file found a directory?
*/
            if(attrib & 0x10) {
                sprintf(tree_root, "%s%s%s", drive, dir, filename);

                if(set_tree(tree_root) != 0) {
                    printf("IMPORT: No such source directory [%s]\n", source_path); /* @@XLATN */
                    Terminate(1);
                }

                while(walk_tree(source_file, &attrib) == 0) {
                    if((attrib & 0x10) == 0 && (attrib & 0x08) == 0) {
                        _splitpath(source_file, drive, dir, fname, ext);

                        if(dir[0] == '\\')
                            sprintf(target_file, "%s%s%s%s", target_path, &dir[1], fname, ext);
                        else
                            sprintf(target_file, "%s%s%s%s", target_path, dir, fname, ext);

                        _splitpath(target_file, drive, dir, fname, ext);

                        strcpy(pathname, drive);
                        strcat(pathname, dir);
                        makepath(pathname);

                        status = Decompress_file(source_file, target_file);
/*
**  If a diskette boundary was crossed, then reset the tree path to
**  where we started.  Then walk the tree until the last half of the
**  file that was split is found again and skip it.  Then continue
**  the tree walk for the next files.
*/
                        if(status == 3) {
                            disk_changed = 1;
                            set_tree(tree_root);
                            do {
                                walk_tree(pathname, &attrib);
                            } while(strcmp(pathname, source_file) != 0);
                        }
                        import_count++;
                    }
                } /* End while(walk_tree()) */
            }
/*
**  The file found wasn't a directory.  Simply import it to the target
**  directory.
*/
            else if((attrib & 0x08) == 0) {
                sprintf(source_file, "%s%s%s", drive, dir, filename);

                if(dir[0] == '\\')
                    sprintf(target_file, "%s%s%s", target_path, &dir[1], filename);
                else
                    sprintf(target_file, "%s%s%s", target_path, dir, filename);

                _splitpath(target_file, drive, dir, fname, ext);
                strcpy(pathname, drive);
                strcat(pathname, dir);
                makepath(pathname);

                status = Decompress_file(source_file, target_file);
                if(status == 3)
                    disk_changed = 1;
                import_count++;
            }
/*
**   If the disk changed, we will need to re-establish the position
**   at which we were before diving down into the directory tree
**   and pick up at the next file in the list.
*/
            if(disk_changed) {
                disk_changed = 0;
                found = Establish_starting_file(source_path, filename, &attrib);
                while(found) {
                    if(strcmp(filename, last_filename) == 0) {
                        found = find_next_file(filename, &attrib);
                        strcpy(last_filename, filename);
                        break;
                    }
                    found = find_next_file(filename, &attrib);
                }
            }
            else {
                write_DTA(DTA_buffer, 48);
                found = find_next_file(filename, &attrib);
                strcpy(last_filename, filename);
            }
/*
**   If no files are found, then are we at the end of the import set?
*/
            while(!found) {
                if(disk_label[3] == 'L')
                    break;
                disk_count = Get_next_disk(disk_count, disk_label);
                found = Establish_starting_file(source_path, filename, &attrib);
                strcpy(last_filename, filename);
            }

        } /* End while(found) */
    } /* End if (S_flag) */
/*
**  Flat directory restore.
*/
    else {
/*
**  Guarantee that the target path ends with a \.
*/
        _splitpath(target_path, drive, dir, fname, ext);
        if(strlen(fname) != 0)
            strcat(target_path, "\\");

        if(makepath(target_path) != 0) {
            printf("IMPORT: Could not create target path %s\n", target_path);   /* @@XLATN */
            Terminate(1);
        }
/*
**   If the source path was d:\, then append *.*.
*/
        _splitpath(source_path, drive, dir, fname, ext);
        if(!strlen(fname) && strcmp(dir, "\\") == 0)
            strcat(source_path, "*.*");
/*
**  Get next disk and establish starting point on it.
*/
        disk_count = Get_next_disk(disk_count, disk_label);

        do {
            found = Establish_starting_file(source_path, filename, &attrib);
            if(found) {
                if((attrib & 0x10) == 0) {
                    strcpy(last_filename, filename);
                    break;
                }
/*
**  The file found is a directory.  If the user is searching using a
**  wildcard in the source path, just skip it and continue searching
**  for files in the directory.  If not, then he wants all files in
**  the specified directory.
*/
                if(strchr(source_path, '*') || strchr(source_path, '?')) {
                    strcpy(last_filename, filename);
                    break;
                }
                else {
                    strcat(source_path, "\\*.*");
                    continue;
                }
            }
/*
**  File not found.  Are we at the end of the import set?
*/
            if(disk_label[3] == 'L') {
                puts("IMPORT: No files found to import.");  /* @@XLATN */
                Terminate(1);
            }

            disk_count = Get_next_disk(disk_count, disk_label);

        } FOREVER;

        _splitpath(source_path, drive, dir, fname, ext);
/*
**   Construct the source and target filenames and do the decompression.
*/
        while (found) {
            if((attrib & 0x10) == 0 && (attrib & 0x08) == 0) {
                sprintf(source_file, "%s%s%s", drive, dir, filename);
                sprintf(target_file, "%s%s", target_path, filename);
                status = Decompress_file(source_file, target_file);
                import_count++;
                if(status == 3) {
                    found = Establish_starting_file(source_path, filename, &attrib);
                }
                found = find_next_file(filename, &attrib);
            }
            else
                found = find_next_file(filename, &attrib);

            while(!found) {
                if(disk_label[3] == 'L')
                    break;
                disk_count = Get_next_disk(disk_count, disk_label);
                found = Establish_starting_file(source_path, filename, &attrib);
                strcpy(last_filename, filename);
            }
        }
    } /* End IF */

    if(import_count == 0)
        puts("IMPORT: No files found to import.");  /* @@XLATN */

    puts("\nIMPORT complete."); /* @@XLATN */
}
/*
=====
*/
Establish_starting_file(char *source_path, char *filename, int *attrib)
{
    int     found;

    _splitpath(source_path, drive, dir, fname, ext);

    if(!find_first_file(source_path, filename, attrib))
        return(0);

    if(!strcmp(filename, ".")) {
        find_next_file(filename, attrib);      /* Get ".." */
        if(!find_next_file(filename, attrib))
            return(0);
    }

    if(*attrib & 0x08) {
        found = find_next_file(filename, attrib);
        return(found);
    }
    else
        return(1);      /* Set FOUND = TRUE */
}
