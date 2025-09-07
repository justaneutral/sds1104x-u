#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <math.h>

extern int x11_multiplot(const char *command);

int main() {
    // Open two windows, 0 and 1
    x11_multiplot("open,0");
    x11_multiplot("open,1");

    // Set window 1 to points mode
    x11_multiplot("mode,1,0");

    // Plot some sine wave data to both windows
    for (int i = 0; i < 100; i++) {
        double x = i * 0.1;
        double y1 = sin(x);
        double y2 = cos(x);
        char cmd1[256], cmd2[256];
        
        sprintf(cmd1, "plot,0,%f,%f", x, y1);
        sprintf(cmd2, "plot,1,%f,%f", x, y2);
        
        x11_multiplot(cmd1);
        x11_multiplot(cmd2);
        
        usleep(10000);
    }
    
    // Close the windows after a delay
    sleep(5);
    x11_multiplot("close,0");
    x11_multiplot("close,1");

    return 0;
}

