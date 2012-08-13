#include "common.h"

void readInfo (char *llfn, struct LinkList *ll, struct Problem *prob);

void readLinks (FILE *fp, struct LinkList *ll); 

void readConflictMatrix (FILE *fp, struct LinkList *ll); 

void readProtoConflictMatrix (FILE *fp, struct LinkList *ll); 

void readPhyUniConflictMatrix (FILE *fp, struct LinkList *ll); 

void readPhyBiConflictMatrix (FILE *fp, struct LinkList *ll); 

void readSDPairs (FILE *fp, struct Problem *prob); 
