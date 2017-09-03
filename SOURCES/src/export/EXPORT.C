/*=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        export.c
 task name:          export.exe
 creation date:      01/08/91
 revision date:      12/18/92
 author:             rbr/bwr/mjs
 description:        pc-mos backup utility

======================================================================

.ts

Testing notes for EXPORT.EXE

==== usage

 export d:[path] d: [/s] [/d:mm-dd-yy] [/m] [/q] [/?]

    d:[path]    source directory or file to be archived to floppy drive.

    d:          target drive.

    /s          copy all subdirectories.

    /f 		select alternate behavior for /s (see below)

    /d          archive all files after specified date.
                (default is archive all files)

    /m          archive only files with archive bit set.
                (files modified since last backup)

    /q          ask user for parameters.  ignore any others
                entered on command line.

    /a		append to existing backup set.

    /?          display help page showing user how to use export


==== elaboration on the /f switch

Given the configuration:

 export c:\sales\j*.* a: /s

here is what would happen:

All files within the C:\SALES directory that start with the letter
'J' would be exported.  In addition, EXPORT would also find any
subdirectories within C:\SALES whose name starts with an 'J'.  For
each of these directories, and all child directories under them, ALL
files would be backed up, regardless of whether they started with 'J'
or not.

This would be useful for the case where your C:\SALES directory
contained the following subdirectories:

C:\SALES\JAN
C:\SALES\FEB
C:\SALES\MAR
C:\SALES\APR
C:\SALES\MAY
...
...
C:\SALES\DEC

The above EXPORT parameters would cause all files within the JAN, JUN
and JUL directories to be backed up.

There could also be cases where an alternate behavior would be
desired, which is where the /f switch comes in:

 export c:\sales\j*.* a: /s /f

This would cause the following:

All files within the C:\SALES directory that start with the letter
'J' would be exported.  In addition, EXPORT would also find any and
all subdirectories within C:\SALES.  For each of these directories,
and all child directories under them, only files that started with
'J' would be backed up.


==== tests

-- verify proper action when a single file is specified

 export xyz.abc  a:

-- when a group of files is specified

 export xyz.* a:
 export *.abc a:
 export x*.abc a:    
 export c:\archive\x*.abc a:

-- when a directory name is specified

 export \ a:
 export d:\ a:	     (where the current drive is not d:)
 export c:\work.dir a:

-- verify proper handling of mos's security info

 when export writes a file to the backup diskettes, it temporarily
 changes the system's default output class to match the class of 
 the file.  

!! Current state !!

 it appears that a file's creation date and user name are not
 preserved.  check import's sourcecode.

-- verify critical error handling

 if a critical error is forced during the exportation of a secured
 file whose class is different than the defalut output class, upon
 choosing abort, the current defalut output class should be 
 properly restored.

-- verify control-c handling

 if a cntrl-c exit is made during the exportation of a secured file,
 export's cntrl-c handler should make sure that the original defalut
 output class is restored.  this could happen if break is on since
 a cntrl-c would be recognized on any system call for file i/o (export
 makes a lot of these).  this could also happen when a secured file
 is continued from one diskette to another and you enter cntrl-c
 at the "insert next diskette" prompt.

-- handling of the /a parameter

 if an attempt is made to start the append operation with any other
 diskette other than the last of the current backup set, an error 
 should be flagged.

 the first diskette used in an append operation (the last diskette
 of the current backup set), it should not, of course, be cleared.
 but, when subsequent diskettes are inserted, they should be
 cleared of any existing contents.

 export should sync up with the existing diskette numbering through
 the volume labels.  for example, if the first append disk is labeled
 as #3, then when export asks for the next diskette, it should ask
 for #4.  export should syncronize to the numbering of the current
 backup set by reading the volume label of the first diskette used
 in the append operation.

-- handling of the /s and /f parameters

 simple form: export c:\ a: /s

  this should export all files in the root and all files in all
  subdirectories.

 variation #1:  export c:\stuff a: /s

  should export all files within c:\stuff (presuming that stuff is
  a directory rather than a file) and all files in all child directories.

 variation #2:  export c:\stuff\m*.* a: /s

  this should export all files within the c:\stuff directory that
  start with the letter 'm'.  it should also find every subdirectory
  within c:\stuff whose name starts with an 'm' and then export
  all files within those subdirectories and their child directories.

 variation #3:  export c:\stuff\m*.* a: /s /f

  this should export all files within the c:\stuff directory that start
  with the letter 'm'.  it should also find every subdirectory within
  c:\stuff and then export all files within those subdirectories and
  their child directories that start with the letter 'm'.

 giving the /f switch without the /s switch should be flagged as
 a syntax error.

-- handling of the /d parameter

 the doc says that /d selects files with dates that come after the
 specified data.  but, the code has always been designed to select
 files that match or come after the specified date.

-- handling of the /m parameter

 should only archive files with archive bit set.

-- handling of the /q parameter

 should prompt for parameter values.

-- handling of the /? parameter

 should report proper syntax.

-- syntax checking for bad parameters

 should balk at:
  attempts to use invalid switches
  invalid use of valid switches
  bad drive and file specifications
  extra parameters

-- other

 test under dos - export tests for mos and doesn't try to deal with
 security information under dos.  note: exporting secured files under
 mos and then restoring them under dos will not allow them to be 
 decrypted.

 test with a large file -- one that spans across multiple diskettes.

 verify that existing diskette data is erased when don't use /a.

 proper reporting of # of files processed.

.te

======================================================================

sah 03/31/92	fix bug for 14th disk. not correctly closing files

mjs 10/05/92	the write_output_file() function was using diskfree()
		(from rsasmall.lib) to determine freespace on the disk.
		this function was not returning meaningful data and
		couldn't find its sourcecode.  rewrote the 
		write_output_file() function to not need diskfree().
		combined all c source for export into this module
		and cleaned up the source format.

mjs 12/18/92	complete rewrite.  remove all use of the rsasmall.lib 
		library.  adapt to compile under bcc 3.1.
		modify /a behavior.  add /f behavior.

mjs 02/01/93	changes actually made: 1/6/93 -- 1/7/93.
		the /q option now works again.  
		when run under mos, this utility will warn the 
		user if more than 1 task exists.  the help message
		(from the /? switch) explains /d and /m more clearly 
		and now covers the /f switch.

====================================================================*/

#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <malloc.h>
#include <dos.h>
#include <io.h>
#include <dir.h>
#include <string.h>
#include <ctype.h>
#include <fcntl.h>
#include <errno.h>
#include <sys\types.h>
#include <sys\stat.h>

#include "ulib.h"


// prototypes for expasm.asm

void setup_i2324(void);


#define BUF_SIZE 24 * 1024

typedef struct ffblk DTA;

typedef struct {
 byte file_attrib;
 byte filename[13];
 word time_stamp;
 word date_stamp;
 long file_size;
 } FINFO;

static union REGS regs;		// for intdos calls
static struct SREGS segregs;	// for intdos calls
word file_count;		// total files backed up
word disk_count;     		// number of disks backed up so far
byte A_flag = 0;     		// append to data existing on disk
byte S_flag = 0;     		// archive sub directories?
byte F_flag = 0;     		// alternate behavior for /s
byte M_flag = 0;     		// copy only modified files?
byte Q_flag = 0;     		// get parameters manually?
byte D_flag = 0;     		// archiving files after a date?
byte yes[] = "Yes";  		// @@xlatn
byte no[] = "No";    		// @@xlatn
byte source_arg[65]; 		// source path argument
byte target_arg[65]; 		// target drive argument
word target_drive;   		// numeric drive assignment. 1=a, 2=b
word start_date[7] = {0,0,0,0,0,0,0}; // archive after date
byte cvalue;			// compression value, reset for each file
static char FCB[37];		// fcb for i21f13
char signature[] = "Xf";			
char buffer[80];
unsigned char local_buffer[300];
byte ismos;
dword tcbcdftPtr;
byte origcdft;
byte sensitive = 0;		// flags sensitive time for i23 and i24
byte first_append = 1;		// flags 1st diskette in an append operation
byte *p2_spec;			// helper for process_file2()
byte p2_norm[12];		// normalized version of string at p2_spec

/*======================================================================
;,fs
; void terminate(void)
; 
; used through the atexit() feature.
;
; in:
;
; out:	
;
;,fe
========================================================================*/
void terminate(void) {

  if(ismos) {
    *tcbcdftPtr.bptr = origcdft;
    }
  }

/*======================================================================
;,fs
; byte getyesno(void)
; 
; in:	
;
; out:	retval = 1 if char entered is yes[0], else retval = 0
;
;,fe
========================================================================*/
byte getyesno(void) {

  byte ans[4];

  ans[0] = 2;
  cgets(ans);
  printf("\n");
  if(toupper(ans[2]) == yes[0]) {
    return(1);
    }
  else {
    return(0);
    }
  }

/*======================================================================
;,fs
; void getenter(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void getenter(void) {

  byte ans[3];

  ans[0] = 1;
  cgets(ans);
  }

/*======================================================================
;,fs
; void kill_directory(byte *parent, byte *dir_name)
; 
; in:	parent -> parent of the directory to kill
;	dir_name -> the directory to kill
;
; out:	
;
;,fe
========================================================================*/
void kill_directory(byte *parent, byte *dir_name) {

  byte current_path[MAXPATH];
  DTA d;
  byte first;
  byte *tptr;
  word err_stat;

  chdir(dir_name);

  // delete all files in this directory.

  regs.h.ah = 0x13;
  regs.x.dx = (unsigned)FCB;
  segread(&segregs);
  int86x(0x21,&regs,&regs,&segregs);

  // now, search for all directories and walk down into them.

  getcwd(current_path,MAXPATH);
  tptr = strchr(current_path,0);
  if(*(tptr-1) != '\\') {
    strcat(current_path,"\\*.*");
    }
  else {
    strcat(current_path,"*.*");
    }
  first = 1;
  while(1) {
    if(first) {
      err_stat = findfirst(current_path,&d,0x10);
      *tptr = 0;
      first = 0;
      }
    else {
      err_stat = findnext(&d);
      }
    if(err_stat) {
      if(_doserrno == 0x12) {
        break;
        }
      else {
        printf("Error initializing target\n"); // @@xlatn
        exit(1);
        }
      }
    if(d.ff_attrib & 0x10) {
      if(d.ff_name[0] == '.') {
        continue;
        }
      kill_directory(current_path,d.ff_name);
      }
    }

  // the directory has been wiped out.  return to the 
  // parent and remove the directory.

  chdir(parent);
  rmdir(dir_name);
  }

/*======================================================================
;,fs
; word initialize_drive(word drive)
; 
; in:	drive = drive to be initialized (1=A, 2=B, etc.).
;
; out:	retval = 0 if no error
;
;,fe
========================================================================*/
word initialize_drive(word drive) {

  byte current_path[MAXPATH];
  word current_drive;
  DTA d;
  byte first;
  byte *tptr;
  word err_stat;

  // set up our fcb.

  FCB[0] = drive;
  strcpy(&FCB[1], "???????????");
  memset(&FCB[12],0,25);

  // first, get the current drive, then change to the selected drive.

  regs.h.ah = 0x19;
  intdos(&regs,&regs);
  current_drive = regs.h.al;

  // change to the selected drive.

  regs.h.ah = 0x0E;
  regs.h.dl = drive-1;
  intdos(&regs,&regs);
  if(regs.x.cflag) {
    return(-1);
    }

  // change to the root directory.

  chdir("\\");

  // delete all files in this directory.

  regs.h.ah = 0x13;
  regs.x.dx = (unsigned) FCB;
  segread(&segregs);
  int86x(0x21,&regs,&regs,&segregs);

  // now, search for all directories and walk down into them.

  getcwd(current_path,MAXPATH);
  tptr = strchr(current_path,0);
  strcat(current_path,"*.*");
  first = 1;
  while(1) {
    if(first) {
      err_stat = findfirst(current_path,&d,0x10);
      *tptr = 0;
      first = 0;
      }
    else {
      err_stat = findnext(&d);
      }
    if(err_stat) {
      if(_doserrno == 0x12) {
        break;
        }
      else {
        printf("Error initializing target\n"); // @@xlatn
        exit(1);
        }
      }
    if(d.ff_attrib & 0x10) {
      kill_directory(current_path,d.ff_name);
      }
    }

  // return to the original drive and exit.

  regs.h.ah = 0x0E;
  regs.h.dl = current_drive;
  intdos(&regs,&regs);
  if(regs.x.cflag)  {
    return(-1);
    }
  return(0);
  }

/*======================================================================
;,fs
; word get_next_disk(word count)
; 
; in:	count = # of diskettes already written
;
; out:	retval = # of diskettes + 1
;
;,fe
========================================================================*/
word get_next_disk(word count) {

  byte lbl_buf[12];
  byte bad;
  byte i;
  byte ans[10];

  if(A_flag && first_append) {
    printf("\nContinuing backup on drive %s.\n", target_arg); // @@xlatn
    printf("Press the ENTER key when ready ....");  // @@xlatn
    getenter();
    printf("\n\n");

    // read the disk label, verify proper form and derive the count value

    ul_read_dsklbl(target_drive,lbl_buf);
    bad = 0;
    if((strlen(lbl_buf) != 8) || (strncmp(lbl_buf,"EX-L",4) != 0)) {
      bad = 1;
      }
    for(i=4;i<8;i++) {
      if(isdigit(lbl_buf[i]) == 0) {
        bad = 1;
        break;
        }
      }
    if(bad) {
      printf("Not the last diskette of a backup set\n"); // @@xlatn
      exit(1);
      }
    count = atoi(&lbl_buf[4]);
    }
  else {
    printf("\nPlease insert archive disk # %d in drive %s.\n",++count, target_arg); // @@xlatn
    printf("Press the ENTER key when ready ....");  // @@xlatn
    getenter();
    printf("\n\n");
    }

  // if /a wasn't specified or if /a was specified but first_append == 0, 
  // destroy anything on the target diskette.

  if(!A_flag || first_append == 0) {
    printf("Preparing diskette in %s ... ", target_arg);    // @@xlatn
    initialize_drive(target_drive);
    printf("diskette cleared.\n");  // @@xlatn
    }

  // write diskette volume label on the target drive.

  sprintf(buffer, "EX-I%04d", count);
  ul_write_dsklbl(target_drive,buffer);

  // reset first_append so subsequent diskettes in the append operation
  // will be wiped clean.

  if(A_flag) {
    first_append = 0;
    }

  // return the new disk count.

  return(count);
  }

/*======================================================================
;,fs
; word count_repeats(const byte *buffer, const word offset, const word len)
; 
; in:	buffer -> ???
;	offset = ???
;	len = ???
;
; out:	retval = ???
;
;,fe
========================================================================*/
word count_repeats(const byte *buffer, const word offset, const word len) {

  word i;
  word count = 0;
  register byte test_byte;

  if(offset >= len)  {
    return(0);
    }
  test_byte = buffer[offset];
  for(i=offset+1; i<len; ++i) {
    if(buffer[i] == test_byte) {

      // max in ctrl word

      if(++count == 253)                   {
        return(count);
        }
      }
    else {
      return(count);
      }
    }
  return(count);
  }

/*======================================================================
;,fs
; word compress_data(byte *inbuff, byte *outbuff, word len)
; 
; in:	inbuff -> ????????
;	outbuff -> ????
;	len = ?????????
;
; out:	retval = ???
;
;,fe
========================================================================*/
word compress_data(byte *inbuff, byte *outbuff, word len) {

  word max;
  word ib_index;
  word ob_index;
  word lb_index;
  word count;
  word diff_count;

  ib_index = ob_index = lb_index = 0;
  diff_count = 0;
  max = len-1;
  ib_index = 0;
  while(ib_index < max) {
    if(inbuff[ib_index] != inbuff[ib_index+1]) {
      local_buffer[lb_index++] = inbuff[ib_index++];
      diff_count++;
      if(diff_count == 254) {
        diff_count = 0;
        outbuff[ob_index++] = 254;      // Uncompressed data
        outbuff[ob_index++] = 0;        // compressed data
        memcpy(&outbuff[ob_index], local_buffer, 254);
        ob_index += 254;
        lb_index = 0;
        }
      }
    else {

      // at least two bytes are the same.  make sure there are at least
      // 4 before dumping the local buffer and setting up a control word.

      count = count_repeats(inbuff, ib_index, len);
      if(count >= 3) {
        count++;                                // now # of bytes
        if(cvalue != inbuff[ib_index]) {
          cvalue = inbuff[ib_index];
          outbuff[ob_index++] = 0xFF;         // control
          outbuff[ob_index++] = cvalue;       // new comp byte
          }
        outbuff[ob_index++] = diff_count;       // uncompressed
        outbuff[ob_index++] = count;            // compressed bytes
        ib_index += count;
        if(diff_count > 0) {
          memcpy(&outbuff[ob_index], local_buffer, diff_count);
          ob_index += diff_count;
          lb_index = 0;
          diff_count = 0;
          }
        }
      else {
        local_buffer[lb_index++] = inbuff[ib_index++];
        diff_count++;
        if(diff_count == 254) {
          diff_count = 0;
          outbuff[ob_index++] = 254;
          outbuff[ob_index++] = 0;
          memcpy(&outbuff[ob_index], local_buffer, 254);
          ob_index += 254;
          lb_index = 0;
          }
        }
      }
    }

  // if any of the local buffer is left, dump it out.  if not, then
  // handle the last byte.

  if(diff_count > 0) {
    outbuff[ob_index++] = diff_count;
    outbuff[ob_index++] = 0;
    memcpy(&outbuff[ob_index], local_buffer, diff_count);
    ob_index += diff_count;
    }

  // was there a straggler byte? 

  if(ib_index == max) {
    outbuff[ob_index++] = 1;
    outbuff[ob_index++] = 0;
    outbuff[ob_index++] = inbuff[max];
    }

  // all done.  return the size of the output buffer.

  return(ob_index);
  }

/*======================================================================
;,fs
; word write_output_file(byte *ifil, byte *ofil, byte *dpath, FINFO fin)
; 
; compresses and writes the specified input file to the target file.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
word write_output_file(byte *ifil, byte *ofil, byte *dpath, FINFO fin) {

  byte spec_buffer[10];
  byte *inbuff;
  byte *outbuff;
  word space_free;
  word temp;
  word byte_count;
  word comp_count;
  word in_handle;
  word out_handle;
  int actual;
  long fpos;   

  // load the tcb with the security class of this file before writing
  // it. (if under mos that is).

  if(ismos) {

    // call id4f03 to get the file's class.  make that the
    // default output class while exporting this file.

    regs.x.ax = 0x0300;
    regs.x.dx = (word)ifil;
    segregs.ds = _DS;
    regs.x.bx = (word)spec_buffer;
    segregs.es = _DS;
    int86x(0xd4,&regs,&regs,&segregs);
    *tcbcdftPtr.bptr = spec_buffer[1];
    sensitive = 1;
    }

  // allocate buffer space.

  if((inbuff = malloc(BUF_SIZE)) == NULL) {
    printf("Error - insufficient memory\n");
    exit(1);
    }

  // + 1024 to give overflow room

  if((outbuff = malloc(BUF_SIZE + 1024)) == NULL) {
    printf("Error - insufficient memory\n");
    exit(1);
    }

  // open the two files.

  out_handle = open(ofil, O_CREAT | O_BINARY | O_RDWR, S_IREAD | S_IWRITE);
  in_handle = open(ifil, O_BINARY | O_RDONLY);

  // write the file date into the header.

  write(out_handle, signature, 2);                 // write export signature
  write(out_handle, (byte *) &fin.file_attrib, 1); // file attributes
  write(out_handle, (byte *) &fin.time_stamp, 2);  // time stamp of file
  write(out_handle, (byte *) &fin.date_stamp, 2);  // date stamp of file
  write(out_handle, (byte *) &fin.file_size, 4);   // file length (bytes)
  write(out_handle, fin.filename, 13);             // file name

  // read, compress and write the file.

  cvalue = 0;
  do {
    byte_count = read(in_handle, inbuff, BUF_SIZE);
    if(byte_count == 0) {
      break;
      }
    comp_count = compress_data(inbuff, outbuff, byte_count);
    actual = write(out_handle, outbuff, comp_count);

    // if a write error, or less was written than requested, presume
    // a full diskette.

    if(actual == -1 || actual < comp_count) {

      // if a partial write was done, must truncate the output file 
      // at the last whole-write point.

      if(actual != -1) {
        fpos = lseek(out_handle,0L,SEEK_CUR);
        fpos -= actual;
        lseek(out_handle,fpos,SEEK_SET);
        write(out_handle, outbuff, 0);
        }

      // prompt for the next diskette and continue, resetting
      // the read pointer for the input file to repeat the block
      // that wouldn't fit.

      close(out_handle);
      disk_count = get_next_disk(disk_count);
      printf("Continuing export of: %s\n", ofil);  // @@xlatn
      if(strlen(dpath) > 0) {
        if(ul_makepath(dpath)) {
          printf("Error creating directory on target\n"); // @@xlatn
          exit(1);
          }
        }
      out_handle = open(ofil, O_CREAT | O_BINARY | O_RDWR, S_IREAD | S_IWRITE);
      fpos = lseek(in_handle,0L,SEEK_CUR);
      fpos -= BUF_SIZE;
      lseek(in_handle,fpos,SEEK_SET);
      }
    } while(1);
  close(in_handle);
  close(out_handle);

  // restore the tcb file class to the default.

  if(ismos) {
    *tcbcdftPtr.bptr = origcdft;
    sensitive = 0;
    }

  // clear the archive bit in the input file.

  _chmod(ifil,1,fin.file_attrib);
  free(inbuff);
  free(outbuff);
  return(0);
  }

/*======================================================================
;,fs
; word output_file(byte *input_file)
; 
; in:	input_file -> full pathname of file to be placed on target drive.
;
; out:	retval = 0 if no error
;	retval = 1 if file not output due to date requirements
;
;,fe
========================================================================*/
word output_file(byte *input_file) {

  byte drive[MAXDRIVE];
  byte dir[MAXDIR];
  byte fname[MAXFILE];
  byte ext[MAXEXT];
  byte output_path[MAXPATH];
  byte output_file[MAXPATH];
  word file_date[3];
  FINFO fin;
  word ihandle;

  // if the user specified to backup only files that were modified
  // (i.e. the archive bit is set) then check to see if this file
  // qualifies to be backed up.

  fin.file_attrib = _chmod(input_file,0);
  if(M_flag && (fin.file_attrib & 0x20) == 0) {
    return(1);
    }
  fin.file_attrib &= 0xDF;                            // Clear archive bit

  // get file date

  ihandle = open(input_file, O_BINARY | O_RDONLY);
  _dos_getftime(ihandle,&fin.date_stamp,&fin.time_stamp);
  close(ihandle);
  file_date[0] = (fin.date_stamp >> 9) + 1980;
  file_date[1] = (fin.date_stamp >> 5) & 0xf;
  file_date[2] = fin.date_stamp & 0x1f;

  // get file size

  fin.file_size = ul_getfilesize(input_file);

  // prep name and path strings

  fnsplit(input_file, drive, dir, fname, ext);
  strcpy(fin.filename, fname);
  strcat(fin.filename, ext);

  // next, using the pathname of the file input, construct the
  // pathname of the output file.  then, before trying to copy
  // it over, make sure the path directory exists on the target
  // drive.

  sprintf(output_file, "%s%s%s%s", target_arg, dir, fname, ext);
  if(strlen(dir) > 0) {
    strcpy(output_path, target_arg);
    strcat(output_path, dir);
    if(ul_makepath(output_path)) {
      printf("Error creating directory on target\n"); // @@xlatn
      exit(1);
      }
    }
  else {
    output_path[0] = '\0';
    }

  // did the user ask to output only files past a certain date?

  if(D_flag) {
    if(file_date[0] >= start_date[0] && file_date[1] >= start_date[1] && file_date[2] >= start_date[2]) {
      printf("Exporting: %s\n", input_file);  // @@xlatn
      write_output_file(input_file, output_file, output_path, fin);
      }
    else {
      return(1);
      }
    }
  else {
    printf("Exporting: %s\n", input_file);  // @@xlatn
    write_output_file(input_file, output_file, output_path, fin);
    }

  // the file was output successfully.

  return(0);
  }

/*======================================================================
;,fs
; word process_file1(byte *path, byte *fname, byte attr)
; 
; handles the processing of each file found by ul_trace_dir()
; and ul_walk_tree().
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
word process_file1(byte *path, byte *fname, byte attr) {

  byte buf[MAXPATH];

  strcpy(buf,path);
  strcat(buf,fname);
  if(output_file(buf) == 0) {
    file_count++;
    }
  return(0);
  }

/*======================================================================
;,fs
; word process_file2(byte *path, byte *fname, byte attr)
; 
; handles the /s case by using ul_walk_tree() when a directory
; is encountered.  this is for the non-/f case
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
word process_file2(byte *path, byte *fname, byte attr) {

  byte pathname[MAXPATH];

  if(attr & 0x10)  {
    if(fname[0] != '.') {
      strcpy(pathname,path);
      strcat(pathname,fname);
      ul_walk_tree(pathname,"*.*",process_file1);
      }
    return(0);
    }
  else  {
    return(process_file1(path,fname,attr));
    }
  }

/*======================================================================
;,fs
; word process_file3(byte *path, byte *fname, byte attr)
; 
; handles the /s case by using ul_walk_tree() when a directory
; is encountered.  this is for the /f case.
;
; in:	
;
; out:	
;
;,fe
========================================================================*/
word process_file3(byte *path, byte *fname, byte attr) {

  byte pathname[MAXPATH];
  byte found_norm[12];

  if(attr & 0x10)  {
    if(fname[0] != '.') {
      strcpy(pathname,path);
      strcat(pathname,fname);
      ul_walk_tree(pathname,p2_spec,process_file1);
      }
    return(0);
    }
  else  {

    // if a pattern match, process the file

    ul_form_template(fname,found_norm);
    if(ul_qualify_template(p2_norm,found_norm)) {
      return(process_file1(path,fname,attr));
      }
    else {
      return(0);
      }

    }
  }

/*======================================================================
;,fs
; void display_usage(void)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void display_usage(void) {

  puts("PC-MOS File Archiving Utility v5.01 (921214)");   // @@xlatn
  puts("(C) Copyright 1990-1992 The Software Link, Inc.");
  puts("All Rights Reserved Worldwide.\n");
  puts("Usage:  EXPORT d:[path] d: [/S] [/D:mm-dd-yy] [/M] [/Q] [/A] [/?]\n"); // @@xlatn
  puts("        d:[path]     - Drive, directory, and files to archive."); // @@xlatn
  puts("        d:           - Destination drive to accept archive."); // @@xlatn
  puts("        /S           - Include sub-directories in archive."); // @@xlatn
  puts("        /F           - Specify alternate behavior for /S."); // @@xlatn
  puts("        /D:mm-dd-yy  - Archive all files on or after this date"); // @@xlatn
  puts("                       otherwise archive all files."); // @@xlatn
  puts("        /M           - Archive only files modified since last export."); // @@xlatn
  puts("        /A           - Append to existing files on diskette."); // @@xlatn
  puts("        /Q           - Query for options, ignore command line."); // @@xlatn
  puts("        /?           - This HELP page.\n"); // @@xlatn
  }

/*======================================================================
;,fs
; void syntax_error(byte *str)
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
void syntax_error(byte *str)  {

  printf("EXPORT: Syntax error in %s\n", str);    // @@xlatn
  puts("Use EXPORT /? for HELP.");    // @@xlatn
  }

/*======================================================================
;,fs
; void parse_command_line(int argc, char **argv)
; 
; in:	argc = # of cmd line args
;	argv[] = array of pointers to cmd line args
;
; out:	
;
;,fe
========================================================================*/
void parse_command_line(int argc, char **argv)  {

  byte fatal_error = 0;
  byte drive[3];
  byte dir[65];
  byte fname[9];
  byte ext[5];
  byte *cptr;
  byte ans[10];
  byte buffer[81];
  byte cmd_tail[128];
  word i;
  dword dw;

  // Initialize.

  source_arg[0] = '\0';       // initially nothing
  target_arg[0] = '\0';
  cmd_tail[0] = '\0';
  if(argc == 1)  {
    display_usage();
    exit(1);
    }

  // scan all command-line arguments.  first look for all switched
  // arguments.

  for(i=1; i<argc; ++i)  {
    if(!strcmp(argv[i], "/?")) {
      display_usage();
      exit(1);
      }
    strcat(cmd_tail, argv[i]);
    if(argv[i][0] == '/')  {
      strcpy(buffer, argv[i]);
      strupr(buffer);

      if(strchr("ADMSFQ",buffer[1]) == NULL) {
        printf("EXPORT: Unknown option [ %s ]\n", buffer);  // @@xlatn
        exit(1);
        }
      }
    else  {
      if(!strlen(source_arg))  {
        strcpy(source_arg, argv[i]);
        strupr(source_arg);
        cptr = strchr(source_arg, '/');
        if(cptr)  {
          *cptr = '\0';
          }
        }
      else  {
        if(!strlen(target_arg))  {
          strcpy(target_arg, argv[i]);
          strupr(target_arg);
          cptr = strchr(target_arg, '/');
          if(cptr)  {
            *cptr = '\0';
            }
          }
        else  {
          puts("IMPORT: Unknown command-line parameter.");    // @@xlatn
          exit(1);
          }
        }
      }
    }

  // get command line options.

  strupr(cmd_tail);
  if(strstr(cmd_tail, "/A"))  {
    A_flag = 1;
    }
  if(strstr(cmd_tail, "/M"))  {
    M_flag = 1;
    }
  if(strstr(cmd_tail, "/S"))  {
    S_flag = 1;
    }
  if(strstr(cmd_tail, "/F"))  {
    F_flag = 1;
    }
  if((cptr = strstr(cmd_tail, "/D")) != NULL)  {
    cptr += 2;
    if(*cptr != ':')  {
      syntax_error("/D option");
      exit(1);
      }
    cptr++;
    start_date[1] = atoi(cptr);
    cptr = strchr(cptr, '-');
    if(start_date[1] < 1 || start_date[1] > 12 || !cptr)  {
      syntax_error("/D option");
      exit(1);
      }
    start_date[2] = atoi(++cptr);
    cptr = strchr(cptr, '-');
    if(start_date[2] < 1 || start_date[2] > 31 || !cptr)  {
      syntax_error("/D option");
      exit(1);
      }
    start_date[0] = atoi(++cptr);
    D_flag = 1;
    }

  // if the /q option was specified, all other options are cancelled.
  // get command line parameters manually.

  if(strstr(cmd_tail, "/Q"))  {
    Q_flag = 1;
    A_flag = 0;
    D_flag = 0;
    M_flag = 0;
    S_flag = 0;
    F_flag = 0;
    memset(start_date,0,14);
    source_arg[0] = '\0';
    target_arg[0] = '\0';
    }

  // now that the /? case has been handled, check for multiple tasks.

  if(ismos)  {

    // caution if more than one task

    regs.h.ah = 2;
    int86x(0xd4,&regs,&regs,&segregs);
    SETDWORD(dw,segregs.es,regs.x.bx);
    if(*dw.wptr != *(dw.wptr+1)) {
      printf(
      "\n"
      "WARNING: Multiple tasks exist.\n"				       // @@xlatn
      "         Corruption of backup data possible if files exported\n"  // @@xlatn
      "         are currently open by another application.\n"	       // @@xlatn
      "         For safety, remove all other tasks and run EXPORT\n"     // @@xlatn
      "         from task 0.\n"					       // @@xlatn
      "\n"
      "         Do you wish to continue? (Y/N): "                        // @@xlatn
      );
      if(getyesno() == 0)  {
        puts("\nEXPORT: Terminated by user.\n");    // @@xlatn
        exit(1);
        }
      }
    }

  // end of argument processing.
  // now, was the /q flag set indicating manual input of options?

  if(Q_flag)  {
    puts(">> Enter options manually <<\n"); // @@xlatn

    // verify input at the time the user does it.

    printf("Enter source path (e.g. C:\\*.* ): ");  // @@xlatn
    gets(source_arg);
    strupr(source_arg);
    do  {
      printf("Enter target drive: "); // @@xlatn
      gets(target_arg);
      strupr(target_arg);
      if(!isalpha(target_arg[0]) || target_arg[1] != ':' || strlen(target_arg) > 2) {
        puts("Invalid drive specified.");   // @@xlatn
        }
      else  {
        break;
        }
      } while(1);
    printf("Archive subdirectories? (Y/N): ");  // @@xlatn
    if(getyesno())  {
      S_flag = 1;
      printf("Apply alternate file selection method? (Y/N): ");  // @@xlatn
      if(getyesno())  {
        F_flag = 1;
        }
      else  {
        F_flag = 0;
        }
      }
    else  {
      S_flag = 0;
      }
    do  {
      printf("Enter file selection option:\n\n"); // @@xlatn
      printf("A - Back up ALL files in path.\n"); // @@xlatn
      printf("M - Files modified since last back up.\n"); // @@xlatn
      printf("D - Files modified after a specific date.\n\n");    // @@xlatn
      printf("Enter option: ");   // @@xlatn
      ans[0] = 2;
      cgets(ans);
      printf("\n");
      ans[2] = toupper(ans[2]);
      switch(ans[2])  {
      case 'M':
        M_flag = 1;
        break;
      case 'D':
        printf("\nEnter date. (MM/DD/YY): ");   // @@xlatn
        scanf("%d/%d/%d", &start_date[1], &start_date[2], &start_date[0]);
        break;
      case 'A':
        break;
      default:
        puts("*** Invalid option. Try again. ***"); // @@xlatn
        continue;
        }
      break;
      } while(1);

    // does the user want to append to data on the diskette?

    do  {
      printf("Enter (O) to overwrite diskette or (A) to append to it: "); // @@xlatn
      ans[0] = 2;
      cgets(ans);
      printf("\n");
      ans[2] = toupper(ans[2]);
      switch(ans[2]) {
      case 'O':
        A_flag = 0;
        break;
      case 'A':
        A_flag = 1;
        break;
      default:
        puts("*** Invalid option. Try again. ***"); // @@xlatn
        continue;
        }
      break;
      } while(1);
    }

  // check validity of command line options.  (they will have already
  // been checked if the user entered them manually.

  fatal_error = 0;
  if(!isalpha(target_arg[0]) || target_arg[1] != ':' || strlen(target_arg) > 2)  {
    puts("EXPORT: Target must be a drive ONLY. (Ex. A:)");  // @@xlatn
    fatal_error = 1;
    }
  else  {
    target_drive = target_arg[0] - 'A' + 1;
    }
  if(F_flag == 1 && S_flag == 0) {
    puts("EXPORT: /f switch only valid when /s is used");  // @@xlatn
    fatal_error = 1;
    }
  if(fatal_error)  {
    puts("\nEXPORT: Due to errors, cannot continue.");  // @@xlatn
    puts("          EXPORT terminated.");   // @@xlatn
    exit(1);
    }
  }

/*======================================================================
;,fs
; int main(int argc, char *argv[])
; 
; in:	
;
; out:	
;
;,fe
========================================================================*/
int main(int argc, char *argv[]) {

  byte drive[MAXDRIVE];
  byte dir[MAXDIR];
  byte fname[MAXFILE];
  byte ext[MAXEXT];
  byte pathname[MAXPATH];
  byte ans[10];
  DTA ffblk;				// structure for findfirst/next
  fspc_type fs;
  byte srchspec[13];
  word attr;

  atexit(terminate);

  ismos = ul_ismos();
  if(ismos)  {

    // setup pointer for default class

    regs.h.ah = 4;
    regs.x.bx = 0xffff;
    int86x(0xd4,&regs,&regs,&segregs);
    SETDWORD(tcbcdftPtr,segregs.es,0x7f);
    origcdft = *tcbcdftPtr.bptr;
    }
  setup_i2324();
  parse_command_line(argc, argv);

  // if the /a (append) flag was not set, then warn the user.

  if(A_flag)  {
    printf(
    "\n"
    "NOTE: EXPORTed files will be appended to the data\n"  // @@xlatn
    "      already existing on drive %s.\n"                // @@xlatn
    "\n"
    "      Do you wish to continue? (Y/N): ", target_arg   // @@xlatn
    );
    if(getyesno() == 0)  {
      puts("\nEXPORT: Terminated by user.\n");    // @@xlatn
      exit(1);
      }
    }
  else {
    printf(
    "\n"
    "WARNING: All files on drive %s will be DELETED.\n"     // @@xlatn
    "\n"
    "         Do you wish to continue? (Y/N): ", target_arg // @@xlatn
    );
    if(getyesno() == 0)  {
      puts("\nEXPORT: Terminated by user.\n"); // @@xlatn
      exit(1);
      }
    }
  file_count = 0;
  disk_count = get_next_disk(0);

  // if the spec is a directory all by itself, use *.* for the search
  // spec.

  attr = _chmod(source_arg,0);
  if(attr != 0xffff && attr & FA_DIREC) {
    strcpy(pathname,source_arg);
    strcpy(srchspec,"*.*");
    }
  else {
    fnsplit(source_arg,drive,dir,fname,ext);
    strcpy(pathname,drive);
    strcat(pathname,dir);
    strcpy(srchspec,fname);
    strcat(srchspec,ext);
    }
  fs.search_spec = srchspec;

  // setup for the different type of searches

  if(S_flag)  {
    fs.search_attr = 0x10;
    if(F_flag) {
      fs.work_func = process_file3;
      fs.search_spec = "*.*";
      p2_spec = srchspec;
      ul_form_template(p2_spec,p2_norm);
      }
    else {
      fs.work_func = process_file2;
      p2_spec = "*.*";
      }
    }
  else  {
    fs.search_attr = 0;
    fs.work_func = process_file1;
    }

  // call ul_trace_dir() to process the export.

  if(ul_trace_dir(pathname,&fs)) {
    puts("EXPORT: Could not find source path."); // @@xlatn
    exit(1);
    }

  // if some files were backed up, write the final label to 
  // the disk in the target drive.

  if(file_count > 0)  {
    sprintf(buffer, "EX-L%04d", disk_count);
    ul_write_dsklbl(target_drive, buffer);
    printf("EXPORT: %d files backed up to %s\n", file_count, target_arg); // @@xlatn
    }
  else  {
    puts("EXPORT: No files found to be exported."); // @@xlatn
    exit(1);
    }
  return(0);
  }

