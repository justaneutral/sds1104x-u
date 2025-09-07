#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#define MAX_WINDOWS 10
#define MAX_SAMPLES_PER_WINDOW 1000
#define WINDOW_WIDTH 400
#define WINDOW_HEIGHT 300

// Structure to hold state for each window
typedef struct {
    Display *display;
    Window window;
    GC gc;
    int is_open;
    int mode; // 0: Points, 1: Lines
    int num_samples;
    double samples_x[MAX_SAMPLES_PER_WINDOW];
    double samples_y[MAX_SAMPLES_PER_WINDOW];
} WindowState;

static WindowState window_states[MAX_WINDOWS] = {0};

// Function prototypes
static void setup_x11(int n);
static void draw_graph(int n);
static void cleanup_x11(int n);

// Main function for handling commands
int x11_multiplot(const char *command) {
    char cmd_str[256];
    strcpy(cmd_str, command);
    
    char *token = strtok(cmd_str, ",");
    
    if (token == NULL) {
        return -1;
    }
    
    // Command: open
    if (strcmp(token, "open") == 0) {
        token = strtok(NULL, ",");
        int n = token ? atoi(token) : -1;
        if (n >= 0 && n < MAX_WINDOWS && !window_states[n].is_open) {
            setup_x11(n);
            return 0;
        }
    }
    
    // Command: close
    else if (strcmp(token, "close") == 0) {
        token = strtok(NULL, ",");
        int n = token ? atoi(token) : -1;
        if (n >= 0 && n < MAX_WINDOWS && window_states[n].is_open) {
            cleanup_x11(n);
            return 0;
        }
    }
    
    // Command: plot
    else if (strcmp(token, "plot") == 0) {
        token = strtok(NULL, ",");
        int n = token ? atoi(token) : -1;
        token = strtok(NULL, ",");
        double x = token ? atof(token) : -1.0;
        token = strtok(NULL, ",");
        double y = token ? atof(token) : -1.0;
        
        if (n >= 0 && n < MAX_WINDOWS && window_states[n].is_open) {
            if (window_states[n].num_samples < MAX_SAMPLES_PER_WINDOW) {
                window_states[n].samples_x[window_states[n].num_samples] = x;
                window_states[n].samples_y[window_states[n].num_samples] = y;
                window_states[n].num_samples++;
                draw_graph(n);
            }
            return 0;
        }
    }
    
    // Command: mode
    else if (strcmp(token, "mode") == 0) {
        token = strtok(NULL, ",");
        int n = token ? atoi(token) : -1;
        token = strtok(NULL, ",");
        int m = token ? atoi(token) : -1;
        if (n >= 0 && n < MAX_WINDOWS && window_states[n].is_open && (m == 0 || m == 1)) {
            window_states[n].mode = m;
            draw_graph(n);
            return 0;
        }
    }
    
    return -1; // Unknown or invalid command
}

static void setup_x11(int n) {
    WindowState *ws = &window_states[n];
    ws->display = XOpenDisplay(NULL);
    if (ws->display == NULL) {
        fprintf(stderr, "Cannot open display for window %d\n", n);
        return;
    }

    int screen = DefaultScreen(ws->display);
    unsigned long black = BlackPixel(ws->display, screen);
    unsigned long white = WhitePixel(ws->display, screen);

    ws->window = XCreateSimpleWindow(ws->display, RootWindow(ws->display, screen),
                                     10 + n * 40, 10 + n * 40, WINDOW_WIDTH, WINDOW_HEIGHT, 1,
                                     black, white);

    XSelectInput(ws->display, ws->window, ExposureMask);
    XMapWindow(ws->display, ws->window);
    
    ws->gc = XCreateGC(ws->display, ws->window, 0, NULL);
    XSetForeground(ws->display, ws->gc, black);
    
    ws->is_open = 1;
    ws->num_samples = 0;
    ws->mode = 1; // Default to lines
}

static void draw_graph(int n) {
    WindowState *ws = &window_states[n];
    XClearWindow(ws->display, ws->window);

    if (ws->num_samples < 2) return;

    // Simple normalization and scaling
    double min_x = ws->samples_x[0];
    double max_x = ws->samples_x[0];
    double min_y = ws->samples_y[0];
    double max_y = ws->samples_y[0];
    
    for (int i = 1; i < ws->num_samples; i++) {
        if (ws->samples_x[i] < min_x) min_x = ws->samples_x[i];
        if (ws->samples_x[i] > max_x) max_x = ws->samples_x[i];
        if (ws->samples_y[i] < min_y) min_y = ws->samples_y[i];
        if (ws->samples_y[i] > max_y) max_y = ws->samples_y[i];
    }
    
    double range_x = (max_x - min_x) > 0 ? (max_x - min_x) : 1.0;
    double range_y = (max_y - min_y) > 0 ? (max_y - min_y) : 1.0;

    int w = WINDOW_WIDTH;
    int h = WINDOW_HEIGHT;
    
    if (ws->mode == 1) { // Lines
        for (int i = 0; i < ws->num_samples - 1; i++) {
            int x1 = (int)((ws->samples_x[i] - min_x) / range_x * w);
            int y1 = (int)(h - (ws->samples_y[i] - min_y) / range_y * h);
            int x2 = (int)((ws->samples_x[i+1] - min_x) / range_x * w);
            int y2 = (int)(h - (ws->samples_y[i+1] - min_y) / range_y * h);
            XDrawLine(ws->display, ws->window, ws->gc, x1, y1, x2, y2);
        }
    } else { // Points
        for (int i = 0; i < ws->num_samples; i++) {
            int x = (int)((ws->samples_x[i] - min_x) / range_x * w);
            int y = (int)(h - (ws->samples_y[i] - min_y) / range_y * h);
            XDrawPoint(ws->display, ws->window, ws->gc, x, y);
        }
    }
    XFlush(ws->display);
}

static void cleanup_x11(int n) {
    WindowState *ws = &window_states[n];
    if (ws->is_open) {
        XFreeGC(ws->display, ws->gc);
        XDestroyWindow(ws->display, ws->window);
        XCloseDisplay(ws->display);
        memset(ws, 0, sizeof(WindowState)); // Reset state
    }
}

