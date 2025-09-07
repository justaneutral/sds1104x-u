#include <stdio.h>

#define _USE_MATH_DEFINES // Must be defined before including math.h
#include <math.h>

// Sampling and filter parameters
#define INPUT_SAMPLE_RATE 500000.0 // 500 kHz
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
complex_t history1[COMPLEX_FILTER_TAPS] = {0}; // Initialize to all zeros
int history_idx1 = 0;
int decimate_counter1 = 0;
double angle1 = 0.0;
double angle_increment1 = 2.0 * M_PI * F_C1 / INPUT_SAMPLE_RATE;

// State variables for Filter 2
complex_t history2[COMPLEX_FILTER_TAPS] = {0}; // Initialize to all zeros
int history_idx2 = 0;
int decimate_counter2 = 0;
double angle2 = 0.0;
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

// Example usage in a main function
int main() {
    // Assuming a long buffer of samples exists
    signed char sample_buffer[] = {
        // ... your long buffer of oscilloscope samples ...
        // Example: a test tone at 24 kHz
        (signed char)(100 * sin(2.0 * M_PI * 24000.0 / INPUT_SAMPLE_RATE * 0)),
        (signed char)(100 * sin(2.0 * M_PI * 24000.0 / INPUT_SAMPLE_RATE * 1)),
        (signed char)(100 * sin(2.0 * M_PI * 24000.0 / INPUT_SAMPLE_RATE * 2)),
        // ...
    };
    int buffer_length = sizeof(sample_buffer) / sizeof(signed char);

    complex_t output1, output2;
    int ready1, ready2;

    for (int i = 0; i < buffer_length; ++i) {
        if(i&0xf) printf(".");
        // Process sample for Filter 1
        process_sample(sample_buffer[i], complex_filter_coeffs, history1, &history_idx1, &decimate_counter1, &angle1, angle_increment1, &output1, &ready1);
        if (ready1) {
            printf("\nFilter 1 Output (at reduced rate): Real = %f, Imag = %f\n", output1.real, output1.imag);
        }

        // Process sample for Filter 2
        process_sample(sample_buffer[i], complex_filter_coeffs, history2, &history_idx2, &decimate_counter2, &angle2, angle_increment2, &output2, &ready2);
        if (ready2) {
            printf("\nFilter 2 Output (at reduced rate): Real = %f, Imag = %f\n", output2.real, output2.imag);
        }
    }

    return 0;
}

