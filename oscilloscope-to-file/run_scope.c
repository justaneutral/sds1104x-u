
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define _USE_MATH_DEFINES // Must be defined before including math.h
#include <math.h>
#include <unistd.h>
#include <time.h>

#include "osc.h"

#include <unistd.h>

#define INPUT_SAMPLE_RATE (500000.0)

#define INPUT_N 1024 //16384 //4096 //1024

#define DEFAULT_K 4


int run_scope_n(int n)
{
    int rv = 0;
    int num_iterations;
    int m;

    signed char **buf_before = (signed char**)calloc((size_t)DEFAULT_K, sizeof(signed char*));
    if (!buf_before)
    {
        fprintf(stderr, "OOM\n");
        rv = -1;
        goto _prtn0;
    }

    //Siglent sds1104x-u oscilloscope
    OscCtx ctx;

    ViStatus st = osc_init(&ctx, NULL);
    if (st < VI_SUCCESS) return -1;
    ctx.loop_counter = n;

    st = osc_step(&ctx);
    if (st < VI_SUCCESS) goto _prtn1;

    while (ctx.loop_counter) 
    {
        st = osc_step(&ctx);
        if (st < VI_SUCCESS) break;

        for (int ch = 0; ch < DEFAULT_K; ch++) 
        {
            buf_before[ch] = (signed char*)ctx.ch[ch];
            if (!(buf_before[ch]))
            {
                fprintf(stderr, "OOM\n");
                return -1;
            }
        }
   
	m = 0;
        num_iterations = ctx.len/INPUT_N;
        for(int i = 0; i < num_iterations; i++) 
        {
            for(int j=0;j<INPUT_N;j++)
            {
                for (int ch = 0; ch < DEFAULT_K; ch++)
                {
		}
                m++;
            }
            
            fflush(stdout);
    	}
    }
_prtn1:
    osc_close(&ctx);
_prtn0:
    if(buf_before) free(buf_before);
    return rv;
}

