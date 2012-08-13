CC=g++
CFLAGS=-Wall
EXE = perflow
OBJ = common.o lpcom.o readlist.o perflow.o lpsolve.o
all: perflow

common.o: common.c common.h
	$(CC) $(CFLAGS) -c -o common.o common.c

perflow.o: perflow.c perflow.h
	$(CC) $(CFLAGS) -c -o perflow.o perflow.c

lpcom.o: lpcom.c lpcom.h
	$(CC) $(CFLAGS) -c -o lpcom.o lpcom.c

readlist.o: readlist.c readlist.h
	$(CC) $(CFLAGS) -c -o readlist.o readlist.c

lpsolve.o: lpsolve.c lpsolve.h
	$(CC) $(CFLAGS) -c -o lpsolve.o lpsolve.c

$(EXE): $(OBJ)
	$(CC) $(CFLAGS) -o $(EXE) $(OBJ)

clean:
	rm -f $(EXE) $(OBJ)
