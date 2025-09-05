#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#define preambula "DAT2,#9"
//usage print_waveforms(buffer,__BUFFER_BYTE_OFFSET__,__BUFFER_BYTE_CHANNAL_LEN__);

void print_waveforms(char *buffer,unsigned int offset, unsigned int length)
{
    int i,j;
    char tmpc;
    char *ch[] = {&buffer[offset],&buffer[offset+length],&buffer[offset+length*2],&buffer[offset+length*3]};
    unsigned int stp[] = {strlen(preambula)+strstr(preambula,ch[0]),strlen(preambula)+strstr(preambula,ch[1]),strlen(preambula)+strstr(preambula,ch[2]),strlen(preambula)+strstr(preambula,ch[3])};
    //unsigned int stp[] = {strlen(preambula)+strstr(ch[0],preambula),strlen(preambula)+strstr(ch[1],preambula),strlen(preambula)+strstr(ch[2],preambula),strlen(preambula)+strstr(ch[3],preambula)};
    unsigned int num_samp[4],ns;
    for (i=0;i<4;i++)
    {
        ch[i] += (size_t)stp[i];
        //printf("chln = %s\n", ch[i]);
        num_samp[i]=0;
        for(j=0;j<9;j++)
        {
            num_samp[i] = num_samp[i]*10 + *(ch[i]++) - '0';
        }
        printf("stp[%d] = %d, num_samp[%d] = %u\n",i,stp[i],i,num_samp[i]);
        fflush(stdout);
    }
    ns = (num_samp[0]<num_samp[1]?num_samp[0]:num_samp[1])<(num_samp[2]<num_samp[3]?num_samp[2]:num_samp[3])?(num_samp[0]<num_samp[1]?num_samp[0]:num_samp[1]):(num_samp[2]<num_samp[3]?num_samp[2]:num_samp[3]);


    for(i=0;i<ns;i++)
    {
        printf("%u:\t%d\t%d\t%d\t%d\n",i,*(ch[0]+i),*(ch[1]+i),*(ch[2]+i),*(ch[3]+i));
    }
}

