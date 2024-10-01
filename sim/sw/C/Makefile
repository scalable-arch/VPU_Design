# Makefile to compile and run GoldenModel in any directory with LD_LIBRARY_PATH set

# Variables
CC = gcc
CFLAGS = -I./header
LDFLAGS = -L./library -lIp_floating_point_v7_1_bitacc_cmodel -lgmp -lmpfr
TARGET = GoldenModel
SRC = ./bitacc_Cmodel/Golden_Model_first.c
INPUT_DIR = ./inputfile
INPUT_FILE = bf16_numbers.txt
LIBRARY_PATH = ./library

# Default target to build and run the program
all: setenv $(TARGET)

# Set the LD_LIBRARY_PATH
setenv:
	export LD_LIBRARY_PATH=$(LIBRARY_PATH):$$LD_LIBRARY_PATH

# Compile the program
$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

# Run the program with the input file
run: $(TARGET)
	LD_LIBRARY_PATH=$(LIBRARY_PATH):$$LD_LIBRARY_PATH ./$(TARGET) -input $(INPUT_DIR)/$(INPUT_FILE)

# Clean up the compiled binary
clean:
	rm -f $(TARGET)
