# Makefile to compile and run GoldenModel with LD_LIBRARY_PATH set

# Variables
CC = gcc
CFLAGS = -I./header
LDFLAGS = -L./library -lIp_floating_point_v7_1_bitacc_cmodel -lgmp -lmpfr
TARGET = GoldenModel
SRC = ./bitacc_Cmodel/Golden_Model_first.c
INPUT_DIR = ./test_vector
INPUT_FILE = bf16_numbers.txt
INPUT_FILE_POSITIVE = bf16_numbers_only_positive.txt
OUTPUT_DIR = $(VPU_HOME)/sim/testvector
LIBRARY_PATH = ./library

# Default target to build and run the program
all: $(TARGET)

# Compile the program
$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

# Run the program with the input files and output directory
run: $(TARGET)
	@if [ -z "$(VPU_HOME)" ]; then \
		echo "Error: VPU_HOME 환경 변수가 설정되지 않았습니다."; \
		exit 1; \
	fi
	mkdir -p $(OUTPUT_DIR)
	cp $(INPUT_DIR)/$(INPUT_FILE) $(OUTPUT_DIR)
	cp $(INPUT_DIR)/$(INPUT_FILE_POSITIVE) $(OUTPUT_DIR)
	LD_LIBRARY_PATH=$(LIBRARY_PATH):$$LD_LIBRARY_PATH ./$(TARGET) -input $(INPUT_DIR)/$(INPUT_FILE) -positive_input $(INPUT_DIR)/$(INPUT_FILE_POSITIVE) -output $(OUTPUT_DIR)

# Clean up the compiled binary
clean:
	rm -f $(TARGET)