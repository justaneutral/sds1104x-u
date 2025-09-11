
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
#include <time.h>

#include "x11_plot.h"
#include "fft_lib.h"
#include "osc.h"

#define DEFAULT_SAMPLE_RATE 500000.0
#define DEFAULT_N 1024
#define DEFAULT_K 4
#define WIN_W 1100
#define WIN_H 850


int run_scope(void)
{
    OscCtx ctx;
    PlotContext *ctx_before = plot_create("Stage A - BEFORE (Overlay)", DEFAULT_N, DEFAULT_K, WIN_W, WIN_H, DEFAULT_SAMPLE_RATE);
    PlotContext *ctx_after  = plot_create("Stage B - AFTER  (Overlay)", DEFAULT_N, DEFAULT_K, WIN_W, WIN_H, DEFAULT_SAMPLE_RATE);
    
    if (!ctx_before || !ctx_after)
    {
        fprintf(stderr, "Failed to create X11 windows. Is X server available?\n");
        plot_destroy(ctx_before);
        plot_destroy(ctx_after);
        return -1;
    }

    ViStatus st = osc_init(&ctx, NULL); /*use default resource*/
    if (st < VI_SUCCESS) return -1;

    /* Example: infinite loop (press Ctrl+C to stop your process externally) */
    for (;;) 
    {
        st = osc_step(&ctx);
        if (st < VI_SUCCESS) break; /* error or user stop */
        fflush(stdout);
    }


    plot_destroy(ctx_before);
    plot_destroy(ctx_after);
    osc_close(&ctx);
    return 0;
}

/* Or: bounded loop (e.g., 4 frames) */
int run_scope_n(int n)
{
    int rv = 0;
    signed char **buf_before = (signed char**)calloc((size_t)DEFAULT_K, sizeof(signed char*));
    signed char **buf_after  = (signed char**)calloc((size_t)DEFAULT_K, sizeof(signed char*));
    if (!buf_before || !buf_after)
    {
        fprintf(stderr, "OOM\n");
        rv = -1;
        goto _prtn0;
    }

    OscCtx ctx;
    PlotContext *ctx_before = plot_create("Stage A - BEFORE (Overlay)", DEFAULT_N, DEFAULT_K, WIN_W, WIN_H, DEFAULT_SAMPLE_RATE);
    PlotContext *ctx_after  = plot_create("Stage B - AFTER  (Overlay)", DEFAULT_N, DEFAULT_K, WIN_W, WIN_H, DEFAULT_SAMPLE_RATE);
    
    if (!ctx_before || !ctx_after)
    {
        fprintf(stderr, "Failed to create X11 windows. Is X server available?\n");
        plot_destroy(ctx_before);
        plot_destroy(ctx_after);
        rv = -2;
        goto _prtn1;
    }

    ViStatus st = osc_init(&ctx, NULL);
    if (st < VI_SUCCESS) return -1;
    ctx.loop_counter = n;

    while (ctx.loop_counter) 
    {
        st = osc_step(&ctx);
        if (st < VI_SUCCESS) break;

        for (int ch = 0; ch < DEFAULT_K; ch++) 
        {
            buf_before[ch] = ctx.ch[ch];
            buf_after[ch] = ctx.ch[ch];
            if (!(buf_before[ch]) || !(buf_after[ch]))
            {
                fprintf(stderr, "OOM\n");
                return -1;
            }
    
            plot_update(ctx_before, (const signed char * const *)buf_before, ctx.acq_delay_us);
            plot_update(ctx_after,  (const signed char * const *)buf_after,  ctx.acq_delay_us);

            int closed_a = plot_handle_events(ctx_before);
            int closed_b = plot_handle_events(ctx_after);
            if (closed_a || closed_b) 
            {
                goto _prtn1;
            }
            fflush(stdout);
        }
    }

_prtn1:
    plot_destroy(ctx_before);
    plot_destroy(ctx_after);
    osc_close(&ctx);
_prtn0:
    if(buf_before) free(buf_before);
    if(buf_after) free(buf_after);
    return rv;
}

