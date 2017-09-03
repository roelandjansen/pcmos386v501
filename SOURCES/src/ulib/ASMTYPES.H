/*=====================================================================
               (c) copyright 1992, the software link inc.
                       all rights reserved

 module name:        asmtypes.h
 task name:          various modules
 creation date:      04/01/92
 revision date:      04/01/92
 author:             mjs
 description:        assembler-like typedefs

======================================================================

mjs 04/01/92	created this module.

=======================================================================
*/

/*==== assembler equivelant storage types ====*/

typedef unsigned char byte;
typedef unsigned int word;

#define a_ofs 0
#define a_seg 1
typedef union {
  word h[2];			/* access to each half of the ptr */
  byte far *bptr;		/* ptr for a byte operation */
  word far *wptr; 		/* ptr for a word operation */
  unsigned long far *lptr;	/* ptr for a long */
  void far *vptr;		/* for ptr to ptr copies */
  long li;			/* double word numbers */
  void far (*ffptrv)();		/* ptr to far function returning void */
  word far (*ffptri)();		/* ptr to far function returning word */
  } dword;

#define SETDWORD(x,s,o) (x).h[a_seg]=s; (x).h[a_ofs]=o
#define DSEG(x) (x).h[a_seg]
#define DOFS(x) (x).h[a_ofs]

/*==== declare the existance of this module */

#define asmtypes 1

