/*
	HEADER:		CUG000.00;
	TITLE:		Entab/Detab/Strip Combo;
	DATE:		05/17/1987;
	DESCRIPTION:	"Strips upper-order bits, detabifies, then entabifies a
			text file.  Old and new tab increments can differ.  If
			new increment is 1, no entabification occurs.";
	VERSION:	0.0;
	KEYWORDS:	Tab, Tabs, Tab Expansion, Tab Utility, Tabify, Untab,
			Detab, Detab Utility;
	FILENAME:	RETAB.C;
	COMPILERS:	vanilla;
	AUTHORS:	W. C. Colley III;
*/

/*
			 Tab Size Readjustment Program

		   Copyright (c) 1987 William C. Colley, III

This program combines the functions of an ENTAB program and a DETAB program
in the same program.  Combining the two allows a simple means of retabifying
a program.  For example, let's say you edit a C program with your editor set
for a tab increment of 4.  Now, you TYPE this file on the console and you find
that it laps over the right edge of the screen because your terminal expands
tabs with a tab increment of 8.	 What you really would like to do is delete
some of the tabs so that your program will TYPE just like it looked inside the
editor.	 The following command will do just that:

	RETAB -O4 -N8 oldfile newfile

In the above command line, the two file names must be in order, but the -
options can be spread around anywhere.	In fact, the - options are optional.
Their default values are set by a pair of #defines below.  The -O option
specifies the tab increment that the old file was created with.	 The -N option
specifies the desired tab increment of the new file.

Note that or -N1 causes no entabification.  Thus, the following command will
detabify a file:

	RETAB -O8 -N1 oldfile newfile

Also note that if the old file contains no tabs, there will be no
detabification.	 Thus, the following command will entabify a detabified file:

	RETAB -N8 oldfile newfile

Blanks and tabs in quoted strings are left alone.  The C conventions regarding
character constants like '"' and character strings like "Here\'s a \"quote\"."
are supported.
*/

#include <stdio.h>

/*  Uncomment the following #defines if you are using an AZTEC C compiler:  */

/*
#define getc(x)	    agetc(x)
#define putc(x,y)   aputc(x,y)
*/

/*  User-adjustable default values:					    */

#define OLDTABS	    4	    /*	Default old tab increment.		    */
#define NEWTABS	    8	    /*	Default new tab increment.		    */

#define NORMAL	    0	    /*	Normal state.				    */
#define QUOTE	    1	    /*	Quoted string skip state.		    */
#define BLANK	    2	    /*	Blank parsing state.			    */

int main(argc,argv)
int argc;
char **argv;
{
    int del, i, j, atoi();
    FILE *old, *new;
    static char *oldfile = NULL, *newfile = NULL;
    static int err = 0, oldtabs = OLDTABS, newtabs = NEWTABS;
    static int blnks = 0, col = 0, lit = 0, state = NORMAL;

    while (--argc) {
	if (**++argv == '-') {
	    switch (i = *(*argv + 1)) {
		case 'n':
		case 'N':   if ((i = atoi(*argv + 2)) < 1) {
				printf("ERROR:  New tab increment < 1\n\n");
				err = !0;
			    }
			    else newtabs = i;
			    break;

		case 'o':
		case 'O':   if ((i = atoi(*argv + 2)) < 1) {
				printf("ERROR:  Old tab increment < 1\n\n");
				err = !0;
			    }
			    else oldtabs = i;
			    break;

		default:    printf("ERROR:  Illegal option %s\n\n",*argv);
			    err = !0;  break;
	    }
	}
	else if (!oldfile) oldfile = *argv;
	else if (!newfile) newfile = *argv;
	else {
	    printf("ERROR:  Extra filename %s\n\n",*argv);
	    err = !0;
	}
    }
    if (!oldfile || !newfile) {
	printf("Usage:\tRETAB { -Onn } { -Nnn } oldfile newfile\n\n");
	err = !0;
    }
    else if (!(old = fopen(oldfile,"r"))) {
	printf("ERROR:  Cannot find file %s\n\n",oldfile);
	err = !0;
    }
    else {
	if (!(new = fopen(newfile,"w"))) {
	    printf("ERROR:  Cannot create file %s\n\n",newfile);
	    err = !0;
	}
	else {
	    while ((i = getc(old)) != EOF) {
		switch (state) {
		    case NORMAL:    switch (i) {
					case '\n':  col = 0;  putc('\n',new);
						    break;

					case '\t':  blnks = oldtabs -
							col % oldtabs;
						    state = BLANK;  break;

					case ' ':   blnks = 1;	state = BLANK;
						    break;

					case '\'':  del = '\'';	 goto quote1;

					case '"':   del = '"';
quote1:						    if (!lit) state = QUOTE;

					default:    ++col;  putc(i,new);
						    break;
				    }
				    break;

		    case QUOTE:	    switch (i) {
					case '\n':  if (!lit) state = NORMAL;
						    col = 0;  break;

					case '\t':  col += newtabs -
							col % newtabs;
						    break;

					case '\'':
					case '"':   if (!lit && i == del)
							state = NORMAL;

					default:    ++col;  break;
				    }
				    putc(i,new);  break;

		    case BLANK:	    switch (i) {
					case '\t':  blnks += oldtabs - (col +
							blnks) % oldtabs;
						    break;

					case ' ':   ++blnks;  break;

					case '"':   del = '"';	goto quote2;

					case '\'':  del = '\'';
quote2:						    state = QUOTE;  goto entab;

					default:    state = NORMAL;
entab:						    if (blnks > 1 &&
							newtabs > 1)
							while ((j = newtabs -
							    col % newtabs)
							    <= blnks) {
							    col += j;
							    blnks -= j;
							    putc('\t',new);
							}
						    for (; blnks; --blnks) {
							++col;	putc(' ',new);
						    }
						    if (i == '\n') col = 0;
						    else ++col;
						    putc(i,new);  break;
				    }
				    break;
		}
		lit = !lit && i == '\\';
	    }
	    if (ferror(new) || fclose(new)) {
		printf("ERROR:  Disk full\n\n");
		err = !0;
	    }
	}
	fclose(old);
    }
    return err;
}

