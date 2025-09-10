#include <time.h>
#include <stdint.h>

/**
 * @brief Returns monotonic time in microseconds.
 * @return The number of microseconds since an unspecified starting point.
 * @note Requires linking with `-lrt` on some systems.
 */
long monotonic_us(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long)(ts.tv_sec * 1000000 + ts.tv_nsec / 1000);
}

