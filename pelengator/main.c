#include <stdio.h>

int oscilloscope_loop(int (*callback)(char* ch[4], int len));
int dsp_callback(signed char *ch[], int len);

int main(int argc, char *argv[])
{
	int rv = oscilloscope_loop(dsp_callback);
	return rv;
}
