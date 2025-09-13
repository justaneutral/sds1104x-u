#include <stdio.h>
#include <stdlib.h>
#include <complex.h>
#include <math.h>

#define MAX_FILTER_LENGTH 100
#define MU 0.01  // Step size (learning rate)

// Define the LMS filter structure
typedef struct {
    complex double weights[2];  // Complex filter coefficients for two inputs
    complex double desired_signal;  // Desired signal (reference) for comparison
} LMSFilter;

// Function to initialize the LMS filter
void lms_filter_init(LMSFilter* filter, complex double desired_signal);

// top step function
double lms_step(LMSFilter *pfilter, complex double s0,  complex double s1);

// ------------------------------------------------------------------------------------------

// Function to compute the LMS filter output for a given sample
complex double lms_filter_output(LMSFilter* filter, complex double input_sample_1, complex double input_sample_2);

// Function to update the LMS filter weights
void lms_filter_update(LMSFilter* filter, complex double input_sample_1, complex double input_sample_2, complex double error_signal);

// Function to compute the error signal (desired_signal - filter_output)
complex double lms_filter_error(LMSFilter* filter, complex double filter_output);

// Function to calculate the angle (phase) of the error signal
double calculate_error_angle(complex double error_signal);

