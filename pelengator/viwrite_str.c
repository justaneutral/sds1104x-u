#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "visa_util.h"

ViUInt32 viwrite_str(ViSession instr, ViBuf buffer)
{
    ViUInt32 retCount;
    ViStatus status = viWrite(instr, (ViBuf)buffer, strlen((char*)buffer), &retCount);
    if (status < VI_SUCCESS)
    {
        printf("Error writing to the device: %s , Status: %ld\n", (char*)buffer, status);
        //close_device(defaultRM, instr);
        return -1;
    }
    //printf("viWrite(%d): %s\n",strlen(buffer),buffer);
    return retCount;
}
