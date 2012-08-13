#include "upperbound.h"

int main (int argc, char **argv)
{
	struct LinkList ll; 
	struct SetCliques scl;
	struct LinProg lp; 
	struct Problem prob; 
	int effort; 

	if (argc < 8 || argc > 13) {
		printf ("Usage: %s <link file> <effort> <output format> <output filename> <random seed> <obj type> <lambda> (<clique input file> <lossFile> <epsilon> <routeFile> <flow LB file>)\n", argv[0]);
		exit(-1);
	}

	// read in problem: i.e. single/multipath and list of sources and destinations
	readInfo(argv[1], &ll, &prob); 
	
	// how much effort; 
	effort = atoi(argv[2]); 

	// what output format
	lp.opform = atoi(argv[3]);

        // Lili added: by default, no constant variables 
        lp.const_var = 0;

        // Lili added: by default, no variable lower bounds
        lp.var_LBs = 0;
        
	//Modeified by Yi Li to be consistent with lowerbound
	//if ((prob.multipath == 0) && (lp.opform != OPFORM_LPSOLVE)) {
	if ((prob.multipath == 0) && ((lp.opform == OPFORM_MATLAB_SPARSE)||(lp.opform == OPFORM_MATLAB))) {
		printf ("matlab can not solve single path problem\n");
		exit(-1); 
	}

	if (ll.ifmodel != IFMODEL_PROTO) {
		printf ("upper bound for physical model not implemented yet\n");
		exit(1);
	}

	srand(atoi(argv[5]));

        if (strcmp(argv[8], "NULL") == 0) {
          // find cliques, making a certain number of attempts
          findCliques (ll, &scl, effort);
          prob.clique_const_type = CLIQUE_OPT_SCHEDULE;
        }
        else {
          // read cliques from input file argv[7]
          readCliques(argv[8], ll, &scl);
          prob.clique_const_type = CLIQUE_802_11;
        }
        
	//printCliques (scl);
	
	// open the files needed for output
	OpenFiles (&(lp.fp), lp.opform, argv[4]); 

                        
	// generate the linear program
        prob.obj_type = atoi(argv[6]);
        prob.lambda = atof(argv[7]);
        
        if (argc >= 10)
          readLoss(argv[9], &ll);

        if (argc >= 11)
          prob.epsilon = atof(argv[10]);

        if (argc >= 12)
          readRoute(argv[11], prob, ll, &lp);

        if (argc == 13)
          readFlowLowerBound(argv[12], prob, ll, &lp);
        
	genUpperBoundLinProg (ll, scl, prob, &lp);

	// close output files 
	CloseFiles (&(lp.fp), lp.opform); 
	return 0;
}
