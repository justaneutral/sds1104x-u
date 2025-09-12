#include "fft_lib.h"
#include <complex.h>
#include <math.h>
#include <string.h>

/* Iterative radix-2 Cooley–Tukey FFT */
void fft(complex double *x, complex double *out, int n) {
    complex double tmp[n];
    memcpy(tmp, x, n * sizeof(complex double));
    memcpy(out, tmp, n * sizeof(complex double));

    int i, j, k, l;
    for (i = 1, j = 0; i < n; i++) {
        for (k = n >> 1; j >= k; k >>= 1) j -= k;
        j += k;
        if (i < j) {
            complex double t = out[i];
            out[i] = out[j];
            out[j] = t;
        }
    }
    for (l = 2; l <= n; l <<= 1) {
        double w_real = cos(-2 * M_PI / l);
        double w_imag = sin(-2 * M_PI / l);
        complex double w = w_real + I * w_imag;
        for (j = 0; j < n; j += l) {
            complex double wk = 1.0;
            for (k = 0; k < l / 2; k++) {
                complex double t = wk * out[j + k + l / 2];
                complex double u = out[j + k];
                out[j + k] = u + t;
                out[j + k + l / 2] = u - t;
                wk *= w;
            }
        }
    }
}

void hamming_window(double *data, int n) {
    for (int i = 0; i < n; i++)
        data[i] *= 0.54 - 0.46 * cos(2 * M_PI * i / (double)(n - 1));
}

void process_fft(const signed char *input, double *output_mag_db, int n) {
    complex double in[n], out[n];
    double win[n];
    for (int i = 0; i < n; i++) win[i] = (double)input[i];
    hamming_window(win, n);
    for (int i = 0; i < n; i++) in[i] = win[i];

    fft(in, out, n);

    double max_m2 = 0.0;
    for (int i = 0; i < n / 2; i++) {
        double re = creal(out[i]), im = cimag(out[i]);
        double m2 = re*re + im*im;
        if (m2 > max_m2) max_m2 = m2;
    }
    if (max_m2 < 1e-12) max_m2 = 1e-12;
    double max_db = 10.0 * log10(max_m2);

    for (int i = 0; i < n / 2; i++) {
        double re = creal(out[i]), im = cimag(out[i]);
        double m2 = re*re + im*im;
        if (m2 < 1e-12) m2 = 1e-12;
        double db = 10.0 * log10(m2);
        double rel = db - max_db;
        output_mag_db[i] = (rel < -120.0) ? -120.0 : rel;
    }
}


void process_fftc(const double *input_r, const double *input_i, double *output_mag_db, int n) {
    double complex in[n], out[n];
    double win[n];

    // Copy input complex values directly into the in array
    for (int i = 0; i < n; i++) in[i] = input_r[i] + input_i[i] * I;

    // Apply Hamming window to both the real and imaginary parts of the input
    for (int i = 0; i < n; i++) win[i] = creal(in[i]);  // Use real part for windowing

    hamming_window(win, n);  // Assuming the hamming_window function applies the window correctly

    // Apply window to both real and imaginary parts
    for (int i = 0; i < n; i++) {
        in[i] = win[i] * (creal(in[i]) + I * cimag(in[i]));  // Multiply by window on both real and imaginary parts
    }

    // Perform FFT
    fft(in, out, n);

    // Find the maximum magnitude square for normalization
    double max_m2 = 0.0;
    for (int i = 0; i < n / 2; i++) {
        double re = creal(out[i]), im = cimag(out[i]);
        double m2 = re * re + im * im;
        if (m2 > max_m2) max_m2 = m2;
    }
    if (max_m2 < 1e-12) max_m2 = 1e-12;  // Avoid log(0) by setting a small minimum value
    double max_db = 10.0 * log10(max_m2);

    // Calculate magnitudes in dB, relative to max_db
    for (int i = 0; i < n / 2; i++) {
        double re = creal(out[i]), im = cimag(out[i]);
        double m2 = re * re + im * im;
        if (m2 < 1e-12) m2 = 1e-12;  // Avoid log(0) by setting a small minimum value
        double db = 10.0 * log10(m2);
        double rel = db - max_db;
        output_mag_db[i] = (rel < -120.0) ? -120.0 : rel;  // Clamping the dB values
    }
}

