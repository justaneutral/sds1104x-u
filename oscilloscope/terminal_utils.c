#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

// Set terminal to non-blocking raw mode
void set_non_blocking_mode(struct termios *orig_termios) {
    struct termios raw;
    tcgetattr(STDIN_FILENO, orig_termios);
    raw = *orig_termios;
    raw.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &raw);

    // Set the file descriptor for standard input to non-blocking
    fcntl(STDIN_FILENO, F_SETFL, fcntl(STDIN_FILENO, F_GETFL, 0) | O_NONBLOCK);
}

// Restore original terminal mode
void restore_mode_and_blocking(struct termios *orig_termios) {
    // Restore the file descriptor to blocking mode
    fcntl(STDIN_FILENO, F_SETFL, fcntl(STDIN_FILENO, F_GETFL, 0) & ~O_NONBLOCK);
    // Restore original terminal settings
    tcsetattr(STDIN_FILENO, TCSANOW, orig_termios);
}

