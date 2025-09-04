#ifndef VISA_UTIL_H
#define VISA_UTIL_H

#include "visa.h"
#include "visa_util.h"

// Function to open the VISA device
ViStatus open_device(ViSession* defaultRM, ViSession* instr, const char* resourceName);

// Function to close the VISA sessions
void close_device(ViSession defaultRM, ViSession instr);

#endif // VISA_UTIL_H

#include <stdio.h>
#include "visa_util.h"

#define __BUFFER_BYTE_LEN__ (7*1024*1024)
#define __BUFFER_BYTE_OFFSET__ (1024)
#define __BUFFER_BYTE_CHANNAL_LEN__ ((__BUFFER_BYTE_LEN__-__BUFFER_BYTE_OFFSET__)>>2)
#define __BUFFER_CH0_START__ (__BUFFER_BYTE_OFFSET__)
#define __BUFFER_CH1_START__ (__BUFFER_CH0_START__+__BUFFER_BYTE_CHANNAL_LEN__)
#define __BUFFER_CH2_START__ (__BUFFER_CH1_START__+__BUFFER_BYTE_CHANNAL_LEN__)
#define __BUFFER_CH3_START__ (__BUFFER_CH2_START__+__BUFFER_BYTE_CHANNAL_LEN__)
#define buffer0 (&(buffer[__BUFFER_CH0_START__]))
#define buffer1 (&(buffer[__BUFFER_CH1_START__]))
#define buffer2 (&(buffer[__BUFFER_CH2_START__]))
#define buffer3 (&(buffer[__BUFFER_CH3_START__]))

int main(void) {
    ViSession defaultRM = VI_NULL, instr = VI_NULL;
    ViStatus status;
    ViUInt32 retCount;
    char *buffer = (char*)malloc(__BUFFER_BYTE_LEN__);
    if(!buffer)
    {
        return -2;
    }

    const char* resourceName = "USB0::0xF4EC::0x1012::SDSAHBAX6R0452::INSTR";

    // Open the VISA device using the function from open_device.c
    status = open_device(&defaultRM, &instr, resourceName);
    if (status < VI_SUCCESS) {
       goto _stp;
    }

    printf("Successfully opened session to %s.\n", resourceName);

    // --- Device communication logic ---
    
    if(-1==viwrite_str(instr, (ViBuf)"*IDN?\n")) goto _rtn;
    // Read the response
    status = viRead(instr, (ViBuf)buffer, sizeof(buffer), &retCount);
    if (status < VI_SUCCESS) {
        printf("Error reading from the device. Status: %ld\n", status);
        close_device(defaultRM, instr);
        return -1;
    }
    buffer[retCount] = '\0'; // Null-terminate the string
    printf("Device Response: %s\n", buffer);
    

    /////////////////////////////////////////////////////////////////

    if(-1==viwrite_str(instr, (ViBuf)"*IDN?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"*SAV 20\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"*RST\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"*OPC?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"*RCL 20\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"CHDR OFF\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)":C1 ON\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)":C1:DISP OFF\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)":C2 OFF\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)":C3 OFF\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)":C4 OFF\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)":C1:PROB 1X\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)":C1:SCAL 2.0\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)":TIM:SCAL 1e-6\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)":ACQ:MODE NORM\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)":ACQ:POIN:MODE NORM\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)":ACQ:MEMD 14M\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"\ACQuire:POINts 3500\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"*WAI\n")) goto _rtn;

    printf("Arm and see the state:\n");
    if(-1==viwrite_str(instr, (ViBuf)"TRSE EDGE,SR,C1,HT,OFF,HV,0,HV2,0\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"BWL C1,ON,C2,ON,C3,ON,C4,ON\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:TRCP AC\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:ATTN 1\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:CPL A50\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:OFST +0V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:SKEW 0.00E-00S\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:TRA ON\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:UNIT V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:VDIV 2V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:INVS OFF\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:TRCP AC\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:ATTN 1\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:CPL A50\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:OFST +0V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:SKEW 0.00E-00S\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:TRA ON\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:UNIT V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:VDIV 2V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:INVS OFF\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:TRCP AC\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:ATTN 1\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:CPL A50\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:OFST +0V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:SKEW 0.00E-00S\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:TRA ON\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:UNIT V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:VDIV 2V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:INVS OFF\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:TRCP AC\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:ATTN 1\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:CPL A50\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:OFST +0V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:SKEW 0.00E-00S\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:TRA ON\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:UNIT V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:VDIV 2V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:INVS OFF\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"TRLV 0\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"TRMD SINGLE\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"TRMD STOP\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"TRDL 0\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"STOP\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"INR?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"INR?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)":ARM\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"*OPC?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"INR?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"INR?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    
    if(-1==viwrite_str(instr, (ViBuf)"MSIZ 7M\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"MSIZ?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    //print_buf(buffer,0,1024,0,0);
    
    
    // Read the response
    if( 0!=set_attribute(instr, VI_ATTR_TMO_VALUE, 10000)) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"WFSU SP,100,NP,50,FP,0,SN,0\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"INR?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)":ARM\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"*OPC?\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"INR?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:WF? DAT2\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer0, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:WF? DAT2\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer1, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:WF? DAT2\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer2, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:WF? DAT2\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer3, __BUFFER_BYTE_LEN__))) goto _rtn;
    print_buf(buffer0,0,retCount-1,16,1);
    print_buf(buffer1,1,retCount-1,16,1);
    print_buf(buffer2,2,retCount-1,16,1);
    print_buf(buffer3,3,retCount-1,16,1);
    //int NumBytesInMemory=get_binary_block_length(buffer);
    //printf("Received %d sample bytes\n",NumBytesInMemory);
    
    //int NumBytesTransferred = 0;//retCount - 29;
    //printf("Hold %d sample bytes\n", NumBytesTransferred);
    //while(NumBytesTransferred< NumBytesInMemory)
    //{
    //    if(-1==(retCount=viread_buf(instr, &(buffer[NumBytesTransferred]), NumBytesInMemory-NumBytesTransferred))) goto _rtn;
    //    NumBytesTransferred += retCount;
    //    printf("Transferred %d bytes\n", retCount);
    //}
    //printf("Total transferred %d bytes\n", NumBytesTransferred);
    //printf("Device Response: %s\n", buffer);
   
    //if(strlen(buffer)<retCount)
    //{
    //    for(int i=0;i<retCount;i++)
    //    {
    //        char b = buffer[i];
    //        printf("%hhx",b);
    //    }
    //}
    //printf("\n now convert to samples\n");

    //float *samples = (float *)malloc(retCount);
    //convert_buffer_to_samples(buffer, retCount, samples, 2, 1.0, 0.0);
    //for(int i=0;i<retCount;i++)
    //{
    //    float s = samples[i];
    //    printf("%f",s);
    //}
    printf("\n***end***\n");
   


    // --- End device communication logic ---
_rtn:
    // Close the VISA device using the function from close_device.c
    close_device(defaultRM, instr);
_stp:
    free(buffer);
    return 0;
}


