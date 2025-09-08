#ifndef X11_PLOT_H
#define X11_PLOT_H

#include <X11/Xlib.h>

void init_fft_and_time_plot(const char *window_title, int n);
void update_fft_and_time_plot(const signed char *input_buffer, int n, long long current_time_us);
void cleanup_fft_and_time_plot();
void handle_x11_events();

#endif

