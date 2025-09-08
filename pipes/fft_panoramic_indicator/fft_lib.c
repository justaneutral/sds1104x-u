#include "fft_lib.h"
#include <math.h>
#include <string.h>

/* Iterative FFT function (radix-2 Cooley-Tukey) */
void fft(complex double *x, complex double *out, int n) {
    complex double temp_x[n];
    memcpy(temp_x, x, n * sizeof(complex double));
    memcpy(out, temp_x, n * sizeof(complex double));

    // Reverse bits
    int i, j, k, l;
    for (i = 1, j = 0; i < n; i++) {
        for (k = n >> 1; j >= k; k >>= 1) {
            j -= k;
        }
        j += k;
        if (i < j) {
            complex double temp = out[i];
            out[i] = out[j];
            out[j] = temp;
        }
    }

    // Butterfly passes
    for (l = 2; l <= n; l <<= 1) {
        double w_real = cos(-2 * M_PI / l);
        double w_imag = sin(-2 * M_PI / l);
        complex double w = w_real + I * w_imag;

        for (j = 0; j < n; j += l) {
            complex double w_k = 1.0;
            for (k = 0; k < l / 2; k++) {
                complex double t = w_k * out[j + k + l / 2];
                complex double u = out[j + k];
                out[j + k] = u + t;
                out[j + k + l / 2] = u - t;
                w_k *= w;
            }
        }
    }
}

void hamming_window(double *data, int n) {
    for (int i = 0; i < n; i++) {
        data[i] *= 0.54 - 0.46 * cos(2 * M_PI * i / (double)(n - 1));
    }
}

void process_fft(const signed char *input, double *output_mag_db, int n) {
    complex double fft_input[n];
    complex double fft_output[n];
    double windowed_input[n];
    double max_mag_sq = 0.0;

    for (int i = 0; i < n; i++) {
        windowed_input[i] = (double)input[i];
    }
    hamming_window(windowed_input, n);

    for (int i = 0; i < n; i++) {
        fft_input[i] = windowed_input[i];
    }

    fft(fft_input, fft_output, n);

    // Find the maximum magnitude squared for normalization
    for (int i = 0; i < n / 2; i++) {
        double current_mag_sq = creal(fft_output[i]) * creal(fft_output[i]) + cimag(fft_output[i]) * cimag(fft_output[i]);
        if (current_mag_sq > max_mag_sq) {
            max_mag_sq = current_mag_sq;
        }
    }

    double max_db = 10 * log10(max_mag_sq > 1.0e-12 ? max_mag_sq : 1.0e-12);
    double min_db_scaled = 10 * log10(1.0);

    for (int i = 0; i < n / 2; i++) {
        double current_mag_sq = creal(fft_output[i]) * creal(fft_output[i]) + cimag(fft_output[i]) * cimag(fft_output[i]);
        double current_db = 10 * log10(current_mag_sq > 1.0e-12 ? current_mag_sq : 1.0e-12);
        output_mag_db[i] = current_db - max_db;
        if (output_mag_db[i] < min_db_scaled - max_db) {
            output_mag_db[i] = min_db_scaled - max_db;
        }
    }
}

