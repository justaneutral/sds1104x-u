#include <stdio.h>
#include "visa_util.h"

ViStatus open_device(ViSession* defaultRM, ViSession* instr, const char* resourceName) {
    ViStatus status;

    status = viOpenDefaultRM(defaultRM);
    if (status < VI_SUCCESS) {
        // Fix: Changed %ld to %d for ViStatus
        printf("Error: Could not open the default Resource Manager. Status: %d\n", status);
        return status;
    }

    status = viOpen(*defaultRM, (ViChar*)resourceName, VI_NULL, VI_NULL, instr);
    if (status < VI_SUCCESS) {
        // Fix: Changed %ld to %d for ViStatus
        printf("Error: Could not open the device at %s. Status: %d\n", resourceName, status);
        viClose(*defaultRM);
        return status;
    }

    return VI_SUCCESS;
}

