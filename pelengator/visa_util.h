#ifndef VISA_UTIL_H
#define VISA_UTIL_H

#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>

#include "visa.h"

#define NS_PER_MICROSECOND 1000L

// Function to open the VISA device
ViStatus open_device(ViSession* defaultRM, ViSession* instr, const char* resourceName);

// Function to write a command to the VISA device
ViUInt32 viwrite_str(ViSession instr, ViBuf buffer);
ViStatus set_attribute(ViSession vi, ViAttr attribute, ViAttrState value);

// Function to read a binary waveform from the VISA device
ViUInt32 viread_buf(ViSession instr, char *buffer,ViUInt32 requested_bytes);
ViUInt32 viread_str(ViSession instr, char *buffer,ViUInt32 requested_bytes);
ViUInt32 viwrite_str(ViSession instr, ViBuf buffer);

// Function to convert a binary buffer to an array of samples
// The `scale` and `offset` parameters are instrument-specific
int get_binary_block_length(const char* header_str);
void convert_buffer_to_samples(const char* buffer, ViUInt32 num_bytes, float* samples, int bytes_per_sample, float scale, float offset);

// Function to close the VISA sessions
void close_device(ViSession defaultRM, ViSession instr);

void set_non_blocking_mode(struct termios *orig_termios);
void restore_mode_and_blocking(struct termios *orig_termios);
void print_buf(char *buffer,unsigned int offset, unsigned int length);
void print_str(char *buffer,unsigned int offset, unsigned int length);
void print_waveforms(char *buffer,unsigned int offset, unsigned int length);
int set_buffers(char *ch[4], char *buffer,unsigned int offset, unsigned int length);
long monotonic_us(void);

#endif // VISA_UTIL_H

