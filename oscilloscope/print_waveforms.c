#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#define preambula "DAT2,#9"
//usage print_waveforms(buffer,__BUFFER_BYTE_OFFSET__,__BUFFER_BYTE_CHANNAL_LEN__);

void print_waveforms(char *buffer,unsigned int offset, unsigned int length)
{
    int i,j;
    char *ch[] = 
    {
        strlen(preambula)+strstr(&buffer[offset+0*length],preambula),
        strlen(preambula)+strstr(&buffer[offset+1*length],preambula),
        strlen(preambula)+strstr(&buffer[offset+2*length],preambula),
        strlen(preambula)+strstr(&buffer[offset+3*length],preambula)
    };
    unsigned int num_samp[4],ns;
    for (i=0;i<4;i++)
    {
        num_samp[i]=0;
        for(j=0;j<9;j++)
        {
            num_samp[i] = num_samp[i]*10 + *(ch[i]++) - '0';
        }
        printf("num_samp[%d] = %u\n",i,num_samp[i]);
        fflush(stdout);
    }
    ns = (num_samp[0]<num_samp[1]?num_samp[0]:num_samp[1])<(num_samp[2]<num_samp[3]?num_samp[2]:num_samp[3])?(num_samp[0]<num_samp[1]?num_samp[0]:num_samp[1]):(num_samp[2]<num_samp[3]?num_samp[2]:num_samp[3]);


    for(i=0;i<ns;i++)
    {
        printf("%u:\t%d\t%d\t%d\t%d\n",i,*(ch[0]+i),*(ch[1]+i),*(ch[2]+i),*(ch[3]+i));
    }
}

