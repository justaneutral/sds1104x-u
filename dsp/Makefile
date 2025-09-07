# Makefile for Cygwin to compile all C files in the current directory

# Define the C compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=gnu99 -g
LDFLAGS = -lm # Link against the math library

# The name of the final executable
EXECUTABLE = dsp_test.exe

# Use the 'wildcard' function to find all .c files in the current directory
SOURCES = $(wildcard *.c)

# Automatically generate a list of object files (.o) from the list of source files
OBJECTS = $(SOURCES:.c=.o)

# The default target. Builds the executable.
all: $(EXECUTABLE)

# Rule to link all object files into the final executable
$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $(EXECUTABLE)

# Pattern rule to compile each .c file into a .o file
# This rule is used automatically by 'make' for each .c file
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# A phony target for cleaning up compiled files
.PHONY: clean

# Rule to clean up all intermediate and final build files
clean:
	rm -f $(OBJECTS) $(EXECUTABLE)

