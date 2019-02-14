#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

int main()
{
	int rand_num=0;	
	time_t tseed;
	char buffer[11];
	char tmpbuf[6];
	int count=0;
	FILE *serfil=NULL;
	FILE *regfil=NULL;

	if((serfil = fopen("serial.inc", "w+")) == NULL)
	{
		printf("Error opening serial.inc\n");
		printf("Kernel will fail build\n");
		return -1;
	}
	/* Everybody gets 25 user licenses now */
	/* Followed by Version Number          */
	strcpy(buffer, "25502"); 
	strcpy(tmpbuf, "00000");

	/* Generate random serial number for   */
	/* last 5 digits.  We don't care if    */
	/* duplicates exist in the world, we   */
	/* aren't charging for this stuff!     */
	(void) time(&tseed);
	srand((unsigned int) tseed);

	rand_num=rand();

	itoa(rand_num, tmpbuf, 10);	

	/* Normalize random number to 5 digits */
	for(count=0; count<5; count++)
		if((tmpbuf[count] > '9') || (tmpbuf[count] < '0'))
			tmpbuf[count]='0';

	tmpbuf[5]='\n';
	strncat(buffer, tmpbuf, 5);

	fprintf(serfil, "enbedded\tdb\t'%s'\n", buffer);

	(void) fclose(serfil);

	/*  Create registration script        */

	if((regfil = fopen("regist.bat", "w+")) == NULL)
	{
		printf("Error createing regist.bat\n");
		printf("Registration will fail\n");
		return -2;
	}

	fprintf(regfil, "snreg.com /I %s 1 > c:\\distro\\regme.bat\n", buffer);

	(void) fclose(regfil);

	return 0;
}
