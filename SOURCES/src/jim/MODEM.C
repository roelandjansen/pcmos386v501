
#define MODEM_STR_LEN 50	/* length of modem init string table entry */
long offset_speed=0x2218;	/* offset into modem.com of speed table */
long offset_init_str=0x222c;	/* offset into modem.com of modem_init_string
									table */

#include <stdio.h>
#include <color.h>
#include "keydef.h"

/*
	MODEM initialize a modem port and modem for dialin

	generate using Aztec compiler system:
		cc modem
		ln -b 100 -o modem.com modem.o s.lib c.lib

	Update 07/13/89 SAH to include all of PMU functions into MODEM.COM
*/

/*	following tables externalized so addresses are in map for PMU	*/

unsigned modem_speed[10] = {300,1200,2400,9600,0,0,0,0,0,0}; /* transmission speed */
unsigned char modem_init_str[10][50]= {
	{'A','T',' ','E','0',' ','Q','1',0x0d,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, /* 300 bps */
	{'A','T',' ','E','0',' ','Q','1',' ','S','0','=','1',0x0d,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},	/* 1200 bps Hayes */
	{'A','T',' ','E','0',' ','Q','1',' ','S','0','=','1',' ','&','D','3',0x0d,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},	/* 2400 bps Hayes */
	{'A','T',' ','E','0',' ','Q','1',' ','S','0','=','1',' ','&','D','3',0x0d,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},	/* 9600 bps Hayes */
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, /* extra */
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, /* extra */
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, /* extra */
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, /* extra */
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, /* extra */
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, /* extra */
};	/* end of array */

static char version[] ="4.00";
static char header[] ="Modem Initialization Program";
static unsigned char workbuffer[52];
static unsigned modem_speed_tab[10]={0,0,0,0,0,0,0,0,0,0};
static unsigned char mdmstrtab[10][50];
static unsigned char tbuf[6];	       /* temporary buffer */
static unsigned char modem_buffer[50]; /* buffer for modem init string */
static char mfile[] = "MODEM.COM";
static char EscKeys;
static FILE *fp;

main(argc,argv)
int argc;
char *argv[];
{

	struct regs {		/* registers for int 14 calls */
		unsigned ax;
		unsigned bx;
		unsigned cx;
		unsigned dx;
		unsigned di;
		unsigned si;
		unsigned ds;
		unsigned es;
		};

	struct regs *inregs;	/* pointer to register structure */
	struct regs *malloc();

	unsigned segregs[4];	/* array of segment registers */
	unsigned port;		/* port number */
	unsigned modem_type;	/* modem type */

	static unsigned fcn=0x14;		/* bios function */

	int i,j;	/* extra variables */
	char c;


if(argc < 2) {		/* check for command line count */
	fputs("No port or modem type specified!         ", stdout);  putchar('\n');
	fputs("Proper syntax is: MODEM x y       ", stdout);  putchar('\n');
	fputs("Where x=port number and y=modem type (0-9).          ", stdout); putchar('\n');
	fputs("Modem types are:   ", stdout);  putchar('\n');
	fputs("0 - Hayes  300  ", stdout);  putchar('\n');
	fputs("1 - Hayes 1200  ", stdout);  putchar('\n');
	fputs("2 - Hayes 2400  ", stdout);  putchar('\n');
	fputs("3 - Hayes 9600  ", stdout);  putchar('\n');
	fputs("Types 4 - 9 are user-definable.    ",  stdout);  putchar('\n');
	fputs("Version ", stdout);  fputs(version, stdout);  putchar('\n');
	putchar('\n');
	fputs("Enter 1 to edit modem initialization strings          ", stdout);
	putchar('\n');
	fputs("Enter 2 to return to MOS.                    ",stdout);
	putchar('\n');
	c = ' ';
	while (c != '2')
	{
	      c = scr_getc();
	      if (c == '1')
	      {
		    SetModem();
		    c = '2';
	      }
	      else if (c != '2')
		    scr_printf("\007");
	}
	putchar('\n');
	exit(3);	/* exit error code - no parms on command line */
	}

if(argv[2]==NULL) {	/* They didn't specify a port number */
	fputs("No modem type specified!           ", stdout);  putchar('\n');
	exit(2);
	}

inregs=NULL;		/* initialize */
inregs=malloc(sizeof(struct regs));
if(inregs==NULL) {
	fputs("Out of memory! Cannot allocate structure!     ", stdout);  putchar('\n');
	exit(1);
	}

port=atoi(argv[1]);	/* change the string to an integer */
modem_type=atoi(argv[2]);	/* same for the modem type */



segread(segregs);	/* read the segment registers */
inregs->si=inregs->di=0;	/* init si,di */
inregs->ds=segregs[2];		/* init ds */
inregs->es=segregs[3];		/* iniz es */

inregs->ax=0x0600;
inregs->dx=port-1;
i=sysint(fcn,inregs,inregs);
inregs->ax &= 0x8000;
if (inregs->ax!= 0x8000) {
	fputs("No serial driver installed!         ", stdout);  putchar('\n');
	exit(5);
	}

inregs->ax=0x0d00;
inregs->dx=port-1;
i=sysint(fcn,inregs,inregs);
if((inregs->ax &=0xff00) == 0xff00) {
	fputs("Invalid port number!           ", stdout);  putchar('\n');
	exit(4);
	}


inregs->ax=0x0403;	/* init the modem */
inregs->bx=modem_speed[modem_type];

inregs->cx=0;
inregs->dx=port-1;	/* set up the port */


i=sysint(fcn,inregs,inregs);	/* init the port */
inregs->ax &=0xff00;		/* clear al */
if(inregs->ax==0xff00) {
	fputs("Invalid port number!           ", stdout);  putchar('\n');
	exit(4);
	}

inregs->dx=port-1;	/* set the port number - just to be sure */
j=0;
while(modem_init_str[modem_type][j] != 0) {	/* send the string */
	inregs->ax=0x0100;
	inregs->ax |= modem_init_str[modem_type][j++];
	inregs->ax &= 0x01ff;	/* make sure ax is clean
	inregs->ax |= 0x0100;	/* this is the single character send */
	i=sysint(fcn,inregs,inregs);
	inregs->ax=0x0300;	/* do a status check */
	i=sysint(fcn,inregs,inregs);
	inregs->dx=port-1;
	}


inregs->ax=0x0a00;	/* see if there are any characters in the buffer */
inregs->dx=port-1;	/* if so, get them out */
i=sysint(fcn,inregs,inregs);
if(inregs->ax !=0) {
	j=inregs->ax;
	while(j-- !=0) {
		inregs->ax=0x0200;
		i=sysint(fcn,inregs,inregs);
		}
	}

free(inregs);	/* release the memory */
exit(0);	/* clean get away */
}	/* end of main */

/*****************************************************************************/

SetModem()
{

	int ca,g,i,j,k,l,row,col;
	unsigned char c,SayBye;
	long rwp;		/* read/write pointer */

if((fp=fopen(mfile,"r+"))==NULL) {
	ca=scr_getatr();		/* save the current screen attribute */
	scr_setatr(RED,WHITE,HIGH,NO_BLINK);	/* set new attribute */
	scr_clear();			/* clear the screen */

	/*  Warning message */

	scr_curs(11,28);			/* position the cursor */
	scr_printf("One or all of the files      ");
	scr_curs(12,5);
	scr_printf("MODEM.COM is NOT in the current directory   ");
	scr_curs(13,28);
	scr_printf("Press any key to terminate       ");

	c=scr_getc();
	scr_resatr(ca);
	scr_clear();
	fclose(fp);
	exit(1);
	}

k=0;
ca=scr_getatr();	/* save the current screen attribute */
j=0;
for(i=0;i<10;i++) {
     for(j=0;j<50;j++)
	   mdmstrtab[i][j]='\0';
      }

scr_setatr(BLUE,WHITE,HIGH,NO_BLINK);
scr_clear();
row=2;col=40-(strlen(header) / 2);
sbox(0,0,4,80);
scr_curs(row,col);
scr_printf("%s",header);
col=40-(strlen(version)/2);
scr_curs(++row,col);
scr_printf("%s",version);

scr_curs(7,0);		/* position cursor & clear to eos */
scr_eos();
scr_curs(6,30);
scr_printf("Currently defined types    ");
scr_curs(8,0);
scr_printf("  Type  ");
scr_curs(8,8);
scr_printf("  Modem Speed   ");
scr_curs(8,35);
scr_printf("Initialization string      ");
i=0;			/* print them out */
rwp=offset_speed;
fseek(fp,rwp,0L);	/* read the speed table */
j=fread(modem_speed_tab,2,10,fp);
j=fread(mdmstrtab,50,10,fp);
row=10;col=3;
for(i=0;i<10;i++) {
       scr_curs(row,col);
       scr_printf("%d",i);
       if(mdmstrtab[i][0] != '\0') {
	      scr_curs(row,col+10);
	      scr_printf("%d",modem_speed_tab[i]);
	      scr_curs(row++,col+25);
	      scr_printf("%s",mdmstrtab[i]);
	      }
	else {
	      scr_curs(row++,col+25);
	      scr_printf("<undefined>    ");
	     }
	}
scr_curs(22,2);
scr_printf("   Use the up/down arrow keys to position the cursor over the type number   ");
scr_curs(23,8);
scr_printf("   you wish to edit. Then press Enter to select, ESC to abort.   ");
row=10;col=3;
scr_curs(row,col);
i=0;

SayBye='N';
while(SayBye=='N') {
      c=scr_getc();
      switch(c) {
	   case(0x48 | 0x80):	   /* up arrow */
		row--;
		if(row<10)	/* effect a wrap */
		       row=19;
		scr_curs(row,col);
		break;

	   case(0x50 | 0x80):	   /* down arrow */
		row++;
		if(row>19)	/* wrap the cursor */
		       row=10;
		scr_curs(row,col);
		break;

	   case(0x0d):
		scr_curs(24,26);
		g=scr_getatr();
		scr_setatr(BLUE,GREEN,HIGH,BLINK);
		scr_printf("Enter the speed of the modem.   ");
		scr_resatr(g);
		EscKeys='Y';
		while (EscKeys=='Y')
		{
		    scr_curs(row,col+10);
		    scr_printf("     ");
		    scr_curs(row,col+10);
		    j=0;
		    j=getline(5,0);
		}
		for (i=0;i<6;i++)
		    tbuf[i]=workbuffer[i];
		modem_speed_tab[row-10]=atoi(tbuf);
		scr_curs(24,26);
		scr_eos();
		scr_curs(24,29);
		g=scr_getatr();
		scr_setatr(BLUE,GREEN,HIGH,BLINK);
		scr_printf("Enter Modem Init string    ");
		scr_resatr(g);
		EscKeys='Y';
		while (EscKeys=='Y')
		{
		     scr_curs(row,col+25);
		     scr_eol();
		     j=0;
		     if (mdmstrtab[row-10][0]=='\0')
			 j=getline(49,0);
		     else
		     {
			 i=0;
			 c=mdmstrtab[row-10][0];
			 while ((c != '\0') && (c != '\r'))
			 {
			      workbuffer[i]=mdmstrtab[row-10][i];
			      c=mdmstrtab[row-10][i++];
			  }
			  j=getline(49,i-1);
		    }
		}
		for (i=0;i<50;i++)
		    mdmstrtab[row-10][i]=workbuffer[i];
		if (j<48)
		     for(i=j+2;i<MODEM_STR_LEN;i++)
			 mdmstrtab[row-10][i]=0;
		scr_curs(24,26);
		g=scr_getatr();
		scr_setatr(BLUE,RED,HIGH,BLINK);
		scr_printf("Hit F3 to save, ESC to Exit     ");
		scr_resatr(g);
		while((c=scr_getc()) != (F3 | 0x80) && c != ESC)
			scr_printf("\007");

		scr_curs(24,0);
		scr_eol();
		if(c != ESC) {
			fseek(fp,offset_speed,0L);
			j=fwrite(modem_speed_tab,2,10,fp);
			fseek(fp,offset_init_str+((row-10)*MODEM_STR_LEN),0L);
			j=fwrite(mdmstrtab[row-10],50,1,fp);
			}
		else
		    SayBye='Y';

		fclose(fp);

		if (SayBye != 'Y')   {
		    if((fp=fopen(mfile,"r+"))==NULL) {
			terminate(mfile,ca);
			SayBye='Y';
			exit(3);
		    }
		}
		scr_curs(row,col);
		break;

	   case(ESC):
		fclose(fp);
		SayBye='Y';
		break;

	   default:
		 scr_printf("\007");
		 break;

	 }
}
scr_resatr(ca);
scr_clear();
}

/*****************************************************************************/

int getline(k,m)
int k,m;
{
	int l;
	unsigned char c;

if (m != 0)
     for (l=0;l<m;l++)
	scr_putc(workbuffer[l]);
l=m;
EscKeys='N';

while(l<k && (c=scr_getc()) != '\r') {	      /* get the name */
	if (c=='\b') {
		if (l>0) {
			l--;	/* edit with backspace */
			scr_printf("%c \b",c);
			}
		}

	else if (c==27) {
		EscKeys='Y';
		l = k;
		}
	else	{
		workbuffer[l++]=c;
		scr_putc(c);
		}

	}	/* close while loop */
workbuffer[l]='\r';
workbuffer[l+1]='\0';
return(l);
}	/* end of getline */
 


/*****************************************************************************/

fkeys(r,c,kn)
int r,c,kn;
{

	int ca;

ca=scr_getatr();
scr_setatr(BLUE,RED,HIGH,NO_BLINK);
sbox(r,c,2,5);
scr_curs(r+1,c+2);
scr_printf("F%d",kn);
scr_resatr(ca);
return;
}	/* end of fkeys */



/*****************************************************************************/

terminate(s,ca)
char *s;
int ca;
{

scr_curs(20,28);
scr_printf("\007Unable to open %s!    ",s);
scr_curs(21,34);
scr_printf("Hit any key!       ");
scr_getc();
scr_resatr(ca);
scr_clear();

}		/* end of terminate */


/******************************************************************************
* Draw a box, sr - start row, sc - start col, rc - row count, cc - col count  *
******************************************************************************/

sbox(sr,sc,rc,cc)
int sr,sc,rc,cc;
{
	int i;

scr_curs(sr,sc);
scr_putc(0xda);
for(i=1;i<cc;i++) {
	scr_curs(sr,sc+i);
	scr_putc(0xc4);
	}

scr_curs(sr++,sc+i);
scr_putc(0xbf);
for(i=0;i<rc-1;i++) {
	scr_curs(sr,sc);
	scr_putc(0xb3);
	scr_curs(sr++,sc+cc);
	scr_putc(0xb3);
	}

scr_curs(sr,sc);
scr_putc(0xc0);
for(i=1;i<cc;i++) {
	scr_curs(sr,sc+i);
	scr_putc(0xc4);
	}

scr_curs(sr,sc+cc);
scr_putc(0xd9);
return;
}	/* end of sbox */
