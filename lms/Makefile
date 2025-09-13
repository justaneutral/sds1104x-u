# Compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=gnu99 -O2 -g
LDFLAGS = -lm

# Output executable
TARGET = lms_filter_demo

# Object files
OBJS = main.o lms_filter.o

# Build the executable
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS) $(LDFLAGS)

# Compile the main program
main.o: main.c lms_filter.h
	$(CC) $(CFLAGS) -c main.c

# Compile the filter logic
lms_filter.o: lms_filter.c lms_filter.h
	$(CC) $(CFLAGS) -c lms_filter.c

# Clean up compiled files
clean:
	rm -f $(OBJS) $(TARGET)

