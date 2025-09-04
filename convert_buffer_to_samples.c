#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "visa_util.h"

/**
 * @brief Converts a binary buffer of waveform data into an array of floating-point samples.
 *
 * This function assumes the incoming data is in a specific format (e.g., 16-bit signed integers)
 * and scales and offsets it according to the instrument's settings.
 *
 * @param buffer A pointer to the binary data buffer received from the instrument.
 * @param num_bytes The total number of bytes in the buffer.
 * @param samples A pre-allocated array to store the converted floating-point sample values.
 * @param bytes_per_sample The number of bytes that represent a single sample (e.g., 1 for 8-bit, 2 for 16-bit).
 * @param scale The vertical scaling factor for the data (e.g., volts per count).
 * @param offset The vertical offset for the data.
 */
void convert_buffer_to_samples(const char* buffer, ViUInt32 num_bytes, float* samples, int bytes_per_sample, float scale, float offset) {
    int num_samples = num_bytes / bytes_per_sample;
    int i;
    
    // Example for 16-bit signed integer data (common for oscilloscopes)
    if (bytes_per_sample == 2) {
        const short* int_data = (const short*)buffer;
        for (i = 0; i < num_samples; ++i) {
            samples[i] = ((float)int_data[i] * scale) + offset;
        }
    } 
    // Add logic for other bytes_per_sample formats (e.g., 1-byte, 4-byte) as needed
    // based on the instrument's data format.
    // else if (bytes_per_sample == 1) { ... }
}


