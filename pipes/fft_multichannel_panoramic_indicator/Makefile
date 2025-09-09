CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=gnu99 -O2 -g
LDFLAGS = -lm -lX11

TARGET = x11_fft_viewer_multi.exe

OBJS = main.o fft_lib.o x11_plot.o

all: $(TARGET)

main.o: main.c x11_plot.h fft_lib.h
	$(CC) $(CFLAGS) -c main.c

fft_lib.o: fft_lib.c fft_lib.h
	$(CC) $(CFLAGS) -c fft_lib.c

x11_plot.o: x11_plot.c x11_plot.h fft_lib.h
	$(CC) $(CFLAGS) -c x11_plot.c

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS) $(LDFLAGS)

clean:
	rm -f $(OBJS) $(TARGET)

