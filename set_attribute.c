#include <visa.h>
#include <stdio.h>

ViStatus set_attribute(ViSession vi, ViAttr attribute, ViAttrState value) 
{
    ViStatus status;

    // Set the attribute
    status = viSetAttribute(vi, attribute, value);
    if (status != VI_SUCCESS) {
        printf("Error setting attribute %x: %ld\n\n",attribute,status);
        return status;
    }

    printf("Attribute %x set to %u\n\n",attribute,value);
    return VI_SUCCESS;
}
