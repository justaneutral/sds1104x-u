#ifndef OSCILLOSCOPE_H
#define OSCILLOSCOPE_H

#include <X11/Xlib.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

typedef struct {
    Display *display;
    Window window;
    GC gc;
    int width, height;

    // Signal buffers
    double *x_buf;
    double *y_buf;
    int buf_len;
    int idx;
} Oscilloscope;

void osc_initialize(Oscilloscope *osc, int width, int height, int buf_len);
void oscilloscope_close(Oscilloscope *osc);
void osc_add_sample(Oscilloscope *osc, double x, double y);
void osc_draw(Oscilloscope *osc);

#endif
