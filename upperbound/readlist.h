#include "common.h"

void readInfo (char *llfn, struct LinkList *ll, struct Problem *prob);

void readLoss(char *lossFile, struct LinkList *ll);
     
void readLinks (FILE *fp, struct LinkList *ll); 

void readConflictMatrix (FILE *fp, struct LinkList *ll); 

void readProtoConflictMatrix (FILE *fp, struct LinkList *ll); 

void readPhyUniConflictMatrix (FILE *fp, struct LinkList *ll); 

void readPhyBiConflictMatrix (FILE *fp, struct LinkList *ll); 

void readSDPairs (FILE *fp, struct Problem *prob); 

// Lili starts
void readRoute(char *routeFile, struct Problem prob, struct LinkList ll, struct LinProg *lp);

int extractNodeId(char *str);

void readFlowLowerBound (char *flbfn, struct Problem prob, struct LinkList ll, struct LinProg *lp);

// Lili ends
