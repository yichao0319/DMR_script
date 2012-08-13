#include "perflow.h"

int main (int argc, char **argv)
{
  struct LinkList ll;
  struct Problem prob;
  struct lpsolveResult lpr;
  int i, j, nf;
  float t, total;
  int opform;
  double epsilon;
  if (argc != 5 && argc != 6) {
    printf ("Usage: %s <link file> <output format> <lp_solve_resultfile> <variables_map_file> [<epsilon>]\n", argv[0]);
    exit(-1);
  }

  //read in problem: i.e. single/multipath and list of sources and destinations
  readInfo(argv[1], &ll, &prob);

  epsilon = 0;
  if (argc == 6)
    epsilon = atof(argv[5]);

  //get the first ncon*nl variables
  printf("ncon=%d nl=%d\n",prob.ncon,ll.nl);
  lpr.nv = prob.ncon*ll.nl;

  //what output format: 1 Matlab, 2 lp_solve, 4 cplex
  opform = atoi(argv[2]);

  switch(opform)
    {
    case OPFORM_MATLAB_SPARSE:
      fprintf(stderr, "Currently unsupported MATLAB type\n");
      exit(-1);
      break;
    case OPFORM_MATLAB:
      fprintf(stderr, "Currently unsupported MATLAB type\n");
      exit(-1);
      break;
   
    case OPFORM_LPSOLVE:
      //read in lp_result"
      if (readLpsolveRes (argv[3], &lpr) == -1)
	{
	  fprintf(stderr, "Reading LPSOLVE result error!");
	  exit(-1);
	};
      break;
    
    case OPFORM_CPLEX_LP:
      //use CPLEX2lp_solve.py to convert lp_solve result to CPLEX result
      if (readLpsolveRes(argv[3], &lpr) == -1)
	{
	  fprintf(stderr, "Reading CPLex result error!");
	  exit(-1);
	}
      break;
    default:
      fprintf(stderr, "Incorrect op format\n");
      exit(-1);
      break;

    }

  //dump the variables to a file
  FILE *xfp;
  struct Variable *xs;
  struct FlowInfo *finfos;

  //Open the file
  if ((xfp = fopen(argv[4], "w")) == NULL) {
    fprintf(stderr, "Can't open file %s for writing\n", argv[4]);
    exit(-1);
  }
  
  //memory for holding the list of variables
  if ((xs = (struct Variable *) calloc(lpr.nv, sizeof(struct Variable))) == NULL) {
    fprintf(stderr, "Can't allocate memory to hold variables");
    exit(-1);
  }

  //memory for holding the flowInfo
  if ((finfos = (struct FlowInfo *) calloc(prob.ncon, sizeof(struct FlowInfo))) == NULL) {
    fprintf(stderr, "Can't allocate memory to hodl flows");
    exit(-1);
  }

  //for each connection,
  //      for all links that come out of nodes s
  //          compute its throughput
  total = 0.0;
  for (i = 0; i < prob.ncon; i ++) {
    finfos[i].S = prob.con[i].s;
    finfos[i].D = prob.con[i].d;
    t = 0.0;
    for (j = 0;  j < ll.nl; j ++) {
      nf = i*ll.nl + j;
      if (ll.l[j].from == prob.con[i].s)
	t = t + lpr.x[nf];
    }
    finfos[i].flow_t = t;
    total = total + t;
    printf("%d %d %.10f\n", prob.con[i].s, prob.con[i].d, t);
  }
  printf("total = %.10f\n", total);

  
  //Fill in variables
  for (i = 0; i < prob.ncon; i ++) {
    for (j = 0;  j < ll.nl; j++) {
      //get x(nf)
      nf = i * ll.nl + j;

      xs[nf].x = nf;
      xs[nf].flow = i;
      xs[nf].flow_S = prob.con[i].s;
      xs[nf].flow_D = prob.con[i].d;
      xs[nf].link = j;
      xs[nf].link_from = ll.l[j].from;
      xs[nf].link_to = ll.l[j].to;
      xs[nf].channel = ll.l[j].channel;
      xs[nf].capacity = ll.l[j].capacity;
      xs[nf].load = lpr.x[nf];
      xs[nf].flow_t = finfos[i].flow_t;
      if (xs[nf].load >= epsilon) {
        fprintf(xfp, "%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.10f\t%.10f\t%.10f\n", xs[nf].x, xs[nf].flow, xs[nf].flow_S, xs[nf].flow_D, xs[nf].link, xs[nf].link_from, xs[nf].link_to, xs[nf].channel, xs[nf].capacity, xs[nf].load, xs[nf].flow_t);
      }
    }
  }

  fclose(xfp);
  

  return 0;
}
