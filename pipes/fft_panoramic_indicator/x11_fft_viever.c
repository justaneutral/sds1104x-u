#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <complex.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#define WINDOW_WIDTH 800
#define WINDOW_HEIGHT 400
#define BORDER_SIZE 50
#define FONT_NAME "9x15"

// FFT configuration
static void fft(complex double *buf, complex double *out, int n, int step);
static void hamming_window(double *data, int n);

// X11 setup and drawing
static void draw_spectrum(Display *disp, Window win, GC gc, const double *mag_db, int n, const char *title);
static void draw_time_domain(Display *disp, Window win, GC gc, const signed char *data, int n, const char *title);

// Main function for showing FFT and time domain
void show_fft_and_time_domain(const signed char *input_buffer, int n) {
    // --- FFT Processing ---
    complex double buf[n];
    complex double out[n];
    double windowed_input[n];
    double mag_db[n / 2];
    double max_mag_sq = 0.0;

    for (int i = 0; i < n; i++) {
        windowed_input[i] = (double)input_buffer[i];
    }
    hamming_window(windowed_input, n);

    for (int i = 0; i < n; i++) {
        buf[i] = windowed_input[i];
    }

    fft(buf, out, n, 1);

    // Calculate magnitude squared to find max for normalization
    for (int i = 0; i < n / 2; i++) {
        double current_mag_sq = creal(out[i]) * creal(out[i]) + cimag(out[i]) * cimag(out[i]);
        if (current_mag_sq > max_mag_sq) {
            max_mag_sq = current_mag_sq;
        }
    }

    // Convert magnitude to dB relative to max (0 dB)
    double max_db = 10 * log10(max_mag_sq > 1.0e-12 ? max_mag_sq : 1.0e-12);
    double min_db_val = 1.0;
    double min_db_scaled = 10 * log10(min_db_val * min_db_val);

    for (int i = 0; i < n / 2; i++) {
        double current_mag_sq = creal(out[i]) * creal(out[i]) + cimag(out[i]) * cimag(out[i]);
        double current_db = 10 * log10(current_mag_sq > 1.0e-12 ? current_mag_sq : 1.0e-12);
        mag_db[i] = current_db - max_db;
        if (mag_db[i] < min_db_scaled - max_db) {
            mag_db[i] = min_db_scaled - max_db;
        }
    }

    // --- X11 Setup ---
    Display *disp;
    Window win;
    GC gc;
    XEvent event;

    disp = XOpenDisplay(NULL);
    if (disp == NULL) {
        fprintf(stderr, "Cannot open display\n");
        exit(1);
    }
    int screen = DefaultScreen(disp);
    unsigned long black = BlackPixel(disp, screen);
    unsigned long white = WhitePixel(disp, screen);
    win = XCreateSimpleWindow(disp, RootWindow(disp, screen), 10, 10, WINDOW_WIDTH, WINDOW_HEIGHT, 1, black, white);
    XSelectInput(disp, win, ExposureMask | KeyPressMask);
    XMapWindow(disp, win);
    gc = XCreateGC(disp, win, 0, NULL);
    XSetForeground(disp, gc, black);

    // --- Main Event Loop ---
    while (1) {
        XNextEvent(disp, &event);
        if (event.type == Expose) {
            draw_spectrum(disp, win, gc, mag_db, n, "FFT Spectrum (dB)");
            draw_time_domain(disp, win, gc, input_buffer, n, "Time Domain Signal");
        }
        if (event.type == KeyPress) {
            break;
        }
    }

    // --- Cleanup ---
    XFreeGC(disp, gc);
    XDestroyWindow(disp, win);
    XCloseDisplay(disp);
}

// --- FFT Helper Functions ---
static void fft(complex double *buf, complex double *out, int n, int step) {
    if (n == 1) {
        *out = *buf;
        return;
    }
    fft(buf, out, n / 2, step * 2);
    fft(buf + step, out + n / 2, n / 2, step * 2);

    for (int i = 0; i < n / 2; i++) {
        complex double t = cexp(-I * M_PI * i / (double)(n / 2)) * out[i + n / 2];
        buf[i] = out[i] + t;
        buf[i + n / 2] = out[i] - t;
    }
}

static void hamming_window(double *data, int n) {
    for (int i = 0; i < n; i++) {
        data[i] *= 0.54 - 0.46 * cos(2 * M_PI * i / (double)(n - 1));
    }
}

// --- X11 Helper Functions ---
static void draw_spectrum(Display *disp, Window win, GC gc, const double *mag_db, int n, const char *title) {
    XSetForeground(disp, gc, BlackPixel(disp, DefaultScreen(disp)));
    XFillRectangle(disp, win, gc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT * 0.75);

    double x_scale = (double)(WINDOW_WIDTH - 2 * BORDER_SIZE) / (n / 2);
    double y_scale = (double)(WINDOW_HEIGHT * 0.75 - 2 * BORDER_SIZE) / (-80.0 - (-120.0)); // Range from -80 to -120 dB
    int plot_height = (int)(WINDOW_HEIGHT * 0.75);

    // Draw axes
    XDrawLine(disp, win, gc, BORDER_SIZE, plot_height - BORDER_SIZE, WINDOW_WIDTH - BORDER_SIZE, plot_height - BORDER_SIZE);
    XDrawLine(disp, win, gc, BORDER_SIZE, BORDER_SIZE, BORDER_SIZE, plot_height - BORDER_SIZE);

    // Draw spectrum data
    XSetForeground(disp, gc, 0x0000FF);
    for (int i = 1; i < n / 2; i++) {
        int x1 = BORDER_SIZE + (int)((i - 1) * x_scale);
        int y1 = plot_height - BORDER_SIZE - (int)((mag_db[i - 1] - (-120.0)) * y_scale);
        int x2 = BORDER_SIZE + (int)(i * x_scale);
        int y2 = plot_height - BORDER_SIZE - (int)((mag_db[i] - (-120.0)) * y_scale);
        XDrawLine(disp, win, gc, x1, y1, x2, y2);
    }
}

static void draw_time_domain(Display *disp, Window win, GC gc, const signed char *data, int n, const char *title) {
    XSetForeground(disp, gc, WhitePixel(disp, DefaultScreen(disp)));
    XFillRectangle(disp, win, gc, 0, (int)(WINDOW_HEIGHT * 0.75), WINDOW_WIDTH, (int)(WINDOW_HEIGHT * 0.25));

    double x_scale = (double)(WINDOW_WIDTH - 2 * BORDER_SIZE) / n;
    double y_scale = (double)(WINDOW_HEIGHT * 0.25 - 2 * BORDER_SIZE) / (MAX_Y_VALUE - MIN_Y_VALUE + 2 * Y_MARGIN);
    int plot_offset = (int)(WINDOW_HEIGHT * 0.75);
    int plot_height = (int)(WINDOW_HEIGHT * 0.25);

    // Draw axes
    XSetForeground(disp, gc, BlackPixel(disp, DefaultScreen(disp)));
    XDrawLine(disp, win, gc, BORDER_SIZE, plot_offset + plot_height / 2, WINDOW_WIDTH - BORDER_SIZE, plot_offset + plot_height / 2);
    XDrawLine(disp, win, gc, BORDER_SIZE, plot_offset + BORDER_SIZE, BORDER_SIZE, plot_offset + plot_height - BORDER_SIZE);

    // Draw time-domain signal
    XSetForeground(disp, gc, 0x0000FF);
    for (int i = 1; i < n; i++) {
        int x1 = BORDER_SIZE + (int)((i - 1) * x_scale);
        int y1 = plot_offset + plot_height / 2 - (int)(data[i - 1] * y_scale);
        int x2 = BORDER_SIZE + (int)(i * x_scale);
        int y2 = plot_offset + plot_height / 2 - (int)(data[i] * y_scale);
        XDrawLine(disp, win, gc, x1, y1, x2, y2);
    }
}

