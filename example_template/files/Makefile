##
# Game of Life Makefile
#
# @file
# @version 0.1

SRC := $(wildcard *.c)
SRC += $(wildcard libs/*.c)
OBJ := $(patsubst %.c,%.o,$(SRC))

CC := mpicc

ifdef DEBUG
FLAGS := -g
else
FLAGS := -O3
endif

.PHONY: clean

main: $(OBJ)
	$(CC) $(FLAGS) $^ -o $@


$(OBJ) : %.o : %.c
	$(CC) $(FLAGS) -c $< -o $@

clean:
	rm -Rf $(OBJ)
	rm -Rf main

# end
