#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <unistd.h>

int dsp_callback(signed char *ch[], int len)
{
	printf("\ndsp callback: len = %d, ch[0] = %llu,   ch[1] = %llu,   ch[2] = %llu,   ch[3] = %llu\n", len, (size_t)ch[0], (size_t)ch[1], (size_t)ch[2], (size_t)ch[3]);
	fflush(stdout);
	return len;
}
