#ifndef OSC_H
#define OSC_H

#include <visa.h>          /* VISA headers */
#include "visa_util.h"     /* open_device, close_device declarations */

/* ---- Buffer layout constants (same as your original) ---- */
#define __BUFFER_BYTE_LEN__           (4*1024 + 4*7*1024*1024)
#define __BUFFER_BYTE_OFFSET__        (1024)
#define __BUFFER_BYTE_CHANNAL_LEN__   ((__BUFFER_BYTE_LEN__-__BUFFER_BYTE_OFFSET__)>>2)
#define __BUFFER_CH0_START__          (__BUFFER_BYTE_OFFSET__)
#define __BUFFER_CH1_START__          (__BUFFER_CH0_START__+__BUFFER_BYTE_CHANNAL_LEN__)
#define __BUFFER_CH2_START__          (__BUFFER_CH1_START__+__BUFFER_BYTE_CHANNAL_LEN__)
#define __BUFFER_CH3_START__          (__BUFFER_CH2_START__+__BUFFER_BYTE_CHANNAL_LEN__)

/* ---- Persistent context (single structure) ---- */
typedef struct {
    /* VISA sessions */
    ViSession defaultRM;
    ViSession instr;

    /* I/O scratch & capture buffer (single blob, contains headers+all 4 channels) */
    char *buffer;
    char *ch[4];
    int len;

    /* Last read count from viread_str (kept in case caller needs it) */
    ViUInt32 last_retCount;

    /* Timing control */
    unsigned long acq_delay_us;            /* computed from SANU?/SARA? */
    unsigned long remaining_acq_delay_us;  /* updated each frame */
    unsigned long processing_start_us;

    /* Loop state */
    int loop_counter;       /* if you want bounded loop; set negative/large for “infinite” */
    char quit_key;          /* not used, kept for parity */

   /* Cached resource name (for diagnostics) */
    const char *resourceName;
} OscCtx;

/* ---------------- API: one struct + 3 functions ---------------- */

/* Initialization:
   - Opens instrument, configures it (the long SCPI block you had),
   - Queries sample count & rate to compute frame delay,
   - Arms the first acquisition,
   - Sets callback to be used during osc_step.
   Returns VI_SUCCESS on success, < VI_SUCCESS on failure. */
ViStatus osc_init(OscCtx *ctx, const char *resourceName);  /* if NULL, uses your USB resource */

/* One iteration of the acquisition/processing loop:
   - Waits remaining time,
   - Reads all four channels,
   - Re-arms next acquisition,
   - Processes (print_waveforms),
   - Invokes callback(ch,len) if provided,
   - Updates remaining_acq_delay_us based on processing time.
   Returns VI_SUCCESS to continue; < VI_SUCCESS for an error (caller should break/close). */
ViStatus osc_step(OscCtx *ctx);

/* Cleanup:
   - Closes VISA sessions,
   - Frees buffers.
   Safe to call multiple times. */
void osc_close(OscCtx *ctx);

#endif /* OSC_H */

