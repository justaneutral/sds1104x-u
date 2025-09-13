
#include "lms_filter.h"

// Function to initialize the LMS filter
void lms_filter_init(LMSFilter* filter, complex double desired_signal)
{
    filter->weights[0] = 0.0 + 0.0 * I;  // Initialize weights for antenna 1
    filter->weights[1] = 0.0 + 0.0 * I;  // Initialize weights for antenna 2
    filter->desired_signal = desired_signal;  // Set the desired signal
}

// Function to compute the LMS filter output for a given sample
complex double lms_filter_output(LMSFilter* filter, complex double smpl0, complex double smpl1)
{
    // Output is the weighted sum of the inputs
    complex double output = filter->weights[0] * smpl0 + filter->weights[1] * smpl1;
    return output;
}

// Function to update the LMS filter weights
void lms_filter_update(LMSFilter* filter, complex double smpl0, complex double smpl1, complex double error_signal)
{
    // LMS weight update rule complex weights)
    filter->weights[0] += MU * smpl0 * conj(error_signal);
    filter->weights[1] += MU * smpl1 * conj(error_signal);
}

// Function to compute the error signal (desired_signal - filter_output)
complex double lms_filter_error(LMSFilter* filter, complex double filter_output)
{
    return filter->desired_signal - filter_output;
}

// Function to calculate the angle (phase) of the error signal
double calculate_error_angle(complex double error_signal)
{
    return carg(error_signal);  // Use the `carg` function to get the phase (angle) in radians
}


double lms_step(LMSFilter *pfilter, complex double s0,  complex double s1)
{
    // Compute the filter output
        complex double filter_output = lms_filter_output(pfilter, s0, s1);

        // Compute the error signal
        complex double error_signal = lms_filter_error(pfilter, filter_output);

        // Update the LMS filter weights
        lms_filter_update(pfilter, s0, s1, error_signal);

        // Calculate the angle (phase) of the error signal
        double angle = calculate_error_angle(error_signal);
	return angle;
}
