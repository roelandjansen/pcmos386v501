/*=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        summary.h
 task name:          install.exe and hdsetup.exe
 creation date:      02/27/92
 revision date:      04/01/92
 author:             mjs
 description:        data format for hdsetup.sum summary file

======================================================================

mjs 04/01/92	created this module

=======================================================================*/

#define SUMMARY_FNAME "hdsetup.sum"

// NOTE: the wmask string is the write mask for fprintf (within hdsetup)
// and the rmask string is the read mask for sscanf (within install).
// if you change one, make parallel changes to the other.

#define SUMMARY_WMASK "    %01d   %02d    %01d   %5s    %c      %c    %05d %05d %05d %05d   %c\n"
#define SUMMARY_RMASK "%d %d %d %5s %c %c %d %d %d %d %c"

struct sumtype {
  struct sumtype *next;
  word hdrive;
  word ptnum;
  word ptentry;
  byte pttype[6];
  byte drvletter;
  byte bootstatus;
  word megs;
  word cylds;
  word startcyld;
  word endcyld;
  byte febpb;
  };

typedef struct sumtype sum_type;


