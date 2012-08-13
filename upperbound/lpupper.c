#include "lpupper.h"
#include "common.h"

void genUpperBoundLinProg (struct LinkList ll, struct SetCliques scl, struct Problem prob, struct LinProg *lp)
{
	// how many variables do we need?
        countVariables (ll, scl, prob, lp);

	if (lp->opform == OPFORM_MATLAB_SPARSE) {
		// print it
		printLinProg(*lp, SIZE, prob.ncon*ll.nl);
	}

	// allocate memory
	allocMemory (lp); 

	// define objective function 
	printf ("starting obj\n"); fflush(stdout);
        if (prob.obj_type == MAX_PROPORTIONAL_FAIR)
          addObj_proportional_fair(ll, prob, lp);
        else
          addObj (ll, prob, lp);
	printf ("done\n"); fflush(stdout);


	// add equality constraints
	printf ("starting eq\n"); fflush(stdout);
	addEq (ll, prob, lp); 
	printf ("done\n"); fflush(stdout);
	
	// add inequality constraints 
	printf ("starting ineq\n"); fflush(stdout);
	addInEq (ll, scl, prob, lp);
	printf ("done\n"); fflush(stdout);

	// lower bound on variables
	printf ("starting LB\n"); fflush(stdout);
	addLbc (ll, prob, lp); 
	printf ("done\n"); fflush(stdout);
	
	// upper bound on variables
	printf ("starting ub\n"); fflush(stdout);
	addUbc (ll, prob, lp); 
	printf ("done\n"); fflush(stdout);

	// integer constraints for single path problem
	if (prob.multipath == 0) {
          // Lili starts
          if (lp->const_var > 0)
            printLinProg(*lp, CONST_VAR, prob.ncon*ll.nl);
          else
            printLinProg(*lp, INT, prob.ncon*ll.nl);
          // Lili ends
	}
}

void countVariables (struct LinkList ll, struct SetCliques scl, struct Problem prob, struct LinProg *lp)
{
	// number of variables is:
	// - number of flows = number of sd pairs * number of links 
	//   (i.e. along each link, a flow is assigned to a connection)
	// if we are looking at a single-path problem, add also:  
	//  - one variable per flow to serve as an indicator variable.

	// the order of the variables is as follows: 
	//  - first ncon*nl variables are flows. 
	//    flow belonging to sd pair "p" along link q
	//    is given by p*ll.nl+q
	//  - if we are solving a single-path problem,
	//    next ncon*nl variables are indicator variable. 
	//    the indicator variable for sd pair "p" along 
	//    link q is: ncon*nl + p*ll.nl+q
        //  if MAX_ALPHA: one more variable for alpha
        //  if MAX_FAIR_SHARE: one variable z for each flow
        //  if proportional fairness: ncon*num_cut_points
  
	lp->nv = prob.ncon*ll.nl; 

	if (prob.multipath == 0) {
		lp->nint = prob.ncon*ll.nl;
		lp->nv = lp->nv + lp->nint; 
	}
	else {
		lp->nint = 0; 
	}

        printf("1: lp->nv = %d\n", lp->nv);

        if (prob.obj_type == MAX_ALPHA)
          // last variable is alpha
          lp->nv ++;
        else if (prob.obj_type == MAX_FAIR_SHARE)
          // zi for each flow and w
          lp->nv += (prob.ncon+1);
        else if (prob.obj_type == MAX_PROPORTIONAL_FAIR)
          lp->nv += (prob.ncon*num_cut_points);

        printf("2: lp->nv = %d\n", lp->nv);
        
	// number of euqality constraints: 
	// - for each sd pair: 
	//     - sum of flow out of sink is 0
	//     - sum of flow into source is 0
	//     - for all other nodes, incoming flows = outgoing flows

	lp->neq = prob.ncon*ll.nn; 

        // w = sum_i throughput_i
        if (prob.obj_type == MAX_FAIR_SHARE)
          lp->neq ++;
        
	// nubmer of inequality constraints: 
	// - sum of utlizations of links belonging to a clique is less than or equal to 1 
	// if we are looking at single path problem, add also: 
	//  - for each sd pair (q)
	//   	- at each node
	//   		sum of indicator variables for flows for pair q on links that 
	//   		are incoming at this node is less than or euqal to 1
	//  - for each sd pair p
	//  	- for each link q
	//  		flow p*nl+q - indicator variable for flow p*nl+q*link capacity <= 0
	
	lp->nineq = scl.n;

	if (prob.multipath == 0) {
		lp->nineq = lp->nineq + prob.ncon*ll.nn + prob.ncon*ll.nl; 
	}

        if (prob.obj_type == MAX_ALPHA)
          // for each flow, traffic successfully delivered to each dest >= alpha*demand
          // for each flow, traffic successfully delivered to each dest >= epsilon
          lp->nineq += 2*prob.ncon;
        else if (prob.obj_type == MAX_FAIR_SHARE)
          // for each flow, sum(throughput) * D_i/sum(Di)-throughput-zi <=0
          // for each flow, -(sum(throughput) * D_i/sum(Di)-throughput)-zi <=0 
          lp->nineq += 2*prob.ncon;

        lp->nineq += prob.ncon; // Lili added constraints that for each flow i, its throughput <= demand_i                              
}

// Lili starts: add proportional fairness objective
void addObj_proportional_fair (struct LinkList ll, struct Problem prob, struct LinProg *lp)
{
	// The objective function is to maximize the amount of flow 
	// assigned to a given sd pair, out of each s
	
	int i, j, nf; 

	int ni_base;

        if (prob.multipath == 0)
          ni_base = 2*prob.ncon*ll.nl;
        else
          ni_base = prob.ncon*ll.nl;
        
	// first set everything to 0
	for (i = 0; i < lp->nv ; i++) {
		lp->F[i] = 0; 
	}

	// first nl*ncon variables are flows. 
	// for each connection, 
	// 	for all links that come out of node s
	// 		set F[] = -1
	// NOTE: mathematica minimizes, so we need -1.

	for (i = 0 ; i < prob.ncon; i++) {
          for (int k = 0; k < num_cut_points; k++ ) {
            nf = ni_base + i*num_cut_points+k;
            lp->F[nf] = -slope[k];
          }
        }
        
	// print it
	printLinProg(*lp, OBJ, prob.ncon*ll.nl);
}
// Lili ends

void addObj (struct LinkList ll, struct Problem prob, struct LinProg *lp)
{
	// The objective function is to maximize the amount of flow 
	// assigned to a given sd pair, out of each s
	
	int i, j, nf; 

	int ni_base;

        if (prob.multipath == 0)
          ni_base = 2*prob.ncon*ll.nl;
        else
          ni_base = prob.ncon*ll.nl;
        
	// first set everything to 0
	for (i = 0; i < lp->nv ; i++) {
		lp->F[i] = 0; 
	}

	// first nl*ncon variables are flows. 
	// for each connection, 
	// 	for all links that come out of node s
	// 		set F[] = -1
	// NOTE: mathematica minimizes, so we need -1.

	for (i = 0 ; i < prob.ncon; i++) {
		for (j = 0; j < ll.nl ; j++) {		
			// calculate the index of the flow
			nf = i*ll.nl + j;
                        // Lili starts: change obj to maximize successfully delivered flow to d    
			if (ll.l[j].to == prob.con[i].d)  {
                          lp->F[nf] = -1;
                        }
                        // Lili ends  
		}
	}

        if (prob.obj_type == MAX_ALPHA) {
          // min: - throughput - lambda*alpha*total_demand
          lp->F[lp->nv-1] = -prob.total_demand*prob.lambda;
        }
        else if (prob.obj_type == MAX_FAIR_SHARE) {
          // min: - throughput + lambda * sum zi 
          for (i = 0; i < prob.ncon; i++) {
            printf("conn %d: %lf\n", i, prob.lambda);
            lp->F[ni_base+i] = prob.lambda;
          }
        }
        
	// print it
	printLinProg(*lp, OBJ, prob.ncon*ll.nl);
}

void addLbc (struct LinkList ll, struct Problem prob, struct LinProg *lp)
{
	// lower bound on variables

	int i; 	

	// all variables are lower bound by 0
	for (i = 0; i < lp->nv; i++) {
		lp->lb[i] = 0; 
	}

        if (lp->var_LBs) {
        	for (i = 0; i < prob.ncon*ll.nl; i++) {
                	lp->lb[i] = lp->var_LBs[i];
                }
        }

	// print it
	printLinProg(*lp, LB, prob.ncon*ll.nl);
}

void addUbc (struct LinkList ll, struct Problem prob, struct LinProg *lp)
{
	// upper bound on variables
	
	int i, j, nf;
        int ni_base;
        
	// flows along a link are upperbound by link capacities
	for (i = 0; i < prob.ncon; i++) {
		for (j = 0; j < ll.nl; j++) {
			// calculate the index of the flow
			nf = i*ll.nl + j;
                        // Lili starts 
			lp->ub[nf] = ll.l[j].capacity;
                        // Lili ends
		}
	}
        ni_base = prob.ncon*ll.nl;
        
	// if we have single-path problem, indicator variables are upper-bound by 1
	// in each case lp->nv has the correct value!
        if (prob.multipath == 0) {
          for (i = ll.nl*prob.ncon; i < ll.nl*prob.ncon*2; i++) {
            lp->ub[i] = 1;
          }
          ni_base += prob.ncon*ll.nl;
        }

        if (prob.obj_type == MAX_ALPHA) {
          lp->ub[ni_base] = 1; // alpha's upperbound is 1
        }
        else if (prob.obj_type == MAX_FAIR_SHARE) {
          // the new variables for MAX_FAIR_SHARE doesn't have upperbound
          // for each conn i, zi
          // total throughput w
          for (i = ni_base; i < lp->nv; i++) {
            printf("i = %d\n", i);
            lp->ub[i] = -1;
          }
        }
        else if (prob.obj_type == MAX_PROPORTIONAL_FAIR) {
          for (i = ni_base; i <lp->nv; i++) {
            if ((i-ni_base)%num_cut_points != num_cut_points-1) 
              lp->ub[i] = width[(i-ni_base)%num_cut_points];
            else
              lp->ub[i] = -1;
          }
        }
        
	// print it
	printLinProg(*lp, UB, prob.ncon*ll.nl);
}

void addEq (struct LinkList ll, struct Problem prob, struct LinProg *lp)
{
	// eqality constraints
	// - for each sd pair: 
	//     - sum of flow out of sink is 0
	//     - sum of flow into source is 0
	//     - for all other nodes, incoming flows = outgoing flows

	int i, j, k, nf;
	
	lp->ec = 0; 

	// set everything to zero
	memset (lp->Aeq, 0, sizeof(double)*lp->nv); 

	// for each connection
	for (i = 0; i < prob.ncon; i++) { 
		// for each node
		for (j = 0 ; j < ll.nn; j++) { 
			// if this node is a source
			if (j == prob.con[i].s) {
				// for each link
				for (k = 0; k < ll.nl; k++) {
					// where this node is destination
					if (ll.l[k].to == j) {
						// sum of flows for that connection along that link (i.e. nf)
						nf = i*ll.nl + k; 
						lp->Aeq[nf] = 1;
					}
					nf ++;
				}
			} else {
				// if this node is a destination
				if (j == prob.con[i].d) {
					// for each link
					for (k = 0; k < ll.nl; k++) {
					// where this node is a source 
						if (ll.l[k].from == j) {
							// sum of flows for that connection along that link (i.e. nf)
							nf = i*ll.nl + k; 
							lp->Aeq[nf] = 1;
						}
						nf ++;
					}
				} else {
					// if this node is neither a source nor
					// a destination, some of inflows == sum
					// of outflows
					for (k = 0; k < ll.nl; k++) {
						if (ll.l[k].from == j) {
							// add up all outgoing flows (nf) at this node
							nf = i*ll.nl + k; 
							lp->Aeq[nf] = 1;
						} else {
							if (ll.l[k].to == j) {
								// subtract all incoming flows (nf) at this node
								nf = i*ll.nl + k; 
								lp->Aeq[nf] = -1;
							}
						}
					}
				}
			}	
			// is zero ....
			lp->beq[0] = 0;
			// print it.
			printf ("added equality %d\n", lp->ec);
			printLinProg(*lp, EQ, prob.ncon*ll.nl);
			// set everything to zero
			memset (lp->Aeq, 0, sizeof(double)*lp->nv); 
			lp->ec ++;
		}
	}

        if (prob.obj_type == MAX_FAIR_SHARE) {
          // sum(throughput_i) - w = 0
          // for each flow
          for (i = 0; i < prob.ncon; i++) {
            // for each link
            for (k = 0; k < ll.nl; k++) {
              // where this node is dest
              if (ll.l[k].to == prob.con[i].d) {
                // sum of flows for that connection along that link (i.e. nf)
                nf = i*ll.nl + k;
                lp->Aeq[nf] = 1;
              }
            }
          }
          lp->Aeq[lp->nv-1] = -1;
          lp->beq[0] = 0;
          printLinProg(*lp, EQ, prob.ncon*ll.nl);
          // set everything to zero
          memset (lp->Aeq, 0, sizeof(double)*lp->nv);
          lp->ec ++;
        }

        if (prob.obj_type == MAX_PROPORTIONAL_FAIR) {

          int ni_base;
          if (prob.multipath == 0)
            ni_base = 2*prob.ncon*ll.nl;
          else
            ni_base = prob.ncon*ll.nl;
          
          for (i=0; i<prob.ncon; i++) {
            for (k = 0; k < ll.nl; k++) {
              // where this node is dest
              if (ll.l[k].to == prob.con[i].d) {
                // sum of flows for that connection along that link (i.e. nf)
                nf = i*ll.nl + k;
                lp->Aeq[nf] = 1;
              }
            }

            for (k=0; k<num_cut_points; k++) {
              nf = ni_base + i*num_cut_points + k;
              lp->Aeq[nf] = -1;
            }

            lp->beq[0] = 0;
            printLinProg(*lp, EQ, prob.ncon*ll.nl);
            // set everything to zero
            memset (lp->Aeq, 0, sizeof(double)*lp->nv);
            lp->ec ++;
          }
        }
}

void addInEq (struct LinkList ll, struct SetCliques scl, struct Problem prob, struct LinProg *lp)
{
  //FILE *fp = lp->fp.lp;
  
	// ineqality constraints
	
	// nubmer of inequality constraints: 
	// - sum of utilizations of links belonging to a clique is less than or equal to 1. 
	// if we are looking at single path problem, add also: 
	//  - for each sd pair (q)
	//   	- at each node
	//   		sum of indicator variables for flows for pair q on links that 
	//   		are incoming at this node is less than or euqal to 1
	//  - for each sd pair p
	//  	- for each link q
	//  		flow p*nl+q - indicator variable for flow p*nl+q*link capacity <= 0
	// - for MAX_ALPHA (fairness)
        //   for each sd pair p
        //       p's flow >= alpha * demand
  
	int i, j, k, nf, ni_base, ni, count;
        double scale;

	lp->ec = 0; 
	// set everything to zero
	memset (lp->A, 0, sizeof(double)*lp->nv); 
	
	// first nl*ncon variables are flows. 
	// index of flow of connection p (0 .. ncon-1) 
	// along link q (0 .. nl-1) is given by: 
	// p*nl + q
	
	for (i = 0; i < scl.n; i++) {
		// for each clique
		count = 0;
		for (j = 0; j < ll.nl; j++) {
                  // is this link in this clique?
                  int id = isIn(j, scl.cl[i]);
                  if (id != -1) {
                    count ++;
                    // if it is, add its utilization ...
                    for (k = 0; k < prob.ncon; k++) {
                      nf = k*ll.nl + j;
                      // Lili  modified
                      if (prob.clique_const_type == CLIQUE_OPT_SCHEDULE)
                        lp->A[nf] = scl.cl[i].w[id]/ll.l[j].capacity*1/(1-ll.l[j].loss);
                      else
                        lp->A[nf] = scl.cl[i].w[id]/ll.l[j].capacity;
                    }
                  }
		}
		// the sum is less than, or equal to max_util
		lp->b[0] = scl.cl[i].max_util;
		// print it.
		printf ("added inequality %d\n", lp->ec);
		printLinProg(*lp, INEQ, prob.ncon*ll.nl);
		// set everything to zero
		memset (lp->A, 0, sizeof(double)*lp->nv); 
		lp->ec++;
	}

        ni_base = ll.nl*prob.ncon;
        
	memset (lp->A, 0, sizeof(double)*lp->nv); 

	if (prob.multipath == 0) {

		// ni_base is where indicator variables start
		
		//  - for each sd pair (q)
		//   	- at each node
		//   		sum of indicator variables for flows for pair q on links that 
		//   		are incoming at this node is less than or euqal to 1

		for (i = 0; i < prob.ncon; i++) {
			for (j = 0; j < ll.nn; j++) {
				for (k = 0; k < ll.nl; k++) {
					if (ll.l[k].to == j) {
						ni = ni_base + i*ll.nl + k;
						lp->A[ni] = 1;
					}
				}
				lp->b[0] = 1;
				printf ("added inequality %d\n", lp->ec);
				printLinProg(*lp, INEQ, prob.ncon*ll.nl);
				// set everything to zero
				memset (lp->A, 0, sizeof(double)*lp->nv); 
				lp->ec ++;
			}
		}
		
		//  - for each sd pair p
		//  	- for each link q
		//  		flow p*nl+q - indicator variable for flow p*nl+q*link capacity <= 0

		memset (lp->A, 0, sizeof(double)*lp->nv); 

		for (i = 0; i < prob.ncon; i++) {
			for (j = 0; j < ll.nl; j++) {
				ni = ni_base + i*ll.nl + j;
				nf = i*ll.nl + j;
				lp->A[nf] = 1;
                                // Lili starts
				lp->A[ni] = -1*ll.l[j].capacity;
                                // Lili ends
				lp->b[0] = 0;
				printf ("added inequality %d\n", lp->ec);
				printLinProg(*lp, INEQ, prob.ncon*ll.nl);
				// set everything to zero
				memset (lp->A, 0, sizeof(double)*lp->nv); 
				lp->ec ++;
			}
		}

                ni_base += ll.nl*prob.ncon; 
	}

        memset (lp->A, 0, sizeof(double)*lp->nv);

        if (prob.obj_type == MAX_ALPHA) {
          //fprintf(fp, "start demand\n");
          // each flow's throughput - alpha*demand >= 0
          // equivalent to (- each flow's throughput + alpha * demand <= 0)

          // for each flow, its throughput >= alpha * demand
          for (i = 0; i < prob.ncon; i++) {
            // for each link
            for (k = 0; k < ll.nl; k++) {
              // where this node is dest
              if (ll.l[k].to == prob.con[i].d) {
                // sum of flows for that connection along that link (i.e. nf)
                nf = i*ll.nl + k;
                lp->A[nf] = -1;
              }
            }
            lp->A[lp->nv-1] = prob.con[i].demand;
            lp->b[0] = 0;
            printLinProg(*lp, INEQ, prob.ncon*ll.nl);
            // set everything to zero
            memset (lp->A, 0, sizeof(double)*lp->nv);
            lp->ec ++;
          }
          //fprintf(fp, "end demand\n");

          // for each flow, its throughput >= epsilon
          // for each flow
          scale = (prob.epsilon > 0) ? 1.0/sqrt(prob.epsilon) : 1.0;
          for (i = 0; i < prob.ncon; i++) {
            // for each link
            for (k = 0; k < ll.nl; k++) {
              // where this node is dest
              if (ll.l[k].to == prob.con[i].d) {
                // sum of flows for that connection along that link (i.e. nf)
                nf = i*ll.nl + k;
                lp->A[nf] = -scale;
              }
            }
            lp->b[0] = -scale*prob.epsilon;
            printLinProg(*lp, INEQ, prob.ncon*ll.nl);
            // set everything to zero
            memset (lp->A, 0, sizeof(double)*lp->nv);
            lp->ec ++;
          }
        }
        else if (prob.obj_type == MAX_FAIR_SHARE) {

          // w*Di/sum(Di) - throughput(i) - zi <= 0
          // for each flow
          for (i = 0; i < prob.ncon; i++) {
            // for each link
            for (k = 0; k < ll.nl; k++) {
              // where this node is dest
              if (ll.l[k].to == prob.con[i].d) {
                // sum of flows for that connection along that link (i.e. nf)
                nf = i*ll.nl + k;
                lp->A[nf] = -1;
              }
            }
            printf("ni_base+i = %d\n", ni_base+i);
            lp->A[ni_base+i] = -1; // -zi
            lp->A[lp->nv-1] = prob.con[i].demand/prob.total_demand; // w*Di/sum(Di)
            lp->b[0] = 0;
            printLinProg(*lp, INEQ, prob.ncon*ll.nl);
            // set everything to zero
            memset (lp->A, 0, sizeof(double)*lp->nv);
            lp->ec ++;
          }
          
          // -w*Di/sum(Di) + throughput(i) - zi <= 0
          // for each flow
          for (i = 0; i < prob.ncon; i++) {
            // for each link
            for (k = 0; k < ll.nl; k++) {
              // where this node is dest
              if (ll.l[k].to == prob.con[i].d) {
                // sum of flows for that connection along that link (i.e. nf)
                nf = i*ll.nl + k;
                lp->A[nf] = 1;
              }
            }
            lp->A[ni_base+i] = -1; // -zi
            lp->A[lp->nv-1] = -prob.con[i].demand/prob.total_demand; // -w*Di/sum(Di)
            lp->b[0] = 0;
            printLinProg(*lp, INEQ, prob.ncon*ll.nl);
            // set everything to zero
            memset (lp->A, 0, sizeof(double)*lp->nv);
            lp->ec ++;
          }
        }

        // for each flow, its throughput <= demand
        for (i = 0; i < prob.ncon; i++) {
          // for each link
          for (k = 0; k < ll.nl; k++) {
            // where this node is dest
            if (ll.l[k].to == prob.con[i].d) {
              // sum of flows for that connection along that link (i.e. nf)
              nf = i*ll.nl + k;
              lp->A[nf] = 1;
            }
          }
          lp->b[0] = prob.con[i].demand;
          printLinProg(*lp, INEQ, prob.ncon*ll.nl);
          // set everything to zero
          memset (lp->A, 0, sizeof(double)*lp->nv);
          lp->ec ++;
        }
        
}

int isIn(int l, struct Clique cl) 
{
	//returns 1 if l is in is else 0
	
	int i; 

	for (i = 0; i < cl.n ; i++) {
		if (cl.v[i] == l) {
			return i; 
		}
	}
	return -1;
}
