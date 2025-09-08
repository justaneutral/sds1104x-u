#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>

#include "fft_lib.h"
#include "x11_plot.h"

#define DEFAULT_SAMPLE_RATE 500000.0 // 500 ksps
#define N 1024                       // FFT size
#define K 1                         // Overlap step
#define MIN_FREQ 0.0            // Max frequency (half the sample rate)
#define MAX_FREQ 250000.0            // Max frequency (half the sample rate)

int main() {
    double sample_rate = DEFAULT_SAMPLE_RATE;
    signed char input_buffer[N];
    double freq = MIN_FREQ;
    double freq_step_hz = MAX_FREQ * 0.001; // Step frequency by 1% of the total BW
    long long current_time_us = 0;

    init_fft_and_time_plot("Panoramic FFT Viewer", N);
    
    while (1) {
        // Generate a sine wave with the current central frequency
        for (int i = 0; i < N; i++) {
            input_buffer[i] = (signed char)(127.0 * cos(2.0 * M_PI * freq * i / sample_rate));
            //printf("ib[%d]=%d\t",i,input_buffer[i]);
        }

        // Update the plots with the new data
        update_fft_and_time_plot(input_buffer, N, current_time_us);
        
        // Move to the next frequency
        freq += freq_step_hz;
        if (freq > MAX_FREQ) {
            freq = MIN_FREQ;
        }

        // Increment time for the display
        current_time_us += (long long)(N / sample_rate * 1000000.0);
        
        usleep(10000); // Wait for 10ms to see the updates
    }
    
    cleanup_fft_and_time_plot();
    
    return 0;
}

