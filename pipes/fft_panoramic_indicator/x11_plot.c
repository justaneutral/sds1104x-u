#include "x11_plot.h"
#include "fft_lib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>

#define WINDOW_WIDTH 800
#define WINDOW_HEIGHT 800
#define BORDER_SIZE 50
#define FONT_NAME "9x15"
#define MIN_Y_VALUE -128.0
#define MAX_Y_VALUE 127.0
#define Y_MARGIN 5.0
#define SPECTRUM_PLOT_HEIGHT 0.75
#define TIME_PLOT_HEIGHT 0.25

static Display *disp;
static Window win;
static GC gc;
static XFontStruct *font_info;
static int is_initialized = 0;
static int fft_size;

static void draw_spectrum(const double *mag_db) {
    int plot_height = (int)(WINDOW_HEIGHT * SPECTRUM_PLOT_HEIGHT);
    XSetForeground(disp, gc, WhitePixel(disp, DefaultScreen(disp)));
    XFillRectangle(disp, win, gc, 0, 0, WINDOW_WIDTH, plot_height);

    XSetForeground(disp, gc, BlackPixel(disp, DefaultScreen(disp)));
    XDrawLine(disp, win, gc, BORDER_SIZE, plot_height - BORDER_SIZE, WINDOW_WIDTH - BORDER_SIZE, plot_height - BORDER_SIZE);
    XDrawLine(disp, win, gc, BORDER_SIZE, BORDER_SIZE, BORDER_SIZE, plot_height - BORDER_SIZE);

    char label[64];
    sprintf(label, "Frequency (Hz)");
    XDrawString(disp, win, gc, WINDOW_WIDTH / 2 - 50, plot_height - 10, label, strlen(label));
    sprintf(label, "Magnitude (dB)");
    XDrawString(disp, win, gc, 5, plot_height / 2 - 20, label, strlen(label));

    double min_db = -80.0;
    double max_db = 0.0;
    double y_scale = (double)(plot_height - 2 * BORDER_SIZE) / (max_db - min_db);
    int y_step_px = (plot_height - 2 * BORDER_SIZE) / 4;
    for (int i = 0; i <= 4; i++) {
        int y_pos = BORDER_SIZE + i * y_step_px;
        XDrawLine(disp, win, gc, BORDER_SIZE - 5, y_pos, BORDER_SIZE, y_pos);
        sprintf(label, "%.0f", max_db - (i * 20.0));
        XDrawString(disp, win, gc, 5, y_pos + 5, label, strlen(label));
    }

    XSetForeground(disp, gc, 0x0000FF);
    double x_scale = (double)(WINDOW_WIDTH - 2 * BORDER_SIZE) / (fft_size / 2);
    for (int i = 1; i < fft_size / 2; i++) {
        int x1 = BORDER_SIZE + (int)((i - 1) * x_scale);
        int y1 = plot_height - BORDER_SIZE - (int)((mag_db[i - 1] - min_db) * y_scale);
        int x2 = BORDER_SIZE + (int)(i * x_scale);
        int y2 = plot_height - BORDER_SIZE - (int)((mag_db[i] - min_db) * y_scale);
        XDrawLine(disp, win, gc, x1, y1, x2, y2);
    }
}

static void draw_time_domain(const signed char *data) {
    int plot_offset = (int)(WINDOW_HEIGHT * SPECTRUM_PLOT_HEIGHT);
    int plot_height = (int)(WINDOW_HEIGHT * TIME_PLOT_HEIGHT);
    XSetForeground(disp, gc, WhitePixel(disp, DefaultScreen(disp)));
    XFillRectangle(disp, win, gc, 0, plot_offset, WINDOW_WIDTH, plot_height);

    XSetForeground(disp, gc, BlackPixel(disp, DefaultScreen(disp)));
    XDrawLine(disp, win, gc, BORDER_SIZE, plot_offset + plot_height / 2, WINDOW_WIDTH - BORDER_SIZE, plot_offset + plot_height / 2);
    XDrawLine(disp, win, gc, BORDER_SIZE, plot_offset + BORDER_SIZE, BORDER_SIZE, plot_offset + plot_height - BORDER_SIZE);

    char label[64];

    double x_scale = (double)(WINDOW_WIDTH - 2 * BORDER_SIZE) / fft_size;
    double y_range = MAX_Y_VALUE - MIN_Y_VALUE + 2 * Y_MARGIN;
    double y_scale = (double)(plot_height - 2 * BORDER_SIZE) / y_range;
    
    // Draw Y-axis scale marks and labels
    int y_step_px = (plot_height - 2 * BORDER_SIZE) / 4;
    for (int i = 0; i <= 4; i++) {
        int y_pos = plot_offset + BORDER_SIZE + i * y_step_px;
        XDrawLine(disp, win, gc, BORDER_SIZE - 5, y_pos, BORDER_SIZE, y_pos);
        double val = MAX_Y_VALUE - (double)i * (y_range / 4.0) + Y_MARGIN;
        sprintf(label, "%.0f", val);
        XDrawString(disp, win, gc, 5, y_pos + 5, label, strlen(label));
    }
    
    XSetForeground(disp, gc, 0x0000FF);
    int y_offset = plot_offset + plot_height / 2;
    int y_plot_range = plot_height - 2 * BORDER_SIZE;
    double y_scale_factor = (double)y_plot_range / y_range;
    printf("y_offset=%d\n",y_offset);
    printf("y_plot_range=%d\n",y_plot_range);

    for (int i = 1; i < fft_size; i++) {
        int x1 = BORDER_SIZE + (int)((i - 1) * x_scale);
        int y1 = y_offset - (int)((data[i - 1] - MIN_Y_VALUE) * y_scale_factor - y_plot_range / 2);
        int x2 = BORDER_SIZE + (int)(i * x_scale);
        int y2 = y_offset - (int)((data[i] - MIN_Y_VALUE) * y_scale_factor - y_plot_range / 2);
        XDrawLine(disp, win, gc, x1, y1, x2, y2);
        //printf("d[%d]=%d : line %d,%d->%d,%d\n",i,data[i],x1,y1,x2,y2);
    }
}

void init_fft_and_time_plot(const char *window_title, int n) {
    if (is_initialized) return;
    fft_size = n;

    disp = XOpenDisplay(NULL);
    if (disp == NULL) {
        fprintf(stderr, "Cannot open display\n");
        exit(1);
    }
    int screen = DefaultScreen(disp);
    unsigned long black = BlackPixel(disp, screen);
    unsigned long white = WhitePixel(disp, screen);
    win = XCreateSimpleWindow(disp, RootWindow(disp, screen), 10, 10, WINDOW_WIDTH, WINDOW_HEIGHT, 1, black, white);
    XStoreName(disp, win, window_title);
    XSelectInput(disp, win, ExposureMask | KeyPressMask);
    XMapWindow(disp, win);
    gc = XCreateGC(disp, win, 0, NULL);
    XSetForeground(disp, gc, black);
    font_info = XLoadQueryFont(disp, FONT_NAME);
    if (font_info) XSetFont(disp, gc, font_info->fid);
    is_initialized = 1;
}

void update_fft_and_time_plot(const signed char *input_buffer, int n, long long current_time_us) {
    if (!is_initialized) return;

    double mag_db[n / 2];
    process_fft(input_buffer, mag_db, n);

    XEvent event;
    while (XPending(disp)) {
        XNextEvent(disp, &event);
        if (event.type == KeyPress) {
            cleanup_fft_and_time_plot();
            exit(0);
        }
    }

    draw_spectrum(mag_db);
    draw_time_domain(input_buffer);
    XFlush(disp);
}

void cleanup_fft_and_time_plot() {
    if (!is_initialized) return;
    XFreeGC(disp, gc);
    XDestroyWindow(disp, win);
    XCloseDisplay(disp);
    is_initialized = 0;
}

void handle_x11_events() {
    if (!is_initialized) return;
    XEvent event;
    while (XPending(disp)) {
        XNextEvent(disp, &event);
        if (event.type == KeyPress) {
            cleanup_fft_and_time_plot();
            exit(0);
        }
    }
}

