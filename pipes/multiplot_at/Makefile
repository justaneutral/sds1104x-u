CC = gcc
CFLAGS = -Wall -Wextra -pedantic -std=gnu99 -g
LDFLAGS = -lm -lX11

all: main.exe

x11_multiplot.o: x11_multiplot.c
	$(CC) $(CFLAGS) -c x11_multiplot.c

main.exe: main.c x11_multiplot.o
	$(CC) $(CFLAGS) main.c x11_multiplot.o $(LDFLAGS) -o main.exe

clean:
	rm -f *.o *.exe

