#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "visa_util.h"


ViUInt32 viread_buf(ViSession instr, char *buffer,ViUInt32 requested_bytes)
{
    ViUInt32 retCount;
    ViStatus status = viRead(instr, (ViBuf)buffer, requested_bytes, &retCount);
    if (status < VI_SUCCESS)
    {
        printf("Error reading from the device. Status: %ld\n", status);
        //close_device(defaultRM, instr);
        return -1;
    }
    //printf("viRead(%d read / %d requested bytes): ",retCount,requested_bytes);
    //unsigned int plen = (retCount>64)? 64 : retCount;
    //print_buf(buffer,0, plen);
    return retCount;
}


