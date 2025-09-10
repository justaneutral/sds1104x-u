#include <stdio.h>
#include <stdlib.h>
#include <string.h>
//#include "parse_header.h"

/**
 * @brief Parses a VISA header string and extracts the binary block length.
 *
 * This function looks for the "#" and "WAVEDESC" markers to find the numeric
 * length specifier in a standard IEEE 488.2 header format (e.g., #9XXXXXXXXX).
 *
 * @param header_str The full header string received from the instrument.
 * @return The binary block length as an integer, or -1 if the format is invalid.
 */
int get_binary_block_length(const char* header_str) {
    char* start_ptr = NULL;
    char* end_ptr = NULL;
    char length_str[10]; // 9 digits + null terminator
    int num_digits;

    // Find the start of the IEEE 488.2 binary block header
    start_ptr = strchr(header_str, '#');
    if (start_ptr == NULL) {
        return -1; // Format error: '#' not found
    }

    // Move past the '#' character
    start_ptr++;

    // The next character indicates the number of digits in the length
    if (*start_ptr < '1' || *start_ptr > '9') {
        return -1; // Format error: Invalid number of digits
    }

    num_digits = *start_ptr - '0';

    // Move past the number-of-digits character
    start_ptr++;

    // Find the end of the length string (before "WAVEDESC")
    end_ptr = strstr(start_ptr, "WAVEDESC");
    if (end_ptr == NULL || (end_ptr - start_ptr) != num_digits) {
        return -1; // Format error: "WAVEDESC" not found or length mismatch
    }

    // Copy the length string into a temporary buffer
    strncpy(length_str, start_ptr, num_digits);
    length_str[num_digits] = '\0'; // Null-terminate the string

    // Convert the string to an integer and return it
    return atoi(length_str);
}

