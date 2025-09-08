CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=gnu99 -g
LDFLAGS = -lm -lX11

all: x11_fft_viewer.exe

x11_plot.o: x11_plot.c x11_plot.h fft_lib.h
	$(CC) $(CFLAGS) -c x11_plot.c

fft_lib.o: fft_lib.c fft_lib.h
	$(CC) $(CFLAGS) -c fft_lib.c

main.o: main.c x11_plot.h fft_lib.h
	$(CC) $(CFLAGS) -c main.c

x11_fft_viewer.exe: x11_plot.o fft_lib.o main.o
	$(CC) $(CFLAGS) -o x11_fft_viewer.exe x11_plot.o fft_lib.o main.o $(LDFLAGS)

clean:
	rm -f *.o x11_fft_viewer.exe

