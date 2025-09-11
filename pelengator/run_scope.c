
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define _USE_MATH_DEFINES // Must be defined before including math.h
#include <math.h>
#include <unistd.h>
#include <time.h>

#include "x11_plot.h"
#include "fft_lib.h"
#include "osc.h"

#define INPUT_SAMPLE_RATE 500000.0
#define OUTPUT_SAMPLE_RATE (INPUT_SAMPLE_RATE/20)
#define INPUT_N 1024
#define OUTPUT_N (INPUT_N)

#define DEFAULT_K 4
#define WIN_W 1100
#define WIN_H 850


// Sampling and filter parameters
#define PASSBAND_WIDTH 200.0      // 200 Hz
#define F_C1 24000.0              // Center frequency for filter 1
#define F_C2 25400.0              // Center frequency for filter 2
#define DECIMATION_FACTOR 20      // Reduced sample rate: 500kHz / 20 = 25kHz

// Complex number structure
typedef struct {
    double real;
    double imag;
} complex_t;

// Coefficients for the complex low-pass FIR filter
// These coefficients must be generated externally and pasted here.
// The filter's passband should cover the baseband signal (e.g., 0-200 Hz).
// Passband: 0-200 Hz, Stopband: > 12500 Hz, Attenuation: 80 dB
#define COMPLEX_FILTER_TAPS 61   // Taps for the low-pass filter
const double complex_filter_coeffs[COMPLEX_FILTER_TAPS] = {
    -0.0000563303977127,    -0.0000119583586124,    -0.0000130316259547,    -0.0000142253484869,
    -0.0000152838480442,    -0.0000162326020046,    -0.0000171600820158,    -0.0000180429684566,
    -0.0000188086905799,    -0.0000194372728780,    -0.0000199423472368,    -0.0000203158703565,
    -0.0000205385789983,    -0.0000206100962494,    -0.0000205363291769,    -0.0000203080794742,
    -0.0000199120494929,    -0.0000193472320107,    -0.0000186179383377,    -0.0000177243552015,
    -0.0000166696646939,    -0.0000154662807987,    -0.0000141283395674,    -0.0000126654705475,
    -0.0000110875477845,    -0.0000094085899355,    -0.0000076428470819,    -0.0000058024911620,
    -0.0000039019408147,    -0.0000019607175531,    0.0000000000000000,    0.0000019607175531,
    0.0000039019408147,    0.0000058024911620,    0.0000076428470819,    0.0000094085899355,
    0.0000110875477845,    0.0000126654705475,    0.0000141283395674,    0.0000154662807987,
    0.0000166696646939,    0.0000177243552015,    0.0000186179383377,    0.0000193472320107,
    0.0000199120494929,    0.0000203080794742,    0.0000205363291769,    0.0000206100962494,
    0.0000205385789983,    0.0000203158703565,    0.0000199423472368,    0.0000194372728780,
    0.0000188086905799,    0.0000180429684566,    0.0000171600820158,    0.0000162326020046,
    0.0000152838480442,    0.0000142253484869,    0.0000130316259547,    0.0000119583586124,
    0.0000563303977127
};


// State variables for Filter 1
complex_t history1[4][COMPLEX_FILTER_TAPS] = {0}; // Initialize to all zeros
int history_idx1[4] = {0,0,0,0};
int decimate_counter1[4] = {0,0,0,0};
double angle1[4] = {0.0,0.0,0.0,0.0};
double angle_increment1 = 2.0 * M_PI * F_C1 / INPUT_SAMPLE_RATE;

// State variables for Filter 2
complex_t history2[4][COMPLEX_FILTER_TAPS] = {0}; // Initialize to all zeros
int history_idx2[4] = {0,0,0,0};
int decimate_counter2[4] = {0,0,0,0};
double angle2[4] = {0.0,0.0,0.0,0.0};
double angle_increment2 = 2.0 * M_PI * F_C2 / INPUT_SAMPLE_RATE;

/**
 * @brief Complex frequency shift, low-pass filter, and decimation.
 * @param input_sample The current signed char sample.
 * @param coeffs The array of filter coefficients to use.
 * @param history The circular buffer for filter history.
 * @param history_idx The current index for the circular buffer.
 * @param decimate_counter The decimation counter.
 * @param angle The current angle for the complex mixer.
 * @param angle_increment The angle increment per sample.
 * @param output The output complex sample, if ready.
 * @param ready_flag 1 if a new sample is ready, 0 otherwise.
 */
void process_sample(signed char input_sample, const double* coeffs, complex_t* history, int* history_idx,
                    int* decimate_counter, double* angle, double angle_increment, complex_t* output, int* ready_flag) {

    // Reset ready flag
    *ready_flag = 0;

    // 1. Complex Frequency Shift (Mixing)
    // Create a complex mixer based on the center frequency
    double mixer_real = cos(*angle);
    double mixer_imag = -sin(*angle); // Negative sign for down-conversion
    *angle += angle_increment;
    if (*angle >= 2.0 * M_PI) {
        *angle -= 2.0 * M_PI;
    }

    // Multiply input by mixer to shift frequency
    // Input is real, so imag component is zero
    complex_t mixed_sample;
    mixed_sample.real = (double)input_sample * mixer_real;
    mixed_sample.imag = (double)input_sample * mixer_imag;

    // 2. Low-Pass Filter
    // Store mixed sample in circular buffer
    history[*history_idx] = mixed_sample;

    // Perform the complex convolution only when a new sample is needed (at decimation rate)
    *decimate_counter += 1;
    if (*decimate_counter == DECIMATION_FACTOR) {
        *decimate_counter = 0;

        complex_t filtered_output = {0.0, 0.0};
        int j = *history_idx;
        for (int i = 0; i < COMPLEX_FILTER_TAPS; ++i) {
            filtered_output.real += coeffs[i] * history[j].real;
            filtered_output.imag += coeffs[i] * history[j].imag;
            j--;
            if (j < 0) {
                j = COMPLEX_FILTER_TAPS - 1;
            }
        }

        *output = filtered_output;
        *ready_flag = 1;
    }

    // Update circular buffer index
    *history_idx = (*history_idx + 1) % COMPLEX_FILTER_TAPS;
}



int run_scope_n(int n)
{
    int rv = 0;

    complex_t filter_output;

    signed char **buf_before = (signed char**)calloc((size_t)DEFAULT_K, sizeof(signed char*));
    signed char **buf_after  = (signed char**)calloc((size_t)DEFAULT_K, sizeof(signed char*));
    if (!buf_before || !buf_after)
    {
        fprintf(stderr, "OOM\n");
        rv = -1;
        goto _prtn0;
    }

    OscCtx ctx;
    PlotContext *ctx_before = plot_create("Stage A - BEFORE (Overlay)", INPUT_N, DEFAULT_K, WIN_W, WIN_H, INPUT_SAMPLE_RATE);
    PlotContext *ctx_after  = plot_create("Stage B - AFTER  (Overlay)", OUTPUT_N, DEFAULT_K, WIN_W, WIN_H, OUTPUT_SAMPLE_RATE);
    
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

    st = osc_step(&ctx);
    if (st < VI_SUCCESS) goto _prtn1;

    for(int ch=0; ch<DEFAULT_K; ch++)
    for(int i=0;i<COMPLEX_FILTER_TAPS;i++)
    {
        history1[ch][i].imag = 0;
        history1[ch][i].real = 0;
        history2[ch][i].imag = 0;
        history2[ch][i].real = 0;
    }

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
        }
    
        int num_iterations = (ctx.len - INPUT_N)/INPUT_N;
        for(int i = 0; i < num_iterations; i++) 
        {
        
            plot_update(ctx_before, (const signed char * const *)buf_before, i);
            int m = 0;
            int ready[DEFAULT_K] = {0,0,0,0};

            for(int j=0;j<INPUT_N;j++)
            {
                for (int ch = 0; ch < DEFAULT_K; ch++)
                {
                    process_sample(buf_before[ch][j], complex_filter_coeffs, history1[ch], &history_idx1[ch], &decimate_counter1[ch], &angle1[ch], angle_increment1, &filter_output, &ready[ch]);
                    //process_sample(buf_before[i][j], complex_filter_coeffs, history2, &history_idx2, &decimate_counter2, &angle2, angle_increment2, buf_after[i][m], &ready);
                    if(ready)
                    {
                        //buf_after[ch][m] = (signed char)(filter_output.real);  // Take real part as output
                        //buf_after[ch][m+1] = (signed char)(filter_output.imag);  // Take imag part as output
                        if(ch==DEFAULT_K-1) m++;
                    }
                }
    
            }
            for(int ch=0;ch<DEFAULT_K;ch++)
            {
                for(int k=m;k<OUTPUT_N;k++) buf_after[ch][k] = 0;
            }

            plot_update(ctx_after,  (const signed char * const *)buf_after,  i);

            int closed_a = plot_handle_events(ctx_before);
            int closed_b = plot_handle_events(ctx_after);
            if (closed_a || closed_b) 
            {
                goto _prtn1;
            }
            fflush(stdout);
        }

        for (int ch = 0; ch < DEFAULT_K; ch++) 
        {
            buf_before[ch]+=INPUT_N;
            buf_after[ch]+=INPUT_N;
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

