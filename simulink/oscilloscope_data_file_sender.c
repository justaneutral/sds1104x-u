#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>  // For sleep() function (POSIX standard
#include <time.h>


#define NUM_CHANNELS (4)
#define CHANNEL_LENGTH (9)
#define PATH_FILE_NAME ("temp_output.txt")
#define __VERBOSE__


int oscilloscope_data_file_write(char *p0, char *p1, char *p2, char *p3, double sleep_time_ns) 
{
    FILE *file;
    struct timespec req, rem;

    req.tv_sec = sleep_time_ns / 1000000000.0; // seconds
    req.tv_nsec = sleep_time_ns - 1000000000.0*req.tv_sec;  // 1 millisecond = 1,000,000 ns

    if(!p0) return -1;
    if(!p1) return -2;
    if(!p2) return -3;
    if(!p3) return -4;

    // check if the file exists to prevent rewriting the file which was not read in simulink.
    file = fopen(PATH_FILE_NAME, "r");
    while(file) //file exists
    {
	fclose(file);  // Always close it!
        // Sleep sleep_time_s seconds before writing again
    	if (nanosleep(&req, &rem) == -1)
    	{
            sleep(req.tv_sec>1?req.tv_sec:1);
            perror("nanosleep");
    	}
    	file = fopen(PATH_FILE_NAME, "r");
#ifdef __VERBOSE__
    	printf(".");
	fflush(stdout);
#endif //__VERBOSE__
    }

    // Open the file in write mode
    file = fopen(PATH_FILE_NAME, "wb");

    if (file == NULL)
    {
        printf("Error opening file %s for writing\n", PATH_FILE_NAME);
        return -5;
    }

    fwrite(p0,1,CHANNEL_LENGTH,file);
    fwrite(p1,1,CHANNEL_LENGTH,file);
    fwrite(p2,1,CHANNEL_LENGTH,file);
    fwrite(p3,1,CHANNEL_LENGTH,file);

    // Close the file after writing
    fclose(file);

#ifdef __VERBOSE__
    printf("Data written to %s : ", PATH_FILE_NAME);
    printf("\nch0:\n");
    for(int i=0;i<CHANNEL_LENGTH;i++) printf(" %hhx", p0[i]);
    printf("\nch1:\n");
    for(int i=0;i<CHANNEL_LENGTH;i++) printf(" %hhx", p1[i]);
    printf("\nch2:\n");
    for(int i=0;i<CHANNEL_LENGTH;i++) printf(" %hhx", p2[i]);
    printf("\nch3:\n");
    for(int i=0;i<CHANNEL_LENGTH;i++) printf(" %hhx", p3[i]);
    printf("\n");
    fflush(stdout);
#endif //__VERBOSE__

    return 0;
}


int main()
{
    const char file_name[] = "temp_output.txt";
    int delay_nanoseconds = 1000000000.0; //100 milliseconds
    char a[NUM_CHANNELS*CHANNEL_LENGTH];
    int n = 1;
    while (1)
    {
        // Write some data to the file
        for(int i=0; i<NUM_CHANNELS*CHANNEL_LENGTH; i++) a[i]=i+n;
        n++;
	oscilloscope_data_file_write(a, &a[CHANNEL_LENGTH], &a[2*CHANNEL_LENGTH], &a[3*CHANNEL_LENGTH], delay_nanoseconds);
    }
    return 0;
}

