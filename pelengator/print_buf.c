#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>


void print_buf(char *buffer,unsigned int offset, unsigned int length,unsigned int body_offset, unsigned int indentation)
{
    unsigned int body_offset_counter = 0;
    unsigned int indentation_counter = 0;
    unsigned int line_counter = 0;
    char b;


    if(length>0)
    {
        for(int i=offset;i<(offset+length);i++)
        {
                if((body_offset == 0 || body_offset_counter >= body_offset) && indentation_counter == 0)
                {
                      printf("%04u> ", line_counter++);
                }

            b = buffer[i];
            short v = b;
            if(isprint(b))
                printf(".*%c(%+03d)",b,v);
            else
                printf(".%02hhX(%+03d)",b,v);
            if(body_offset > 0 && body_offset_counter < body_offset)
            {
                if((++body_offset_counter) >= body_offset)
                {
                    printf("\n");
                }
            }
            else if(indentation > 0)
            {
                if((++indentation_counter)>= indentation)
                {
                    indentation_counter = 0;
                    printf("\n");
                }
            }
        }
    }
    printf("\n\n");
}


