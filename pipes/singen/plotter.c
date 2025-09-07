#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#define MAX_SAMPLES 500000 
#define WINDOW_WIDTH 800
#define WINDOW_HEIGHT 600
#define UPDATE_INTERVAL_MS 100 // Update every 100 milliseconds

typedef struct {
    double time;
    double value;
} Sample;

Display *display;
Window window;
GC gc;
int screen;

Sample samples[MAX_SAMPLES];
int num_samples = 0;
int max_samples_per_window = 1000; // Number of samples to show in the window

void draw_graph() {
    XClearWindow(display, window);

    if (num_samples < 2) {
        return;
    }

    int start_index = (num_samples > max_samples_per_window) ? num_samples - max_samples_per_window : 0;
    
    double max_value = 110.0;
    double min_value = -110.0;

    double time_range = samples[num_samples - 1].time - samples[start_index].time;
    if (time_range == 0) time_range = 1.0; 

    double scale_x = (double)WINDOW_WIDTH / time_range;
    double scale_y = (double)WINDOW_HEIGHT / (max_value - min_value);

    XDrawLine(display, window, gc, 0, WINDOW_HEIGHT / 2, WINDOW_WIDTH, WINDOW_HEIGHT / 2);
    
    for (int i = start_index; i < num_samples - 1; i++) {
        int x1 = (int)((samples[i].time - samples[start_index].time) * scale_x);
        int y1 = (int)(WINDOW_HEIGHT / 2 - samples[i].value * scale_y);
        int x2 = (int)((samples[i+1].time - samples[start_index].time) * scale_x);
        int y2 = (int)(WINDOW_HEIGHT / 2 - samples[i+1].value * scale_y);
        XDrawLine(display, window, gc, x1, y1, x2, y2);
    }
}

void setup_x11() {
    display = XOpenDisplay(NULL);
    if (display == NULL) {
        fprintf(stderr, "Cannot open display\n");
        exit(1);
    }
    screen = DefaultScreen(display);
    unsigned long black = BlackPixel(display, screen);
    unsigned long white = WhitePixel(display, screen);
    window = XCreateSimpleWindow(display, RootWindow(display, screen),
                                 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, 1, black, white);
    XSelectInput(display, window, ExposureMask | KeyPressMask);
    XMapWindow(display, window);
    gc = XCreateGC(display, window, 0, NULL);
    XSetForeground(display, gc, black);
}

int main() {
    // Set stdin to non-blocking mode
    fcntl(fileno(stdin), F_SETFL, O_NONBLOCK);

    setup_x11();
    
    XEvent event;
    clock_t last_update = clock();

    while (1) {
        // Read samples from stdin in a non-blocking manner
        double time, sample;
        if (fscanf(stdin, "%lf %lf", &time, &sample) == 2 && num_samples < MAX_SAMPLES) {
            samples[num_samples].time = time;
            samples[num_samples].value = sample;
            num_samples++;
        }

        // Handle X events
        while (XPending(display)) {
            XNextEvent(display, &event);
            if (event.type == Expose) {
                draw_graph();
            }
            if (event.type == KeyPress) {
                // Exit on any key press
                goto cleanup; 
            }
        }
        
        // Timer for updates
        if ((double)(clock() - last_update) / CLOCKS_PER_SEC * 1000 > UPDATE_INTERVAL_MS) {
            if (num_samples > 1) {
                draw_graph();
            }
            last_update = clock();
        }
    }

cleanup:
    XFreeGC(display, gc);
    XDestroyWindow(display, window);
    XCloseDisplay(display);
    return 0;
}

