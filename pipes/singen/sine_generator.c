#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <unistd.h> // For usleep

#define _USE_MATH_DEFINES // For M_PI

#define AMPLITUDE   100.0
#define FREQUENCY   1.0
#define SAMPLE_RATE 100.0
#define DURATION    20.0 // seconds

int main() {
    double time = 0.0;
    double time_step = 1.0 / SAMPLE_RATE;
    double period = 1.0 / FREQUENCY;
    long long num_samples = (long long)(DURATION * SAMPLE_RATE);

    for (long long i = 0; i < num_samples; i++) {
        double sample = AMPLITUDE * sin(2.0 * M_PI * FREQUENCY * time);
        printf("%f %f\n", time, sample);
        fflush(stdout); // Flush the output buffer to ensure data is sent immediately
        
        time += time_step;
        usleep(1000000 / SAMPLE_RATE); // Simulate real-time sampling (adjust sleep time as needed)
    }

    return 0;
}

