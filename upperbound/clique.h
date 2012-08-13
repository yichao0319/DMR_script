#include "common.h"

void findCliques (struct LinkList llist, struct SetCliques *scl, int attempts);

struct Clique GetClique (struct LinkList llist, int *nodelist, int *scratch);

void InsertClique (struct SetCliques *scl, struct Clique cl);

int AreEqualCliques (struct Clique a, struct Clique b);

void printCliques (struct SetCliques scl);

int canAdd (struct LinkList ll, int *v, int vlen, int nextnode);

int canAddProto (struct LinkList ll, int *v, int vlen, int nextnode);

void readCliques(char *clique_inputFile, struct LinkList ll, struct SetCliques  *scl);
