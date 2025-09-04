#include <visa.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <ctype.h>

#define BUFFER_SIZE 256 // Define a sufficient buffer size for responses

// Global flag for signal handling
volatile sig_atomic_t stop_streaming = 0;

// Signal handler for Ctrl+C
void sigint_handler(int signum) {
    printf("\n[DIAG] Ctrl+C detected. Setting stop flag.\n");
    stop_streaming = 1;
}

// Function to handle VISA status codes and print diagnostics
void check_visa_status(ViStatus status, const char *message) {
    if (status < VI_SUCCESS) {
        ViChar err_msg[VI_FIND_BUFLEN];
        viStatusDesc(VI_NULL, status, err_msg);
        fprintf(stderr, "[ERROR] %s: 0x%lx - %s\n", message, (unsigned long)status, err_msg);
        exit(EXIT_FAILURE);
    }
    printf("[DIAG] %s: Status OK (0x%lx)\n", message, (unsigned long)status);
}

// Function to query a SCPI command and check for errors
void visa_query(ViSession instr, const char *command, char *response, ViUInt32 response_size) {
    ViUInt32 retCount;
    viWrite(instr, (ViBuf)command, strlen(command), &retCount);
    if (strstr(command, "?")) {
        viRead(instr, (ViBuf)response, response_size, &retCount);
        response[retCount] = '\0'; // Ensure null termination
        char *end = strchr(response, '\n');
        if (end) *end = '\0';
        end = strchr(response, '\r');
        if (end) *end = '\0';
    } else {
        // Clear response for non-query commands
        response[0] = '\0';
    }
    printf("[SCPI] Sent: %s", command);
    if (response[0] != '\0') {
        printf(" -> Received: %s\n", response);
    } else {
        printf("\n");
    }
    // Check for SCPI errors, using a temporary buffer
    ViChar error_check_buffer[BUFFER_SIZE];
    viWrite(instr, (ViBuf)"SYST:ERR?\n", 10, &retCount);
    viRead(instr, (ViBuf)error_check_buffer, sizeof(error_check_buffer), &retCount);
    error_check_buffer[retCount] = '\0';
    char *end = strchr(error_check_buffer, '\n');
    if (end) *end = '\0';
    end = strchr(error_check_buffer, '\r');
    if (end) *end = '\0';

    if (strstr(error_check_buffer, "No error")) {
        printf("[DIAG] SCPI Error Check: No errors reported.\n");
    } else {
        fprintf(stderr, "[ERROR] SCPI Error: %s\n", error_check_buffer);
    }
}

// Function to print a buffer in hexadecimal format
void print_hex_dump(const void* data, size_t size, int channel_num) {
    const unsigned char* byte_data = (const unsigned char*)data;
    size_t i, j;
    
    fprintf(stderr, "[DIAG] Hex dump for Channel C%d (size: %zu bytes):\n", channel_num, size);
    for (i = 0; i < size; i += 16) {
        fprintf(stderr, "[DIAG] %08zx  ", i);
        
        for (j = 0; j < 16; j++) {
            if (i + j < size) {
                fprintf(stderr, "%02x ", byte_data[i + j]);
            } else {
                fprintf(stderr, "   ");
            }
        }
        
        fprintf(stderr, " ");
        
        for (j = 0; j < 16; j++) {
            if (i + j < size) {
                fprintf(stderr, "%c", isprint(byte_data[i + j]) ? byte_data[i + j] : '.');
            }
        }
        fprintf(stderr, "\n");
    }
}

// Main streaming logic
int main() {
    ViSession defaultRM, instr;
    ViStatus status;
    ViFindList findList;
    ViUInt32 retCount;
    ViChar instrDesc[VI_FIND_BUFLEN];
    char buffer[BUFFER_SIZE]; // Use a sufficiently large buffer
    char scpi_cmd[BUFFER_SIZE];
    
    signal(SIGINT, sigint_handler);
    printf("[DIAG] Signal handler for Ctrl+C installed.\n");

    printf("[DIAG] Initializing VISA resources.\n");
    status = viOpenDefaultRM(&defaultRM);
    check_visa_status(status, "viOpenDefaultRM");

    printf("[DIAG] Searching for USB instruments.\n");
    status = viFindRsrc(defaultRM, "USB?*::INSTR", &findList, &retCount, instrDesc);
    if (status < VI_SUCCESS || retCount == 0) {
        fprintf(stderr, "[ERROR] No USB instruments found. Is the oscilloscope connected and powered on?\n");
        viClose(defaultRM);
        return EXIT_FAILURE;
    }
    printf("[DIAG] Found 1 instrument. Connecting to: %s\n", instrDesc);

    status = viOpen(defaultRM, instrDesc, VI_NULL, VI_NULL, &instr);
    check_visa_status(status, "viOpen");

    status = viSetAttribute(instr, VI_ATTR_TMO_VALUE, 5000);
    check_visa_status(status, "viSetAttribute (timeout)");

    // Fix applied here: Pass sizeof(buffer)
    visa_query(instr, "*IDN?\n", buffer, sizeof(buffer));

    printf("[DIAG] Configuring oscilloscope settings.\n");
    visa_query(instr, "TDIV 10ms\n", buffer, sizeof(buffer));
    for (int i = 0; i < 4; ++i) {
        snprintf(scpi_cmd, sizeof(scpi_cmd), "C%d:VDIV 2V\n", i + 1);
        visa_query(instr, scpi_cmd, buffer, sizeof(buffer));
    }
    
    visa_query(instr, "TRMD SINGLE\n", buffer, sizeof(buffer));
    visa_query(instr, "TRSE EDGE\n", buffer, sizeof(buffer));
    visa_query(instr, "TRSO C1\n", buffer, sizeof(buffer));
    visa_query(instr, "TRSL POS\n", buffer, sizeof(buffer));
    visa_query(instr, "TRLV 1V\n", buffer, sizeof(buffer));

    printf("[DIAG] Configuring instrument for binary data transfer.\n");
    visa_query(instr, "WAVEFORM:FORMAT NORMal\n", buffer, sizeof(buffer));
    visa_query(instr, "WAVEFORM:POINTS:MODE RAW\n", buffer, sizeof(buffer));
    visa_query(instr, "CHDR ON\n", buffer, sizeof(buffer));
    usleep(100000);
    
    ViUInt32 waveform_points;
    visa_query(instr, "WAVEFORM:POINTS?\n", buffer, sizeof(buffer));
    waveform_points = atoi(buffer);
    printf("[DIAG] Waveform points per channel: %lu\n", (unsigned long)waveform_points);
    
    ViByte *waveform_raw_data = (ViByte*)malloc(waveform_points + 20);
    if (!waveform_raw_data) {
        fprintf(stderr, "[ERROR] Memory allocation failed!\n");
        return EXIT_FAILURE;
    }
    
    printf("\n[DIAG] Starting continuous streaming. Press Ctrl+C to stop.\n");
    printf("time,");
    for (int i = 0; i < 4; ++i) {
        for (int j = 0; j < 20; ++j) {
            printf("ch%d_s%d,", i + 1, j);
        }
    }
    printf("\n");
    
    double t_start = 0.0;
    
    while (!stop_streaming) {
        printf("[DIAG] Forcing a new acquisition.\n");
        visa_query(instr, "SINGLE\n", buffer, sizeof(buffer));
        usleep(100000);
        
        printf("%.6f,", t_start);
        for (int i = 0; i < 4; ++i) {
            snprintf(scpi_cmd, sizeof(scpi_cmd), "WAVEFORM:SOURCE C%d\n", i + 1);
            visa_query(instr, scpi_cmd, buffer, sizeof(buffer));

            viWrite(instr, (ViBuf)"WAVEFORM:DATA?\n", 15, &retCount);
            
            status = viRead(instr, waveform_raw_data, waveform_points + 20, &retCount);
            if (status < VI_SUCCESS) {
                ViChar error_description[VI_FIND_BUFLEN];
                viStatusDesc(instr, status, error_description);
                fprintf(stderr, "[ERROR] Failed to read waveform for channel C%d. VISA Status: 0x%lx - %s\n", i + 1, (unsigned long)status, error_description);
                for (int j = 0; j < 20; ++j) printf("NAN,");
                continue;
            }
            
            print_hex_dump(waveform_raw_data, retCount, i + 1);

            const char* data_ptr = (const char*)waveform_raw_data;
            if (retCount >= 6 && strncmp(data_ptr, "DAT2,", 5) == 0) {
                data_ptr += 5;
                if (data_ptr < (const char*)waveform_raw_data + retCount && *data_ptr == '#') {
                    if (data_ptr + 1 < (const char*)waveform_raw_data + retCount) {
                        int len_digits = *(data_ptr + 1) - '0';
                        if (len_digits > 0 && len_digits < 10) {
                            if (data_ptr + 2 + len_digits < (const char*)waveform_raw_data + retCount) {
                                char data_len_str[10]; // Use a fixed-size buffer for safety
                                strncpy(data_len_str, data_ptr + 2, len_digits);
                                data_len_str[len_digits] = '\0';
                                int header_size = 5 + 1 + len_digits;
                                
                                if (retCount > header_size) {
                                    for (int j = 0; j < 20 && (header_size + j) < retCount; ++j) {
                                        signed char raw_sample = (signed char)waveform_raw_data[header_size + j];
                                        printf("%d,", raw_sample);
                                    }
                                } else {
                                    fprintf(stderr, "[ERROR] No data found after header for channel C%d.\n", i + 1);
                                    for (int j = 0; j < 20; ++j) printf("NAN,");
                                }
                            } else {
                                fprintf(stderr, "[ERROR] Malformed length field in binary header for channel C%d.\n", i + 1);
                                for (int j = 0; j < 20; ++j) printf("NAN,");
                            }
                        } else {
                            fprintf(stderr, "[ERROR] Invalid binary header length digit for channel C%d.\n", i + 1);
                            for (int j = 0; j < 20; ++j) printf("NAN,");
                        }
                    } else {
                        fprintf(stderr, "[ERROR] Incomplete binary header for channel C%d.\n", i + 1);
                        for (int j = 0; j < 20; ++j) printf("NAN,");
                    }
                } else {
                    fprintf(stderr, "[ERROR] Missing binary header '#' for channel C%d.\n", i + 1);
                    for (int j = 0; j < 20; ++j) printf("NAN,");
                }
            } else {
                fprintf(stderr, "[ERROR] Unexpected waveform data format (missing 'DAT2,') from channel C%d.\n", i + 1);
                for (int j = 0; j < 20; ++j) printf("NAN,");
            }
        }
        printf("\n");
        t_start += 0.05;
        usleep(50000);
    }

    printf("\n[DIAG] Streaming stopped. Closing resources.\n");

    free(waveform_raw_data);
    viClose(instr);
    viClose(findList);
    viClose(defaultRM);
    
    printf("[DIAG] Resources closed. Exiting.\n");
    
    return EXIT_SUCCESS;
}
