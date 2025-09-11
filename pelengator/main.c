#include <stdio.h>
#include "run_scope.h"

int dsp_callback(signed char *ch[], int len);

int main(int argc, char *argv[])
{
	int rv = run_scope_n(4);
	return rv;
}
