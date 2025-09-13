#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "visa_util.h"
#include "osc.h"

/* ---- Forward declarations for helpers you already have elsewhere ---- */
/* int viwrite_str(ViSession instr, ViBuf cmd);
   int viread_str(ViSession instr, char *buf, size_t buflen);
   int set_attribute(ViSession instr, ViAttr attr, ViUInt32 value);
   long monotonic_us(void);
   void print_waveforms(char *fullbuf, int payload_offset, int per_channel_len);
   int set_buffers(char *ch[4], char *fullbuf, int payload_offset, int per_channel_len); */

/* ---- Internal helpers/macros to access channel payloads from single buffer ---- */
#define BUF_CH0(buf)   (&(buf)[__BUFFER_CH0_START__])
#define BUF_CH1(buf)   (&(buf)[__BUFFER_CH1_START__])
#define BUF_CH2(buf)   (&(buf)[__BUFFER_CH2_START__])
#define BUF_CH3(buf)   (&(buf)[__BUFFER_CH3_START__])

/* Default resource if none supplied */
static const char *kDefaultResource =
    "USB0::0xF4EC::0x1012::SDSAHBAX6R0452::INSTR";

/* ---- Initialization ---- */
ViStatus osc_init(OscCtx *ctx, const char *resourceName)
{
    if (!ctx) return VI_ERROR_INV_OBJECT;
    memset(ctx, 0, sizeof(*ctx));

    ctx->resourceName = resourceName ? resourceName : kDefaultResource;
    ctx->quit_key = ~'q';
    ctx->loop_counter = -1; /* infinite by default */

    /* Allocate the large buffer once */
    ctx->buffer = (char*)malloc(__BUFFER_BYTE_LEN__);
    if (!ctx->buffer) {
        return VI_ERROR_SYSTEM_ERROR;
    }

    /* Open VISA */
    ViStatus st = open_device(&ctx->defaultRM, &ctx->instr, ctx->resourceName);
    if (st < VI_SUCCESS) {
        free(ctx->buffer); ctx->buffer = NULL;
        return st;
    }
    printf("Successfully opened session to %s.\n", ctx->resourceName);

    /* ----------------- Device configuration (from your original code) ----------------- */
    ViSession instr = ctx->instr;
    ViUInt32 retCount;

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"*IDN?\n")) goto fail;
    if ((ViUInt32)-1==(retCount=viread_str(instr, ctx->buffer, __BUFFER_BYTE_LEN__))) goto fail;

    //if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"*RST\n")) goto fail;
    //usleep(5000000);
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"*OPC?\n")) goto fail;
    if ((ViUInt32)-1==(retCount=viread_str(instr, ctx->buffer, __BUFFER_BYTE_LEN__))) goto fail;

    printf("Setup\n");
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"CHDR OFF\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"MSIZ 7M\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"MSIZ?\n")) goto fail;
    if ((ViUInt32)-1==(retCount=viread_str(instr, ctx->buffer, __BUFFER_BYTE_LEN__))) goto fail;

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"TDIV 1S\n")) goto fail;
    //if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"TDIV 1US\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"TRMD SINGLE\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"TRDL 0\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"TRWI 10V\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"TRPA C1,L,C2,L,C3,L,C4,L,STATE,OR\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"TRSE EDGE,SR,C1,HT,OFF,HV,0,HV2,0\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"TRSE?\n")) goto fail;
    if ((ViUInt32)-1==(retCount=viread_str(instr, ctx->buffer, __BUFFER_BYTE_LEN__))) goto fail;

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"BWL C1,ON,C2,ON,C3,ON,C4,ON\n")) goto fail;

    /* Channel setups C1..C4 (same as original) */
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:TRCP AC\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:TRLV 0mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:TRLV2 0mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:TRSL WINDOW\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:ATTN 1\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:CPL A50\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:OFST +0V\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:SKEW 0.00E-00S\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:TRA ON\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:UNIT V\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:VDIV 2mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:INVS OFF\n")) goto fail;

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:TRCP AC\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:TRLV 0mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:TRLV2 0mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:TRSL WINDOW\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:ATTN 1\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:CPL A50\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:OFST +0V\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:SKEW 0.00E-00S\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:TRA ON\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:UNIT V\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:VDIV 2mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:INVS OFF\n")) goto fail;

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:TRCP AC\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:TRLV 0mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:TRLV2 0mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:TRSL WINDOW\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:ATTN 1\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:CPL A50\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:OFST +0V\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:SKEW 0.00E-00S\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:TRA ON\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:UNIT V\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:VDIV 2mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:INVS OFF\n")) goto fail;

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:TRCP AC\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:TRLV 0mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:TRLV2 0mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:TRSL WINDOW\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:ATTN 1\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:CPL A50\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:OFST +0V\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:SKEW 0.00E-00S\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:TRA ON\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:UNIT V\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:VDIV 2mV\n")) goto fail;
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:INVS OFF\n")) goto fail;

    /* VISA timeout & sample/time queries */
    if (0 != set_attribute(instr, VI_ATTR_TMO_VALUE, 30000)) goto fail;

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"SANU? C1\n")) goto fail;
    if ((ViUInt32)-1==(retCount=viread_str(instr, ctx->buffer, __BUFFER_BYTE_LEN__))) goto fail;
    float num_samples = 0.0f, samples_per_second = 0.0f, duration_seconds = 0.0f;
    sscanf(ctx->buffer, "%g", &num_samples);

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"SARA?\n")) goto fail;
    if ((ViUInt32)-1==(retCount=viread_str(instr, ctx->buffer, __BUFFER_BYTE_LEN__))) goto fail;
    sscanf(ctx->buffer, "%g", &samples_per_second);

    duration_seconds = num_samples / (samples_per_second > 0.0f ? samples_per_second : 1.0f);
    ctx->acq_delay_us = 500000UL + (unsigned long)(1000000.0 * duration_seconds);
    ctx->remaining_acq_delay_us = ctx->acq_delay_us;

    printf("\nSamples per channel = %g, sample rate per second = %g, duration_seconds = %f, acq_delay_us = %lu\n\n",
           num_samples, samples_per_second, duration_seconds, ctx->acq_delay_us);

    /* Frame configuration (kept from your code) */
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"WFSU SP,1,NP,7000000,FP,0,SN,0\n")) goto fail;
    usleep(5000);

    /* First ARM */
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"ARM\n")) goto fail;

    return VI_SUCCESS;

fail:
    osc_close(ctx);
    return VI_ERROR_SYSTEM_ERROR;
}

/* ---- One loop iteration ---- */
ViStatus osc_step(OscCtx *ctx)
{
    if (!ctx || !ctx->buffer || ctx->instr == VI_NULL) return VI_ERROR_INV_OBJECT;
    /* Optional bounded loop check */
    if (ctx->loop_counter == 0) {
        return VI_WARN_QUEUE_OVERFLOW; /* use a non-fatal code to indicate done */
    }
    /* Compute remaining delay for next cycle */
    long processing_time_delta_us = monotonic_us() - ctx->processing_start_us;
    ctx->remaining_acq_delay_us =
        (processing_time_delta_us >= (long)ctx->acq_delay_us)
            ? 0UL
            : (unsigned long)(ctx->acq_delay_us - processing_time_delta_us);
    printf("remaining_acq_delay_us = %lu\n\n", ctx->remaining_acq_delay_us);
    /* Sleep remaining time to let scope finish acquisition */
    usleep(ctx->remaining_acq_delay_us);
    /* Fetch 4 channels (DAT2) */
    ViSession instr = ctx->instr;
    ViUInt32 retCount;

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C1:WF? DAT2\n")) return VI_ERROR_SYSTEM_ERROR;
    if ((ViUInt32)-1==(retCount=viread_str(instr, BUF_CH0(ctx->buffer), __BUFFER_BYTE_LEN__))) return VI_ERROR_SYSTEM_ERROR;

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C2:WF? DAT2\n")) return VI_ERROR_SYSTEM_ERROR;
    if ((ViUInt32)
-1==(retCount=viread_str(instr, BUF_CH1(ctx->buffer), __BUFFER_BYTE_LEN__))) return VI_ERROR_SYSTEM_ERROR;

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C3:WF? DAT2\n")) return VI_ERROR_SYSTEM_ERROR;
    if ((ViUInt32)
-1==(retCount=viread_str(instr, BUF_CH2(ctx->buffer), __BUFFER_BYTE_LEN__))) return VI_ERROR_SYSTEM_ERROR;

    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"C4:WF? DAT2\n")) return VI_ERROR_SYSTEM_ERROR;
    if ((ViUInt32)
-1==(retCount=viread_str(instr, BUF_CH3(ctx->buffer), __BUFFER_BYTE_LEN__))) return VI_ERROR_SYSTEM_ERROR;

    ctx->last_retCount = retCount;

    /* Start next acquisition immediately */
    if ((ViUInt32)-1==viwrite_str(instr, (ViBuf)"ARM\n")) return VI_ERROR_SYSTEM_ERROR;

    /* Processing window (do work on previously captured data) */
    ctx->processing_start_us = monotonic_us();
    ctx->len = set_buffers(ctx->ch, ctx->buffer, __BUFFER_BYTE_OFFSET__, __BUFFER_BYTE_CHANNAL_LEN__);

    /* Your visual/diagnostic processing */
    //print_waveforms(ctx->buffer, __BUFFER_BYTE_OFFSET__, __BUFFER_BYTE_CHANNAL_LEN__);
    /* Decrement bounded loop counter if used */
    if (ctx->loop_counter > 0) ctx->loop_counter--;
    return VI_SUCCESS;
}

/* ---- Cleanup ---- */
void osc_close(OscCtx *ctx)
{
    if (!ctx) return;

    if (ctx->defaultRM || ctx->instr)
    {
        close_device(ctx->defaultRM, ctx->instr);
        ctx->defaultRM = VI_NULL;
        ctx->instr = VI_NULL;
    }
    if (ctx->buffer)
    {
        free(ctx->buffer);
        ctx->buffer = NULL;
    }
    ctx->resourceName = NULL;
}

