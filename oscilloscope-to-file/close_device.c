#include <stdio.h>
#include "visa_util.h"

// Function to close the VISA sessions
void close_device(ViSession defaultRM, ViSession instr) {
    if (instr) {
        viClose(instr);
    }
    if (defaultRM) {
        viClose(defaultRM);
    }
    printf("Successfully closed VISA sessions.\n");
}

