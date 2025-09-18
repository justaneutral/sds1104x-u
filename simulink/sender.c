#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>  // For sleep() function (POSIX standard)

int main() 
{
    FILE *file;
    char a[1024];
    int n = 1;
    while (1) {
        // Open the file in write mode
        file = fopen("temp_output.txt", "wb");

        if (file == NULL) {
            printf("Error opening file for writing\n");
            return -1;
        }

        // Write some data to the file
	for(int i=0;i<1024;i++) a[i]=i+n;
	n++;
        fwrite(a,1,1024,file);

        // Close the file after writing
        fclose(file);

        printf("Data written to temp_output.txt : ");
        for(int i=0;i<1024;i++) printf(" %hhx", a[i]);
	printf("\n");

        // Sleep for 3 seconds before writing again
        sleep(3);
    }

    return 0;
}

