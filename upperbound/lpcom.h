#include "common.h"

double *alloc1D (int num, char *err); 

void allocMemory (struct LinProg *);

void printLinProg (struct LinProg lp, int lpPart, int ni_base);

void printMATLAB (struct LinProg lp, int lpPart, int ni_base);
void printColumnMatrix (int rows, double *m, FILE *fp);
void printRowMatrix (int coulmns, double *m, FILE *fp) ;

void printMATLABSparse (struct LinProg lp, int lpPart, int ni_base);
void printSparseColumnMatrix (int cid, int rows, double *m, FILE *fp);
void printSparseRowMatrix (int rid, int coulmns, double *m, FILE *fp) ;

void printLP(struct LinProg lp, int lpPart, int ni_base);

void printCPLEX(struct LinProg lp, int lpPart, int ni_base);

