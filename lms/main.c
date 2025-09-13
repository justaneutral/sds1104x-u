#include "lms_filter.h"

int main() {
    // Desired signal (reference), for example, a constant signal
    complex double desired_signal = 1.0 + 0.0 * I;

    // Initialize the LMS filter
    LMSFilter filter;
    lms_filter_init(&filter, desired_signal);

    // Simulated antenna samples (complex signal)
    complex double antenna_1_sample = 1.0 + 1.0 * I;  // Example complex sample from antenna 1
    complex double antenna_2_sample = 0.5 + 0.5 * I;  // Example complex sample from antenna 2

    // Iterate over the samples (in this case, just one iteration)
    for (int n = 0; n < 1000; n++) {
        // Compute the filter output
        complex double filter_output = lms_filter_output(&filter, antenna_1_sample, antenna_2_sample);

        // Compute the error signal
        complex double error_signal = lms_filter_error(&filter, filter_output);

        // Update the LMS filter weights
        lms_filter_update(&filter, antenna_1_sample, antenna_2_sample, error_signal);

        // Calculate the angle (phase) of the error signal
        double angle = calculate_error_angle(error_signal);
        printf("Sample %d: Error signal phase (angle) = %f radians\n", n, angle);

        // You would append new samples here, e.g., new antenna data
        // In this case, let's just simulate changing the antenna signals
        antenna_1_sample += 0.01 + 0.01 * I;  // Simulate new data from antenna 1
        antenna_2_sample += 0.02 + 0.02 * I;  // Simulate new data from antenna 2
    }

    return 0;
}

