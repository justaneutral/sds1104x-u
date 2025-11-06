#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "visa_util.h"


void printcx(char *buffer, int start, int stop)
{
	for(int i= start; i<=stop; i++)
	{
		char smb = buffer[i];
		if(isprint(smb)) printf("%c", smb);
                else printf("(%hhx)", smb);
	}
}


ViUInt32 viread_str(ViSession instr, char *buffer,ViUInt32 requested_bytes)
{
    ViUInt32 retCount;
    ViStatus status = viRead(instr, (ViBuf)buffer, requested_bytes, &retCount);
    if (status < VI_SUCCESS)
    {
        printf("Error reading from the device. Status: %d\n", status);
        //close_device(defaultRM, instr);
        return -1;
    }
    printf("viRead(%d read / %d requested bytes): ",retCount,requested_bytes);
    if(retCount>0)
    {
	unsigned int cup = retCount>32 ? 32 : retCount;
	printcx(buffer,0,cup-1);
	if(retCount>cup)
	{
		printf(" .... ");
		printcx(buffer,retCount-3,retCount-1);
	}
	printf("\n");
    }
    return retCount;
}


