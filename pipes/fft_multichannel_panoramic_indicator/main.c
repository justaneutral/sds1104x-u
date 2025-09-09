#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
#include <time.h>

#include "x11_plot.h"
#include "fft_lib.h"

#define DEFAULT_SAMPLE_RATE 500000.0
#define DEFAULT_N 1024
#define DEFAULT_K 4
#define WIN_W 1100
#define WIN_H 850

static void generate_signals(signed char **bufs, int K, int N, double fs, double t0) {
    double base_freq = 2000.0;
    double df = 1000.0;
    double amp = 120.0;
    for (int ch = 0; ch < K; ch++) {
        double f = base_freq + (double)ch * df;
        double phase = 0.25 * M_PI * ch;
        for (int i = 0; i < N; i++) {
            double t = t0 + (double)i / fs;
            double s = amp * cos(2.0 * M_PI * f * t + phase);
            s += 5.0 * ((double)rand() / (double)RAND_MAX - 0.5);
            if (s > 127.0) s = 127.0;
            if (s < -128.0) s = -128.0;
            bufs[ch][i] = (signed char)lrint(s);
        }
    }
}

static void simple_process(signed char **dst, signed char **src, int K, int N) {
    for (int ch = 0; ch < K; ch++) {
        double tmp[N];
        for (int i = 0; i < N; i++) tmp[i] = (double)src[ch][i];
        hamming_window(tmp, N);
        double y = 0.0;
        for (int i = 0; i < N; i++) {
            y = 0.9 * y + 0.1 * tmp[i];
            if (y > 127.0) y = 127.0;
            if (y < -128.0) y = -128.0;
            dst[ch][i] = (signed char)lrint(y);
        }
    }
}

static void usage(const char *prog) {
    fprintf(stderr, "Usage: %s [K_channels (default %d)] [FFT_N (default %d)]\n", prog, DEFAULT_K, DEFAULT_N);
    fprintf(stderr, "Close a window by pressing any key inside it.\n");
}

int main(int argc, char **argv) {
    int K = DEFAULT_K;
    int N = DEFAULT_N;

    if (argc >= 2) {
        K = atoi(argv[1]);
        if (K <= 0) { usage(argv[0]); return 1; }
    }
    if (argc >= 3) {
        N = atoi(argv[2]);
        if (N <= 0 || (N & (N - 1)) != 0) {
            fprintf(stderr, "FFT_N must be a power of two > 0\n");
            return 1;
        }
    }

    srand((unsigned int)time(NULL));
    double fs = DEFAULT_SAMPLE_RATE;

    signed char **buf_before = (signed char**)calloc((size_t)K, sizeof(signed char*));
    signed char **buf_after  = (signed char**)calloc((size_t)K, sizeof(signed char*));
    if (!buf_before || !buf_after) { fprintf(stderr, "OOM\n"); return 1; }
    for (int ch = 0; ch < K; ch++) {
        buf_before[ch] = (signed char*)malloc((size_t)N);
        buf_after[ch]  = (signed char*)malloc((size_t)N);
        if (!buf_before[ch] || !buf_after[ch]) { fprintf(stderr, "OOM\n"); return 1; }
        memset(buf_before[ch], 0, (size_t)N);
        memset(buf_after[ch],  0, (size_t)N);
    }

    /* Pass sample rate so ticks show proper frequency/time scales */
    PlotContext *ctx_before = plot_create("Stage A - BEFORE (Overlay)", N, K, WIN_W, WIN_H, fs);
    PlotContext *ctx_after  = plot_create("Stage B - AFTER  (Overlay)", N, K, WIN_W, WIN_H, fs);
    if (!ctx_before || !ctx_after) {
        fprintf(stderr, "Failed to create X11 windows. Is X server available?\n");
        plot_destroy(ctx_before);
        plot_destroy(ctx_after);
        return 1;
    }

    long long t_us = 0;
    const double frame_dt_sec = (double)N / fs;

    while (1) {
        double t0 = (double)t_us / 1e6;
        generate_signals(buf_before, K, N, fs, t0);
        simple_process(buf_after, buf_before, K, N);

        plot_update(ctx_before, (const signed char * const *)buf_before, t_us);
        plot_update(ctx_after,  (const signed char * const *)buf_after,  t_us);

        int closed_a = plot_handle_events(ctx_before);
        int closed_b = plot_handle_events(ctx_after);
        if (closed_a || closed_b) break;

        usleep(10000);
        t_us += (long long)lrint(frame_dt_sec * 1e6);
    }

    plot_destroy(ctx_before);
    plot_destroy(ctx_after);

    for (int ch = 0; ch < K; ch++) {
        free(buf_before[ch]);
        free(buf_after[ch]);
    }
    free(buf_before);
    free(buf_after);

    return 0;
}

