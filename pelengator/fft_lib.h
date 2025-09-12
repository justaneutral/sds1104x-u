#ifndef FFT_LIB_H
#define FFT_LIB_H

#include <complex.h>

void hamming_window(double *data, int n);
void fft(complex double *buf, complex double *out, int n);
void process_fft(const signed char *input, double *output_mag_db, int n);
void process_fftc(const double *input_r, const double *input_i, double *output_mag_db, int n);

#endif

