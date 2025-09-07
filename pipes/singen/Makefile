# Makefile
CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=gnu99 -g
LDFLAGS = -lm

EXECUTABLE1 = sine_generator.exe
EXECUTABLE2 = plotter.exe
SOURCES1 = sine_generator.c
SOURCES2 = plotter.c

all: $(EXECUTABLE1) $(EXECUTABLE2)

$(EXECUTABLE1): $(SOURCES1)
	$(CC) $(CFLAGS) $(SOURCES1) $(LDFLAGS) -o $(EXECUTABLE1)

$(EXECUTABLE2): $(SOURCES2)
	$(CC) $(CFLAGS) $(SOURCES2) $(LDFLAGS) -o $(EXECUTABLE2) -lX11

clean:
	rm -f $(EXECUTABLE1) $(EXECUTABLE2)

