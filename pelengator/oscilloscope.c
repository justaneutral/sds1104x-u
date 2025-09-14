#include "oscilloscope.h"
#include <stdio.h>
#include <stdlib.h>

static void draw_grid(Oscilloscope *osc, int x, int y, int w, int h, int step) {
    XSetForeground(osc->display, osc->gc, BlackPixel(osc->display, DefaultScreen(osc->display)));
    for(int i=0;i<=w;i+=step){
        XDrawLine(osc->display, osc->window, osc->gc, x+i, y, x+i, y+h);
    }
    for(int i=0;i<=h;i+=step){
        XDrawLine(osc->display, osc->window, osc->gc, x, y+i, x+w, y+i);
    }
}

void osc_initialize(Oscilloscope *osc, int width, int height, int buf_len) {
    osc->width = width;
    osc->height = height;
    osc->buf_len = buf_len;
    osc->idx = 0;

    osc->x_buf = malloc(sizeof(double)*buf_len);
    osc->y_buf = malloc(sizeof(double)*buf_len);
    for(int i=0;i<buf_len;i++) { osc->x_buf[i]=0; osc->y_buf[i]=0; }

    osc->display = XOpenDisplay(NULL);
    if(!osc->display){fprintf(stderr,"Cannot open display\n"); exit(1);}
    int screen = DefaultScreen(osc->display);
    osc->window = XCreateSimpleWindow(osc->display, RootWindow(osc->display,screen),
                                      0,0,width,height,1,
                                      BlackPixel(osc->display,screen),
                                      WhitePixel(osc->display,screen));
    XStoreName(osc->display, osc->window, "Oscilloscope");
    XSelectInput(osc->display, osc->window, ExposureMask | KeyPressMask);
    XMapWindow(osc->display, osc->window);
    osc->gc = DefaultGC(osc->display, screen);
}

void oscilloscope_close(Oscilloscope *osc){
    free(osc->x_buf);
    free(osc->y_buf);
    XCloseDisplay(osc->display);
}

void osc_add_sample(Oscilloscope *osc, double x, double y){
    osc->x_buf[osc->idx] = x;
    osc->y_buf[osc->idx] = y;
    osc->idx = (osc->idx + 1) % osc->buf_len;
}

static void draw_signal(Oscilloscope *osc, double *buf, int buf_len,
                        int left, int top, int width, int height,
                        unsigned long color, const char* label) {
    XSetForeground(osc->display, osc->gc, BlackPixel(osc->display, DefaultScreen(osc->display)));
    draw_grid(osc, left, top, width, height, 20);

    XSetForeground(osc->display, osc->gc, color);
    XDrawString(osc->display, osc->window, osc->gc, left, top-5, label, strlen(label));

    for(int i=1;i<buf_len;i++){
        int idx1 = (osc->idx + i-1) % buf_len;
        int idx2 = (osc->idx + i) % buf_len;
        int x1 = left + (i-1)*width/buf_len;
        int y1 = top + height/2 - buf[idx1]*height/2;
        int x2 = left + i*width/buf_len;
        int y2 = top + height/2 - buf[idx2]*height/2;
        XDrawLine(osc->display, osc->window, osc->gc, x1,y1,x2,y2);
    }
}

static void draw_xy(Oscilloscope *osc, int left, int top, int size){
    draw_grid(osc, left, top, size, size, 20);
    XSetForeground(osc->display, osc->gc, 0x0000ff);
    XDrawString(osc->display, osc->window, osc->gc, left, top-5, "X-Y Plot", 9);

    for(int i=0;i<osc->buf_len;i++){
        int idx = (osc->idx + i) % osc->buf_len;
        int px = left + (osc->x_buf[idx]+1)/2*size;
        int py = top + size - (osc->y_buf[idx]+1)/2*size;
        XDrawPoint(osc->display, osc->window, osc->gc, px, py);
    }
}

void osc_draw(Oscilloscope *osc){
    XSetForeground(osc->display, osc->gc, WhitePixel(osc->display, DefaultScreen(osc->display)));
    XFillRectangle(osc->display, osc->window, osc->gc, 0,0,osc->width,osc->height);

    int margin = 50;
    int left_width = (osc->width - 3*margin)/2;
    int right_size = left_width;
    int top_height = (osc->height - 3*margin)/2;
    int bottom_height = top_height;

    draw_signal(osc, osc->x_buf, osc->buf_len, margin, margin, left_width, top_height, 0xff0000, "X Signal");
    draw_signal(osc, osc->y_buf, osc->buf_len, margin, margin+top_height+margin, left_width, bottom_height, 0x00aa00, "Y Signal");
    draw_xy(osc, left_width + 2*margin, margin, right_size);
}
