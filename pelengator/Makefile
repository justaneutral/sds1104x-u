# Makefile for sds_stream.c
# Adjust these paths if your installation directories are different
VISA_INC_PATH = /cygdrive/c/Program\ Files/IVI\ Foundation/VISA/Win64/Include
VISA_LIB_PATH = /cygdrive/c/Program\ Files/IVI\ Foundation/VISA/Win64/Lib_x64/msc

# Compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra -g -I$(VISA_INC_PATH)
LDFLAGS = -L$(VISA_LIB_PATH) -lvisa64

# Executable name
TARGET = pelengator.exe

# Source files
SRC = *.c

$(TARGET): $(SRC)
	@echo "Compiling and linking..."
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)
	@echo "Compilation successful. Executable created: $(TARGET)"

clean:
	@echo "Cleaning up..."
	rm -f $(TARGET)
	@echo "Cleanup complete."

.PHONY: all clean
