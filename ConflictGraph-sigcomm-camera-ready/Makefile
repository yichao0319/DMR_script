# CC=g++-3.3
CC=g++
CFLAGS=-Wall
OBJ=ConflictGraph.o stdafx.o
EXE=ConflictGraph

all: $(EXE)

ConflictGraph.o: ConflictGraph.cpp ConflictGraph.h
	$(CC) $(CFLAGS) -c -o ConflictGraph.o ConflictGraph.cpp

stdafx.o: stdafx.cpp stdafx.h
	$(CC) $(CFLAGS) -c -o stdafx.o stdafx.cpp

ConflictGraph: $(OBJ)
	$(CC) $(CFLAGS) -o $(EXE) $(OBJ)

clean:
	rm -f $(EXE) $(OBJ)
