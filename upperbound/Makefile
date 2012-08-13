CC=g++
CFLAGS=-Wall -g
EXE = upperbound
OBJ = common.o clique.o lpcom.o readlist.o lpupper.o upperbound.o

all: $(EXE)

common.o: common.c clique.h  common.h  lpcom.h  lpupper.h  readlist.h  upperbound.h
	$(CC) $(CFLAGS) -c -o common.o common.c
clique.o: clique.c clique.h  common.h  lpcom.h  lpupper.h  readlist.h  upperbound.h
	$(CC) $(CFLAGS) -c -o clique.o clique.c
lpcom.o: lpcom.c clique.h  common.h  lpcom.h  lpupper.h  readlist.h  upperbound.h
	$(CC) $(CFLAGS) -c -o lpcom.o lpcom.c
readlist.o: readlist.c clique.h  common.h  lpcom.h  lpupper.h  readlist.h  upperbound.h
	$(CC) $(CFLAGS) -c -o readlist.o readlist.c
lpupper.o: lpupper.c clique.h  common.h  lpcom.h  lpupper.h  readlist.h  upperbound.h
	$(CC) $(CFLAGS) -c -o lpupper.o lpupper.c
upperbound.o: upperbound.c clique.h  common.h  lpcom.h  lpupper.h  readlist.h  upperbound.h
	$(CC) $(CFLAGS) -c -o upperbound.o upperbound.c

$(EXE): $(OBJ)
	$(CC) $(CFLAGS) -o $(EXE) $(OBJ)

clean:
	rm -f $(EXE) $(OBJ)

