#include "readlist.h"
#include "lpcom.h" // Lili added

void readInfo (char *llfn, struct LinkList *ll, struct Problem *prob) 
{
	FILE *fp;

	// open the file
	if ((fp = fopen (llfn, "r")) == NULL) {
		printf ("Can't open file %s for reading\n", llfn);
		exit(-1);
	}
	
	// interference model
	fscanf (fp, "%d", &(ll->ifmodel));
	
	// mac 
	fscanf (fp, "%d", &(ll->mac));

	// read number of nodes
	fscanf (fp, "%d", &(ll->nn));

	readLinks (fp, ll); 

	readConflictMatrix (fp, ll); 

	readSDPairs(fp, prob); 

	fclose(fp);
}

// Lili starts
void readLoss(char *lossFile, struct LinkList *ll)
{
  FILE *fp;
  int i, index;

  // open the file
  if ((fp = fopen (lossFile, "r")) == NULL) {
    printf ("Can't open file %s for reading\n", lossFile);
    exit(-1);
  }

  for (i = 0 ; i < ll->nl; i++) {
    fscanf (fp, "%d %d %d %lf", &index, &(ll->l[i].from), &(ll->l[i].to), &(ll->l[i].loss));
  }

  fclose(fp);
}

void readRoute(char *routeFile, Problem prob, struct LinkList ll, struct LinProg *lp)
{
  FILE *fp;
  int i, j, k, flowid, power, rate, src, dest, currNode, nextHop, nf, connId, hops;
  char line[1024];
  char str[1024];
  char str1[1024];
  float ratef;

  connId = -1;
  
  // open the file
  if ((fp = fopen (routeFile, "r")) == NULL) {
    printf ("Can't open file %s for reading\n", routeFile);
    exit(-1);
  }

  lp->const_var = prob.ncon * ll.nl;
  
  lp->var_values = alloc1D(prob.ncon*ll.nl, "VarValue");
  memset(lp->var_values, 0, sizeof(double)*prob.ncon*ll.nl);
  
  for (i = 0; i < prob.ncon; i++) {
    fscanf(fp, "%d %s %s %d", &flowid, str, str1, &hops);
    src = extractNodeId(str)-1; //qualnet nodeId differs by 1 from conflict.txt 
    dest = extractNodeId(str1)-1;

    // find the connection with the same src & dest
    for (j = 0; j < prob.ncon; j++) {
      if (prob.con[j].s == src && prob.con[j].d == dest) {
        connId = j;
        break;
      }
    }
    //printf("got flow: %d src: %d dst: %d hops: %d\n", connId,src,dest,hops);

    assert(connId >= 0);
    
    fscanf(fp, "%s", str);
    currNode = src;
    
    for (j = 0; j < hops; j++) {
      fscanf(fp, "%d %f %s",  &power, &ratef, str);
      //printf("mikie rate %f %s !!!\n", ratef, str);

      nextHop = extractNodeId(str)-1;
      //printf("got nexthop: %d\n", nextHop);

      // search for the linkId with currNode-nextHop
      for (k = 0; k < ll.nl; k++) {
        if (ll.l[k].from == currNode && ll.l[k].to == nextHop) {
          nf = connId*ll.nl + k;
          break;
        }
      }
      lp->var_values[nf] = 1;
      currNode = nextHop;
    }
  }
}

/*
void readRoute(char *routeFile, Problem prob, struct LinkList ll, struct LinProg *lp)
{
  FILE *fp;
  int i, j, k, src, dest, currNode, nextHop, nf, connId, hops;
  char str[1024];

  connId = -1;
  
  // open the file
  if ((fp = fopen (routeFile, "r")) == NULL) {
    printf ("Can't open file %s for reading\n", routeFile);
    exit(-1);
  }

  lp->const_var = prob.ncon * ll.nl;
  
  lp->var_values = alloc1D(prob.ncon*ll.nl, "VarValue");
  memset(lp->var_values, 0, sizeof(double)*prob.ncon*ll.nl);
  
  for (i = 0; i < prob.ncon; i++) {
    fscanf(fp, "%d %s %d", &src, str, &hops);
    src = src-1; //qualnet nodeId differs by 1 from conflict.txt 
    dest = extractNodeId(str)-1;

    // find the connection with the same src & dest
    for (j = 0; j < prob.ncon; j++) {
      if (prob.con[j].s == src && prob.con[j].d == dest) {
        connId = j;
        break;
      }
    }

    assert(connId >= 0);
    
    fscanf(fp, "%s", str);
    currNode = src;
    
    for (j = 0; j < hops; j++) {
      fscanf(fp, "%s", str);
      nextHop = extractNodeId(str)-1;

      // search for the linkId with currNode-nextHop
      for (k = 0; k < ll.nl; k++) {
        if (ll.l[k].from == currNode && ll.l[k].to == nextHop) {
          nf = connId*ll.nl + k;
          break;
        }
      }
      lp->var_values[nf] = 1;
      currNode = nextHop;
    }
  }
}
*/
int extractNodeId(char *str)
{
  int addr[4];
  sscanf(str, "%d.%d.%d.%d", &addr[0], &addr[1], &addr[2], &addr[3]);
  printf("1: %d 2: %d 3: %d 4: %d\n",addr[0], addr[1], addr[2], addr[3]);
  return(addr[3]);
}
// Lili ends

void readLinks (FILE *fp, struct LinkList *ll)
{
	int i, index; 

	// read number of links
	fscanf (fp, "%d", &(ll->nl));

	// memory for holding the list of links
	if ((ll->l = (Link *) calloc (ll->nl, sizeof(struct Link))) == NULL) {
		printf ("can't allocate memory to hold link list\n");
		exit(-1);
	}
	
	// read the list of links
	for (i = 0 ; i < ll->nl; i++) {
          ll->l[i].loss = 0;
		fscanf (fp, "%d %d %d %d %lf", 
			     	&index, 
			     	&(ll->l[i].from), &(ll->l[i].to), 
			     	&(ll->l[i].channel),
			     	&(ll->l[i].capacity));
		printf ("%d %d %d %d %lf\n", 
				index, 
				ll->l[i].from, ll->l[i].to, 
				ll->l[i].channel,
				ll->l[i].capacity);
	}
}

void readConflictMatrix (FILE *fp, struct LinkList *ll)
{
  printf("lfmodel = %d\n", ll->ifmodel);
  
	if (ll->ifmodel == IFMODEL_PROTO) {
			readProtoConflictMatrix (fp, ll);
	} else {
		if ((ll->ifmodel == IFMODEL_PHY) && (ll->mac == MAC_UNI)) {
				readPhyUniConflictMatrix (fp, ll);
		} else {
			if ((ll->ifmodel == IFMODEL_PHY) && (ll->mac == MAC_BI)) {
					readPhyBiConflictMatrix (fp, ll);
			} else {
				printf ("can't handle this ifmodel and/or mac\n");
				exit(-1);
			}
		}
	}
}

void readProtoConflictMatrix (FILE *fp, struct LinkList *ll)
{
	int i, j;

	// for now, the size of conflict graph is nxn. 
	if ((ll->conflict = (int **)calloc(ll->nl, sizeof (int *))) == NULL) {
		printf ("can't allocate conflict graph memory -1\n");
		exit(-1);
	}
	for (i = 0 ; i < ll->nl; i++) {
		if ((ll->conflict[i] = (int *)calloc(ll->nl, sizeof(int))) == NULL) {
			printf ("can't allocate conflict graph memory %d\n", i);
			exit(-1);
		}
	}
	// read data from file
	for (i = 0 ; i < ll->nl; i++) {
		for (j = 0 ; j < ll->nl; j++) {
			fscanf (fp, "%d", &(ll->conflict[i][j]));
			//printf ("%d ", ll->conflict[i][j]);
		}
		printf ("Row %d read \n", i);
	}
}

void readPhyUniConflictMatrix (FILE *fp, struct LinkList *ll)
{
	int i, j; 

	// for now, the size of phy_conflict graph is nxn. 
	if ((ll->phy_conflict = (double **)calloc(ll->nl, sizeof (double *))) == NULL) {
		printf ("can't allocate phy_conflict graph memory -1\n");
		exit(-1);
	}
	for (i = 0 ; i < ll->nl; i++) {
		if ((ll->phy_conflict[i] = (double *)calloc(ll->nl, sizeof(double))) == NULL) {
			printf ("can't allocate phy_conflict graph memory %d\n", i);
			exit(-1);
		}
	}
	// read data from file
	for (i = 0 ; i < ll->nl; i++) {
		for (j = 0 ; j < ll->nl; j++) {
			fscanf (fp, "%lf", &(ll->phy_conflict[i][j]));
			printf ("%lf ", ll->phy_conflict[i][j]);
		}
		printf ("\n");
	}
}

void readPhyBiConflictMatrix (FILE *fp, struct LinkList *ll)
{
	int i, j, k; 

	// for now, the size of phy_bi_conflict graph is nxnx2. 
	if ((ll->phy_bi_conflict = (double ***)calloc(ll->nl, sizeof (double **))) == NULL) {
		printf ("can't allocate phy_bi_conflict graph memory -1\n");
		exit(-1);
	}
	for (i = 0 ; i < ll->nl; i++) {
		if ((ll->phy_bi_conflict[i] = (double **)calloc(ll->nl, sizeof(double *))) == NULL) {
			printf ("can't allocate phy_bi_conflict graph memory %d\n", i);
			exit(-1);
		}
		for (j = 0; j < ll->nl; j++) {
			if ((ll->phy_bi_conflict[i][j] = (double *)calloc(2, sizeof(double))) == NULL) {
				printf ("can't allocate phy_bi_conflict graph memory %d %d\n", i, j);
				exit(-1);
			}
		}
	}

	// read data from file
	for (i = 0 ; i < ll->nl; i++) {
		for (j = 0 ; j < ll->nl; j++) {
			for (k = 0; k < 2; k++) {
				fscanf (fp, "%lf", &(ll->phy_bi_conflict[i][j][k]));
				printf ("%lf ", ll->phy_bi_conflict[i][j][k]);
			}
		}
		printf ("\n");
	}
}

void readSDPairs (FILE *fp, struct Problem *prob) 
{
	int i; 

	// # of flows, and single.multiptah
	fscanf (fp, "%d %d", &(prob->ncon), &(prob->multipath)); 

	// memory for holding the list of connections 
	if ((prob->con = (Connection*) calloc (prob->ncon, sizeof(struct Connection))) == NULL) {
		printf ("can't allocate memory to hold connection list\n");
		exit(-1);
	}

        // Lili starts
	// read in soure-destination pairs
        prob->total_demand = 0;
	for (i = 0; i < prob->ncon; i++) {
          fscanf(fp, "%lf %d %d", &(prob->con[i].demand),&(prob->con[i].s), &(prob->con[i].d));
          printf("%d %d\n", prob->con[i].s, prob->con[i].d);
          prob->total_demand += prob->con[i].demand;
          // Lili ends
	}

}

void readFlowLowerBound (char *flbfn, struct Problem prob, struct LinkList ll, struct LinProg *lp) 
{
	FILE *fp;
	int i, j;
        
	// open the file
	if ((fp = fopen (flbfn, "r")) == NULL) {
		printf ("Can't open file %s for reading\n", flbfn);
		exit(-1);
	}
        
        lp->var_LBs = alloc1D(prob.ncon*ll.nl, "VarValue");
        memset(lp->var_LBs, 0, sizeof(double)*prob.ncon*ll.nl);
        
	// read in demand lower bounds
	for (i = 0; i < prob.ncon; i++) {
        	for (j = 0; j < ll.nl; j++) {
            		fscanf(fp, "%lf", &lp->var_LBs[i*ll.nl+j]);
                }
	}

        fclose(fp);
}

