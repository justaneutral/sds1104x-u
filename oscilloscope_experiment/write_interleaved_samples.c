#include <stdio.h>
#include <fcntl.h>      // open
#include <unistd.h>     // write, close, fsync
#include <stdlib.h>     // exit

#define INPUT_N 1024       // number of samples per channel

void write_interleaved_samples(const char *filename,
                               const char *ch1, const char *ch2,
                               const char *ch3, const char *ch4) {
    int valmin[4] = {127,127,127,127};
    int valmax[4] = {-127,-127,-127,-127};
    int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) {
        perror("Error opening file");
        exit(EXIT_FAILURE);
    }

    unsigned char buffer[4]; // temporary buffer to hold one sample from each channel

    for (int i = 0; i < INPUT_N; i++) {
        buffer[0] = ch1[i];
        buffer[1] = ch2[i];
        buffer[2] = ch3[i];
        buffer[3] = ch4[i];

	for(int j=0; j<4;j++)
	{
		valmin[j] = valmin[j]<buffer[j]?valmin[j]:buffer[j];
		valmax[j] = valmax[j]>buffer[j]?valmax[j]:buffer[j];
	}

        ssize_t written = write(fd, buffer, sizeof(buffer));
        if (written < 0) {
            perror("Error writing to file");
            close(fd);
            exit(EXIT_FAILURE);
        } else if (written != sizeof(buffer)) {
            fprintf(stderr, "Partial write: %zd bytes\n", written);
            close(fd);
            exit(EXIT_FAILURE);
        }
    }

    printf("Limits: %d:%d,  %d:%d,  %d:%d,  %d:%d\n",valmin[0],valmax[0],valmin[1],valmax[1],valmin[2],valmax[2],valmin[3],valmax[3]);
    for(int j=0; j<4;j++)
    {
          valmin[j] = valmin[j]<buffer[j]?valmin[j]:buffer[j];
          valmax[j] = valmax[j]>buffer[j]?valmax[j]:buffer[j];
    }


    // Flush to disk
    if (fsync(fd) < 0) {
        perror("Error syncing file");
        close(fd);
        exit(EXIT_FAILURE);
    }

    if (close(fd) < 0) {
        perror("Error closing file");
        exit(EXIT_FAILURE);
    }
}

