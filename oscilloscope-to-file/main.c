#include <stdio.h>
#include "run_scope.h"

int dsp_callback(signed char *ch[], int len);

int main(int argc, char *argv[])
{
	int num_acqs = 4;
	if(argc>1)
	{
		num_acqs = atoi(argv[1]);
		if(num_acqs<1) num_acqs=1;
		if(num_acqs>1000) num_acqs=1000;
	}
	int rv = run_scope_n(num_acqs);
	return rv;
}
