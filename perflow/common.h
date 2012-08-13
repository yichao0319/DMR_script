#ifndef _COMMON_H
#define _COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <search.h>
#include <math.h>
#include <memory.h>
#include <assert.h>
#include <time.h>

#define IFMODEL_PROTO 0
#define IFMODEL_PHY   1

#define MAC_UNI 0
#define MAC_BI  1

#define OPFORM_MATLAB 1
#define OPFORM_LPSOLVE 2 
#define OPFORM_MATLAB_SPARSE 3 
#define OPFORM_CPLEX_LP 4 

// print what?
#define OBJ 1
#define LB 2
#define UB 3 
#define INEQ 4 
#define EQ 5 
#define INT 6 
#define SIZE 7
#define CONST_VAR 8 // Lili added

#define MAX_VALFORM_LEN 100
#define EPSILON 0.000001

#define MAX_FILENAME 100

// objective function type
#define MAX_THROUGHPUT 0
#define MAX_ALPHA      1
#define MAX_FAIR_SHARE 2

#define CLIQUE_OPT_SCHEDULE 1
#define CLIQUE_802_11 2

struct Link {
	int from;
	int to;
	int channel;
	double capacity;
	double loss; // Lili added 
};

struct LinkList {
	int ifmodel; // interference model (0: protocol. 1 phy)
	int mac;     // interference model (0: uni. 1: bi) 
	int nn;	     // number of nodes
	int nl;	     // number of links

	struct Link *l;			// links

	int **conflict;			// conflict graph (ifmoddel 0, mac 0 or 1)
	double **phy_conflict;		// conflcit graph (ifmodel 1, mac 0)
	double ***phy_bi_conflict;	// conflict graph (ifmodel 1, mac 1)
};

struct IndepSet {
	int n; 
	int *v;
};

struct SetIndepSets {
	int n; 
	struct IndepSet *is;
};

struct Clique {
	int n; 
	int *v;
	double *w;       // Lili added
	double max_util; // Lili added
};

struct SetCliques {
	int n; 
	struct Clique *cl;
};

struct FP {
	// these are needed for matlab
	FILE *obj;
	FILE *lb; 
	FILE *ub; 
	FILE *A; 
	FILE *b; 
	FILE *Aeq; 
	FILE *beq; 

	// this is need for sparse
	FILE *sz; 

	// these for lp_solve
	FILE *lp;
};

struct LinProg {

	int nv; // number of variables
	int nint; // last nint variables are integers 
	int neq; // number of equality constraints
	int nineq; // number of inequality constraints
	
	int ec; // which row are we generating now?
	
	double *F;
	double *lb;
	double *ub;

	double *A; // one row at a time
	double *b;

	double *Aeq; // one row at a time
	double *beq;

        double *var_values; // Lili added: values for some variables
        int const_var; // Lili added: number of variables with constant values
	double *var_LBs; // Lili added: lower bounds for some variables
  
	int opform; // output format
	
	struct FP fp; // file pointers for output files
};

struct Connection {
	int s; 
	int d;
	double demand;    // Lili added
}; 

struct Problem {
	int ncon;  // number of flows to maximize
	struct Connection *con; 
	int multipath; // 1 yes. 0 no.
        int obj_type; // Lili added: MAX_THROUGHPUT, MAX_ALPHA
        double lambda; // Lili added: weight for fairness term
        double total_demand; // Lili added
        double epsilon; // Lili added
  int clique_const_type; // Lili added
};

struct lpsolveResult {
  int nv;
  float *x;
};

void Permute (int *nodelist, int size);
int Compare( const void *arg1, const void *arg2 );
void CloseFiles (struct FP *fp, int opform);
FILE *OpenFileToWrite (char *fnam); 
void OpenFiles (struct FP *fp, int opform, char *fnam);

#endif

