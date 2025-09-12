#ifndef X11_PLOT_H
#define X11_PLOT_H

#include <X11/Xlib.h>

typedef struct PlotContext PlotContext;

/* One window, K channels overlaid on the SAME axes:
   - Top region: all channel spectra with frequency ticks (0..Fs/2)
   - Bottom region: all channel waveforms with time ticks (0..N/Fs)
*/
PlotContext* plot_create(const char *window_title,
                         int fft_size,
                         int num_channels,
                         int width,
                         int height,
                         double sample_rate_hz); /* Fs */
PlotContext* plot_createc(const char *window_title,
                         int fft_size,
                         int num_channels,
                         int width,
                         int height,
                         double sample_rate_hz); /* Fs */

void plot_update(PlotContext *ctx,
                 const signed char * const *channels,
                 long long current_time_us);
void plot_updatec(PlotContext *ctx,
                 const double * const * channels_r,
                 const double * const * channels_i,
                 long long current_time_us);


int plot_handle_events(PlotContext *ctx);
void plot_destroy(PlotContext *ctx);

#endif

