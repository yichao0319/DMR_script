#include "common.h"
#include "lpcom.h"

void genUpperBoundLinProg (struct LinkList ll, struct SetCliques scl, struct Problem prob, struct LinProg *lp); 

void countVariables (struct LinkList ll, struct SetCliques scl, struct Problem prob, struct LinProg *lp); 

void addObj (struct LinkList, struct Problem, struct LinProg *); 

void addObj_proportional_fair (struct LinkList, struct Problem, struct LinProg *);

void addLbc (struct LinkList, struct Problem, struct LinProg *); 
	
void addUbc (struct LinkList, struct Problem, struct LinProg *); 
	
void addEq (struct LinkList, struct Problem, struct LinProg *);  

void addInEq (struct LinkList, struct SetCliques scl, struct Problem, struct LinProg *);  

int isIn(int l, struct Clique cl);


