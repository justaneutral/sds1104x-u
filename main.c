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

#define __BUFFER_BYTE_LEN__ (4*1024 + 4*7*1024*1024)
#define __BUFFER_BYTE_OFFSET__ (1024)
#define __BUFFER_BYTE_CHANNAL_LEN__ ((__BUFFER_BYTE_LEN__-__BUFFER_BYTE_OFFSET__)>>2)
#define __BUFFER_CH0_START__ (__BUFFER_BYTE_OFFSET__)
#define __BUFFER_CH1_START__ (__BUFFER_CH0_START__+__BUFFER_BYTE_CHANNAL_LEN__)
#define __BUFFER_CH2_START__ (__BUFFER_CH1_START__+__BUFFER_BYTE_CHANNAL_LEN__)
#define __BUFFER_CH3_START__ (__BUFFER_CH2_START__+__BUFFER_BYTE_CHANNAL_LEN__)
#define buffer (&buffer_top[buffer_index*__BUFFER_BYTE_LEN__])
#define buffer0 (&(buffer[__BUFFER_CH0_START__]))
#define buffer1 (&(buffer[__BUFFER_CH1_START__]))
#define buffer2 (&(buffer[__BUFFER_CH2_START__]))
#define buffer3 (&(buffer[__BUFFER_CH3_START__]))

int main(void) {
    ViSession defaultRM = VI_NULL, instr = VI_NULL;
    ViStatus status;
    ViUInt32 retCount;
    int buffer_index = 0;
    char *buffer_top = (char*)malloc(2*__BUFFER_BYTE_LEN__);
    if(!buffer_top)
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
    /////////////////////////////////////////////////////////////////

    if(-1==viwrite_str(instr, (ViBuf)"*IDN?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"*SAV 20\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"*RST\n")) goto _rtn;
    usleep(5000000);
    if(-1==viwrite_str(instr, (ViBuf)"*OPC?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"*RCL 20\n")) goto _rtn;
    printf("Setup\n");
    if(-1==viwrite_str(instr, (ViBuf)"CHDR OFF\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"MSIZ 7M\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"MSIZ?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"TDIV 1S\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"HMAG 100US\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"HPOS 0US\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"SET50\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"TRMD SINGLE\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"TRMD STOP\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"TRDL 0\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"TRWI 10V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"TRPA C1,L,C2,L,C3,L,C4,L,STATE,OR\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"TRSE EDGE,SR,C1,HT,OFF,HV,0,HV2,0\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"TRSE?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"BWL C1,ON,C2,ON,C3,ON,C4,ON\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:TRCP AC\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:TRLV 0mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:TRLV2 0mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:TRSL WINDOW\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:ATTN 1\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:CPL A50\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"C1:CPL GND\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:OFST +0V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:SKEW 0.00E-00S\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:TRA ON\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:UNIT V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:VDIV 5mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C1:INVS OFF\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:TRCP AC\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:TRLV 0mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:TRLV2 0mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:TRSL WINDOW\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:ATTN 1\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:CPL A50\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:OFST +0V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:SKEW 0.00E-00S\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:TRA ON\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:UNIT V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:VDIV 5mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C2:INVS OFF\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:TRCP AC\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:TRLV 0mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:TRLV2 0mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:TRSL WINDOW\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:ATTN 1\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:CPL A50\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:OFST +0V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:SKEW 0.00E-00S\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:TRA ON\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:UNIT V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:VDIV 5mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C3:INVS OFF\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:TRCP AC\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:TRLV 0mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:TRLV2 0mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:TRSL WINDOW\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:ATTN 1\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:CPL A50\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:OFST +0V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:SKEW 0.00E-00S\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:TRA ON\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:UNIT V\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:VDIV 5mV\n")) goto _rtn;
    if(-1==viwrite_str(instr, (ViBuf)"C4:INVS OFF\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"WFSU SP,10000,NP,35,FP,0,SN,0\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"WFSU SP,65536,NP,96,FP,0,SN,0\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"STOP\n")) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"INR?\n")) goto _rtn;
    //if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    //if(-1==viwrite_str(instr, (ViBuf)"INR?\n")) goto _rtn;
    //if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    if( 0!=set_attribute(instr, VI_ATTR_TMO_VALUE, 30000)) goto _rtn;
    //usleep(5000);
    if(-1==viwrite_str(instr, (ViBuf)"SANU? C1\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    float num_samples,samples_per_second,duration_seconds;
    unsigned int acq_delay_us;
    sscanf(buffer,"%g",&num_samples);
    if(-1==viwrite_str(instr, (ViBuf)"SARA?\n")) goto _rtn;
    if(-1==(retCount=viread_str(instr, buffer, __BUFFER_BYTE_LEN__))) goto _rtn;
    sscanf(buffer,"%g",&samples_per_second);
    duration_seconds = num_samples/samples_per_second;
    acq_delay_us = 500000 + (unsigned long)(1000000.0*duration_seconds);
    printf("\nSamples per channel = %g\, sample rate per second = %g, duration_seconds = %f, acq_delay_us = %lu\n\n", num_samples,samples_per_second,duration_seconds,acq_delay_us);
    if(-1==viwrite_str(instr, (ViBuf)"WFSU SP,100000,NP,70,FP,0,SN,0\n")) goto _rtn;
    usleep(5000);
    //main loop
    char key = ~'q';
    int loop_counter = 4;
    //struct termios orig_termios;
    //set_non_blocking_mode(&orig_termios);
    //int ready;
    if(-1==viwrite_str(instr, (ViBuf)"ARM\n")) goto _rtn;
    while(key != 'q' && loop_counter--) 
    {
        usleep(acq_delay_us);
        if(-1==viwrite_str(instr, (ViBuf)"C1:WF? DAT2\n")) goto _rtn;
        if(-1==(retCount=viread_str(instr, buffer0, __BUFFER_BYTE_LEN__))) goto _rtn;
        if(-1==viwrite_str(instr, (ViBuf)"C2:WF? DAT2\n")) goto _rtn;
        if(-1==(retCount=viread_str(instr, buffer1, __BUFFER_BYTE_LEN__))) goto _rtn;
        if(-1==viwrite_str(instr, (ViBuf)"C3:WF? DAT2\n")) goto _rtn;
        if(-1==(retCount=viread_str(instr, buffer2, __BUFFER_BYTE_LEN__))) goto _rtn;
        if(-1==viwrite_str(instr, (ViBuf)"C4:WF? DAT2\n")) goto _rtn;
        if(-1==(retCount=viread_str(instr, buffer3, __BUFFER_BYTE_LEN__))) goto _rtn;
        //print_buf(buffer0,0,retCount-1,16,1);
        //print_buf(buffer1,1,retCount-1,16,1);
        //print_buf(buffer2,2,retCount-1,16,1);
        //print_buf(buffer3,3,retCount-1,16,1);
        print_waveforms(buffer,__BUFFER_BYTE_OFFSET__,__BUFFER_BYTE_CHANNAL_LEN__);


        //check keystrokes
        //if (read(STDIN_FILENO, &key, 1) > 0)
        //{
        //    printf("Key pressed: '%c' (ASCII: %d)\n", key, key);
        //}
        fflush(stdout);
        //next acquistion start
        if(-1==viwrite_str(instr, (ViBuf)"ARM\n")) goto _rtn;
    }
    //restore_mode_and_blocking(&orig_termios);
    printf("\n***end***\n");
    // --- End device communication logic ---
_rtn:
    // Close the VISA device using the function from close_device.c
    close_device(defaultRM, instr);
_stp:
    free(buffer_top);
    return 0;
}

