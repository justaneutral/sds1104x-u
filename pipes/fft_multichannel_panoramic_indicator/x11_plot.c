#include "x11_plot.h"
#include "fft_lib.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <X11/Xutil.h>

#define DEFAULT_WINDOW_WIDTH  1000
#define DEFAULT_WINDOW_HEIGHT 800
#define BORDER_PX 50

struct PlotContext {
    Display *disp;
    int screen;
    Window win;
    GC gc;
    XFontStruct *font;
    Colormap cmap;

    int width, height;
    int fft_size;
    int num_channels;
    double fs_hz;              /* sample rate */
    unsigned long bg_pixel;    /* yellow background */

    /* spectra buffer: K * (N/2) doubles */
    double *mag_db;

    /* colors per channel */
    unsigned long *chan_pixels;

    int is_open;
    char title[128];
};

static int alloc_named(Display *dpy, Colormap cmap, const char *name, XColor *xc) {
    return XAllocNamedColor(dpy, cmap, name, xc, xc) != 0;
}

static unsigned long choose_color(Display *dpy, Colormap cmap, int ch) {
    /* ch1->orange, ch2->red, ch3->blue, ch4->dark green */
    XColor c;
    const char *name = NULL;
    switch (ch) {
        case 0: name = "orange";     break;
        case 1: name = "red";        break;
        case 2: name = "blue";       break;
        case 3: name = "dark green"; break;
        default:
            name = (ch % 2 == 0) ? "black" : "gray30";
            break;
    }
    if (alloc_named(dpy, cmap, name, &c)) return c.pixel;
    if (alloc_named(dpy, cmap, "black", &c)) return c.pixel;
    return BlackPixel(dpy, DefaultScreen(dpy));
}

static unsigned long get_bg(Display *dpy, Colormap cmap) {
    XColor c;
    if (alloc_named(dpy, cmap, "yellow", &c)) return c.pixel;
    return WhitePixel(dpy, DefaultScreen(dpy));
}

static void draw_string(Display *dpy, Window w, GC gc, int x, int y, const char *s) {
    XDrawString(dpy, w, gc, x, y, s, (int)strlen(s));
}

static void draw_axes_box(Display *dpy, Window win, GC gc,
                          int left, int top, int right, int bottom,
                          const char *title)
{
    XDrawRectangle(dpy, win, gc, left, top, (unsigned int)(right-left), (unsigned int)(bottom-top));
    if (title) draw_string(dpy, win, gc, left + 5, top + 15, title);
}

/* Format Hz neatly to Hz/kHz/MHz */
static void fmt_hz(double hz, char *buf, size_t sz) {
    if (hz >= 1e6) snprintf(buf, sz, "%.3f MHz", hz/1e6);
    else if (hz >= 1e3) snprintf(buf, sz, "%.3f kHz", hz/1e3);
    else snprintf(buf, sz, "%.0f Hz", hz);
}

/* Format seconds neatly to s/ms/us */
static void fmt_sec(double s, char *buf, size_t sz) {
    if (s >= 1.0) snprintf(buf, sz, "%.3f s", s);
    else if (s >= 1e-3) snprintf(buf, sz, "%.3f ms", s*1e3);
    else snprintf(buf, sz, "%.3f us", s*1e6);
}

static void draw_spectrum_multi(struct PlotContext *ctx,
                                int x0, int y0, int w, int h)
{
    Display *dpy = ctx->disp;
    Window win = ctx->win;
    GC gc = ctx->gc;

    /* fill region with yellow background */
    XSetForeground(dpy, gc, ctx->bg_pixel);
    XFillRectangle(dpy, win, gc, x0, y0, (unsigned int)w, (unsigned int)h);

    XSetForeground(dpy, gc, BlackPixel(dpy, ctx->screen));
    int left = x0 + BORDER_PX;
    int right = x0 + w - BORDER_PX;
    int top = y0 + BORDER_PX;
    int bottom = y0 + h - BORDER_PX;
    if (right <= left || bottom <= top) return;

    draw_axes_box(dpy, win, gc, left, top, right, bottom, "Spectrum");

    const double dB_min = -120.0, dB_max = 0.0;

    /* y ticks (bottom = -120 dB, top = 0 dB) */
    int y_ticks = 4;
    for (int i = 0; i <= y_ticks; i++) {
        double frac = (double)i / (double)y_ticks;          /* 0..1 bottom->top */
        int y = bottom - (int)((bottom - top) * frac);
        XDrawLine(dpy, win, gc, left - 5, y, left, y);
        char lab[32];
        double val = dB_min + (dB_max - dB_min) * frac;     /* −120 → 0 */
        snprintf(lab, sizeof(lab), "%.0f dB", val);
        draw_string(dpy, win, gc, x0 + 5, y + 5, lab);
    }

    /* x (frequency) ticks 0..Fs/2 */
    double f_max = ctx->fs_hz * 0.5;
    int x_ticks = 8; /* nice resolution */
    for (int i = 0; i <= x_ticks; i++) {
        double frac = (double)i / (double)x_ticks;
        int x = left + (int)((right - left) * frac);
        XDrawLine(dpy, win, gc, x, bottom, x, bottom + 5);
        char lab[48];
        fmt_hz(f_max * frac, lab, sizeof(lab));
        draw_string(dpy, win, gc, x - 25, bottom + 18, lab);
    }
    /* axes labels */
    draw_string(dpy, win, gc, (left + right)/2 - 40, bottom + 32, "Frequency");

    int N2 = ctx->fft_size / 2;
    double x_scale = (double)(right - left) / (double)N2;

    /* traces */
    for (int ch = 0; ch < ctx->num_channels; ch++) {
        XSetForeground(dpy, gc, ctx->chan_pixels[ch]);
        const double *mag = ctx->mag_db + (size_t)ch * (size_t)N2;
        for (int i = 1; i < N2; i++) {
            int x1 = left + (int)((i - 1) * x_scale);
            int x2 = left + (int)(i * x_scale);

            double y1f = (mag[i - 1] - dB_min) / (dB_max - dB_min); if (y1f < 0) y1f = 0; if (y1f > 1) y1f = 1;
            double y2f = (mag[i]     - dB_min) / (dB_max - dB_min); if (y2f < 0) y2f = 0; if (y2f > 1) y2f = 1;

            int y1 = bottom - (int)((bottom - top) * y1f);
            int y2 = bottom - (int)((bottom - top) * y2f);
            XDrawLine(dpy, win, gc, x1, y1, x2, y2);
        }
    }

    /* Legend (first 4 named) */
    const char *names[] = {"ch1 (orange)", "ch2 (red)", "ch3 (blue)", "ch4 (dark green)"};
    int legend_x = right - 200, legend_y = top + 20;
    for (int ch = 0; ch < ctx->num_channels && ch < 8; ch++) {
        XSetForeground(dpy, gc, ctx->chan_pixels[ch]);
        XDrawLine(dpy, win, gc, legend_x, legend_y + ch*16, legend_x + 25, legend_y + ch*16);
        XSetForeground(dpy, gc, BlackPixel(dpy, ctx->screen));
        char buf[64];
        if (ch < 4) snprintf(buf, sizeof(buf), "%s", names[ch]);
        else snprintf(buf, sizeof(buf), "ch%d", ch+1);
        draw_string(dpy, win, gc, legend_x + 32, legend_y + ch*16 + 5, buf);
    }
}

static void draw_time_multi(struct PlotContext *ctx,
                            const signed char * const *channels,
                            int x0, int y0, int w, int h)
{
    Display *dpy = ctx->disp;
    Window win = ctx->win;
    GC gc = ctx->gc;

    /* fill region with yellow background */
    XSetForeground(dpy, gc, ctx->bg_pixel);
    XFillRectangle(dpy, win, gc, x0, y0, (unsigned int)w, (unsigned int)h);

    XSetForeground(dpy, gc, BlackPixel(dpy, ctx->screen));
    int left = x0 + BORDER_PX;
    int right = x0 + w - BORDER_PX;
    int top = y0 + BORDER_PX;
    int bottom = y0 + h - BORDER_PX;
    if (right <= left || bottom <= top) return;

    draw_axes_box(dpy, win, gc, left, top, right, bottom, "Waveform");

    const double min_y = -128.0, max_y = 127.0;

    /* y ticks */
    int y_ticks = 4;
    for (int i = 0; i <= y_ticks; i++) {
        double frac = (double)i / (double)y_ticks;
        int y = bottom - (int)((bottom - top) * frac);
        XDrawLine(dpy, win, gc, left - 5, y, left, y);
        char lab[32];
        double val = min_y + (max_y - min_y) * frac;
        snprintf(lab, sizeof(lab), "%.0f", val);
        draw_string(dpy, win, gc, x0 + 5, y + 5, lab);
    }

    /* x (time) ticks 0..N/Fs */
    int N = ctx->fft_size;
    double T = (double)N / ctx->fs_hz;
    int x_ticks = 8;
    for (int i = 0; i <= x_ticks; i++) {
        double frac = (double)i / (double)x_ticks;
        int x = left + (int)((right - left) * frac);
        XDrawLine(dpy, win, gc, x, bottom, x, bottom + 5);
        char lab[48];
        fmt_sec(T * frac, lab, sizeof(lab));
        draw_string(dpy, win, gc, x - 25, bottom + 18, lab);
    }
    draw_string(dpy, win, gc, (left + right)/2 - 20, bottom + 32, "Time");

    /* zero line */
    int midY = bottom - (int)((bottom - top) * ((0.0 - min_y) / (max_y - min_y)));
    XDrawLine(dpy, win, gc, left, midY, right, midY);

    /* traces */
    double x_scale = (double)(right - left) / (double)N;
    for (int ch = 0; ch < ctx->num_channels; ch++) {
        XSetForeground(dpy, gc, ctx->chan_pixels[ch]);
        const signed char *data = channels[ch];
        if (!data) continue;
        for (int i = 1; i < N; i++) {
            int x1 = left + (int)((i - 1) * x_scale);
            int x2 = left + (int)(i * x_scale);

            double y1f = ((double)data[i - 1] - min_y) / (max_y - min_y); if (y1f < 0) y1f = 0; if (y1f > 1) y1f = 1;
            double y2f = ((double)data[i]     - min_y) / (max_y - min_y); if (y2f < 0) y2f = 0; if (y2f > 1) y2f = 1;

            int y1 = bottom - (int)((bottom - top) * y1f);
            int y2 = bottom - (int)((bottom - top) * y2f);
            XDrawLine(dpy, win, gc, x1, y1, x2, y2);
        }
    }
}

PlotContext* plot_create(const char *window_title,
                         int fft_size,
                         int num_channels,
                         int width,
                         int height,
                         double sample_rate_hz)
{
    if (fft_size <= 0 || (fft_size & (fft_size - 1)) != 0) {
        fprintf(stderr, "fft_size must be a power of two > 0\n");
        return NULL;
    }
    if (num_channels <= 0) {
        fprintf(stderr, "num_channels must be > 0\n");
        return NULL;
    }

    PlotContext *ctx = (PlotContext*)calloc(1, sizeof(PlotContext));
    if (!ctx) return NULL;

    ctx->fft_size = fft_size;
    ctx->num_channels = num_channels;
    ctx->width = (width > 0) ? width : DEFAULT_WINDOW_WIDTH;
    ctx->height = (height > 0) ? height : DEFAULT_WINDOW_HEIGHT;
    ctx->fs_hz = (sample_rate_hz > 0) ? sample_rate_hz : 1.0; /* avoid div0 */
    snprintf(ctx->title, sizeof(ctx->title), "%s", window_title ? window_title : "FFT Viewer");

    ctx->mag_db = (double*)malloc(sizeof(double) * (size_t)num_channels * (size_t)(fft_size/2));
    if (!ctx->mag_db) { free(ctx); return NULL; }

    ctx->disp = XOpenDisplay(NULL);
    if (!ctx->disp) {
        fprintf(stderr, "Cannot open X display\n");
        free(ctx->mag_db);
        free(ctx);
        return NULL;
    }
    ctx->screen = DefaultScreen(ctx->disp);
    ctx->cmap = DefaultColormap(ctx->disp, ctx->screen);
    ctx->bg_pixel = get_bg(ctx->disp, ctx->cmap); /* yellow */

    unsigned long black = BlackPixel(ctx->disp, ctx->screen);

    ctx->win = XCreateSimpleWindow(ctx->disp,
                                   RootWindow(ctx->disp, ctx->screen),
                                   60, 60,
                                   (unsigned int)ctx->width,
                                   (unsigned int)ctx->height,
                                   1, black, ctx->bg_pixel); /* yellow bg */
    XStoreName(ctx->disp, ctx->win, ctx->title);
    XSelectInput(ctx->disp, ctx->win, ExposureMask | KeyPressMask | StructureNotifyMask);
    XMapWindow(ctx->disp, ctx->win);

    ctx->gc = XCreateGC(ctx->disp, ctx->win, 0, NULL);
    XSetForeground(ctx->disp, ctx->gc, black);

    ctx->font = XLoadQueryFont(ctx->disp, "9x15");
    if (ctx->font) XSetFont(ctx->disp, ctx->gc, ctx->font->fid);

    ctx->chan_pixels = (unsigned long*)malloc(sizeof(unsigned long) * (size_t)num_channels);
    if (!ctx->chan_pixels) {
        XFreeGC(ctx->disp, ctx->gc);
        XDestroyWindow(ctx->disp, ctx->win);
        XCloseDisplay(ctx->disp);
        free(ctx->mag_db);
        free(ctx);
        return NULL;
    }
    for (int ch = 0; ch < num_channels; ch++)
        ctx->chan_pixels[ch] = choose_color(ctx->disp, ctx->cmap, ch);

    ctx->is_open = 1;
    return ctx;
}

void plot_update(PlotContext *ctx,
                 const signed char * const *channels,
                 long long current_time_us)
{
    (void)current_time_us;
    if (!ctx || !ctx->is_open || !channels) return;

    int N = ctx->fft_size, N2 = N/2;
    for (int ch = 0; ch < ctx->num_channels; ch++) {
        const signed char *in = channels[ch];
        if (!in) continue;
        process_fft(in, ctx->mag_db + (size_t)ch * (size_t)N2, N);
    }

    /* drain events so Expose doesn't backlog */
    XEvent ev;
    while (XPending(ctx->disp)) XNextEvent(ctx->disp, &ev);

    int spec_h = (int)(ctx->height * 0.65);
    int time_h = ctx->height - spec_h;

    draw_spectrum_multi(ctx, 0, 0, ctx->width, spec_h);
    draw_time_multi(ctx, channels, 0, spec_h, ctx->width, time_h);

    XFlush(ctx->disp);
}

int plot_handle_events(PlotContext *ctx) {
    if (!ctx || !ctx->is_open) return 1;
    int should_close = 0;
    XEvent ev;
    while (XPending(ctx->disp)) {
        XNextEvent(ctx->disp, &ev);
        switch (ev.type) {
            case Expose: break;
            case KeyPress: should_close = 1; break;
            case DestroyNotify: should_close = 1; break;
            default: break;
        }
    }
    if (should_close) {
        ctx->is_open = 0;
        return 1;
    }
    return 0;
}

void plot_destroy(PlotContext *ctx) {
    if (!ctx) return;
    if (ctx->disp && ctx->win) XDestroyWindow(ctx->disp, ctx->win);
    if (ctx->disp && ctx->gc)  XFreeGC(ctx->disp, ctx->gc);
    if (ctx->disp && ctx->font) XFreeFont(ctx->disp, ctx->font);
    if (ctx->disp) XCloseDisplay(ctx->disp);
    free(ctx->mag_db);
    free(ctx->chan_pixels);
    free(ctx);
}

