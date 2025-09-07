#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>

#include "x11_multiplot.h"

int main() {
    char cmd[256];
    int i;
    double t;
    
    // --- Window 0: Standard Lines Mode ---
    x11_multiplot("open,0");
    
    for (i = 0; i < 200; i++) {
        t = i * 0.1;
        sprintf(cmd, "plot,0,%f,%f", t, sin(t));
        x11_multiplot(cmd);
        usleep(10000);
    }
    
    // --- Window 1: X-Y Plot Mode ---
    x11_multiplot("open,1");
    x11_multiplot("mode,1,2"); // Set mode to X-Y
    
    for (i = 0; i < 200; i++) {
        t = i * 0.1;
        sprintf(cmd, "plot,1,%f,%f", cos(t), sin(t)); // Plot a circle
        x11_multiplot(cmd);
        usleep(10000);
    }
    
    // --- Window 2: Points Mode ---
    x11_multiplot("open,2");
    x11_multiplot("mode,2,0"); // Set mode to Points
    
    for (i = 0; i < 200; i++) {
        t = i * 0.1;
        sprintf(cmd, "plot,2,%f,%f", t, cos(t));
        x11_multiplot(cmd);
        usleep(10000);
    }
    
    sleep(5);
    
    x11_multiplot("close,0");
    x11_multiplot("close,1");
    x11_multiplot("close,2");

    return 0;
}

